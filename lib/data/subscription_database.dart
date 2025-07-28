import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import '../models/subscription.dart';
import '../services/notification_service.dart';
import 'dart:io'; // Added for File

class SubscriptionDatabase {
  static Database? _database;
  static const String _databaseName = 'subscriptions.db';
  static const int _databaseVersion = 5;
  static final Logger _logger = Logger();

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
  static const String _columnAlertDays = 'alert_days';
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
          $_columnAlertDays INTEGER DEFAULT 1,
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
    try {
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
      if (oldVersion < 5) {
        // Check if alert_days column already exists
        try {
          await db.execute(
            "ALTER TABLE $_tableName ADD COLUMN $_columnAlertDays INTEGER",
          );
          // Update existing rows to have default value
          await db.execute(
            "UPDATE $_tableName SET $_columnAlertDays = 1 WHERE $_columnAlertDays IS NULL",
          );
        } catch (e) {
          // Column might already exist, ignore the error
          _logger.w('Alert days column might already exist: $e');
        }
      }
    } catch (e) {
      _logger.e('Database upgrade error: $e');
      rethrow;
    }
  }

  // Insert a new subscription
  static Future<int> insertSubscription(Subscription subscription) async {
    try {
      final db = await database;

      // Use the subscription as-is since timestamps are already set
      final subscriptionWithTimestamp = subscription;

      final subscriptionMap = subscriptionWithTimestamp.toMap();
      _logger.d('Inserting subscription with data: $subscriptionMap');

      int id = await db.insert(_tableName, subscriptionMap);

      // Schedule notification for the new subscription (handle errors gracefully)
      if (subscription.status == 'active') {
        try {
          final subscriptionWithId = subscriptionWithTimestamp.copyWith(id: id);
          await NotificationService().scheduleSubscriptionNotification(
            subscriptionWithId,
          );
        } catch (notificationError) {
          _logger.w(
            'Failed to schedule notification for subscription $id: $notificationError',
          );
          // Don't rethrow - the subscription was saved successfully
        }
      }

      return id;
    } catch (e) {
      _logger.e('Error inserting subscription: $e');
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

      final subscriptionMap = updatedSubscription.toMap();
      _logger.d('Updating subscription with data: $subscriptionMap');

      int count = await db.update(
        _tableName,
        subscriptionMap,
        where: '$_columnId = ?',
        whereArgs: [subscription.id],
      );

      // Update notification for the subscription (handle errors gracefully)
      try {
        await NotificationService().updateSubscriptionNotifications(
          updatedSubscription,
        );
      } catch (notificationError) {
        _logger.w(
          'Failed to update notifications for subscription ${subscription.id}: $notificationError',
        );
        // Don't rethrow - the subscription was updated successfully
      }

      return count;
    } catch (e) {
      _logger.e('Error updating subscription: $e');
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

      // Cancel notifications for the deleted subscription
      await NotificationService().cancelSubscriptionNotifications(id);

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

  // Force recreate database (for testing)
  static Future<void> forceRecreateDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, _databaseName);

      // Delete existing database file
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        _logger.i('Deleted existing database file');
      }

      // Recreate database
      _database = await _initDatabase();
      _logger.i('Recreated database successfully');
    } catch (e) {
      _logger.e('Error recreating database: $e');
      rethrow;
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

  // Test database connection
  static Future<bool> testDatabaseConnection() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT 1 as test');
      _logger.d('Database connection test successful: $result');
      return true;
    } catch (e) {
      _logger.e('Database connection test failed: $e');
      return false;
    }
  }

  // Get database info
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final db = await database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      final subscriptionColumns = await db.rawQuery(
        "PRAGMA table_info($_tableName)",
      );

      return {
        'tables': tables,
        'subscription_columns': subscriptionColumns,
        'database_version': await db.getVersion(),
      };
    } catch (e) {
      _logger.e('Error getting database info: $e');
      return {'error': e.toString()};
    }
  }

  // Get all subscriptions with computed counts for dashboard optimization
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final db = await database;

      // Use a single optimized query with computed values
      final now = DateTime.now();
      final weekFromNow = now.add(const Duration(days: 7));
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Single query to get all data with computed counts
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT 
          *,
          CASE 
            WHEN status = 'active' AND billing_date BETWEEN ? AND ? THEN 1 
            ELSE 0 
          END as is_this_week,
          CASE 
            WHEN status = 'active' AND billing_date BETWEEN ? AND ? THEN 1 
            ELSE 0 
          END as is_this_month
        FROM $_tableName 
        ORDER BY billing_date ASC
      ''',
        [
          now.millisecondsSinceEpoch,
          weekFromNow.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch,
          currentMonthEnd.millisecondsSinceEpoch,
        ],
      );

      // Efficient single-pass processing
      final List<Subscription> allSubscriptions = [];
      final List<Subscription> activeSubscriptions = [];
      final List<Subscription> pausedSubscriptions = [];
      final List<Subscription> finishedSubscriptions = [];

      int activeCount = 0;
      int pausedCount = 0;
      int finishedCount = 0;
      int thisWeekCount = 0;
      int thisMonthCount = 0;
      final Map<String, int> categoryCounts = <String, int>{};

      for (final map in maps) {
        final subscription = Subscription.fromMap(map);
        allSubscriptions.add(subscription);

        // Single-pass categorization and counting
        switch (subscription.status) {
          case 'active':
            activeCount++;
            activeSubscriptions.add(subscription);

            // Use pre-computed values from SQL
            if (map['is_this_week'] == 1) thisWeekCount++;
            if (map['is_this_month'] == 1) thisMonthCount++;

            categoryCounts[subscription.category] =
                (categoryCounts[subscription.category] ?? 0) + 1;
            break;
          case 'paused':
            pausedCount++;
            pausedSubscriptions.add(subscription);
            break;
          case 'finished':
            finishedCount++;
            finishedSubscriptions.add(subscription);
            break;
        }
      }

      return {
        'allSubscriptions': allSubscriptions,
        'activeSubscriptions': activeSubscriptions,
        'pausedSubscriptions': pausedSubscriptions,
        'finishedSubscriptions': finishedSubscriptions,
        'counts': {
          'total': allSubscriptions.length,
          'active': activeCount,
          'paused': pausedCount,
          'finished': finishedCount,
          'thisWeek': thisWeekCount,
          'thisMonth': thisMonthCount,
        },
        'categoryCounts': categoryCounts,
      };
    } catch (e) {
      return {
        'allSubscriptions': [],
        'activeSubscriptions': [],
        'pausedSubscriptions': [],
        'finishedSubscriptions': [],
        'counts': {
          'total': 0,
          'active': 0,
          'paused': 0,
          'finished': 0,
          'thisWeek': 0,
          'thisMonth': 0,
        },
        'categoryCounts': {},
      };
    }
  }
}
