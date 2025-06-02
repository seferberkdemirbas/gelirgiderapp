// lib/pages/transactions_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/db_helper.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({Key? key}) : super(key: key);

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  Future<List<TransactionModel>> _loadTransactions() {
    return DBHelper.instance.getTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TransactionModel>>(
      future: _loadTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final txns = snapshot.data ?? [];
        if (txns.isEmpty) {
          return const Center(child: Text('Henüz hiç işlem yok'));
        }

        // Bu ayın işlemleri
        final now = DateTime.now();
        final monthTxns =
            txns.where((t) {
              final d = DateTime.parse(t.date);
              return d.year == now.year && d.month == now.month;
            }).toList();

        final monthlyIncome = monthTxns
            .where((t) => !t.isExpense)
            .fold<double>(0, (sum, t) => sum + t.amount);
        final monthlyExpense = monthTxns
            .where((t) => t.isExpense)
            .fold<double>(0, (sum, t) => sum + t.amount);
        final monthlyBalance = monthlyIncome - monthlyExpense;

        return Column(
          children: [
            // Özet kartlar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildSummaryCard(
                    title: 'Aylık Gelir',
                    amount: monthlyIncome,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    title: 'Aylık Gider',
                    amount: monthlyExpense,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    title: 'Aylık Bakiye',
                    amount: monthlyBalance,
                    color: Colors.blueGrey,
                  ),
                ],
              ),
            ),

            // Liste
            Expanded(
              child: ListView.separated(
                itemCount: txns.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final txn = txns[index];
                  final date = DateTime.parse(txn.date);
                  return Dismissible(
                    key: ValueKey(txn.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await DBHelper.instance.deleteTransaction(txn.id!);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('İşlem silindi')),
                      );
                    },
                    child: ListTile(
                      title: Text(txn.title),
                      subtitle: Text(DateFormat('dd.MM.yyyy').format(date)),
                      trailing: Text(
                        '${txn.isExpense ? '-' : '+'}${txn.amount.toStringAsFixed(2)} ₺',
                        style: TextStyle(
                          color: txn.isExpense ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => _showEditDialog(txn),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₺${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(TransactionModel txn) async {
    final _formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: txn.title);
    final amountCtrl = TextEditingController(text: txn.amount.toString());
    bool isExpense = txn.isExpense;
    DateTime date = DateTime.parse(txn.date);

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('İşlemi Düzenle'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Başlık'),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Boş bırakılamaz'
                                  : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Tutar'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Geçerli tutar girin';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (dt != null) {
                          date = dt;
                          setState(() {}); // Dialog içinden date güncellemesi
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tarih'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd.MM.yyyy').format(date)),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Gider mi?'),
                      value: isExpense,
                      onChanged: (v) => setState(() => isExpense = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final updated = TransactionModel(
                    id: txn.id,
                    title: titleCtrl.text.trim(),
                    amount: double.parse(amountCtrl.text.trim()),
                    date: DateFormat('yyyy-MM-dd').format(date),
                    isExpense: isExpense,
                  );
                  await DBHelper.instance.updateTransaction(updated);
                  Navigator.pop(ctx);
                  setState(() {}); // Listeyi yenile
                },
                child: const Text('Güncelle'),
              ),
            ],
          ),
    );
  }
}
