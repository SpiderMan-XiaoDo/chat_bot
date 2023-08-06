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
  var _keyCodeStatus;
  @override
  void initState() {
    _isLoading = false;
    _getOldOpenAIKey();
    super.initState();
  }

  Future<int> isCorrectKey(String value) async {
    final url = Uri.https('api.openai.com', 'v1/models');
    return await http
        .get(url, headers: {'Authorization': ' Bearer $value'}).then((result) {
      _keyCodeStatus = result.statusCode;
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
            width: 300,
            height: 300,
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
              color: Colors.blue,
            ),
          ),
          TextFormField(
            maxLength: 51,
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              errorStyle: TextStyle(
                color: Colors.red, // Màu chữ thông báo lỗi
                fontSize: 16, // Kích thước chữ thông báo lỗi
              ),
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
            ),
            validator: (value) {
              setState(() {
                isCorrectKey(value!);
              });
              if (value == null ||
                  value.isEmpty ||
                  value.trim().length <= 1 ||
                  value.trim().length > 51 ||
                  // ignore: unrelated_type_equality_checks
                  _keyCodeStatus != 200) {
                return 'Wrong key';
              }
              return null;
            },
            onSaved: (value) {
              _enteredOpenAiKey = value!;
            },
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  style: ButtonStyle(
                      minimumSize:
                          MaterialStateProperty.all<Size>(const Size(300, 50))),
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
                      : const Text(
                          'Submit',
                          style: TextStyle(),
                        )),
            ],
          ),
          const SizedBox(
            height: 250,
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
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(172),
                image: DecorationImage(
                    image: Image.asset('assets/image/brycen.jpg').image),
              ),
            ),
            Container(
              width: 500,
              height: 80,
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 76, 97, 115),
                  borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
              child: Center(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                          width: 60,
                          height: 60,
                          padding: const EdgeInsets.fromLTRB(4, 0, 0, 4),
                          margin: const EdgeInsets.only(bottom: 8, right: 4),
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 227, 239, 237),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Center(
                            // const Align(
                            // alignment: AlignmentDirectional.center,
                            child: Text(
                              'Key using',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )),
                    ),
                    Expanded(
                      flex: 5,
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.fromLTRB(4, 0, 0, 4),
                        margin: const EdgeInsets.only(bottom: 8, right: 4),
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 113, 111, 111),
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                            _keyToken(),
                            style: const TextStyle(
                                fontSize: 20,
                                color: Color.fromARGB(255, 101, 246, 214)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                        minimumSize: MaterialStateProperty.all<Size>(
                            const Size(170, 50))),
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
                    style: ButtonStyle(
                        minimumSize: MaterialStateProperty.all<Size>(
                            const Size(170, 50))),
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
              height: 270,
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
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 240, 240),
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
