import 'package:flutter/material.dart';
import 'screens/input_page.dart';

void main() => runApp(const BMICalculator());

class BMICalculator extends StatelessWidget {
  const BMICalculator({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3F829B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0E161F),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFbc12ab),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
      home: const InputPage(),
    );
  }
}
