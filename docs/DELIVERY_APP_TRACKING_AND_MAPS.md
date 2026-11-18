# Delivery Partner App — Live Location Tracking & Maps (Flutter)

Technical options and recommendations for building **live location tracking** and **map navigation** in the enterprise delivery partner app.

---

## App Flow Context

The app flow this applies to:

1. **Splash screen** → Get Started
2. **Login** with mobile number + OTP
3. **Home screen** with 3 toggles: **Pickup**, **Delivering**, **Past**
   - **Pickup** — lists orders arriving at the warehouse the delivery partner belongs to. Tapping "Pick Up" assigns the partner (tap again to unassign). "Start Journey" switches to the Delivering toggle.
   - **Delivering** — "Navigate" opens a map showing the route from warehouse to drop location. Partner marks **Arrived at Drop**, then **Mark Delivered**. After delivery, returns to Delivering toggle; "View Summary" navigates to Past.
   - **Past** — delivery history/summary.
4. **Status toggle** at top — Active (can pick up orders) / Offline.

---

## The Two Problems to Solve

1. **Live Location Tracking** — The partner's phone must keep sending its location to the server (even when the app is backgrounded or the screen is off), so the warehouse/customer can see where the order is.
2. **Map + Navigation Route** — Show a map in the app with the route drawn from the warehouse to the customer's address, and provide turn-by-turn navigation.

These are separate problems with separate tools.

---

## Part 1: Live Location Tracking

### The Hard Part

Getting location while the app is **open** is easy. The real challenge is when the partner locks the phone or switches apps — Android and iOS aggressively kill background apps to save battery. An enterprise app **must** solve this, or tracking will silently stop mid-delivery.

### Options (best first)

#### Option A: `flutter_background_geolocation` (Transistorsoft) — the enterprise choice ✅

- Industry-standard plugin built exactly for this; used by real logistics/fleet companies.
- Survives backgrounding, screen lock, and even phone reboots.
- **Battery smart** — uses motion sensors, so it tracks aggressively while moving and goes quiet when the rider stops. Critical for a full-shift workday.
- Built-in **offline handling**: if the rider enters a no-network area, locations are stored locally and synced to the server once back online.
- **Cost:** Paid for Android release builds (one-time license fee, roughly a few hundred dollars). For an enterprise app, this is money well spent — building this reliability in-house takes months.

#### Option B: `geolocator` + `flutter_foreground_task` (free, DIY)

- `geolocator` is the most popular free location plugin. Combine it with a **foreground service** (the persistent notification seen in rider apps — *"Tracking your delivery..."*).
- Works, but **you** must handle: battery optimization, OEM quirks (Xiaomi/Oppo/Vivo kill background apps aggressively), offline buffering, and retries.
- Good if budget is zero and there is time to harden it.

### Getting Location to the Server

| Method | When to use |
|---|---|
| **WebSocket / Socket.IO** | Best for true real-time. Server pushes rider location to customer app instantly. Most common choice. |
| **MQTT** | Even lighter than WebSocket; built for exactly this (low bandwidth, flaky networks). Great for enterprise fleets. |
| **Plain HTTP POST every X seconds** | Simplest, fine to start. Send a batch of points every 10–15 sec. |
| **Firebase Realtime DB / Firestore** | Fastest to build, but costs grow fast with many riders updating every few seconds. |

### When to Track

- **Start** tracking when the rider taps **"Start Journey"**.
- **Stop** when the rider taps **"Mark Delivered"** (or goes offline via the status toggle).
- Do **not** track 24/7 — it kills battery and raises privacy concerns.

---

## Part 2: Maps & Navigation Route

Two sub-questions: **which map to show**, and **who calculates the route**.

### Map Display Options

#### Option A: Google Maps (`google_maps_flutter`) — the safe enterprise default ✅

- Official Flutter plugin from Google; best road data in most countries (especially India).
- Draw the route as a **polyline** (a colored line) on the map.
- **Cost:** Pay-per-use. ~$200 free credit/month from Google; map loads + Directions API calls billed beyond that. Predictable but not free for a fleet.

#### Option B: Mapbox (`mapbox_maps_flutter`)

- Beautiful maps; dedicated **Navigation SDK** with turn-by-turn voice guidance (like Google Maps navigation *inside* your own app).
- Often cheaper than Google at scale; generous free tier.

#### Option C: OpenStreetMap via `flutter_map` (free)

- Zero map-display cost, fully open source.
- Still needs a routing service (e.g. OSRM, which can be self-hosted). More setup work; road data quality varies by region.

### Who Calculates the Route (warehouse → customer)?

The map itself doesn't know routes. Call a **Directions/Routing API**, get back the path, and draw it:

| Routing API | Pairs with |
|---|---|
| **Google Directions API** | Google Maps — live-traffic-aware ETA |
| **Mapbox Directions API** | Mapbox |
| **OSRM / OpenRouteService** | `flutter_map` — free / self-hostable |

### The Shortcut Many Delivery Apps Use 💡

When the rider taps **"Navigate"**, instead of building navigation inside the app, **launch the Google Maps app** with the destination pre-filled (via `url_launcher` or `maps_launcher`). The rider gets full turn-by-turn voice navigation for free, background tracking keeps running, and he returns to the app to tap "Arrived at Drop."

- **Pros:** Zero navigation cost, zero maintenance, riders already know Google Maps.
- **Cons:** Rider leaves the app momentarily; less "branded" experience.

You can still show the route polyline **inside** the app on the Delivering screen (looks professional), and use the external-app launch for actual turn-by-turn driving.

---

## Recommended Stack (Enterprise)

| Need | Pick |
|---|---|
| Background live tracking | `flutter_background_geolocation` (Transistorsoft) |
| Sending location to server | WebSocket (or MQTT if fleet is large) |
| Map display in app | `google_maps_flutter` |
| Route line on map | Google Directions API → draw polyline |
| Turn-by-turn navigation | Launch external Google Maps app on "Navigate" tap |
| Permissions handling | `permission_handler` (location "Allow all the time" needs careful UX) |

**Why this combo:** It's the proven stack — reliable background tracking that won't die mid-delivery, the best map data, and it avoids the heavy cost/effort of building in-app turn-by-turn navigation. Later, for a fully branded navigation experience, upgrade to Mapbox Navigation SDK without redoing the tracking layer.

---

## Compliance Note (plan early)

**Google Play requires a declaration form for background location access** — you must explain why the app needs it (delivery tracking is an accepted use case) and document it in a privacy policy. Easy to clear, but don't leave it to launch week.

iOS similarly requires `NSLocationAlwaysAndWhenInUseUsageDescription` strings in `Info.plist` with a clear user-facing justification.
