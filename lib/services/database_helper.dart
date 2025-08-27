import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/recharge_history.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'recharge_history.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recharge_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operator TEXT NOT NULL,
        code TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertRecharge(RechargeHistory recharge) async {
    final db = await database;
    return await db.insert('recharge_history', recharge.toMap());
  }

  Future<List<RechargeHistory>> getRechargeHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recharge_history',
      orderBy: 'date DESC',
      limit: 50,
    );

    return List.generate(maps.length, (i) {
      return RechargeHistory.fromMap(maps[i]);
    });
  }

  Future<void> deleteRecharge(int id) async {
    final db = await database;
    await db.delete('recharge_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('recharge_history');
  }
}
