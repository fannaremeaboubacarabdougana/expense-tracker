import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'services/currency_service.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load the saved theme preference.
  final themeService = ThemeService();
  await themeService.loadTheme();
  final currencyService = CurrencyService();
  await currencyService.loadCurrency();

  runApp(
    ExpenseTrackerApp(
      themeService: themeService,
      currencyService: currencyService,
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  final ThemeService themeService;
  final CurrencyService currencyService;

  const ExpenseTrackerApp({
    super.key,
    required this.themeService,
    required this.currencyService,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeService,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Expense Tracker',

          // Light theme.
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          // Dark theme.
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),

          // Saved theme preference.
          themeMode: themeService.themeMode,

          // Firebase authentication remains unchanged.
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return HomeScreen(
                  themeService: themeService,
                  currencyService: currencyService,
                );
              }

              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('Authentication error: ${snapshot.error}'),
                  ),
                );
              }

              if (snapshot.hasData) {
                return HomeScreen(
                  themeService: themeService,
                  currencyService: currencyService,
                );
              }

              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
