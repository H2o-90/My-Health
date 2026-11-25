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

  static const Color orangeNeon = Color(0xFFFF5520);
  static const Color amberGlow = Color(0xFFFF9F1C);
  static const Color background = Color(0xFF0A0A0C);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Health',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orangeNeon,
          brightness: Brightness.dark,
          primary: orangeNeon,
          secondary: amberGlow,
          surface: const Color(0xFF151519),
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Color(0xFFE4E4E7)),
          bodyMedium: TextStyle(color: Color(0xFF9A9AA2)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          labelStyle: const TextStyle(color: Color(0xFF9A9AA2)),
          prefixIconColor: orangeNeon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: orangeNeon, width: 1.7),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: orangeNeon,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: orangeNeon,
            side: BorderSide(color: orangeNeon.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E1E24),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: initialLoggedIn ? const HomeShell() : const LoginScreen(),
    );
  }
}