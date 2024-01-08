import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:test_1/editItem.dart';
import 'package:test_1/editProfile.dart';
import 'package:test_1/login.dart';
import 'package:test_1/swiping.dart';
import 'displayItem.dart';
import 'help.dart';

import 'addItem.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  String? userid;

  //List<dynamic>? rupert; // rupert is a temporary variable name.
  int currIndex = 0;
  List<dynamic> userItems = [];
  late IOClient https;

  @override
  void initState() {
    super.initState();
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    https = IOClient(ioClient);
    _updateVariables();
  }

  //Color constants
  Color outline = Colors.brown;
  Color background = const Color.fromRGBO(255, 255, 255, 1);
  Color editprofilecolor = globalAppbarColor;

  Future<void> _updateVariables() async {
    setState(() {
      //userid = googleSignin.currentUser?.id;
      getItems();
    });
  }

  Future<void> getItems() async {
    final url =
        Uri.parse('https://13.48.78.37:5000/get-user-items?userId=$userId');
    //Ingen duration på timeout gav knas förut
    final response = await https.get(url).timeout(const Duration(seconds: 7));

    if (response.statusCode == 200) {
      setState(() {
        userItems = (json.decode(response.body))['info'];
        //rupert = userItems[0]['images'];
      });
    }
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
          onTap: () async {
            // Code to execute when container is tapped
            // For example, you can navigate to a new screen or show a dialog
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      EditClothesScreen(itemIndex: index, ioClient: https)),
            );
            setState(() {
              _updateVariables();
            });
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
        );
      },
    );
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
            title: const Text('Your Profile'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  bool confirmLogout = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title:
                            const Text('Log out', textAlign: TextAlign.center),
                        content: const Text('Are you sure you want to log out?',
                            textAlign: TextAlign.center),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        actions: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Log out'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmLogout == true) {
                    await googleSignin.signOut();
                    // ignore: use_build_context_synchronously
                    // Navigator.of(context).pop();
                    // // ignore: use_build_context_synchronously
                    // Navigator.of(context).pop();
                    // ignore: use_build_context_synchronously
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HelpScreen()),
                  );
                },
                child: const Text(
                  'Help',
                  style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.4,
                //color: Colors.greenAccent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          NetworkImage(googleSignin.currentUser!.photoUrl!),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      googleSignin.currentUser!.displayName!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EditUserScreen()),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: editprofilecolor,
                          borderRadius: BorderRadius.circular(
                              25), // Increase borderRadius value
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(150, 150, 150, 220),
                              spreadRadius: 4,
                              blurRadius: 2,
                              //offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Edit profile",
                              style: TextStyle(
                                //fontStyle: FontStyle.italic,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Container(
                              padding: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: globalApplyButtonColor,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(
                                    25), // Increase borderRadius value
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(100, 100, 100, 200),
                                    spreadRadius: 3,
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              (userItems.isEmpty)
                  ? Container(
                      width: MediaQuery.of(context).size.width * 0.5,
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
                          child: Column(
                            children: const [
                              SizedBox(
                                height: 10,
                              ),
                              Text("You dont have any items"),
                              SizedBox(
                                height: 10,
                              ),
                            ],
                          )))
                  : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(
                        child: displayItems(userItems),
                      ),
                    ),
            ],
          ),
        ));
  }
}
