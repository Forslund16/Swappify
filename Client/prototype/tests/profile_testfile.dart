import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/profile.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;


@GenerateMocks([http.Client])
void main() {
  group('Profile Screen tests', () {

    testWidgets('AppBar contains correct elements', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ProfileScreen()));
      expect(find.text('Your Profile'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });


  });
}