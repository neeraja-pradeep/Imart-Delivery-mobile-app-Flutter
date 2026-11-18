# iMart Delivery — Rider App

Flutter app for iMart delivery partners: pick orders at the hub, arrange the
route, navigate stop by stop, confirm delivery (with a cash check for COD),
and manage availability / leave.

Built from the Claude Design handoff (`iMart Delivery.dc.html` + the iMart
design system). Screens run on the delivery-partner API at
`https://imartapp.store` by default (see **Backend integration**), or on
static fixture data behind the same interfaces with `USE_STATIC_DATA=true`.

## Run

```bash
flutter pub get
flutter run                     # device / emulator
flutter run -d chrome           # web
flutter test                    # unit + widget tests
```

Open any design state directly (debug / profile builds only — ignored in
release), mirroring the prototype's "Start Screen" tweak:

```bash
flutter run --dart-define=PREVIEW_SCREEN=navigation
# web debug/profile builds also accept a query param: /?preview=route
```

`PREVIEW_SCREEN`: `splash` · `login` · `loading` · `trip` · `route` ·
`navigation` · `profile` · `empty` · `error`. Demo OTP (static data) is
`123456` (the login takes a 6-digit code).

## Folder structure

Follows `docs/Folder structure - structure.csv` (feature-first, 4 layers).

```
lib/
├─ app/
│  ├─ bootstrap/app_bootstrap.dart   ProviderScope, error hooks, preview clock
│  ├─ config/                        constants (assets, timings, all UI copy),
│  │                                 env (preview / API base URL), feature_flags
│  ├─ router/                        go_router, routes, guards/auth_guard.dart
│  ├─ theme/                         colors, typography, theme (radii, shadows,
│  │                                 sizes, durations)
│  └─ app.dart                       ScreenUtil (390×844) + MaterialApp.router
├─ core/
│  ├─ widgets/                       design-system widgets (see below)
│  ├─ error/                         Failure, ErrorView (empty/error/blocked)
│  └─ utils/                         format, date/clock, map links, logger
└─ features/
   ├─ auth/             splash, login (phone → OTP)
   ├─ dashboard/        signed-in shell: tabs + bottom nav + load-error state
   ├─ trip/             pickup → arrange → navigation → complete, sheets, states
   ├─ profile/          profile, availability/leave, KPIs, edit, history
   └─ common/feedback/  app-wide loader, toast, offline banner
```

Each feature has `domain/`, `application/`, `infrastructure/`,
`presentation/{screen,components}`. Only `presentation/` is the deliverable
of this branch; the other three layers contain the minimum (entities,
repository contracts, static APIs, controllers) the UI needs to run.

## Reusable components (`lib/core/widgets`)

| Widget | Used for |
| --- | --- |
| `AppButton` | every button: primary, brand, secondary (Call/Navigate), tinted (Mark Picked Up / Optimize), danger, dangerOutline, ghost; `enabled: false` = gated grey state |
| `AppCard` | stop cards, summary, profile cards, menu rows, history rows |
| `AppTextField` | phone, OTP, edit-profile fields (outline / filled) |
| `AppBadge` | status + payment pills (green / red / amber / blue / violet) |
| `AppIcon` | all glyphs — exact SVG paths from the design |
| `AppAvatar`, `AppLogo` | rider avatar, logo lockup |
| `AppNavBar` (`navbar.dart`) | fixed labelled bottom nav |
| `AppSubHeader`, `AppBackButton` | sub-page headers (Arrange, Edit, History) |
| `AppActionBar` | sticky single-primary-action bar above the nav |
| `AppBottomSheet` | confirm-delivery and fail sheets |
| `AppStatTile`, `AppProgressBar`, `AppBulletList`, `AppDashedDivider` | metrics, progress, order contents |
| `AppPatternBackground` | vegetable texture (splash, login, complete) |
| `AppLoadingOverlay`, `AppToast`, `AppOfflineBanner` | feedback |
| `ErrorView` (`core/error`) | No Trip, Connection Lost, On Leave, Navigation Locked |

## Backend integration

The app talks to the delivery-partner API documented in
`docs/delivery_partner_api.md` (Postman collection alongside). Set the base
URL at build time; without one the app uses `https://imartapp.store`.

```bash
# iMart API (default, same as API_BASE_URL=https://imartapp.store)
flutter run

# Static fixtures, no backend (design previews)
flutter run --dart-define=USE_STATIC_DATA=true

# Local stateful mock of the API (Postman CLI), then the app on an emulator
postman mock run postman/mocks/delivery-partner-api --port 8010
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8010
# mock login: 9876500001 / OTP 123456
# mock helpers: POST /__mock/reset (reseed), POST /__mock/assign (2 more
# orders), GET /__mock/last-point (last location body, trips)
```

`USE_STATIC_DATA=true|false` overrides the choice. Plain-HTTP dev servers are
allowed in debug builds only (`android/app/src/debug/AndroidManifest.xml`).

| Layer | Where |
| --- | --- |
| HTTP client, CSRF, retries, error mapping | `core/network/` (`ApiClient`, `ApiEndpoints`, `NetworkExceptions`) |
| Session cookies (Keychain / Keystore) | `core/storage/secure_cookie_storage.dart` |
| Auth: phone + OTP, auto-login, logout | `auth/.../auth_remote_api.dart` |
| Profile + 7-day history and earnings | `profile/.../profile_remote_api.dart`, `profile_mapper.dart` |
| Trip: deliveries, stop order, status steps, fail reasons, leave, live location, Trip Complete figures | `trip/.../trip_remote_api.dart`, `delivery_mapper.dart`, `location_local_ds.dart` |

How the fixed UI maps onto the API:

- **Trip**: the server groups the rider's orders into a trip (`trip_id`,
  `stop_number`); the app shows the open trip in that order. Orders left at
  the warehouse aren't part of a started trip and come back for the next one.
- **Pickup**: picking orders is local until **Start Trip**, which saves the
  stop order (`POST /deliveries/arrange/`, orders left at the warehouse
  last), then sends `at_pickup` → `picked_up` for each chosen order and
  `out_for_delivery` for the first stop. Finishing a stop sends the next one
  out for delivery. The saved order survives an app restart.
- **Stop area**: `shipping_address.locality`, else the city.
- **Trip Complete**: distance is the trip's `total_km`
  (`GET /delivery-trips/{id}/`) and "Cash to deposit" is all COD cash the
  rider holds (`cash_in_hand`, `GET /deliveries/cash-summary/`); the app's
  own figures are used if either call fails.
- **Profile "Last 7 days" and Trip History**: per-day stops, km and earnings
  from `GET /payouts/v1/me/earnings/summary/?days=7`, falling back to
  `GET /deliveries/history/` if that fails.
- **COD**: delivered sends `cash_collected` = `order_details.amount_to_collect`.
- **Failed**: reasons come from the server; `other` sends its label as the note
  (the sheet has no text box).
- **On leave** = availability `offline`; ending leave sets `online`.
- **Vehicle**: one text field, shown as `Bike · KL07AB1234`; saving parses that
  form back into type + number, otherwise saves the text as the number.
- **Phone** is admin-managed and is not sent on Edit Profile.
- **Not provided by the API**: the turn instruction (blank; directions open
  in Google Maps). Distances and pay are straight-line, as the server
  computes them.
- Idle riders are checked for a new trip every 30 s.

### Live location tracking

- While the trip is under way, the app streams GPS through geolocator's
  Android foreground service (type `location`), shown as the "Tracking your
  delivery" notification. It keeps working with the app in the background
  (e.g. Google Maps open) or the screen off, and stops when the trip ends,
  on leave or on logout.
- Each position goes to `POST /delivery-profiles/me/location/`, which updates
  every active order of the rider, so every customer on the trip sees the
  rider, not only the next stop. It carries `recorded_at` (the fix time, so a
  late request never moves the rider backwards), and `accuracy_m`,
  `speed_mps` and `heading` when the phone reports them. If the server
  rejects the fix time (a phone clock running ahead), the app keeps sending
  points without it.
- A position is sent at most every 5 s and only after the rider moves 20 m
  (`ApiConfig.locationPingInterval`, `locationDistanceFilterMeters`), so a
  rider standing still sends nothing; the server doesn't treat silence as
  offline.
- Tracking is **required**: on **Start Trip** the app asks for location and
  notifications, and the trip only starts once location is allowed **and**
  the app may run without battery restrictions. Otherwise the **Keep
  Tracking On** sheet appears with only ways to fix it: **Allow** (Android's
  "run in background" dialog), **Open Phone Settings** (Battery →
  Unrestricted, plus Autostart on Xiaomi / Oppo / Vivo), or **Cancel** (the
  trip doesn't start). It re-checks when the rider returns from Settings and
  closes itself once everything is allowed. If either setting is turned off
  during a trip, the sheet appears again whenever the rider returns to the
  app. Notifications are asked for but not required.
- Code: `trip/.../local/location_local_ds.dart`,
  `tracking_permissions_local_ds.dart`, `tracking_setup_providers.dart`,
  `presentation/components/tracking_setup_sheet.dart`, mid-trip check in
  `dashboard/presentation/screen/home_screen.dart`.
- Release checklist: Play Console asks for a foreground-service (location)
  declaration and, because of `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, a reason
  for the battery exemption; delivery tracking is an accepted use.

### In-app map

- `TripMapView` (`trip/presentation/components/trip_map_view.dart`) draws the
  Navigation and Arrange Route maps with **OpenStreetMap** tiles via
  `flutter_map`: numbered stop pins (current stop green, finished stops grey
  ✓), the rider's live blue dot, and framing that keeps pins clear of the
  delivery panel. No API key needed.
- Straight lines show the trip order: a solid green line from the rider to
  the current stop, then a dashed line through the stops still to deliver
  (Arrange Route: one dashed line through all stops in the chosen order).
  They are not road routes; "Navigate" gives those.
- If the rider's dot leaves the visible part of the map, the map re-frames
  the rider and the current stop; otherwise it stays where the rider panned.
- **Development only.** OpenStreetMap's tile servers don't allow production
  app traffic. Before handover, switch `TripMapView` to `google_maps_flutter`
  (screens pass the same data, so only that file and `MapConfig` change),
  add the Android / iOS Maps keys, and drop the OSM credit.
- "Navigate" still opens the Google Maps app for turn-by-turn directions.

## Design QA

Every state was compared pixel-by-pixel against the HTML prototype (Chromium,
390×844 @2x, clock pinned, maps stubbed, the prototype's fake status bar
masked): 29 scenarios, 0.4 %–3.4 % differing pixels. The residue is text
anti-aliasing / sub-pixel line rounding between Chrome and Flutter plus the
prototype's rounded phone-frame corners.

Intentional differences from the prototype:

- The prototype's fake "9:41" status bar and phone bezel are not drawn — the
  OS status bar is used, with icon colour set per screen.
- Single-order trips show the "Starting navigation…" loader (the trip-start
  API call); the prototype skipped it.
- Trip History still shows "Earned" amounts, exactly as in the design, even
  though the profile KPIs were made non-monetary — product decision pending.
