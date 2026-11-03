class Wallet {
  final int id;
  final String name;
  final String type;
  final String currency;
  final double balance;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    type: json['type'] as String,
    currency: json['currency'] as String,
    balance: (json['balance'] as num).toDouble(),
  );
}
