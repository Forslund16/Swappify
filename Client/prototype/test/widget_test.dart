// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:http/testing.dart';
import 'package:test_1/getItemPage.dart';
import 'package:test_1/editItem.dart';
import 'package:http/http.dart' as http;


//NOTE: only zero pictures otherwise it will fail
Map<String, dynamic>? alternate = {"info": {"_id": "6456c126e4a355fc2a1f2e5a", "name": "VÃ¤g2", "desc": "testar", "gender": "Unisex", "size": "1", "type": "", "tags": ["Unisex", "Designer fashion"], "images": [], "user_id": "100392810021535667486", "liked_by": ["118275183918171221434", "107043564822200781477", "103215896690344689841", "117774032041860997130", "116782189006623172647", "110731528346118239597", "102995458260366148084"]}};
class MockIOClient extends IOClient {
  
  MockIOClient(MockClient mockClient)
      : super();

  @override
  Future<IOStreamedResponse> send(request) {
    Stream<List<int>> dataStream = Stream.fromIterable([json.encode(alternate).codeUnits]);

    return Future.value(IOStreamedResponse((dataStream), 200));
  }
}

//Generate tests for the code in this project
void main() {

  testWidgets('Test for the EditClothesScreen widget', (WidgetTester tester) async {
   // Define a mock implementation of HttpClient
  final mockHttpClient = MockClient((request) async {
  // Return a HTTP response with a status code of 200 and a response body with suitable data
    return http.Response(json.encode(alternate), 200);
  });
  MockIOClient httpClient = MockIOClient(mockHttpClient);
  // Build our app and trigger a frame.
  await tester.pumpWidget(MaterialApp(home: EditClothesScreen(itemIndex: 0, ioClient: httpClient)));
  //Pump again to recieve the data from the "server"
  try{
    await tester.pump();
  }
  catch(e){
    print(e);
  }
  tester.allWidgets.forEach((element) {print(element);});
  //check that the widget exists
  expect(find.widgetWithText(TextFormField, 'Name'), findsOneWidget);
  //Edit name and ensure name is changes
  expect(find.widgetWithText(TextFormField, 'testedname'), findsNothing);
  await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'testedname');
  expect(find.widgetWithText(TextFormField, 'testedname'), findsOneWidget);
  //Do the same for description
  expect(find.widgetWithText(TextFormField, 'Description'), findsOneWidget);
  expect(find.widgetWithText(TextFormField, 'testeddescription'), findsNothing);
  await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'testeddescription');
  expect(find.widgetWithText(TextFormField, 'testeddescription'), findsOneWidget);
  //Do the same for size
  expect(find.widgetWithText(TextFormField, 'Size'), findsOneWidget);
  expect(find.widgetWithText(TextFormField, 'testedsize'), findsNothing);
  await tester.enterText(find.widgetWithText(TextFormField, 'Size'), 'testedsize');
  expect(find.widgetWithText(TextFormField, 'testedsize'), findsOneWidget);
  //Select the tag "Designer fashion" from the inputdetector labled tags and ensure no other tags are selected
  expect(find.widgetWithText(InputDecorator, 'Tags'), findsOneWidget);
  expect(find.widgetWithText(GestureDetector, 'Designer fashion'), findsOneWidget);
  expect(find.widgetWithText(GestureDetector, 'Unisex'), findsOneWidget);
  //Check that the button can be tapped
  await tester.tap(find.widgetWithText(GestureDetector, 'Designer fashion'));
  //TODO Check that Designer fasion was checked and is now unchecked


    //find.byWidgetPredicate ((Widget widget) => widget is TextFormField);// && widget.initialValue== "Testaren");
    /**
    //Do the same for description
    await tester.enterText(find.widgetWithText(TextFormField, 'description'), 'testeddescription');
    //Do the same for size
    await tester.enterText(find.widgetWithText(TextFormField, 'size'), 'testedsize');
    //Select the tag "Designer fashion" from the inputdetector labled tags and ensure no other tags are selected
    await tester.tap(find.widgetWithText(InputDecorator, 'tags'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Designer fashion'));
     */
  });
  
}