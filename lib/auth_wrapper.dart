import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      // This stream from your AuthService listens for login/logout changes
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        
        // 1. Show a loading spinner while checking the auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. If the snapshot has data, the user is LOGGED IN
        if (snapshot.hasData && snapshot.data != null) {
          // Go to the HomeScreen (this is what your LoginScreen does)
          return const HomeScreen();
        }

        // 3. If the snapshot has no data, the user is LOGGED OUT
        // Show the LoginScreen
        return const LoginScreen();
      },
    );
  }
}
