import 'dart:io';

import 'package:chat_bot/screens/tab_screen.dart';
import 'package:chat_bot/widgets/summarize_drawer.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SummarizeScreen extends StatefulWidget {
  const SummarizeScreen(
      {super.key,
      required this.openAiKey,
      required this.chatSummarizeConversation,
      required this.oldFilePath,
      required this.oldFileContent});
  final String openAiKey;
  final List<dynamic> chatSummarizeConversation;
  final String oldFilePath;
  final String oldFileContent;
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
  final List<dynamic> chatConversation = [];
  final _formKey = GlobalKey<FormState>();
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  var enteredQuestion = '';
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
  var isLoadedSummarize = false;
  dynamic llm;
  List<Document> textsWithSources = [];
  dynamic embeddings;
  late MemoryVectorStore docSearch;
  late OpenAIQAWithSourcesChain qaChain;
  late StuffDocumentsChain finalQAChain;
  late RetrievalQAChain retrievalQA;
  String fileContent = '';

  @override
  void initState() {
    try {
      super.initState();
      if (widget.oldFilePath.isNotEmpty) {
        filePath = widget.oldFilePath;
        fileName = filePath.substring(filePath.lastIndexOf('/') + 1);
        fileType = filePath.substring(filePath.lastIndexOf('.') + 1);
        fileContent = widget.oldFileContent;
        widget.chatSummarizeConversation.forEach((element) {
          chatConversation.add(element);
        });
        isSelected = true;
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
        chatConversation.add({'Human': enteredQuestion});
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
        file.readAsString().then((value) {
          fileContent = value;
          print('FileContent: $fileContent');
          return value;
        });
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
          print('Value Length:__________ ${value.length}');
          const textSplitter = CharacterTextSplitter(
            chunkSize: 100,
            chunkOverlap: 0,
          );
          var fileToDoc = Document(pageContent: fileContent);
          // final docChunks = textSplitter.splitDocuments(value);
          final docChunks = textSplitter.splitDocuments([fileToDoc]);
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
          llm = ChatOpenAI(
              apiKey: widget.openAiKey,
              model: 'gpt-3.5-turbo-0613',
              temperature: 0.5);
          isLoadedFile = true;
          embeddings = OpenAIEmbeddings(apiKey: widget.openAiKey);
          MemoryVectorStore.fromDocuments(
                  documents: textsWithSources, embeddings: embeddings)
              .then((value) {
            print('docSearch:_________________ ${value.memoryVectors.first}');
            docSearch = value;
            qaChain = OpenAIQAWithSourcesChain(llm: llm);
            final docPrompt = PromptTemplate.fromTemplate(
              '''Hãy sử dụng nội dung của tôi đã cung cấp trong file text để trả lời các câu hỏi bằng tiếng Việt.\nLưu ý: Nếu không tìm thấy câu trả lời trong nội dung đã cung cấp, hãy thông báo "Thông tin không có trong tài liệu đã cung cung cấp ".
        Nếu câu hỏi là các câu tương tự như: 'Xin chào', 'Hello'... hãy phản hồi: 'Xin chào, hãy đặt các câu hỏi liên quan đến tài liệu đã cung cấp.'.
        .\ncontent: {page_content}\nSource: {source}
        ''',
            );
            // final
            finalQAChain = StuffDocumentsChain(
              llmChain: qaChain,
              documentPrompt: docPrompt,
            );
            // final
            retrievalQA = RetrievalQAChain(
              retriever: docSearch.asRetriever(),
              combineDocumentsChain: finalQAChain,
            );
            print('Cong doan tom tat');
            retrievalQA(
                    '''Hãy lựa chọn một số câu hỏi sau để tóm tắt văn bản :\n Ai là nhân vật chính.\n Sự kiện chính trong văn bản.
            \n Người viết ra văn bản đó là ai.\nBối cảnh văn bản đề cập đến...để có thể tóm tắt nó.
            Cố gắng trả lời nhiều câu hỏi nhất có có thể.
            ''')
                // retrievalQA('''Ai là nhân vật chính trong nội dung trên?
                // ''')
                .then((value) {
              print('Cong doan tom tat 2');
              if (value['statusCode'] == 429) {
                setState(() {
                  textSummarize =
                      'Lỗi tóm tắt file, hãy thử lại  status code = 409';
                });
              } else {
                setState(() {
                  print('value:________________ $value');
                  textSummarize = value['result'].toString();
                  isLoadedSummarize = true;
                });
              }
            });
            return value;
          }).catchError((err) {
            setState(() {
              chatConversation.add({'Ai': _responsedAnswer.trim()});
              isLoading = false;
              isLoadedSummarize = true;
            });
            docSearch = MemoryVectorStore(embeddings: embeddings);
            return MemoryVectorStore(embeddings: embeddings);
          });
        }).catchError((err) {
          setState(() {
            textSummarize = 'Lỗi tóm tắt file, hãy thử lại ${err.toString()}';
            isLoading = false;
            isLoadedSummarize = true;
          });
        });
      }
    } catch (e) {
      setState(() {
        textSummarize = 'Lỗi tóm tắt file, hãy thử lại ${e.toString()}';
        isLoading = false;
        isLoadedSummarize = true;
      });
    }
  }

  void loadFilePdf() async {}

  void getChatResponse() async {
    try {
      final res = await retrievalQA(enteredQuestion);
      if (res['statusCode'] == 429) {
        _responsedAnswer =
            'Bạn đã gửi quá nhiều yêu cầu(Tối Tối đa 3 yêu cầu/phút), hãy thử lại sau 20s.';
        chatConversation.add({'Ai': _responsedAnswer.trim()});
        isLoading = false;
      } else {
        setState(() {
          _responsedAnswer = res['result'].toString();
          chatConversation.add({'Ai': _responsedAnswer.trim()});
          isLoading = false;
        });
      }
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
  void dispose() {
    super.dispose();
    print('Da goi ham dispose');
    print('ChatConversation:________ ${chatConversation.length}');
    // print('widget.oldConversation:______ ${widget.oldConversation.length}');
    if (chatConversation.isNotEmpty &&
        // &&
        // chatConversation.length != widget.oldConversation.length
        textSummarize.isNotEmpty &&
        fileName.isNotEmpty &&
        filePath.isNotEmpty &&
        fileContent.isNotEmpty) {
      try {
        _chatController.dispose();
        FirebaseFirestore.instance.collection('summarize').add({
          'conversation': chatConversation,
          "createdAt": Timestamp.now(),
          'deletedAt': null,
          'summarize': textSummarize,
          'fileName': fileName,
          'filePath': filePath,
          'documentContent': fileContent
        });
      } catch (e) {
        print(e.toString());
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
    Widget summarizeTextWidget = textSummarize.isNotEmpty
        ? Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            margin: const EdgeInsets.only(
              bottom: 8,
              top: 8,
            ),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Color.fromARGB(255, 228, 96, 200)),
            child: SingleChildScrollView(
              child: Text(
                textSummarize,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ))
        : const Text('');
    var listView = ListView.builder(
        controller: _scrollController,
        itemCount: chatConversation.length + 1,
        itemBuilder: (ctx, index) {
          if (index == 0) {
            return summarizeTextWidget;
          } else {
            final item = chatConversation[index - 1];
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
          }
        });
    Widget inputChatForm = Form(
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
                enteredQuestion = value!;
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
                        if (enteredQuestion.isNotEmpty) {
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
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summarize data'),
        actions: [
          ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const TabScreen(
                          selectedIndex: 2,
                          chatHistory: [],
                          filePath: '',
                          oldFileContent: '',
                          summarizeChatHistory: [],
                        )));
              },
              child: const Text('New Summarize')),
        ],
      ),
      drawer: const MainSummarizeDrawer(),
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
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                    children: [fileSelect, selectedFile, selectedFileName]),
              )),
          isLoadedSummarize
              ? Expanded(
                  child: listView,
                )
              : Container(),
          Opacity(
            opacity: isLoadedSummarize ? 1 : 0.3,
            child: IgnorePointer(
              ignoring: !isLoadedSummarize,
              child: inputChatForm,
            ),
          )
        ],
        // ),
      ),
    );
  }
}
