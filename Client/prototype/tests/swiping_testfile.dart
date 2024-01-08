import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:test_1/swiping.dart';



void main() {
  testWidgets('Swipe left on an item', (WidgetTester tester) async {
    // Build the Swiping widget
    await tester.pumpWidget(Swiping());

    // Find the swipeable widget
    final swipeableFinder = find.byType(Swiping);

    // Perform a swipe left gesture on the widget
    await tester.drag(swipeableFinder, Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    // Check if the swipe left action was performed successfully
    // You can add any relevant checks here based on your implementation
  });

  testWidgets('Swipe right on an item', (WidgetTester tester) async {
    // Build the Swiping widget
    await tester.pumpWidget(Swiping());

    // Find the swipeable widget
    final swipeableFinder = find.byType(Swiping);

    // Perform a swipe right gesture on the widget
    await tester.drag(swipeableFinder, Offset(500.0, 0.0));
    await tester.pumpAndSettle();

    // Check if the swipe right action was performed successfully
    // You can add any relevant checks here based on your implementation
  });
}