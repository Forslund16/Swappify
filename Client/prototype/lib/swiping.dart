import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:test_1/displayItem.dart';
import 'dart:core';

import 'package:test_1/match.dart';
import 'package:test_1/profile.dart';
import 'package:test_1/swipingFilters.dart';
import 'addItem.dart';
import 'login.dart';
import 'help.dart';

Color globalAppbarColor = Color.fromRGBO(162, 188, 205, 1);
Color globalBackground = Color.fromARGB(255, 255, 255, 255);
Color globalApplyButtonColor = Color.fromARGB(255, 78, 114, 247);

class Swiping extends StatefulWidget {
  const Swiping({super.key});

  @override
  SwipingState createState() => SwipingState();
}

class SwipingState extends State<Swiping> {
  Map<String, dynamic>? itemData;
  int currentImageIndex = 0;

  bool hasItem = false;
  bool expandNameBox = false;
  double bottomBarMenuButtonSize = 30; // 24 is the smallest size for an icon.
  double bigScreenBoxSize = 0.85;

  //COLOR CONSTANTS
  MaterialColor bottomIconColor = Colors.lightBlue;

  Color profileIconColor = Colors.brown;
  Color addItemColor = const Color.fromARGB(255, 89, 247, 4);
  Color showTradesColor = const Color.fromARGB(255, 206, 44, 90);

  bool imageReady = false;
  final cacheManager = CacheManager(
      Config('my_cache_key', stalePeriod: const Duration(minutes: 30)));

  List<File> downloadedImages = [];

  //Converts a list of URL-images to files and adds them to downloadedImages List.
  addURLPicsToFileList(List<dynamic> urls) async {
    int start = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int numErrors = 0;
    int i = 0;
    while (i < urls.length) {
      try {
        await addOneImage(urls[i]);
        i++;
      } on ClientException catch (e) {
        if (numErrors < urls.length + 2) {
          numErrors++;
          print(
              "ClientException error in getImagesLoop. numErrors: $numErrors");
        } else {
          rethrow;
        }
      }
    }
    int end = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  addOneImage(dynamic url) async {
    var file = await cacheManager.getSingleFile(url).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw ClientException('addOneImage timeout. Threw ClientException.');
      },
    );
    downloadedImages.add(file);
  }

  void showLiked() async {
    await sendItemFeedback('like', 0);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          Timer(const Duration(seconds: 1), () {
            Navigator.of(context).pop();
            setState(() {
              imageReady = false;
              expandNameBox = false;
            });
            fetchItemData();
          });
          Dialog retval = const Dialog(
              backgroundColor: Colors.transparent,
              child: Icon(
                Icons.favorite,
                size: 100,
                color: Colors.green,
              ));

          return retval;
        });
  }

  void showDisliked() async {
    await sendItemFeedback('dislike', 0);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          Timer(const Duration(seconds: 1), () {
            Navigator.of(context).pop();
            setState(() {
              imageReady = false;
              expandNameBox = false;
            });

            fetchItemData();
          });
          Dialog retval = const Dialog(
              backgroundColor: Colors.transparent,
              child: Icon(
                Icons.close,
                size: 100,
                color: Colors.grey,
              ));
          return retval;
        });
  }

  Future<List<File>> downloadImages(List<dynamic> urls) async {
    List<File> files = [];
    for (String url in urls) {
      var response = await https?.get(Uri.parse(url));
      if (response?.statusCode == 200) {
        // create a file with a unique name in the app's temporary directory
        File file = File(
            '${(await getTemporaryDirectory()).path}/${DateTime.now().millisecondsSinceEpoch}.png');
        // write the downloaded image to the file
        await file.writeAsBytes(response?.bodyBytes as List<int>);
        // add the file to the list
        files.add(file);
      }
    }
    return files;
  }

  Future<void> preCacheImages() async {
    if (downloadedImages.length == 1) {
      return;
    }

    if (currentImageIndex != downloadedImages.length - 1) {
      await precacheImage(
          FileImage(downloadedImages[currentImageIndex + 1]), context);
    } else {
      await precacheImage(FileImage(downloadedImages[0]), context);
    }
  }

  clearCacheAndDownloadedImages() async {
    await cacheManager.emptyCache();
    downloadedImages = [];
  }

  final audioPlayer = AudioPlayer(); //AudioPlayer();
  Future<void> _playSound() async {
    AudioCache cache = AudioCache();
    // Play audio file
    cache.play('sounds/spark2.mp3');
  }

  IOClient? https;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    https = IOClient(ioClient);
    fetchItemData();
  }

  // Gets a new item from the database
  Future<void> fetchItemData() async {
    String itemId = "";
    if (itemData != null) {
      itemId = itemData!['item_id'] ?? "";
    }

    String filtersAsString = "";
    if (selectedFilters.isNotEmpty) {
      filtersAsString = selectedFilters.join(',');
    }

    try {
      final response = await https!
          .get(Uri.parse(
              'https://13.48.78.37:5000/get-item-data?userId=$userId&filters=$filtersAsString&currentItemId=$itemId'))
          .timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw ClientException(
              'fetchitemdata timeout. Threw ClientException.');
        },
      );

      itemData = json.decode(response.body);

      if (response.statusCode == 200 && itemData!['status'] == 'OK') {
        await clearCacheAndDownloadedImages();
        await addURLPicsToFileList(itemData!['images']);
        //downloadedImages = await downloadImages(itemData!['images']);
        currentImageIndex = 0;
        preCacheImages();

        for (File image in downloadedImages) {
          final lengthInBytes = image.lengthSync();
          final lengthInKB = lengthInBytes / 1024;
        }
        setState(() {
          imageReady = true;
          hasItem = true;
        });
      } else {
        setState(() {
          clearCacheAndDownloadedImages();
          hasItem = false;
        });
      }
    } on ClientException catch (e) {
      print("caught exception with runtime type: ${e.runtimeType}");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error', textAlign: TextAlign.center),
            content: const Text('Error fetching items from server.',
                textAlign: TextAlign.center),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  fetchItemData();
                },
                child: const Text('Try again'),
              ),
            ],
          );
        },
      );
    }
    //catch all. Remove before final launch
    catch (e) {
      print("caught exception with runtime type: ${e.runtimeType}");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error', textAlign: TextAlign.center),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            content: Text(e.toString()),
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
    }
  }

  // Sends like or dislike status regarding a specific item
  Future<void> sendItemFeedback(String feedback, int numErrors) async {
    try {
      await trySendFeedback(feedback);
    } on ClientException {
      if (numErrors < 2) {
        numErrors++;
        print(
            "error in sending feedback on ${itemData!['item_id']}, error count: $numErrors");
        await sendItemFeedback(feedback, numErrors);
      } else {
        rethrow;
      }
    } catch (e) {
      print("caught exception with runtime type: ${e.runtimeType}");
    }
  }

  Future<void> trySendFeedback(String feedback) async {
    final url = Uri.parse('https://13.48.78.37:5000/item-feedback');
    final response = await https!
        .post(
      url,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'user_id': userId.toString(),
        'item_id': itemData!['item_id'],
        'feedback': feedback,
      }),
    )
        .timeout(
      const Duration(seconds: 1),
      onTimeout: () {
        throw ClientException(
            'trySendFeedback timeout. Threw ClientException.');
      },
    );

    if (response.statusCode == 200) {
      final player = AudioPlayer();
      if ((json.decode(response.body))['match'] == 'true') {
        _playSound;
        //player.play('assets/sounds/spark2.mp3', isLocal: true);
        // ignore: use_build_context_synchronously
        bool goToMatches = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Attention', textAlign: TextAlign.center),
              content: const Text('You have got a new match!',
                  textAlign: TextAlign.center),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              actions: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('View Matches'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Continue Swiping'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );

        if (goToMatches == true) {
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MatchScreen()),
          );
        }
      }
    } else {
      throw Exception('Failed to send feedback');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swappify',
      //TOP BAR
      home: Scaffold(
        backgroundColor: globalBackground,
        appBar: AppBar(
            backgroundColor: globalAppbarColor,
            toolbarHeight: 40,
            title: const Text(
              'Swappify',
              style: TextStyle(
                fontFamily: 'Ubuntu',
                fontSize: 24.0,
                fontWeight: FontWeight.normal,
              ),
            )),
        body: Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                if (itemData != null)
                  Column(
                    children: [
                      if (hasItem == true)
                        GestureDetector(
                          child: Stack(children: [
                            Stack(
                              children: [
                                //imageWidget,
                                SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height *
                                      bigScreenBoxSize,
                                  child: Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        //borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(1),
                                            spreadRadius: 5,
                                            blurRadius: 7,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      margin: const EdgeInsets.all(2),
                                      //padding: const EdgeInsets.all(1),
                                      child: ClipRRect(
                                        //borderRadius: BorderRadius.circular(20),
                                        child: SizedBox(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              bigScreenBoxSize,
                                          child: Center(
                                              child: imageReady
                                                  ? FadeInImage(
                                                      placeholder: Image.asset(
                                                        'assets/images/blank.jpg',
                                                      ).image,
                                                      image: Image.file(
                                                        downloadedImages[
                                                            currentImageIndex],
                                                      ).image,
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              bigScreenBoxSize,
                                                      fit: BoxFit.cover,
                                                      fadeInDuration:
                                                          const Duration(
                                                              milliseconds:
                                                                  200),
                                                      fadeInCurve:
                                                          Curves.easeInCirc,
                                                    )
                                                  : const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: Colors.redAccent,
                                                        backgroundColor:
                                                            Colors.cyan,
                                                      ),
                                                    )),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Add the image indicator dots here
                                imageReady
                                    ? Positioned(
                                        bottom: 15.0,
                                        left: 0.0,
                                        right: 0.0,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                              itemData!['images'].length,
                                              (index) {
                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 2.0),
                                              height: 8.0,
                                              width: 8.0,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    index == currentImageIndex
                                                        ? Colors.blueGrey
                                                        : Colors.grey
                                                            .withOpacity(0.5),
                                              ),
                                            );
                                          }),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                            imageReady
                                ? Positioned(
                                    left: 20,
                                    top: 20,
                                    child: GestureDetector(
                                      child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color.fromRGBO(
                                                150, 150, 150, 150),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color.fromRGBO(
                                                    150, 150, 150, 220),
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
                                                itemData!['name'].length > 13
                                                    ? (expandNameBox
                                                        ? '${itemData!['name'].substring(0, 13)}'
                                                        : '${itemData!['name'].substring(0, 13)}...')
                                                    : '${itemData!['name']}',
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
                                              expandNameBox &&
                                                      itemData!['name'].length >
                                                          13
                                                  ? Text(
                                                      itemData!['name']
                                                                  .substring(13)
                                                                  .length >
                                                              13
                                                          ? '${itemData!['name'].substring(13)}...'
                                                          : '${itemData!['name'].substring(13)}.',
                                                      style: const TextStyle(
                                                        fontSize: 24.0,
                                                        color: Colors.white70,
                                                        shadows: [
                                                          Shadow(
                                                            color:
                                                                Color.fromRGBO(
                                                                    100,
                                                                    100,
                                                                    100,
                                                                    10),
                                                            blurRadius: 10,
                                                          )
                                                        ],
                                                      ),
                                                    )
                                                  : SizedBox.shrink(),
                                              Text(
                                                'Gender: ${itemData!['gender']}',
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
                                                itemData!['size'].length > 20
                                                    ? 'Size: ${itemData!['size'].substring(0, 15)}...'
                                                    : 'Size: ${itemData!['size']}',
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
                                              expandNameBox
                                                  ? Text(
                                                      itemData!['desc'].length >
                                                              18
                                                          ? 'Description: ${itemData!['desc'].substring(0, 18)}'
                                                          : 'Description: ${itemData!['desc']}',
                                                      style: const TextStyle(
                                                        fontSize: 16.0,
                                                        color: Colors.white70,
                                                        shadows: [
                                                          Shadow(
                                                            color:
                                                                Color.fromRGBO(
                                                                    100,
                                                                    100,
                                                                    100,
                                                                    10),
                                                            blurRadius: 10,
                                                          )
                                                        ],
                                                      ),
                                                    )
                                                  : SizedBox.shrink(),
                                              expandNameBox &&
                                                      itemData!['desc'].length >
                                                          18
                                                  ? Text(
                                                      itemData!['desc']
                                                                  .substring(18)
                                                                  .length >
                                                              28
                                                          ? '${itemData!['desc'].substring(18, 46)}...'
                                                          : '${itemData!['desc'].substring(18)}.',
                                                      style: const TextStyle(
                                                        fontSize: 16.0,
                                                        color: Colors.white70,
                                                        shadows: [
                                                          Shadow(
                                                            color:
                                                                Color.fromRGBO(
                                                                    100,
                                                                    100,
                                                                    100,
                                                                    10),
                                                            blurRadius: 10,
                                                          )
                                                        ],
                                                      ),
                                                    )
                                                  : SizedBox.shrink(),
                                            ],
                                          )),
                                      //onTap show the items desc as a decoration like name and size was shown above
                                      onTap: () {
                                        expandNameBox = !expandNameBox;
                                        //Update the state of the app
                                        setState(() {
                                          expandNameBox;
                                        });
                                      },
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            imageReady
                                ? Positioned(
                                    right: 16,
                                    bottom: 16,
                                    child: Container(
                                      // ignore: prefer_const_constructors
                                      decoration: BoxDecoration(
                                        color: Colors.green.withAlpha(100),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.green,
                                          width: 2,
                                        ),
                                        //color: Colors.transparent,
                                      ),
                                      child: IconButton(
                                        iconSize: 60,
                                        onPressed: () async {
                                          try {
                                            showLiked();
                                          } on ClientException {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text('Error',
                                                      textAlign:
                                                          TextAlign.center),
                                                  content: const Text(
                                                      'Error sending feedback to server, please try again later',
                                                      textAlign:
                                                          TextAlign.center),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.0),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Text('Ok'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.check),
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            imageReady
                                ? Positioned(
                                    left: 16,
                                    bottom: 16,
                                    child: Container(
                                      // ignore: prefer_const_constructors
                                      decoration: BoxDecoration(
                                        color: Colors.red.withAlpha(100),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                        //color: Colors.transparent,
                                      ),
                                      child: IconButton(
                                        iconSize: 60,
                                        onPressed: () async {
                                          try {
                                            showDisliked();
                                          } on ClientException {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text('Error',
                                                      textAlign:
                                                          TextAlign.center),
                                                  content: const Text(
                                                      'Error sending feedback to server, please try again later',
                                                      textAlign:
                                                          TextAlign.center),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.0),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Text('Ok'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.close),
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            Positioned(
                              right: 17,
                              top: 17,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withAlpha(150),
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(100, 100, 100, 200),
                                      spreadRadius: 3,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  iconSize: 30,
                                  onPressed: () async {
                                    final response = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const SwipingFilters()),
                                    );
                                    try {
                                      setState(() {
                                        imageReady = false;
                                      });
                                      fetchItemData();
                                    } catch (e) {
                                      print(
                                          "caught exception with runtime type: ${e.runtimeType}");
                                      // ignore: use_build_context_synchronously
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Error'),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            content: const Text(
                                                'Error fetching items from servers, please try again later'),
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
                                    }
                                  },
                                  icon: const Icon(Icons.filter_alt),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ]),

                          onTap: () {
                            if (downloadedImages.length != 1) {
                              setState(() {
                                currentImageIndex = (currentImageIndex + 1) %
                                    (downloadedImages.length ?? 0);
                              });
                              preCacheImages();
                            }
                          },
                          onLongPress: () {
                            //Navigate to displayItem
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DisplayItem(itemData!)),
                            );
                          },

                          //SWIPING HANDLING BELOW
                          onHorizontalDragEnd: (details) async {
                            // Check if the swipe was left to right or right to left
                            if (details.velocity.pixelsPerSecond.dx > 0) {
                              try {
                                showLiked();
                              } on ClientException {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Error',
                                          textAlign: TextAlign.center),
                                      content: const Text(
                                          'Error sending feedback to server, please try again later',
                                          textAlign: TextAlign.center),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Ok'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                              // Right to left
                            } else {
                              // Left to right
                              try {
                                showDisliked();
                              } on ClientException {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Error',
                                          textAlign: TextAlign.center),
                                      content: const Text(
                                          'Error sending feedback to server, please try again later',
                                          textAlign: TextAlign.center),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Ok'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          },
                        ),
                      if (hasItem == false)
                        Stack(
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height *
                                  bigScreenBoxSize,
                              child: Image.asset(
                                'assets/images/noitems.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 17,
                              top: 17,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withAlpha(150),
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(100, 100, 100, 200),
                                      spreadRadius: 3,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  iconSize: 30,
                                  onPressed: () async {
                                    final response = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const SwipingFilters()),
                                    );
                                    try {
                                      fetchItemData();
                                    } catch (e) {
                                      print(e);
                                      // ignore: use_build_context_synchronously
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Error'),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            content: const Text(
                                                'Error fetching items from servers, please try again later'),
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
                                    }
                                  },
                                  icon: const Icon(Icons.filter_alt),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                //BOTTOM BAR
                Expanded(
                  child: Container(
                    color: globalAppbarColor,
                    child: Flex(
                      direction: Axis.horizontal,
                      //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                            flex: 1,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.transparent,
                                child: Icon(
                                  Icons.person,
                                  size: bottomBarMenuButtonSize,
                                  color: Colors.white,
                                ),
                              ),
                            )),
                        Flexible(
                            flex: 1,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddClothesScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.transparent,
                                // necessary to make the gesturedetector read the entire container
                                child: Icon(
                                  Icons.add_circle,
                                  size: bottomBarMenuButtonSize,
                                  color: Colors.white,
                                ),
                              ),
                            )),
                        Flexible(
                            flex: 1,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MatchScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.transparent,
                                // necessary to make the gesturedetector read the entire container
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.message,
                                  size: bottomBarMenuButtonSize,
                                  color: Colors.white,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
