import 'package:flutter/material.dart';
import 'package:test_1/swiping.dart';

class HelpScreen extends StatefulWidget {
  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<bool> _isExpandedList = List.filled(7, false);

  final List<String> _sectionContents = [
    'To start using Swappify, you\'ll need to publish an article showcasing the clothing item(s) you\'d like to exchange. To create an article:\n\n'
        'Click the "+" icon on the main screen.\n'
        'Add multiple pictures of the clothing item.\n'
        'Include a detailed description.\n'
        'Select the gender (man, woman, or unisex) and size.\n'
        'Add relevant tags for easy discovery by other users.\n'
        'Click "Publish" to make your article visible to other Swappify users.',
    'Browse and like articles by swiping left or right, similar to the Tinder app:\n\n'
        'Swipe right to like an article.\n'
        'Swipe left to dislike an article and move on to the next one.',
    'If both you and another user like each other\'s articles, you\'ll get a match. View your matches by:\n\n'
        'Clicking the "Chat" icon at the bottom of the screen.\n'
        'This will open the "Matches" window, where you can see all your successful matches.',
    'To initiate a chat and eventually trade clothing items:\n\n'
        'Click on a user in the "Matches" window.\n'
        'Start a conversation to discuss the details of the trade.\n'
        'Finalize the exchange by mutually agreeing on the terms of the swap.',
    'Click on the "Filter" icon on the main screen (it looks like a funnel).\n'
        'A filter menu will appear, allowing you to customize the articles you see based on preferences such as gender, size, and tags.',
    'Click on the "Profile" tab.\n'
        'Edit your phone number and save your changes.',
    'Go to your profile page.\n'
        'Click on the article you wish to modify or delete.\n'
        'To modify, edit the relevant fields (pictures, description, gender, size, tags) and save your changes.\n'
        'To remove the article, click on the "Delete" button and confirm.',
  ];

  Widget _buildSectionTitle(String title, int index) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Text(
            _sectionContents[index],
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
      ],
      onExpansionChanged: (bool isExpanded) {
        setState(() {
          _isExpandedList[index] = isExpanded;
        });
      },
      initiallyExpanded: _isExpandedList[index],
      key: GlobalKey(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: globalBackground,
      appBar: AppBar(
        title: Text('Swappify Help'),
        toolbarHeight: 40,
        backgroundColor: globalAppbarColor,
      ),
      body: SingleChildScrollView(

      padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSectionTitle('1. Publishing Articles', 0),
            _buildSectionTitle('2. Browsing and Liking Articles', 1),
            _buildSectionTitle('3. Matches', 2),
            _buildSectionTitle('4. Chatting and Trading', 3),
            _buildSectionTitle('5. Filtering Articles', 4),
            _buildSectionTitle('6. Modifying Your Profile', 5),
            _buildSectionTitle(
                '7. Modifying and Removing Published Articles', 6),
          ],
        ),
      ),
    );
  }
}
