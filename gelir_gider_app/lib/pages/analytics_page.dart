import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../services/db_helper.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<String> aylar = [];
  String? secilenAy;
  late Future<List<TransactionModel>> _txnsFuture;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    aylar = await DBHelper.instance.getDistinctMonths();
    if (aylar.isNotEmpty) {
      secilenAy = aylar.first;
      _txnsFuture = DBHelper.instance.getTransactionsByMonth(secilenAy!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (secilenAy == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        DropdownButton<String>(
          value: secilenAy,
          items:
              aylar.map((ay) {
                return DropdownMenuItem(value: ay, child: Text(ay));
              }).toList(),
          onChanged: (yeniAy) {
            setState(() {
              secilenAy = yeniAy!;
              _txnsFuture = DBHelper.instance.getTransactionsByMonth(
                secilenAy!,
              );
            });
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<TransactionModel>>(
            future: _txnsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final txns = snapshot.data ?? [];

              final incomeMap = <String, double>{};
              final expenseMap = <String, double>{};
              for (var t in txns) {
                final cat = t.categoryName ?? 'Diğer';
                if (t.isExpense) {
                  expenseMap[cat] = (expenseMap[cat] ?? 0) + t.amount;
                } else {
                  incomeMap[cat] = (incomeMap[cat] ?? 0) + t.amount;
                }
              }

              final totalIncome = incomeMap.values.fold(0.0, (a, b) => a + b);
              final totalExpense = expenseMap.values.fold(0.0, (a, b) => a + b);

              final incomeColors = <Color>[
                Colors.greenAccent,
                Colors.blueAccent,
                Colors.orangeAccent,
                Colors.purpleAccent,
                Colors.tealAccent,
                Colors.redAccent,
              ];
              final expenseColors = <Color>[
                Colors.redAccent,
                Colors.orangeAccent,
                Colors.purpleAccent,
                Colors.tealAccent,
                Colors.greenAccent,
                Colors.blueAccent,
              ];
              final overallColors = [Colors.greenAccent, Colors.redAccent];

              Widget buildOverallChart() {
                if (totalIncome + totalExpense == 0) {
                  return const Center(
                    child: Text('Henüz gelir/gider verisi yok'),
                  );
                }
                final sections = [
                  PieChartSectionData(
                    color: overallColors[0],
                    value: totalIncome,
                    title: '${totalIncome.toStringAsFixed(0)}₺',
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  PieChartSectionData(
                    color: overallColors[1],
                    value: totalExpense,
                    title: '${totalExpense.toStringAsFixed(0)}₺',
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Genel Gelir-Gider Dağılımı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 30,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _legendItem(overallColors[0], 'Gelir'),
                        const SizedBox(width: 16),
                        _legendItem(overallColors[1], 'Gider'),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }

              Widget buildCategoryChart(
                String title,
                Map<String, double> dataMap,
                List<Color> colors,
              ) {
                if (dataMap.isEmpty) {
                  return Center(child: Text('Henüz $title yok'));
                }
                final sections = <PieChartSectionData>[];
                int i = 0;
                dataMap.forEach((category, amount) {
                  final color = colors[i % colors.length];
                  sections.add(
                    PieChartSectionData(
                      color: color,
                      value: amount,
                      title: '${amount.toStringAsFixed(0)}₺',
                      radius: 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                  i++;
                });
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 30,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          dataMap.keys.map((category) {
                            final idx = dataMap.keys.toList().indexOf(category);
                            final color = colors[idx % colors.length];
                            return _legendItem(color, category);
                          }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildCategoryChart(
                      'Gelir Dağılımı',
                      incomeMap,
                      incomeColors,
                    ),
                    buildCategoryChart(
                      'Gider Dağılımı',
                      expenseMap,
                      expenseColors,
                    ),
                    buildOverallChart(),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
