# Delivery Partner App: Pending Backend Requirements

**For:** backend team · **From:** delivery partner app (Flutter) · **Date:** 2026-11-14

Reviewed against `docs/delivery_partner_api.md` and
`docs/imart_delivery_partner_api.postman_collection.json` (changelog up to
2026-11-14 (d)).

## Summary

Thanks for the 2026-11-14 changes. The app now uses trips and stop order,
the single location endpoint (with `recorded_at`, accuracy, speed, heading),
locality, cash-summary and the earnings summary. These earlier asks are
done: one location for all active deliveries (T1), timestamp/stale points
(T2), "silence isn't offline" (T3), locality (D1), history distance and
earnings (D3), POD upload (U1), saved stop order, and both "please confirm"
questions.

What's left:

| Priority | # | Item |
|---|---|---|
| **P1** | E2 | Test orders for partner 9746863592 on `imartapp.store` |
| **P1** | R1 | Road distance for pay (`leg_km`) and ETA |
| P2 | D2 | Customer coordinates always filled in |
| P2 | N1 | Push notifications (Firebase) |
| P3 | X1–X5 | Doc / example mismatches |

---

## 1. Testing (P1)

| # | Need | Detail |
|---|---|---|
| E1 | Server | The app now points at `https://imartapp.store`, which has every endpoint it uses. As it's production, a non-production iMart server would still be safer if one exists. |
| E2 | **Test orders for 9746863592** | 2–3 `packed` test orders assigned to this partner (at least one COD and one prepaid, with customer coordinates), e.g. via `seed_partner_demo --phone 9746863592`. They must be test orders: status steps notify customers and live location shows on their map. |

E4 is resolved: OTPs are 6 digits, and the login screen now takes 6.

## 2. Distance and pay (P1)

### R1. Road distance instead of straight line

`leg_km`, `trip.total_km`, `trip.distance_km` and `eta_minutes` are all
straight-line. Since 10.x pays `per_km × (leg_km − free_km)`, riders are paid
for less than they ride (bridges, backwaters, one-way roads often add 30–60%).

**Ask:** compute `leg_km` (and ideally `trip.distance_km` / `eta_minutes`)
with a routing service on the server (OSRM self-hosted, or Google Routes
API), for the bike route. If routing fails, fall back to straight line × a
detour factor (e.g. 1.4). Keep GPS distance only as an audit check.

A road polyline and turn instructions are **not** needed; turn-by-turn
navigation happens in the Google Maps app.

## 3. Data (P2)

| # | Field | Today | Ask |
|---|---|---|---|
| D2 | `shipping_address.latitude/longitude` | Can be `null`: that stop has no map pin and Navigate has no destination | Geocode the address when it's saved, or at order confirmation |

## 4. Push notifications (P2)

### N1

- `FIREBASE_CREDENTIALS_FILE` set on the server;
- the delivery app's Firebase files (`google-services.json`,
  `GoogleService-Info.plist`) from whoever owns the Firebase project.

Until then the app checks `GET /deliveries/` every 30 s while idle.

## 5. Doc mismatches (P3)

| # | Where | Mismatch |
|---|---|---|
| X1 | 4.8 Trip history | Text says "Earnings are not included yet" and the example has no `earned` / `leg_km`, but changelog (c) says both were added. The Postman example also lacks `distance_km` and `trip_id`. |
| X2 | 9.1 / 9.2 trip objects | Changelog says `earned` and `total_km` were added; the examples don't show them. The Delivery example doesn't show `earned` either. |
| X3 | Postman "Trip detail (Trip Complete)" | Trip is `completed` with 3 delivered, but the stops still show `out_for_delivery` / `picked_up`; all 3 stops have the same customer and coordinates (same in "Current trip"). |
| X4 | `09-delivery.md` | Says partners may write only `status`, `notes`, `proof_of_delivery`; the API doc also allows `fail_reason` and `cash_collected`. |
| X5 | `09-delivery.md` | Describes only per-delivery `update_location`, not `delivery-profiles/me/location/`. |
