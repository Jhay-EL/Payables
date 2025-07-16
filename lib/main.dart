import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/dashboard_screen.dart';
import 'data/subscription_database.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for the entire app
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Enable edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize subscription database
  await initializeDatabase();

  runApp(const MyApp());
}

Future<void> initializeDatabase() async {
  try {
    // This will create the database if it doesn't exist
    await SubscriptionDatabase.database;
  } catch (e) {
    // Continue app execution even if database initialization fails
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Fallback to default theme if dynamic colors are not available
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Payables App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
          ),
          themeMode: ThemeMode.system,
          home: Builder(
            builder: (context) {
              final isDarkMode =
                  Theme.of(context).brightness == Brightness.dark;

              // Update system UI overlay style based on current theme
              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  statusBarIconBrightness: isDarkMode
                      ? Brightness.light
                      : Brightness.dark,
                  statusBarBrightness: isDarkMode
                      ? Brightness.dark
                      : Brightness.light,
                  systemNavigationBarIconBrightness: isDarkMode
                      ? Brightness.light
                      : Brightness.dark,
                ),
              );

              return const DashboardScreen();
            },
          ),
        );
      },
    );
  }
}
