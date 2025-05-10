// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gezzy_buddy/widgets/package_card.dart';

void main() {
  testWidgets('PackageCard displays title and image correctly', (WidgetTester tester) async {
    const title = 'Test Package';
    const imagePath = 'https://picsum.photos/200/300';
    bool wasTapped = false;

    await tester.pumpWidget(MaterialApp(
      home: PackageCard(
        title: title,
        imagePath: imagePath,
        onTap: () => wasTapped = true,
      ),
    ));

    // Verify that title is displayed
    expect(find.text(title), findsOneWidget);

    // Verify that image is displayed
    expect(find.byType(Image), findsOneWidget);
    final Image image = tester.widget(find.byType(Image));
    expect(image.image, isA<NetworkImage>());

    // Verify tap callback
    await tester.tap(find.byType(PackageCard));
    await tester.pump();
    expect(wasTapped, isTrue);
  });
}
