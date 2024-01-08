import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart';
import 'package:test_1/displayItem.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:test_1/getItemPage.dart';
import 'package:test_1/login.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:test_1/swiping.dart';

class TradingWindow extends StatefulWidget {
  final String myuserId;
  final String tradingId;
  final IO.Socket? socket;
  final String roomId;
  const TradingWindow(this.myuserId, this.tradingId, this.socket, this.roomId,
      {super.key});
  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _TradingWindowState createState() => _TradingWindowState(myuserId, tradingId);
}

class _TradingWindowState extends State<TradingWindow> {
  String myuserIdState = '';
  String otherUserIdState = '';
  List myItems = [];
  List othersItems = [];

  List mySentItems = [];
  List otherSentItems = [];

  List myLikedItems = [];
  List otherLikedItems = [];

  List mySelectedItems = [];
  List otherSelectedItems = [];

  List<bool> myIsSelected = [];
  List<bool> otherIsSelected = [];

  Future<void> _updateVariables() async {
    await selectToOffer();
    await askToGet();
    setState(() {});
  }

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

  _TradingWindowState(String myuserId, String tradingId) {
    myuserIdState = myuserId;
    otherUserIdState = tradingId;
  }
  //handles the user selecting something of their own to offer
  Future<void> selectToOffer() async {
    List todisplay = [];
    final url =
        Uri.parse('https://13.48.78.37:5000/get-user-items?userId=$userId');
    final response = await https!.get(url);
    if (response.statusCode == 200) {
      dynamic result = json.decode(response.body);
      todisplay = (json.decode(response.body))['info'];
      setState(() {
        mySentItems = result['info'];
        myLikedItems = result['liked'];
      });
      myIsSelected = [];
      for (var _ in mySentItems) {
        myIsSelected.add(false);
      }
    }
    //Tillse att dupleter inte blir ett problem
    List toremove = [];
    for (dynamic item in todisplay) {
      for (dynamic item2 in myItems) {
        if (item['_id'] == item2['_id']) {
          toremove.add(item);
        }
      }
    }
    for (dynamic removeItem in toremove) {
      todisplay.remove(removeItem);
    }

    // ignore: use_build_context_synchronously
    // final dynamic selected = await Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => getItemPage(todisplay, otherLikedItems)),
    // );
    // if (selected != "nothing") {
    //   myItems.add(selected);
    //   _updateVariables();
    // }
  }

  //handles the user asking for something in return
  Future<void> askToGet() async {
    List todisplay = [];

    final url = Uri.parse(
        'https://13.48.78.37:5000/get-user-items?userId=$otherUserIdState');
    final response = await https!.get(url);
    if (response.statusCode == 200) {
      dynamic result = json.decode(response.body);
      todisplay = (json.decode(response.body))['info'];
      setState(() {
        otherSentItems = result['info'];
        otherLikedItems = result['liked'];
      });
      otherIsSelected = [];
      for (var _ in otherSentItems) {
        otherIsSelected.add(false);
      }
    }

    //Tillse att dupleter inte blir ett problem
    List toremove = [];
    for (dynamic item in todisplay) {
      for (dynamic item2 in othersItems) {
        if (item['_id'] == item2['_id']) {
          toremove.add(item);
        }
      }
    }
    for (dynamic removeItem in toremove) {
      todisplay.remove(removeItem);
    }
  }

  Future<void> sendUpdate(List myItemsId, List othersItemsId) async {
    //
    final data = {
      'senderId': myuserIdState,
      'recieverId': otherUserIdState,
      'senderoffer': myItemsId,
      'recieverdemands': othersItemsId
    };
    final url = Uri.parse('https://13.48.78.37:5000/add-trade');
    final response = await https!.post(
      url,
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update item');
    }

    widget.socket!.emit(
      'tradeRequest',
      {
        'name': googleSignin.currentUser!.displayName!,
        'message': "Trade offer",
        'room': widget.roomId,
        'offered': myItemsId,
        'demanded': othersItemsId,
        'tradeId': jsonDecode(response.body)['tradeId'],
        'from': googleSignin.currentUser!.id,
      },
    );
  }

  bool isLiked(String itemId, List likes) {
    if (likes.contains(itemId)) {
      return true;
    }
    return false;
  }

  //Colors
  Color buttonColor = globalApplyButtonColor;

  SizedBox displayGridView(BuildContext context, List items, List itemId,
      List likes, List<bool> isSelected) {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.38,
        child: Center(
            child: GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () async {
                if (isSelected[index] == false) {
                  itemId.add(items[index]['_id']);
                } else {
                  itemId.remove(items[index]['_id']);
                }
                setState(() {
                  isSelected[index] = !isSelected[index];
                });
              },
              child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected[index]
                            ? Colors.green
                            : Colors.grey.withOpacity(0.5),
                        spreadRadius: isSelected[index]
                            ? 5
                            : 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        items[index]['images'][0].toString(),
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
                    (isLiked(items[index]['_id'], likes))
                        ? Positioned(
                            top: 2,
                            right: 2,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: const Icon(
                                Icons.thumb_up_alt,
                                color: Color.fromARGB(255, 11, 167, 16),
                                size: 25,
                              ),
                            ),
                          )
                        : Container(),
                  ])),
              onLongPress: () {
                Map<String, dynamic> tmp = items[index];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisplayItem(tmp),
                  ),
                );
              },
            );
          },
        )));
  }

  // SizedBox displayGridView(BuildContext context, List items, List itemId,
  //     List likes, List<bool> isSelected) {
  //   return SizedBox(
  //     height: MediaQuery.of(context).size.height * 0.38,
  //     child: Center(
  //       child: GridView.count(
  //         crossAxisCount: 3,
  //         childAspectRatio: 0.8,
  //         semanticChildCount: 6,
  //         children: List.generate(items.length, (index) {
  //           return GestureDetector(
  //             onTap: () async {
  //               if (isSelected[index] == false) {
  //                 itemId.add(items[index]['_id']);
  //               } else {
  //                 itemId.remove(items[index]['_id']);
  //               }
  //               setState(() {
  //                 isSelected[index] = !isSelected[index];
  //               });
  //             },
  //             onLongPress: () {
  //               Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                       builder: (context) => DisplayItem(items[index])));
  //             },
  //             child: Container(
  //               decoration: BoxDecoration(
  //                 color: isSelected[index] ? Colors.green : globalAppbarColor,
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               margin: const EdgeInsets.all(20),
  //               padding: const EdgeInsets.all(5),
  //               child: Stack(
  //                 children: [
  //                   ClipRRect(
  //                     borderRadius: BorderRadius.circular(20),
  //                     child: CachedNetworkImage(
  //                       imageUrl: items[index]['images'][0].toString(),
  //                       fit: BoxFit.cover,
  //                       height: 200,
  //                       width: 200,
  //                       alignment: Alignment.center,
  //                       errorWidget:
  //                           (BuildContext context, String url, dynamic error) {
  //                         return const Icon(Icons.error);
  //                       },
  //                     ),
  //                   ),
  //                   (isLiked(items[index]['_id'], likes))
  //                       ? Positioned(
  //                           top: 2,
  //                           right: 2,
  //                           child: ClipRRect(
  //                             borderRadius: BorderRadius.circular(20),
  //                             child: const Icon(
  //                               Icons.thumb_up_alt,
  //                               color: Color.fromARGB(255, 11, 167, 16),
  //                               size: 25,
  //                             ),
  //                           ),
  //                         )
  //                       : Container(),
  //                 ],
  //               ),
  //             ),
  //           );
  //         }),
  //       ),
  //     ),
  //   );
  // }

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
          const SizedBox(
            height: 22,
            child: Text(
              'Your Items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          displayGridView(
              context, mySentItems, myItems, otherLikedItems, myIsSelected),
          const SizedBox(
            height: 22,
            child: Text(
              'Their items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          displayGridView(context, otherSentItems, othersItems, myLikedItems,
              otherIsSelected),
          const SizedBox(
            height: 14,
          ),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                //Send the trade offer to the
                // List myItemId = [];
                // for (int i = 0; i < myItems.length; i++) {
                //   myItemId.add(myItems[i]['_id']);
                // }

                // List othersItemsID = [];
                // for (int i = 0; i < othersItems.length; i++) {
                //   othersItemsID.add(othersItems[i]['_id']);
                // }
                // print("myItemId = $myItemId");
                // print("othersItemsID = $othersItemsID");
                if (myItems.isNotEmpty && othersItems.isNotEmpty) {
                  bool confirmTrade = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title:
                            const Text('Confirm', textAlign: TextAlign.center),
                        content: const Text(
                            'Are you sure you want to send this trade?',
                            textAlign: TextAlign.center),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        actions: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextButton(
                                  onPressed: () async {
                                    await sendUpdate(myItems, othersItems);
                                    Navigator.of(context).pop(true);
                                  },
                                  child: const Text('Yes'),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                  // ignore: use_build_context_synchronously
                  if (confirmTrade == true) Navigator.pop(context, "nothing");
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title:
                            const Text('Warning', textAlign: TextAlign.center),
                        content: const Text('You can\'t send an empty trade',
                            textAlign: TextAlign.center),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Ok'),
                          ),
                        ],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      );
                    },
                  );
                }
                //send to server
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(buttonColor),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              child: const Text(
                'Send Trade',
                textScaleFactor: 1.25,
              ),
            ),
          ),
          const SizedBox(
            height: 14,
          )
        ],
      ),
    );
  }
}
