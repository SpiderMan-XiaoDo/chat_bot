import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:dart_openai/dart_openai.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.openAIKey});
  final String openAIKey;
  @override
  State<StatefulWidget> createState() {
    return _ChatScreenState();
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final _speechToText = SpeechToText();
  final _chatController = TextEditingController();
  // bool _speechEnabled = false;
  String _lastWords = '';
  final List<Map<String, String>> chatConversation = [];
  final _formKey = GlobalKey<FormState>();
  var _enteredQuestion = '';
  var isText = false;
  var isListen = false;
  var isLoading = false;
  var initValueTextField = '';
  var _responsedAnswer = '';
  @override
  void initState() {
    super.initState();
    OpenAI.apiKey = widget.openAIKey;
    _initSpeech();
  }

  @override
  void dispose() {
    _chatController.dispose();
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
        chatConversation.add({'user': _enteredQuestion});
        // print('Length chatConversation: ');
        // print(chatConversation.length);
        _formKey.currentState!.reset();
        _chatController.clear();
        isText = false;
        isLoading = true;
        // print(_enteredQuestion);
      });
    }
  }

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
          isLoading = false;
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
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          chatConversation.isNotEmpty
              ? Expanded(
                  child: ListView.builder(
                      itemCount: chatConversation.length,
                      itemBuilder: (ctx, index) {
                        final item = chatConversation[index];
                        final role = item.keys.first;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    child: Icon(Icons.android_rounded))
                          ],
                        );
                      }),
                )
              : Container(),
          Form(
            key: _formKey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                    onChanged: (value) {
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
                  width: 5,
                ),
                isLoading
                    ? const CircularProgressIndicator()
                    : isText
                        ? ElevatedButton(
                            onPressed: () {
                              renderQuestion();
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
