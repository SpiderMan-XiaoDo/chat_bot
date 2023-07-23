import 'dart:ui';

import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.openAIKey});
  final String openAIKey;
  @override
  State<StatefulWidget> createState() {
    return _ChatScreenState();
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> chatConversation = [];
  final _formKey = GlobalKey<FormState>();
  var _enteredQuestion = '';
  void renderQuestion() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        chatConversation.add({'user': _enteredQuestion});
        print('Length chatConversation: ');
        print(chatConversation.length);
        // print(_enteredQuestion);
      });
      _formKey.currentState!.reset();
    }
  }

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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          chatConversation.length! != 0
              ? Expanded(
                  child: ListView.builder(
                      itemCount: chatConversation.length,
                      itemBuilder: (ctx, index) {
                        final item = chatConversation[index];
                        return Row(
                          // mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Expanded(child: Icon(Icons.person)),
                            Expanded(child: Text(item.values.first)),
                          ],
                        );
                      }),
                )
              : const Text('Hello'),
          //     Row(
          //           children: [
          //             Expanded(
          //               child: Icon(Icons.person),
          //             ),
          //             Expanded(
          //               child: Text('Hello'),
          //             ),
          //             // Text(chatConversation[index]);
          //           ],
          //         ))
          // : const Expanded(child: SizedBox(width: 30, height: 30)),
          Form(
            key: _formKey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
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
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                ElevatedButton(
                    onPressed: renderQuestion, child: const Icon(Icons.input))
              ],
            ),
          )
        ],
        // ),
      ),
    );
  }
}
