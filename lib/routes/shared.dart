import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'package:aperturama/routes/collections_list.dart';
import 'package:aperturama/routes/media_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:aperturama/utils/main_drawer.dart';
import 'package:aperturama/utils/media.dart';
import '../utils/user.dart';

class Shared extends StatefulWidget {
  const Shared({Key? key}) : super(key: key);

  @override
  State<Shared> createState() => _SharedState();
}

class _SharedState extends State<Shared> {
  int _gridSize = 0; // Start at 0 and set during the first build
  int _gridSizeMax = 0; // Start at 0 and set during the first build

  String jwt = "";

  // TODO: Enable swipe down to reload

  // Store the URLs for all the photos the app needs to download and cache
  Future<MediaCollectionsLists> _getSharedList() async {
    List<Media> media = [];

    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    jwt = await User.getJWT();
    http.Response resp;
    try {
      resp = await http.get(Uri.parse(serverAddress + '/api/v1/media/shared'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer ' + jwt,
          });

      if(resp.statusCode != 200) {
        log("Media listing failed: Code " + resp.statusCode.toString());
      } else {
        final responseJson = jsonDecode(resp.body);

        // For each media item we got
        for (int i = 0; i < responseJson.length; i++) {
          media.add(Media(
            responseJson[i]["media_id"].toString(), MediaType.photo,
            serverAddress + "/api/v1/media/" + responseJson[i]["media_id"].toString() + '/thumbnail',
            serverAddress + "/api/v1/media/" + responseJson[i]["media_id"].toString() + '/media',
          ));
        }
      }

    } on SocketException {
      log("Media listing failed: Socket exception");
    }

    List<Collection> collections = [];

    // Send a request to the backend
    try {
      resp = await http.get(Uri.parse(serverAddress + '/api/v1/collections/shared'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer ' + jwt,
          });

      if(resp.statusCode != 200) {
        log("Collection listing failed: Code " + resp.statusCode.toString());
      } else {

        final responseJson = jsonDecode(resp.body);

        log("Listing collection media");
        // For each collection item we got
        for (int i = 0; i < responseJson.length; i++) {
          // Find all the photos
          // Send a request to the backend
          List<Media> m = [];
          try {
            resp = await http.get(Uri.parse(serverAddress + '/api/v1/collections/' + responseJson[i]["collection_id"].toString()),
                headers: {
                  HttpHeaders.authorizationHeader: 'Bearer ' + jwt,
                });

            if(resp.statusCode != 200) {
              log("Collection media listing failed: Code " + resp.statusCode.toString());
            } else {
              final responseJson2 = jsonDecode(resp.body);

              final cmedia = responseJson2["media"];
              for (int k = 0; k < cmedia.length; k++) {
                m.add(Media(
                  cmedia[i]["media_id"].toString(), MediaType.photo,
                  serverAddress + "/api/v1/media/" + cmedia[i]["media_id"].toString() + '/thumbnail',
                  serverAddress + "/api/v1/media/" + cmedia[i]["media_id"].toString() + '/media',
                ));
              }
              // Save the collection
              collections.add(Collection(
                responseJson[i]["name"], "", responseJson[i]["collection_id"].toString(),
                false,
                m,
              ));
            }
          } on SocketException {
            log("Collection media listing failed: Socket exception");
          }

        }
      }

    } on SocketException {
      log("Collection listing failed: Socket exception");
    }

    // TODO: Save and load from disk if network is unavailable

    return MediaCollectionsLists(collections, media);

  }

  // Function to handle changing the size of the photo grid
  void _changeGridSize(int amount) {
    // Make sure the grid size can't go below 1 or above the max size
    if (_gridSize > 10) {
      amount *= kIsWeb ? 2 : 1;
    }

    // Otherwise update it as normal
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
        FutureBuilder<MediaCollectionsLists>(
          future: _getSharedList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      horizontalTitleGap: 0,
                      title: const Text("Collections"),
                      contentPadding: const EdgeInsets.only(left: 14, bottom: 10),
                      subtitle: Text(snapshot.data!.collections.length.toString() + " collections shared with you"),
                    ),
                    CollectionList(snapshot.data!.collections, jwt),
                    ListTile(
                      horizontalTitleGap: 0,
                      title: const Text("Photos"),
                      contentPadding: const EdgeInsets.only(left: 14, bottom: 10),
                      subtitle: Text(snapshot.data!.media.length.toString() + " photos shared with you"),
                    ),
                   MediaGrid(snapshot.data!.media, _gridSize, jwt, ""),
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
