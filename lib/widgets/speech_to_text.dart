import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechToTextScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SpeechToText();
  }
}

class _SpeechToText extends State<SpeechToTextScreen> {
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    PermissionStatus status = await Permission.microphone.request();
    print('Hello');
    _speechEnabled = await _speechToText.initialize().then((value) {
      print('value: ${value}');
      return value;
    });
    setState(() {
      print('Hello2');
    });
  }

  void _startListening() async {
    try {
      await _speechToText.listen(onResult: _onSpeechResult).then((value) {});
      setState(() {});
    } catch (e) {
      print(e.toString());
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      // print('_lastWords: ${_lastWords}');
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                'Recognized words:',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: Text(
                    // If listening is active show the recognized words
                    _lastWords != null && _lastWords != ''
                        ? '${_lastWords}'
                        : ''),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            // If not yet listening for speech start, otherwise stop
            _speechToText.isNotListening ? _startListening : _stopListening,
        tooltip: 'Listen',
        child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
