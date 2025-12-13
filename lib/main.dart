import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'ui/dashboard/dashboard_screen.dart';
import 'ui/auth/login_screen.dart';
import 'ui/splash_screen.dart';
import 'firebase_options.dart'; // Ensure this file is generated via 'flutterfire configure'

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase Initialization Error: $e");
    // Continue running app even if Firebase fails (for dev/testing without config)
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Billing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688), // Teal
          secondary: const Color(0xFF2196F3), // Blue
          surface: const Color(0xFFF8F9FA),
          background: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF009688),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Colors.white,
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFE0F2F1)),
          headingTextStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold, 
            color: const Color(0xFF00695C),
            fontSize: 14,
          ),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
             if (states.contains(WidgetState.selected)) return const Color(0xFFE0F2F1);
             return Colors.white;
          }),
          dividerThickness: 0.5,
          columnSpacing: 24,
          headingRowHeight: 60,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 56,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), 
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), 
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), 
            borderSide: const BorderSide(color: Color(0xFF009688), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIconColor: const Color(0xFF009688),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009688),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF009688),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}
