import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:aperturama/utils/main_drawer.dart';
import 'package:aperturama/utils/media.dart';
import '../utils/main_drawer.dart';
import 'media_list.dart';

class CollectionMediaManagerRemove extends StatefulWidget {
  const CollectionMediaManagerRemove({Key? key}) : super(key: key);

  @override
  State<CollectionMediaManagerRemove> createState() => _CollectionMediaManagerRemoveState();
}

class _CollectionMediaManagerRemoveState extends State<CollectionMediaManagerRemove> {
  int _gridSize = 0; // Start at 0 and set during the first build
  int _gridSizeMax = 0; // Start at 0 and set during the first build

  List<Media> selectedMedia = [];
  late final Collection collection;

  String mode = "";
  String jwt = "";
  bool initialDataPending = true;

  // Load info on first load
  @override
  void initState() {
    super.initState();
  }

  // TODO: Enable swipe down to reload

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

  // Function to build a nice button widget with the thumbnail inside it that can be tapped to add to the change list
  Widget _createTappableMediaIcon(Media media) {
    return GestureDetector(
      onTap: () {
        if (selectedMedia.contains(media)) {
          selectedMedia.remove(media);
        } else {
          selectedMedia.add(media);
        }
        setState(() {});
      },
      child: Stack(
        children: <Widget>[
          MediaIcon(media, jwt, ""),
          if (selectedMedia.contains(media))
            const Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.remove_circle_outline),
            ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (jwt == "") { // Only run this once
      if (ModalRoute.of(context)!.settings.arguments != null) {
        var args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        collection = args["collection"];
        jwt = args["jwt"];
      } else {
        collection = Collection("", "", "", false, []);
        // Todo: Probably navigate back to the /collections page
      }
    }

    // TODO: This doesn't reload when a web browser's size is changed, should probably be fixed
    if (_gridSize == 0 && _gridSizeMax == 0) {
      double width = MediaQuery.of(context).size.width;
      _gridSize = math.max(4, (width / 200.0).round());
      _gridSizeMax = math.max(8, (width / 100.0).round());
      debugPrint('$width $_gridSize $_gridSizeMax');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select media to remove", style: TextStyle(fontSize: 16)),
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
        Expanded(
          child: Column(
            children: [
              TextButton(
                child: const Text("Save"),
                onPressed: () async {
                  if (await collection.removeMedia(selectedMedia)) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Media removed successfully.')));
                    setState(() {});
                    Navigator.pushReplacementNamed(context, '/collections');
                  } else {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Failed to remove media.')));
                  }
                },
              ),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _gridSize),
                itemBuilder: (BuildContext context, int index) {
                  return _createTappableMediaIcon(collection.media[index]);
                },
                itemCount: collection.media.length,
              ),
            ],
          )
        )
      ]),
    );
  }
}
