import 'package:aperturama/utils/media.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class MediaViewer extends StatefulWidget {
  const MediaViewer({Key? key}) : super(key: key);

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  double _maxScale = 1;
  late Media media;
  String jwt = "";
  String code = "";

  // Load info on first load
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    // Take in information about the current media given as args,
    // or set it to no media if the args are invalid for some reason
    if(ModalRoute.of(context)!.settings.arguments != null) {
      var args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      media = args["media"];
      jwt = args.containsKey("jwt") ? args["jwt"] : "";
      code = args.containsKey("code") ? args["code"] : "";
    } else {
      media = Media("", MediaType.photo, "", "");
      // Todo: Probably navigate back to the /photos page
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Media Viewer"),
        centerTitle: true,
        actions: [
          (code != "") ? const Text("") : IconButton( // Hide settings if the code is used
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/media_settings',
                arguments: <String, dynamic>{
                  'media': media,
                  'jwt': jwt,
                  'code': "",
                },
              );
            },
            tooltip: 'Media Information and Settings',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: _maxScale,
          child: CachedNetworkImage(
            httpHeaders: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },
            imageUrl: media.highresURL + (code.isEmpty ? "" : "?code=" + code),
            // Make the image fit the width
            imageBuilder: (context, imageProvider) {
              WidgetsBinding.instance?.addPostFrameCallback((_) => setState(() {
                    _maxScale = 16;
                  }));
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              );
            },
            // Show the low res thumbnail while waiting for the high res to load
            progressIndicatorBuilder: (context, url, downloadProgress) => Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Low-res thumbnail
                CachedNetworkImage(
                  httpHeaders: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },
                  imageUrl: media.thumbnailURL + (code.isEmpty ? "" : "?code=" + code),
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      CircularProgressIndicator(
                          value: downloadProgress.progress),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  // Make the image fit the width
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),
                // Show the progress indicator on top of the low-res pic
                CircularProgressIndicator(value: downloadProgress.progress),
              ],
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        )
      )
    );
  }
}
