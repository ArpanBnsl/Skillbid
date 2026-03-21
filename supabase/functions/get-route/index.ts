// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const ORS_API_KEY = Deno.env.get("ORS_API_KEY") ?? "";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    if (!ORS_API_KEY) {
      return new Response(JSON.stringify({ error: "ORS_API_KEY is not configured" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { start, end } = await req.json();

    if (
      !Array.isArray(start) ||
      !Array.isArray(end) ||
      start.length !== 2 ||
      end.length !== 2
    ) {
      return new Response(JSON.stringify({ error: "Invalid start/end coordinates" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const url = "https://api.openrouteservice.org/v2/directions/driving-car";
    const response = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: ORS_API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        coordinates: [start, end],
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      return new Response(
        JSON.stringify({ error: "ORS API error", detail: text }),
        {
          status: response.status,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const data = await response.json();

    const route = data?.routes?.[0];
    if (!route) {
      return new Response(
        JSON.stringify({ error: "No route found" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    const result = {
      geometry: route.geometry,
      distance: route.summary?.distance ?? 0,
      duration: route.summary?.duration ?? 0,
    };

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Internal error", message: String(err) }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
