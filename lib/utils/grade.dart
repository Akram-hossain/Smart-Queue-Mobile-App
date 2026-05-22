import '../models/enums.dart';
import '../models/gpa_record.dart';

class GradeCalc {
  /// Standard credit-weighted GPA: Σ(credit × points) / Σ(credit).
  static double gpa(Iterable<GpaRecord> records) {
    double totalPoints = 0;
    double totalCredits = 0;
    for (final r in records) {
      totalPoints += r.credit * r.grade.points;
      totalCredits += r.credit;
    }
    if (totalCredits == 0) return 0;
    return totalPoints / totalCredits;
  }

  /// Per-semester GPA map keyed by semesterLabel.
  static Map<String, double> bySemester(Iterable<GpaRecord> records) {
    final groups = <String, List<GpaRecord>>{};
    for (final r in records) {
      groups.putIfAbsent(r.semesterLabel, () => []).add(r);
    }
    return {
      for (final entry in groups.entries) entry.key: gpa(entry.value),
    };
  }

  /// Letter assignment for a GPA value.
  static Grade letter(double gpa) {
    if (gpa >= 3.875) return Grade.aPlus;
    if (gpa >= 3.625) return Grade.a;
    if (gpa >= 3.375) return Grade.aMinus;
    if (gpa >= 3.125) return Grade.bPlus;
    if (gpa >= 2.875) return Grade.b;
    if (gpa >= 2.625) return Grade.bMinus;
    if (gpa >= 2.375) return Grade.cPlus;
    if (gpa >= 2.125) return Grade.c;
    if (gpa >= 1.875) return Grade.d;
    return Grade.f;
  }
}
