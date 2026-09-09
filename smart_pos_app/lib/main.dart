import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/pos_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase
  // Pastikan file google-services.json sudah diletakkan di android/app/
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase belum terkonfigurasi: $e');
  }

  runApp(const SmartPOSApp());
}

class SmartPOSApp extends StatelessWidget {
  const SmartPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart POS Kasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 1,
        ),
      ),
      home: const POSHomeScreen(),
    );
  }
}
