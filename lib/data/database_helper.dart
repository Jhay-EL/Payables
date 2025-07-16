import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class DatabaseHelper {
  static Database? _database;
  static const String _databaseName = 'subscriptions_collection_pack.db';

  // Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  static Future<Database> _initDatabase() async {
    try {
      // Get the path to the documents directory
      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, _databaseName);

      // Check if database exists
      bool exists = await databaseExists(path);

      if (!exists) {
        // Copy from assets if it doesn't exist

        try {
          await Directory(dirname(path)).create(recursive: true);
        } catch (_) {}

        // Copy from assets
        ByteData data = await rootBundle.load('lib/data/$_databaseName');
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes);
      }

      // Open the database
      Database db = await openDatabase(
        path,
        version: 1,
        readOnly: true, // Open in read-only mode since we're just reading
      );

      return db;
    } catch (e) {
      rethrow;
    }
  }

  // Get all subscription services from database
  static Future<List<Map<String, dynamic>>> getSubscriptionServices() async {
    try {
      Database db = await database;

      // Try common table names for subscription services
      List<String> possibleTables = [
        'subscriptions',
        'services',
        'subscription_services',
        'apps',
        'companies',
        'brands',
      ];

      for (String tableName in possibleTables) {
        try {
          List<Map<String, dynamic>> result = await db.rawQuery(
            "SELECT * FROM $tableName LIMIT 5",
          );
          if (result.isNotEmpty) {
            return await db.rawQuery("SELECT * FROM $tableName");
          }
        } catch (e) {
          // Table doesn't exist, continue to next
          continue;
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Get subscription icons from database
  static Future<List<Map<String, dynamic>>> getSubscriptionIcons() async {
    try {
      Database db = await database;

      // Try to find tables that might contain icon data
      List<String> possibleIconTables = [
        'icons',
        'subscription_icons',
        'app_icons',
        'service_icons',
        'images',
      ];

      for (String tableName in possibleIconTables) {
        try {
          List<Map<String, dynamic>> result = await db.rawQuery(
            "SELECT * FROM $tableName LIMIT 5",
          );
          if (result.isNotEmpty) {
            return await db.rawQuery("SELECT * FROM $tableName");
          }
        } catch (e) {
          // Table doesn't exist, continue to next
          continue;
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Get all tables in the database
  static Future<List<String>> getAllTables() async {
    try {
      Database db = await database;
      List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      return tables.map((table) => table['name'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  // Get data from any table
  static Future<List<Map<String, dynamic>>> getTableData(
    String tableName,
  ) async {
    try {
      Database db = await database;
      return await db.rawQuery("SELECT * FROM $tableName");
    } catch (e) {
      return [];
    }
  }

  // Search for subscription services by name or category
  static Future<List<Map<String, dynamic>>> searchSubscriptions(
    String query,
  ) async {
    try {
      Database db = await database;

      // Get all tables first
      List<String> tables = await getAllTables();

      for (String tableName in tables) {
        try {
          // Try to search in each table for text fields that might contain subscription names
          List<Map<String, dynamic>> result = await db.rawQuery(
            "SELECT * FROM $tableName WHERE "
            "CAST($tableName.* AS TEXT) LIKE '%$query%' LIMIT 10",
          );

          if (result.isNotEmpty) {
            return result;
          }
        } catch (e) {
          // Skip tables that don't support this query
          continue;
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Close database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
