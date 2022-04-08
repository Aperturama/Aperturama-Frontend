import 'dart:math';

import 'package:aperturama/routes/photos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aperturama/utils/media.dart';

import '../utils/main_drawer.dart';

class Collections extends StatefulWidget {
  const Collections({Key? key}) : super(key: key);

  @override
  State<Collections> createState() => _CollectionsState();
}

class _CollectionsState extends State<Collections> {

  // Store the URLs for all the photos the app needs to download and cache
  Future<List<Collection>> _getCollectionsList() async {
    List<Collection> collections = [];

    // For now, make up some collections
    var rng = Random();
    int numCollections = 20;

    for (int i = 0; i < numCollections; i++) {
      int photoCount = rng.nextInt(100) + 10;
      int videoCount = rng.nextInt(100) + 10;

      List<Photo> p = [];
      for (int k = 1; k <= photoCount; k++) {
        p.add(Photo(
            k.toString(),
            'https://picsum.photos/seed/' +
                (i * numCollections + k).toString() +
                '/256',
            'https://picsum.photos/seed/' +
                (i * numCollections + k).toString() +
                '/4096'));
      }

      collections.add(Collection(
          "Collection " + (i + 1).toString(),
          photoCount.toString() +
              " Photos, " +
              videoCount.toString() +
              " Videos",
          "random url",
          rng.nextInt(2) == 0 ? false : true,
          p));
    }

    // TODO: Save and load from disk if network is unavailable

    return collections;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("Collections"),
          centerTitle: true,
        ),
        body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            child: kIsWeb ? const MainDrawer() : null,
          ),
          Expanded(
            child: FutureBuilder<List<Collection>>(
              future: _getCollectionsList(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return CollectionList(snapshot.data!);
                } else if (snapshot.hasError) {
                  return const Text("Error");
                }
                return const Text("Loading...");
              },
            ),
          ),
        ]),
        drawer: kIsWeb ? null : const MainDrawer());
  }
}

class CollectionList extends StatelessWidget {
  const CollectionList(this.collections, {Key? key}) : super(key: key);

  final List<Collection> collections;

  Widget _createCollectionCard(
      BuildContext context, Collection collection) {
    return GestureDetector(
      onTap: () => {
        Navigator.pushNamed(
          context,
          '/collection_viewer',
          arguments: collection,
        )
      },
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              children: List.generate(4, (index) {
                return PhotoIcon(collection.images[index]);
              }),
            ),
            ListTile(
              horizontalTitleGap: 0,
              title: ListTile(
                title: Transform(
                  transform: Matrix4.translationValues(
                      -16, 0.0, 0.0), // Fix the indention issue
                  child: Text(collection.name),
                ),
                trailing: Text(collection.shared ? "Shared" : "Not Shared"),
              ),
              subtitle: Text(collection.information),
              contentPadding: const EdgeInsets.only(left: 14, bottom: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      // This is needed for the shared media page
      // so that it doesn't scroll within the larger scrollable list
      physics: const ClampingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return _createCollectionCard(
            context, collections[index]);
      },
      itemCount: collections.length,
    );
  }

}


