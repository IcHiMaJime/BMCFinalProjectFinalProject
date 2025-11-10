// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:gourmet_snacks_app/screens/auth_wrapper.dart';
import 'package:gourmet_snacks_app/providers/cart_provider.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';

// --- UPDATED BLUE COLOR PALETTE ---
const Color kBlue = Color(0xFF2196F3); // Standard Blue (Primary)
const Color kLightBlue = Color(0xFF64B5F6); // Lighter accent blue (Secondary)
const Color kLightBackground = Color(0xFFE3F2FD); // Very light blue background

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final cartProvider = CartProvider();
        cartProvider.initialize();
        return cartProvider;
      },
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gourmet Snacks Marketplace',
      theme: ThemeData(
        fontFamily: GoogleFonts.lato().fontFamily,

        // Global color scheme
        colorScheme: ColorScheme.light(
          primary: kBlue, // Main color for buttons, etc.
          secondary: kLightBlue, // Accent color
          background: kLightBackground, // Soft light blue background color
          surface: Colors.white, // Card and sheet backgrounds
        ),
        useMaterial3: true,

        // --- Custom Global Widget Styles ---

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),

        // ElevatedButton Theme (Blue, rounded corners)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),

        // Input Field Theme (Rounded corners, outlined in blue)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBlue, width: 2),
          ),
          labelStyle: GoogleFonts.lato(color: Colors.grey[600]),
        ),

        // Inalis ang CardTheme upang maiwasan ang type error sa iyong SDK.
      ),
      home: const AuthWrapper(),
    );
  }
}