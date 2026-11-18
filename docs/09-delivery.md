# 09 — Delivery

## Models

- **`DeliveryProfile`** — `OneToOne(User)` for a `delivery`-role user:
  `vehicle_type ∈ {bike, scooter, electric_bike, electric_scooter, cycle}`,
  `vehicle_number`, last-known `latitude`/`longitude`,
  `availability_status ∈ {offline, online, on_delivery}`, and an optional
  `warehouse` scope. Table `delivery_profiles`.
- **`Delivery`** — one job per order (`uniq_delivery_per_order`, audit L7b).
  `status ∈ {pending, assigned, at_pickup, picked_up, out_for_delivery,
  delivered, failed}`, `delivery_fee`, `assigned_at`, `picked_up_at`,
  `delivered_at`, `proof_of_delivery`, `notes`, `fail_reason`, and the COD
  cash trail `cash_collected` / `cash_collected_at` / `cash_deposited_at` /
  `cash_deposited_by` / `cash_deposit_reference`. Table `deliveries`.
- **`DeliveryAttempt`** — append-only, one row per finished attempt
  (`outcome ∈ {delivered, failed}`) with the partner who made it, `fail_reason`,
  notes and cash. Survives re-dispatch (the `Delivery` row moves to the next
  partner), so it backs the partner's trip history. Table `delivery_attempts`.
- **`ServiceablePincode`** — pincode, locality, `eta_minutes` (default 20),
  `is_active`. Backs the "Delivery available · ETA 20 min" line on the
  add-address form. Distinct from `inventory.WarehouseServiceablePincode`, which
  does order routing.

A `Delivery(status="pending")` row is created automatically the moment an order
is confirmed — in `PaymentService.verify_payment`, and in the branch of
`initiate_payment` that confirms ₹0 free orders and cash-on-delivery orders.

### Cash on delivery

`Order.payment_method ∈ {prepaid, cod}`. COD is chosen at
`POST /api/order/v1/checkout/` (`payment_method: "cod"`), gated by
`COD_ENABLED` and `COD_MAX_ORDER_AMOUNT` (`orders.services.cod_unavailable_reason`),
and confirmed immediately: stock is committed exactly like a paid order.

- `Order.amount_to_collect()` = total − value of unsupplied units (never < 0);
  `0` for prepaid. The partner must report exactly this as `cash_collected` to
  complete a COD delivery (`delivery.services.cod_collection_error`; also a
  backstop inside `mark_order_and_delivery_delivered`).
- `failed` + `fail_reason=customer_refused` on a COD order →
  `orders.services.cancel_order_after_cod_refusal` (cancel + restock), instead
  of the usual revert to `packed`.
- Cancelling a confirmed COD (or ₹0) order restocks from the lines.
- Collected cash is reconciled through `deliveries/cash-summary/` and the admin
  `deliveries/cash-deposits/`. COD refunds are manual (admin refund drawer).

## Lifecycle

```
order confirmed ──> Delivery(pending)
        │
   assign partner ──> Delivery(assigned), assigned_at,  profile → on_delivery
        │
   partner updates ──> at_pickup ──> picked_up ──> out_for_delivery
        │                                         + Order packed → out_for_delivery
   delivered ──> Delivery(delivered) + delivered_at + Order(delivered)
                 + profile → online
   failed    ──> Delivery(failed) + Order out_for_delivery → packed
                 + profile → online   (re-assign to re-dispatch)
```

The two status machines are kept in step from either side
(`orders.services.mark_order_out_for_delivery`,
`revert_order_after_failed_delivery`, `mark_order_and_delivery_delivered`):
a partner's delivery update moves the order, and the order-side
`out-for-delivery` / `mark-delivered` actions move the delivery. Delivery
`out_for_delivery` is refused unless the order is `packed`.

Partners may write only `status`, `notes` and `proof_of_delivery` on their own
delivery; `order` is immutable for everyone after creation.

### Assignment rules

Driven from the order side
(`POST /api/order/v1/orders/{id}/assign-delivery-partner/`,
`IsAdminOrWarehouseStaff`) — see [05](05-orders-and-fulfilment.md). An admin
`PATCH/PUT /deliveries/{id}/` that changes `delivery_partner` applies the same
rules: both paths call `delivery.services.partner_assignment_error`,
`occupy_partner` and `free_partner`.

- Locked once the order is `out_for_delivery | delivered | cancelled | failed`.
- **L7a** — a partner whose `DeliveryProfile.warehouse` is set may only take
  orders allocated to that warehouse. Partners with no profile, or a profile with
  no warehouse, remain manually assignable. Orders with no warehouse-stamped
  lines (legacy data) skip the check.
- **H7** — only an `online` partner is assignable. Re-assigning the partner who
  already holds the order is idempotent. Assignment flips the profile to
  `on_delivery`; unassigning or replacing frees the previous partner back to
  `online`.
- The partner can't be swapped or removed once the delivery is `picked_up` or later
  (re-sending the same partner is an idempotent no-op).
- `Order.out_for_delivery` returns **400** unless a `Delivery` with a partner exists.
- The order-side `out-for-delivery` and `mark-delivered` actions are restricted,
  for the `delivery` role, to the partner assigned to that order (403 otherwise).
- `delivery-candidates` lists partners scoped to the order's warehouse(s) plus
  delivery users with **no profile**; partners pinned to another warehouse are
  excluded.
- Partners control only the `online`/`offline` toggle on `/me/`: it needs a
  vehicle, can't be changed while a job is active, and `on_delivery` is
  server-managed. `user` and `warehouse` are admin-only.

### Delivered is synchronised (audit H5, H8)

`orders.services.mark_order_and_delivery_delivered(order, changed_by, note,
skip_delivery_id)` is the single source of truth. Whichever side marks first,
both records move: the order goes `delivered` with an `OrderStatusHistory` row,
every linked `Delivery` gets `status="delivered"` and `delivered_at`, and any
partner still `on_delivery` returns to `online`.

It refuses any source status other than `out_for_delivery` or `delivered`
(idempotent), so a partner's delivery update can no longer jump an order from
`packed` straight to `delivered`. `skip_delivery_id` lets the delivery-side
caller exclude the row its own serializer is already saving.

## Endpoints (`/api/delivery/v1/`)

| Method | Path | Permission |
|---|---|---|
| — | `delivery-profiles/` | list/retrieve: authenticated (own profile unless admin); create/update/destroy: `IsAdmin` |
| `GET/PUT/PATCH` | `delivery-profiles/me/` | `IsDelivery` — own profile |
| `POST` | `delivery-profiles/change-password/` | `IsDelivery` |
| — | `deliveries/` | `DeliveryViewSet` — list/retrieve (admin & warehouse: all; partner: assigned; customer: own orders), create/destroy `IsAdmin`, update `IsAdminOrAssignedDeliveryPartner` with `_validate_status_transition` |
| `POST` | `deliveries/{id}/update_location/` | `IsDelivery` — assigned partner only |
| `GET` | `deliveries/history/?days=` | partner (own) / admin (`partner_id`) — from `DeliveryAttempt` |
| `GET` | `deliveries/fail-reasons/` | authenticated |
| `GET` | `deliveries/cash-summary/` | partner (own) / admin |
| `POST` | `deliveries/cash-deposits/` | `IsAdmin` |
| `GET` | `serviceability/?pincode=` | `AllowAny` — serviceable / locality / ETA |
| `GET` | `test-live-location/` | dev template |

`DeliveryViewSet.get_queryset` scopes by role; `get_permissions` varies per
action. Status changes go through `_validate_status_transition(old, new, user,
delivery)`; `delivery.services.free_partner` returns the partner to `online` when a job ends (only if they hold no other active job).

## Live location tracking

`POST /api/delivery/v1/deliveries/{id}/update_location/`

Guards: caller must be the assigned partner (403 otherwise); delivery status must
be `at_pickup | picked_up | out_for_delivery`; `latitude`/`longitude` required
and numeric.

Three-tier write strategy:

1. **Redis cache (primary)** — `delivery_location_{id}`, TTL 1h, the full payload
   (`delivery_id`, lat, lon, timestamp, `user_id`, `order_id`, `partner_name`).
   Sub-millisecond, and what reads serve.
2. **DB (periodic)** — `DeliveryProfile.latitude/longitude` is persisted only
   every **10th** update, tracked by `delivery_location_update_count_{id}`.
3. **Stream (broadcast)** — `enqueue_location(...)` does a single fire-and-forget
   `XADD` onto the Redis stream `delivery:locations`.

The response echoes the cached location plus a `storage` block describing the
persistence cadence.

### The coalescing consumer

`grocery_application/delivery_location_stream.py`:

- **Producer** (sync, called from the DRF view): one `XADD` on
  `delivery:locations`, `maxlen≈10000` approximate. No event loop, no
  `async_to_sync`, ~0.2 ms. Failure only degrades realtime — the location is
  already cached.
- **Consumer** (async, started by the ASGI **lifespan** hook in the socketio
  process): `start_location_consumer(sio)` reads via `XREADGROUP`
  (group `socketio-emitters`, block 2000 ms, batch 200), keeps only the **latest
  payload per `delivery_id`** in memory, and flushes to Socket.IO rooms once per
  `FLUSH_INTERVAL_S = 1.0`.

Net effect: a 5 Hz GPS ping rate becomes 1 Hz on the wire. Intermediate pings are
dropped by design.

Clients watch a delivery room over Socket.IO; joining is authorised by
`_can_access_delivery` — the order's customer, the assigned partner, or an admin.
See [12 — Realtime](12-realtime.md).

## Partner app login and push

- Phone + OTP: `POST /api/auth/v1/delivery/otp/send/` and `.../otp/verify/`
  (`accounts.views.DeliveryPartnerOTP*View`). Same provider as customer login
  (`core.otp_utils`), restricted to active `delivery`-role users, numbers
  normalised to `+91XXXXXXXXXX` (`accounts.phone`), resend cooldown
  (`DELIVERY_OTP_RESEND_COOLDOWN_SECONDS`) and a wrong-attempt cap
  (`DELIVERY_OTP_MAX_ATTEMPTS`), both in the cache.
- Push: `notifications.DeviceToken` + `POST/DELETE /api/notifications/v1/devices/`;
  the `push` channel (`notifications/push.py`, `firebase-admin`) is on for the
  partner notification types and is a no-op until `FIREBASE_CREDENTIALS_FILE`
  is set. Dead tokens are pruned on send.
- Delivery payload extras: `pickup_points` and a straight-line `trip`
  (`delivery.services.pickup_points` / `trip_estimate`, speed
  `DELIVERY_AVG_SPEED_KMPH`).

## Trips (multi-order)

A partner may hold up to `DELIVERY_MAX_ACTIVE_ORDERS` (default 3) active
deliveries, grouped in a `DeliveryTrip` (`delivery_trips`).

- **Assignment rule** (`delivery.services.partner_assignment_error`, shared by
  both assign paths and the candidates list): not `offline`; fewer than the cap
  active; and none of them `picked_up` / `out_for_delivery` (orders are added
  only before the rider leaves the warehouse). Re-assigning the partner who
  still holds the active job is idempotent; a failed stop re-dispatched to the
  same rider is a new assignment.
- **Membership**: `reassign_trip` → `attach_to_trip` (open trip or a new one,
  `sequence = last + 1`, partner's profile row locked) / `detach_from_trip`
  (reject, unassign, re-dispatch; renumbers). `mark_trip_departed` on the first
  pickup. `free_partner` closes the trip when no active stop is left (an empty
  trip is deleted). `DeliveryAttempt.trip` keeps a failed, re-dispatched stop in
  its original trip.
- **Endpoints**: `delivery-trips/` (list / detail / `current/`),
  `deliveries/arrange/` (partner sets stop order),
  `delivery-profiles/me/location/` (one ping published to every active
  delivery via `delivery.services.publish_location`, which also backs
  `update_location` and drops points with an older `recorded_at`).
- **Customer view**: `stops_ahead` on the delivery payload; `trip_id` /
  `stop_number` are hidden from customers.
- Migration `0013` groups any in-flight deliveries into one open trip per
  partner.
- Staging fixture: `python manage.py seed_partner_demo --phone <number>`.
