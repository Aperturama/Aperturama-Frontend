import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:aperturama/routes/media_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:aperturama/utils/media.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as httpParser;
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:async/async.dart';
import 'package:convert/convert.dart';

import '../utils/main_drawer.dart';
import '../utils/user.dart';

class AutoUpload extends StatefulWidget {
  const AutoUpload({Key? key}) : super(key: key);

  @override
  State<AutoUpload> createState() => _AutoUploadState();
}

class _AutoUploadState extends State<AutoUpload> {

  List<Media> recentlyUploaded = [];
  List<MediaFolder> localMediaFolders = [];
  DateTime lastSync = DateTime.parse("1970-01-01 00:00:00");
  String jwt = "";

  // Load settings from disk on first load
  @override
  void initState() {
    super.initState();
    _loadAutomaticUploadSettings();
  }

  void _loadAutomaticUploadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    jwt = await User.getJWT();

    String _recentlyUploadedString = prefs.getString("recentlyUploaded") ?? "";
    String _localMediaFoldersString = prefs.getString("localMediaFolders") ?? "";

    log("Loading preferences");
    log(_recentlyUploadedString);
    log(_localMediaFoldersString);

    if(_recentlyUploadedString != "") {
      List<dynamic> jsonList = jsonDecode(_recentlyUploadedString);
      for(var j in jsonList) {
        Media m = Media.fromJson(j);
        recentlyUploaded.add(m);
      }
      setState(() {});
    }

    if(_localMediaFoldersString != "") {
      List<dynamic> jsonList = jsonDecode(_localMediaFoldersString);
      for(var m in jsonList) {
        MediaFolder mf = MediaFolder.fromJson(m);
        localMediaFolders.add(mf);
      }
      setState(() {});
    }

    setState(() {
      lastSync = DateTime.parse(prefs.getString("lastSync") ?? "1970-01-01 00:00:00");
    });
    log("Loaded Preferences");
  }

  void _saveAutomaticUploadSettings() async {
    log("Saving Preferences");
    final prefs = await SharedPreferences.getInstance();

    String _recentlyUploadedJSON = jsonEncode(recentlyUploaded);
    String _localMediaFoldersJSON = jsonEncode(localMediaFolders);

    log(_recentlyUploadedJSON);
    log(_localMediaFoldersJSON);

    await prefs.setString("recentlyUploaded", _recentlyUploadedJSON);
    await prefs.setString("localMediaFolders", _localMediaFoldersJSON);
    await prefs.setString("lastSync", lastSync.toIso8601String());

    log("Saved Preferences");
  }


  Future<List<FileSystemEntity>> dirContents(Directory dir) {
    var files = <FileSystemEntity>[];
    var completer = Completer<List<FileSystemEntity>>();
    var lister = dir.list(recursive: true);
    lister.listen (
            (file) => files.add(file),
        // should also register onError
        onDone:   () => completer.complete(files)
    );
    return completer.future;
  }

  Future<void> _handleAddingFolder(BuildContext context) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      // User did not cancel the picker

      // Add a new folder to the localMediaFolders
      localMediaFolders.add(MediaFolder(selectedDirectory, 0));

      // Rescan every folder for good measure
      _scanAllFolderContents();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Folder added, rescanning all folders...")));

    } else {
      // Show a little message at the bottom of the screen
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Cancelled.")));
    }
  }

  Future<void> _handleRemovingFolder(BuildContext context, int index) async {
    setState(() {
      localMediaFolders.removeAt(index);
    });
    _saveAutomaticUploadSettings();
    // Show a little message at the bottom of the screen
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Folder removed.")));
  }

  void _addMediaToRecentlyUploaded(Media media) {
    recentlyUploaded.insert(0, media);
    if(recentlyUploaded.length > 64) {
      recentlyUploaded.removeAt(64);
    }
  }

  // From https://djangocas.dev/blog/flutter/calculate-file-crypto-hash-sha1-sha256-sha512/
  Future<Digest> getFileSha256(String path) async {
    final reader = ChunkedStreamReader(File(path).openRead());
    const chunkSize = 4096;
    var output = AccumulatorSink<Digest>();
    var input = sha256.startChunkedConversion(output);

    try {
      while (true) {
        final chunk = await reader.readChunk(chunkSize);
        if (chunk.isEmpty) {
          // indicate end of file
          break;
        }
        input.add(chunk);
      }
    } finally {
      // We always cancel the ChunkedStreamReader,
      // this ensures the underlying stream is cancelled.
      reader.cancel();
    }

    input.close();

    return output.events.single;
  }

  Future<void> _scanFolderContents(MediaFolder folder) async {
    List<FileSystemEntity> files = await dirContents(Directory(folder.path));
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();

    // Update the number of items in the directory and upload as necessary
    folder.itemCount = 0;
    for (var f in files) {
      if(f is File) {
        folder.itemCount++;

        log("Processing file " + f.path);

        // Check if there are any unknown photos
        // TODO: Make a bunch of HTTP requests to the backend server
        // Send a request to the backend with the photo

        String extension = p.extension(f.path, 1).substring(1);
        if(extension == "jpg") extension = "jpeg";
        if(["jpeg", "png", "gif"].contains(extension)) {
          log("Found image to check");
          // This is an image, let's hash it and see if the server has it
          final hash = await getFileSha256(f.path);
          final hashBase64UrlSafe = base64Url.encode(hash.bytes);
          log("sha256 hash hex in lowercase: ${hash.toString()}");
          log("sha256 hash base64 url safe: $hashBase64UrlSafe");

          var resp = await http.get(Uri.parse(serverAddress + '/api/v1/media/checkhash?hash=' + hash.toString()),
            headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },
          );

          if(resp.statusCode == 304) {
            // Found the image already, skip processing
            log("Image already uploaded, ignoring");
            continue;
          } else if(resp.statusCode == 204) {
            // Image not found, upload it!
            log("New image to upload!");

            var postUri = Uri.parse(serverAddress + '/api/v1/media');
            var request = http.MultipartRequest("POST", postUri);
            request.headers['authorization'] = 'Bearer ' + jwt;
            request.files.add(http.MultipartFile.fromBytes('mediafile',
                await File.fromUri(f.uri).readAsBytes(),
                contentType: httpParser.MediaType('image', extension),
            filename: p.basename(f.path)));

            await request.send().then((streamedResponse) async {
              if (streamedResponse.statusCode == 200) {
                log("Uploaded " + f.uri.toString());
                var response = await http.Response.fromStream(streamedResponse);
                log(response.toString());
                // Add them to the recently uploaded list
                String id = jsonDecode(response.body)["media_id"].toString();
                Media m = Media.uploaded(
                    id, MediaType.photo,
                    serverAddress + "/api/v1/media/" + id + '/thumbnail',
                    serverAddress + "/api/v1/media/" + id + '/media',
                    f.path,
                    DateTime.now()
                );
                _addMediaToRecentlyUploaded(m);

              } else {
                log("Failed to upload " + f.uri.toString() + ", code: " + streamedResponse.statusCode.toString());
              }
            });

            // Rerender the UI
            setState(() {});

          } else {
            log("Media hash check failed: Code " + resp.statusCode.toString());
            continue;
          }

        } else {
          log("Non-image found");
        }

      }
    }

    // Rerender the UI
    setState(() {});

  }

  Future<void> _scanAllFolderContents() async {
    // Scan each folder
    for(MediaFolder m in localMediaFolders) {
      await _scanFolderContents(m);
    }

    // Update the last synced time
    setState(() {
      lastSync = DateTime.now();
    });

    // Save everything to local storage
    _saveAutomaticUploadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Automatic Upload"),
          centerTitle: true,
        ),
        body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            child: kIsWeb ? const MainDrawer() : null,
          ),
          Expanded(
            child: Column(
              children: [
                ListTile(
                  horizontalTitleGap: 0,
                  title: const Text("Recently Uploaded"),
                  contentPadding: const EdgeInsets.only(left: 14),
                  subtitle: Text("Last sync: " + (lastSync.year != 1970 ?
                      lastSync.year.toString() + "/" +
                      lastSync.month.toString() + "/" +
                      lastSync.day.toString() + " " +
                      ((lastSync.hour + 11) % 12 + 1).toString() + ":" +
                      lastSync.minute.toString().padLeft(2, '0') +
                      ((lastSync.hour >= 12) ? " pm" : " am")
                      : "Never")

                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.clear), // Clear recent uploads button
                        onPressed: () {
                          setState(() {
                            recentlyUploaded.clear();
                          });
                          _saveAutomaticUploadSettings();
                          // Show a little message at the bottom of the screen
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Cleared recently uploaded list.')));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.loop), // Resync button
                        onPressed: () {
                          _scanAllFolderContents();
                          // Show a little message at the bottom of the screen
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Resyncing...')));
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: recentlyUploaded.isNotEmpty ? ListView.builder(
                    shrinkWrap: true,
                    // This is needed for the shared media page
                    // so that it doesn't scroll within the larger scrollable list
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        leading: SizedBox(
                            width: 56,
                            height: 56,
                            child: MediaIcon(recentlyUploaded[index], jwt, "")),
                        title: Text(recentlyUploaded[index].localPath),
                        subtitle: Text("Uploaded: " +
                            recentlyUploaded[index].uploadedTimestamp.year.toString() + "/" +
                            recentlyUploaded[index].uploadedTimestamp.month.toString() + "/" +
                            recentlyUploaded[index].uploadedTimestamp.day.toString() + " " +
                            ((recentlyUploaded[index].uploadedTimestamp.hour + 11) % 12 + 1).toString() + ":" +
                            recentlyUploaded[index].uploadedTimestamp.minute.toString().padLeft(2, '0') +
                            ((recentlyUploaded[index].uploadedTimestamp.hour >= 12) ? " pm" : " am")
                        ),
                      );
                    },
                    itemCount: recentlyUploaded.length,
                  )
                  : const Text("No recently uploaded media items."),
                ),
                const Divider(),
                ListTile(
                  horizontalTitleGap: 0,
                  title: const Text("Folders Configured for Automatic Upload"),
                  contentPadding: const EdgeInsets.only(left: 14),
                  subtitle: Text(localMediaFolders.length.toString() + " Folders"),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      _handleAddingFolder(context);
                    },
                  ),
                ),
                const Divider(),
                Expanded(
                  child: localMediaFolders.isNotEmpty ? ListView.builder(
                    shrinkWrap: true,
                    // This is needed for the shared media page
                    // so that it doesn't scroll within the larger scrollable list
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                          title: Text(localMediaFolders[index].path),
                          subtitle: Text(localMediaFolders[index].itemCount.toString() + " Item(s)"),
                          contentPadding: const EdgeInsets.only(left: 14),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              _handleRemovingFolder(context, index);
                            },
                          ),
                      );
                    },
                    itemCount: localMediaFolders.length,
                  )
                      : const Text("No configured folders."),
                ),
              ],
            ),
          ),
        ]),
        drawer: kIsWeb ? null : const MainDrawer());
  }
}
