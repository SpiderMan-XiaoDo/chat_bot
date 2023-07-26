import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dart_openai/dart_openai.dart';

class ChatResponeScreen extends StatefulWidget {
  const ChatResponeScreen({super.key, required this.openAIKey});
  final String openAIKey;
  @override
  State<StatefulWidget> createState() {
    return _ChatResponeScreenState();
  }
}

class _ChatResponeScreenState extends State<ChatResponeScreen> {
  final _chatController = TextEditingController();
  // bool _speechEnabled = false;
  final List<Map<String, String>> chatConversation = [];
  final _formKey = GlobalKey<FormState>();
  var _enteredQuestion = '';
  var initValueTextField = '';
  var _responsedAnswer = '';
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void renderQuestion() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        chatConversation.add({'user': _enteredQuestion});
        // print('Length chatConversation: ');
        // print(chatConversation.length);
        _formKey.currentState!.reset();
        _chatController.clear();
        // print(_enteredQuestion);
      });
    }
  }

  // void getRequestFunction() async {
  //   final url = Uri.https('api.openai.com', 'v1/models');
  //   print('URL:__________ $url');
  //   try {
  //     final response = await http.get(url, headers: {
  //       'Authorization':
  //           ' Bearer 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'
  //     });
  //     print('Status code: ${response.statusCode}');
  //   } catch (e) {
  //     // print(e.toString());
  //   }
  // }

  void getResponseChatClone() async {
    // OpenAI.apiKey = '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';
    try {
      await OpenAI.instance.completion
          .create(
        model: 'text-davinci-003',
        prompt: _enteredQuestion,
        maxTokens: 500,
        temperature: 1,
      )
          .then((value) {
        setState(() {
          _responsedAnswer = value.choices[0].text;
          chatConversation.add({'asistant': _responsedAnswer.trim()});
        });
        return value;
      }).catchError((error) {
        print('EROOR: ________');
        print(error.toString());
      });
      // return completion.choices[0].text;
    } catch (e) {
      print(e.toString());
    }
  }

  // void renderAnswer() {
  //   setState(() {
  //     chatConversation.add({'user': _responsedAnswer});
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Coversation'),
      ),
      body:
          //  SingleChildScrollView(
          //   child:
          Column(
        // crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          chatConversation.isNotEmpty
              ? Expanded(
                  child: ListView.builder(
                      itemCount: chatConversation.length,
                      itemBuilder: (ctx, index) {
                        final item = chatConversation[index];
                        final role = item.keys.first;
                        return Row(
                          children: [
                            role == 'user'
                                ? const Expanded(child: Icon(Icons.person))
                                : Expanded(
                                    flex: 7,
                                    child: Container(
                                      padding: EdgeInsets.only(left: 80),
                                      child: Text(
                                        item.values.first,
                                        textAlign: TextAlign.justify,
                                      ),
                                    )),
                            role == 'user'
                                ? Expanded(
                                    flex: 7, child: Text(item.values.first))
                                : const Expanded(
                                    child: Icon(Icons.blur_circular_sharp))
                          ],
                        );
                      }),
                )
              : Container(),
          Form(
            key: _formKey,
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _chatController,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      label: Text('Enter a message'),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          value.trim().length <= 1) {
                        return 'A Short message!';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _enteredQuestion = value!;
                    },
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                ElevatedButton(
                    onPressed: () {
                      renderQuestion();
                      // getRequestFunction();
                      if (_enteredQuestion.isNotEmpty) {
                        getResponseChatClone();
                      }
                      // renderAnswer();
                    },
                    child: const Icon(Icons.input))
              ],
            ),
          )
        ],
        // ),
      ),
    );
  }
}
