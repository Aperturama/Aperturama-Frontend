import 'dart:math';

import 'package:aperturama/routes/photos.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../utils/main_drawer.dart';

class Collections extends StatefulWidget {
  const Collections({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<Collections> createState() => _CollectionsState();
}

class _CollectionsState extends State<Collections> {

  int _gridSize = 2;

  // Store the URLs for all the photos the app needs to download and cache
  Future<List<CollectionDetails>> _getCollectionsList() async {
    List<CollectionDetails> collections = [];

    // For now, make up some collections
    var rng = Random();
    int numCollections = 20;

    for (int i = 0; i < numCollections; i++) {

      int photos = rng.nextInt(100) + 10;
      int videos = rng.nextInt(100) + 10;

      List<PhotoDetails> p = [];
      for (int k = 1; k <= 8; k++) {
        p.add(PhotoDetails(k.toString(),
          'https://picsum.photos/seed/' + (i * numCollections + k).toString() + '/256',
          'https://picsum.photos/seed/' + (i * numCollections + k).toString() + '/4096'
          )
        );
      }

      collections.add(CollectionDetails(
          "Collection " + (i+1).toString(),
          photos.toString() + " Photos, " + videos.toString() + " Videos",
          "random url",
          rng.nextInt(2) == 0 ? false : true,
          p
        )
      );
    }

    // TODO: Save and load from disk if network is unavailable

    return collections;
  }

  Widget _createCollectionCard(BuildContext context, CollectionDetails collection) {
    return GestureDetector(
      onTap: () => {
        Navigator.pushNamed(context, '/collection_viewer',
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
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Center(child: CachedNetworkImage(
                      imageUrl: collection.previewImages[index].thumbnailURL,
                      progressIndicatorBuilder: (context, url, downloadProgress) =>
                          SizedBox(width: 32, height: 32, child:
                          CircularProgressIndicator(value: downloadProgress.progress)
                          ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                      imageBuilder: (context, imageProvider) {
                        return Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        );
                      }),
                  ),
                );
              }),
            ),
            ListTile(
              horizontalTitleGap: 0,
              title: ListTile(
                title: Transform(
                  transform: Matrix4.translationValues(-16, 0.0, 0.0), // Fix the indention issue
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
        body: FutureBuilder<List<CollectionDetails>>(
          future: _getCollectionsList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return _createCollectionCard(context, snapshot.data![index]);
                  },
                  itemCount: snapshot.data!.length,
              );
            } else if (snapshot.hasError) {
              return const Text("Error");
            }
            return const Text("Loading...");
          },
        ),
        drawer: const MainDrawer());
  }
}


class CollectionDetails {
  final String name;
  final String information;
  final String url;
  final bool shared;
  final List<PhotoDetails> previewImages;

  CollectionDetails(
      this.name, this.information, this.url, this.shared, this.previewImages
  );
}