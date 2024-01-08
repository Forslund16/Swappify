import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:test_1/swiping.dart';
import 'package:test_1/trade.dart';
import 'dart:typed_data';
import 'dart:core';

import 'acceptedTrades.dart';
import 'declinedTrades.dart';
import 'login.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  MatchScreenState createState() => MatchScreenState();
}

class MatchScreenState extends State<MatchScreen> {
  Map<String, dynamic> matches = {'status': 'no matches'};
  Map<String, dynamic>? trades;
  List<dynamic>? names;
  List<dynamic>? phone;
  List<dynamic>? ids;
  List<dynamic>? images;
  List<dynamic>? myitems;

  IOClient? https;

  @override
  void initState() {
    super.initState();
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    https = IOClient(ioClient);
    _updateVariables();
  }

  Future<void> _updateVariables() async {
    await getMatches();
    await getTrades();
    if (names == null) {
      setState(() {
        if (matches != null) {
          names = [];
          phone = [];
          ids = [];
          images = [];

          if (matches != null && matches['matches'] != null) {
            List<dynamic> matchesList = matches['matches'];

            names =
                matchesList.map((match) => match['username'] ?? '').toList();

            phone = matchesList.map((match) => match['phone'] ?? '').toList();
            images = matchesList.map((match) => match['items'] ?? '').toList();
            myitems =
                matchesList.map((match) => match['my_items'] ?? '').toList();

            ids = matches['ids'].toList();
          }
        }
      });
    }
  }

  List<String> visitedUrls = [];
  //Colors for the background
  Color outline = const Color.fromARGB(255, 207, 52, 96);
  Color background = const Color.fromARGB(255, 148, 37, 69);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Matches',
        home: Scaffold(
          backgroundColor: globalBackground,
          appBar: AppBar(
            backgroundColor: globalAppbarColor,
            toolbarHeight: 40,
            title: const Text('Matches'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            actions: [
              // TextButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (context) => const AcceptedScreen()),
              //     );
              //   },
              //   child: const Text('Accepted'),
              // ),
              // TextButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (context) => const DeclinedScreen()),
              //     );
              //   },
              //   child: const Text('Declined'),
              // ),
            ],
          ),
          body: FutureBuilder<void>(
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (matches['status'] == 'no matches') {
                //if (matches['matches'] == null) {

                return const Center(child: Text('No matches found'));
              }
              final Map<String, List<int>> idIndices =
                  {}; // new map to store indices of each ID
              final List<String> uniqueIds = [];

              for (int i = 0; i < ids!.length; i++) {
                if (!uniqueIds.contains(ids![i])) {
                  uniqueIds.add(ids![i]);
                  idIndices[ids![i]] = [
                    i
                  ]; // initialize list with index of first occurrence
                } else {
                  idIndices[ids![i]]!
                      .add(i); // add index to list of occurrences
                }
              }

              return ListView.builder(
                itemCount: uniqueIds.length,
                itemBuilder: (BuildContext context, int index) {
                  final String id = uniqueIds[index];
                  final List<int> idIndicesList = idIndices[id]!;

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                List<dynamic> temp = trades!['trades'];
                                List<dynamic> items = [];

                                return TradeScreen(
                                  names![idIndicesList.first],
                                  phone![idIndicesList.first],
                                  ids![idIndicesList.first],
                                  temp,
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      names![idIndicesList.first],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 69,
                                      child: ListView.builder(
                                        itemCount:
                                            images![idIndicesList.first].length,
                                        scrollDirection: Axis.horizontal,
                                        itemBuilder: (BuildContext context,
                                            int imgIndex) {
                                          final String imageUrl =
                                              images![idIndicesList.first]
                                                  [imgIndex][0];
                                          return FutureBuilder<Uint8List>(
                                            future: https!
                                                .get(Uri.parse(imageUrl))
                                                .then((response) =>
                                                    response.bodyBytes),
                                            builder: (BuildContext context,
                                                AsyncSnapshot<Uint8List>
                                                    snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.done) {
                                                if (snapshot.hasData) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 8.0),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              34.5),
                                                      child: Image.memory(
                                                        snapshot.data!,
                                                        alignment:
                                                            Alignment.topRight,
                                                        fit: BoxFit.cover,
                                                        width: 69,
                                                        height: 69,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return buildErrorBox();
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                } else if (snapshot.hasError) {
                                                  return buildErrorBox();
                                                }
                                              }
                                              return const ClipOval(
                                                child: SizedBox(
                                                  width: 69,
                                                  height: 69,
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ),
                      ),
                      const Divider(
                        color: Colors.grey,
                        thickness: 1,
                        indent:
                            10, // Adjust this value to create space on the left
                        endIndent:
                            10, // Adjust this value to create space on the right
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ));
  }

  Widget buildErrorBox() {
    return GestureDetector(
      onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load image data, exception error'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Container(
          width: 69,
          height: 69,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34.5),
            color: Colors.grey,
          ),
          child: const Text(
            'X',
            style: TextStyle(fontSize: 39, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> getMatches() async {
    final url =
        Uri.parse('https://13.48.78.37:5000/get-matches?userId=$userId');
    final response = await https!.get(url);
    matches = json.decode(response.body);

    if (matches['status'] == 'OK') {}
  }

  Future<void> getTrades() async {
    final url = Uri.parse('https://13.48.78.37:5000/get-trades?userId=$userId');
    final response = await https!.get(url);
    trades = json.decode(response.body);
  }
}

// Efter build-widgeten
