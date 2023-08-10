import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SummarizeScreen extends StatefulWidget {
  const SummarizeScreen({super.key, required this.openAiKey});
  final String openAiKey;
  @override
  State<StatefulWidget> createState() {
    return _SummarizeScreenState();
  }
}

class _SummarizeScreenState extends State<SummarizeScreen> {
  final _speechToText = SpeechToText();
  final _flutterTts = FlutterTts();

  // bool _speechEnabled = false;
  String _lastWords = '';
  final List<Map<String, String>> chatConversation = [];
  final _formKey = GlobalKey<FormState>();
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  var _enteredQuestion = '';
  var isText = false;
  var isListen = false;
  var isLoading = false;
  var initValueTextField = '';
  var _responsedAnswer = '';
  final _focusNode = FocusNode();
  var fileName = '';
  var filePath = '';
  var fileType = '';
  var isSelected = false;
  var textSummarize = '';
  var isLoadedFile = false;
  dynamic textsWithSources = [];
  dynamic embeddings;
  dynamic docSearch;
  @override
  void initState() {
    try {
      super.initState();
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

  void filePicker() async {
    FilePicker.platform.clearTemporaryFiles();
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        filePath = file.path;
        fileName = file.path.substring(file.path.lastIndexOf('/') + 1);
        fileType = file.path.substring(file.path.lastIndexOf('.') + 1);
        isSelected = true;
      });
    }
    try {} catch (e) {
      print(e.toString());
    }
  }

  void loaderFile() async {
    try {
      if (filePath.isNotEmpty && isLoadedFile == false) {
        var loader = TextLoader(filePath);
        loader.load().then((value) {
          const textSplitter = CharacterTextSplitter(
            chunkSize: 100,
            chunkOverlap: 0,
          );
          final docChunks = textSplitter.splitDocuments(value);
          textsWithSources = docChunks.map(
            (e) {
              return e.copyWith(
                metadata: {
                  ...e.metadata,
                  'source': '${docChunks.indexOf(e)}-pl'
                },
              );
            },
          ).toList();
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void loadFilePdf() async {}

  void getChatResponse() async {
    try {
      embeddings = OpenAIEmbeddings(apiKey: widget.openAiKey);
      var docSearch = await MemoryVectorStore.fromDocuments(
              documents: textsWithSources, embeddings: embeddings)
          .then((value) {
        print('docSearch:_________________ ${value.memoryVectors.first}');
        return value;
      }).catchError((err) {
        setState(() {
          _responsedAnswer = err.toString();
          chatConversation.add({'Ai': _responsedAnswer.trim()});
          isLoading = false;
        });
        return MemoryVectorStore(embeddings: embeddings);
      });

      final llm = ChatOpenAI(
          apiKey: widget.openAiKey,
          model: 'gpt-3.5-turbo-0613',
          temperature: 0.5);
      final qaChain = OpenAIQAWithSourcesChain(llm: llm);
      final docPrompt = PromptTemplate.fromTemplate(
        '''Hãy sử dụng nội dung của tôi đã cung cấp trong file text để trả lời các câu hỏi bằng tiếng Việt.\nLưu ý: Nếu không tìm thấy câu trả lời trong nội dung đã cung cấp, hãy thông báo "Thông tin không có trong tài liệu đã cung cung cấp ".
        Nếu câu hỏi là các câu tương tự như: 'Xin chào', 'Hello'... hãy phản hồi: 'Xin chào, hãy đặt các câu hỏi liên quan đến tài liệu đã cung cấp.'.
        .\ncontent: {page_content}\nSource: {source}
        ''',
      );
      final finalQAChain = StuffDocumentsChain(
        llmChain: qaChain,
        documentPrompt: docPrompt,
      );
      print('Hello_retrievalQA_1');

      final retrievalQA = RetrievalQAChain(
        retriever: docSearch.asRetriever(),
        combineDocumentsChain: finalQAChain,
      );

      final res = await retrievalQA(_enteredQuestion);
      if (res['statusCode'] == 429) {
        _responsedAnswer =
            'Bạn đã gửi quá nhiều yêu cầu(Tối Tối đa 3 yêu cầu/phút), hãy thử lại sau 20s.';
        chatConversation.add({'Ai': _responsedAnswer.trim()});
        isLoading = false;
      } else {
        setState(() {
          print(res.toString());
          _responsedAnswer = res['result'].toString();
          chatConversation.add({'Ai': _responsedAnswer.trim()});
          isLoading = false;
        });
      }
      // print('Hello_retrievalQA_2');
      // retrievalQA(_enteredQuestion).then((value) {
      //   print('Hello_________');

      //   setState(() {
      //     print('Hello_________');
      //     if (value.isEmpty || value == null) {
      //       _responsedAnswer =
      //           'Xin chào, hãy đặt các câu hỏi liên quan đến tài liệu đã cung cấp.';
      //       chatConversation.add({'Ai': _responsedAnswer.trim()});
      //       isLoading = false;
      //     } else if (value['result'] != Null) {
      //       _responsedAnswer = value['result'].toString();
      //       chatConversation.add({'Ai': _responsedAnswer.trim()});
      //       isLoading = false;
      //     } else {
      //       _responsedAnswer =
      //           'Xin chào, hãy đặt các câu hỏi liên quan đến tài liệu đã cung cấp.';
      //       chatConversation.add({'Ai': _responsedAnswer.trim()});
      //       isLoading = false;
      //     }
      //   });
      //   return value;
      // }).catchError((error) {
      //   setState(() {
      //     print('Hello');
      //     _responsedAnswer = error.toString();
      //     chatConversation.add({'Ai': _responsedAnswer.trim()});
      //     isLoading = false;
      //   });
      //   return error;
      // });
    } catch (err) {
      {
        if (err.toString().contains('statusCode: 429')) {
          setState(() {
            _responsedAnswer =
                'Tài khoản của bạn bị giới hạn 3 req/min, hãy nâng cấp hoặc thử lại sau 20s.';
            chatConversation.add({'Ai': _responsedAnswer.trim()});
            isLoading = false;
          });
        } else {
          setState(() {
            _responsedAnswer =
                'Xin chào, hãy đặt các câu hỏi liên quan đến tài liệu đã cung cấp. ${err.toString()}';
            chatConversation.add({'Ai': _responsedAnswer.trim()});
            isLoading = false;
          });
        }
      }
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
    if (isSelected == true) {
      loaderFile();
      // loadFilePdf();
    }
    Widget fileSelect = !isSelected
        ? const Align(
            child: Text('Select File'),
          )
        : const Align();

    Widget selectedFile = !isSelected
        ? Align(
            alignment: Alignment.topCenter,
            child: IconButton(
                onPressed: filePicker,
                icon: const Icon(
                  Icons.drive_folder_upload,
                  size: 40,
                )),
          )
        : fileType == 'pdf'
            ? const Icon(
                Icons.picture_as_pdf,
                size: 40,
              )
            : fileType == 'txt'
                ? Image.network(
                    'https://cdn-icons-png.flaticon.com/512/3979/3979306.png',
                    width: 46,
                    height: 46,
                  )
                : fileType == 'docx'
                    ? Image.network(
                        'https://cdn-icons-png.flaticon.com/512/4725/4725970.png',
                        width: 46,
                        height: 46,
                      )
                    : const Align();
    Widget selectedFileName = isSelected
        ? Align(
            child: Text(fileName),
          )
        : const Align();
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
        title: const Text('Summarize data'),
      ),
      body:
          //  Container(
          //   child: Column(
          //     children: [fileSelect, selectedFile, selectedFileName],
          //   ),
          // )
          Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Align(
              alignment: Alignment.topCenter,
              child: Column(children: [
                fileSelect,
                selectedFile,
                selectedFileName,
              ])),
          // Text(textSummarize),
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
                                getChatResponse();
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
