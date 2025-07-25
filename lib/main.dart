import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:payables/data/currency_provider.dart';
import 'package:payables/data/subscription_database.dart';
import 'package:provider/provider.dart';
import 'package:payables/ui/dashboard_screen.dart';
import 'package:payables/utils/theme_provider.dart';
import 'package:payables/utils/dashboard_refresh_provider.dart';
import 'package:payables/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = Logger();

  // Test database connection
  try {
    logger.i('Testing database connection...');
    final dbTest = await SubscriptionDatabase.testDatabaseConnection();
    if (dbTest) {
      logger.i('Database connection successful');
      final dbInfo = await SubscriptionDatabase.getDatabaseInfo();
      logger.d('Database info: $dbInfo');
    } else {
      logger.e('Database connection failed');
    }
  } catch (e) {
    logger.e('Database test error: $e');
  }

  // Initialize notification service (with error handling)
  try {
    await NotificationService().initialize();

    // Request notification permissions on first app launch
    await NotificationService().requestPermissions();
  } catch (e) {
    logger.e('Failed to initialize notification service: $e');
    // Continue app execution even if notifications fail
  }

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
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF191c20)),
              bodyMedium: TextStyle(color: Color(0xFF191c20)),
              bodySmall: TextStyle(color: Color(0xFF191c20)),
              titleLarge: TextStyle(color: Color(0xFF191c20)),
              titleMedium: TextStyle(color: Color(0xFF191c20)),
              titleSmall: TextStyle(color: Color(0xFF191c20)),
              labelLarge: TextStyle(color: Color(0xFF191c20)),
              labelMedium: TextStyle(color: Color(0xFF191c20)),
              labelSmall: TextStyle(color: Color(0xFF191c20)),
              headlineLarge: TextStyle(color: Color(0xFF191c20)),
              headlineMedium: TextStyle(color: Color(0xFF191c20)),
              headlineSmall: TextStyle(color: Color(0xFF191c20)),
              displayLarge: TextStyle(color: Color(0xFF191c20)),
              displayMedium: TextStyle(color: Color(0xFF191c20)),
              displaySmall: TextStyle(color: Color(0xFF191c20)),
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
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF191c20)),
              bodyMedium: TextStyle(color: Color(0xFF191c20)),
              bodySmall: TextStyle(color: Color(0xFF191c20)),
              titleLarge: TextStyle(color: Color(0xFF191c20)),
              titleMedium: TextStyle(color: Color(0xFF191c20)),
              titleSmall: TextStyle(color: Color(0xFF191c20)),
              labelLarge: TextStyle(color: Color(0xFF191c20)),
              labelMedium: TextStyle(color: Color(0xFF191c20)),
              labelSmall: TextStyle(color: Color(0xFF191c20)),
              headlineLarge: TextStyle(color: Color(0xFF191c20)),
              headlineMedium: TextStyle(color: Color(0xFF191c20)),
              headlineSmall: TextStyle(color: Color(0xFF191c20)),
              displayLarge: TextStyle(color: Color(0xFF191c20)),
              displayMedium: TextStyle(color: Color(0xFF191c20)),
              displaySmall: TextStyle(color: Color(0xFF191c20)),
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
