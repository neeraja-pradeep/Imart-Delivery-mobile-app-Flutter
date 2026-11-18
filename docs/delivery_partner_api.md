# iMart: Delivery Partner API

This covers:
- everything the **delivery-partner app** calls;
- the **admin / warehouse** endpoints that create partners, scope them, and assign them to orders.

Companion Postman collection: `imart_delivery_partner_api.postman_collection.json` (same folder).

Every example on this page was captured from the dev server on 2026-11-13, after the delivery-partner fixes landed. IDs and timestamps will differ in your environment.

---

## Conventions

### Base URL

| Env | Base URL |
|---|---|
| Dev (docker) | `http://localhost:8010` |
| Prod | `https://<api-host>` |

### Authentication: session cookie + CSRF

There are no bearer tokens. Auth uses a Django **session cookie**.

1. Sign in:
   - partners: `POST /api/auth/v1/delivery/signin/`
   - admin / warehouse staff: `POST /api/auth/v1/signin/`

   The response sets two cookies: `sessionid` and `csrftoken`.
2. Send both cookies on every later request. Mobile clients need a cookie jar, for example `dio_cookie_manager` with a persistent `CookieJar`.
3. Every **mutating** request (`POST`, `PUT`, `PATCH`, `DELETE`) must also send:
   - `X-CSRFToken: <value of the csrftoken cookie>`
   - `Referer: <base URL>/`, but only over HTTPS. Django's CSRF check rejects HTTPS requests that have no matching Referer.
4. Sign-in is CSRF-exempt. Every other mutating endpoint returns `403 {"detail": "CSRF Failed: CSRF token missing."}` if the header is missing.
5. Signing in rotates the CSRF token. Always re-read `csrftoken` from the cookie jar after signing in.

Standard headers used below:

| Name | Value | When |
|---|---|---|
| `Cookie` | `sessionid=…; csrftoken=…` | every authenticated call (the cookie jar adds it) |
| `X-CSRFToken` | value of the `csrftoken` cookie | every POST / PUT / PATCH / DELETE except sign-in |
| `Content-Type` | `application/json` | every request with a body |

> **Dev only:** when `DEBUG=True`, a `dev: <user_id>` header impersonates that user and skips CSRF. Never rely on it in app code.

### Common errors (apply to every endpoint)

| Code | When | Body |
|---|---|---|
| 403 | Not signed in (session auth returns 403, **not** 401) | `{"detail": "Authentication credentials were not provided."}` |
| 403 | Missing or invalid CSRF header | `{"detail": "CSRF Failed: CSRF token missing."}` |
| 403 | Wrong role | `{"detail": "<permission message>"}`, e.g. `"You must be a delivery person to access this resource."` |
| 404 | ID not found **or not visible to you** (results are scoped by role) | `{"detail": "No Delivery matches the given query."}` |
| 429 | Throttled. Throttling is currently **disabled** (all rates `None`). | `{"detail": "Request was throttled. Expected available in N seconds."}` |

Validation errors use DRF's shape: `{"<field>": ["message", …]}` or `{"<field>": "message"}`. Check the field name, not the exact text.

### Pagination

List endpoints use DRF `PageNumberPagination`: 25 items per page, selected with `?page=N`. Clients can't change the page size.

```json
{ "count": 42, "next": "http://…/?page=2", "previous": null, "results": [ … ] }
```

A page number past the end returns `404 {"detail": "Invalid page."}`.

### Timestamps

ISO-8601. Model fields come back in IST (`+05:30`). A few computed fields come back in UTC (`Z` / `+00:00`):
- `status_changed_at`
- the location `timestamp`
- `assigned_at` in the assign response

Always parse with an offset-aware parser.

### Delivery lifecycle and order sync

```
                 (admin / warehouse assigns)
pending ─────────────────────────────────────> assigned
assigned ──(partner accepts)──> at_pickup ──> picked_up ──> out_for_delivery ──> delivered
                                                                         └──> failed
assigned / at_pickup ──(partner rejects)──> pending   (partner removed and freed)
failed ──(admin / warehouse re-assigns)──> assigned   (re-dispatch)
```

The **delivery** and the **order** move together. The app only needs to update the delivery.

| Delivery change | What happens to the order |
|---|---|
| → `out_for_delivery` | Order `packed` → `out_for_delivery`, with a history row and the customer notification. Refused with 400 if the order isn't `packed` yet. |
| → `delivered` | Order → `delivered`. |
| → `failed` | Order `out_for_delivery` → `packed`, so ops can re-assign. Ops get an "unassigned order" alert. |

Calling the order endpoints [5.3](#53-mark-order-out-for-delivery) / [5.4](#54-mark-order-delivered) instead also moves the delivery.

Partner availability (`DeliveryProfile.availability_status`):

| Value | Meaning |
|---|---|
| `offline` | Can't be assigned. |
| `online` | Can be assigned. Requires `vehicle_type` and `vehicle_number`. |
| `on_delivery` | Holding at least one active order. Set by the server on assignment, and cleared when the last active order ends (delivered, failed, rejected, unassigned or deleted). The partner can't set it, and can't toggle online/offline while any order is active. **Still assignable** within the trip rules below. |

### Trips: several orders per partner

A partner can carry up to **3** orders at once (server setting `DELIVERY_MAX_ACTIVE_ORDERS`). These orders form a **trip**:

- **Opening:** a trip opens with the partner's first assignment. Later assignments join it as the next stop.
- **Adding orders:** new orders can be added only **while the partner is still at the warehouse**. Once any order in the trip is `picked_up` or `out_for_delivery`, the partner gets no new orders until the trip ends.
- **Each order moves on its own:** every order in the trip goes through the normal status steps (above) independently. Pick up each one, mark each one out for delivery, deliver or fail each one.
- **Rejecting:** a rejected order leaves the trip, and the remaining stops are renumbered.
- **Stop order:** the partner sets it with [4.13](#413-arrange-trip-stops). The default is assignment order.
- **Closing:** the trip closes when its last active order ends. The partner then goes back to `online`.
- **Failed stops:** a failed order that's re-dispatched leaves this trip for the new assignment, but stays listed in this trip's history (`reassigned: true`).
- **Customers on the trip:** they see `stops_ahead` ("Rider is delivering 1 order before yours"). One location ping ([2.6](#26-send-my-location-all-active-orders)) updates every one of them.

`ui_stage` groups the statuses for the tracking UI:

| `ui_stage` | Statuses |
|---|---|
| `accepted` | `pending`, `assigned` |
| `pickup` | `at_pickup`, `picked_up` |
| `on_the_way` | `out_for_delivery` |
| `completed` | `delivered`, `failed` |

---

## Reference objects

### `DeliveryProfile` object

```json
{
  "id": 22,
  "user": 58,
  "username": "ravi.k",
  "email": "ravi.k@example.com",
  "vehicle_type": "bike",
  "vehicle_number": "KL07AB1234",
  "latitude": "9.931233",
  "longitude": "76.267304",
  "availability_status": "online",
  "warehouse": 14,
  "created_at": "2026-11-13T12:06:11.257412+05:30",
  "updated_at": "2026-11-13T12:06:12.904311+05:30"
}
```

| Field | Type | Notes |
|---|---|---|
| `vehicle_type` | enum or `""` | `bike`, `scooter`, `electric_bike`, `electric_scooter`, `cycle`. `""` means not set yet. |
| `vehicle_number` | string | `""` means not set yet. |
| `latitude`, `longitude` | decimal string or null | Last saved position. Written by [4.4](#44-push-live-location) on the 1st, 11th, 21st… ping. Read-only for partners. |
| `availability_status` | enum | `offline`, `online`, `on_delivery` (see above) |
| `warehouse` | int or null | Warehouse the partner serves. `null` = unscoped, can be assigned any order. **Only admins can change it.** |
| `user` | int | **Only admins can change it.** |

### `Delivery` object

```json
{
  "id": 16,
  "order": 50,
  "order_details": {
    "id": 50,
    "user": { "id": 53, "first_name": "Anita", "last_name": "M", "phone_number": "9000000001" },
    "shipping_address": { "id": 11, "first_name": "Anita", "last_name": "M", "street_address1": "12 MG Road", "street_address2": null, "landmark": "Near metro", "city": "Kochi", "state": "KL", "postal_code": "682001", "country": "IN", "latitude": "9.93", "longitude": "76.26", "address_type": "home", "selected": false, "created_at": "…", "updated_at": "…", "locality": "Ernakulam" },
    "billing_address": { "…": "same shape as shipping_address" },
    "latitude": null,
    "longitude": null,
    "status": "packed",
    "total": "500.00",
    "payment_mode": "cod",
    "amount_to_collect": "500.00",
    "created_at": "2026-11-13T12:06:08.904426+05:30",
    "updated_at": "2026-11-13T12:06:08.904443+05:30"
  },
  "items": [
    { "id": 42, "product_name": "Tomato", "variant_name": "1 kg", "sku": "TOM-1KG", "quantity": 2, "fulfilled_quantity": 2, "is_available": true }
  ],
  "delivery_partner": 58,
  "delivery_partner_details": { "id": 58, "username": "ravi.k", "first_name": "Ravi", "last_name": "Kumar", "phone_number": "9876500001", "role": "delivery", "created_at": "…" },
  "delivery_partner_profile": { "…": "DeliveryProfile object (without email for non-admins)" },
  "status": "assigned",
  "ui_stage": "accepted",
  "item_count": 2,
  "status_changed_at": "2026-11-13T06:36:12.900953+00:00",
  "delivery_fee": "0.00",
  "assigned_at": "2026-11-13T12:06:12.900953+05:30",
  "picked_up_at": null,
  "delivered_at": null,
  "proof_of_delivery": null,
  "notes": null,
  "pickup_points": [
    { "id": 14, "name": "Kochi Central", "address": "12 MG Road, Kochi, 682001", "latitude": 9.9312, "longitude": 76.2673 }
  ],
  "trip": { "distance_km": 4.7, "eta_minutes": 15, "method": "straight_line" },
  "trip_id": 9,
  "stop_number": 2,
  "stops_ahead": 1,
  "fail_reason": "",
  "fail_reason_display": "",
  "cash_collected": null,
  "cash_collected_at": null,
  "cash_deposited_at": null,
  "cash_deposit_reference": "",
  "created_at": "2026-11-13T12:06:12.890769+05:30",
  "updated_at": "2026-11-13T12:06:12.904352+05:30"
}
```

| Field | Notes |
|---|---|
| `order_details` | Order summary only. Gateway / refund fields are **not** included. `user` is the customer's name and phone, for calling on arrival. |
| `order_details.payment_mode` | `"prepaid"` or `"cod"`. Show the COD badge and the cash checkbox only for `"cod"`. |
| `order_details.amount_to_collect` | Cash to collect at the door. `"0.00"` for prepaid. For COD it is the total minus the value of any items the warehouse couldn't supply, so always show this, not `total`. |
| `pickup_points` | Warehouses to collect from. Usually one; an order split across warehouses lists each. Coordinates can be `null`. |
| `shipping_address.locality` | Area name for display: the pincode's locality (e.g. "Panampilly Nagar"), else the address's landmark or second line, else `null`. |
| `trip_id`, `stop_number` | The trip this order is in and its position in the partner's order (both `null` when unassigned). Hidden from customers. |
| `stops_ahead` | Active stops before this one in the trip (`0` = next). `null` once finished or unassigned. Customers see this one. |
| `trip` | Not the trip record (that's `trip_id`); kept for compatibility. Straight-line warehouse → customer distance and an ETA at an average speed (server setting, default 20 km/h). Both are `null` when either end has no coordinates. |
| `fail_reason`, `fail_reason_display` | Code and label of why the last attempt failed; `""` otherwise. Codes come from [4.9](#49-fail-reasons). |
| `cash_collected`, `cash_collected_at` | Set when a COD delivery is completed. |
| `cash_deposited_at`, `cash_deposit_reference` | Set when an admin records the hand-over ([4.11](#411-mark-cod-cash-deposited-admin)). |
| `items` | The pick list: one row per order line. |
| `item_count` | Total units across all lines. |
| `delivery_partner_details`, `delivery_partner_profile` | Both are `null` when nobody is assigned. The keys are always present. `email` appears only for admins. |
| `status_changed_at` | Best-effort time the current status was set (UTC). |
| Read-only | `id`, `assigned_at`, `picked_up_at`, `delivered_at`, `cash_collected_at`, `cash_deposited_at`, `cash_deposit_reference`, `created_at`, `updated_at`. The server stamps the timestamps on each transition. |
| Partner-writable | Only `status`, `notes`, `proof_of_delivery`, plus `fail_reason` (with `status: failed`) and `cash_collected` (with `status: delivered`). |

---

## 1. Auth

### 1.1 Delivery partner sign-in

- **Name / purpose:** Sign a delivery partner in and start a session. Accounts that aren't delivery partners are rejected.
- **Method + path:** `POST /api/auth/v1/delivery/signin/`
- **Headers:** `Content-Type: application/json`. No auth and no CSRF (exempt).
- **Path / query params:** none
- **Request body:**
  ```json
  { "email": "ravi.k@example.com", "password": "Passw0rd!QA" }
  ```
- **Success response:** `200 OK`, sets the `sessionid` and `csrftoken` cookies.
  ```json
  {
    "message": "Delivery partner login successful",
    "user": { "id": 58, "username": "ravi.k", "email": "ravi.k@example.com", "first_name": "Ravi", "last_name": "Kumar", "phone_number": "9876500001", "role": "delivery", "created_at": "2026-11-13T12:06:11.251202+05:30" }
  }
  ```
- **Error responses:**
  - `400` missing / invalid fields: `{"email": ["This field is required."]}`
  - `401` wrong email or password: `{"error": "Invalid credentials"}`
  - `401` account isn't a delivery partner: `{"error": "User is not a delivery partner"}`
- **Pagination:** none

### 1.1a Delivery partner OTP login: send code

- **Name / purpose:** Step 1 of phone + OTP login for the partner app. Same SMS provider as customer login, but only numbers registered to an active delivery partner get a code. Partner accounts are created by an admin ([1.3](#13-register-a-delivery-partner-admin)).
- **Method + path:** `POST /api/auth/v1/delivery/otp/send/`
- **Headers:** `Content-Type: application/json`. No auth and no CSRF (exempt).
- **Path / query params:** none
- **Request body:** any of `9876500001`, `+919876500001`, `+91 98765 00001`, `09876500001` is accepted.
  ```json
  { "phone_number": "9876500001" }
  ```
- **Success response:** `200 OK`. `phone_number` is the normalised form; send it back unchanged in step 2. Disable "Resend" for `resend_after_seconds`.
  ```json
  { "message": "OTP sent successfully", "phone_number": "+919876500001", "resend_after_seconds": 30, "expires_in_seconds": 600 }
  ```
- **Error responses:** every error has a machine-readable `code`.
  - `400` `{"error": "Enter a valid 10-digit mobile number.", "code": "invalid_phone"}`
  - `403` `{"error": "This number is not registered as a delivery partner. Please contact your admin.", "code": "not_a_partner"}`
  - `403` `{"error": "Your account is disabled. Please contact your admin.", "code": "account_disabled"}`
  - `409` `{"error": "More than one partner account uses this number. Please contact your admin.", "code": "duplicate_phone"}`
  - `429` `{"error": "Please wait before requesting another OTP.", "code": "resend_too_soon", "retry_after_seconds": 24}`
  - `429` request throttle (too many auth calls)
  - `503` `{"error": "Failed to send OTP. Please try again.", "code": "otp_service_unavailable"}`
- **Pagination:** none

### 1.1b Delivery partner OTP login: verify code

- **Name / purpose:** Step 2. Verifies the code and starts the session, exactly like [1.1](#11-delivery-partner-sign-in). Also returns the partner's profile, so the app has the name, phone and vehicle after a restart without another call.
- **Method + path:** `POST /api/auth/v1/delivery/otp/verify/`
- **Headers:** `Content-Type: application/json`. No auth and no CSRF (exempt).
- **Path / query params:** none
- **Request body:** the code length is set by the SMS provider; the server accepts 4–6 digits.
  ```json
  { "phone_number": "+919876500001", "otp_code": "4821" }
  ```
- **Success response:** `200 OK`, sets the `sessionid` and `csrftoken` cookies. `profile` is `null` if the admin hasn't created one.
  ```json
  {
    "message": "Delivery partner login successful",
    "user": { "id": 58, "username": "ravi.k", "email": "ravi.k@example.com", "first_name": "Ravi", "last_name": "Kumar", "phone_number": "+919876500001", "role": "delivery", "created_at": "…" },
    "profile": { "id": 7, "user": 58, "username": "ravi.k", "vehicle_type": "bike", "vehicle_number": "KL07AB1234", "latitude": null, "longitude": null, "availability_status": "offline", "warehouse": 14, "created_at": "…", "updated_at": "…" }
  }
  ```
- **Error responses:**
  - `400` `{"error": "Enter a valid 10-digit mobile number.", "code": "invalid_phone"}`
  - `400` `{"error": "Enter the OTP you received.", "code": "invalid_otp_format"}`
  - `401` `{"error": "Incorrect OTP.", "code": "invalid_otp", "attempts_remaining": 4}`
  - `401` `{"error": "This OTP has expired. Request a new one.", "code": "otp_expired"}` (codes are valid for 10 minutes)
  - `429` `{"error": "Too many wrong attempts. Request a new OTP.", "code": "too_many_attempts"}` (after 5 wrong codes; a new code from 1.1a resets the count)
  - `403` `not_a_partner` / `account_disabled`, `409` `duplicate_phone`, `503` `otp_service_unavailable` as in 1.1a
- **Pagination:** none

### 1.2 Logout

- **Name / purpose:** End the session.
- **Method + path:** `POST /api/auth/v1/logout/`
- **Headers:** session cookie, `X-CSRFToken`
- **Path / query params:** none
- **Request body:** `{}`
- **Success response:** `200 OK`
  ```json
  { "message": "Logout successful" }
  ```
- **Error responses:**
  - `403` not signed in: `{"detail": "Authentication credentials were not provided."}`
- **Pagination:** none

### 1.3 Register a delivery partner (admin)

- **Name / purpose:** Admin creates a `delivery`-role user. A `DeliveryProfile` (status `offline`) is created with it. Vehicle and warehouse can be set in the same call. If they're left out, the partner must add the vehicle via [2.2](#22-update-my-profile-vehicle) before going online.
- **Method + path:** `POST /api/auth/v1/delivery/register/`
- **Headers:** admin session cookie, `X-CSRFToken`, `Content-Type: application/json`. Use `multipart/form-data` instead when sending `profile_photo_file`.
- **Path / query params:** none
- **Request body:**

  Required: `username`, `email`, `first_name`, `last_name`, `phone_number`.
  - `phone_number`: the number the partner logs in with by OTP. Any common format is accepted (`9876500001`, `+91 98765 00001`, `09876500001`); it's stored as `+919876500001`. It must not belong to any other account.

  Optional:
  - `password` + `password_confirm`: only needed if the partner should also be able to use email + password sign-in (1.1). Without them the account is OTP-only. When sent, `password` must pass the server's password rules: at least 8 characters, not too common, not entirely numeric, not too similar to the username or email.
  - `vehicle_type`, `vehicle_number`, `warehouse` (warehouse ID), `profile_photo_file` (image, multipart only).

  ```json
  {
    "username": "ravi.k",
    "email": "ravi.k@example.com",
    "password": "Passw0rd!QA",
    "password_confirm": "Passw0rd!QA",
    "first_name": "Ravi",
    "last_name": "Kumar",
    "phone_number": "9876500001",
    "vehicle_type": "scooter",
    "vehicle_number": "KL07CD5678",
    "warehouse": 14
  }
  ```
- **Success response:** `201 Created`
  ```json
  {
    "message": "Delivery partner registered successfully and DeliveryProfile created",
    "user": { "id": 58, "username": "ravi.k", "email": "ravi.k@example.com", "first_name": "Ravi", "last_name": "Kumar", "phone_number": "+919876500001", "role": "delivery", "created_at": "2026-11-13T12:06:11.251202+05:30" }
  }
  ```
- **Error responses:**
  - `400` missing / bad phone: `{"phone_number": ["This field is required."]}`, `{"phone_number": ["Enter a valid 10-digit mobile number."]}`
  - `400` phone in use: `{"phone_number": ["This mobile number is already used by another account."]}`
  - `400` weak password: `{"password": ["This password is too short. It must contain at least 8 characters.", "This password is too common.", "This password is entirely numeric."]}`
  - `400` passwords don't match: `{"password": ["Password fields didn't match."]}`
  - `400` duplicate account: `{"username": ["A user with that username already exists."], "email": ["user with this email already exists."]}`
  - `400` bad vehicle / warehouse: `{"vehicle_type": ["\"plane\" is not a valid choice."]}`, `{"warehouse": ["Invalid pk \"999\" - object does not exist."]}`
  - `403` not admin: `{"detail": "You must be an admin to access this resource."}`
  - `403` no CSRF header: `{"detail": "CSRF Failed: CSRF token missing."}`
- **Pagination:** none

### 1.4 Manage delivery partners (admin)

- **Name / purpose:** The admin panel's partner list and edit screen. It lists, adds and edits partners' personal details, and deactivates them. Vehicle, warehouse and availability are edited on the delivery profile ([3.4](#34-update-a-profile-admin)).
- **Method + path:**
  - `GET /api/auth/v1/admin-delivery-partners/` (list)
  - `GET /api/auth/v1/admin-delivery-partners/{id}/`
  - `POST /api/auth/v1/admin-delivery-partners/` (create; same body and rules as 1.3; returns the row shape below)
  - `PATCH /api/auth/v1/admin-delivery-partners/{id}/`
  - No `DELETE`: deactivate instead.
- **Headers:** admin session cookie; `X-CSRFToken` and `Content-Type: application/json` for POST / PATCH
- **Path / query params:** `id` (user ID). List filters:

  | Param | Example |
  |---|---|
  | `search` | name, username, email or phone |
  | `is_active` | `true` / `false` |
  | `warehouse` | `14` |
  | `availability_status` | `offline`, `online`, `on_delivery` |
  | `ordering` | `created_at`, `-created_at`, `first_name`, `username` |
  | `page` | `2` |
- **Request body (PATCH):** any of `first_name`, `last_name`, `email`, `phone_number`, `is_active`.
  ```json
  { "phone_number": "9876522222", "is_active": false }
  ```
  - `phone_number` follows the same rules as 1.3: normalised, and unique across all accounts.
  - **Deactivating:** refused while the partner holds active orders. On success the partner is set `offline`, can't sign in, and their existing session stops working.
  - Set `is_active: true` to reactivate.
- **Success response:** `200 OK` (`201` for create)
  ```json
  {
    "id": 58, "username": "ravi.k", "name": "Ravi Kumar", "first_name": "Ravi", "last_name": "Kumar", "email": "ravi.k@example.com",
    "phone_number": "+919876500001", "is_active": true,
    "profile": { "id": 7, "vehicle_type": "bike", "vehicle_number": "KL07AB1234", "warehouse": 14, "warehouse_name": "Kochi Central", "availability_status": "on_delivery" },
    "active_orders": 2, "created_at": "2026-11-13T12:06:11.251202+05:30", "last_login": "2026-11-14T09:01:00+05:30"
  }
  ```
- **Error responses:**
  - `400` `{"phone_number": ["This mobile number is already used by another account."]}`
  - `400` `{"is_active": ["This partner has active orders. Reassign or finish them before deactivating."]}`
  - `400` `{"email": ["An account already exists for this email."]}`
  - `403` not admin
  - `404` not a delivery partner
  - `405` DELETE
- **Pagination:** list, 25 per page

---

## 2. My profile (delivery partner)

### 2.1 Get my profile

- **Name / purpose:** Load the signed-in partner's profile: vehicle, availability, warehouse.
- **Method + path:** `GET /api/delivery/v1/delivery-profiles/me/`
- **Headers:** partner session cookie
- **Path / query params:** none
- **Request body:** none
- **Success response:** `200 OK`, a [`DeliveryProfile`](#deliveryprofile-object). A freshly registered partner with no vehicle looks like this:
  ```json
  { "id": 22, "user": 58, "username": "ravi.k", "email": "ravi.k@example.com", "vehicle_type": "", "vehicle_number": "", "latitude": null, "longitude": null, "availability_status": "offline", "warehouse": null, "created_at": "2026-11-13T12:06:11.257412+05:30", "updated_at": "2026-11-13T12:06:11.257430+05:30" }
  ```
- **Error responses:**
  - `403` not a delivery user: `{"detail": "You must be a delivery person to access this resource."}`
  - `404` no profile: `{"error": "Delivery profile not found for this user"}`
- **Pagination:** none

### 2.2 Update my profile (vehicle)

- **Name / purpose:** Set vehicle details.
  - `PATCH` is a partial update.
  - `PUT` requires both `vehicle_type` and `vehicle_number`.
- **Method + path:** `PATCH /api/delivery/v1/delivery-profiles/me/` (or `PUT`)
- **Headers:** partner session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** none
- **Request body:**
  ```json
  { "vehicle_type": "bike", "vehicle_number": "KL07AB1234" }
  ```
  Writable fields: `vehicle_type`, `vehicle_number`, `availability_status` (see [2.3](#23-go-online--offline)).

  These fields are read-only here and **silently ignored** if sent: `user`, `warehouse`, `latitude`, `longitude`.
- **Success response:** `200 OK`, the updated [`DeliveryProfile`](#deliveryprofile-object):
  ```json
  { "id": 22, "user": 58, "username": "ravi.k", "email": "ravi.k@example.com", "vehicle_type": "bike", "vehicle_number": "KL07AB1234", "latitude": null, "longitude": null, "availability_status": "offline", "warehouse": null, "created_at": "…", "updated_at": "…" }
  ```
- **Error responses:**
  - `400` bad enum: `{"vehicle_type": ["\"plane\" is not a valid choice."]}`
  - `400` PUT missing a field: `{"vehicle_number": ["This field is required."]}`
  - `403` CSRF or role (see Common errors)
  - `404` `{"error": "Delivery profile not found for this user"}`
- **Pagination:** none

### 2.3 Go online / offline

- **Name / purpose:** Shift toggle. Only `online` partners can be assigned orders.
- **Method + path:** `PATCH /api/delivery/v1/delivery-profiles/me/`
- **Headers:** partner session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** none
- **Request body:**
  ```json
  { "availability_status": "online" }
  ```
  Allowed values: `online` / `offline`. Vehicle details can be sent in the same request, e.g. `{"vehicle_type":"bike","vehicle_number":"KL07AB1234","availability_status":"online"}`.
- **Success response:** `200 OK`, a [`DeliveryProfile`](#deliveryprofile-object) with `"availability_status": "online"`
- **Error responses:**
  - `400` no vehicle yet: `{"availability_status": ["Set your vehicle type and number before going online."]}`
  - `400` while a job is active: `{"availability_status": ["You can't change availability while you have an active delivery."]}`
  - `400` sent `on_delivery`: `{"availability_status": ["'on_delivery' is set automatically when an order is assigned to you."]}`
  - `400` unknown value: `{"availability_status": ["\"busy\" is not a valid choice."]}`
  - `403` / `404` as in 2.2
- **Pagination:** none

### 2.4 Change password

- **Name / purpose:** Partner changes their own password. **The current session stays signed in.**
- **Method + path:** `POST /api/delivery/v1/delivery-profiles/change-password/`
- **Headers:** partner session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** none
- **Request body:**
  ```json
  { "current_password": "Passw0rd!QA", "new_password": "N3wPassw0rd!", "new_password_confirm": "N3wPassw0rd!" }
  ```
  `new_password` follows the same rules as registration (1.3).
- **Success response:** `200 OK`
  ```json
  { "message": "Password changed successfully" }
  ```
- **Error responses** (all `400`):
  - `{"error": "current_password, new_password, and new_password_confirm are required"}`
  - `{"error": "Current password is incorrect"}`
  - `{"error": "New passwords do not match"}`
  - `{"error": "New password must be at least 8 characters long"}`
  - `{"error": "This password is too common. This password is entirely numeric."}` (the password-rule messages, joined)

  `403` if not a delivery user.
- **Pagination:** none

### 2.5 Name, email and photo

- **Name / purpose:** The partner's personal details live on the shared account profile, not the delivery profile. It works for partners as-is: use it for the profile screen header after a restart (F1) and to edit name / email / photo (B4). `phone_number` is read-only (an admin changes it), and so is `role`.
- **Method + path:** `GET /api/auth/v1/profile/` and `PATCH /api/auth/v1/profile/`
- **Headers:** session cookie. PATCH also needs `X-CSRFToken` and `Content-Type: application/json`, or `multipart/form-data` when uploading a photo.
- **Path / query params:** none
- **Request body (PATCH):**
  ```json
  { "first_name": "Ravi", "last_name": "Kumar", "email": "ravi.k@example.com" }
  ```
  Photo: send `profile_photo_file` (image) as multipart, or `profile_photo_remove: true` to clear it.
- **Success response:** `200 OK` with the user profile (`id`, `username`, `first_name`, `last_name`, `email`, `phone_number`, `role`, `profile_photo`, …)
- **Error responses:** `400` `{"email": ["An account already exists for this email."]}` and other field errors, `403` not signed in
- **Pagination:** none

Vehicle: keep a type picker (`vehicle_type`, one of the values in [2.2](#22-update-my-profile-vehicle)), with free text for `vehicle_number` only. Both are required before going online.

### 2.6 Send my location (all active orders)

- **Name / purpose:** One GPS point for the rider, fanned out to every order they hold in `at_pickup`, `picked_up` or `out_for_delivery`. Each customer on the trip sees the rider, not just the next stop's customer. Use this instead of [4.4](#44-push-live-location).
- **Method + path:** `POST /api/delivery/v1/delivery-profiles/me/location/`
- **Headers:** partner session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** none
- **Request body:** only `latitude` and `longitude` are required.
  ```json
  { "latitude": 9.931233, "longitude": 76.267304, "recorded_at": "2026-11-14T12:01:13+05:30", "accuracy_m": 8.5, "speed_mps": 6.2, "heading": 270 }
  ```
  | Field | Rules |
  |---|---|
  | `latitude`, `longitude` | -90..90 / -180..180; `0` is valid |
  | `recorded_at` | ISO-8601 **with offset**; when the phone took the fix. Not more than 2 min in the future. Default: server time. |
  | `accuracy_m` | 0..100000 |
  | `speed_mps` | 0..100 |
  | `heading` | 0..360 |

  A point whose `recorded_at` isn't newer than the last stored one for an order is ignored for that order. A delayed request never moves the rider backwards on a customer's map.
- **Success response:** `200 OK`. With no active orders it still saves the position on the profile, and both lists are empty.
  ```json
  { "deliveries_updated": [16, 17, 18], "stale": [] }
  ```
  The customer's Socket.IO `location_update` event now also carries `recorded_at`, and `accuracy_m` / `speed_mps` / `heading` when sent.
- **Error responses:**
  - `400` `{"error": "latitude and longitude are required"}`
  - `400` `{"error": "recorded_at must be an ISO-8601 datetime with a UTC offset"}`
  - `400` `{"error": "recorded_at is in the future"}`
  - `400` `{"error": "heading must be between 0 and 360"}` (same pattern for `accuracy_m` and `speed_mps`)
  - `403` not a delivery partner
- **Pagination:** none

The server has no "no ping means offline" rule; the last position stays for an hour. A rider standing still can simply send nothing.

---

## 3. Delivery profiles (admin)

Who can do what:
- **Reads:** admins see every profile. Other signed-in users see only their own.
- **Writes** (create / update / delete): admin only. Partners use `/me/`.

### 3.1 List profiles

- **Name / purpose:** Admin list of all delivery profiles.
- **Method + path:** `GET /api/delivery/v1/delivery-profiles/`
- **Headers:** session cookie
- **Path / query params:** `page`
- **Request body:** none
- **Success response:** `200 OK`
  ```json
  { "count": 4, "next": null, "previous": null, "results": [ { "id": 22, "user": 58, "username": "ravi.k", "email": "ravi.k@example.com", "vehicle_type": "bike", "vehicle_number": "KL07AB1234", "latitude": null, "longitude": null, "availability_status": "online", "warehouse": 14, "created_at": "…", "updated_at": "…" } ] }
  ```
- **Error responses:**
  - `403` not signed in
- **Pagination:** yes, 25 per page

### 3.2 Retrieve a profile

- **Name / purpose:** One profile, by **profile** ID (not user ID).
- **Method + path:** `GET /api/delivery/v1/delivery-profiles/{id}/`
- **Headers:** session cookie
- **Path / query params:** `id` (int, profile ID)
- **Request body:** none
- **Success response:** `200 OK`, a [`DeliveryProfile`](#deliveryprofile-object)
- **Error responses:**
  - `404` `{"detail": "No DeliveryProfile matches the given query."}`
  - `403` not signed in
- **Pagination:** none

### 3.3 Create a profile (admin)

- **Name / purpose:** Create a profile for an existing `delivery`-role user who has none. Rarely needed, because registration (1.3) already creates one.
- **Method + path:** `POST /api/delivery/v1/delivery-profiles/`
- **Headers:** admin session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** none
- **Request body:**
  ```json
  { "user": 57, "vehicle_type": "cycle", "vehicle_number": "KL01ZZ9999", "warehouse": 14 }
  ```
- **Success response:** `201 Created`, a [`DeliveryProfile`](#deliveryprofile-object) whose `user` is the user from the body
- **Error responses:**
  - `400` not a delivery user: `{"user": ["User 54 is not a delivery partner (role: customer)."]}`
  - `400` user already has a profile: `{"user": ["delivery profile with this user already exists."]}`
  - `400` missing vehicle fields
  - `403` not admin: `{"detail": "You must be an admin to access this resource."}`
- **Pagination:** none

### 3.4 Update a profile (admin)

- **Name / purpose:** Admin edits a partner's profile:
  - scope the partner to a warehouse;
  - fix vehicle details;
  - force availability, e.g. to un-stick a partner.
- **Method + path:** `PATCH /api/delivery/v1/delivery-profiles/{id}/` (or `PUT` with `user`, `vehicle_type`, `vehicle_number`)
- **Headers:** admin session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** `id` (int, profile ID)
- **Request body:**
  ```json
  { "warehouse": 14 }
  ```
- **Success response:** `200 OK`, a [`DeliveryProfile`](#deliveryprofile-object)
- **Error responses:**
  - `400` field errors
  - `403` non-admin, including the partner themselves: `{"detail": "You must be an admin to access this resource."}`
  - `404`
- **Pagination:** none

### 3.5 Delete a profile (admin)

- **Name / purpose:** Remove a partner's profile. The user account stays.
- **Method + path:** `DELETE /api/delivery/v1/delivery-profiles/{id}/`
- **Headers:** admin session cookie, `X-CSRFToken`
- **Path / query params:** `id` (int, profile ID)
- **Request body:** none
- **Success response:** `204 No Content` (empty body)
- **Error responses:**
  - `403` `{"detail": "You must be an admin to access this resource."}`
  - `404`
- **Pagination:** none

---

## 4. Deliveries

Visibility by role:

| Role | Sees | Can write |
|---|---|---|
| Admin | all deliveries | everything |
| Warehouse staff | all deliveries | nothing here; assign via [5.2](#52-assign--unassign-a-delivery-partner) |
| Delivery partner | deliveries assigned to them, including finished (`delivered`, `failed`) ones; a job they rejected, or that was re-dispatched to someone else after a failure, drops out (use [4.8](#48-trip-history) for history) | `status`, `notes`, `proof_of_delivery`, `fail_reason`, `cash_collected` on their own |
| Customer | deliveries for their own orders | nothing |

### 4.1 List my deliveries

- **Name / purpose:** The partner's job list (home screen). Admins and warehouse staff see all deliveries.
- **Method + path:** `GET /api/delivery/v1/deliveries/`
- **Headers:** session cookie
- **Path / query params** (all optional):

  | Param | Type | Example |
  |---|---|---|
  | `status` | one delivery status | `assigned` |
  | `order__id` | int | `50` |
  | `delivery_partner__id` | int (admin use) | `58` |
  | `page` | int | `2` |

  `status` takes a single value. For an "Active" tab, call once per status or filter on the client.
- **Request body:** none
- **Success response:** `200 OK`
  ```json
  {
    "count": 1, "next": null, "previous": null,
    "results": [ { "id": 16, "order": 50, "order_details": { "…": "…" }, "items": [ { "…": "…" } ], "delivery_partner": 58, "status": "assigned", "ui_stage": "accepted", "item_count": 2, "delivery_fee": "0.00", "assigned_at": "2026-11-13T12:06:12.900953+05:30", "picked_up_at": null, "delivered_at": null, "proof_of_delivery": null, "notes": null, "…": "full Delivery object" } ]
  }
  ```
- **Error responses:**
  - `400` bad filter: `{"status": ["Select a valid choice. bogus is not one of the available choices."]}`
  - `403` not signed in
  - `404` `{"detail": "Invalid page."}`
- **Pagination:** yes, 25 per page

### 4.2 Get a delivery

- **Name / purpose:** Job detail screen.
- **Method + path:** `GET /api/delivery/v1/deliveries/{id}/`
- **Headers:** session cookie
- **Path / query params:** `id` (int, delivery ID)
- **Request body:** none
- **Success response:** `200 OK`, a [`Delivery`](#delivery-object)
- **Error responses:**
  - `404` `{"detail": "No Delivery matches the given query."}`, also returned for deliveries not assigned to you and for ones you rejected
- **Pagination:** none

### 4.3 Update delivery status (partner actions)

- **Name / purpose:** Move a delivery through its lifecycle: accept, reject, picked up, out for delivery, delivered, failed. The same call can attach notes and proof of delivery.
- **Method + path:** `PATCH /api/delivery/v1/deliveries/{id}/`
- **Headers:** session cookie (assigned partner or admin), `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** `id` (int, delivery ID)
- **Request body:** one of the following.

  | Action | From | Body | Side effects |
  |---|---|---|---|
  | Accept / arrived at store | `assigned` | `{"status": "at_pickup"}` | |
  | Reject | `assigned`, `at_pickup` | `{"status": "pending", "notes": "Vehicle breakdown"}` | partner removed, `"Rejected by <username>"` appended to notes, order leaves the trip, partner → online if it was their last order |
  | Picked up | `at_pickup` | `{"status": "picked_up"}` | stamps `picked_up_at` |
  | Out for delivery | `picked_up` | `{"status": "out_for_delivery"}` | order `packed` → `out_for_delivery`, customer notified |
  | Delivered (prepaid) | `out_for_delivery` | `{"status": "delivered", "proof_of_delivery": "https://imart-grocery.b-cdn.net/pod/123.jpg", "notes": "Handed to customer"}` | order → `delivered`, stamps `delivered_at`, partner → online and trip closes if it was the last active order |
  | Delivered (COD) | `out_for_delivery` | `{"status": "delivered", "cash_collected": "500.00"}` | as above, plus stamps `cash_collected` / `cash_collected_at`. `cash_collected` must equal `order_details.amount_to_collect` |
  | Failed | `out_for_delivery` | `{"status": "failed", "fail_reason": "customer_unavailable", "notes": "Rang twice"}` | order → `packed` for re-dispatch, `"Failed by <username>: <reason>"` appended, partner → online and trip closes if it was the last active order |
  | Failed, COD refused | `out_for_delivery` | `{"status": "failed", "fail_reason": "customer_refused"}` on a COD order | order → `cancelled` and the goods go back into stock (nothing was paid). It can't be re-dispatched |

  Every `delivered` / `failed` is also written to the partner's trip history ([4.8](#48-trip-history)).

  Notes:
  - `proof_of_delivery` is optional. If sent, it must be a URL on the configured Bunny CDN host.
  - `notes` can be updated on its own at any time: `{"notes": "Gate code 1234"}`.
  - `fail_reason` is required for `failed`. It must be a code from [4.9](#49-fail-reasons). `other` also needs `notes`.
  - Send at most one step per call; `at_pickup` then `picked_up` back-to-back is fine. Once `picked_up`, the job can't be rejected; use `failed`.
  - Partners may only change `status`, `notes`, `proof_of_delivery`, `fail_reason` and `cash_collected`.
- **Success response:** `200 OK`, the updated [`Delivery`](#delivery-object). `order_details.status` reflects the synced order. After `out_for_delivery`:
  ```json
  { "id": 16, "order": 50, "status": "out_for_delivery", "ui_stage": "on_the_way", "picked_up_at": "2026-11-13T12:06:14.555425+05:30", "order_details": { "id": 50, "status": "out_for_delivery", "…": "…" }, "…": "full Delivery object" }
  ```
  After `failed`:
  ```json
  { "id": 18, "order": 53, "status": "failed", "ui_stage": "completed", "fail_reason": "customer_unavailable", "fail_reason_display": "Customer unavailable", "notes": "Rang twice\nFailed by ravi.k: Customer unavailable", "order_details": { "id": 53, "status": "packed", "…": "…" }, "…": "…" }
  ```
  After a COD `delivered`:
  ```json
  { "id": 16, "status": "delivered", "cash_collected": "500.00", "cash_collected_at": "2026-11-13T12:40:02.118034+05:30", "order_details": { "id": 50, "status": "delivered", "payment_mode": "cod", "amount_to_collect": "500.00", "…": "…" }, "…": "…" }
  ```
- **Error responses:**
  - `400` illegal transition: `{"status": "Cannot transition from 'assigned' to 'picked_up'"}`
  - `400` order not packed yet: `{"status": "Cannot transition order from 'picking' to 'out_for_delivery'."}`
  - `400` bad proof URL: `{"proof_of_delivery": ["Proof of delivery must be a URL hosted on the configured CDN."]}`
  - `400` COD without cash: `{"cash_collected": ["This is a cash-on-delivery order. Collect ₹500.00 and send cash_collected to complete it."]}`
  - `400` wrong amount: `{"cash_collected": ["Cash collected (₹450.00) must equal the amount due (₹500.00)."]}`
  - `400` cash on a prepaid order: `{"cash_collected": ["This order is prepaid; there is no cash to collect."]}`
  - `400` no reason: `{"fail_reason": ["Say why the delivery failed. One of: customer_unavailable, wrong_address, customer_refused, unable_to_contact, other."]}`
  - `400` unknown reason: `{"fail_reason": ["\"bogus\" is not a valid choice."]}`
  - `400` `other` without notes: `{"notes": ["Describe what happened when the fail reason is 'other'."]}`
  - `400` partner touching an admin field: `{"delivery_fee": ["Delivery partners can only update status, notes and proof_of_delivery."]}` (same message for `delivery_partner`)
  - `400` changing the order: `{"order": ["The order of an existing delivery cannot be changed."]}`
  - `403` customer / warehouse: `{"detail": "Only an admin or the assigned delivery partner can update this delivery."}`
  - `404` not your delivery: `{"detail": "No Delivery matches the given query."}`
- **Pagination:** none

### 4.4 Push live location

- **Name / purpose:** GPS ping while on a job. What happens to each ping:
  - cached in Redis;
  - fanned out to the customer's tracking screen over Socket.IO, at about 1 Hz;
  - saved to the profile on the 1st, 11th, 21st… ping.

  Recommended client rate: every 3–5 s.
- **Method + path:** `POST /api/delivery/v1/deliveries/{id}/update_location/`. For trips, prefer [2.6](#26-send-my-location-all-active-orders), which updates every active order at once. This endpoint takes the same optional fields (`recorded_at`, `accuracy_m`, `speed_mps`, `heading`) and the same stale-point rule.
- **Headers:** partner session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** `id` (int, delivery ID)
- **Request body:**
  ```json
  { "latitude": 9.931233, "longitude": 76.267304 }
  ```
  Rules:
  - Allowed only while the delivery is `at_pickup`, `picked_up` or `out_for_delivery`.
  - `latitude` must be between -90 and 90; `longitude` between -180 and 180.
  - `0` is a valid value.
- **Success response:** `200 OK`
  ```json
  {
    "message": "Location updated successfully (cached in Redis)",
    "location": { "delivery_id": 16, "latitude": 9.931233, "longitude": 76.267304, "timestamp": "2026-11-13T06:36:13.143664+00:00", "user_id": 58, "order_id": 50, "partner_name": "ravi.k" },
    "stale": false,
    "storage": { "cache": "Redis (primary storage)", "db_persistence": "Every 10 updates", "current_update": 1, "next_db_persist": 10 }
  }
  ```
  `location` also includes `recorded_at`, `accuracy_m`, `speed_mps` and `heading`. An out-of-date point returns `200` with `"stale": true` and the stored `location`.
- **Error responses:**
  - `400` `{"error": "Cannot update location for this delivery status"}`
  - `400` `{"error": "latitude and longitude are required"}`
  - `400` `{"error": "latitude and longitude must be valid numbers"}`
  - `400` `{"error": "latitude must be between -90 and 90 and longitude between -180 and 180"}`
  - `403` not a delivery user: `{"detail": "You must be a delivery person to access this resource."}`
  - `404` not your delivery
- **Pagination:** none

### 4.5 Create a delivery (admin)

- **Name / purpose:** Manually create the delivery record for an order. Normally this happens automatically when the order is confirmed, or on first assignment.
- **Method + path:** `POST /api/delivery/v1/deliveries/`
- **Headers:** admin session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** none
- **Request body:**
  ```json
  { "order": 55, "delivery_fee": "25.00", "notes": "Fragile" }
  ```
- **Success response:** `201 Created`, a [`Delivery`](#delivery-object) with `"status": "pending"` and `"delivery_partner": null`
- **Error responses:**
  - `400` order already has a delivery: `{"order": ["A delivery already exists for this order."]}`
  - `400` `{"order": ["This field is required."]}`
  - `403` `{"detail": "You must be an admin to access this resource."}`
- **Pagination:** none

### 4.6 Update / assign a delivery (admin)

- **Name / purpose:** Admin full or partial update.
  - Changing `delivery_partner` follows the **same rules as [5.2](#52-assign--unassign-a-delivery-partner)**: warehouse scope and `online` availability.
  - A partner change sets the status itself (`assigned`, or `pending` on unassign) and moves partner availability.
  - The partner can't be changed once the delivery is `picked_up` or later.
- **Method + path:** `PUT` or `PATCH /api/delivery/v1/deliveries/{id}/`
- **Headers:** admin session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** `id` (int, delivery ID)
- **Request body:** PUT:
  ```json
  { "order": 55, "delivery_partner": 58, "status": "pending", "delivery_fee": "30.00", "notes": "Updated by admin" }
  ```
  To unassign: `PATCH {"delivery_partner": null}`
- **Success response:** `200 OK`, a [`Delivery`](#delivery-object). The PUT above returns `"status": "assigned"` with `assigned_at` stamped. The unassign returns `"status": "pending"` with `"assigned_at": null`.
- **Error responses:**
  - `400` `{"order": ["This field is required."]}` (PUT)
  - `400` `{"delivery_partner": "Delivery partner is not assigned to this order's warehouse."}`
  - `400` `{"delivery_partner": "Delivery partner is offline."}`
  - `400` `{"delivery_partner": "Delivery partner already has 3 active orders."}`
  - `400` `{"delivery_partner": "Delivery partner has already left the warehouse with other orders."}`
  - `400` `{"delivery_partner": "Cannot change the delivery partner once the delivery is 'picked_up'."}`
  - `400` `{"delivery_partner": "Cannot assign a partner to a cancelled order."}` (also `delivered`, `returned`, `failed`)
  - `400` `{"status": "Assign a delivery partner instead of setting status 'assigned' directly."}`
  - `400` illegal transition
  - `404`
- **Pagination:** none

### 4.7 Delete a delivery (admin)

- **Name / purpose:** Delete a delivery record. If a partner was on it, they're set back to `online`.
- **Method + path:** `DELETE /api/delivery/v1/deliveries/{id}/`
- **Headers:** admin session cookie, `X-CSRFToken`
- **Path / query params:** `id` (int, delivery ID)
- **Request body:** none
- **Success response:** `204 No Content`
- **Error responses:**
  - `403` `{"detail": "You must be an admin to access this resource."}`
  - `404`
- **Pagination:** none


### 4.8 Trip history

- **Name / purpose:** History screen: every delivery the partner finished (delivered or failed) in the last N days, with a summary. Built from an attempt log, so a failed job stays in the original partner's history even after the order is re-dispatched to someone else. `distance_km` is the straight-line warehouse → customer distance of each order (not the GPS route). Earnings are not included yet.
- **Method + path:** `GET /api/delivery/v1/deliveries/history/`
- **Headers:** partner (or admin) session cookie
- **Path / query params:**

  | Param | Type | Notes |
  |---|---|---|
  | `days` | int, 1–90 | default `7` |
  | `partner_id` | int | admin only, required for admins |
  | `page` | int | |
- **Request body:** none
- **Success response:** `200 OK`. `summary` covers the whole window, not just the page. Newest first.
  ```json
  {
    "days": 7,
    "summary": { "total": 2, "delivered": 1, "failed": 1, "cash_collected": "500.00", "distance_km": 7.8 },
    "count": 2, "next": null, "previous": null,
    "results": [
      { "attempt_id": 31, "delivery_id": 16, "order_id": 50, "outcome": "delivered", "fail_reason": null, "fail_reason_display": null, "notes": "", "payment_mode": "cod", "order_total": "500.00", "cash_collected": "500.00", "distance_km": 4.7, "trip_id": 9, "customer_name": "Anita M", "drop_locality": "Kochi, 682011", "assigned_at": "2026-11-13T06:36:12.900953+00:00", "ended_at": "2026-11-13T07:10:02.118034+00:00" },
      { "attempt_id": 30, "delivery_id": 18, "order_id": 53, "outcome": "failed", "fail_reason": "wrong_address", "fail_reason_display": "Wrong address", "notes": "No such house number", "payment_mode": "prepaid", "order_total": "120.00", "cash_collected": null, "distance_km": 3.1, "trip_id": 8, "customer_name": "Joseph P", "drop_locality": "Kochi, 682016", "assigned_at": "…", "ended_at": "…" }
    ]
  }
  ```
  For "today", call with `days=1` and filter `ended_at` on the phone.
- **Error responses:**
  - `400` `{"error": "days must be an integer between 1 and 90."}`
  - `400` admin without `partner_id`: `{"error": "partner_id is required."}`
  - `403` customer / warehouse
- **Pagination:** yes, 25 per page

### 4.9 Fail reasons

- **Name / purpose:** The fixed list for the "Mark as failed" sheet. Fetch it rather than hard-coding the codes.
- **Method + path:** `GET /api/delivery/v1/deliveries/fail-reasons/`
- **Headers:** session cookie
- **Path / query params:** none
- **Request body:** none
- **Success response:** `200 OK`
  ```json
  {
    "results": [
      { "code": "customer_unavailable", "label": "Customer unavailable", "requires_notes": false },
      { "code": "wrong_address", "label": "Wrong address", "requires_notes": false },
      { "code": "customer_refused", "label": "Customer refused", "requires_notes": false },
      { "code": "unable_to_contact", "label": "Unable to contact customer", "requires_notes": false },
      { "code": "other", "label": "Other", "requires_notes": true }
    ]
  }
  ```
- **Error responses:** `403` not signed in
- **Pagination:** none

### 4.10 COD cash in hand

- **Name / purpose:** "Cash to deposit": COD cash the partner has collected but not yet handed over.
  - Partners see their own.
  - Admins pass `partner_id`, or omit it for a per-partner breakdown.
- **Method + path:** `GET /api/delivery/v1/deliveries/cash-summary/`
- **Headers:** session cookie
- **Path / query params:** `partner_id` (int, admin only, optional)
- **Request body:** none
- **Success response:** `200 OK`. Partner (or admin with `partner_id`):
  ```json
  {
    "partner_id": 58,
    "cash_in_hand": "1000.00",
    "count": 2,
    "deliveries": [
      { "delivery_id": 16, "order_id": 50, "amount": "500.00", "collected_at": "2026-11-13T07:10:02.118034+00:00" },
      { "delivery_id": 21, "order_id": 57, "amount": "500.00", "collected_at": "2026-11-13T08:02:44.501120+00:00" }
    ]
  }
  ```
  Admin without `partner_id`:
  ```json
  { "total_cash_in_hand": "1500.00", "results": [ { "partner_id": 58, "partner_name": "Ravi Kumar", "cash_in_hand": "1000.00", "count": 2 }, { "partner_id": 61, "partner_name": "Suresh", "cash_in_hand": "500.00", "count": 1 } ] }
  ```
- **Error responses:**
  - `400` `{"error": "partner_id must be an integer."}`
  - `403` customer / warehouse
- **Pagination:** none

### 4.11 Mark COD cash deposited (admin)

- **Name / purpose:** Record that a partner handed their collected cash to the warehouse. Pass either specific deliveries, or a partner for everything they hold.
- **Method + path:** `POST /api/delivery/v1/deliveries/cash-deposits/`
- **Headers:** admin session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** none
- **Request body:** exactly one of `delivery_ids` and `partner_id`; `reference` is optional (receipt number, max 100 characters).
  ```json
  { "partner_id": 58, "reference": "WH-RCPT-0042" }
  ```
  ```json
  { "delivery_ids": [16, 21], "reference": "WH-RCPT-0042" }
  ```
- **Success response:** `200 OK`
  ```json
  { "deposited": 2, "amount": "1000.00", "delivery_ids": [16, 21], "deposited_at": "2026-11-13T13:30:00.000000+00:00", "reference": "WH-RCPT-0042" }
  ```
- **Error responses:**
  - `400` `{"non_field_errors": ["Provide exactly one of delivery_ids or partner_id."]}`
  - `400` `{"error": "These deliveries have no undeposited cash.", "delivery_ids": [999]}` (nothing is marked)
  - `400` `{"error": "This partner has no undeposited cash."}`
  - `403` `{"detail": "You must be an admin to access this resource."}`
- **Pagination:** none

### 4.12 Upload proof-of-delivery photo

- **Name / purpose:** Store a doorstep photo on the CDN and attach it to the delivery. The returned URL is already saved as `proof_of_delivery`, so the "delivered" PATCH doesn't need to send it.
- **Method + path:** `POST /api/delivery/v1/deliveries/{id}/proof/`
- **Headers:** assigned partner session cookie, `X-CSRFToken`, `Content-Type: multipart/form-data`
- **Path / query params:** `id` (int, delivery ID)
- **Request body:** multipart field `file`: an image, at most 10 MB. The server resizes it (max 1280 px wide) and stores it as WEBP.
- **Success response:** `201 Created`
  ```json
  { "url": "https://imart-grocery.b-cdn.net/deliveries/pod/16_3f9c….webp" }
  ```
- **Error responses:**
  - `400` `{"error": "Proof can be uploaded only while the delivery is out for delivery."}`
  - `400` `{"error": "Attach the photo as multipart field 'file'."}`
  - `400` `{"error": "file must be an image."}` / `{"error": "file must be at most 10 MB."}`
  - `403` another partner's delivery: `{"error": "You can only upload proof for your assigned deliveries"}`
  - `404` not your delivery
  - `503` `{"error": "Upload failed. Please try again."}`
- **Pagination:** none

### 4.13 Arrange trip stops

- **Name / purpose:** Save the stop order from the app's Arrange Route screen. List **every active order** of your open trip exactly once, in the order you'll deliver them. Finished stops keep their numbers at the front.
- **Method + path:** `POST /api/delivery/v1/deliveries/arrange/`
- **Headers:** partner session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** none
- **Request body:**
  ```json
  { "delivery_ids": [18, 16, 17] }
  ```
- **Success response:** `200 OK`, the updated [trip](#91-current-trip) with `stops` in the new order. Each customer's `stops_ahead` changes accordingly.
- **Error responses:**
  - `400` `{"error": "delivery_ids must be a non-empty list of delivery ids."}`
  - `400` `{"error": "delivery_ids contains duplicates."}`
  - `400` `{"error": "delivery_ids must list every active stop of your open trip exactly once.", "active_delivery_ids": [16, 17, 18]}`
  - `400` `{"error": "You have no open trip.", "code": "no_open_trip"}`
  - `403` not a delivery partner
- **Pagination:** none

---

## 5. Order-side delivery actions

### 5.1 Delivery candidates for an order

- **Name / purpose:** Assign drawer. Lists partners who can take this order:
  - partners scoped to the order's warehouse(s), or with no warehouse;
  - delivery users with **no profile at all**.

  Partners pinned to a different warehouse are excluded.
- **Method + path:** `GET /api/order/v1/orders/{id}/delivery-candidates/`
- **Headers:** admin or warehouse session cookie
- **Path / query params:** `id` (int, order ID)
- **Request body:** none
- **Success response:** `200 OK` (plain array, not paginated)
  ```json
  [
    { "id": 58, "name": "Ravi Kumar", "vehicle_type": "bike", "availability_status": "on_delivery", "warehouse_id": 14, "warehouse_name": "Kochi Central", "active_orders": 1, "capacity_left": 2, "assignable": true, "reason": null },
    { "id": 59, "name": "Suresh", "vehicle_type": "bike", "availability_status": "on_delivery", "warehouse_id": 14, "warehouse_name": "Kochi Central", "active_orders": 2, "capacity_left": 1, "assignable": false, "reason": "Delivery partner has already left the warehouse with other orders." },
    { "id": 61, "name": "new.partner", "vehicle_type": null, "availability_status": null, "warehouse_id": null, "warehouse_name": null, "active_orders": 0, "capacity_left": 3, "assignable": true, "reason": null }
  ]
  ```
  - `id` is the **user ID**: pass it as `partner_id` in 5.2.
  - `assignable` / `reason` apply the same rules as 5.2: offline, full (`capacity_left` 0), or already left the warehouse. Grey out rows with `assignable: false` and show `reason`.
- **Error responses:**
  - `403` `{"detail": "You must be an admin or warehouse staff to perform this action."}`
  - `404`
- **Pagination:** none

### 5.2 Assign / unassign a delivery partner

- **Name / purpose:** Assign a partner to an order, enforcing warehouse scope and `online` availability:
  - the order joins the partner's open trip as the last stop (or opens a trip); a partner already `on_delivery` can take more orders until the cap, if they're still at the warehouse;
  - the new partner becomes `on_delivery`;
  - a replaced partner goes back to `online`.

  Also used to **re-dispatch after a failed attempt**: the order is back at `packed`, so assignment is open again.
- **Method + path:** `POST /api/order/v1/orders/{id}/assign-delivery-partner/`
- **Headers:** admin or warehouse session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** `id` (int, order ID)
- **Request body:**
  ```json
  { "partner_id": 58 }
  ```
  To unassign:
  ```json
  { "partner_id": null }
  ```
- **Success response:** `200 OK`
  ```json
  { "delivery_id": 16, "delivery_partner_id": 58, "delivery_partner_name": "Ravi Kumar", "delivery_status": "assigned", "assigned_at": "2026-11-13T06:36:12.900953Z" }
  ```
  Unassign:
  ```json
  { "delivery_id": 19, "delivery_partner_id": null, "delivery_partner_name": null, "delivery_status": "pending", "assigned_at": null }
  ```
  Re-sending the current partner after pickup is a no-op and returns the current state, e.g. `"delivery_status": "picked_up"`.
- **Error responses** (all `400`):
  - `{"error": "Invalid partner_id."}`
  - `{"error": "Delivery partner is not assigned to this order's warehouse."}`
  - `{"error": "Delivery partner is offline."}`
  - `{"error": "Delivery partner already has 3 active orders."}`
  - `{"error": "Delivery partner has already left the warehouse with other orders."}`
  - `{"error": "Cannot change delivery partner once the delivery is 'picked_up'."}`
  - `{"error": "Cannot change delivery partner on a out_for_delivery order."}`, also returned for `delivered`, `cancelled` and `failed` orders

  Plus `403` wrong role and `404` order not found.
- **Pagination:** none

### 5.3 Mark order out for delivery

- **Name / purpose:** Moves the **order** `packed` → `out_for_delivery`, and the delivery along with it (stamping `picked_up_at` if empty). Partner apps don't need this endpoint, because 4.3 `status=out_for_delivery` does the same. It's for the admin panel.
- **Method + path:** `POST /api/order/v1/orders/{id}/out-for-delivery/`
- **Headers:** admin or **assigned** delivery partner session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** `id` (int, **order** ID)
- **Request body:** `{}`
- **Success response:** `200 OK`
  ```json
  { "status": "out_for_delivery", "previous": "packed" }
  ```
- **Error responses:**
  - `400` `{"error": "Cannot transition from 'confirmed' to 'out_for_delivery'."}`
  - `400` `{"error": "Assign a delivery person before marking out for delivery."}`
  - `403` a different partner: `{"error": "You are not the delivery partner assigned to this order."}`
  - `403` wrong role: `{"detail": "You must be an admin or delivery staff to perform this action."}`
  - `404`
- **Pagination:** none

### 5.4 Mark order delivered

- **Name / purpose:** Order-side "delivered". Moves the order **and** its delivery to `delivered` and frees the partner. Equivalent to 4.3 `status=delivered`.
- **Method + path:** `POST /api/order/v1/orders/{id}/mark-delivered/`
- **Headers:** admin or **assigned** delivery partner session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** `id` (int, order ID)
- **Request body:** `{}` for prepaid. For COD, the cash collected:
  ```json
  { "cash_collected": "500.00" }
  ```
- **Success response:** `200 OK`
  ```json
  { "status": "delivered", "previous": "out_for_delivery" }
  ```
- **Error responses:**
  - `400` `{"error": "Cannot transition from 'packed' to 'delivered'."}`
  - `400` COD: `{"error": "This is a cash-on-delivery order. Collect ₹500.00 and send cash_collected to complete it.", "amount_to_collect": "500.00"}` (also for a wrong amount)
  - `403` `{"error": "You are not the delivery partner assigned to this order."}`
  - `403` wrong role
  - `404`
- **Pagination:** none

---

## 6. Serviceability (public)

### 6.1 Check a pincode

- **Name / purpose:** Powers the "Delivery available · ETA 20 min" line on the add-address form.
- **Method + path:** `GET /api/delivery/v1/serviceability/`
- **Headers:** none (public)
- **Path / query params:** `pincode` (string, required)
- **Request body:** none
- **Success response:** `200 OK`
  ```json
  { "pincode": "682001", "serviceable": true, "locality": "Ernakulam", "eta_minutes": 20 }
  ```
  Unknown pincode:
  ```json
  { "pincode": "000000", "serviceable": false, "locality": null, "eta_minutes": null }
  ```
- **Error responses:**
  - `400` `{"detail": "pincode query param is required."}`
- **Pagination:** none

---

## 7. Push notifications

The partner gets `delivery_assigned` ("New delivery assigned") and `order_ready_for_pickup` in three ways:
- the in-app inbox (`GET /api/notifications/v1/notifications/`);
- Socket.IO, while connected;
- Firebase Cloud Messaging (FCM) push, so jobs arrive while the app is closed.

The push `data` carries `id`, `type`, `severity`, `link` (e.g. `orders/50`) and `created_at` as strings.

Push is sent only once the server has `FIREBASE_CREDENTIALS_FILE` set (a Firebase service-account JSON). Until then the other two channels still work, and polling `GET /deliveries/` every 30 s remains a fine fallback.

### 7.1 Register this device for push

- **Name / purpose:** Save the FCM registration token after login, and again whenever Firebase rotates it. Idempotent. If the token was registered to another account (shared phone), it moves to the signed-in user.
- **Method + path:** `POST /api/notifications/v1/devices/`
- **Headers:** session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** none
- **Request body:** `platform` is `android` (default), `ios` or `web`.
  ```json
  { "token": "fcm-registration-token", "platform": "android" }
  ```
- **Success response:** `200 OK`
  ```json
  { "id": 3, "platform": "android", "created": true }
  ```
- **Error responses:**
  - `400` `{"error": "token is required (max 512 characters)."}`
  - `400` `{"error": "platform must be one of: android, ios, web."}`
  - `403` not signed in
- **Pagination:** none

### 7.2 Unregister this device

- **Name / purpose:** Call on logout so the phone stops receiving this account's pushes.
- **Method + path:** `DELETE /api/notifications/v1/devices/`
- **Headers:** session cookie, `X-CSRFToken`, `Content-Type: application/json`
- **Path / query params:** none
- **Request body:**
  ```json
  { "token": "fcm-registration-token" }
  ```
- **Success response:** `204 No Content` (also when the token wasn't registered)
- **Error responses:** `400` `{"error": "token is required."}`, `403` not signed in
- **Pagination:** none

---

## 8. Cash on delivery: customer and admin side

These live in the customer and admin APIs; they're listed here because they create the COD jobs partners see.

- **Cart summary** `GET /api/order/v1/checkouts/active/summary/` now includes whether COD can be offered:
  ```json
  { "…": "…", "total": "2250.00", "cod": { "available": false, "max_amount": "2000.00", "reason": "Cash on delivery is available for orders up to ₹2000. Please pay online." } }
  ```
- **Place order** `POST /api/order/v1/checkout/` takes `payment_method`: `"prepaid"` (default; Cashfree as before) or `"cod"`. A COD order is confirmed immediately, with no gateway step and no `payment/verify/`. Stock is committed at that point.
  ```json
  { "payment_method": "cod" }
  ```
  `201`:
  ```json
  { "order_id": 50, "gateway_order_id": null, "payment_session_id": null, "cashfree_env": "sandbox", "amount": "500.00", "currency": "INR", "free_order": false, "payment_method": "cod" }
  ```
  Errors:
  - `400` `{"error": "payment_method must be 'prepaid' or 'cod'."}`
  - `400` over the cap: `{"error": "Cash on delivery is available for orders up to ₹2000. Please pay online."}`
  - `400` COD switched off: `{"error": "Cash on delivery is not available right now. Please pay online."}`
- **Orders** (customer list/detail and admin): `payment_method` is `"prepaid"` / `"cod"`.
  - Admin list/detail show `"COD"` / `"Prepaid"`.
  - A COD order's `payment_status` is `"Paid"` once the cash is collected.
  - Admin filters: `?payment_method=cod|prepaid` and `?payment_status=paid|unpaid`, both COD-aware.
- **Cancelling** a confirmed COD order puts its stock back. A ₹0 free order now does too.
- **Returns / refunds** of COD orders are recorded manually through the existing admin refund drawer (UPI or bank transfer); no gateway refund is attempted.
- **Server settings:**
  - `COD_ENABLED` (default `true`);
  - `COD_MAX_ORDER_AMOUNT` (default `2000`; `0` means no cap);
  - `DELIVERY_OTP_RESEND_COOLDOWN_SECONDS` (30);
  - `DELIVERY_OTP_MAX_ATTEMPTS` (5);
  - `DELIVERY_AVG_SPEED_KMPH` (20);
  - `FIREBASE_CREDENTIALS_FILE`.

---

## 9. Trips

### 9.1 Current trip

- **Name / purpose:** The rider's open trip: the stop list for the trip screen, progress, and COD cash. Poll it after each status change, or after an assignment notification.
- **Method + path:** `GET /api/delivery/v1/delivery-trips/current/`
- **Headers:** partner session cookie
- **Path / query params:** none
- **Request body:** none
- **Success response:** `200 OK`
  ```json
  {
    "id": 9,
    "delivery_partner": 58,
    "status": "open",
    "started_at": "2026-11-14T10:02:11.120934+05:30",
    "departed_at": "2026-11-14T10:20:40.004112+05:30",
    "ended_at": null,
    "counts": { "total": 3, "active": 2, "delivered": 1, "failed": 0 },
    "cash_to_collect": "750.00",
    "cash_collected": "500.00",
    "stops": [
      { "delivery_id": 16, "order_id": 50, "stop_number": 1, "status": "delivered", "reassigned": false, "customer_name": "Anita Menon", "customer_phone": "+919000000101", "locality": "Panampilly Nagar", "latitude": 9.9573, "longitude": 76.2932, "payment_mode": "cod", "amount_to_collect": "500.00", "cash_collected": "500.00", "fail_reason": null },
      { "delivery_id": 17, "order_id": 51, "stop_number": 2, "status": "out_for_delivery", "reassigned": false, "customer_name": "Joseph P", "customer_phone": "+919000000102", "locality": "Marine Drive", "latitude": 9.9776, "longitude": 76.2769, "payment_mode": "prepaid", "amount_to_collect": "0.00", "cash_collected": null, "fail_reason": null },
      { "delivery_id": 18, "order_id": 52, "stop_number": 3, "status": "picked_up", "reassigned": false, "customer_name": "Leela R", "customer_phone": "+919000000103", "locality": "Kadavanthra", "latitude": 9.9668, "longitude": 76.2984, "payment_mode": "cod", "amount_to_collect": "750.00", "cash_collected": null, "fail_reason": null }
    ]
  }
  ```
  | Field | Notes |
  |---|---|
  | `cash_to_collect` | COD still to collect on the trip's active stops |
  | `cash_collected` | COD collected on this trip so far. "Cash to deposit" across all trips is [4.10](#410-cod-cash-in-hand). |
  | `departed_at` | First pickup; no orders can be added after it |
  | `stops[].reassigned` | `true` for a failed stop that was later re-dispatched to another rider. It has no `stop_number`. |
- **Error responses:**
  - `404` idle: `{"error": "You have no open trip.", "code": "no_open_trip"}`
  - `403` not a delivery partner
- **Pagination:** none

### 9.2 Trip list / Trip Complete

- **Name / purpose:** The partner's trips, newest first. `GET …/{id}/` is one trip: use it for the Trip Complete screen right after the last stop, since the trip is then `completed` and no longer "current".
- **Method + path:** `GET /api/delivery/v1/delivery-trips/` and `GET /api/delivery/v1/delivery-trips/{id}/`
- **Headers:** partner (own trips) or admin session cookie
- **Path / query params:**

  | Param | Notes |
  |---|---|
  | `days` | 1–90: trips started in the last N days |
  | `status` | `open` or `completed` |
  | `partner_id` | admin only |
  | `page` | |
- **Request body:** none
- **Success response:** `200 OK`, a page of trip objects (same shape as 9.1), or one trip for `{id}`.
- **Error responses:**
  - `400` `{"days": ["days must be an integer between 1 and 90."]}`
  - `403` customers and warehouse staff
  - `404` another partner's trip
- **Pagination:** yes, 25 per page (list)

To see which trip just finished: when the last stop's PATCH returns, its `trip_id` is the trip to open with `GET …/{id}/`.

---

## 10. Pay (earnings)

How a rider's pay is worked out:

- **The rate card.** An admin sets up a **rate card** ([10.1](#101-rate-cards-admin)) that says what each event pays. The rider's own override card is used if there is one, otherwise their warehouse's card, otherwise the global card.
- **When it's calculated.** Every finished stop, and every completed trip, writes **earning lines** using the card in force at that moment:

  | Line | When | Amount |
  |---|---|---|
  | `delivery` | stop delivered | `per_delivery` |
  | `distance` | stop delivered | `per_km × max(0, leg_km − free_km)` |
  | `cod_handling` | delivered COD stop | `per_cod_delivery` |
  | `failed_attempt` | stop failed | `per_failed_attempt` |
  | `trip` | trip completed with ≥ 1 delivery | `per_trip` |
  | `extra_stop` | trip completed | `per_extra_stop × (delivered stops − 1)` |
  | `bonus` / `penalty` | admin adjustment ([10.3](#103-earnings-ledger-and-adjustments-admin)) | as entered |
- **Distance.** `leg_km` is the straight-line distance from the previous finished stop of the trip (or the warehouse, for the first) to this customer. It follows the order the rider actually completed the stops in. `trip.total_km` is the sum of the legs.
- **Lines never change.**
  - Rate changes apply only from their start time.
  - Corrections are new bonus or penalty lines.
  - ₹0 lines aren't stored.
  - With no rate card, nothing is earned.
- **COD cash isn't pay.** Cash collected for the customer's order is tracked separately (4.10).

Where riders see it:
- `earned` on history rows and in the history `summary` (4.8);
- on trips (9.x), with `total_km`;
- on a finished delivery (`earned`, hidden from customers);
- in [10.2](#102-my-earnings).

### 10.1 Rate cards (admin)

- **Name / purpose:** Set pay rates. `POST` creates a **new version** for its scope and closes the previous version of that scope at the new one's `effective_from`. Once a version has paid anything it's locked: no edit or delete, so create a new version instead.
- **Method + path:**
  - `GET/POST /api/payouts/v1/rate-cards/`
  - `GET/PATCH/DELETE /api/payouts/v1/rate-cards/{id}/` (PATCH / DELETE only while unused)
- **Headers:** admin session cookie; `X-CSRFToken` and `Content-Type: application/json` for writes
- **Path / query params:** filters `warehouse`, `partner_id`, `scope` (`global` / `warehouse` / `partner`), `current=true`, `page`
- **Request body (POST):** scope is `warehouse` **or** `delivery_partner` (an override for one rider) **or** neither (global). Amounts default to 0. `effective_from` defaults to now.
  ```json
  { "warehouse": 14, "per_delivery": "25.00", "per_km": "6.00", "free_km": "2.00", "per_failed_attempt": "0.00", "per_cod_delivery": "10.00", "per_trip": "20.00", "per_extra_stop": "10.00", "effective_from": "2026-11-17T00:00:00+05:30", "note": "Kochi launch rates" }
  ```
- **Success response:** `201 Created` / `200 OK`
  ```json
  { "id": 3, "scope": "warehouse", "warehouse": 14, "delivery_partner": null, "effective_from": "2026-11-17T00:00:00+05:30", "effective_to": null, "per_delivery": "25.00", "per_km": "6.00", "free_km": "2.00", "per_failed_attempt": "0.00", "per_cod_delivery": "10.00", "per_trip": "20.00", "per_extra_stop": "10.00", "note": "Kochi launch rates", "in_use": false, "created_by": 1, "created_at": "…" }
  ```
- **Error responses:**
  - `400` `{"non_field_errors": ["A rate card is for a warehouse or for one partner, not both."]}`
  - `400` `{"error": "A newer version already exists for this scope; its start must be before the new card's."}`
  - `400` `{"error": "This rate card has already been used for pay. Create a new version instead."}` (PATCH / DELETE)
  - `400` `{"error": "warehouse can't be changed; create a new version instead."}` (also `delivery_partner`, `effective_from`)
  - `400` negative amount: `{"per_km": ["Ensure this value is greater than or equal to 0."]}`
  - `403` not admin
- **Pagination:** list, 25 per page

### 10.2 My earnings

- **Name / purpose:** The rider's earnings: a summary for the home and profile screens, and the full ledger.
- **Method + path:**
  - `GET /api/payouts/v1/me/earnings/summary/?days=7`
  - `GET /api/payouts/v1/me/earnings/` (ledger)
- **Headers:** partner session cookie
- **Path / query params:**
  - summary: `days` (1–90, default 7);
  - ledger: `kind`, `from`, `to` (`YYYY-MM-DD`), `page`.
- **Request body:** none
- **Success response:** `200 OK`. Summary (dates are India time; the current pay period is Monday–Sunday):
  ```json
  {
    "today": "106.20",
    "this_period": { "start": "2026-11-09", "end": "2026-11-15", "earned": "412.40" },
    "unpaid_total": "412.40",
    "last_paid": null,
    "days": 7,
    "by_day": [
      { "date": "2026-11-08", "earned": "0.00", "delivered": 0, "failed": 0, "distance_km": 0.0 },
      { "date": "2026-11-14", "earned": "106.20", "delivered": 2, "failed": 1, "distance_km": 9.6 }
    ]
  }
  ```
  Ledger row:
  ```json
  { "id": 41, "delivery_partner": 58, "kind": "distance", "kind_display": "Distance", "amount": "16.20", "order_id": 50, "delivery_id": 16, "trip_id": 9, "attempt": 31, "rate_card": 3, "earned_at": "2026-11-14T10:41:02+05:30", "note": "2.70 km × ₹6.00", "created_at": "…" }
  ```
- **Error responses:**
  - `400` `{"error": "days must be an integer between 1 and 90."}`
  - `403` not a delivery partner
- **Pagination:** ledger, 25 per page

### 10.3 Earnings ledger and adjustments (admin)

- **Name / purpose:** See any rider's earning lines, and add a bonus or a penalty. A penalty is stored as a negative amount.
- **Method + path:**
  - `GET /api/payouts/v1/earnings/`
  - `POST /api/payouts/v1/earnings/adjustments/`
- **Headers:** admin session cookie; `X-CSRFToken` and `Content-Type: application/json` for POST
- **Path / query params (GET):** `partner_id`, `kind`, `from`, `to`, `page`
- **Request body (POST):** `note` is required. `amount` is always positive; `kind` decides the sign.
  ```json
  { "partner_id": 58, "amount": "50.00", "kind": "bonus", "note": "Rain bonus 14 Nov" }
  ```
- **Success response:** `201 Created`, a ledger row (`"amount": "-20.00"` for a ₹20 penalty)
- **Error responses:**
  - `400` `{"partner_id": ["Not a delivery partner."]}`
  - `400` `{"note": ["This field is required."]}`
  - `400` `{"amount": ["Ensure this value is greater than or equal to 0.01."]}`
  - `403` not admin
- **Pagination:** list, 25 per page

### 10.4 Pay statements (admin)

**The weekly cycle** (Monday–Sunday, India time; server setting `PAYOUT_CYCLE`):
1. Every night at 02:00 the server drafts or refreshes a **statement** per rider for the period that just ended. Admins can also generate on demand.
2. A statement collects every earning line not yet on a statement and earned before the period ended, so late lines are included.
3. Older drafts that were never approved are voided, and their lines roll into the new statement. This carries a negative balance forward.
4. An admin reviews and **approves** it, which freezes the totals.
5. The admin pays the rider outside the app (UPI or bank), then **marks it paid** with the reference.
6. The rider gets a "Payout sent" notification (in-app, live and push).

**Statuses:**

| `status` | Meaning |
|---|---|
| `draft` | Generated; refreshed when new lines arrive |
| `approved` | Totals frozen; ready to pay. Lines arriving later go to the next period. |
| `paid` | Payment recorded |
| `void` | Cancelled; its lines are free for the next statement |

**Totals:**
- `gross`: stops and trips;
- `adjustments`: bonus, penalty, carry-forward;
- `net_payable` = gross + adjustments;
- `cod_outstanding`: the rider's undeposited COD cash, **for information only, never deducted**.

**Endpoints:**
- `GET /api/payouts/v1/statements/`: filters `status`, `partner_id`, `period_start`. The detail (`/{id}/`) adds `lines`.
- `POST /api/payouts/v1/statements/generate/` `{"period_start": "2026-11-09", "period_end": "2026-11-15", "partner_id": 58}`. `partner_id` is optional; the period is at most 62 days. Returns `{"count": n, "results": [statement…]}`.
- `POST /api/payouts/v1/statements/{id}/approve/`
- `POST /api/payouts/v1/statements/{id}/mark-paid/` `{"payment_method": "UPI" | "Bank transfer" | "Cash", "payment_reference": "UTR123456", "paid_at": "…optional"}`
- `POST /api/payouts/v1/statements/{id}/void/` `{"reason": "optional"}`
- `GET /api/payouts/v1/statements/export/?status=approved|paid`: a CSV for bank bulk upload. Columns: `statement_id, partner_id, partner_name, phone, period_start, period_end, amount, method, upi_id, account_holder, account_number, ifsc`.

**Headers:** admin session cookie; `X-CSRFToken` and `Content-Type: application/json` for POST.

**Statement:**
```json
{ "id": 12, "delivery_partner": 58, "partner_name": "Ravi Kumar", "period_start": "2026-11-09", "period_end": "2026-11-15", "status": "approved", "gross": "1180.00", "adjustments": "50.00", "net_payable": "1230.00", "cod_outstanding": "750.00", "line_count": 43, "approved_by": 1, "approved_at": "2026-11-16T10:02:00+05:30", "paid_by": null, "paid_at": null, "payment_method": "", "payment_reference": "", "notes": "", "created_at": "…", "updated_at": "…" }
```

**Errors** (all `400`):
- `{"error": "Only a draft statement can be approved (this one is paid)."}`
- `{"error": "Nothing is payable on this statement; it will roll into the next period."}`
- `{"error": "Only an approved statement can be marked paid (this one is draft)."}`
- `{"payment_reference": ["This field is required."]}`
- `{"error": "A paid statement can't be voided."}`
- `{"non_field_errors": ["period_end must be on or after period_start."]}`

Plus `403` not admin, `404` unknown statement.

**Pagination:** list, 25 per page.

### 10.5 Payout account (UPI / bank)

- **Name / purpose:** Where a rider is paid. Admins enter it; riders see it masked.
- **Method + path:**
  - Admin, full details: `GET` / `PUT /api/auth/v1/admin-delivery-partners/{id}/payout-account/`
  - Rider, masked: `GET /api/payouts/v1/me/payout-account/`
- **Headers:** session cookie; `X-CSRFToken` and `Content-Type: application/json` for PUT
- **Request body (PUT):** UPI or bank. IFSC is upper-cased.
  ```json
  { "method": "upi", "upi_id": "ravikumar@okaxis" }
  ```
  ```json
  { "method": "bank", "account_holder": "Ravi Kumar", "account_number": "001234567890", "ifsc": "SBIN0001234" }
  ```
- **Success response:** `200 OK`.
  - Admin: the full details plus `updated_by` / `updated_at`.
  - Rider (masked):
    ```json
    { "method": "bank", "upi_id": "", "account_holder": "Ravi Kumar", "account_number": "XXXXXXXX7890", "ifsc": "SBIN0001234", "updated_at": "…" }
    ```
    A UPI ID shows as `ra*******@okaxis`.
- **Error responses:**
  - `400` `{"upi_id": ["Enter a valid UPI ID, e.g. name@okbank."]}`
  - `400` `{"account_number": ["Account number must be 9-18 digits."], "ifsc": ["Enter a valid IFSC, e.g. SBIN0001234."]}`
  - `404` not set yet: `{"error": "No payout account yet. Ask your admin to add your UPI or bank details.", "code": "no_payout_account"}`
  - `403` wrong role
- **Pagination:** none

### 10.6 My statements

- **Name / purpose:** The rider's pay statements, newest first. Void ones are hidden. The detail includes every earning line.
- **Method + path:** `GET /api/payouts/v1/me/statements/` and `GET /api/payouts/v1/me/statements/{id}/`
- **Headers:** partner session cookie
- **Success response:** `200 OK`, statements (as in 10.4); the detail adds `lines`. `me/earnings/summary/` (10.2) now fills `last_paid` and counts only lines not yet paid in `unpaid_total`.
- **Error responses:** `403` not a partner, `404` someone else's statement
- **Pagination:** list, 25 per page

---

## Changelog

**2026-11-14 (d): partner pay, part 2.**
- Statements: generate, approve, mark paid (with notification), void, and CSV export (10.4).
- Payout accounts (10.5) and the rider's statements (10.6).
- Settings: `PAYOUT_CYCLE` (`weekly` / `daily` / `monthly`) and `PAYOUT_WEEK_START` (0 = Monday).

**2026-11-14 (c): partner pay, part 1.**
- Rate cards (10.1), the earnings ledger and adjustments (10.3), and the rider's earnings (10.2).
- `earned` and `leg_km` on history rows.
- `earned` in the history summary.
- `earned` / `total_km` on trips.
- `earned` on finished deliveries.

**2026-11-14: multi-order trips and the pending app items.**

| Area | Now |
|---|---|
| Assignment | A partner can hold up to 3 orders (`DELIVERY_MAX_ACTIVE_ORDERS`), added only before they leave the warehouse. New errors: offline / full / already left. Candidates show `active_orders`, `capacity_left`, `assignable`, `reason`. |
| Trips | New [9](#9-trips) `delivery-trips/` (current, list, detail) and [4.13](#413-arrange-trip-stops) arrange. The delivery payload adds `trip_id`, `stop_number`, `stops_ahead`. |
| Location | [2.6](#26-send-my-location-all-active-orders): one ping for all active orders. Both location endpoints accept `recorded_at`, `accuracy_m`, `speed_mps`, `heading` and drop out-of-date points. |
| Proof | [4.12](#412-upload-proof-of-delivery-photo) photo upload. |
| Address | `shipping_address.locality` on the delivery payload. |
| History | `distance_km` (straight-line) per row and in `summary`; `trip_id` per row. |
| Partners (admin) | Registration now requires a valid, unique `phone_number` (stored as `+91…`); password is optional (OTP-only accounts). New [1.4](#14-manage-delivery-partners-admin) list / edit / deactivate. |
| Staging | `python manage.py seed_partner_demo --phone <number>` creates a partner with a 3-stop trip (2 COD, 1 prepaid). |

**2026-11-13 (b): partner app requirements.** All additive except the two stricter `failed` / COD `delivered` rules.

| Area | Now |
|---|---|
| Login | Phone + OTP for partners: [1.1a](#11a-delivery-partner-otp-login-send-code) / [1.1b](#11b-delivery-partner-otp-login-verify-code), with a 30 s resend cooldown, a 5-attempt limit and distinct error codes. Email + password (1.1) still works. |
| COD | Checkout accepts `payment_method: "cod"`. Delivery payload has `payment_mode` + `amount_to_collect`. COD `delivered` requires the exact `cash_collected`. A COD refusal cancels and restocks. Cash in hand ([4.10](#410-cod-cash-in-hand)) and deposit ([4.11](#411-mark-cod-cash-deposited-admin)). |
| Failed | `fail_reason` is now **required** (codes from [4.9](#49-fail-reasons)); `other` needs notes. |
| History | [4.8](#48-trip-history) `?days=7`, kept per partner across re-dispatch. No distance or earnings. |
| Delivery payload | `pickup_points` (warehouse name / address / coordinates) and `trip` (straight-line distance + ETA). |
| Push | FCM device registration ([7](#7-push-notifications)); partner notifications go to the phone once Firebase is configured. |

**2026-11-13: delivery-partner review fixes.** Behaviour that clients may notice:

| Area | Before | Now |
|---|---|---|
| Delivery → `out_for_delivery` | order stayed `packed`, and "delivered" then failed with 400 | order moves with it; one call is enough |
| Delivery → `failed` | order stuck in `out_for_delivery`, no way to recover | order returns to `packed`; re-assign via 5.2 |
| Partner PATCH | could change `delivery_fee`, `order`, `delivery_partner` | 400; only `status`, `notes`, `proof_of_delivery` |
| `/me/` | `user`, `warehouse` writable; any availability value at any time | those are read-only; availability rules in 2.3 |
| 5.3 / 5.4 | any delivery partner could move any order | only the assigned partner (else 403) |
| Admin PATCH `delivery_partner` | skipped warehouse and availability checks; `null` left status `assigned` | same rules as 5.2; `null` → `pending` |
| POST `/delivery-profiles/` | attached the profile to the caller; customers allowed | admin only; profile goes to `user` from the body |
| Candidates | could include partners from other warehouses | excluded |
| Duplicate POST `/deliveries/` | 500 | 400 |
| Anonymous PATCH `/deliveries/{id}/` | 500 | 403 |
| Delivery payload | payment fields, no line items, partner email visible to customers | slim `order_details`, `items` pick list, email admin-only; `delivery_partner_profile` always present |
| `update_location` | rejected `0`, accepted 999 | `0` accepted, range-checked |
| Change password | logged the session out; weak passwords accepted | session kept; password rules enforced |
| Register | weak passwords accepted; no vehicle/warehouse fields | password rules enforced; optional `vehicle_type`, `vehicle_number`, `warehouse` |
| Warehouse staff GET `/deliveries/` | empty | all deliveries (read-only) |
