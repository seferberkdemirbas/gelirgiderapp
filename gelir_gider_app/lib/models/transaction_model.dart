// lib/models/transaction_model.dart

class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String date; // 'yyyy-MM-dd'
  final bool isExpense;
  final int? categoryId; // kategori ilişkisi
  final String? categoryName; // JOIN ile okunacak

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    this.categoryId,
    this.categoryName,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'amount': amount,
    'date': date,
    'isExpense': isExpense ? 1 : 0,
    'categoryId': categoryId,
  };

  factory TransactionModel.fromMap(Map<String, dynamic> m) {
    return TransactionModel(
      id: m['id'] as int?,
      title: m['title'] as String,
      amount: m['amount'] as double,
      date: m['date'] as String,
      isExpense: (m['isExpense'] as int) == 1,
      categoryId: m['categoryId'] as int?,
      categoryName: m['categoryName'] as String?,
    );
  }
}
