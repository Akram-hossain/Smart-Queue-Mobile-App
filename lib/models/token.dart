class QueueToken {
  final int id;
  final int tokenNumber;
  final String issuedAt;
  final String status; // 'waiting' | 'serving' | 'done'

  const QueueToken({
    required this.id,
    required this.tokenNumber,
    required this.issuedAt,
    required this.status,
  });

  factory QueueToken.fromMap(Map<String, Object?> map) => QueueToken(
        id: map['id'] as int,
        tokenNumber: map['token_number'] as int,
        issuedAt: map['issued_at'] as String,
        status: map['status'] as String,
      );
}
