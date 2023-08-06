import 'dart:convert';
import 'package:chat_bot/screens/chat_screen.dart';
import 'package:chat_bot/screens/new_home_screen.dart';
import 'package:chat_bot/screens/returned_home_screen.dart';
import 'package:chat_bot/screens/summariz_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TabScreen extends StatefulWidget {
  const TabScreen({super.key, required this.selectedIndex});
  final selectedIndex;
  @override
  State<StatefulWidget> createState() {
    return _TabScreenState();
  }
}

class _TabScreenState extends State<TabScreen> {
  Widget activePage = NewHomeScreen();
  var currentIndex = -1;
  var _initOpenAIKey = '';
  void _getOldOpenAIKey() async {
    final url = Uri.https(
        'chat-bot-api-ffdeb-default-rtdb.asia-southeast1.firebasedatabase.app',
        'openai-key.json');
    try {
      final response = await http.get(url);
      final Map<String, dynamic> listData = json.decode(response.body);
      for (final itemData in listData.entries) {
        setState(() {
          _initOpenAIKey = itemData.value['OpenAIkey'];
          print('_InitIDKey: _________ $_initOpenAIKey');
        });
      }
    } catch (e) {}
  }

  @override
  void initState() {
    _getOldOpenAIKey();
    super.initState();
  }

  Widget build(BuildContext context) {
    if (currentIndex == -1) {
      activePage = _initOpenAIKey == ''
          ? NewHomeScreen()
          : widget.selectedIndex == 0
              ? ReturnedHomeScreen(openAIKey: _initOpenAIKey)
              : widget.selectedIndex == 1
                  ? ChatScreen(openAIKey: _initOpenAIKey)
                  : SummarizeScreen(openAiKey: _initOpenAIKey);
    } else {
      activePage = currentIndex == 0
          ? _initOpenAIKey == ''
              ? NewHomeScreen()
              : ReturnedHomeScreen(openAIKey: _initOpenAIKey)
          : currentIndex == 1
              ? ChatScreen(openAIKey: _initOpenAIKey)
              : SummarizeScreen(openAiKey: _initOpenAIKey);
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 160, 210, 255),
        elevation: 0.0,
        title: Container(
          margin: EdgeInsets.zero,
          child: Row(
            children: [
              Expanded(
                child: Image.asset(
                  'assets/image/logo.png',
                  width: 190,
                  height: 60,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              const Expanded(
                child: Text(
                  'Chat GPT',
                  style: TextStyle(
                    fontSize: 32,
                    color: Color.fromARGB(255, 39, 126, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
          onTap: (value) {
            if (_initOpenAIKey == '') {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Invald input'),
                  content: const Text(
                      'Please make sure a valid tile, amount, date and category was entered!'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      child: const Text('Okay'),
                    )
                  ],
                ),
              );
            } else {
              setState(() {
                currentIndex = value;
              });
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.house_outlined), label: 'Home Page'),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline), label: 'Try Chat'),
            BottomNavigationBarItem(
                icon: Icon(Icons.summarize_sharp), label: 'Try Summarize'),
          ]),
    );
  }
}
