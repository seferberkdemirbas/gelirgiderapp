// lib/services/db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart'; // ★ BudgetModel’ı import ettik

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'transactions.db');
    return await openDatabase(
      path,
      version: 5, // ► v4’e yükselttik
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // categories tablosu
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // transactions tablosu
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        isExpense INTEGER NOT NULL,
        categoryId INTEGER,
        FOREIGN KEY(categoryId) REFERENCES categories(id)
      )
    ''');

    // budgets tablosu
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER,       -- NULL ise genel bütçe
        amount REAL NOT NULL,
        UNIQUE(categoryId)
      )
    ''');

    // Örnek kategoriler
    for (var name in [
      'Fatura',
      'Yiyecek',
      'Ulaşım',
      'Diğer',
      'Kira',
      'Araç',
      'Hediye',
      'Giyim',
    ]) {
      await db.insert('categories', {'name': name});
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: categories ve categoryId ekle
      await db.execute('''
        CREATE TABLE categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN categoryId INTEGER
      ''');
      for (var name in ['Fatura', 'Yiyecek', 'Ulaşım', 'Diğer']) {
        await db.insert('categories', {'name': name});
      }
    }

    if (oldVersion < 4) {
      // v3 → v4: budgets tablosunu ekle
      await db.execute('''
        CREATE TABLE budgets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          categoryId INTEGER,
          amount REAL NOT NULL,
          UNIQUE(categoryId)
        )
      ''');
    }
  }

  // Category CRUD
  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name');
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  // Transaction CRUD
  Future<int> insertTransaction(TransactionModel txn) async {
    final db = await database;
    return await db.insert(
      'transactions',
      txn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT t.*, c.name as categoryName
      FROM transactions t
      LEFT JOIN categories c ON t.categoryId = c.id
      ORDER BY date DESC
    ''');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(
    String monthYear,
  ) async {
    final db = await database;

    final parts = monthYear.split(' ');
    final ayMap = {
      'Ocak': '01',
      'Şubat': '02',
      'Mart': '03',
      'Nisan': '04',
      'Mayıs': '05',
      'Haziran': '06',
      'Temmuz': '07',
      'Ağustos': '08',
      'Eylül': '09',
      'Ekim': '10',
      'Kasım': '11',
      'Aralık': '12',
    };

    final sqliteMonthYear = '${ayMap[parts[0]]}-${parts[1]}';

    final result = await db.rawQuery(
      '''
    SELECT t.*, c.name as categoryName
    FROM transactions t
    LEFT JOIN categories c ON t.categoryId = c.id
    WHERE strftime('%m-%Y', t.date) = ?
    ORDER BY t.date DESC
  ''',
      [sqliteMonthYear],
    );

    return result.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<String>> getDistinctMonths() async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT DISTINCT strftime('%m-%Y', date) as monthYear
    FROM transactions
    ORDER BY monthYear DESC
  ''');

    final ayMap = {
      '01': 'Ocak',
      '02': 'Şubat',
      '03': 'Mart',
      '04': 'Nisan',
      '05': 'Mayıs',
      '06': 'Haziran',
      '07': 'Temmuz',
      '08': 'Ağustos',
      '09': 'Eylül',
      '10': 'Ekim',
      '11': 'Kasım',
      '12': 'Aralık',
    };

    return result.map((row) {
      final parts = row['monthYear'].toString().split('-');
      final ay = ayMap[parts[0]] ?? 'Bilinmeyen';
      return '$ay ${parts[1]}';
    }).toList();
  }

  Future<int> updateTransaction(TransactionModel txn) async {
    final db = await database;
    return await db.update(
      'transactions',
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Budget CRUD

  /// Genel veya kategori bazlı bütçeyi getir
  Future<BudgetModel?> getBudget(int? categoryId) async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      where: categoryId == null ? 'categoryId IS NULL' : 'categoryId = ?',
      whereArgs: categoryId == null ? null : [categoryId],
    );
    if (maps.isEmpty) return null;
    return BudgetModel.fromMap(maps.first);
  }

  /// Yeni veya varolan bütçeyi ekle/güncelle
  Future<void> upsertBudget(BudgetModel b) async {
    final db = await database;

    if (b.categoryId == null) {
      // Genel bütçe için önce güncelleme dene
      final count = await db.update('budgets', {
        'amount': b.amount,
      }, where: 'categoryId IS NULL');
      if (count == 0) {
        // Eğer hiç satır güncellenmediyse, ekle
        await db.insert('budgets', {'categoryId': null, 'amount': b.amount});
      }
    } else {
      // Kategori bütçeleri için eskisi varsa replace et, yoksa ekle
      await db.insert(
        'budgets',
        b.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Tüm bütçeleri getir
  Future<List<BudgetModel>> getAllBudgets() async {
    final db = await database;
    final maps = await db.query('budgets');
    return maps.map((m) => BudgetModel.fromMap(m)).toList();
  }
}
