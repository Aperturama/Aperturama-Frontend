import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:aperturama/utils/media.dart';

class SharedItemAccess extends StatefulWidget {
  const SharedItemAccess({Key? key, required this.code, required this.collection, required this.media})
      : super(key: key);

  final String code;
  final String collection;
  final String media;

  @override
  State<SharedItemAccess> createState() => _SharedItemAccessState();
}

class _SharedItemAccessState extends State<SharedItemAccess> {
  bool initialDataPending = true;

  @override
  void initState() {
    super.initState();
    redirect();
  }

  Future<void> redirect() async {
    // Check to make sure there's a code
    if (widget.code == "") {
      // Actually just end here, this will show the error message
      setState(() {
        initialDataPending = false;
      });
    } else {
      // There is a code, let's see if we've got a collection or media
      if (widget.collection != "" && widget.media == "") {
        // This is a collection, we need to query for it
        http.Response resp;
        try {
          resp = await http.get(Uri.parse('/api/v1/collections/' + widget.collection));

          if(resp.statusCode != 200) {
            log("Collection listing failed: Code " + resp.statusCode.toString());
            // Show the error message
            setState(() {
              initialDataPending = false;
            });

          } else {
            // Got the data
            final responseJson = jsonDecode(resp.body);
            Collection c = Collection(responseJson["name"], "", widget.collection, false, responseJson["media"]);

            // Let's go there
            Navigator.pushNamed(context, '/collection_viewer', arguments: <String, dynamic>{
              'collection': c,
              'jwt': "",
              'code': widget.code,
            });
          }

        } on SocketException {
          log("Collection listing failed: Socket exception");
          // Show the error message
          setState(() {
            initialDataPending = false;
          });
        }

      } else if (widget.collection == "" && widget.media != "") {
        // This is a media item

        Media m = Media(
          widget.media, MediaType.photo,
          "/api/v1/media/" + widget.media + '/thumbnail',
          "/api/v1/media/" + widget.media + '/media',
        );

        // Let's go there
        Navigator.pushNamed(context, '/media_viewer', arguments: <String, dynamic>{
          'media': m,
          'jwt': "",
          'code': widget.code,
        });

      } else {
        // Seems they did something wrong, like having both/no collection and/or media set
        // Show the error message
        setState(() {
          initialDataPending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Shared Media"),
          centerTitle: true,
        ),
        body: (initialDataPending)
            ? const Center(child: CircularProgressIndicator())
            : const Text("Shared media item not found"));
  }
}
