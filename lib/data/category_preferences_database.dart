import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

class CategoryPreferencesDatabase {
  static Database? _database;
  static const String _databaseName = 'category_preferences.db';
  static const int _databaseVersion = 1;
  static final Logger _logger = Logger();

  // Table and column names
  static const String _tableName = 'category_preferences';
  static const String _columnId = 'id';
  static const String _columnName = 'name';
  static const String _columnIsHidden = 'is_hidden';
  static const String _columnIconCodePoint = 'icon_code_point';
  static const String _columnColorValue = 'color_value';
  static const String _columnBackgroundColorValue = 'background_color_value';
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
        readOnly: false,
      );
    } catch (e) {
      _logger.e('Error initializing category preferences database: $e');
      rethrow;
    }
  }

  // Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE $_tableName (
          $_columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $_columnName TEXT NOT NULL UNIQUE,
          $_columnIsHidden INTEGER NOT NULL DEFAULT 0,
          $_columnIconCodePoint INTEGER,
          $_columnColorValue INTEGER,
          $_columnBackgroundColorValue INTEGER,
          $_columnCreatedAt INTEGER NOT NULL,
          $_columnUpdatedAt INTEGER NOT NULL
        )
      ''');
    } catch (e) {
      _logger.e('Error creating category preferences table: $e');
      rethrow;
    }
  }

  // Handle database upgrades
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    try {
      if (oldVersion < 1) {
        // Future upgrade logic here
      }
    } catch (e) {
      _logger.e('Error upgrading category preferences database: $e');
      rethrow;
    }
  }

  // Hide a category (mark as deleted)
  static Future<void> hideCategory(String categoryName) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert(_tableName, {
        _columnName: categoryName,
        _columnIsHidden: 1,
        _columnCreatedAt: now,
        _columnUpdatedAt: now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      _logger.e('Error hiding category: $e');
      rethrow;
    }
  }

  // Show a category (unmark as deleted)
  static Future<void> showCategory(String categoryName) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.update(
        _tableName,
        {_columnIsHidden: 0, _columnUpdatedAt: now},
        where: '$_columnName = ?',
        whereArgs: [categoryName],
      );
    } catch (e) {
      _logger.e('Error showing category: $e');
      rethrow;
    }
  }

  // Check if a category is hidden
  static Future<bool> isCategoryHidden(String categoryName) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$_columnName = ? AND $_columnIsHidden = 1',
        whereArgs: [categoryName],
        limit: 1,
      );
      return maps.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking if category is hidden: $e');
      return false;
    }
  }

  // Get all hidden categories
  static Future<List<String>> getHiddenCategories() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$_columnIsHidden = 1',
        columns: [_columnName],
      );
      return maps.map((map) => map[_columnName] as String).toList();
    } catch (e) {
      _logger.e('Error getting hidden categories: $e');
      return [];
    }
  }

  // Save category customizations (icon, color)
  static Future<void> saveCategoryCustomization({
    required String categoryName,
    int? iconCodePoint,
    int? colorValue,
    int? backgroundColorValue,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final data = <String, dynamic>{_columnUpdatedAt: now};

      if (iconCodePoint != null) data[_columnIconCodePoint] = iconCodePoint;
      if (colorValue != null) data[_columnColorValue] = colorValue;
      if (backgroundColorValue != null) {
        data[_columnBackgroundColorValue] = backgroundColorValue;
      }

      await db.insert(_tableName, {
        _columnName: categoryName,
        _columnIsHidden: 0,
        _columnIconCodePoint: iconCodePoint,
        _columnColorValue: colorValue,
        _columnBackgroundColorValue: backgroundColorValue,
        _columnCreatedAt: now,
        _columnUpdatedAt: now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      _logger.e('Error saving category customization: $e');
      rethrow;
    }
  }

  // Get category customization
  static Future<Map<String, dynamic>?> getCategoryCustomization(
    String categoryName,
  ) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$_columnName = ?',
        whereArgs: [categoryName],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return maps.first;
      }
      return null;
    } catch (e) {
      _logger.e('Error getting category customization: $e');
      return null;
    }
  }

  // Get all category customizations
  static Future<Map<String, Map<String, dynamic>>>
  getAllCategoryCustomizations() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName);

      final Map<String, Map<String, dynamic>> customizations = {};
      for (final map in maps) {
        customizations[map[_columnName] as String] = map;
      }

      return customizations;
    } catch (e) {
      _logger.e('Error getting all category customizations: $e');
      return {};
    }
  }

  // Delete category preference (completely remove from preferences)
  static Future<void> deleteCategoryPreference(String categoryName) async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: '$_columnName = ?',
        whereArgs: [categoryName],
      );
    } catch (e) {
      _logger.e('Error deleting category preference: $e');
      rethrow;
    }
  }

  // Clear all preferences
  static Future<void> clearAllPreferences() async {
    try {
      final db = await database;
      await db.delete(_tableName);
    } catch (e) {
      _logger.e('Error clearing all preferences: $e');
      rethrow;
    }
  }
}
