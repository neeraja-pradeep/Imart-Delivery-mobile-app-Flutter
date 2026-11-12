/// The signed-in delivery partner.
class RiderProfile {
  /// Creates a profile.
  const RiderProfile({
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicle,
    required this.hubName,
    this.avatarUrl,
  });

  /// Full name.
  final String name;

  /// Display phone, e.g. `+91 99000 11223`.
  final String phone;

  /// Email.
  final String email;

  /// Vehicle, e.g. `Bike · KA 01 AB 1234`.
  final String vehicle;

  /// Fulfilment hub the rider works from.
  final String hubName;

  /// Optional avatar image.
  final String? avatarUrl;

  /// First name.
  String get firstName => name.trim().split(' ').first;

  /// Copy with changes.
  RiderProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? vehicle,
  }) {
    return RiderProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vehicle: vehicle ?? this.vehicle,
      hubName: hubName,
      avatarUrl: avatarUrl,
    );
  }
}
