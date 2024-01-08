import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:test_1/privacyPolicy.dart';
import 'package:test_1/addUser.dart';
import 'package:test_1/swiping.dart';
import 'package:animated_background/animated_background.dart';

String userId = "";
final GoogleSignIn googleSignin = GoogleSignIn();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  List<Color> background = [
    const Color.fromARGB(255, 154, 203, 255),
    const Color.fromARGB(255, 202, 217, 221),
    const Color.fromARGB(255, 255, 255, 255),
    const Color.fromARGB(255, 202, 217, 221),
    const Color.fromARGB(255, 154, 203, 255)
  ];
  Map<String, dynamic>? loginStatus;
  bool connectionError = false;
  IOClient? https;
  @override
  void initState() {
    super.initState();
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    https = IOClient(ioClient);
  }

  Future<bool> loginRequest() async {
    userId = googleSignin.currentUser!.id;
    connectionError = false;
    //TODO: Should we use this soluton or popup instead?
    while (true) {
      if (userId == "") {
        googleSignin.signIn();
      }
      userId = googleSignin.currentUser!.id;
      try {
        final response = await https!
            .get(Uri.parse('https://13.48.78.37:5000/login?userId=$userId'))
            .timeout(const Duration(seconds: 10));

        setState(() {
          loginStatus = json.decode(response.body);
        });
        if (response.statusCode == 200 && loginStatus!['status'] == 'OK') {
          return true;
        }
        return false;
      } on SocketException {
        sleep(const Duration(seconds: 5));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Container loginImage = Container(
      width: 170,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/recycle.png'),
          fit: BoxFit.contain,
        ),
      ),
      child: Image.asset('assets/images/recycle.png',
          color: Color.fromARGB(151, 154, 203, 255).withOpacity(0.8)),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: background,
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            tileMode: TileMode.clamp,
          ),
        ),
        child: AnimatedBackground(
          behaviour: RandomParticleBehaviour(
            options: const ParticleOptions(
              spawnMaxRadius: 50,
              spawnMinSpeed: 10.00,
              particleCount: 45,
              spawnMaxSpeed: 50,
              minOpacity: 0.3,
              spawnOpacity: 0.4,
              baseColor: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          vsync: this,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(child: loginImage),
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 0, 69, 188),
                              Color.fromARGB(255, 53, 109, 205),
                              Color.fromARGB(255, 43, 149, 255)
                            ],
                            stops: [0.0, 0.5, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            tileMode: TileMode.clamp,
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: const Center(
                          child: Text(
                            'Swappify',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 64, // or any other size that you prefer
                              fontFamily: 'Ubuntu',
                              fontWeight: FontWeight.bold,
                              //color: Colors.black,
                              textBaseline: TextBaseline.alphabetic,
                              shadows: [
                                Shadow(
                                  blurRadius: 2,
                                  color: Colors.black,
                                  offset: Offset(1.0, 1.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                SignInButton(
                  Buttons.Google,
                  text: "Sign up with Google",
                  onPressed: () async {
                    try {
                      await googleSignin.signIn();

                      userId = googleSignin.currentUser!.id;

                      bool isLoggedIn = await loginRequest();

                      if (isLoggedIn != true) {
                        // ignore: use_build_context_synchronously
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddUserScreen()),
                        );
                      } else {
                        if (loginStatus!['recently_matched'].toString() !=
                            "[]") {
                          // ignore: use_build_context_synchronously
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Match',
                                    textAlign: TextAlign.center),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                content: const Text(
                                    'You have gotten a match while you were offline',
                                    textAlign: TextAlign.center),
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
                        // ignore: use_build_context_synchronously
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Swiping()),
                        );
                      }
                    } on PlatformException catch (p) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Error',
                                textAlign: TextAlign.center),
                            content: const Text(
                                'Error connecting to google signin servers, please try again later',
                                textAlign: TextAlign.center),
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
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Error',
                                textAlign: TextAlign.center),
                            content: const Text(
                                'Error connecting to Flutter server, please try again later',
                                textAlign: TextAlign.center),
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
                    }
                  },
                ),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return PrivacyPolicy();
                      },
                    );
                  },
                  child: const Text('Privacy Policy',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.black,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
