# iMart Delivery — Rider App

Flutter app for iMart delivery partners: pick orders at the hub, arrange the
route, navigate stop by stop, confirm delivery (with a cash check for COD),
and manage availability / leave.

This branch delivers the **presentation layer**, built from the Claude Design
handoff (`iMart Delivery.dc.html` + the iMart design system). All screens run
on **static fixture data** behind the same interfaces the real API will
implement, so wiring the backend does not touch any widget.

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
`navigation` · `profile` · `empty` · `error`. Demo OTP is `1234`.

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

## Replacing static data with the API

Static data lives only in `infrastructure/data_sources/remote/*_static_api.dart`.
Each implements the feature's `*Api` interface (endpoints documented on the
interface). To integrate, add a Dio-backed class implementing the same
interface and return it from the provider — one line per feature:

| Feature | Swap point | Interface |
| --- | --- | --- |
| Trip | `tripApiProvider` (`trip/application/providers/trip_providers.dart`) | `TripApi` |
| Auth | `authApiProvider` (`auth/application/providers/auth_providers.dart`) | `AuthApi` |
| Profile | `profileApiProvider` (`profile/application/providers/profile_providers.dart`) | `ProfileApi` |

The trip phase is derived from server statuses (any `outForDelivery` →
navigating, all terminal → complete), so a resumed trip lands on the right
screen. Turn off the demo OTP hint with
`--dart-define=SHOW_DEMO_OTP_HINT=false` once real OTP is live. The map embed
URL in `core/utils/map_links.dart` must move to the Maps Embed API with a
restricted key.

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
