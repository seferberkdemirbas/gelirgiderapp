// lib/services/budget_service.dart

import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import 'db_helper.dart';
import 'notification_service.dart';

class BudgetService {
  static Future<void> checkBudgets() async {
    final db = DBHelper.instance;
    final txns = await db.getTransactions();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    // Genel bütçe
    final gen = await db.getBudget(null);
    if (gen != null) {
      final spentGen = txns
          .where((t) => t.isExpense)
          .where((t) {
            final d = DateTime.parse(t.date);
            return !d.isBefore(monthStart) && d.isBefore(monthEnd);
          })
          .fold<double>(0.0, (sum, txn) => sum + txn.amount);

      await _maybeNotify(
        1000,
        'Genel Bütçe Uyarısı',
        spentGen,
        gen.amount,
        'Genel',
      );
    }

    // Kategori bütçeleri
    final budgets = await db.getAllBudgets();
    final cats = await db.getCategories();
    for (var b in budgets.where((b) => b.categoryId != null)) {
      final spentCat = txns
          .where((t) => t.isExpense && t.categoryId == b.categoryId)
          .where((t) {
            final d = DateTime.parse(t.date);
            return !d.isBefore(monthStart) && d.isBefore(monthEnd);
          })
          .fold<double>(0.0, (sum, txn) => sum + txn.amount);

      final name = cats.firstWhere((c) => c.id == b.categoryId).name;
      await _maybeNotify(
        2000 + b.categoryId!,
        '$name Bütçe Uyarısı',
        spentCat,
        b.amount,
        name,
      );
    }
  }

  static Future<void> _maybeNotify(
    int id,
    String title,
    double spent,
    double budget,
    String label,
  ) async {
    final ratio = spent / budget;
    if (ratio >= 1.0) {
      await NotificationService.showNow(
        id: id,
        title: title,
        body:
            '$label bütçeniz aşıldı (harcama: ${spent.toStringAsFixed(2)}₺, bütçe: ${budget.toStringAsFixed(2)}₺)',
      );
    } else if (ratio >= 0.8) {
      await NotificationService.showNow(
        id: id,
        title: title,
        body:
            '$label bütçenizin %80’ine ulaştınız (harcama: ${spent.toStringAsFixed(2)}₺)',
      );
    }
  }
}
