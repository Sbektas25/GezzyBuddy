import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gezzy_buddy/widgets/package_card.dart';

void main() {
  group('PackageCard Widget Tests', () {
    testWidgets('displays title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PackageCard(
          title: 'Test Package',
          imagePath: 'https://picsum.photos/200/300',
          onTap: () {},
        ),
      ));

      expect(find.text('Test Package'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(MaterialApp(
        home: PackageCard(
          title: 'Test Package',
          imagePath: 'https://picsum.photos/200/300',
          onTap: () {
            wasTapped = true;
          },
        ),
      ));

      await tester.tap(find.byType(PackageCard));
      expect(wasTapped, true);
    });

    testWidgets('displays network image correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PackageCard(
          title: 'Test Package',
          imagePath: 'https://picsum.photos/200/300',
          onTap: () {},
        ),
      ));

      expect(find.byType(Image), findsOneWidget);
      final Image image = tester.widget(find.byType(Image));
      expect(image.image, isA<NetworkImage>());
    });
  });
} 