import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';

import 'package:aperturama/routes/media_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aperturama/utils/media.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';

import '../utils/main_drawer.dart';
import '../utils/user.dart';

class Collections extends StatefulWidget {
  const Collections({Key? key}) : super(key: key);

  @override
  State<Collections> createState() => _CollectionsState();
}

class _CollectionsState extends State<Collections> {

  // Store the URLs for all the photos the app needs to download and cache
  Future<List<Collection>> _getCollectionsList() async {
    List<Collection> collections = [];

    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      resp = await http.get(Uri.parse(serverAddress + '/api/v1/collections'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer ' + jwt,
          });
    } on SocketException {
      log("Collection listing failed: Socket exception");
      return collections;
    }

    if(resp.statusCode != 200) {
      log("Collection listing failed: Code " + resp.statusCode.toString());
      return collections;
    }

    log(resp.body);
    final responseJson = jsonDecode(resp.body);
    log(responseJson);

    // For each collection item we got
    for (int i = 0; i < responseJson.length; i++) {
      // Find all the photos
      // Send a request to the backend
      try {
        resp = await http.get(Uri.parse(serverAddress + '/api/v1/collections/' + responseJson.collection_id),
            headers: {
              HttpHeaders.authorizationHeader: 'Bearer ' + jwt,
            });
      } on SocketException {
        log("Collection media listing failed: Socket exception");
        return collections;
      }

      if(resp.statusCode != 200) {
        log("Collection media listing failed: Code " + resp.statusCode.toString());
        return collections;
      }

      log(resp.body);
      final responseJson2 = jsonDecode(resp.body);
      log(responseJson2);

      List<Media> m = [];
      final cmedia = responseJson2.media;
      for (int k = 0; k < cmedia.length; k++) {
        m.add(Media(
          cmedia[i].media_id, MediaType.photo,
          serverAddress + "/api/v1/media/" + cmedia[i].media_id + '/thumbnail',
          serverAddress + "/api/v1/media/" + cmedia[i].media_id + '/media',
        ));
      }

      // Save the collection
      collections.add(Collection(
        responseJson[i].collection_id, "", responseJson[i].name,
        false,
        m,
      ));
    }

    // TODO: Save and load from disk if network is unavailable

    return collections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Collections"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                Navigator.pushNamed(context, '/collections/new');
              },
              tooltip: 'Add new collection',
            ),
          ],
        ),
        body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            child: kIsWeb ? const MainDrawer() : null,
          ),
          Expanded(
            child: FutureBuilder<List<Collection>>(
              future: _getCollectionsList(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return CollectionList(snapshot.data!);
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

class CollectionList extends StatelessWidget {
  const CollectionList(this.collections, {Key? key}) : super(key: key);

  final List<Collection> collections;

  Widget _createCollectionCard(
      BuildContext context, Collection collection) {
    return GestureDetector(
      onTap: () => {
        Navigator.pushNamed(
          context,
          '/collection_viewer',
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
                return MediaIcon(collection.images[index]);
              }),
            ),
            ListTile(
              horizontalTitleGap: 0,
              title: ListTile(
                title: Transform(
                  transform: Matrix4.translationValues(
                      -16, 0.0, 0.0), // Fix the indention issue
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
    return ListView.builder(
      shrinkWrap: true,
      // This is needed for the shared media page
      // so that it doesn't scroll within the larger scrollable list
      physics: const ClampingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return _createCollectionCard(
            context, collections[index]);
      },
      itemCount: collections.length,
    );
  }

}


