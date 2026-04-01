# Code Citations

## License: unknown
https://github.com/Nicollas1305/Testing-Maps/blob/9574601e78ec6facda1c44458c0b4dc4aa55636b/README.md

```
Here is the **complete list of expected changes** for the "Immediate Service" feature:

---

## 1. DATABASE SCHEMA CHANGES

### A. `profiles` table — Add location + immediate request counter

```sql
ALTER TABLE profiles
  ADD COLUMN latitude DOUBLE PRECISION,
  ADD COLUMN longitude DOUBLE PRECISION,
  ADD COLUMN location_updated_at TIMESTAMP,
  ADD COLUMN imm_req_cnt INT DEFAULT 0;
```

| Column | Type | Purpose |
|---|---|---|
| `latitude` | `DOUBLE PRECISION` | User's last-known latitude |
| `longitude` | `DOUBLE PRECISION` | User's last-known longitude |
| `location_updated_at` | `TIMESTAMP` | When location was last refreshed |
| `imm_req_cnt` | `INT DEFAULT 0` | Count of immediate requests the user has posted |

### B. `jobs` table — Add immediate-service fields + precise geo-coordinates

```sql
ALTER TABLE jobs
  ADD COLUMN is_immediate BOOLEAN DEFAULT FALSE,
  ADD COLUMN expires_at TIMESTAMP,
  ADD COLUMN job_lat DOUBLE PRECISION,
  ADD COLUMN job_lng DOUBLE PRECISION;

CREATE INDEX idx_jobs_is_immediate ON jobs(is_immediate);
CREATE INDEX idx_jobs_expires_at ON jobs(expires_at);
```

| Column | Type | Purpose |
|---|---|---|
| `is_immediate` | `BOOLEAN DEFAULT FALSE` | Flag: standard job vs. immediate service |
| `expires_at` | `TIMESTAMP` | Deadline for bid acceptance (only for immediate jobs) |
| `job_lat` | `DOUBLE PRECISION` | Precise job latitude (from map picker) |
| `job_lng` | `DOUBLE PRECISION` | Precise job longitude (from map picker) |

### C. `contracts` table — Add live-tracking fields

```sql
ALTER TABLE contracts
  ADD COLUMN provider_lat DOUBLE PRECISION,
  ADD COLUMN provider_lng DOUBLE PRECISION,
  ADD COLUMN last_location_update TIMESTAMP,
  ADD COLUMN tracking_enabled BOOLEAN DEFAULT FALSE;
```

| Column | Type | Purpose |
|---|---|---|
| `provider_lat` | `DOUBLE PRECISION` | Provider's current latitude during active tracking |
| `provider_lng` | `DOUBLE PRECISION` | Provider's current longitude during active tracking |
| `last_location_update` | `TIMESTAMP` | When provider location was last written |
| `tracking_enabled` | `BOOLEAN DEFAULT FALSE` | True only while contract is active & from immediate job |

### D. New indexes

```sql
CREATE INDEX idx_jobs_is_immediate ON jobs(is_immediate);
CREATE INDEX idx_jobs_expires_at ON jobs(expires_at);
CREATE INDEX idx_contracts_tracking ON contracts(tracking_enabled) WHERE tracking_enabled = TRUE;
CREATE INDEX idx_profiles_location ON profiles(latitude, longitude) WHERE latitude IS NOT NULL;
```

---

## 2. SUPABASE REALTIME CONFIGURATION

| Table | Event | Purpose |
|---|---|---|
| `bids` | INSERT | Real-time new-bid notifications under client's "Posted" section for immediate jobs |
| `contracts` | UPDATE (`provider_lat`, `provider_lng`) | Live provider location tracking on client map |
| `jobs` | UPDATE (`status`) | Detect when job is cancelled/expired |

**Enable Realtime** on these tables in the Supabase Dashboard → Database → Replication, or via SQL:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE bids;
ALTER PUBLICATION supabase_realtime ADD TABLE contracts;
ALTER PUBLICATION supabase_realtime ADD TABLE jobs;
```

---

## 3. SUPABASE EDGE FUNCTION

### `get-route` Edge Function

**Purpose**: Acts as a secure proxy to the OpenRouteService Directions API so the API key is never exposed in the client.

**Location**: `supabase/functions/get-route/index.ts`

**Input** (POST JSON):
```json
{
  "start": [provider_lng, provider_lat],
  "end": [client_lng, client_lat]
}
```

**Output** (JSON):
```json
{
  "geometry": "<encoded polyline>",
  "distance": 12345.6,
  "duration": 890.5
}
```

**Environment variable** (set via Supabase Dashboard → Edge Functions → Secrets):
```
ORS_API_KEY=<your-openrouteservice-api-key>
```

**Deployment**:
```bash
supabase functions deploy get-route
```

---

## 4. SUPABASE SCHEDULED FUNCTION (or pg_cron)

### Job Expiration Cron

**Purpose**: Automatically cancel expired immediate jobs and their bids.

**Option A — pg_cron** (recommended, runs inside Postgres):
```sql
SELECT cron.schedule(
  'cancel-expired-immediate-jobs',
  '* * * * *',  -- every minute
  $$
    UPDATE bids SET status = 'cancelled', updated_at = NOW()
    WHERE job_id IN (
      SELECT id FROM jobs
      WHERE is_immediate = TRUE AND status = 'open' AND expires_at <= NOW()
    ) AND status = 'pending';

    UPDATE jobs SET status = 'cancelled', updated_at = NOW()
    WHERE is_immediate = TRUE AND status = 'open' AND expires_at <= NOW();
  $$
);
```

**Option B — Supabase Edge Function** triggered by a cron (if pg_cron is not available on your plan).

---

## 5. FLUTTER DEPENDENCIES TO ADD (`pubspec.yaml`)

| Package | Purpose |
|---|---|
| `flutter_map: ^6.0.0` | OpenStreetMap-based map widget (free, no API key required for tiles) |
| `latlong2: ^0.9.0` | Latitude/longitude math (distance calculations, point storage) |
| `geolocator: ^12.0.0` | Device GPS location (permission handling, continuous position stream) |
| `flutter_polyline_points: ^2.1.0` | Decode ORS encoded polyline geometry to `LatLng` list |
| `permission_handler: ^11.0.0` | Runtime location permission requests (Android/iOS) |

> **Alternative map option**: `google_maps_flutter` if you prefer Google Maps (requires API key + billing). `flutter_map` with OpenStreetMap tiles is free and works well.

---

## 6. ANDROID CONFIGURATION

### [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)

Add permissions:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>SkillBid needs your location to find nearby services and enable provider tracking.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>SkillBid needs background location to update your position while on active jobs.</string>
```

---

## 7. MODEL CHANGES (Dart)

### A. `JobModel` — New fields

| Field | Type | Default |
|---|---|---|
| `isImmediate` | `bool` | `false` |
| `expiresAt` | `DateTime?` | `null` |
| `jobLat` | `double?` | `null` |
| `jobLng` | `double?` | `null` |

### B. `ContractModel` — New fields

| Field | Type | Default |
|---|---|---|
| `providerLat` | `double?` | `null` |
| `providerLng` | `double?` | `null` |
| `lastLocationUpdate` | `DateTime?` | `null` |
| `trackingEnabled` | `bool` | `false` |

### C. `ProfileModel` — New fields

| Field | Type | Default |
|---|---|---|
| `latitude` | `double?` | `null` |
| `longitude` | `double?` | `null` |
| `locationUpdatedAt` | `DateTime?` | `null` |
| `immReqCnt` | `int` | `0` |

### D. Regenerate freezed/json_serializable
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 8. REPOSITORY CHANGES

### A. `JobRepository`
- `createJob()` → accept `isImmediate`, `expiresAt`, `jobLat`, `jobLng`; increment `profiles.imm_req_cnt` when immediate
- `getAvailableJobs()` → for providers, filter immediate jobs by proximity (compare provider lat/lng with job_lat/job_lng and expires_at)
- Add `getImmediateJobsNearby({lat, lng, radiusKm})` → return open immediate jobs within radius
- Add `cancelExpiredJobs()` → app-side fallback; mark expired immediate jobs as cancelled

### B. `BidRepository`
- `createBid()` → for immediate jobs, validate that provider can reach job location within `expires_at` window (proximity check)
- No schema changes needed to bids table itself

### C. `ContractRepository`
- `acceptBidAndCreateContract()` → if job is immediate, set `tracking_enabled = true` on the contract
- `completeContract()` / `terminateContract()` → set `tracking_enabled = false`
- Add `updateProviderLocation({contractId, lat, lng})` → updates `provider_lat`, `provider_lng`, `last_location_update`
- Add `subscribeToProviderLocation(contractId)` → Supabase realtime listener for contract location columns

### D. `UserRepository`
- Add `updateUserLocation({userId, lat, lng})` → updates `profiles.latitude`, `profiles.longitude`, `location_updated_at`

---

## 9. NEW SERVICES

### A. `LocationService` (new file)
- `getCurrentPosition()` → returns `Position` with permission handling
- `requestPermission()` → handles permission flow (geolocator + permission_handler)
- `startLocationStream({intervalMs})` → periodic position streaming for provider tracking
- `stopLocationStream()` → cancels the stream
- `calculateDistance(lat1, lng1, lat2, lng2)` → haversine distance in km
- `estimateTravelTime(distanceKm, avgSpeedKmh)` → for nearby-provider filtering

### B. `RouteService` (new file)
- `getRoute({providerLat, providerLng, clientLat, clientLng})` → calls Supabase Edge Function `get-route`
- Returns: route polyline (decoded to `List<LatLng>`
```


## License: unknown
https://github.com/Nicollas1305/Testing-Maps/blob/9574601e78ec6facda1c44458c0b4dc4aa55636b/README.md

```
Here is the **complete list of expected changes** for the "Immediate Service" feature:

---

## 1. DATABASE SCHEMA CHANGES

### A. `profiles` table — Add location + immediate request counter

```sql
ALTER TABLE profiles
  ADD COLUMN latitude DOUBLE PRECISION,
  ADD COLUMN longitude DOUBLE PRECISION,
  ADD COLUMN location_updated_at TIMESTAMP,
  ADD COLUMN imm_req_cnt INT DEFAULT 0;
```

| Column | Type | Purpose |
|---|---|---|
| `latitude` | `DOUBLE PRECISION` | User's last-known latitude |
| `longitude` | `DOUBLE PRECISION` | User's last-known longitude |
| `location_updated_at` | `TIMESTAMP` | When location was last refreshed |
| `imm_req_cnt` | `INT DEFAULT 0` | Count of immediate requests the user has posted |

### B. `jobs` table — Add immediate-service fields + precise geo-coordinates

```sql
ALTER TABLE jobs
  ADD COLUMN is_immediate BOOLEAN DEFAULT FALSE,
  ADD COLUMN expires_at TIMESTAMP,
  ADD COLUMN job_lat DOUBLE PRECISION,
  ADD COLUMN job_lng DOUBLE PRECISION;

CREATE INDEX idx_jobs_is_immediate ON jobs(is_immediate);
CREATE INDEX idx_jobs_expires_at ON jobs(expires_at);
```

| Column | Type | Purpose |
|---|---|---|
| `is_immediate` | `BOOLEAN DEFAULT FALSE` | Flag: standard job vs. immediate service |
| `expires_at` | `TIMESTAMP` | Deadline for bid acceptance (only for immediate jobs) |
| `job_lat` | `DOUBLE PRECISION` | Precise job latitude (from map picker) |
| `job_lng` | `DOUBLE PRECISION` | Precise job longitude (from map picker) |

### C. `contracts` table — Add live-tracking fields

```sql
ALTER TABLE contracts
  ADD COLUMN provider_lat DOUBLE PRECISION,
  ADD COLUMN provider_lng DOUBLE PRECISION,
  ADD COLUMN last_location_update TIMESTAMP,
  ADD COLUMN tracking_enabled BOOLEAN DEFAULT FALSE;
```

| Column | Type | Purpose |
|---|---|---|
| `provider_lat` | `DOUBLE PRECISION` | Provider's current latitude during active tracking |
| `provider_lng` | `DOUBLE PRECISION` | Provider's current longitude during active tracking |
| `last_location_update` | `TIMESTAMP` | When provider location was last written |
| `tracking_enabled` | `BOOLEAN DEFAULT FALSE` | True only while contract is active & from immediate job |

### D. New indexes

```sql
CREATE INDEX idx_jobs_is_immediate ON jobs(is_immediate);
CREATE INDEX idx_jobs_expires_at ON jobs(expires_at);
CREATE INDEX idx_contracts_tracking ON contracts(tracking_enabled) WHERE tracking_enabled = TRUE;
CREATE INDEX idx_profiles_location ON profiles(latitude, longitude) WHERE latitude IS NOT NULL;
```

---

## 2. SUPABASE REALTIME CONFIGURATION

| Table | Event | Purpose |
|---|---|---|
| `bids` | INSERT | Real-time new-bid notifications under client's "Posted" section for immediate jobs |
| `contracts` | UPDATE (`provider_lat`, `provider_lng`) | Live provider location tracking on client map |
| `jobs` | UPDATE (`status`) | Detect when job is cancelled/expired |

**Enable Realtime** on these tables in the Supabase Dashboard → Database → Replication, or via SQL:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE bids;
ALTER PUBLICATION supabase_realtime ADD TABLE contracts;
ALTER PUBLICATION supabase_realtime ADD TABLE jobs;
```

---

## 3. SUPABASE EDGE FUNCTION

### `get-route` Edge Function

**Purpose**: Acts as a secure proxy to the OpenRouteService Directions API so the API key is never exposed in the client.

**Location**: `supabase/functions/get-route/index.ts`

**Input** (POST JSON):
```json
{
  "start": [provider_lng, provider_lat],
  "end": [client_lng, client_lat]
}
```

**Output** (JSON):
```json
{
  "geometry": "<encoded polyline>",
  "distance": 12345.6,
  "duration": 890.5
}
```

**Environment variable** (set via Supabase Dashboard → Edge Functions → Secrets):
```
ORS_API_KEY=<your-openrouteservice-api-key>
```

**Deployment**:
```bash
supabase functions deploy get-route
```

---

## 4. SUPABASE SCHEDULED FUNCTION (or pg_cron)

### Job Expiration Cron

**Purpose**: Automatically cancel expired immediate jobs and their bids.

**Option A — pg_cron** (recommended, runs inside Postgres):
```sql
SELECT cron.schedule(
  'cancel-expired-immediate-jobs',
  '* * * * *',  -- every minute
  $$
    UPDATE bids SET status = 'cancelled', updated_at = NOW()
    WHERE job_id IN (
      SELECT id FROM jobs
      WHERE is_immediate = TRUE AND status = 'open' AND expires_at <= NOW()
    ) AND status = 'pending';

    UPDATE jobs SET status = 'cancelled', updated_at = NOW()
    WHERE is_immediate = TRUE AND status = 'open' AND expires_at <= NOW();
  $$
);
```

**Option B — Supabase Edge Function** triggered by a cron (if pg_cron is not available on your plan).

---

## 5. FLUTTER DEPENDENCIES TO ADD (`pubspec.yaml`)

| Package | Purpose |
|---|---|
| `flutter_map: ^6.0.0` | OpenStreetMap-based map widget (free, no API key required for tiles) |
| `latlong2: ^0.9.0` | Latitude/longitude math (distance calculations, point storage) |
| `geolocator: ^12.0.0` | Device GPS location (permission handling, continuous position stream) |
| `flutter_polyline_points: ^2.1.0` | Decode ORS encoded polyline geometry to `LatLng` list |
| `permission_handler: ^11.0.0` | Runtime location permission requests (Android/iOS) |

> **Alternative map option**: `google_maps_flutter` if you prefer Google Maps (requires API key + billing). `flutter_map` with OpenStreetMap tiles is free and works well.

---

## 6. ANDROID CONFIGURATION

### [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)

Add permissions:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>SkillBid needs your location to find nearby services and enable provider tracking.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>SkillBid needs background location to update your position while on active jobs.</string>
```

---

## 7. MODEL CHANGES (Dart)

### A. `JobModel` — New fields

| Field | Type | Default |
|---|---|---|
| `isImmediate` | `bool` | `false` |
| `expiresAt` | `DateTime?` | `null` |
| `jobLat` | `double?` | `null` |
| `jobLng` | `double?` | `null` |

### B. `ContractModel` — New fields

| Field | Type | Default |
|---|---|---|
| `providerLat` | `double?` | `null` |
| `providerLng` | `double?` | `null` |
| `lastLocationUpdate` | `DateTime?` | `null` |
| `trackingEnabled` | `bool` | `false` |

### C. `ProfileModel` — New fields

| Field | Type | Default |
|---|---|---|
| `latitude` | `double?` | `null` |
| `longitude` | `double?` | `null` |
| `locationUpdatedAt` | `DateTime?` | `null` |
| `immReqCnt` | `int` | `0` |

### D. Regenerate freezed/json_serializable
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 8. REPOSITORY CHANGES

### A. `JobRepository`
- `createJob()` → accept `isImmediate`, `expiresAt`, `jobLat`, `jobLng`; increment `profiles.imm_req_cnt` when immediate
- `getAvailableJobs()` → for providers, filter immediate jobs by proximity (compare provider lat/lng with job_lat/job_lng and expires_at)
- Add `getImmediateJobsNearby({lat, lng, radiusKm})` → return open immediate jobs within radius
- Add `cancelExpiredJobs()` → app-side fallback; mark expired immediate jobs as cancelled

### B. `BidRepository`
- `createBid()` → for immediate jobs, validate that provider can reach job location within `expires_at` window (proximity check)
- No schema changes needed to bids table itself

### C. `ContractRepository`
- `acceptBidAndCreateContract()` → if job is immediate, set `tracking_enabled = true` on the contract
- `completeContract()` / `terminateContract()` → set `tracking_enabled = false`
- Add `updateProviderLocation({contractId, lat, lng})` → updates `provider_lat`, `provider_lng`, `last_location_update`
- Add `subscribeToProviderLocation(contractId)` → Supabase realtime listener for contract location columns

### D. `UserRepository`
- Add `updateUserLocation({userId, lat, lng})` → updates `profiles.latitude`, `profiles.longitude`, `location_updated_at`

---

## 9. NEW SERVICES

### A. `LocationService` (new file)
- `getCurrentPosition()` → returns `Position` with permission handling
- `requestPermission()` → handles permission flow (geolocator + permission_handler)
- `startLocationStream({intervalMs})` → periodic position streaming for provider tracking
- `stopLocationStream()` → cancels the stream
- `calculateDistance(lat1, lng1, lat2, lng2)` → haversine distance in km
- `estimateTravelTime(distanceKm, avgSpeedKmh)` → for nearby-provider filtering

### B. `RouteService` (new file)
- `getRoute({providerLat, providerLng, clientLat, clientLng})` → calls Supabase Edge Function `get-route`
- Returns: route polyline (decoded to `List<LatLng>`
```

