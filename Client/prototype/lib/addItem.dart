// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:test_1/login.dart';
import 'package:test_1/swiping.dart';
import 'package:test_1/swipingFilters.dart';

import 'imageCompression.dart';

class AddClothesScreen extends StatefulWidget {
  const AddClothesScreen({super.key});

  @override
  AddClothesScreenState createState() => AddClothesScreenState();
}

class AddClothesScreenState extends State<AddClothesScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedGender;
  bool _showGenderButtons = false;
  final ImagePicker picker = ImagePicker();
  List<XFile> rupert = []; // rupert is a temporary variable name.
  String? name;
  String? desc;
  String? size;
  var pictureIndex = 0;

  Set<String> _selectedTags = {};
  bool _showTagButtons = false;
  Set<int> _selectedIndexList = {};

  IOClient? https;
  

  @override
  void initState() {
    super.initState();
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    https = IOClient(ioClient);
  }

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

  //Colors
  Color tagsNotSelected = Colors.white;
  Color tagsSelected = globalAppbarColor;
  Color cursorColor = Colors.black;
  Color underLineColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: globalBackground,
      appBar: AppBar(
        backgroundColor: globalAppbarColor,
        toolbarHeight: 40,
        title: const Text('Add Clothes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    cursorColor: cursorColor,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      name = value;
                      return null;
                    },
                  ),
                  TextFormField(
                    cursorColor: cursorColor,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      desc = value;
                      return null;
                    },
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showGenderButtons = !_showGenderButtons;
                      });
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        // Maybe rename to like Fit? It might be simpler to keep gender out of this.
                        // errorText: _selectedGender == null
                        //     ? 'Please select a gender'
                        //     : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            _selectedGender ?? 'Select gender',
                            // Maybe rename to like Fit? It might be simpler to keep gender out of this.
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
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
                                _selectedGender = value;
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
                                _selectedGender = value;
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
                                _selectedGender = value;
                                _showGenderButtons = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  TextFormField(
                    cursorColor: cursorColor,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a size';
                      }
                      size = value;
                      return null;
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
                        labelText: 'Tags ',
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
                    ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        rupert.length > 1
                            ? Container(
                                // ignore: prefer_const_constructors
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  iconSize: 40,
                                  onPressed: () {
                                    if (rupert.isNotEmpty) {
                                      if (rupert.length != 1) {
                                        setState(() {
                                          pictureIndex = (pictureIndex - 1) %
                                              (rupert.length);
                                        });
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.arrow_back_ios_outlined,
                                    size: 40,
                                  ),
                                  color: cursorColor,
                                ),
                              )
                            : SizedBox.shrink(),
                        Stack(
                          children: [
                            // Wrap the image container with GestureDetector
                            GestureDetector(
                              onTap: () async {
                                List<XFile>? temp =
                                    await picker.pickMultiImage();
                                rupert.addAll(temp);
                                setState(() {
                                  pictureIndex = rupert.length - 1;
                                });
                              },
                              child: Container(
                                width: 200,
                                height: 200,
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
                                  child: rupert.isNotEmpty
                                      ? Image.file(
                                          File(rupert[pictureIndex].path),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          'assets/images/selectImage.png',
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                            // Image container ends here
                            rupert.isNotEmpty
                                ? Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      // ignore: prefer_const_constructors
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Colors.red, width: 2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        iconSize: 24,
                                        onPressed: () {
                                          setState(() {
                                            rupert.removeAt(pictureIndex);
                                            pictureIndex == 0
                                                ? pictureIndex = 0
                                                : pictureIndex--;
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 30,
                                        ),
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink()
                          ],
                        ),
                        rupert.length > 1
                            ? Container(
                                // ignore: prefer_const_constructors
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  iconSize: 40,
                                  onPressed: () {
                                    if (rupert.isNotEmpty) {
                                      if (rupert.length != 1) {
                                        setState(() {
                                          pictureIndex = (pictureIndex + 1) %
                                              (rupert.length);
                                        });
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    size: 40,
                                  ),
                                  color: Colors.blueGrey,
                                ),
                              )
                            : SizedBox.shrink()
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (rupert.isEmpty) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text(
                                      'Warning',
                                      textAlign: TextAlign.center,
                                    ),
                                    content: const Text(
                                        'You cant upload an item without any pictures!',
                                        textAlign: TextAlign.center),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    actions: [
                                      ButtonBar(
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Ok'),
                                          ),
                                        ],
                                      )
                                    ],
                                  );
                                },
                              );
                            } else {
                              if (_formKey.currentState!.validate()) {
                                // Perform the upload action here
                                // You can access the form data using _formKey.currentState!.value
                                sendNewItem(name!, desc!, _selectedGender!,
                                    size!, _selectedTags, rupert);
                              }
                            }
                          },
                          style: ButtonStyle(

                            backgroundColor: MaterialStateProperty.all<Color>(globalApplyButtonColor),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                          child: const Text('Publish'),
                        ),
                      ] // Row Children end
                      ),
                ], // Column Children end
              ),
            ),
            // Here ends the User-inputs.
          ], // Stack Children end
        ),
      ),
    );
  }


  Future<void> sendNewItem(String name, String desc, String gender, String size,
      Set<String> tagSet, List<XFile> rupert) async {
    List<String> tagList = tagSet.toList();
    tagList.add(gender);
    List<Uint8List> imageBytes = [];

    List<XFile> compressedImages = await compressAllImages(rupert);

    for (int i = 0; i < compressedImages.length; i++) {
      final imagePath = compressedImages[i].path;
      final bytes = await File(imagePath).readAsBytes();
      imageBytes.add(bytes);
    }
    final data = {
      'name': name,
      'desc': desc,
      'gender': gender,
      'size': size,
      'type': "",
      'tags': tagList,
      'images': imageBytes,
      'user_id': googleSignin.currentUser?.id.toString(),
      'liked_by': [],
    };
    final url = Uri.parse('https://13.48.78.37:5000/add-item');
    final response = await https!.post(
      url,
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send new item');
    } else if (response.statusCode == 200) {
      //Show an alert dialog to the user that the item was successfully uploaded
      showDialog(
        context: context,
        builder: (BuildContext context) {
          //Start a timer that triggers after 2 seconds poping the context twice
          Timer(const Duration(seconds: 2), () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          });
          return AlertDialog(
            title: const Text(
              'Success',
              textAlign: TextAlign.center,
            ),
            //An icon that is a green checkmark
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),

            content: const Text(
                'Your item was successfully uploaded!',
                textAlign: TextAlign.center),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            
          );
        },
      );
    }
  }
}
