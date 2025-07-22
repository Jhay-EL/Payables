import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subscription.dart';

class SubscriptionDatabase {
  static Database? _database;
  static const String _databaseName = 'subscriptions.db';
  static const int _databaseVersion = 4;

  // Table and column names
  static const String _tableName = 'subscriptions';
  static const String _columnId = 'id';
  static const String _columnTitle = 'title';
  static const String _columnCurrency = 'currency';
  static const String _columnAmount = 'amount';
  static const String _columnBillingDate = 'billing_date';
  static const String _columnEndDate = 'end_date';
  static const String _columnBillingCycle = 'billing_cycle';
  static const String _columnType = 'type';
  static const String _columnPaymentMethod = 'payment_method';
  static const String _columnWebsiteLink = 'website_link';
  static const String _columnShortDescription = 'short_description';
  static const String _columnCategory = 'category';
  static const String _columnIconCodePoint = 'icon_code_point';
  static const String _columnIconFilePath = 'icon_file_path';
  static const String _columnColorValue = 'color_value';
  static const String _columnNotes = 'notes';
  static const String _columnStatus = 'status';
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
      rethrow;
    }
  }

  // Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE $_tableName (
          $_columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $_columnTitle TEXT NOT NULL,
          $_columnCurrency TEXT NOT NULL DEFAULT 'EUR',
          $_columnAmount REAL NOT NULL DEFAULT 0.0,
          $_columnBillingDate INTEGER NOT NULL,
          $_columnEndDate INTEGER,
          $_columnBillingCycle TEXT NOT NULL DEFAULT 'Monthly',
          $_columnType TEXT NOT NULL DEFAULT 'Recurring',
          $_columnPaymentMethod TEXT NOT NULL DEFAULT 'Not set',
          $_columnWebsiteLink TEXT,
          $_columnShortDescription TEXT,
          $_columnCategory TEXT NOT NULL DEFAULT 'Not set',
          $_columnIconCodePoint INTEGER,
          $_columnIconFilePath TEXT,
          $_columnColorValue INTEGER NOT NULL DEFAULT 4278190080,
          $_columnNotes TEXT,
          $_columnStatus TEXT NOT NULL DEFAULT 'active',
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
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $_tableName ADD COLUMN $_columnIconFilePath TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE $_tableName ADD COLUMN $_columnType TEXT NOT NULL DEFAULT 'Recurring'",
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE $_tableName ADD COLUMN $_columnStatus TEXT NOT NULL DEFAULT 'active'",
      );
    }
  }

  // Insert a new subscription
  static Future<int> insertSubscription(Subscription subscription) async {
    try {
      final db = await database;
      final now = DateTime.now();

      // Create subscription with timestamps
      final subscriptionWithTimestamp = subscription.copyWith(
        createdAt: now,
        updatedAt: now,
      );

      int id = await db.insert(_tableName, subscriptionWithTimestamp.toMap());
      return id;
    } catch (e) {
      rethrow;
    }
  }

  // Get all subscriptions
  static Future<List<Subscription>> getAllSubscriptions() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: '$_columnBillingDate ASC',
      );

      return List.generate(maps.length, (i) {
        return Subscription.fromMap(maps[i]);
      });
    } catch (e) {
      return [];
    }
  }

  // Get subscription by ID
  static Future<Subscription?> getSubscriptionById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$_columnId = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Subscription.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get subscriptions by category
  static Future<List<Subscription>> getSubscriptionsByCategory(
    String category,
  ) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$_columnCategory = ?',
        whereArgs: [category],
        orderBy: '$_columnBillingDate ASC',
      );

      return List.generate(maps.length, (i) {
        return Subscription.fromMap(maps[i]);
      });
    } catch (e) {
      return [];
    }
  }

  // Get upcoming subscriptions (due within specified days)
  static Future<List<Subscription>> getUpcomingSubscriptions({
    int daysAhead = 7,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now();
      final future = now.add(Duration(days: daysAhead));

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$_columnBillingDate BETWEEN ? AND ?',
        whereArgs: [now.millisecondsSinceEpoch, future.millisecondsSinceEpoch],
        orderBy: '$_columnBillingDate ASC',
      );

      return List.generate(maps.length, (i) {
        return Subscription.fromMap(maps[i]);
      });
    } catch (e) {
      return [];
    }
  }

  // Update subscription
  static Future<int> updateSubscription(Subscription subscription) async {
    try {
      final db = await database;

      // Update the updatedAt timestamp
      final updatedSubscription = subscription.copyWith(
        updatedAt: DateTime.now(),
      );

      int count = await db.update(
        _tableName,
        updatedSubscription.toMap(),
        where: '$_columnId = ?',
        whereArgs: [subscription.id],
      );

      return count;
    } catch (e) {
      rethrow;
    }
  }

  // Update subscription status
  static Future<int> updateSubscriptionStatus(int id, String status) async {
    try {
      final db = await database;

      int count = await db.update(
        _tableName,
        {
          _columnStatus: status,
          _columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '$_columnId = ?',
        whereArgs: [id],
      );

      return count;
    } catch (e) {
      rethrow;
    }
  }

  // Delete subscription
  static Future<int> deleteSubscription(int id) async {
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

  // Search subscriptions
  static Future<List<Subscription>> searchSubscriptions(String query) async {
    try {
      final db = await database;
      final String searchQuery = '%${query.toLowerCase()}%';

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where:
            '''
          LOWER($_columnTitle) LIKE ? OR 
          LOWER($_columnShortDescription) LIKE ? OR 
          LOWER($_columnCategory) LIKE ?
        ''',
        whereArgs: [searchQuery, searchQuery, searchQuery],
        orderBy: '$_columnBillingDate ASC',
      );

      return List.generate(maps.length, (i) {
        return Subscription.fromMap(maps[i]);
      });
    } catch (e) {
      return [];
    }
  }

  // Get total monthly cost
  static Future<double> getTotalMonthlyCost() async {
    try {
      final subscriptions = await getAllSubscriptions();
      double total = 0.0;

      for (var subscription in subscriptions) {
        switch (subscription.billingCycle) {
          case 'Daily':
            total += subscription.amount * 30; // Approximate monthly cost
            break;
          case 'Weekly':
            total += subscription.amount * 4.33; // Approximate monthly cost
            break;
          case 'Monthly':
            total += subscription.amount;
            break;
          case 'Yearly':
            total += subscription.amount / 12; // Monthly equivalent
            break;
        }
      }

      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // Get subscriptions count
  static Future<int> getSubscriptionsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Get paused subscriptions
  static Future<List<Subscription>> getPausedSubscriptions() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$_columnStatus = ?',
        whereArgs: ['paused'],
        orderBy: '$_columnBillingDate ASC',
      );

      return List.generate(maps.length, (i) {
        return Subscription.fromMap(maps[i]);
      });
    } catch (e) {
      return [];
    }
  }

  // Get finished subscriptions (either status is 'finished' or endDate is in the past)
  static Future<List<Subscription>> getFinishedSubscriptions() async {
    try {
      final db = await database;
      final now = DateTime.now();

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where:
            '$_columnStatus = ? OR ($_columnEndDate IS NOT NULL AND $_columnEndDate < ?)',
        whereArgs: ['finished', now.millisecondsSinceEpoch],
        orderBy: '$_columnBillingDate ASC',
      );

      return List.generate(maps.length, (i) {
        return Subscription.fromMap(maps[i]);
      });
    } catch (e) {
      return [];
    }
  }

  // Get active subscriptions (not paused or finished)
  static Future<List<Subscription>> getActiveSubscriptions() async {
    try {
      final db = await database;
      final now = DateTime.now();

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where:
            '$_columnStatus = ? AND ($_columnEndDate IS NULL OR $_columnEndDate >= ?)',
        whereArgs: ['active', now.millisecondsSinceEpoch],
        orderBy: '$_columnBillingDate ASC',
      );

      return List.generate(maps.length, (i) {
        return Subscription.fromMap(maps[i]);
      });
    } catch (e) {
      return [];
    }
  }

  // Clear all subscriptions (for testing or reset)
  static Future<void> clearAllSubscriptions() async {
    try {
      final db = await database;
      await db.delete(_tableName);
    } catch (e) {
      rethrow;
    }
  }

  // Force refresh database connection
  static Future<void> forceRefreshConnection() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Ensure database is synchronized
  static Future<void> ensureDatabaseSync() async {
    try {
      final db = await database;
      await db.execute('PRAGMA wal_checkpoint(FULL)');
    } catch (e) {
      // This is non-critical, so we don't rethrow
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
