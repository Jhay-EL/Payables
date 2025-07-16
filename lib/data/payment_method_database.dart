import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment_method.dart';

class PaymentMethodDatabase {
  static Database? _database;
  static const String _databaseName = 'payment_methods.db';
  static const int _databaseVersion = 1;

  // Table and column names
  static const String _tableName = 'payment_methods';
  static const String _columnId = 'id';
  static const String _columnName = 'name';
  static const String _columnCardName = 'card_name';
  static const String _columnLastFourDigits = 'last_four_digits';
  static const String _columnIconCodePoint = 'icon_code_point';
  static const String _columnCreatedAt = 'created_at';
  static const String _columnUpdatedAt = 'updated_at';

  // Get database instance (singleton)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  static Future<Database> _initDatabase() async {
    try {
      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE $_tableName (
          $_columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $_columnName TEXT NOT NULL,
          $_columnCardName TEXT NOT NULL,
          $_columnLastFourDigits TEXT NOT NULL,
          $_columnIconCodePoint INTEGER NOT NULL,
          $_columnCreatedAt INTEGER NOT NULL,
          $_columnUpdatedAt INTEGER NOT NULL
        )
      ''');
    } catch (e) {
      rethrow;
    }
  }

  // Handle database upgrades
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database schema changes here if needed in future versions
  }

  // Insert a new payment method
  static Future<int> insertPaymentMethod(PaymentMethod paymentMethod) async {
    try {
      final db = await database;
      final now = DateTime.now();

      // Create payment method with timestamps
      final paymentMethodWithTimestamp = paymentMethod.copyWith(
        createdAt: now,
        updatedAt: now,
      );

      int id = await db.insert(_tableName, paymentMethodWithTimestamp.toMap());
      return id;
    } catch (e) {
      rethrow;
    }
  }

  // Get all payment methods
  static Future<List<PaymentMethod>> getAllPaymentMethods() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: '$_columnCreatedAt ASC',
      );

      return List.generate(maps.length, (i) {
        return PaymentMethod.fromMap(maps[i]);
      });
    } catch (e) {
      return [];
    }
  }

  // Get payment method by ID
  static Future<PaymentMethod?> getPaymentMethodById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$_columnId = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return PaymentMethod.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get payment method by name
  static Future<PaymentMethod?> getPaymentMethodByName(String name) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$_columnName = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return PaymentMethod.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update payment method
  static Future<int> updatePaymentMethod(PaymentMethod paymentMethod) async {
    try {
      final db = await database;

      // Update the updatedAt timestamp
      final updatedPaymentMethod = paymentMethod.copyWith(
        updatedAt: DateTime.now(),
      );

      int count = await db.update(
        _tableName,
        updatedPaymentMethod.toMap(),
        where: '$_columnId = ?',
        whereArgs: [paymentMethod.id],
      );

      return count;
    } catch (e) {
      rethrow;
    }
  }

  // Delete payment method
  static Future<int> deletePaymentMethod(int id) async {
    try {
      final db = await database;
      int count = await db.delete(
        _tableName,
        where: '$_columnId = ?',
        whereArgs: [id],
      );

      return count;
    } catch (e) {
      rethrow;
    }
  }

  // Delete payment method by name
  static Future<int> deletePaymentMethodByName(String name) async {
    try {
      final db = await database;
      int count = await db.delete(
        _tableName,
        where: '$_columnName = ?',
        whereArgs: [name],
      );

      return count;
    } catch (e) {
      rethrow;
    }
  }

  // Search payment methods
  static Future<List<PaymentMethod>> searchPaymentMethods(String query) async {
    try {
      final db = await database;
      final String searchQuery = '%${query.toLowerCase()}%';

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where:
            '''
          LOWER($_columnName) LIKE ? OR 
          LOWER($_columnCardName) LIKE ?
        ''',
        whereArgs: [searchQuery, searchQuery],
        orderBy: '$_columnCreatedAt ASC',
      );

      return List.generate(maps.length, (i) {
        return PaymentMethod.fromMap(maps[i]);
      });
    } catch (e) {
      return [];
    }
  }

  // Get payment methods count
  static Future<int> getPaymentMethodsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Clear all payment methods (for testing or reset)
  static Future<void> clearAllPaymentMethods() async {
    try {
      final db = await database;
      await db.delete(_tableName);
    } catch (e) {
      rethrow;
    }
  }

  // Check if payment method name exists
  static Future<bool> paymentMethodNameExists(String name) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$_columnName = ?',
        whereArgs: [name],
        limit: 1,
      );

      return maps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Close database
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
