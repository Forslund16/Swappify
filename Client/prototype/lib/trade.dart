import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:test_1/handleOffer.dart';
import 'package:test_1/login.dart';
import 'package:test_1/showTradeDetails.dart';
import 'package:test_1/swiping.dart';
import 'package:test_1/tradingwindow.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class TradeScreen extends StatefulWidget {
  final String name;
  final String phoneNumber;
  final String id;
  final List<dynamic> tradesIn;
  const TradeScreen(this.name, this.phoneNumber, this.id, this.tradesIn,
      {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TradeScreenState createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  TextEditingController messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  String counterId = "";
  dynamic recievedTrades;
  dynamic tradeId;
  String status = "";
  List<dynamic> trades = [];
  Map<String, dynamic> currentTrade = {};

  List<Map<String, dynamic>> requestedItems = [];
  List<Map<String, dynamic>> offeredItems = [];

  final ScrollController _scrollController = ScrollController();
  FocusNode _focusNode = FocusNode();

  // The socket for the chat
  IO.Socket? socket;
  // The room id for the chat
  String roomId = "";
  void initSocket() {
    // Dispose of the socket if it already exists
    if (socket != null) {
      socket!.dispose();
    }

    // Initialize the socket
    socket = IO.io(
      'http://13.48.78.37:5001',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    // Add the event listeners
    socket!.onConnect((_) {
      socket!.emit('join', roomId);
    });

    socket!.onDisconnect((_) {
    });

    socket!.on('declineTrade', (data) {
      List<Map<String, dynamic>> newmessages = messages;
      messages = [];
      for (int i = 0; i < newmessages.length; i++) {
        if (newmessages[i]['tradeId'] == data['tradeId']) {
          String from = data['from'];

          if (from == googleSignin.currentUser!.id) {
            newmessages[i]['status'] = 'declined';
            newmessages[i]['content'] = 'Me: ${data['message']}';
          } else {
            newmessages[i]['status'] = 'declined';
            newmessages[i]['content'] = '${data['name']}: ${data['message']}';
          }
        }
      }
      setState(() {
        messages = newmessages;
      });
    });

    socket!.on('acceptTrade', (data) {

      List<Map<String, dynamic>> newmessages = messages;
      for (int i = 0; i < newmessages.length; i++) {
        if (newmessages[i]['tradeId'] == data['tradeId']) {
          setState(() {
            String from = data['from'];

            if (from == googleSignin.currentUser!.id) {
              newmessages[i]['status'] = 'accepted';
              newmessages[i]['content'] = 'Me: ${data['message']}';
            } else {
              newmessages[i]['status'] = 'accepted';
              newmessages[i]['content'] = '${data['name']}: ${data['message']}';
            }
          });
        }
      }
      setState(() {
        messages = newmessages;
      });
    });

    socket!.on('message', (data) {
      setState(() {
        String from = data['from'];

        if (from == googleSignin.currentUser!.id) {
          messages.add({
            'type': data['type'], // Add the type received from the server.
            'content': 'Me: ${data['message']}',
            'offeredItems': '${data['offered']}',
            'demandedItems': '${data['demanded']}',
            'tradeId': '${data['tradeId']}',
            'status': '${data['status']}'
          });
        } else {
          messages.add({
            'type': data['type'], // Add the type received from the server.
            'content': '${data['name']}: ${data['message']}',
            'offeredItems': '${data['offered']}',
            'demandedItems': '${data['demanded']}',
            'tradeId': '${data['tradeId']}',
            'status': '${data['status']}'
          });
        }
      });
    });

    socket!.on('firstMessage', (data) {
      for (int i = 0; i < data.length; i++) {
        setState(() {
          String from = data[i]['from'];

          if (from == googleSignin.currentUser!.id) {
            if (data[i]['type'] == 'message') {
              messages.add({
                'type': 'message',
                'content': 'Me: ${data[i]['message']}',
              });
            } else {
              messages.add({
                'type': 'tradeRequest',
                'content': 'Me: ${data[i]['message']}',
                'offeredItems': '${data[i]['offered']}',
                'demandedItems': '${data[i]['demanded']}',
                'tradeId': '${data[i]['tradeId']}',
                'status': '${data[i]['status']}'
              });
            }
          } else {
            if (data[i]['type'] == 'message') {
              messages.add({
                'type': 'message',
                'content': '${data[i]['name']}: ${data[i]['message']}',
              });
            } else {
              messages.add({
                'type': 'tradeRequest',
                'content': '${data[i]['name']}: ${data[i]['message']}',
                'offeredItems': '${data[i]['offered']}',
                'demandedItems': '${data[i]['demanded']}',
                'tradeId': '${data[i]['tradeId']}',
                'status': '${data[i]['status']}'
              });
            }
          }
        });
      }
    });
    // Connect to the socket
    socket!.connect();
  }

  @override
  void dispose() {
    // Disconnect and dispose of the socket
    socket!.disconnect();
    socket!.dispose();

    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();

    super.dispose();
  }

  IOClient? https;
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    https = IOClient(ioClient);
    counterId = widget.id;
    recievedTrades = widget.tradesIn;
    // The room id is the id of the user that is logged in and the id of the user that is being chatted with
    int result = googleSignin.currentUser!.id.compareTo(counterId);
    if (result < 0) {
      roomId = googleSignin.currentUser!.id + counterId;
    } else {
      roomId = counterId + googleSignin.currentUser!.id;
    }

    // Dispose of the socket if it already exists
    if (socket != null) {
      socket!.dispose();
    }
    initSocket(); // Initialize the socket
    getTradeData();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut);
        }
      });
    }
  }

  Future<void> fetchChatHistory() async {
    // Create a Completer to handle the async response from the socket
    final completer = Completer<List<Map<String, dynamic>>>();
    // Emit the 'getChatHistory' event
    socket!.emit('getChatHistory', roomId);

    // Listen for the 'firstMessage' event and complete the Completer when it's received
    socket!.once('firstMessage', (data) {
      List<Map<String, dynamic>> newMessages = [];

      for (int i = 0; i < data.length; i++) {
        String from = data[i]['from'];
        if (from == googleSignin.currentUser!.id) {
          if (data[i]['type'] == 'message') {
            newMessages.add({
              'type': 'message',
              'content': 'Me: ${data[i]['message']}',
            });
          } else {
            newMessages.add({
              'type': 'tradeRequest',
              'content': 'Me: ${data[i]['message']}',
              'offeredItems': '${data[i]['offered']}',
              'demandedItems': '${data[i]['demanded']}',
              'tradeId': '${data[i]['tradeId']}',
              'status': '${data[i]['status']}'
            });
          }
        } else {
          if (data[i]['type'] == 'message') {
            newMessages.add({
              'type': 'message',
              'content': '${data[i]['name']}: ${data[i]['message']}',
            });
          } else {
            newMessages.add({
              'type': 'tradeRequest',
              'content': '${data[i]['name']}: ${data[i]['message']}',
              'offeredItems': '${data[i]['offered']}',
              'demandedItems': '${data[i]['demanded']}',
              'tradeId': '${data[i]['tradeId']}',
              'status': '${data[i]['status']}'
            });
          }
        }
      }

      completer.complete(newMessages);
    });

    // Wait for the Completer to complete, and then update the messages state
    final newMessages = await completer.future;
    setState(() {
      messages = newMessages;
    });
  }

  // This method handles what is sent through the socket when we press the send button in the chat
  IconButton _buildSendMessageButton() {
    return IconButton(
      onPressed: () {
        String message = messageController.text.trim();
        if (message.isNotEmpty) {
          setState(() {
            messages.add({'type': 'message', 'content': 'Me: $message'});
          });
          messageController.clear();
          socket!.emit(
            'message',
            {
              'name': googleSignin.currentUser!.displayName!,
              'message': message,
              'room': roomId,
              'from': googleSignin.currentUser!.id,
            },
          );

          // Add this block to scroll down to the latest message when a new message is sent
          WidgetsBinding.instance!.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut);
            }
          });
        }
      },
      icon: const Icon(Icons.send),
    );
  }

  //Colors
  Color outline = const Color.fromARGB(255, 139, 106, 204);
  Color backgroundcolor = const Color.fromARGB(149, 139, 130, 201);

  @override
  Widget build(BuildContext context) {
    String userId = googleSignin.currentUser!.id;
    Column tradebutton;

    //If there are no recieved trades from this individual, show grey button leading to screen for offering trades
    if (trades.isEmpty) {
      tradebutton = Column(children: [
        ElevatedButton(
          onPressed: () async {
            if (await hasTrade() == true) {
              // ignore: use_build_context_synchronously
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text(
                      'Warning',
                      textAlign: TextAlign.center,
                    ),
                    content: const Text(
                      'You already have a pending trade with this user',
                      textAlign: TextAlign.center,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Ok'),
                      ),
                    ],
                  );
                },
              );
            } else {
              final String bar = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          TradingWindow(userId, counterId, socket, roomId)));
              getTradeData();
              setState(() {});
            }
          },
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(globalApplyButtonColor),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
            ),
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.handshake, color: Colors.white),
                SizedBox(width: 8.0),
                Text('Suggest Trade', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ]);
    }
    //Else show green button leading to screen showing trade to accept
    else {
      tradebutton = Column(children: [
        ElevatedButton(
          onPressed: () async {
            final String tradeStatus = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HandleOfferScreen(
                  offeredItems,
                  requestedItems,
                  tradeId,
                  socket,
                  roomId,
                ),
              ),
            );
            if (tradeStatus == "accept" || tradeStatus == "decline") {
              trades = [];
              messages = [];
              await fetchChatHistory();
              setState(
                  () {}); // Call setState() without any asynchronous code inside
            }
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(globalApplyButtonColor),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
            ),
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.handshake, color: Colors.white),
                SizedBox(width: 8.0),
                Text('View Trade', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ]);
    }
    return Scaffold(
      backgroundColor: globalBackground,
      appBar: AppBar(
        backgroundColor: globalAppbarColor,
        toolbarHeight: 40,
        title: Text(widget.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context)
              .unfocus(); // This line will unfocus the text field
          WidgetsBinding.instance!.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut);
            }
          });
        },
        child: Column(
          children: [
            const SizedBox(
              height: 30,
            ),
            tradebutton,
            const SizedBox(
          height: 30,
        ),
            Expanded(
              child: ListView.builder(
  key: ValueKey<int>(messages.length),
  itemCount: messages.length,
  itemBuilder: (BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: messages[index]['content'].startsWith('Me: ')
            ? Alignment.topRight
            : Alignment.topLeft,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: messages[index]['type'] == 'tradeRequest'
                ? globalApplyButtonColor
                : messages[index]['content'].startsWith('Me: ')
                    ? Colors.green[300]
                    : Colors.grey[300],
          ),
          child: messages[index]['type'] == 'tradeRequest'
              ? InkWell(
                  onTap: () async {
                    if (messages[index]['status'] == "pending" &&
                        !messages[index]['content'].startsWith('Me: ')) {
                      final String tradeStatus = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HandleOfferScreen(
                            offeredItems,
                            requestedItems,
                            tradeId,
                            socket,
                            roomId,
                          ),
                        ),
                      );
                      if (tradeStatus == "accept" || tradeStatus == "decline") {
                        trades = [];
                        messages = [];
                        await fetchChatHistory();

                        setState(() {});
                      }
                    } else {
                      final String tradeStatus = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShowTradeDetails(
                              messages[index]['tradeId'],
                              messages[index]['status']),
                        ),
                      );
                    }
                  },
                  child: Text(
                    messages[index]['content']
                        .substring(messages[index]['content'].indexOf(':') + 1)
                        .trim(),
                    style: TextStyle(
                      color: Colors.white,
                      decoration: messages[index]['status'] == "pending"
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                )
              : Text(
                  messages[index]['content']
                      .substring(
                          messages[index]['content'].indexOf(':') + 1)
                      .trim(),
                  style: TextStyle(
                    color: messages[index]['type'] == 'tradeRequest'
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
        ),
      ),
    );
  },
  controller: _scrollController,
),
// ... The rest of your code ...

            ),
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      // Add GestureDetector
                      onTap: () {
                        WidgetsBinding.instance!.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut);
                          }
                        });
                      },
                      child: TextField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type your message here...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  _buildSendMessageButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> hasTrade() async {
    String hasTradeBool = "";

    final url = Uri.parse(
        'https://13.48.78.37:5000/has-trade?userId=$userId&counterId=$counterId');
    final response = await https!.get(url);

    if (response.statusCode == 200) {
      hasTradeBool = jsonDecode(response.body)['status'];
      if (hasTradeBool == "true") {
        return true;
      } else {
        return false;
      }
    } else {
      throw Exception('Failed to check item in trades');
    }
  }

  Future<void> getTradeData() async {
    trades = [];
    requestedItems = [];
    offeredItems = [];
    for (dynamic tradeId in recievedTrades) {
      final url =
          Uri.parse('https://13.48.78.37:5000/get-trade?tradeId=$tradeId');
      final response = await https!.get(url);

      currentTrade = jsonDecode(response.body);

      dynamic senderId = currentTrade['senderId'];
      if (senderId == counterId) {
        trades.add(currentTrade);
      }
    }
    //If trade isnt empty fetch items to show
    if (trades.isNotEmpty) {
      dynamic tradeobject = trades[0];
      //Extract the items requested and demanded
      List<dynamic> offeredItemsId = tradeobject['senderoffer'];
      tradeId = tradeobject['_id'];
      status = tradeobject['status'];

      for (dynamic demandedItem in offeredItemsId) {
        //Get the items demanded and requested

        Uri url = Uri.parse(
            'https://13.48.78.37:5000/get-item-id?itemId=$demandedItem');
        dynamic response = await https!.get(url);
        dynamic responsebody = await jsonDecode(response.body);
        if (!offeredItems.contains(responsebody)) {
          offeredItems.add(responsebody);
        }
      }

      List<dynamic> demandedItemsId = tradeobject['recieverdemands'];
      for (dynamic requestedItem in demandedItemsId) {
        //Get the items demanded
        Uri url = Uri.parse(
            'https://13.48.78.37:5000/get-item-id?itemId=$requestedItem');
        dynamic response = await https!.get(url);
        dynamic responsebody = await jsonDecode(response.body);
        if (!requestedItems.contains(responsebody)) {
          requestedItems.add(responsebody);
        }
      }

      //
    }
    setState(() {
      trades;
      requestedItems;
      offeredItems;
    });
    return;
  }
}
