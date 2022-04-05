import 'dart:math';

import 'package:aperturama/routes/collections.dart';
import 'package:aperturama/routes/photos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:aperturama/utils/main_drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../utils/main_drawer.dart';

class Shared extends StatefulWidget {
  const Shared({Key? key}) : super(key: key);

  @override
  State<Shared> createState() => _SharedState();
}

class _SharedState extends State<Shared> {
  int _gridSize = 0; // Start at 0 and set during the first build
  int _gridSizeMax = 0; // Start at 0 and set during the first build

  // TODO: Enable swipe down to reload

  // Store the URLs for all the photos the app needs to download and cache
  Future<SharedData> _getSharedList() async {
    List<PhotoDetails> photos = [];

    // For now, make up urls
    for (int i = 0; i < 17; i++) {
      photos.add(PhotoDetails(
        photos.length.toString(),
        'https://picsum.photos/seed/' + photos.length.toString() + '/256',
        'https://picsum.photos/seed/' + photos.length.toString() + '/4096',
      ));
    }

    List<CollectionDetails> collections = [];

    // For now, make up some collections
    var rng = Random();
    int numCollections = 2;

    for (int i = 0; i < numCollections; i++) {
      int photoCount = rng.nextInt(100) + 10;
      int videoCount = rng.nextInt(100) + 10;

      List<PhotoDetails> p = [];
      for (int k = 1; k <= photoCount; k++) {
        p.add(PhotoDetails(
            k.toString(),
            'https://picsum.photos/seed/' +
                (i * numCollections + k).toString() +
                '/256',
            'https://picsum.photos/seed/' +
                (i * numCollections + k).toString() +
                '/4096'));
      }

      collections.add(CollectionDetails(
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

    SharedData sd = SharedData(collections, photos);

    return sd;
  }

  // Function to handle changing the size of the photo grid
  void _changeGridSize(int amount) {
    // Make sure the grid size can't go below 1 or above the max size

    if (_gridSize > 10) {
      amount *= kIsWeb ? 2 : 1;
    }

    if (amount < 0) {
      if (_gridSize + amount <= 0) {
        _gridSize = 1;
      } else {
        _gridSize += amount;
      }
    } else if (amount > 0) {
      if (_gridSize + amount >= _gridSizeMax) {
        _gridSize = _gridSizeMax;
      } else {
        _gridSize += amount;
      }
    }
    setState(() {
      _gridSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    // Set up the initial grid sizing
    // TODO: This doesn't reload when a web browser's size is changed, should probably be fixed
    if (_gridSize == 0 && _gridSizeMax == 0) {
      double width = MediaQuery.of(context).size.width;
      _gridSize = max(4, (width / 200.0).round());
      _gridSizeMax = max(8, (width / 100.0).round());
      debugPrint('$width $_gridSize $_gridSizeMax');
    }

    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("Shared Media"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                _changeGridSize(1);
              },
              tooltip: 'Decrease Image Size',
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                _changeGridSize(-1);
              },
              tooltip: 'Increase Image Size',
            ),
          ],
        ),
        body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            child: kIsWeb ? const MainDrawer() : null,
          ),
          FutureBuilder<SharedData>(
            future: _getSharedList(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        horizontalTitleGap: 0,
                        title: const Text("Collections"),
                        contentPadding: EdgeInsets.only(left: 14, bottom: 10),
                        subtitle: Text(snapshot.data!.collections.length.toString() + " collections shared with you"),
                      ),
                      CollectionList(snapshot.data!.collections),
                      ListTile(
                        horizontalTitleGap: 0,
                        title: const Text("Photos"),
                        contentPadding: EdgeInsets.only(left: 14, bottom: 10),
                        subtitle: Text(snapshot.data!.photos.length.toString() + " photos shared with you"),
                      ),
                     PhotoGrid(snapshot.data!.photos, _gridSize),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return const Text("Error");
              }
              return const Text("Loading...");
            },
          ),
        ]),
        drawer: kIsWeb ? null : const MainDrawer());
  }
}

class SharedData {
  final List<CollectionDetails> collections;
  final List<PhotoDetails> photos;

  SharedData(this.collections, this.photos);
}
