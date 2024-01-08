import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:test_1/privacyPolicy.dart';
import 'package:test_1/addUser.dart';
import 'package:test_1/showDeclinedTrade.dart';
import 'package:test_1/swiping.dart';

import 'login.dart';

class DeclinedScreen extends StatefulWidget {
  const DeclinedScreen({super.key});

  @override
  DeclinedScreenState createState() => DeclinedScreenState();
}

class DeclinedScreenState extends State<DeclinedScreen> {
  List<dynamic> declinedTrades = [];
  List<String> sentImages = [];
  List<String> recievedImages = [];
  List<String> sentBy = [];
  List<String> sentTo = [];

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
    await getDeclined();
    // The getItem method has completed at this point, and you can proceed with any other logic that depends on the data returned by it
  }

  //Color
  Color outline = Color.fromARGB(255, 178, 36, 14);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Matches',
        home: Scaffold(
          backgroundColor: globalBackground,
          appBar: AppBar(
            backgroundColor: globalAppbarColor,
            toolbarHeight: 40,
            title: const Text('Declined'),
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

              if (declinedTrades.isEmpty) {
                //if (matches!['matches'] == null) {
                return const Center(child: Text('No trades found'));
              }
              return ListView.builder(
                itemCount: declinedTrades.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      String declinedtradeid = declinedTrades[index]['_id'];
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DeclinedTradeWindow(
                                  declinedTrades[index]['_id'])));
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

  Future<void> getDeclined() async {
    final response = await https!.get(Uri.parse(
        'https://13.48.78.37:5000/get-declined-trades?userId=$userId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch trades');
    }
    setState(() {
      String body = response.body;
      declinedTrades = (json.decode(response.body))['declined'];
    });

    for (var declinedTrade in declinedTrades) {
      dynamic sentItems = declinedTrade['senderoffer'];
      dynamic recievedItems = declinedTrade['recieverdemands'];
      //Get one sent item
      dynamic onesent = sentItems[0];
      String image1 = await getItem(onesent);
      sentImages.add(image1);
      //Get one recieved item
      dynamic oneRecieved = recievedItems[0];
      String image2 = await getItem(oneRecieved);
      recievedImages.add(image2);
      sentBy.add(declinedTrade['senderId']);
      sentTo.add(declinedTrade['recieverId']);

      setState(() {
        sentImages;
        recievedImages;
        sentBy;
        sentTo;
      });
      //Skapa en lista av bildpar för varje accepterad trade med info(namn, telefonnummer) om motparten för varje trade
    }
  }

  Future<String> getItem(dynamic firstItem) async {
    Uri url =
        Uri.parse('https://13.48.78.37:5000/get-item-id?itemId=$firstItem');
    dynamic response = await https!.get(url);
    dynamic item = jsonDecode(response.body);
    //Get first picture for this item
    String firstImage = item['images'][0];

    return firstImage;
    //Skapa en lista av bildpar för varje accepterad trade med info(namn, telefonnummer) om motparten för varje trade
  }

  Future<String> getProfile(dynamic googleId) async {
    Uri url =
        Uri.parse('https://13.48.78.37:5000/get-user?google_id=$googleId');
    dynamic response = await https!.get(url);
    dynamic item = jsonDecode(response.body);
    //Extract profile info about user

    return "";
    //Skapa en lista av bildpar för varje accepterad trade med info(namn, telefonnummer) om motparten för varje trade
  }
}
