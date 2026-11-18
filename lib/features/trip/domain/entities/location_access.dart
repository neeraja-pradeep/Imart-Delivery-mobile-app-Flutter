/// Whether the app can read the phone's location.
enum LocationAccess {
  /// Location is on and the app may use it.
  granted,

  /// Location (GPS) is switched off on the phone.
  serviceOff,

  /// The rider said "Don't allow"; the app can ask again.
  denied,

  /// The rider blocked it; only the phone's Settings can change it.
  deniedForever,
}
