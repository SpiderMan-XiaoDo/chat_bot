import 'dart:convert';

import 'package:chat_bot/screens/tab_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewHomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _StateNewHomeScreen();
  }
}

class _StateNewHomeScreen extends State<NewHomeScreen> {
  var formKey = GlobalKey<FormState>();
  var enteredOpenAiKey = '';
  var keyCodeStatus;

  Future<int> isCorrectKey(String value) async {
    final url = Uri.https('api.openai.com', 'v1/models');
    return await http
        .get(url, headers: {'Authorization': ' Bearer $value'}).then((result) {
      keyCodeStatus = result.statusCode;
      print('StatusCode: ______________________ ${result.statusCode}');
      return result.statusCode;
    }).catchError((error) => 0);
  }

  void _addOpenAIKey() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      final url_ = Uri.https('api.openai.com', 'v1/models');
      http.get(url_, headers: {
        'Authorization': ' Bearer $enteredOpenAiKey'
      }).then((value) {
        if (value.statusCode == 200) {
          final url = Uri.https(
              'chat-bot-api-ffdeb-default-rtdb.asia-southeast1.firebasedatabase.app',
              'openai-key.json');
          http.post(url,
              headers: {
                'Content-Type': 'application/json',
              },
              body: json.encode({
                'OpenAIkey': enteredOpenAiKey,
              }));
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                const TabScreen(selectedIndex: 1, chatHistory: []),
          ));
        } else {
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
      });
    }

    //   final url = Uri.https(
    //       'chat-bot-api-ffdeb-default-rtdb.asia-southeast1.firebasedatabase.app',
    //       'openai-key.json');
    //   await http
    //       .post(url,
    //           headers: {
    //             'Content-Type': 'application/json',
    //           },
    //           body: json.encode({
    //             'OpenAIkey': enteredOpenAiKey,
    //           }))
    //       .then((value) {
    //     print('Value:___________________________ $value');
    //     return value;
    //   }).catchError((err) {
    //     print(err.toString());
    //   });
    //   // _getOldOpenAIKey();
    // }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Form(
              key: formKey,
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
                      // setState(() {
                      //   isCorrectKey(value!);
                      // });

                      if (value == null ||
                              value.isEmpty ||
                              value.trim().length <= 1 ||
                              value.trim().length > 51
                          // ignore: unrelated_type_equality_checks
                          ) {
                        return 'Wrong key';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      enteredOpenAiKey = value!;
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
                              minimumSize: MaterialStateProperty.all<Size>(
                                  const Size(300, 50))),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              _addOpenAIKey();
                            } else {
                              formKey.currentState!.reset();
                            }
                          },
                          child: const Text(
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
            )));
    return Scaffold(
      body: activePage,
    );
  }
}
