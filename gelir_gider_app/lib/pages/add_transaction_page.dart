// lib/pages/add_transaction_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/db_helper.dart';
import '../services/notification_service.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  double _amount = 0;
  bool _isExpense = true;
  DateTime _date = DateTime.now();

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory; // Hiç kategori seçili başlamıyor

  @override
  void initState() {
    super.initState();
    DBHelper.instance.getCategories().then((cats) {
      setState(() {
        _categories = cats;
        // Burada artık varsayılan atama yok:
        // if (cats.isNotEmpty) _selectedCategory = cats.first;
      });
    });
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final dt = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: DateTime(2100),
    );
    if (dt != null) setState(() => _date = dt);
  }

  // lib/pages/add_transaction_page.dart

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final title = _selectedCategory!.name;
    final txn = TransactionModel(
      title: title,
      amount: _amount,
      date: DateFormat('yyyy-MM-dd').format(_date),
      isExpense: _isExpense,
      categoryId: _selectedCategory!.id,
    );
    final id = await DBHelper.instance.insertTransaction(txn);

    if (_isExpense && title.toLowerCase() == 'fatura') {
      final dueDate = _date;
      final notifyAt = dueDate.subtract(const Duration(days: 2));
      final now = DateTime.now();

      // Eğer 2 gün önceki gün "bugün" ise → anında bildirim
      if (notifyAt.year == now.year &&
          notifyAt.month == now.month &&
          notifyAt.day == now.day) {
        await NotificationService.showNow(
          id: id,
          title: 'Fatura Hatırlatma',
          body:
              '${DateFormat('dd.MM.yyyy').format(dueDate)} tarihli faturanıza 2 gün kaldı.',
        );
      } else {
        // Aksi halde tam notifyAt zamanına planla
        await NotificationService.scheduleNotification(
          id: id,
          title: 'Fatura Hatırlatma',
          body:
              '${DateFormat('dd.MM.yyyy').format(dueDate)} tarihli faturanıza 2 gün kaldı.',
          scheduledDate: notifyAt,
        );
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni İşlem')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ------------------------
              // Kategori seçici (boş başlangıç)
              DropdownButtonFormField<CategoryModel>(
                decoration: const InputDecoration(labelText: 'Kategori'),
                hint: const Text('Kategori seçin'),
                items:
                    _categories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat.name),
                          ),
                        )
                        .toList(),
                value: _selectedCategory,
                onChanged: (cat) => setState(() => _selectedCategory = cat),
                validator: (v) => v == null ? 'Kategori seçin' : null,
              ),
              const SizedBox(height: 16),

              // ------------------------
              TextFormField(
                decoration: const InputDecoration(labelText: 'Tutar'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onSaved: (v) => _amount = double.tryParse(v!) ?? 0,
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return (n == null || n <= 0) ? 'Geçerli tutar girin' : null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Gelir'),
                    selected: !_isExpense,
                    onSelected: (sel) {
                      if (sel) setState(() => _isExpense = false);
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Gider'),
                    selected: _isExpense,
                    onSelected: (sel) {
                      if (sel) setState(() => _isExpense = true);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tarih'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd.MM.yyyy').format(_date)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
