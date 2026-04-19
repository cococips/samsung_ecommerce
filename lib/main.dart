import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- 1. IMPORT FIREBASE (SANGAT PENTING) ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'screens/splash_screen.dart';
import 'providers/address_provider.dart';
import 'providers/theme_provider.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()..fetchAddresses()),
        // --- DAFTARKAN MESIN TEMA DI SINI ---
        ChangeNotifierProvider(create: (_) => ThemeProvider()), 
      ],
      child: const SamsungApp(), 
    ),
  );
}

class SamsungApp extends StatelessWidget {
  const SamsungApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- BACA STATUS TEMA DARI PROVIDER ---
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Samsung Store',
      
      // LOGIKA CERDAS: Gunakan darkTheme jika isDarkMode true, jika tidak gunakan theme biasa
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // --- TEMA TERANG (LIGHT MODE) ---
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Inter', 
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, foregroundColor: Color(0xFF1D1D1F), elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000000), foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      // --- TEMA GELAP SULTAN (DARK MODE - PURE BLACK OLED) ---
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Inter', 
        scaffoldBackgroundColor: const Color(0xFF000000), // Hitam pekat untuk OLED
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000), foregroundColor: Colors.white, elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF000000),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white54,
        ),
        cardColor: const Color(0xFF1C1C1E), // Warna abu-abu gelap untuk kotak produk
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, // Tombol jadi putih di mode gelap
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}