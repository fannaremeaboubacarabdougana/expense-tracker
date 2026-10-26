import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE expenses(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      date TEXT NOT NULL,
      isRecurring INTEGER NOT NULL DEFAULT 0
      recurrence TEXT NOT NULL DEFAULT 'Monthly',
    )
  ''');
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await instance.database;

    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Expense>> getExpenses() async {
    final db = await instance.database;

    final result = await db.query('expenses', orderBy: 'date DESC');

    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<void> deleteExpense(String id) async {
    final db = await instance.database;

    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await instance.database;

    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expenses.db');
    await deleteDatabase(path);
  }

  Future<List<Expense>> getRecurringExpenses() async {
    final db = await instance.database;

    final result = await db.query(
      'expenses',
      where: 'isRecurring = ?',
      whereArgs: [1],
    );

    return result.map((e) => Expense.fromMap(e)).toList();
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
