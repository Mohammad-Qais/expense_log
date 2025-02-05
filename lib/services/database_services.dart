import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

class DatabaseService {
  static Database? _db;

  static final DatabaseService instance = DatabaseService._constructor();

  DatabaseService._constructor();

  final String _expensesTableName = 'expenses';
  final String _expensesIdColumnName = 'id';
  final String _expensesContentColumnName = 'content';
  final String _expensesAmountColumnName = 'amount';

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }

    _db = await getDatabase();

    return _db!;
  }

  Future<Database> getDatabase() async {
    final databasePath = join(await getDatabasesPath(), 'master_db.db');

    final database = openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE $_expensesTableName (
            $_expensesIdColumnName INTEGER PRIMARY KEY,
            $_expensesContentColumnName TEXT NOT NULL,
            $_expensesAmountColumnName INTEGER NOT NULL
          )
          ''');
      },
    );

    return database;
  }

  Future<void> addExpenseDB(String content, int amount) async {
    final db = await database;

    await db.insert(_expensesTableName, {
      _expensesContentColumnName: content,
      _expensesAmountColumnName: amount,
    });
  }

  Future<List<Expense>> getExpenseDB() async {
    final db = await database;
    final data = await db.query(_expensesTableName);
    List<Expense> expenses = data
        .map((e) => Expense(
            id: e['id'] as int,
            content: e['content'] as String,
            amount: e['amount'] as int))
        .toList();

    return expenses;
  }

  Future<void> deleteExpenseDB(int id) async {
    final db = await database;
  
    await db.delete(
      _expensesTableName, 
      where: 'id = ?', 
      whereArgs: [
      id,
      ],
    );
  }

  Future<List> calculateTotalDB() async {
    final db = await database;

    var result = await db.rawQuery("SELECT SUM($_expensesAmountColumnName) AS Total FROM $_expensesTableName");
    return result.toList();
  }

  
}
