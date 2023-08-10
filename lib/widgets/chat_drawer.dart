import 'package:chat_bot/screens/tab_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    List<dynamic> listHistory = [];
    List<String> listHistoryID = [];
    Widget historyListView = Container();
    String dateToString(DateTime createdAt) {
      final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      return formatter.format(createdAt);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy(
            "createdAt",
            descending: true,
          )
          .snapshots(),
      builder: (context, snapshot) {
        try {
          if (snapshot.hasData) {
            var documents = snapshot.data!.docs;
            for (var document in documents) {
              var data = document.data();
              listHistory.add(data);
              listHistoryID.add(document.id);
            }
            final colectionRef = FirebaseFirestore.instance.collection('chat');
            historyListView = ListView.builder(
                itemCount: listHistory.length,
                itemBuilder: (ctx, index) {
                  final item = listHistory[index];
                  var chatElementName = '';
                  var chatHistory = [];
                  var chatId = listHistoryID[index];
                  print('ChatID:__________ $chatId');
                  item.forEach((key, value) {
                    // if (key == 'createdAt') {
                    //   chatElementName = dateToString(value.toDate());
                    // }
                    if (key == 'title') {
                      chatElementName = value.toString();
                    }
                    if (key == 'conversation') {
                      chatHistory = value;
                      // print();
                    }
                  });
                  return ListTile(
                    focusColor: Color.fromARGB(255, 250, 235, 235),
                    hoverColor: Color.fromARGB(255, 250, 235, 235),
                    leading: Icon(Icons.chat_bubble_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.onBackground),
                    title: Text(
                      chatElementName.toString(),
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 16,
                          ),
                    ),
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete chat?'),
                          content: const Text(
                              "Warning: You can't undo this action!"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                final documentRef =
                                    colectionRef.doc(listHistoryID[index]);
                                documentRef.delete();
                                Navigator.pop(ctx);
                                Navigator.of(context).pop();
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => const TabScreen(
                                        selectedIndex: 1, chatHistory: [])));
                              },
                              child: const Text('Okay'),
                            ),
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel')),
                          ],
                        ),
                      );
                    },
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => TabScreen(
                              selectedIndex: 1, chatHistory: chatHistory)));
                    },
                  );
                });
          }
        } catch (e) {
          print(e.toString());
        }
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Drawer(
              child: Column(
            children: [
              DrawerHeader(
                // padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.8),
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_sharp,
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(
                      width: 18,
                    ),
                    Text('Chat history',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            )),
                  ],
                ),
              ),
              // ListTile(
              //   leading: Icon(
              //     Icons.restaurant,
              //     size: 26,
              //     color: Theme.of(context).colorScheme.onBackground,
              //   ),
              //   title: Text(
              //     'Meal',
              //     style: Theme.of(context).textTheme.titleSmall!.copyWith(
              //           color: Theme.of(context).colorScheme.onBackground,
              //           fontSize: 24,
              //         ),
              //   ),
              //   onTap: () {},
              // ),
              Expanded(child: historyListView),
              ListTile(
                leading: Icon(
                  Icons.settings,
                  size: 26,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                title: Text(
                  'Setting',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 24,
                      ),
                ),
                onTap: () {},
              )
            ],
          )),
        );
      },
    );
  }
}
