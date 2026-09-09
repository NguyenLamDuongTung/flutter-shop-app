class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final int id;
  final String email;
  final String displayName;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];

    final id = switch (rawId) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    final email = json['email']?.toString() ?? '';

    final displayName =
        json['displayName']?.toString() ??
        json['display_name']?.toString() ??
        json['name']?.toString() ??
        email;

    return AppUser(id: id, email: email, displayName: displayName);
  }
}
