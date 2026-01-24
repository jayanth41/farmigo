import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/widgets/premium_search_bar.dart';

void main() {
  testWidgets('PremiumSearchBar shows clear button after typing', (WidgetTester tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PremiumSearchBar(
          controller: controller,
          onChanged: (_) {},
        ),
      ),
    ));

    // Initially, clear button should not be present
    expect(find.byIcon(Icons.close), findsNothing);

    // Enter text and pump
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pumpAndSettle();

    // Now clear button should appear
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
