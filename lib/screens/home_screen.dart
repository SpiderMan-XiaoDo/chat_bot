import 'dart:convert';

import 'package:chat_bot/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  // final _openAiKeyController = TextEditingController();
  var _formKey = GlobalKey<FormState>();
  var _selectedIndex = 0;
  var _enteredOpenAiKey = '';
  var _isLoading;
  var _initOpenAIKey = '';
  var _initIDKey = '';
  var _isNewKey = false;
  @override
  void initState() {
    _isLoading = false;
    _getOldOpenAIKey();
    super.initState();
  }

  Future<int> isCorrectKey(String value) async {
    final url = Uri.https('api.openai.com', 'v1/models');
    // try {
    //   final response = await http.get(url, headers: {
    //     'Authorization':
    //         ' Bearer $_enteredOpenAiKey'
    //   });
    // } catch (e) {
    //   // print(e.toString());
    // }
    return await http
        .get(url, headers: {'Authorization': ' Bearer $value'}).then((result) {
      print('StatusCode: ______________________ ${result.statusCode}');
      return result.statusCode;
    }).catchError((error) => 0);
  }

  void _selectedPage(int index) {
    if (index == 1 && _initOpenAIKey == '' && _enteredOpenAiKey == '') {
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
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _getOldOpenAIKey() async {
    final url = Uri.https(
        'chat-bot-api-ffdeb-default-rtdb.asia-southeast1.firebasedatabase.app',
        'openai-key.json');
    try {
      final response = await http.get(url);
      final Map<String, dynamic> listData = json.decode(response.body);
      for (final itemData in listData.entries) {
        setState(() {
          _initIDKey = itemData.key;
          _initOpenAIKey = itemData.value['OpenAIkey'];
          print('_InitIDKey: _________ $_initOpenAIKey');
        });
      }
      // _openAiKeyController.text = _initOpenAIKey;
    } catch (e) {}
  }

  void _deleteOpenAIKey() async {
    final url = Uri.https(
        'chat-bot-api-ffdeb-default-rtdb.asia-southeast1.firebasedatabase.app',
        'openai-key.json');
    print(url);
    try {
      final response = await http.delete(url);
      print(response.statusCode);
    } catch (e) {}
  }

  void _addOpenAIKey() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final url = Uri.https(
          'chat-bot-api-ffdeb-default-rtdb.asia-southeast1.firebasedatabase.app',
          'openai-key.json');
      final response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'OpenAIkey': _enteredOpenAiKey,
          }));
      // _getOldOpenAIKey();
      setState(() {
        // _isLoading = true;
        _isNewKey = false;
      });
    }
  }

  void _newChatScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => ChatScreen(openAIKey: _enteredOpenAiKey)));
  }

  String _keyToken() {
    var usedKey = _initOpenAIKey != '' ? _initOpenAIKey : _enteredOpenAiKey;

    var key = usedKey.substring(0, 3) +
        '***********' +
        usedKey.substring(usedKey.length - 4, usedKey.length);
    return key;
  }

  @override
  Widget build(BuildContext context) {
    Widget isReturn = Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 427,
            height: 419,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(172),
              image: DecorationImage(
                  image: Image.asset('assets/image/brycen.jpg').image),
            ),
            // child: Image.asset(
            //   'assets/image/brycen.jpg',
            // ),
          ),
          const Text(
            'Enter your OpenAi Key: ',
            style: TextStyle(
              fontSize: 30,
            ),
          ),
          TextFormField(
            maxLength: 51,
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            style: const TextStyle(
              fontSize: 24,
            ),
            validator: (value) {
              if (value == null ||
                  value.isEmpty ||
                  value.trim().length <= 1 ||
                  value.trim().length > 51 ||
                  // ignore: unrelated_type_equality_checks
                  isCorrectKey(value).then((result) => result) == 200) {
                return 'Wrong key';
              }
              return null;
            },
            onSaved: (value) {
              _enteredOpenAiKey = value!;
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                  onPressed: () {
                    print('IsCorrectKey:___________');
                    _addOpenAIKey();
                    if (_formKey.currentState!.validate()) {
                      _newChatScreen(context);
                    }
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  child: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Submit')),
            ],
          ),
          const SizedBox(
            height: 140,
          )
        ],
      ),
    );
    if (_initOpenAIKey != '' && _isNewKey == false ||
        (_selectedIndex == 0 && _enteredOpenAiKey != '')) {
      isReturn = Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 427,
              height: 419,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(172),
                image: DecorationImage(
                    image: Image.asset('assets/image/brycen.jpg').image),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(40, 15, 40, 15),
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 227, 239, 237),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text(
                'Key using',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 113, 111, 111),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                _keyToken(),
                style: const TextStyle(
                    fontSize: 24, color: Color.fromARGB(255, 101, 246, 214)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                    onPressed: () {
                      _deleteOpenAIKey();
                      setState(() {
                        _initOpenAIKey = '';
                        _enteredOpenAiKey = '';
                        _isNewKey = true;
                      });
                    },
                    child: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('New Key')),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    child: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Use this Key')),
              ],
            ),
            const SizedBox(
              height: 140,
            )
          ],
        ),
      );
    }
    Widget activePage = SingleChildScrollView(
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 4, 149, 79),
              Colors.deepOrange,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )),
          child: isReturn),
    );

    if (_selectedIndex == 1) {
      if (_initOpenAIKey != '' || _enteredOpenAiKey != '') {
        final activeKey =
            _initOpenAIKey != '' ? _initOpenAIKey : _enteredOpenAiKey;
        activePage = ChatScreen(
          openAIKey: activeKey,
        );
        _isLoading = false;
      }
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 160, 210, 255),
        elevation: 0.0,
        title: Container(
          margin: EdgeInsets.zero,
          child: Row(
            children: [
              Image.asset(
                'assets/image/logo.png',
                width: 190,
                height: 60,
              ),
              const SizedBox(
                width: 8,
              ),
              const Text(
                'Chat GPT',
                style: TextStyle(
                  fontSize: 32,
                  color: Color.fromARGB(255, 39, 126, 48),
                ),
              ),
            ],
          ),
        ),
      ),
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
          onTap: (value) {
            _selectedPage(value);
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.house_outlined), label: 'Home Page'),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline), label: 'Try Chat'),
          ]),
    );
  }
}
