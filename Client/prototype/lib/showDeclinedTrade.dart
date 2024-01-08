import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:test_1/displayItem.dart';
import 'dart:convert';

import 'package:test_1/getItemPage.dart';
import 'package:test_1/login.dart';
import 'package:http/io_client.dart';
import 'dart:io';

import 'package:test_1/swiping.dart';

class DeclinedTradeWindow extends StatefulWidget {
  final String tradeId;
  const DeclinedTradeWindow(this.tradeId, {super.key});
  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _DeclinedTradeWindowState createState() => _DeclinedTradeWindowState(tradeId);
}

class _DeclinedTradeWindowState extends State<DeclinedTradeWindow> {
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
  Color outline = Color.fromARGB(255, 178, 36, 14);

  Future<void> _loadData() async {
    
    //Get the declined trade trade
    Uri url = Uri.parse(
        'https://13.48.78.37:5000/get-declined-trade?tradeId=$tradeId');
    dynamic response = await https!.get(url);
    String body = response.body;

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

  _DeclinedTradeWindowState(String tradeIdIn) {
    tradeId = tradeIdIn;
  }

  //Update to
  Future<void> deleteTrade() async {
    //
    Uri url =
        Uri.parse('https://13.48.78.37:5000/delete-declined?tradeId=$tradeId');
    dynamic response = await https!.post(url);
  }

  /**
   * Displays Items from a list in a grid view
   */
  GridView displayItems(List userItems) {
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 0.8,
      semanticChildCount: 6,
      //Generates all the items in the screen
      children: List.generate(userItems.length, (index) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context, userItems[index].toString());
            //return the selection
          },
          child: Container(
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
          onLongPress: () {
            Map<String, dynamic> tmp = userItems[index];
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => DisplayItem(tmp)));
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: globalBackground,
      appBar: AppBar(
        backgroundColor: globalAppbarColor,
        toolbarHeight: 40,
        title: const Text('Trading Window'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, "nothing");
          },
        ),
      ),
      body: Column(
        children: [
          const Text(
            'What you give',
            textScaleFactor: 1.5,
          ),
          Expanded(child: displayItems(myItems)),
          const Text(
            'What you get',
            textScaleFactor: 1.5,
          ),
          Expanded(child: displayItems(othersItems)),
          Container(
            height: 75,
            color: Colors.blueGrey,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      //Send the trade offer to the
                      print("Deleting trade");
                      deleteTrade();
                      //send to server
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                    ),
                    child: const Text(
                      'Delete trade',
                      textScaleFactor: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
