import 'enums.dart';

class GpaRecord {
  final String id;
  final String userId;
  final String semesterLabel;
  final String courseName;
  final String? courseCode;
  final double credit;
  final Grade grade;
  final DateTime createdAt;

  const GpaRecord({
    required this.id,
    required this.userId,
    required this.semesterLabel,
    required this.courseName,
    this.courseCode,
    required this.credit,
    required this.grade,
    required this.createdAt,
  });

  factory GpaRecord.fromMap(Map<String, dynamic> map) => GpaRecord(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        semesterLabel: map['semester_label'] as String,
        courseName: map['course_name'] as String,
        courseCode: map['course_code'] as String?,
        credit: (map['credit'] as num).toDouble(),
        grade: Grade.fromLabel(map['grade'] as String),
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toInsertMap(String userId) => {
        'user_id': userId,
        'semester_label': semesterLabel,
        'course_name': courseName,
        'course_code': courseCode,
        'credit': credit,
        'grade': grade.label,
      };

  Map<String, dynamic> toUpdateMap() => {
        'semester_label': semesterLabel,
        'course_name': courseName,
        'course_code': courseCode,
        'credit': credit,
        'grade': grade.label,
      };

  GpaRecord copyWith({
    String? semesterLabel,
    String? courseName,
    String? courseCode,
    double? credit,
    Grade? grade,
  }) =>
      GpaRecord(
        id: id,
        userId: userId,
        semesterLabel: semesterLabel ?? this.semesterLabel,
        courseName: courseName ?? this.courseName,
        courseCode: courseCode ?? this.courseCode,
        credit: credit ?? this.credit,
        grade: grade ?? this.grade,
        createdAt: createdAt,
      );
}
