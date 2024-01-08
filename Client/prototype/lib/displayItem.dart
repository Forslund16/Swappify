import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:test_1/privacyPolicy.dart';
import 'package:test_1/addUser.dart';
import 'package:test_1/showDeclinedTrade.dart';
import 'package:test_1/swiping.dart';

/*
 * A simple general purpouse screen for displaying items
*/


class DisplayItem extends StatefulWidget {
  final Map<String, dynamic> item;
  const DisplayItem(this.item,  {super.key});

  @override
  DisplayScreenState createState() => DisplayScreenState(item);
}

class DisplayScreenState extends State<DisplayItem> {
  Map<String, dynamic> item;
  int currentImageIndex = 0;
  final double bigScreenBoxSize = 0.90;
  DisplayScreenState(this.item);

  IOClient? https;
  @override
  void initState() {
    super.initState();
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    https = IOClient(ioClient);
  }


  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swappify',
      home: Scaffold(
        backgroundColor: globalBackground,
        appBar: AppBar(
          backgroundColor: globalAppbarColor,
          toolbarHeight: 40,
          title: const Text('Swappify'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
        ),
        body: Center(
          child: 
                        GestureDetector(
                          child: Stack(children: [
                            FutureBuilder(
                              future: precacheImage(
                                  NetworkImage(
                                      '${item['images'][currentImageIndex]}'),
                                  context),
                              builder: (BuildContext context,
                                  AsyncSnapshot<dynamic> snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
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
                                    //margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(5),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                bigScreenBoxSize,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.redAccent,
                                            backgroundColor: Colors.cyan,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return GestureDetector(
                                    onTap: () => setState(() {}),
                                    child: const Center(
                                      child: Text(
                                          'Failed to load image. Tap to try again.'),
                                    ),
                                  );
                                } else {
                                  return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
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
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(5),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          '${item['images'][currentImageIndex]}',
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              bigScreenBoxSize,
                                          fit: BoxFit.cover,
                                        ),
                                      ));
                                }
                              },
                            ),
                            Positioned(
                              left: 20,
                              top: 20,
                              child: Container(
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(150, 150, 150, 150),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color.fromRGBO(150, 150, 150, 220),
                                        spreadRadius: 4,
                                        blurRadius: 2,
                                        //offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                        Text(
                                          '${item['name']}',
                                          style: const TextStyle(
                                            fontSize: 24.0,
                                            color: Colors.white70,
                                            shadows: [
                                              Shadow(
                                                color: Color.fromRGBO(
                                                    100, 100, 100, 10),
                                                blurRadius: 10,
                                              )
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'Gender: ${item['gender']}',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.white70,
                                            shadows: [
                                              Shadow(
                                                color: Color.fromRGBO(
                                                    100, 100, 100, 10),
                                                blurRadius: 10,
                                              )
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'Size: ${item['size']}',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.white70,
                                            shadows: [
                                              Shadow(
                                                color: Color.fromRGBO(
                                                    100, 100, 100, 10),
                                                blurRadius: 10,
                                              )
                                            ],
                                          ),
                                        ),
                                    ],
                                  )),
                            ),
                            //A screen for displaying the item description
                            Positioned(
                              left: 20,
                              bottom: 20,
                              child: Container(
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(150, 150, 150, 150),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color.fromRGBO(150, 150, 150, 220),
                                        spreadRadius: 4,
                                        blurRadius: 2,
                                        //offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                        Text(
                                          'Description:',
                                          style: const TextStyle(
                                            fontSize: 24.0,
                                            color: Colors.white70,
                                            shadows: [
                                              Shadow(
                                                color: Color.fromRGBO(
                                                    100, 100, 100, 10),
                                                blurRadius: 10,
                                              )
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${item['desc']}',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.white70,
                                            shadows: [
                                              Shadow(
                                                color: Color.fromRGBO(
                                                    100, 100, 100, 10),
                                                blurRadius: 10,
                                              )
                                            ],
                                          ),
                                        ),
                                    ],
                                  )),
                            ),
                            
                          ],
                          ),
                          onTap: () {
                            if (item['images']?.length != 1) {
                              setState(() {
                                currentImageIndex = (currentImageIndex + 1) %
                                    (item['images']?.length ?? 0) as int;
                              });
                            }
                          },
                          
                        )
                    
                  
                //Container(color: Colors.white, height: 40),
                
            
            
          
        ),
      ),
    );
  }

}

