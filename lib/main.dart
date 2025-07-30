import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:payables/data/currency_provider.dart';
import 'package:payables/data/subscription_database.dart';
import 'package:provider/provider.dart';
import 'package:payables/ui/dashboard_screen.dart';
import 'package:payables/utils/theme_provider.dart';
import 'package:payables/utils/dashboard_refresh_provider.dart';
import 'package:payables/services/notification_service.dart';
import 'package:payables/utils/material3_color_system.dart';

// Initialize app services in background
void _initializeAppServices(Logger logger) async {
  try {
    // Test database connection
    final dbTest = await SubscriptionDatabase.testDatabaseConnection();
    if (dbTest) {
      logger.i('Database initialization successful');
      final dbInfo = await SubscriptionDatabase.getDatabaseInfo();
      logger.d('Database info: $dbInfo');
    } else {
      logger.e('Database initialization failed');
    }
  } catch (e) {
    logger.e('Database test error: $e');
  }

  // Initialize notification service (with error handling)
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
    logger.i('Notification service initialized successfully');
  } catch (e) {
    logger.e('Failed to initialize notification service: $e');
    // Continue app execution even if notifications fail
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = Logger();

  // Run initialization in background without blocking UI
  _initializeAppServices(logger);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => DashboardRefreshProvider()),
      ],
      child: const PayablesApp(),
    ),
  );
}

class PayablesApp extends StatelessWidget {
  const PayablesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Payables',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: Material3ColorSystem.getLightColorScheme(),
            useMaterial3: true,
            textTheme: TextTheme(
              bodyLarge: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.light),
              ),
              bodyMedium: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.light),
              ),
              bodySmall: TextStyle(
                color: Material3ColorSystem.getOnSurfaceVariantColor(
                  Brightness.light,
                ),
              ),
              titleLarge: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.light),
              ),
              titleMedium: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.light),
              ),
              titleSmall: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.light),
              ),
              labelLarge: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.light),
              ),
              labelMedium: TextStyle(
                color: Material3ColorSystem.getOnSurfaceVariantColor(
                  Brightness.light,
                ),
              ),
              labelSmall: TextStyle(
                color: Material3ColorSystem.getOnSurfaceVariantColor(
                  Brightness.light,
                ),
              ),
              headlineLarge: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.light),
              ),
              headlineMedium: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.light),
              ),
              headlineSmall: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.light),
              ),
              displayLarge: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.light),
              ),
              displayMedium: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.light),
              ),
              displaySmall: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.light),
              ),
            ),
            // Remove default borders
            inputDecorationTheme: InputDecorationTheme(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
            cardTheme: const CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: Material3ColorSystem.getDarkColorScheme(),
            useMaterial3: true,
            textTheme: TextTheme(
              bodyLarge: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.dark),
              ),
              bodyMedium: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.dark),
              ),
              bodySmall: TextStyle(
                color: Material3ColorSystem.getOnSurfaceVariantColor(
                  Brightness.dark,
                ),
              ),
              titleLarge: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.dark),
              ),
              titleMedium: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.dark),
              ),
              titleSmall: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.dark),
              ),
              labelLarge: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.dark),
              ),
              labelMedium: TextStyle(
                color: Material3ColorSystem.getOnSurfaceVariantColor(
                  Brightness.dark,
                ),
              ),
              labelSmall: TextStyle(
                color: Material3ColorSystem.getOnSurfaceVariantColor(
                  Brightness.dark,
                ),
              ),
              headlineLarge: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.dark),
              ),
              headlineMedium: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.dark),
              ),
              headlineSmall: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.dark),
              ),
              displayLarge: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.dark),
              ),
              displayMedium: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.dark),
              ),
              displaySmall: TextStyle(
                color: Material3ColorSystem.getOnSurfaceColor(Brightness.dark),
              ),
            ),
            // Remove default borders
            inputDecorationTheme: InputDecorationTheme(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
            cardTheme: const CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const DashboardScreen(),
        );
      },
    );
  }
}
