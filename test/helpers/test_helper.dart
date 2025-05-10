import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_theme.dart';

class TestHelper {
  static Widget createTestableWidget(
    Widget child, {
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? TestTheme.theme,
      home: Scaffold(
        body: child,
      ),
    );
  }

  static Future<void> pumpWidget(
    WidgetTester tester,
    Widget widget, {
    Duration? duration,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(createTestableWidget(widget, theme: theme));
    if (duration != null) {
      await tester.pump(duration);
    }
  }

  static Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
  }

  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }
} 