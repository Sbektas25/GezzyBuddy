import 'package:flutter/material.dart';
import 'test_theme.dart';

class TestApp extends StatelessWidget {
  final Widget child;
  final ThemeData? theme;

  const TestApp({
    super.key,
    required this.child,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme ?? TestTheme.theme,
      home: Scaffold(
        body: child,
      ),
    );
  }
} 