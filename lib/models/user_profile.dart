class UserProfile {
  final String username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;

  const UserProfile({
    required this.username,
    this.fullName,
    this.bio,
    this.avatarUrl,
  });

  String get displayName => (fullName != null && fullName!.trim().isNotEmpty) ? fullName!.trim() : username;
}
 // i love files where you js call for variables