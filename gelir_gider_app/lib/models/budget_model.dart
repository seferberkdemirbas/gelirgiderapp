// lib/models/budget_model.dart

class BudgetModel {
  final int? id;
  final int? categoryId; 
  final double amount;

  BudgetModel({this.id, this.categoryId, required this.amount});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'categoryId': categoryId,
        'amount': amount,
      };

  factory BudgetModel.fromMap(Map<String, dynamic> m) {
    return BudgetModel(
      id: m['id'] as int?,
      categoryId: m['categoryId'] as int?,
      amount: m['amount'] as double,
    );
  }
}
