class AttendanceItem {
  final String id;
  final String userId;
  final String subjectName;
  final int totalClasses;
  final int attendedClasses;
  final DateTime createdAt;

  const AttendanceItem({
    required this.id,
    required this.userId,
    required this.subjectName,
    required this.totalClasses,
    required this.attendedClasses,
    required this.createdAt,
  });

  factory AttendanceItem.fromMap(Map<String, dynamic> map) => AttendanceItem(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        subjectName: map['subject_name'] as String,
        totalClasses: (map['total_classes'] as num).toInt(),
        attendedClasses: (map['attended_classes'] as num).toInt(),
        createdAt: (DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                DateTime.now())
            .toLocal(),
      );

  Map<String, dynamic> toInsertMap(String userId) => {
        'user_id': userId,
        'subject_name': subjectName,
        'total_classes': totalClasses,
        'attended_classes': attendedClasses,
      };

  Map<String, dynamic> toUpdateMap() => {
        'subject_name': subjectName,
        'total_classes': totalClasses,
        'attended_classes': attendedClasses,
      };

  double get percentage =>
      totalClasses == 0 ? 0 : (attendedClasses / totalClasses) * 100;

  bool get isBelowThreshold => totalClasses > 0 && percentage < 75;

  AttendanceItem copyWith({
    String? subjectName,
    int? totalClasses,
    int? attendedClasses,
  }) =>
      AttendanceItem(
        id: id,
        userId: userId,
        subjectName: subjectName ?? this.subjectName,
        totalClasses: totalClasses ?? this.totalClasses,
        attendedClasses: attendedClasses ?? this.attendedClasses,
        createdAt: createdAt,
      );
}
