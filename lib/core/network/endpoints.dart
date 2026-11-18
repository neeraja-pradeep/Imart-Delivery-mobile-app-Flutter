/// Backend paths used by the delivery-partner app.
///
/// Source of truth: `docs/delivery_partner_api.md` and
/// `docs/imart_delivery_partner_api.postman_collection.json`.
abstract final class ApiEndpoints {
  // ---- Auth ----
  /// `POST` — step 1 of phone + OTP login (1.1a).
  static const String otpSend = '/api/auth/v1/delivery/otp/send/';

  /// `POST` — step 2 of phone + OTP login; starts the session (1.1b).
  static const String otpVerify = '/api/auth/v1/delivery/otp/verify/';

  /// `POST` — ends the session (1.2).
  static const String logout = '/api/auth/v1/logout/';

  /// `GET` / `PATCH` — name, email, phone and photo (2.5).
  static const String accountProfile = '/api/auth/v1/profile/';

  // ---- Delivery profile ----
  /// `GET` / `PATCH` — vehicle and availability of the signed-in partner.
  static const String myDeliveryProfile =
      '/api/delivery/v1/delivery-profiles/me/';

  /// `POST` — one GPS point for every active delivery of the rider (2.6).
  static const String myLocation = '${myDeliveryProfile}location/';

  // ---- Deliveries ----
  /// `GET` — the partner's deliveries (paginated, 25 per page).
  static const String deliveries = '/api/delivery/v1/deliveries/';

  /// `PATCH` — one delivery: status, notes, fail reason, cash collected.
  static String delivery(String id) => '$deliveries$id/';

  /// `POST` — saves the rider's stop order for the open trip (4.13).
  static const String arrange = '${deliveries}arrange/';

  /// `GET` — COD cash the rider holds across trips (4.10).
  static const String cashSummary = '${deliveries}cash-summary/';

  /// `GET` — finished deliveries for the last N days.
  static const String deliveryHistory = '${deliveries}history/';

  /// `GET` — reasons a delivery can fail.
  static const String failReasons = '${deliveries}fail-reasons/';

  // ---- Trips ----
  /// `GET` — the rider's trips (9.2).
  static const String trips = '/api/delivery/v1/delivery-trips/';

  /// `GET` — one trip, e.g. for Trip Complete (9.2).
  static String trip(String id) => '$trips$id/';

  // ---- Pay ----
  /// `GET` — earnings per day for the last N days (10.2).
  static const String earningsSummary = '/api/payouts/v1/me/earnings/summary/';
}

/// Query parameter names and values used with [ApiEndpoints].
abstract final class ApiParams {
  /// Page number for paginated lists.
  static const String page = 'page';

  /// History window in days.
  static const String days = 'days';
}
