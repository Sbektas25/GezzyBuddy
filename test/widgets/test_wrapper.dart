import 'package:flutter/material.dart';
import '../helpers/test_theme.dart';

class TestWrapper extends StatelessWidget {
  final Widget child;

  const TestWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: TestTheme.theme,
      home: Scaffold(
        body: child,
      ),
    );
  }
} 