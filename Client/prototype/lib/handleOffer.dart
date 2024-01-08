import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:test_1/login.dart';
import 'package:test_1/swiping.dart';
import 'package:test_1/tradingwindow.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'displayItem.dart';

class HandleOfferScreen extends StatefulWidget {
  final List<Map<String, dynamic>> offeredItems;
  final List<Map<String, dynamic>> requestedItems;
  final dynamic tradeId;
  final IO.Socket? socket;
  final String roomId;

  HandleOfferScreen(this.offeredItems, this.requestedItems, this.tradeId,
      this.socket, this.roomId,
      {super.key});

  @override
  _HandleOfferScreenState createState() =>
      _HandleOfferScreenState(offeredItems, requestedItems, tradeId);
}

class _HandleOfferScreenState extends State<HandleOfferScreen> {
  List<Map<String, dynamic>> demanded = [];
  List<Map<String, dynamic>> offered = [];
  dynamic tradeId;

  Color secondaryColor = Color.fromARGB(255, 243, 243, 243);
  _HandleOfferScreenState(List<Map<String, dynamic>> offeredItems,
      List<Map<String, dynamic>> requestedItems, dynamic tradeIdIn) {
    offered = offeredItems;
    demanded = requestedItems;
    tradeId = tradeIdIn;
  }

  IOClient? https;
  @override
  void initState() {
    super.initState();
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    https = IOClient(ioClient);
  }

  Widget displayItems(List userItems) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.8,
      ),
      itemCount: userItems.length,
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () {
            //Navigator.pop(context, userItems[index].toString());
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
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
          onLongPress: () {
            Map<String, dynamic> tmp = userItems[index];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayItem(tmp),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Scaffold(
      backgroundColor: globalBackground,
      appBar: AppBar(
        backgroundColor: globalAppbarColor,
        toolbarHeight: 40,
        title: const Text('Trade Offer'),
      ),
      body: Column(
        children: [
          Container(
            color: secondaryColor,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'What you offer',
                style: themeData.textTheme.headline6,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(child: displayItems(demanded)),
          Container(
            color: secondaryColor,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'What they offer',
                style: themeData.textTheme.headline6,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(child: displayItems(offered)),
          Container(
            height: 65,
            color: secondaryColor,
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          //Send the trade offer to the
                          //send to server
                          acceptTrade();
                          // Notify the parent widget that the chat has been updated
                          Navigator.pop(context, "accept");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Accept',
                          textScaleFactor: 1.25,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          //Send the trade offer to the
                          //send to server
                          declineTrade();
                          // Notify the parent widget that the chat has been updated
                          Navigator.pop(context, "decline");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Decline',
                          textScaleFactor: 1.25,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> declineTrade() async {
    final userId = googleSignin.currentUser!.id;
    final data = {
      'tradeId': tradeId,
      'demanded': demanded,
      'offered': offered,
      'userId': userId
    };

    final url = Uri.parse('https://13.48.78.37:5000/decline-trade');
    final response = await https!.post(
      url,
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to decline trade');
    }

    widget.socket!.emit('declineTrade', {
      'room': widget.roomId,
      'tradeId': tradeId,
    });
  }

  Future<void> acceptTrade() async {
    final userId = googleSignin.currentUser!.id;
    final data = {
      'tradeId': tradeId,
      'demanded': demanded,
      'offered': offered,
      'userId': userId
    };

    final url = Uri.parse('https://13.48.78.37:5000/accept-trade');
    final response = await https!.post(
      url,
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to accept trade');
    }

    widget.socket!.emit('acceptTrade', {
      'room': widget.roomId,
      'tradeId': tradeId,
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Start a timer that triggers after 2 seconds, popping the context twice
        Timer(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        });
        return AlertDialog(
          title: const Text(
            'Trade Completed',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          // An icon that is a green checkmark with multiple checks
          icon: const Icon(
            Icons.done_all,
            color: Colors.green,
            size: 100,
          ),
          content: const Text(
            'The trade has been successfully completed!',
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        );
      },
    );
  }
}
