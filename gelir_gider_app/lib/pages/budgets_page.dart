// lib/pages/budgets_page.dart

import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../services/db_helper.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({Key? key}) : super(key: key);
  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <int?, TextEditingController>{};
  List<CategoryModel> _cats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await DBHelper.instance.getCategories();
    final gen = await DBHelper.instance.getBudget(null);
    final catBs = await DBHelper.instance.getAllBudgets();

    // Eskileri kapat, temizle
    _controllers.values.forEach((c) => c.dispose());
    _controllers.clear();

    setState(() {
      _cats = cats;
      _controllers[null] = TextEditingController(
        text: gen?.amount.toString() ?? '',
      );
      for (var c in cats) {
        final b = catBs.firstWhere(
          (b) => b.categoryId == c.id,
          orElse: () => BudgetModel(categoryId: c.id, amount: 0),
        );
        _controllers[c.id] = TextEditingController(
          text: b.amount > 0 ? b.amount.toString() : '',
        );
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Genel bütçe
    final gVal = double.tryParse(_controllers[null]!.text.trim()) ?? 0.0;
    await DBHelper.instance.upsertBudget(
      BudgetModel(categoryId: null, amount: gVal),
    );

    // Kategori bütçeleri
    for (var c in _cats) {
      final val = double.tryParse(_controllers[c.id]!.text.trim()) ?? 0.0;
      await DBHelper.instance.upsertBudget(
        BudgetModel(categoryId: c.id, amount: val),
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bütçeler kaydedildi')));
    await _load(); // yeniden yükle
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _cats.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _controllers[null],
                        decoration: const InputDecoration(
                          labelText: 'Genel Aylık Bütçe',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return double.tryParse(v) == null
                              ? 'Geçerli sayı girin'
                              : null;
                        },
                      ),
                      ..._cats.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextFormField(
                            controller: _controllers[c.id],
                            decoration: InputDecoration(
                              labelText: '${c.name} Bütçesi',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              return double.tryParse(v) == null
                                  ? 'Geçerli sayı girin'
                                  : null;
                            },
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _save,
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
