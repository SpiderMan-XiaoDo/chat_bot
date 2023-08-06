import 'package:chat_bot/screens/tab_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReturnedHomeScreen extends StatelessWidget {
  ReturnedHomeScreen({super.key, required this.openAIKey});
  final String openAIKey;
  void _deleteOpenAIKey() async {
    final url = Uri.https(
        'chat-bot-api-ffdeb-default-rtdb.asia-southeast1.firebasedatabase.app',
        'openai-key.json');
    print(url);
    try {
      final response = await http.delete(url);
      print(response.statusCode);
    } catch (e) {}
  }

  String _keyToken() {
    var usedKey = openAIKey;
    var key =
        '${usedKey.substring(0, 3)}***********${usedKey.substring(usedKey.length - 4, usedKey.length)}';
    return key;
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage = SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 255, 255),
            Color.fromARGB(255, 255, 240, 240),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
        child: Form(
          // key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(172),
                  image: DecorationImage(
                      image: Image.asset('assets/image/brycen.jpg').image),
                ),
              ),
              Container(
                width: 500,
                height: 80,
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 76, 97, 115),
                    borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
                child: Center(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.fromLTRB(4, 0, 0, 4),
                            margin: const EdgeInsets.only(bottom: 8, right: 4),
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 227, 239, 237),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Center(
                              // const Align(
                              // alignment: AlignmentDirectional.center,
                              child: Text(
                                'Key using',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )),
                      ),
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.fromLTRB(4, 0, 0, 4),
                          margin: const EdgeInsets.only(bottom: 8, right: 4),
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 113, 111, 111),
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                            child: Text(
                              _keyToken(),
                              style: const TextStyle(
                                  fontSize: 20,
                                  color: Color.fromARGB(255, 101, 246, 214)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all<Size>(
                              const Size(170, 50))),
                      onPressed: () {
                        _deleteOpenAIKey();
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                const TabScreen(selectedIndex: 0)));
                      },
                      child: const Text('New Key')),
                  ElevatedButton(
                      style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all<Size>(
                              const Size(170, 50))),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              const TabScreen(selectedIndex: 1),
                        ));
                      },
                      child: const Text('Use this Key')),
                ],
              ),
              const SizedBox(
                height: 270,
              )
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      body: activePage,
    );
  }
}
