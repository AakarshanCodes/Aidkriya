import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/firebase_options.dart';
// 1. We are removing the import for WalkRequestsScreen
// 2. We are adding the new import for our AuthWrapper
import 'package:flutter_application_1/auth_wrapper.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AIDkriyaApp());
}

class AIDkriyaApp extends StatelessWidget {
  const AIDkriyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOVO',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 3. This is the fix:
      // We are changing the 'home' to our new AuthWrapper.
      home: const AuthWrapper(),
    );
  }
}