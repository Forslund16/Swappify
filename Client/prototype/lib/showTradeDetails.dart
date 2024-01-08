import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:test_1/displayItem.dart';
import 'dart:convert';

import 'package:test_1/getItemPage.dart';
import 'package:test_1/login.dart';
import 'package:http/io_client.dart';
import 'dart:io';

import 'package:test_1/swiping.dart';

class ShowTradeDetails extends StatefulWidget {
  final String tradeId;
  final String status;
  const ShowTradeDetails(this.tradeId, this.status, {super.key});
  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _ShowTradeDetailsState createState() => _ShowTradeDetailsState(tradeId);
}

class _ShowTradeDetailsState extends State<ShowTradeDetails> {
  String tradeId = "";
  List myItems = [];
  List othersItems = [];

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

  //Colors
  Color outline = const Color.fromARGB(255, 178, 36, 14);
  Color secondaryColor = Color.fromARGB(255, 243, 243, 243);

  Future<void> _loadData() async {
    //Get the declined trade trade
    Uri url = Uri.parse('https://13.48.78.37:5000/get-trade?tradeId=$tradeId');
    dynamic response = await https!.get(url);
    //Determine who was sender and reciever
    for (var item in json.decode(response.body)["senderoffer"]) {
      url = Uri.parse('https://13.48.78.37:5000/get-item-id?itemId=$item');
      dynamic response = await https!.get(url);
      dynamic body = json.decode(response.body);
      myItems.add(body);
    }
    for (var item in json.decode(response.body)["recieverdemands"]) {
      url = Uri.parse('https://13.48.78.37:5000/get-item-id?itemId=$item');
      dynamic response = await https!.get(url);
      dynamic body = json.decode(response.body);
      othersItems.add(body);
    }

    setState(() {
      myItems;
      othersItems;
    });
  }

  _ShowTradeDetailsState(String tradeIdIn) {
    tradeId = tradeIdIn;
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

    Widget statusIndicator() {
      if (widget.status == "accepted") {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Trade accepted!",
            style: TextStyle(color: Colors.green, fontSize: 18),
          ),
        );
      } else if (widget.status == "declined") {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Trade declined!",
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        );
      } else {
        return Container(); // return an empty container for "pending"
      }
    }

    return Scaffold(
      backgroundColor: globalBackground,
      appBar: AppBar(
        backgroundColor: globalAppbarColor,
        toolbarHeight: 40,
        title: const Text('Trade Offer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, "nothing");
          },
        ),
      ),
      body: Column(
        children: [
          statusIndicator(), // Add the status indicator here
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
          Expanded(child: displayItems(myItems)),
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
          Expanded(child: displayItems(othersItems)),
        ],
      ),
    );
  }
}
