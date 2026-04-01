// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Firebase service account credentials (stored as Supabase secrets).
const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
const FIREBASE_CLIENT_EMAIL = Deno.env.get("FIREBASE_CLIENT_EMAIL") ?? "";
const FIREBASE_PRIVATE_KEY = (Deno.env.get("FIREBASE_PRIVATE_KEY") ?? "").replace(
  /\\n/g,
  "\n",
);

// Supabase env vars are automatically available in Edge Functions.
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { type, record } = await req.json();

    // Admin client – bypasses RLS so we can read device_tokens for any user.
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Get OAuth2 access token for FCM HTTP v1 API.
    const accessToken = await getFirebaseAccessToken();

    let recipientUserIds: string[] = [];
    let title = "";
    let body = "";
    let data: Record<string, string> = {};

    switch (type) {
      // -----------------------------------------------------------------
      // NEW JOB — notify all providers
      // -----------------------------------------------------------------
      case "new_job": {
        // Get all users who have the provider role (role_id = 2).
        const { data: roles } = await supabaseAdmin
          .from("user_roles")
          .select("user_id")
          .eq("role_id", 2);

        recipientUserIds = (roles ?? [])
          .map((r: any) => r.user_id)
          .filter((id: string) => id !== record.client_id);

        title = "New Project Available!";
        body = `${record.title} — Budget: $${record.budget}`;
        data = { type: "new_job", target_id: record.id };
        break;
      }

      // -----------------------------------------------------------------
      // NEW BID — notify the job owner (client)
      // -----------------------------------------------------------------
      case "new_bid": {
        const { data: job } = await supabaseAdmin
          .from("jobs")
          .select("client_id, title")
          .eq("id", record.job_id)
          .single();

        if (job) {
          recipientUserIds = [job.client_id];
          title = "New Bid Received!";
          body = `Someone bid $${record.amount} on "${job.title}"`;
          data = { type: "new_bid", target_id: record.job_id };
        }
        break;
      }

      // -----------------------------------------------------------------
      // NEW MESSAGE — notify the other chat participant
      // -----------------------------------------------------------------
      case "new_message": {
        const { data: chat } = await supabaseAdmin
          .from("chats")
          .select("client_id, provider_id")
          .eq("id", record.chat_id)
          .single();

        if (chat) {
          const recipientId =
            record.sender_id === chat.client_id
              ? chat.provider_id
              : chat.client_id;
          recipientUserIds = [recipientId];

          // Sender's display name for the notification title.
          const { data: profile } = await supabaseAdmin
            .from("profiles")
            .select("full_name")
            .eq("id", record.sender_id)
            .single();

          title = profile?.full_name ?? "New Message";
          body =
            record.content?.substring(0, 100) ?? "Sent you a message";
          data = {
            type: "new_message",
            target_id: record.chat_id,
            role:
              record.sender_id === chat.client_id ? "provider" : "client",
          };
        }
        break;
      }
    }

    if (recipientUserIds.length === 0) {
      return new Response(JSON.stringify({ message: "No recipients" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch FCM tokens for all recipients.
    const { data: tokens } = await supabaseAdmin
      .from("device_tokens")
      .select("fcm_token")
      .in("user_id", recipientUserIds);

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: "No tokens found" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fire FCM requests in parallel.
    const results = await Promise.allSettled(
      tokens.map((t: any) =>
        sendFCMNotification(accessToken, t.fcm_token, title, body, data),
      ),
    );

    const sent = results.filter((r) => r.status === "fulfilled").length;

    return new Response(
      JSON.stringify({ message: `Sent ${sent}/${tokens.length} notifications` }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    console.error("send-notification error:", err);
    return new Response(
      JSON.stringify({ error: "Internal error", message: String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

// ---------------------------------------------------------------------------
// Firebase Auth — get an OAuth2 access token from a service-account JWT
// ---------------------------------------------------------------------------

async function getFirebaseAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: FIREBASE_CLIENT_EMAIL,
    sub: FIREBASE_CLIENT_EMAIL,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const encodedHeader = base64url(JSON.stringify(header));
  const encodedPayload = base64url(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(FIREBASE_PRIVATE_KEY),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );

  const jwt = `${signingInput}.${base64url(signature)}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenResponse.json();
  if (!tokenData.access_token) {
    throw new Error(`Firebase token exchange failed: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

// ---------------------------------------------------------------------------
// FCM HTTP v1 — send a single notification
// ---------------------------------------------------------------------------

async function sendFCMNotification(
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>,
) {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          data,
          android: {
            priority: "high",
            notification: {
              channel_id: "skillbid_notifications",
              sound: "default",
            },
          },
        },
      }),
    },
  );

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`FCM error ${response.status}: ${errText}`);
  }
  return response.json();
}

// ---------------------------------------------------------------------------
// Utility helpers
// ---------------------------------------------------------------------------

function base64url(input: string | ArrayBuffer): string {
  let bytes: Uint8Array;
  if (typeof input === "string") {
    bytes = new TextEncoder().encode(input);
  } else {
    bytes = new Uint8Array(input);
  }
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}