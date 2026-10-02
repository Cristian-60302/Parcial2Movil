import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const EcoEatApp());
}

class EcoEatApp extends StatelessWidget {
  const EcoEatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoEat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
