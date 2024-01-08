import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'login.dart';
import 'swiping.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({Key? key}) : super(key: key);

  @override
  AddUserScreenState createState() => AddUserScreenState();
}

class AddUserScreenState extends State<AddUserScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  IOClient? https;
  @override
  void initState() {
    super.initState();
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    https = IOClient(ioClient);
  }

  // Sends user data to the database
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final data = {
      'google_id': googleSignin.currentUser!.id,
      'username': googleSignin.currentUser!.displayName,
      'email': googleSignin.currentUser!.email,
      'phone': _phoneController.text,
    };

    final url = Uri.parse('https://13.48.78.37:5000/add-user');
    final response = await https!.post(
      url,
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to submit form');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: globalBackground,
      appBar: AppBar(
        title: const Text('Add User'),
        toolbarHeight: 40,
        backgroundColor: globalAppbarColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    _submitForm();
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Swiping()),
                    );
                  },
                  child: const Text('Add User'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
