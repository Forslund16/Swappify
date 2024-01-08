import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:test_1/match.dart';
import 'package:test_1/profile.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:test_1/swiping.dart';

import 'addItem.dart';
import 'login.dart';
import 'swiping.dart' as swiping;

// Global variables. These are being used in Swiping, edititem and additem.
// Important to edit the ListTiles in these files accordingly.
Set<String> selectedFilters = {};
Set<int> selectedFiltersIndexes = {};
List<String> availableTags = [
  "Man",
  "Woman",
  "Unisex",
  "T-shirts",
  "Pants",
  "Shoes",
  "Sweatshirts",
  "Hoodies",
  "Jackets",
  "Knitwear",
  "Sportswear",
  "Designer fashion",
];

//the following list is used in editItem and addItem.
List<String> availableTagsNoGender = [
  "T-shirts",
  "Pants",
  "Shoes",
  "Sweatshirts",
  "Hoodies",
  "Jackets",
  "Knitwear",
  "Sportswear",
  "Designer fashion",
];

// End of global variables.

class SwipingFilters extends StatefulWidget {
  const SwipingFilters({super.key});

  @override
  SwipingFiltersState createState() => SwipingFiltersState();
}

class SwipingFiltersState extends State<SwipingFilters> {
  Set<String> localTags = {};
  Set<int> localIndexes = {};

  Color tagsNotSelected = Colors.white;
  Color tagsSelected = globalAppbarColor;

  IOClient? https;

  @override
  void initState() {
    super.initState();
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    https = IOClient(ioClient);
    localTags = selectedFilters;
    localIndexes = selectedFiltersIndexes;
  }

  void pressTagButton(int index) {
    setState(() {
      if (localIndexes.contains(index)) {
        localIndexes.remove(index);
        localTags.remove(availableTags[index]);
      } else {
        localIndexes.add(index);
        localTags.add(availableTags[index]);
      }
    });
  }

  bool isPressed(int index) {
    return localIndexes.contains(index);
  }

  //Colors
  Color outline = Color.fromARGB(255, 80, 20, 220);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swappify',
      home: Scaffold(
        backgroundColor: globalBackground,
        appBar: AppBar(
          backgroundColor: globalAppbarColor,
          toolbarHeight: 40,
          title: const Text('Select filters'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Form(
          child: ListView(
            children: [
              Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          selectedFiltersIndexes = {};
                          selectedFilters = {};
                          Navigator.pop(context, "discard");
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.red),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                          ),
                        ),
                        child: const Text("Clear filters"),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, "apply");
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.lightGreen),
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                                side: const BorderSide(color: Colors.green),
                              ),
                            ),
                          ),
                          child: const Text("Apply filters")),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: Center(
                        child: GridView.count(
                          scrollDirection: Axis.vertical,
                          crossAxisCount: 1,
                          childAspectRatio: 6,
                          semanticChildCount: 4,
                          children:
                              List.generate(availableTags.length, (index) {
                            return GestureDetector(
                              onTap: () {
                                pressTagButton(index);
                              },
                              child: Container(
                                  alignment: Alignment.center,
                                  margin: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isPressed(index)
                                        ? tagsSelected
                                        : tagsNotSelected,
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: const [
                                      BoxShadow(
                                        color:
                                            Color.fromRGBO(100, 100, 100, 200),
                                        spreadRadius: 3,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Icon(
                                        isPressed(index)
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
                                        color: isPressed(index)
                                            ? tagsNotSelected
                                            : tagsSelected,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        availableTags[index],
                                        style: const TextStyle(
                                          fontSize: 17,
                                          color: Colors.black,
                                          // shadows: [
                                          //   Shadow(
                                          //     color: Color.fromRGBO(
                                          //         100, 100, 100, 100),
                                          //     blurRadius: 10,
                                          //   )
                                          // ],
                                        ),
                                      ),
                                    ],
                                  )),
                            );
                          }),
                        ),
                      )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
