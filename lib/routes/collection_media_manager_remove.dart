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

class CollectionMediaManagerRemove extends StatefulWidget {
  const CollectionMediaManagerRemove({Key? key}) : super(key: key);

  @override
  State<CollectionMediaManagerRemove> createState() => _CollectionMediaManagerRemoveState();
}

class _CollectionMediaManagerRemoveState extends State<CollectionMediaManagerRemove> {
  int _gridSize = 0; // Start at 0 and set during the first build
  int _gridSizeMax = 0; // Start at 0 and set during the first build

  List<Media> media = [];
  List<Media> newMedia = [];
  late final Collection collection;

  String mode = "";
  String jwt = "";
  bool initialDataPending = true;

  // Load info on first load
  @override
  void initState() {
    super.initState();
    _getMediaList();
  }

  // TODO: Enable swipe down to reload

  // Store the URLs for all the photos the app needs to download and cache
  Future<void> _getMediaList() async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    jwt = await User.getJWT();
    http.Response resp;
    try {
      log("JWT: " + jwt);
      resp = await http
          .get(Uri.parse(serverAddress + '/api/v1/media'), headers: {HttpHeaders.authorizationHeader: 'Bearer ' + jwt});

      if (resp.statusCode != 200) {
        log("Media listing failed: Code " + resp.statusCode.toString());
        return;
      }

      log(resp.body);
      final responseJson = jsonDecode(resp.body);

      // For each media item we got
      for (int i = 0; i < responseJson.length; i++) {
        log("image " + i.toString());
        media.add(Media(
          responseJson[i]["media_id"].toString(),
          MediaType.photo,
          serverAddress + "/api/v1/media/" + responseJson[i]["media_id"].toString() + '/thumbnail',
          serverAddress + "/api/v1/media/" + responseJson[i]["media_id"].toString() + '/media',
        ));
        media[i].filename = responseJson[i]["filename"];
        media[i].takenTimestamp = DateTime.parse(responseJson[i]["date_taken"]);
      }
      log("images made");

    } on SocketException {
      log("Media listing failed: Socket exception");
      return;
    }

    initialDataPending = false;
    setState(() {});
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

  Widget _createTappableMediaIcon(BuildContext context, Media media, List<Media> newMedia) {
    // Make a nice button that has the thumbnail inside it
    return GestureDetector(
        onTap: () {
          log("adding media");
          if (newMedia.contains(media)) {
            newMedia.remove(media);
          } else {
            newMedia.add(media);
          }
          log(newMedia.toString());
          setState(() {});
        },
        child: Stack(
          children: <Widget>[
            MediaIcon(media, jwt),
            if (newMedia.contains(media))
              const Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.add_circle_outline),
              ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    if (mode == "") {
      // Don't do this a 2nd time
      if (ModalRoute.of(context)!.settings.arguments != null) {
        var args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        collection = args["collection"];
        mode = args["mode"];
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
        title: Text("Select media to " + (mode == "add" ? "add" : "remove")),
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
          child: initialDataPending
              ? Text("Loading...")
              : Column(
                  children: [
                    TextButton(
                      child: const Text("Save"),
                      onPressed: () async {
                        if (await collection.addMedia(newMedia)) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Media added successfully.')));
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Failed to add media.')));
                        }
                      },
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _gridSize),
                      itemBuilder: (BuildContext context, int index) {
                        return _createTappableMediaIcon(context, media[index], newMedia);
                      },
                      itemCount: media.length,
                    ),
                  ],
                ))
      ]),
    );
  }
}

class MediaIcon extends StatelessWidget {
  const MediaIcon(final this.media, this.jwt, {Key? key}) : super(key: key);

  final Media media;
  final String jwt;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Center(
        child: CachedNetworkImage(
            httpHeaders: {HttpHeaders.authorizationHeader: 'Bearer ' + jwt},
            imageUrl: media.thumbnailURL,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                SizedBox(width: 32, height: 32, child: CircularProgressIndicator(value: downloadProgress.progress)),
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
