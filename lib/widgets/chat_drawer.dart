import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> listHistory = [];
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
            }
            historyListView = ListView.builder(
                itemCount: listHistory.length,
                itemBuilder: (ctx, index) {
                  final item = listHistory[index];
                  var chatElementName = '';
                  item.forEach((key, value) {
                    if (key == 'createdAt') {
                      chatElementName = dateToString(value.toDate());
                    }
                  });
                  return ListTile(
                    focusColor: Color.fromARGB(255, 124, 121, 121),
                    hoverColor: Color.fromARGB(255, 124, 121, 121),
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
                    onTap: () {},
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
