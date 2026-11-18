# Delivery Partner App: Pending Backend Items

Status as of 2026-11-14, against `docs/delivery_partner_api.md` and
`docs/imart_delivery_partner_api.postman_collection.json` (changelog up to
2026-11-14 (d)).

Every screen the app has today is integrated with the API (branch
`feature/api-integration`), including the 2026-11-14 additions: trips and
stop order, one location ping for all active orders, locality, Trip Complete
figures, and earnings. The app uses `https://imartapp.store` by default.

The write flow (arrange, location, status steps, COD) was tested on Android
emulator-5556 against the local mock (`postman/mocks/delivery-partner-api`).
On `imartapp.store` the app has been checked for reachability and login.

---

## 1. Needed for real testing

| # | Item | Status |
|---|---|---|
| E1 | Server with the latest API | `imartapp.store` has every endpoint the app uses (they answer 403 without a session, not 404). It is production, so only test orders should be used there. |
| E2 | Test partner account with assigned test orders (COD + prepaid, with coordinates) | Partner number 9746863592 to be used; test orders still needed. The doc's `seed_partner_demo --phone <number>` creates a 3-stop trip. |
| E3 | Receiving the OTP | Real SMS to the partner number. |
| E4 | OTP length | **6 digits** (confirmed); the login field now takes 6. |

## 2. Data the API doesn't provide yet

| # | Screen / section | Shown today | Needed from the backend |
|---|---|---|---|
| D1 | Navigation header: turn instruction | Blank | Next-turn text, or confirmation that this line stays empty |
| D3 | Distances and pay | Straight line (`trip.distance_km`, `leg_km`, `total_km`) | Road distance from a routing service, at least for `leg_km` (it drives the per-km pay) |
| D6 | Map on Navigation and Arrange Route | OpenStreetMap (development only) | Google Maps keys (Android + iOS) before release; switch `TripMapView` to `google_maps_flutter` (app config, not an endpoint) |
| D7 | Stop pin and Navigate | Falls back to 0,0 when missing | `shipping_address.latitude` / `longitude` always filled in |

Done in the 2026-11-14 API: locality (`shipping_address.locality`), distance
and earnings per day (`payouts/v1/me/earnings/summary/`), proof-of-delivery
upload (4.12).

## 3. Needed to finish features the API already has

| # | Feature | API section | Missing piece |
|---|---|---|---|
| P1 | Push notifications for new trips | 7.1 / 7.2 | Firebase project files for the app (`google-services.json`, `GoogleService-Info.plist`) and `FIREBASE_CREDENTIALS_FILE` set on the server. Until then the app checks for new trips every 30 s. |

## 4. In the API, needs a UI decision first

No backend work is needed for these.

| # | Feature | API section | Missing in the app |
|---|---|---|---|
| U1 | Proof-of-delivery photo | 4.12 `deliveries/{id}/proof/` | A camera step before "Yes, Delivered" |
| U2 | Reject an assigned order | 4.3 `status: pending` (from `assigned` or `at_pickup`) | No Reject button. Orders left at the warehouse stay assigned to the rider until the next trip. |
| U3 | Rider notes | 4.3 `notes` | No notes field; "Other" sends its label as the note |
| U4 | Warehouse address and Navigate-to-warehouse | `pickup_points` | Pickup banner shows no address or Navigate button |
| U5 | Orders split across warehouses | `pickup_points` (several) | Only the first warehouse name is used |
| U6 | Previous failed attempt on a re-sent order | `fail_reason_display`, `notes` | Not shown on the stop card |
| U7 | Items the warehouse couldn't supply | `items[].is_available` | Hidden from order contents instead of marked "unavailable" |
| U8 | Earnings detail and pay | 10.2 ledger, 10.5 payout account, 10.6 statements | No screens; only per-day "Earned" in Trip History |
| U9 | Profile photo upload | 2.5 `profile_photo_file` | Edit Profile has no photo picker |
| U10 | Edit phone number | 2.5 (read-only for partners) | Edit Profile lets the rider type a phone, but it isn't sent. Make the field read-only? |
| U11 | Vehicle type | 2.2 `vehicle_type` | One free-text "Vehicle" field (`Bike · KL07AB1234`); the API doc recommends a type picker |
| U12 | Trip stop list from `delivery-trips/current/` | 9.1 | Not needed: the app reads the same data (`trip_id`, `stop_number`) from the deliveries list |

## 5. App-side items (no backend needed)

| # | Item |
|---|---|
| A2 | Hive cache (per `docs/HIVE implementation.md`) not built yet |
| A3 | Custom lint (`naming_conventions_lint`) not run; the package isn't on this machine |

Done: the arranged stop order is saved on the server (4.13) and survives a
restart.

---

## Not needed by this app

Admin / warehouse endpoints (1.3, 1.4, 3.x, 4.5–4.7, 4.11, 5.x, 10.1, 10.3,
10.4), serviceability (6.1), COD checkout (8), email + password sign-in (1.1,
replaced by OTP), change password (2.4), single-delivery `GET` (4.2) and
per-delivery `update_location` (4.4, replaced by 2.6).
