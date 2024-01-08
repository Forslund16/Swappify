import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test_1/login.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockResponse extends Mock implements http.Response {}

void main() {
  late MockGoogleSignIn mockGoogleSignIn;

  setUp(() {
    mockGoogleSignIn = MockGoogleSignIn();
  });

  group('LoginScreen Widget', () {
    testWidgets('should show the login screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      expect(find.text('Sign up with Google'), findsOneWidget);
    });

    testWidgets('should call loginRequest when signing in with Google',
        (WidgetTester tester) async {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuthentication = MockGoogleSignInAuthentication();

      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockAccount);
      when(mockAccount.id).thenReturn('123');
      when(mockAccount.authentication)
          .thenAnswer((_) async => mockAuthentication);
      when(mockAuthentication.accessToken).thenReturn('456');

      when(mockGoogleSignIn.currentUser).thenReturn(mockAccount);

      final mockResponse = MockResponse();
      when(mockResponse.statusCode).thenReturn(200);
      when(mockResponse.body)
          .thenReturn('{"status": "OK", "recently_matched": []}');
      when(http.get(Uri.parse('http://13.48.78.37:5000/login?userId=123')))
          .thenAnswer((_) async => mockResponse);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.tap(find.text('Sign up with Google'));
      await tester.pump();

      verify(mockGoogleSignIn.signIn());
      verify(http.get(Uri.parse('http://13.48.78.37:5000/login?userId=123')));
    });




    
  });
}