import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:smart_shoe/main.dart';

void main() {
  testWidgets('shows smart shoe connection screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartShoeApp());

    expect(find.text('Smart Shoe'), findsOneWidget);
    expect(find.text('Real-Time Dashboard'), findsOneWidget);
    expect(find.text('Live Session'), findsOneWidget);
    expect(find.text('O2 Level'), findsOneWidget);
    expect(find.text('Motion Level'), findsOneWidget);
    expect(find.text('SpO2'), findsNothing);
    expect(find.text('Gait'), findsNothing);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
