import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:http/io_client.dart';
import 'dart:io';

import 'package:test_1/displayItem.dart';
import 'package:test_1/swiping.dart';

// ignore: camel_case_types
class getItemPage extends StatefulWidget {
  final List userItems;
  final List otherUserLikes;
  final String displayText;

  const getItemPage(this.userItems, this.otherUserLikes, this.displayText, {super.key});

  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _getItemPageState createState() =>
      // ignore: no_logic_in_create_state
      _getItemPageState(userItems, otherUserLikes, displayText);
}

// ignore: camel_case_types
class _getItemPageState extends State<getItemPage> {
  List userItems = [];
  List otherUserLikes = [];
  String displayText = "";
  _getItemPageState(List listIn, List likes, String textin) {
    userItems = listIn;
    otherUserLikes = likes;
    displayText = textin;
  }

  IOClient? https;
  @override
  void initState() {
    super.initState();
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    https = IOClient(ioClient);
    setState(() {});
  }

  //Colors
  Color outline = Color.fromARGB(255, 207, 52, 96);

  bool isLiked(String itemId) {
    if (otherUserLikes.contains(itemId)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
          backgroundColor: globalBackground,
      appBar: AppBar(
        backgroundColor: globalAppbarColor,
        toolbarHeight: 40,
        title:  Text(displayText),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, "nothing");
          },
        ),
      ),
      body: Center(
        child: GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          semanticChildCount: 6,
          //Generates all the items in the screen
          children: List.generate(userItems.length, (index) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context, userItems[index]);
                //return the selection
              },
              onLongPress: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DisplayItem(userItems[index])));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isLiked(userItems[index]['_id']) ? Colors.green : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(1),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    userItems[index]['images'][0].toString(),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                    alignment: Alignment.center,
                    errorBuilder: (BuildContext context, Object exception,
                        StackTrace? stackTrace) {
                      return const Icon(Icons.error);
                    },
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ));
  }
}
