import 'package:flutter/material.dart';

class TestConfig {
  static ThemeData get testTheme => ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      );
} 