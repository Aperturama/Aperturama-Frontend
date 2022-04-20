import 'dart:math';

import 'package:aperturama/routes/collection_settings.dart';
import 'package:aperturama/routes/media_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:aperturama/utils/media.dart';

class CollectionViewer extends StatefulWidget {
  const CollectionViewer({Key? key}) : super(key: key);

  @override
  State<CollectionViewer> createState() => _CollectionViewerState();
}

class _CollectionViewerState extends State<CollectionViewer> {
  int _gridSize = 0; // Start at 0 and set during the first build
  int _gridSizeMax = 0; // Start at 0 and set during the first build
  String jwt = "";
  String code = "";

  // Function to handle changing the size of the photo grid
  void _changeGridSize(int amount) {
    // Make sure the grid size can't go below 1 or above the max size

    if(_gridSize > 10) {
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
    final Collection collection;
    if(ModalRoute.of(context)!.settings.arguments != null) {
      var args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      collection = args["collection"];
      jwt = args.containsKey("jwt") ? args["jwt"] : "";
      code = args.containsKey("code") ? args["code"] : "";
    } else {
      collection = Collection("", "", "", false, []);
      // Todo: Probably navigate back to the /collections page
    }

    // Set up the initial grid sizing
    // TODO: This doesn't reload when a web browser's size is changed, should probably be fixed
    if(_gridSize == 0 && _gridSizeMax == 0) {
      double width = MediaQuery.of(context).size.width;
      _gridSize = max(4, (width / 200.0).round());
      _gridSizeMax = max(8, (width / 100.0).round());
      debugPrint('$width $_gridSize $_gridSizeMax');
    }

    return Scaffold(
        appBar: AppBar(
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
                trailing: (code != "") ? null : TextButton( // Hide settings if the code is used
                  child: const Text('Settings'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/collection_settings',
                      arguments: <String, dynamic>{
                        'collection': collection,
                        'jwt': jwt,
                      },
                    );
                  },
                ),
              ),
              subtitle: Text(collection.information),
              contentPadding: const EdgeInsets.only(left: 14, bottom: 10),
            ),
            Expanded(
              child: MediaGrid(collection.media, _gridSize, jwt, code),
            ),
          ],
        ));
  }
}
