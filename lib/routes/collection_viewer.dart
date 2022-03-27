import 'package:aperturama/routes/collection_settings.dart';
import 'package:aperturama/routes/photos.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../utils/main_drawer.dart';
import 'collections.dart';

class CollectionViewer extends StatefulWidget {
  const CollectionViewer({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<CollectionViewer> createState() => _CollectionViewerState();
}

class _CollectionViewerState extends State<CollectionViewer> {
  int _gridSize = 4;
  final int _gridSizeMax = 8;

  // Function to handle changing the size of the photo grid
  void _changeGridSize(int amount) {
    // Make sure the grid size can't go below 1 or above the max size
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
    final CollectionDetails collection;
    if(ModalRoute.of(context)!.settings.arguments != null) {
      collection = ModalRoute.of(context)!.settings.arguments as CollectionDetails;
    } else {
      collection = CollectionDetails("", "", "", false, []);
      // Todo: Probably navigate back to the /collections page
    }

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
          title: Text(collection.name),
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
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              horizontalTitleGap: 0,
              title: ListTile(
                title: Transform(
                  transform: Matrix4.translationValues(-16, 0.0, 0.0), // Fix the indention issue
                  child: Text(collection.shared ? "Shared" : "Not Shared"),
                ),
                trailing: TextButton(
                  child: const Text('Settings'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        barrierDismissible: true,
                        opaque: false,
                        pageBuilder: (_, anim1, anim2) => CollectionSettings(collection),
                      ),
                    );
                  },
                ),
              ),
              subtitle: Text(collection.information),
              contentPadding: EdgeInsets.only(left: 14, bottom: 10),
            ),
            Expanded(
              child: PhotoGrid(collection.images, _gridSize),
            ),
          ],
        ));
  }
}
