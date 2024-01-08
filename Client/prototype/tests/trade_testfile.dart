import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/trade.dart';

void main() {
  group('TradeScreen Tests', () {
    testWidgets('TradeScreen displays name, handshake icon and message input', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TradeScreen('John Doe', '+1234567890', '12345', []),
      ));

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.byIcon(Icons.handshake), findsOneWidget);

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      expect(find.descendant(of: textField, matching: find.text('Type your message here...')), findsOneWidget);
    });
    /*
    testWidgets('TradeScreen sends a message and displays it', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TradeScreen('John Doe', '+1234567890', '12345'),
      ));

      final textField = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send);

      await tester.enterText(textField, 'Hello, John!');
      await tester.tap(sendButton);
      await tester.pump();

      expect(find.text('Me: Hello, John!'), findsOneWidget);
    });

    testWidgets('TradeScreen navigates back when pressing arrow_back icon', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TradeScreen('John Doe', '+1234567890', '12345'),
      ));

      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(TradeScreen), findsNothing);
    });
    */

    // Add more tests as needed
  });
}
