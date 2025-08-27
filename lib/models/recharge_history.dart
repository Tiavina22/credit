class RechargeHistory {
  final int? id;
  final String operator;
  final String code;
  final DateTime date;
  final String status;

  RechargeHistory({
    this.id,
    required this.operator,
    required this.code,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operator': operator,
      'code': code,
      'date': date.toIso8601String(),
      'status': status,
    };
  }

  factory RechargeHistory.fromMap(Map<String, dynamic> map) {
    return RechargeHistory(
      id: map['id']?.toInt(),
      operator: map['operator'] ?? '',
      code: map['code'] ?? '',
      date: DateTime.parse(map['date']),
      status: map['status'] ?? '',
    );
  }
}
