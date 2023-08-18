import 'package:flutter/material.dart';
import 'package:whisper_dart/scheme/scheme.dart';

import 'package:whisper_dart/whisper_dart.dart';

class AudioToText extends StatelessWidget {
  const AudioToText();

  void getTextFromAudio() async {
    Whisper whisper = Whisper(whisperLib: 'galaxeus_ai.so');
    Version whisperVersion = await whisper.getVersion().then((value) {
      print(value);
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: ElevatedButton(
          onPressed: getTextFromAudio,
          child: const Text('Click Here To See Magic!')),
    ));
  }
}
