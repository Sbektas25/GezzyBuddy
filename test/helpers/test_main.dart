import 'package:flutter/material.dart';
import 'test_config.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: TestConfig.testTheme,
      home: const Scaffold(
        body: Center(
          child: Text('Test App'),
        ),
      ),
    );
  }
} 