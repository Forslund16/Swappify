// ignore_for_file: file_names

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/io_client.dart';
import 'package:test_1/imageCompression.dart';
import 'package:test_1/login.dart';
import 'package:test_1/swiping.dart';
import 'package:test_1/swipingFilters.dart';

class EditClothesScreen extends StatefulWidget {
  final int itemIndex;
  final IOClient ioClient;
  const EditClothesScreen({Key? key, required this.itemIndex, required this.ioClient})
      : super(key: key);

  @override
  EditClothesScreenState createState() => EditClothesScreenState();
}

class EditClothesScreenState extends State<EditClothesScreen> {
  int itemIndex = 0;
  String name = 'h';
  String desc = 'h';
  String size = 'h';
  String _selectedGender = 'h';
  bool _showGenderButtons = false;

  Set<String> _selectedTags = {};
  bool _showTagButtons = false;
  final Set<int> _selectedIndexList = {};

  void pressTagButton(int index) {
    setState(() {
      if (_selectedIndexList.contains(index)) {
        _selectedIndexList.remove(index);
        _selectedTags.remove(availableTagsNoGender[index]);
      } else {
        _selectedIndexList.add(index);
        _selectedTags.add(availableTagsNoGender[index]);
      }
    });
  }

  bool isPressed(int index) {
    return _selectedIndexList.contains(index);
  }

  List<XFile> rupert = []; // rupert is a temporary variable name.

  final ImagePicker picker = ImagePicker();
  int pictureIndex = 0;

  dynamic itemData;
  IOClient? https;

  //Colors
  Color outline = globalAppbarColor;
  Color background = Color.fromARGB(255, 205, 165, 77);
  Color removeItem = Color.fromARGB(255, 222, 52, 9);
  Color saveChanges = Color.fromARGB(255, 54, 163, 42);
  Color addPicture = globalApplyButtonColor;

  Color cursorColor = Colors.black;
  Color underLineColor = Colors.grey;
  Color tagsNotSelected = Colors.white;
  Color tagsSelected = globalAppbarColor;

  @override
  void initState() {
    super.initState();
    https = widget.ioClient;
    _updateVariables();
    itemIndex = widget.itemIndex;
  }

  void _updateVariables() {
    setState(() {
      //userid = googleSignin.currentUser?.id;
      getUserdata();
    });
  }

  void getUserdata() async {
    itemIndex = widget.itemIndex;
    if (itemData != null) {
      if (itemIndex >= itemData['images'].length) {
        print(
            "itemIndex out of range. Probably occurred as you deleted an item.");
        return;
      }
    }
    final url =
        //Uri.parse('https://13.48.78.37:5000/get-user-items?userId=$userId');
        Uri.parse(
            'https://13.48.78.37:5000/get-one-user-item?userId=$userId&itemIndex=$itemIndex');

    final response = await https!.get(url);

    if (response.statusCode == 200) {
      setState(() {
        itemData = (json.decode(response.body))['info'];
        if (itemData != null) {
          name = itemData['name'] ?? '';
          desc = itemData['desc'] ?? '';
          size = itemData['size'] ?? '';
          _selectedGender = itemData['gender'] ?? '';

          List<dynamic> tagList = itemData['tags'];
          _selectedTags =
              tagList.map((dynamicTag) => dynamicTag.toString()).toSet();
          //_selectedTags.map((e) => e == "Man" || e == "Woman" || e == "Unisex" ? _selectedTags.remove(e): null);
          _selectedTags
              .removeWhere((e) => e == "Man" || e == "Woman" || e == "Unisex");

          for (int i = 0; i < availableTagsNoGender.length; i++) {
            for (String tag in _selectedTags) {
              tag == availableTagsNoGender[i]
                  ? _selectedIndexList.add(i)
                  : null;
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (itemData == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Scaffold(
        backgroundColor: globalBackground,
        appBar: AppBar(
          backgroundColor: globalAppbarColor,
          toolbarHeight: 40,
          title: const Text('Edit Item'),
        ),
        body: Form(
          child: ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    cursorColor: cursorColor,
                    initialValue: itemData['name'].toString(),
                    decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: cursorColor),
                        iconColor: cursorColor,
                        hoverColor: cursorColor,
                        focusColor: cursorColor,
                        fillColor: cursorColor,
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: underLineColor)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: cursorColor))),
                    onChanged: (value) {
                      name = value;
                    },
                  ),
                  TextFormField(
                    cursorColor: cursorColor,
                    initialValue: itemData['desc'].toString(),
                    decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: cursorColor),
                        iconColor: cursorColor,
                        hoverColor: cursorColor,
                        focusColor: cursorColor,
                        fillColor: cursorColor,
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: underLineColor)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: cursorColor))),
                    onChanged: (value) {
                      desc = value;
                    },
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showGenderButtons = !_showGenderButtons;
                      });
                    },
                    child: InputDecorator(
                      // ignore: prefer_const_constructors
                      decoration: InputDecoration(
                        labelText: 'Gender',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            _selectedGender,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          _showGenderButtons
                              ? const Icon(Icons.arrow_drop_up)
                              : const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  if (_showGenderButtons)
                    Column(
                      children: <Widget>[
                        ListTile(
                          title: const Text('Man'),
                          leading: Radio<String>(
                            value: 'Man',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value!;
                                _showGenderButtons = false;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text('Woman'),
                          leading: Radio<String>(
                            value: 'Woman',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value!;
                                _showGenderButtons = false;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text('Unisex'),
                          leading: Radio<String>(
                            value: 'Unisex',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value!;
                                _showGenderButtons = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  TextFormField(
                    cursorColor: cursorColor,
                    initialValue: itemData['size'].toString(),
                    decoration: InputDecoration(
                        labelText: 'Size',
                        labelStyle: TextStyle(color: cursorColor),
                        iconColor: cursorColor,
                        hoverColor: cursorColor,
                        focusColor: cursorColor,
                        fillColor: cursorColor,
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: underLineColor)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: cursorColor))),
                    onChanged: (value) {
                      size = value;
                    },
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showTagButtons = !_showTagButtons;
                      });
                    },
                    child: InputDecorator(
                      // ignore: prefer_const_constructors
                      decoration: InputDecoration(
                        labelText: 'Tags',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            _selectedTags.isEmpty
                                ? "No tags have been selected"
                                : _selectedTags.join(','),
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          _showTagButtons
                              ? const Icon(Icons.arrow_drop_up)
                              : const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  if (_showTagButtons)
                    Column(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: GridView.count(
                                scrollDirection: Axis.vertical,
                                crossAxisCount: 1,
                                childAspectRatio: 6,
                                semanticChildCount: 4,
                                children: List.generate(
                                    availableTagsNoGender.length, (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      pressTagButton(index);
                                    },
                                    child: Container(
                                        alignment: Alignment.center,
                                        margin: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isPressed(index)
                                              ? tagsSelected
                                              : tagsNotSelected,
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color.fromRGBO(
                                                  100, 100, 100, 200),
                                              spreadRadius: 3,
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Icon(
                                              isPressed(index)
                                                  ? Icons.check_box
                                                  : Icons
                                                      .check_box_outline_blank,
                                              color: isPressed(index)
                                                  ? tagsNotSelected
                                                  : tagsSelected,
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              availableTagsNoGender[index],
                                              style: const TextStyle(
                                                fontSize: 17,
                                                color: Colors.black,
                                                // shadows: [
                                                //   Shadow(
                                                //     color: Color.fromRGBO(
                                                //         100, 100, 100, 100),
                                                //     blurRadius: 10,
                                                //   )
                                                // ],
                                              ),
                                            ),
                                          ],
                                        )),
                                  );
                                }),
                              ),
                            )),
                      ],
                      // Here ends list of all tags
                    )
                ], // Column children end (name, desc osv)
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text(
                              'Confirm',
                              textAlign: TextAlign.center,
                            ),
                            content: const Text(
                                'Are you sure you want to save your changes?',
                                textAlign: TextAlign.center),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            actions: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {
                                        updateItem();
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Ok'),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(saveChanges),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                          side: BorderSide(color: saveChanges.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    child: const Text("Save"),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  itemData['images'].length > 1
                      ? Container(
                          // ignore: prefer_const_constructors
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 40,
                            onPressed: () {
                              if (itemData['images']?.length != 1) {
                                setState(() {
                                  pictureIndex = (pictureIndex - 1) %
                                      (itemData['images']?.length ?? 0) as int;
                                });
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_outlined,
                              size: 40,
                            ),
                            color: Colors.blueGrey,
                          ),
                        )
                      : const SizedBox.shrink(),

                  // PICTURE OF PIECE OF CLOTHING STARTS HERE
                  //Added check to ensure malformed data wont crash the app but should be handled better
                  if(itemData['images'].length > 0)
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: outline,
                          borderRadius: BorderRadius.circular(20),
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: outline,
                          //     spreadRadius: 5,
                          //     blurRadius: 7,
                          //     offset: const Offset(0, 3),
                          //   ),
                          // ],
                        ),
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: FutureBuilder(
                            future: precacheImage(
                                NetworkImage(
                                    '${itemData!['images'][pictureIndex]}'),
                                context),
                            builder: (BuildContext context,
                                AsyncSnapshot<dynamic> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                    print("waiting on image");
                                return const SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return GestureDetector(
                                  onTap: () => setState(() {}),
                                  child: const Center(
                                    child: Text(
                                        'Failed to load image. Tap to try again.'),
                                  ),
                                );
                              } else {
                                return Image.network(
                                  itemData['images'][pictureIndex].toString(),
                                  fit: BoxFit.cover,
                                  height: 200,
                                  width: 200,
                                  alignment: Alignment.center,
                                  errorBuilder: (BuildContext context,
                                      Object exception,
                                      StackTrace? stackTrace) {
                                    return const Icon(Icons.error);
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      // Circular delete-button starts here
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          // ignore: prefer_const_constructors
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.red, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 24,
                            onPressed: () {
                              if (itemData['images']?.length == 1) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Warning'),
                                      content: const Text(
                                          'You can\'t delete your last pic!'),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('ok'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text(
                                        'Confirm',
                                        textAlign: TextAlign.center,
                                      ),
                                      content: const Text(
                                        'Are you sure you want to delete this picture?',
                                        textAlign: TextAlign.center,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      actions: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () {
                                                  /*
                                                 * The ordering of these function-calls (apart
                                                 * from setState) seems to be important for
                                                 * some reason.
                                                 */

                                                  deleteOnePic();

                                                  getUserdata();

                                                  Navigator.of(context).pop();
                                                  setState(() {});
                                                },
                                                child: const Text('Yes'),
                                              ),
                                            ),
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Cancel'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.delete,
                              //Icons.highlight_remove,
                              //Icons.close,
                              size: 30,
                            ),
                            color: Colors.redAccent,
                          ),
                        ),
                      )
                    ],
                  ),

                  // PICTURE OF PIECE OF CLOTHING ENDS HERE
                  itemData['images'].length > 1
                      ? Container(
                          // ignore: prefer_const_constructors
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 40,
                            onPressed: () {
                              if (itemData['images']?.length != 1) {
                                setState(() {
                                  pictureIndex = (pictureIndex + 1) %
                                      (itemData['images']?.length ?? 0) as int;
                                });
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_forward_ios_outlined,
                              size: 40,
                            ),
                            color: Colors.blueGrey,
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (await isInTrade() == true) {
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
                                'You can\'t delete items in active trades!',
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
                        // ignore: use_build_context_synchronously
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text(
                                'Confirm',
                                textAlign: TextAlign.center,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              content: const Text(
                                'Are you sure you want to delete this article?\n(This cannot be undone)',
                                textAlign: TextAlign.center,
                              ),
                              actions: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () async {
                                          try {
                                            deleteItem();
                                          } catch (e) {
                                            print(
                                                "caught exception with runtime type: ${e.runtimeType}");
                                            print("error in deleting item");
                                          }
                                        },
                                        child: const Text('Yes'),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(removeItem),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(color: removeItem),
                        ),
                      ),
                    ),
                    child: const Text("Delete this article"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      List<XFile>? temp;
                      temp = await picker.pickMultiImage();
                      if (temp.isEmpty) {
                        return;
                      }
                      rupert.clear();
                      rupert.addAll(temp);
                      temp.clear();

                      /*
                     * The ordering of these function-calls (apart
                     * from setState) seems to be important for
                     * some reason.
                     */
                      addMorePics(rupert);
                      //getUserdata();

                      setState(() {});
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(addPicture),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(color: addPicture),
                        ),
                      ),
                    ),
                    child: const Text('Add Picture(s)'),
                  ),
                ],
              ),
              const SizedBox(
                height: 50,
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<bool> isInTrade() async {
    String currentItemId = itemData['_id'];
    final url =
        Uri.parse('https://13.48.78.37:5000/is-in-trade?itemId=$currentItemId');
    final response = await https!.get(url);

    if (response.statusCode == 200) {
      dynamic answer = jsonDecode(response.body);
      if (answer['status'] == 'true') {
        return true;
      }
      return false;
    } else {
      throw Exception('Failed to check item in trades');
    }
  }

  Future<void> deleteOnePic() async {
    final data = {
      'objectIdentifier': itemData['_id'].toString(),
      'imageURL': itemData['images'][pictureIndex].toString(),
    };
    final url = Uri.parse('https://13.48.78.37:5000/delete-one-pic');

    final response = await https!.post(
      url,
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      getUserdata();
      setState(() {
        pictureIndex == 0 ? pictureIndex = 0 : pictureIndex--;
      });
    }
  }

  Future<void> addMorePics(List<XFile> rupert_in) async {
    List<Uint8List> imageBytes = [];

    List<XFile> compressedImages = await compressAllImages(rupert_in);

    for (int i = 0; i < compressedImages.length; i++) {
      final imagePath = compressedImages[i].path;
      final bytes = await File(imagePath).readAsBytes();

      imageBytes.add(bytes);
    }


    final data = {
      'images': imageBytes,
      'objectIdentifier': itemData['_id'].toString(),
    };
    final url = Uri.parse('https://13.48.78.37:5000/add-more-pics');
    final response = await https!.post(
      url,
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      getUserdata();
      setState(() {
        pictureIndex = itemData['images']?.length;
      });
    }
  }

  // Updates fields in the item data
  Future<void> updateItem() async {
    List<String> _selectedTagList = _selectedTags.toList();
    _selectedTagList.insert(0, _selectedGender);
    final data = {
      'item_id': itemData['_id'].toString(),
      'name': name,
      'desc': desc,
      'size': size,
      'gender': _selectedGender,
      'tags': _selectedTagList,
    };


    final url = Uri.parse('https://13.48.78.37:5000/edit-item?userId=$userId');
    final response = await https!.post(
      url,
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update item');
    }
  }

  Future<void> deleteItem() async {
    final data = {
      'item_id': itemData['_id'].toString(),
      'images': itemData['images'],
    };
    final url =
        Uri.parse('https://13.48.78.37:5000/delete-item?userId=$userId');
    final response = await https!.post(
      url,
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      _updateVariables();
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();

      rupert.clear();
      setState(() {});
    }
  }
}
