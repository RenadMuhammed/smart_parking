class PaymentModel {
  final String id;
  final String userId;
  final double amount;
  final String method;
  final DateTime date;

  PaymentModel({required this.id, required this.userId, required this.amount, required this.method, required this.date});

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      userId: json['userId'],
      amount: json['amount'],
      method: json['method'],
      date: DateTime.parse(json['date']),
    );
  }

  get cardNumber => null;

  String? get cardType => null;
}
