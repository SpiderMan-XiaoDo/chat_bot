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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Coversation'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Expanded(
                child: TextField(
                  maxLength: 50,
                  decoration: InputDecoration(
                    label: Text('Enter a message'),
                  ),
                ),
              ),
              SizedBox(
                width: 5,
              ),
              ElevatedButton(onPressed: () {}, child: Icon(Icons.input))
            ],
          )
        ],
      ),
    );
  }
}
