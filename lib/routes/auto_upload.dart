import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:aperturama/routes/collections.dart';

import '../utils/main_drawer.dart';

class AutoUpload extends StatelessWidget {
  const AutoUpload({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("Automatic Upload"),
          centerTitle: true,
        ),
        body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            child: kIsWeb ? const MainDrawer() : null,
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        horizontalTitleGap: 0,
                        title: const Text("Recently Uploaded"),
                        contentPadding: EdgeInsets.only(left: 14, bottom: 10),
                        subtitle: Text("Last sync: 2022/04/05 11:25am"),
                        trailing: IconButton(
                          icon: const Icon(Icons.loop),
                          onPressed: () {
                            // TODO: Actually trigger a resync
                          },
                        ),
                      ),
                      //CollectionList(snapshot.data!.collections),

                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        horizontalTitleGap: 0,
                        title: const Text("Configured Folders"),
                        contentPadding: EdgeInsets.only(left: 14, bottom: 10),
                        subtitle: Text("3 Folders"),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            // TODO: Actually trigger a resync
                          },
                        ),
                      ),
                      //PhotoGrid(snapshot.data!.photos, _gridSize),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
        drawer: kIsWeb ? null : const MainDrawer());
  }
}
