import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Farming App',
      theme: ThemeData(primarySwatch: Colors.green),
      home: LoginScreen(), // Starts with the login screen
    );
  }
}
