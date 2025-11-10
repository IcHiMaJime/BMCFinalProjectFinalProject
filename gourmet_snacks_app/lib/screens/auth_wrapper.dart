// auth_wrapper.dart

import 'package:gourmet_snacks_app/screens/home_screen.dart';
import 'package:gourmet_snacks_app/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Kinakausap nito ang Firebase para malaman kung may user na naka-login.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {

        // 1. Loading State: Kung naghihintay pa ng data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Logged In State: Kung may data (User object) na galing sa stream
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // 3. Logged Out State: Kung walang data
        return const LoginScreen();
      },
    );
  }
}