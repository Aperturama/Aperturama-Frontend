import 'package:flutter/material.dart';
import 'package:aperturama/utils/main_drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../utils/main_drawer.dart';

class Photos extends StatefulWidget {
  const Photos({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<Photos> createState() => _PhotosState();
}

class _PhotosState extends State<Photos> {
  int _gridSize = 4;
  final int _gridSizeMax = 8;

  // Store the URLs for all the photos the app needs to download and cache
  List<PhotoDetails> photos = [];
  final int photoBufferAheadMin = 128;
  final int photoBufferAheadStep = 512;

  // Function to handle changing the size of the photo grid
  void _changeGridSize(int amount) {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
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
    });
  }

  void _requestPhotos() {
    // HTTP request using photoBufferAheadStep to get that many more photo urls

    // For now, make up urls
    for(int i = 0; i < photoBufferAheadStep; i++) {
      photos.add(PhotoDetails(photos.length.toString(),
          'https://picsum.photos/seed/' + photos.length.toString() + '/256',
          'https://picsum.photos/seed/' + photos.length.toString() + '/4096',
      ));
    }

  }

  Widget _createPhotoIcon(BuildContext context, int index) {

    // Quick, get some more photos!
    if(index + photoBufferAheadMin > photos.length) {
      _requestPhotos();
    }

    return GestureDetector(
      onTap: () => {
        Navigator.pushNamed(context, '/photo_viewer',
          arguments: photos[index]
        )
      },
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: CachedNetworkImage(
                  imageUrl: photos[index].thumbnailURL,
                  progressIndicatorBuilder:
                      (context, url, downloadProgress) =>
                      CircularProgressIndicator(
                          value: downloadProgress.progress),
                  errorWidget: (context, url, error) =>
                  const Icon(Icons.error),
                ),
              ),
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
          title: const Text("Aperturama"),
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
        body: GridView.builder(
          // Create a grid with 2 columns. If you change the scrollDirection to
          // horizontal, this produces 2 rows.
          //crossAxisCount: _gridSize,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _gridSize),
          itemBuilder: (BuildContext context, int index) {
            return _createPhotoIcon(context, index);
          },
        ),
        
        drawer: const MainDrawer());
  }
}


class PhotoDetails {
  final String photoID;
  final String thumbnailURL;
  final String highresURL;

  PhotoDetails(this.photoID, this.thumbnailURL, this.highresURL);
}