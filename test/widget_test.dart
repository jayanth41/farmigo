// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/home_screen.dart';

void main() {
  testWidgets('App shows header', (WidgetTester tester) async {
    // Build our app and trigger a frame.
  // Pump HomeScreen directly to avoid the splash/auth navigation in main
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();

  // Verify that main header is present
  expect(find.text('FARMIGO'), findsOneWidget);
  expect(find.textContaining('Find your perfect'), findsOneWidget);
  });
}
