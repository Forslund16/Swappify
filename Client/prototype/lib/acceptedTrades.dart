import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:test_1/privacyPolicy.dart';
import 'package:test_1/addUser.dart';
import 'package:test_1/swiping.dart';

import 'login.dart';

class AcceptedScreen extends StatefulWidget {
  const AcceptedScreen({super.key});

  @override
  AcceptedScreenState createState() => AcceptedScreenState();
}

class AcceptedScreenState extends State<AcceptedScreen> {
  List<dynamic> acceptedTrades = [];
  List<String> sentImages = [];
  List<String> recievedImages = [];

  IOClient? https;
  @override
  void initState() {
    super.initState();
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    https = IOClient(ioClient);
    _loadData();
  }

  Future<void> _loadData() async {
    await getAccepted();
    // The getItem method has completed at this point, and you can proceed with any other logic that depends on the data returned by it
  }
  //Color
  Color outline = Color.fromARGB(255, 5, 160, 29);
  Color background =  Color.fromARGB(204, 59, 227, 112);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Matches',
        home: Scaffold(
          backgroundColor: globalBackground,
          appBar: AppBar(
            backgroundColor: globalAppbarColor,
            toolbarHeight: 40,
            title: const Text('Accepted'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: FutureBuilder<void>(
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (acceptedTrades.isEmpty) {
                //if (matches!['matches'] == null) {
                return const Center(child: Text('No trades found'));
              }
              return ListView.builder(
                
                itemCount: acceptedTrades.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      //TODO fixa klick
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.network(
                                  sentImages[index].toString(),
                                  width: 50,
                                  height: 50,
                                ),
                                Image.network(
                                  recievedImages[index].toString(),
                                  width: 50,
                                  height: 50,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ));
  }

  Future<void> getAccepted() async {
    final response = await https!.get(Uri.parse(
        'https://13.48.78.37:5000/get-accepted-trades?userId=$userId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch trades');
    }
    setState(() {
      acceptedTrades = (json.decode(response.body))['accepted'];
    });
    for (var acceptedTrade in acceptedTrades) {
      dynamic sentItems = acceptedTrade['senderoffer'];
      dynamic recievedItems = acceptedTrade['recieverdemands'];
      //Get one sent item
      dynamic onesent = sentItems[0];
      String image1 = await getItem(onesent);
      sentImages.add(image1);
      //Get one recieved item
      dynamic oneRecieved = recievedItems[0];
      String image2 = await getItem(oneRecieved);
      recievedImages.add(image2);

      setState(() {
        sentImages;
        recievedImages;
      });
      //Skapa en lista av bildpar för varje accepterad trade med info(namn, telefonnummer) om motparten för varje trade
    }
  }

  Future<String> getItem(dynamic firstItem) async {
    Uri url = Uri.parse(
        'https://13.48.78.37:5000/get-item-id-traded?itemId=$firstItem');
    dynamic response = await https!.get(url);
    dynamic item = jsonDecode(response.body);
    //Get first picture for this item
    String firstImage = item['images'][0];

    return firstImage;
    //Skapa en lista av bildpar för varje accepterad trade med info(namn, telefonnummer) om motparten för varje trade
  }
}
