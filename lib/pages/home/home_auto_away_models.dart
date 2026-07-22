class HomeAutoAwayLocation {
  const HomeAutoAwayLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class HomeAutoAwayMember {
  const HomeAutoAwayMember({
    required this.uid,
    required this.name,
    required this.role,
    this.email = '',
    this.photoUrl = '',
  });

  final String uid;
  final String name;
  final String role;
  final String email;
  final String photoUrl;
}

class HomeAutoAwayFormData {
  const HomeAutoAwayFormData({
    required this.enabled,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.participantUids,
  });

  final bool enabled;
  final double? latitude;
  final double? longitude;
  final int radiusMeters;
  final Set<String> participantUids;
}
