import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth_wrapper.dart'; // We navigate to our AuthWrapper after

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    // Wait for 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500), () {});
    
    // Go to the AuthWrapper, which will then show the LoginScreen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // You can change the background color if you want
      backgroundColor: Colors.white, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // This is your logo.
            // Make sure you have completed the steps to add 'logo.png'
            Image.network(
  'https://placehold.co/400x400/673AB7/FFFFFF?text=Movo', // A simple placeholder
  height: 250,
),
          ],
        ),
      ),
    );
  }
}
