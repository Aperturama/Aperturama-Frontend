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
  int _gridSize = 6; // TODO: Make this dependent on the screen size
  final int _gridSizeMax = 8; // TODO: Make this dependent on the screen size
  // use MediaQuery.of(context).size.width(); for the screen size, but somewhere
  // that has context available

  // TODO: Enable swipe down to reload

  // Store the URLs for all the photos the app needs to download and cache
  Future<List<PhotoDetails>> _getPhotosList() async {
    List<PhotoDetails> photos = [];

    // For now, make up urls
    for (int i = 0; i < 512; i++) {
      photos.add(PhotoDetails(
        photos.length.toString(),
        'https://picsum.photos/seed/' + photos.length.toString() + '/256',
        'https://picsum.photos/seed/' + photos.length.toString() + '/4096',
      ));
    }

    // TODO: Save and load from disk if network is unavailable

    return photos;
  }

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

  Widget _createPhotoIcon(BuildContext context, PhotoDetails photo) {
    // Make a nice button that has the thumbnail inside it
    return GestureDetector(
      onTap: () =>
          {Navigator.pushNamed(context, '/photo_viewer', arguments: photo)},
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Center(child: CachedNetworkImage(
            imageUrl: photo.thumbnailURL,
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
        body: FutureBuilder<List<PhotoDetails>>(
          future: _getPhotosList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return GridView.builder(
                // Create a grid with 2 columns. If you change the scrollDirection to
                // horizontal, this produces 2 rows.
                //crossAxisCount: _gridSize,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridSize),
                itemBuilder: (BuildContext context, int index) {
                  return _createPhotoIcon(context, snapshot.data![index]);
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

class PhotoDetails {
  final String photoID;
  final String thumbnailURL;
  final String highresURL;

  PhotoDetails(this.photoID, this.thumbnailURL, this.highresURL);
}
