import 'package:flutter/material.dart';

class SummarizeScreen extends StatefulWidget {
  const SummarizeScreen({super.key, required this.openAiKey});
  final String openAiKey;
  @override
  State<StatefulWidget> createState() {
    return _SummarizeScreenState();
  }
}

class _SummarizeScreenState extends State<SummarizeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Summarize data'),
        ),
        body: Container(
          child: Column(
            children: [
              IconButton(
                  onPressed: () {}, icon: Icon(Icons.drive_folder_upload)),
            ],
          ),
        ));
  }
}
