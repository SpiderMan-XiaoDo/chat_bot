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

  @override
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
            chunkSize: 20,
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
          print(
              'Metadata________________________________________________: $textsWithSources');
          final llm = ChatOpenAI(
            apiKey: widget.openAiKey,
            model: 'gpt-3.5-turbo-0613',
            temperature: 0,
          );
          embeddings = OpenAIEmbeddings(apiKey: widget.openAiKey);

          var promptString =
              'Hãy dịch đoạn văn bản sau trên bằng ngôn ngữ {language}:\n {text}';
          var prompt = PromptTemplate.fromTemplate(promptString);
          final summarizeChain = SummarizeChain.mapReduce(llm: llm);
          summarizeChain.run(docChunks).then((value) {
            final chain = LLMChain(llm: llm, prompt: prompt);
            chain.run({'language': 'Viet Nam', 'text': value}).then((value) {
              print('Tóm Tắt bằng tiếng Việt: \n $value');
              setState(() {
                isLoadedFile = true;
                textSummarize = value;
              });
            });
            return value;
          }).catchError((err) {
            print('Err: _______________${err.toString()}');

            return err;
          });
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void loadFilePdf() async {}

  void getChatResponse() async {
    try {
      String history = '';
      chatConversation.forEach((element) {
        history = '$history${element.keys.first}: ${element.values.first}\n';
      });
      // embeddings, docSearch đã được định nghĩa trong loadFile
      docSearch = await MemoryVectorStore.fromDocuments(
          documents: textsWithSources, embeddings: embeddings);
      final llm = ChatOpenAI(
          apiKey: widget.openAiKey,
          model: 'gpt-3.5-turbo-0613',
          temperature: 1);
      final qaChain = OpenAIQAWithSourcesChain(llm: llm);
      final docPrompt = PromptTemplate.fromTemplate(
        'Hãy sử dụng nội dung đã cung cấp để trả lời các câu hỏi bằng tiếng Việt.\ncontent: {page_content}\nSource: {source}',
      );
      final finalQAChain = StuffDocumentsChain(
        llmChain: qaChain,
        documentPrompt: docPrompt,
      );
      final retrievalQA = RetrievalQAChain(
        retriever: docSearch.asRetriever(),
        combineDocumentsChain: finalQAChain,
      );
      retrievalQA(_enteredQuestion).then((value) {
        setState(() {
          _responsedAnswer = value.toString();
          chatConversation.add({'Ai': _responsedAnswer.trim()});
          isLoading = false;
        });
      }).catchError((error) {
        setState(() {
          _responsedAnswer = error.toString();
          chatConversation.add({'Ai': _responsedAnswer.trim()});
          isLoading = false;
        });
      });
    } catch (err) {
      print('err: ${err.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Text(textSummarize),
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
