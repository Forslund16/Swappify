import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class PrivacyPolicy extends StatelessWidget {
  final audioPlayer = AudioPlayer(); //AudioPlayer();
  Future<void> _playSound() async {
    AudioCache cache = AudioCache();
    // Play audio file
    cache.play('sounds/spark2.mp3');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Privacy Policy',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'We take your privacy seriously and want to be transparent about how we collect, use, and share your information. This privacy policy explains our practices and applies to all users of our application.\n',
            style: TextStyle(fontSize: 16),
          ),
          const Text(
            'Information we collect',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            '- Information you provide: We may collect information that you provide when you create an account, such as your name, email address, and location.\n\n'
            '- User-generated content: We may collect the content you create and share on our application, such as photos and descriptions of the clothes you post for swapping.\n\n'
            '- Login information: If you choose to log in with Google, we will collect your Google account information, including your email address and profile picture.\n',
            style: TextStyle(fontSize: 14),
          ),
          const Text(
            'How we use your information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            '- To provide our services: We use your information to facilitate the swapping of used clothes between users on our application.\n\n'
            '- To communicate with you: We may use your email address to communicate with you about your account, our services, and other updates.\n\n'
            '- To improve our services: We may use your information to understand how users are using our application and to make improvements to our services.\n',
            style: TextStyle(fontSize: 14),
          ),
          const Text(
            'How we share your information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            '- With other users: We may share the information you provide and user-generated content with other users on our application as necessary to facilitate the swapping of used clothes.\n\n'
            '- With service providers: We may share your information with third-party service providers who perform services on our behalf, such as hosting our application and providing customer support.\n\n'
            '- As required by law: We may share your information as required by law, such as in response to a subpoena or other legal process.\n',
            style: TextStyle(fontSize: 14),
          ),
          const Text(
            'Data retention',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            'We will retain your information for as long as necessary to provide our services to you and as otherwise necessary to comply with our legal obligations, resolve disputes, and enforce our agreements.\n',
            style: TextStyle(fontSize: 14),
          ),
          const Text(
            'Your choices',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            'You can control your account settings and the information you share on our application through your account settings. You may also choose to delete your account and the information associated with it at any time.\n',
            style: TextStyle(fontSize: 14),
          ),
          const Text(
            'Security',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            'We take appropriate measures to protect your information from unauthorized access, use, disclosure, or destruction. However, no security measures are perfect or impenetrable, and we cannot guarantee the security of your information. \n',
            style: TextStyle(fontSize: 14),
          ),
          const Text(
            'Updates to this Privacy Policy',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            'We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on our application.\n',
            style: TextStyle(fontSize: 14),
          ),
          const Text(
            'Contact us',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            'If you have any questions or concerns about this privacy policy or our practices, you can find us in the DSP room.\n',
            style: TextStyle(fontSize: 14),
          ),
          ElevatedButton(
            onPressed: _playSound,
            child: const Text('Play Sound'),
          ),
        ],
      )),
      actions: [
        TextButton(
          onPressed: () {
            audioPlayer.stop();
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
