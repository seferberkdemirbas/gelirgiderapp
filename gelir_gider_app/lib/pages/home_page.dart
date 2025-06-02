import 'package:flutter/material.dart';
import 'add_transaction_page.dart';
import 'transactions_page.dart';
import 'analytics_page.dart';
import 'budgets_page.dart';
import 'settings_page.dart';
import '../services/budget_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _titles = ['İşlemler', 'Bütçeler', 'Grafikler'];

  Future<void> _goToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    );
    setState(() {}); // ekledikten sonra listeyi yenile
  }

  @override
  Widget build(BuildContext context) {
    // her build’de yeni ana sayfa widget’ları
    final pages = <Widget>[
      TransactionsPage(key: UniqueKey()),
      BudgetsPage(key: UniqueKey()),
      AnalyticsPage(key: UniqueKey()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Finans Yönetimi - ${_titles[_selectedIndex]}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Bütçe Kontrol Et',
            onPressed: () async {
              await BudgetService.checkBudgets();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bütçe kontrolü tamamlandı')),
              );
              setState(() {}); // sayfaları yeniden yükle
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ayarlar',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'İşlemler'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Bütçeler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Grafikler',
          ),
        ],
      ),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                onPressed: _goToAdd,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
