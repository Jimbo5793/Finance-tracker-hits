class Operation {
  final int id;
  final int walletId;
  final String type;
  final double amount;
  final DateTime date;
  final int? categoryId;
  final String? comment;
  final double? taxAmount;

  const Operation({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.date,
    this.categoryId,
    this.comment,
    this.taxAmount,
  });

  bool get isIncome => type.toLowerCase() == 'income';

  factory Operation.fromJson(Map<String, dynamic> json) => Operation(
    id: (json['id'] as num).toInt(),
    walletId: (json['walletId'] as num).toInt(),
    type: json['type'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String), // "yyyy-MM-dd"
    categoryId: (json['categoryId'] as num?)?.toInt(),
    comment: json['comment'] as String?,
    taxAmount: (json['taxAmount'] as num?)?.toDouble(),
  );
}
