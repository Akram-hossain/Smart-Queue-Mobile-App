class Profile {
  final String id;
  final String fullName;
  final String email;
  final String? department;
  final String? semester;
  final String? university;
  final String? avatarUrl;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    this.department,
    this.semester,
    this.university,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        fullName: (map['full_name'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        department: map['department'] as String?,
        semester: map['semester'] as String?,
        university: map['university'] as String?,
        avatarUrl: map['avatar_url'] as String?,
        createdAt: (DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                DateTime.now())
            .toLocal(),
      );

  Map<String, dynamic> toUpdateMap() => {
        'full_name': fullName,
        'department': department,
        'semester': semester,
        'university': university,
        'avatar_url': avatarUrl,
      };

  Profile copyWith({
    String? fullName,
    String? department,
    String? semester,
    String? university,
    String? avatarUrl,
  }) =>
      Profile(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        department: department ?? this.department,
        semester: semester ?? this.semester,
        university: university ?? this.university,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
      );
}
