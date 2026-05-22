class SemesterFee {
  final String id;
  final String userId;
  final String semesterLabel;
  final double totalFee;
  final double paidAmount;
  final DateTime dueDate;
  final String? paymentNote;
  final DateTime createdAt;

  const SemesterFee({
    required this.id,
    required this.userId,
    required this.semesterLabel,
    required this.totalFee,
    required this.paidAmount,
    required this.dueDate,
    this.paymentNote,
    required this.createdAt,
  });

  factory SemesterFee.fromMap(Map<String, dynamic> map) => SemesterFee(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        semesterLabel: map['semester_label'] as String,
        totalFee: (map['total_fee'] as num).toDouble(),
        paidAmount: (map['paid_amount'] as num).toDouble(),
        dueDate: DateTime.parse(map['due_date'] as String),
        paymentNote: map['payment_note'] as String?,
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toInsertMap(String userId) => {
        'user_id': userId,
        'semester_label': semesterLabel,
        'total_fee': totalFee,
        'paid_amount': paidAmount,
        'due_date': _dateOnly(dueDate),
        'payment_note': paymentNote,
      };

  Map<String, dynamic> toUpdateMap() => {
        'semester_label': semesterLabel,
        'total_fee': totalFee,
        'paid_amount': paidAmount,
        'due_date': _dateOnly(dueDate),
        'payment_note': paymentNote,
      };

  double get dueAmount =>
      (totalFee - paidAmount).clamp(0, double.infinity).toDouble();

  double get paidRatio => totalFee == 0 ? 0 : (paidAmount / totalFee).clamp(0, 1);

  bool get isPaid => dueAmount <= 0.0001;

  bool get isOverdue =>
      !isPaid && dueDate.isBefore(DateTime.now());

  SemesterFee copyWith({
    String? semesterLabel,
    double? totalFee,
    double? paidAmount,
    DateTime? dueDate,
    String? paymentNote,
  }) =>
      SemesterFee(
        id: id,
        userId: userId,
        semesterLabel: semesterLabel ?? this.semesterLabel,
        totalFee: totalFee ?? this.totalFee,
        paidAmount: paidAmount ?? this.paidAmount,
        dueDate: dueDate ?? this.dueDate,
        paymentNote: paymentNote ?? this.paymentNote,
        createdAt: createdAt,
      );

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
