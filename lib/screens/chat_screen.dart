import 'package:chat_bot/screens/tab_screen.dart';
import 'package:chat_bot/widgets/chat_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
// import 'package:langchain_openai/langchain_openai.dart';
// import 'package:langchain/langchain.dart';
// import 'package:langchain_openai/langchain_openai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
// import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen(
      {super.key, required this.openAIKey, required this.oldConversation});
  final String openAIKey;
  final List<dynamic> oldConversation;
  @override
  State<StatefulWidget> createState() {
    return _ChatScreenState();
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final _speechToText = SpeechToText();
  final _flutterTts = FlutterTts();

  // bool _speechEnabled = false;
  String _lastWords = '';
  var chatConversation = [];
  final _formKey = GlobalKey<FormState>();
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  var _enteredQuestion = '';
  var isText = false;
  var isListen = false;
  var isLoading = false;
  var initValueTextField = '';
  var _responsedAnswer = '';
  var title = 'New chat';
  final _focusNode = FocusNode();
  @override
  void initState() {
    try {
      super.initState();
      OpenAI.apiKey = widget.openAIKey;
      if (widget.oldConversation.isNotEmpty) {
        widget.oldConversation.forEach((element) {
          chatConversation.add(element);
        });
      }
      _initSpeech();
    } catch (e) {
      print(e.toString());
    }
  }

  void textToSpeech(String content, String language) async {
    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.setPitch(1.0);

      await _flutterTts.speak(content);
    } catch (error) {
      print(error.toString());
    }
  }

  @override
  void dispose() {
    print('Da goi ham dispose');
    print('ChatConversation:________ ${chatConversation.length}');
    print('widget.oldConversation:______ ${widget.oldConversation.length}');
    if (chatConversation.isNotEmpty &&
        chatConversation.length != widget.oldConversation.length) {
      try {
        _chatController.dispose();
        FirebaseFirestore.instance.collection('chat').add({
          'conversation': chatConversation,
          "createdAt": Timestamp.now(),
          'deletedAt': null,
          'summarize': null,
          'title': title,
        });
      } catch (e) {
        print(e.toString());
      }
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    // _speechEnabled =
    await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    try {
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {});
    } catch (e) {
      // print(e.toString());
    }
  }

//Hello
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _chatController.text = _lastWords;
      isText = true;
      _lastWords = '';
    });
  }

  void renderQuestion() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        chatConversation.add({'Human': _enteredQuestion});
        _formKey.currentState!.reset();
        _chatController.clear();
        isText = false;
        isLoading = true;
        // print(_enteredQuestion);
      });
      try {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {}
      ;
    }
  }

  void getResponseChatClone() async {
    try {
      String history = '';
      chatConversation.forEach((element) {
        history = '$history${element.keys.first}: ${element.values.first}\n';
      });
      String historyOfTile = '';
      if (chatConversation.length >= 5 && title == 'New chat') {
        for (var index = 0; index < 6; index += 2) {
          historyOfTile +=
              '${chatConversation.elementAt(index).keys.first}: ${chatConversation.elementAt(index).values.first}\n';
        }
        var titleRes = await OpenAI.instance.chat.create(
          model: 'gpt-3.5-turbo',
          messages: [
            OpenAIChatCompletionChoiceMessageModel(
              content:
                  'Hãy đặt tiêu đề cho nội dung sau, với điều kiện tiêu đề không dài quá 6 từ: $historyOfTile',
              role: OpenAIChatMessageRole.user,
            ),
          ],
        );
        title = titleRes.choices.first.message.content.toString();
        print('title:___________________: $title');
      }

      print('title:___________________: $title');
      var res = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: '$history\nAi:',
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );
      setState(() {
        _responsedAnswer = res.choices.first.message.content.toString();
        chatConversation.add({'Ai': _responsedAnswer.trim()});
        isLoading = false;
      });
      setState(() {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      setState(() {
        _responsedAnswer = e.toString();
        chatConversation.add({'Ai': _responsedAnswer.trim()});
        isLoading = false;
      });
      setState(() {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });

      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      try {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {}
      ;
    });
    var listView = ListView.builder(
        controller: _scrollController,
        itemCount: chatConversation.length,
        itemBuilder: (ctx, index) {
          final item = chatConversation[index];
          final role = item.keys.first;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              role != 'Human'
                  ? const Expanded(
                      child: Align(
                          alignment: Alignment.topLeft,
                          child: Icon(
                            Icons.android_sharp,
                          )),
                    )
                  : Expanded(
                      flex: 7,
                      child: Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            decoration: BoxDecoration(
                                // border: Border.all()
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20)),
                            margin:
                                const EdgeInsets.only(left: 100, bottom: 10),
                            padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
                            child: Text(
                              item.values.first,
                              textAlign: TextAlign.start,
                              style: const TextStyle(fontSize: 16),
                            ),
                          )),
                    ),
              role != 'Human'
                  ? Expanded(
                      flex: 7,
                      child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            decoration: BoxDecoration(
                                // border: Border.all()
                                color: const Color.fromARGB(255, 73, 72, 72),
                                borderRadius: BorderRadius.circular(20)),
                            margin:
                                const EdgeInsets.only(right: 100, bottom: 10),
                            padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
                            child: Row(children: [
                              Expanded(
                                child: Text(
                                  item.values.first,
                                  textAlign: TextAlign.start,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              IconButton(
                                  key: ValueKey(index),
                                  onPressed: () {
                                    textToSpeech(item.values.first, 'vi-VN');
                                  },
                                  icon: const Icon(Icons.volume_up_rounded)),
                            ]),
                          )))
                  : const Expanded(
                      child: Align(
                          alignment: Alignment.topRight,
                          child: Icon(Icons.person_2_rounded))),
            ],
          );
        });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Coversation'),
        actions: [
          ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        const TabScreen(selectedIndex: 1, chatHistory: [])));
              },
              child: const Text('New Chat')),
        ],
      ),
      drawer: MainDrawer(),
      body:
          //  SingleChildScrollView(
          //   child:
          Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          chatConversation.isNotEmpty
              ? Expanded(
                  child: listView,
                )
              : Container(),
          Form(
            key: _formKey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    focusNode: _focusNode,
                    controller: _chatController,
                    maxLength: 500,
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
                    onTap: () {
                      try {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      } catch (e) {}
                      ;
                    },
                    onChanged: (value) {
                      try {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      } catch (e) {}
                      ;
                      if (value != '') {
                        setState(() {
                          isText = true;
                        });
                      } else {
                        setState(() {
                          isText = false;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                isLoading
                    ? const CircularProgressIndicator()
                    : isText
                        ? ElevatedButton(
                            onPressed: () {
                              renderQuestion();
                              _focusNode.unfocus();
                              // getRequestFunction();
                              if (_enteredQuestion.isNotEmpty) {
                                getResponseChatClone();
                              }
                              // renderAnswer();
                            },
                            child: const Icon(Icons.input))
                        : ElevatedButton(
                            onPressed: _speechToText.isNotListening
                                ? _startListening
                                : _stopListening,
                            child: Icon(_speechToText.isNotListening
                                ? Icons.mic_off
                                : Icons.mic)),
              ],
            ),
          )
        ],
        // ),
      ),
    );
  }
}
