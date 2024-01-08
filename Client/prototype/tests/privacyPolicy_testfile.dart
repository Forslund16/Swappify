import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mockito/mockito.dart';
import 'package:test_1/privacyPolicy.dart';


class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrivacyPolicy Widget Tests', () {
    testWidgets('Renders PrivacyPolicy widget', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PrivacyPolicy()));
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Renders title and text content', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PrivacyPolicy()));
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Information we collect'), findsOneWidget);
      expect(find.text('How we use your information'), findsOneWidget);
      expect(find.text('How we share your information'), findsOneWidget);
      expect(find.text('Data retention'), findsOneWidget);
      expect(find.text('Your choices'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Updates to this Privacy Policy'), findsOneWidget);
      expect(find.text('Contact us'), findsOneWidget);
    });

    testWidgets('Renders Play Sound and Close buttons', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PrivacyPolicy()));
      expect(find.text('Play Sound'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Taps Close button', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PrivacyPolicy())));
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyPolicy), findsNothing);
    });

    testWidgets('Renders ElevatedButton for Play Sound', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PrivacyPolicy()));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

  });
}
