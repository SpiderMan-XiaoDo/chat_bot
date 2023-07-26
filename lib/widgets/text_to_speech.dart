import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech extends StatelessWidget {
  TextToSpeech({super.key});
  final _flutterTts = FlutterTts();

  void textToSpeech(String content) async {
    try {
      // List<dynamic> languages = await _flutterTts.getLanguages;
      // print("Danh sách ngôn ngữ hỗ trợ:");
      // languages.forEach((language) {
      //   print(language);
      // });
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(content);
    } catch (error) {
      print(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            ElevatedButton(onPressed: () {}, child: const Icon(Icons.speaker)),
      ),
    );
  }
}
