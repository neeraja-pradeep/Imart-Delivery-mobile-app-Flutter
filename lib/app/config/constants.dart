/// Global non-style constants: asset paths, timings, user-facing copy.
library;

/// Bundled asset paths.
abstract final class AppAssets {
  /// Green apple-bowl mark.
  static const String logoMarkGreen = 'assets/images/logo_mark_green.svg';

  /// White apple-bowl mark.
  static const String logoMarkWhite = 'assets/images/logo_mark_white.svg';

  /// Vegetable line-art texture.
  static const String vegPattern = 'assets/images/veg_pattern.jpg';
}

/// Timings used by the UI.
abstract final class AppTimings {
  /// How long a toast stays on screen.
  static const Duration toast = Duration(milliseconds: 1900);

  /// OTP resend countdown after the first send.
  static const int otpInitialSeconds = 43;

  /// OTP resend countdown after a resend.
  static const int otpResendSeconds = 30;

  /// Countdown tick.
  static const Duration tick = Duration(seconds: 1);
}

/// Input limits.
abstract final class AppLimits {
  /// OTP length.
  static const int otpLength = 4;

  /// Mobile number length.
  static const int phoneLength = 10;
}

/// User-facing copy, kept verbatim from the design.
abstract final class AppStrings {
  // ---- Brand ----
  /// Wordmark.
  static const String wordmark = 'i mart';

  /// Lockup tagline.
  static const String logoTagline = 'online grocery app';

  /// Splash marketing line.
  static const String splashTagline =
      'Groceries at your doorstep—\nfresh, fast, and easy.';

  /// Splash CTA.
  static const String getStarted = 'Get Started';

  // ---- Common ----
  /// Back.
  static const String back = 'Back';

  /// Cancel.
  static const String cancel = 'Cancel';

  /// Offline banner.
  static const String noInternet = 'No internet connection';

  // ---- Login ----
  /// Phone step title.
  static const String loginTitle = 'Welcome';

  /// OTP step title.
  static const String otpTitle = 'Verify OTP';

  /// Phone step subtitle.
  static const String loginSubtitle = 'Login to start your deliveries';

  /// OTP step subtitle.
  static const String otpSubtitle = 'Enter the code sent to your mobile number';

  /// Phone label.
  static const String mobileNumber = 'Mobile Number';

  /// Phone placeholder.
  static const String mobilePlaceholder = 'Enter 10 digit number';

  /// OTP label.
  static const String otpLabel = 'OTP';

  /// Edit number link.
  static const String editNumber = 'Edit number';

  /// OTP placeholder.
  static const String otpPlaceholder = 'Enter Otp send to your mobile';

  /// Wrong OTP.
  static const String otpIncorrect = 'Incorrect OTP. Please try again.';

  /// Resend link.
  static const String resendOtp = 'Resend OTP';

  /// Timer expired copy.
  static const String didntGetCode = 'Didn’t get the code?';

  /// Demo hint prefix.
  static const String demoCode = 'Demo code: ';

  /// Phone step CTA.
  static const String sendOtp = 'Send OTP';

  /// OTP step CTA.
  static const String verifyLogin = 'Verify & Login';

  /// Loading: send OTP.
  static const String sendingOtp = 'Sending OTP…';

  /// Loading: verify.
  static const String verifying = 'Verifying · loading your trip…';

  /// Resend countdown copy.
  static String resendIn(int seconds) =>
      'Resend OTP in 00:${seconds.toString().padLeft(2, '0')}';

  // ---- Nav ----
  /// Trip tab.
  static const String tabTrip = 'Trip';

  /// Map tab.
  static const String tabMap = 'Map';

  /// Profile tab.
  static const String tabProfile = 'Profile';

  // ---- Trip ----
  /// Duty pill.
  static const String onDuty = 'On Duty';

  /// Summary title.
  static const String todaysTrip = 'Today\'s Trip';

  /// Stat label.
  static const String stops = 'Stops';

  /// Stat label.
  static const String items = 'Items';

  /// Stat label.
  static const String estTime = 'Est. Time';

  /// Pickup banner title.
  static const String pickupFromWarehouse = 'Pickup from Warehouse';

  /// Pickup banner subtitle.
  static String chooseOrders(int picked, int total) =>
      'Choose orders to carry · $picked of $total selected';

  /// Section title.
  static const String deliveryRoute = 'Delivery Route';

  /// Pickup hint.
  static const String setOrderNext = 'You\'ll set the order next';

  /// Enroute hint.
  static const String tapStopForDetails = 'Tap a stop for details';

  /// Contents caption.
  static String orderContents(String id) => 'ORDER CONTENTS · $id';

  /// Pick CTA.
  static const String markPickedUp = 'Mark Picked Up';

  /// Picked confirmation.
  static const String addedToTrip = 'Added to this trip';

  /// Remove link.
  static const String remove = 'Remove';

  /// Start CTA — enabled.
  static String startTrip(int count) =>
      'Start Trip · $count order${count == 1 ? '' : 's'}';

  /// Start CTA — disabled.
  static const String pickAtLeastOne = 'Pick at least one order';

  /// Enroute CTA.
  static const String openNavigation = 'Open Navigation';

  /// Progress label (pickup).
  static String pickedProgress(int picked, int total) =>
      '$picked/$total picked';

  /// Progress label (enroute).
  static String deliveredProgress(int done, int total) =>
      '$done/$total delivered';

  /// Item count meta.
  static String itemCount(int count) => '$count items';

  /// Prepaid badge.
  static const String prepaid = 'Prepaid';

  /// COD badge.
  static const String cod = 'COD';

  /// COD chip.
  static String collectCod(String amount) =>
      'Collect $amount · Cash on Delivery';

  /// Prepaid chip.
  static String prepaidNoCollection(String amount) =>
      'Prepaid · $amount (no collection)';

  // ---- Arrange ----
  /// Title.
  static const String arrangeRoute = 'Arrange Route';

  /// Subtitle.
  static String arrangeSubtitle(int stops, String distance, String eta) =>
      '$stops stops · $distance · $eta';

  /// Optimize CTA.
  static const String optimizeByDistance = 'Optimize by Distance';

  /// Arrange hint.
  static const String arrangeHint =
      'Set the order you\'ll deliver in · drag with the arrows';

  /// Start navigation CTA.
  static const String startNavigation = 'Start Navigation';

  /// Loading: start navigation.
  static const String startingNavigation = 'Starting navigation…';

  /// Move up.
  static const String moveUp = 'Move up';

  /// Move down.
  static const String moveDown = 'Move down';

  // ---- Navigation ----
  /// Map back label.
  static const String backToRoute = 'Back to route';

  /// Nav header subtitle.
  static String stopOf(int seq, int total, String eta) =>
      'Stop $seq of $total · ETA $eta';

  /// Arrived badge.
  static const String arrivedBadge = 'Arrived';

  /// Out-for-delivery badge.
  static const String outForDelivery = 'Out for Delivery';

  /// Order id meta.
  static String orderId(String id) => 'Order $id';

  /// Call CTA.
  static const String call = 'Call';

  /// Navigate CTA.
  static const String navigate = 'Navigate';

  /// Arrived CTA.
  static const String iveArrived = 'I’ve Arrived';

  /// Delivered CTA.
  static const String markDelivered = 'Mark Delivered';

  /// Failed CTA.
  static const String failedDelivery = 'Failed Delivery';

  // ---- Confirm delivery ----
  /// Sheet title.
  static const String confirmDelivery = 'Confirm Delivery?';

  /// Items caption.
  static String itemsCaption(int count, String id) => '$count ITEMS · $id';

  /// Cash checkbox prefix.
  static const String cashCollectedPrefix = 'I have collected ';

  /// Cash checkbox suffix.
  static const String cashCollectedSuffix = ' from the customer in cash';

  /// Confirm CTA.
  static const String yesDelivered = 'Yes, Delivered';

  // ---- Fail ----
  /// Sheet title.
  static const String markAsFailed = 'Mark as Failed';

  /// Sheet subtitle.
  static const String returnedToWarehouse =
      'This order will be returned to the warehouse.';

  /// Confirm CTA.
  static const String confirmFailedDelivery = 'Confirm Failed Delivery';

  // ---- Toasts ----
  /// Toast.
  static const String toastAdded = 'Order added to trip';

  /// Toast.
  static const String toastRemoved = 'Order removed';

  /// Toast.
  static String toastDelivered(String name) => 'Delivered · $name';

  /// Toast.
  static const String toastFailed = 'Marked failed · returns to warehouse';

  // ---- Complete ----
  /// Title.
  static const String tripComplete = 'Trip Complete';

  /// Subtitle.
  static String greatWork(String firstName) => 'Great work, $firstName!';

  /// Stat label.
  static const String delivered = 'Delivered';

  /// Stat label.
  static const String failed = 'Failed';

  /// Stat label.
  static const String distance = 'Distance';

  /// Failed-return note.
  static String returnNote(int count) =>
      '$count order(s) must be returned to the warehouse.';

  /// COD row label.
  static const String cashToDeposit = 'Cash to deposit';

  /// CTA.
  static const String startNewTrip = 'Start New Trip';

  /// Loading.
  static const String loadingNewTrip = 'Loading new trip…';

  // ---- States ----
  /// Loading.
  static const String loadingTrip = 'Loading your trip…';

  /// Loading.
  static const String checkingTrips = 'Checking for trips…';

  /// Loading.
  static const String reconnecting = 'Reconnecting…';

  /// Empty title.
  static const String noTripTitle = 'No Trip Assigned Yet';

  /// Empty copy.
  static const String noTripMessage =
      'New orders are still being packed. You\'ll be notified the moment a '
      'trip is assigned to you.';

  /// Refresh CTA.
  static const String refresh = 'Refresh';

  /// Error title.
  static const String connectionLost = 'Connection Lost';

  /// Error copy.
  static const String connectionLostMessage =
      'We couldn\'t load your trip. Check your internet connection and try '
      'again.';

  /// Retry CTA.
  static const String retry = 'Retry';

  /// Leave title.
  static const String onLeaveTitle = 'You\'re On Leave';

  /// Leave copy.
  static const String onLeaveMessage =
      'No trips will be assigned while you\'re on leave. End your leave to '
      'start receiving deliveries again.';

  /// Leave CTA.
  static const String endLeave = 'End Leave';

  /// Locked title.
  static const String navigationLocked = 'Navigation Locked';

  /// Locked copy.
  static const String navigationLockedMessage =
      'Pick up your orders at the warehouse to start turn-by-turn navigation.';

  /// Locked CTA.
  static const String goToPickup = 'Go to Pickup';

  // ---- Profile ----
  /// Title.
  static const String profile = 'Profile';

  /// Availability label.
  static const String availability = 'Availability';

  /// Status.
  static const String onLeave = 'On Leave';

  /// Leave CTA.
  static const String markLeave = 'Mark Leave';

  /// Leave note — on leave.
  static const String leaveNoteOnLeave =
      'You\'re on leave — no new trips will be assigned. End leave to '
      'start a fresh trip.';

  /// Leave note — can apply.
  static const String leaveNoteAvailable =
      'You have no active deliveries. You can apply for leave now.';

  /// Leave note — blocked.
  static const String leaveNoteBlocked =
      'You have an active trip. Finish all deliveries before applying for '
      'leave.';

  /// Stats caption.
  static const String last7Days = 'Last 7 days';

  /// Stat label.
  static const String trips = 'Trips';

  /// Menu.
  static const String editProfile = 'Edit Profile';

  /// Menu.
  static const String tripHistory = 'Trip History';

  /// Menu.
  static const String logOut = 'Log Out';

  /// Field.
  static const String name = 'Name';

  /// Field.
  static const String phone = 'Phone';

  /// Field.
  static const String mail = 'Mail';

  /// Field.
  static const String vehicle = 'Vehicle';

  /// CTA.
  static const String save = 'Save';

  /// History label.
  static const String earned = 'Earned';

  /// History summary.
  static String historySummary(int stops, int failed, String km) => failed == 0
      ? '$stops stops delivered · $km'
      : '$stops stops · $failed failed · $km';
}
