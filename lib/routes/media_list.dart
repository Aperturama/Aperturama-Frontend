import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:aperturama/utils/main_drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aperturama/utils/media.dart';

import '../utils/main_drawer.dart';
import '../utils/user.dart';

class MediaList extends StatefulWidget {
  const MediaList({Key? key}) : super(key: key);

  @override
  State<MediaList> createState() => _MediaListState();
}

class _MediaListState extends State<MediaList> {
  int _gridSize = 0; // Start at 0 and set during the first build
  int _gridSizeMax = 0; // Start at 0 and set during the first build

  // TODO: Enable swipe down to reload

  // Store the URLs for all the photos the app needs to download and cache
  Future<List<Media>> _getMediaList() async {
    List<Media> media = [];

    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      log("JWT: " + jwt);
      resp = await http.get(Uri.parse(serverAddress + '/api/v1/media'),
        headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt });
    } on SocketException {
      log("Media listing failed: Socket exception");
      return media;
    }

    if(resp.statusCode != 200) {
      log("Media listing failed: Code " + resp.statusCode.toString());
      return media;
    }

    log(resp.body);
    final responseJson = jsonDecode(resp.body);
    log(resp.body);

    // For each media item we got
    for (int i = 0; i < responseJson.length; i++) {
      media.add(Media(
        responseJson[i].media_id, MediaType.photo,
        serverAddress + "/api/v1/media/" + responseJson[i].media_id + '/thumbnail',
        serverAddress + "/api/v1/media/" + responseJson[i].media_id + '/media',
      ));
    }

    // TODO: Save and load from disk if network is unavailable

    return media;
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
      _gridSize = math.max(4, (width / 200.0).round());
      _gridSizeMax = math.max(8, (width / 100.0).round());
      debugPrint('$width $_gridSize $_gridSizeMax');
    }

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
        body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            child: kIsWeb ? const MainDrawer() : null,
          ),
          Expanded(
            child: FutureBuilder<List<Media>>(
              future: _getMediaList(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return MediaGrid(snapshot.data!, _gridSize);
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

class MediaGrid extends StatelessWidget {
  const MediaGrid(this.media, this.gridSize, {Key? key}) : super(key: key);

  final List<Media> media;
  final int gridSize;

  Widget _createTappableMediaIcon(BuildContext context, Media media) {
    // Make a nice button that has the thumbnail inside it
    return GestureDetector(
      onTap: () =>
          {Navigator.pushNamed(context, '/media_viewer', arguments: media)},
      child: MediaIcon(media),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      // This is needed for the shared media page
      // so that it doesn't scroll within the larger scrollable list
      physics: const ClampingScrollPhysics(),
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize),
      itemBuilder: (BuildContext context, int index) {
        return _createTappableMediaIcon(context, media[index]);
      },
      itemCount: media.length,
    );
  }
}

class MediaIcon extends StatelessWidget {
  const MediaIcon(final this.media, {Key? key}) : super(key: key);

  final Media media;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Center(
        child: CachedNetworkImage(
            imageUrl: media.thumbnailURL,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                        value: downloadProgress.progress)),
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
  }
}

