import 'package:flutter/material.dart';
import 'screens/home_shell_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  final isLoggedIn = await authService.isSessionActive();
  runApp(MyHealthApp(initialLoggedIn: isLoggedIn));
}

class MyHealthApp extends StatelessWidget {
  final bool initialLoggedIn;
  const MyHealthApp({super.key, required this.initialLoggedIn});

  static const Color green = Color(0xFF159B68);
  static const Color darkGreen = Color(0xFF174B37);
  static const Color background = Color(0xFFF5FAF7);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Health',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.light,
          primary: green,
          secondary: const Color(0xFF80CFA9),
          surface: Colors.white,
          onPrimary: Colors.white,
          onSurface: darkGreen,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: darkGreen,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(color: darkGreen, fontWeight: FontWeight.w800),
          titleLarge: TextStyle(color: darkGreen, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: darkGreen, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Color(0xFF365347)),
          bodyMedium: TextStyle(color: Color(0xFF526B5E)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7FBF8),
          labelStyle: const TextStyle(color: Color(0xFF718078)),
          prefixIconColor: green,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE1ECE6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE1ECE6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: green, width: 1.7),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: green,
            side: const BorderSide(color: Color(0xFFB8DDC9)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: const Color(0x14174B37),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: initialLoggedIn ? const HomeShell() : const LoginScreen(),
    );
  }
}