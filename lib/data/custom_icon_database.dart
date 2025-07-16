import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CustomIconDatabase {
  static const _databaseName = 'custom_icons.db';
  static const _tableName = 'custom_icons';
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertIcon(String path) async {
    final db = await database;
    return await db.insert(_tableName, {'path': path});
  }

  Future<List<Map<String, dynamic>>> getIcons() async {
    final db = await database;
    return await db.query(_tableName);
  }

  Future<void> deleteIcon(int id, String path) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
