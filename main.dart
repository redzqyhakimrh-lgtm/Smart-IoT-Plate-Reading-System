import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAixyilnIJHTt4Bf6xnJsBOlSsnns7DwAs",
      appId: "1:259369687547:web:9a981efdea1f8c4844935e",
      messagingSenderId: "259369687547",
      projectId: "aprs-25281",
      authDomain: "aprs-25281.firebaseapp.com",
      storageBucket: "aprs-25281.firebasestorage.app",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APRS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB),
      ),
      home: const LoginPage(),
    );
  }
}