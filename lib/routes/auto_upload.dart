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
import 'package:http_parser/http_parser.dart' as http_parser;
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
  DateTime lastSync = DateTime.parse("1970-01-01 00:00:00"); // Default value because null doesn't work
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

    // Deserialize the recently uploaded media list
    if (_recentlyUploadedString != "") {
      List<dynamic> jsonList = jsonDecode(_recentlyUploadedString);
      for (var j in jsonList) {
        Media m = Media.fromJson(j);
        recentlyUploaded.add(m);
      }
      setState(() {});
    }

    // Deserialize the local media folders list
    if (_localMediaFoldersString != "") {
      List<dynamic> jsonList = jsonDecode(_localMediaFoldersString);
      for (var m in jsonList) {
        MediaFolder mf = MediaFolder.fromJson(m);
        localMediaFolders.add(mf);
      }
      setState(() {});
    }

    // Set the last sync time
    setState(() {
      lastSync = DateTime.parse(prefs.getString("lastSync") ?? "1970-01-01 00:00:00");
    });
  }

  void _saveAutomaticUploadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    String _recentlyUploadedJSON = jsonEncode(recentlyUploaded);
    String _localMediaFoldersJSON = jsonEncode(localMediaFolders);

    await prefs.setString("recentlyUploaded", _recentlyUploadedJSON);
    await prefs.setString("localMediaFolders", _localMediaFoldersJSON);
    await prefs.setString("lastSync", lastSync.toIso8601String());
  }

  // Function to return a list of the contents of a directory
  Future<List<FileSystemEntity>> dirContents(Directory dir) {
    var files = <FileSystemEntity>[];
    var completer = Completer<List<FileSystemEntity>>();
    var lister = dir.list(recursive: true);
    lister.listen((file) => files.add(file),
        onError: (o) => log("An error occurred listing files in directory."),
        onDone: () => completer.complete(files));
    return completer.future;
  }

  // Called when the user tries to add a new folder to sync
  Future<void> _handleAddingFolder(BuildContext context) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      // User did not cancel the picker

      // Add a new folder to the localMediaFolders
      localMediaFolders.add(MediaFolder(selectedDirectory, 0));

      // Rescan every folder (including this new one) for good measure
      _scanAllFolderContents();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Folder added, rescanning all folders...")));
    } else {
      // User cancelled the folder picker
      // Show a little message at the bottom of the screen
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cancelled.")));
    }
  }

  // Called when the user taps the button to remove the folder
  Future<void> _handleRemovingFolder(BuildContext context, int index) async {
    setState(() {
      localMediaFolders.removeAt(index);
    });
    _saveAutomaticUploadSettings();
    // Show a little message at the bottom of the screen
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Folder removed.")));
  }

  // Called when the scanning process finds and finishes uploading a new media item
  // Deletes the oldest item when the list is 64 files long
  void _addMediaToRecentlyUploaded(Media media) {
    recentlyUploaded.insert(0, media);
    if (recentlyUploaded.length > 64) {
      recentlyUploaded.removeAt(64);
    }
  }

  // Used to hash the file with sha256 to determine whether it's new to the server or not
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

  // Used to scan an individual folder for new media items and upload them to the server if so
  Future<void> _scanFolderContents(MediaFolder folder) async {
    List<FileSystemEntity> files = await dirContents(Directory(folder.path));
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();

    // Reset the number of items in the directory and update through iteration
    folder.itemCount = 0;

    // Iterate over every item
    for (var f in files) {
      if (f is File) {
        folder.itemCount++;

        // Check if the file is an image
        String extension = p.extension(f.path, 1).substring(1);
        if (extension == "jpg") extension = "jpeg";
        if (["jpeg", "png", "gif"].contains(extension)) {
          // This is an image, let's hash it and see if the server has it
          final hash = await getFileSha256(f.path);
          final hashBase64UrlSafe = base64Url.encode(hash.bytes);

          // Send a request to the backend with the photo's hash for comparison
          var resp = await http.get(
            Uri.parse(serverAddress + '/api/v1/media/checkhash?hash=' + hash.toString()),
            headers: {HttpHeaders.authorizationHeader: 'Bearer ' + jwt},
          );

          if (resp.statusCode == 304) {
            // Found the image already, skip processing
            continue;
          } else if (resp.statusCode == 204) {
            // Image not found, upload it!

            // Send a request to the backend with the photo
            var postUri = Uri.parse(serverAddress + '/api/v1/media');
            var request = http.MultipartRequest("POST", postUri);
            request.headers['authorization'] = 'Bearer ' + jwt;
            request.files.add(http.MultipartFile.fromBytes('mediafile', await File.fromUri(f.uri).readAsBytes(),
                contentType: http_parser.MediaType('image', extension), filename: p.basename(f.path)));
            await request.send().then((streamedResponse) async {
              if (streamedResponse.statusCode == 200) {
                // Success, get the ID for our recently uploaded list
                var response = await http.Response.fromStream(streamedResponse);
                // Add them to the recently uploaded list
                String id = jsonDecode(response.body)["media_id"].toString();
                Media m = Media.uploaded(id, MediaType.photo, serverAddress + "/api/v1/media/" + id + '/thumbnail',
                    serverAddress + "/api/v1/media/" + id + '/media', f.path, DateTime.now());
                _addMediaToRecentlyUploaded(m);
              } else {
                log("Failed to upload " + f.uri.toString() + ", code: " + streamedResponse.statusCode.toString());
                // TODO: Report this to the user somehow
              }
            });

            // Rerender the UI after each image so progress can be seen
            setState(() {});

          } else {
            log("Media hash check failed: Code " + resp.statusCode.toString());
            continue;
          }
        }
      }
    }

    // Rerender the UI again for good measure, although probably not necessary
    setState(() {});
  }

  // Called after adding a folder, or when manually resyncing to check all folders for new media
  Future<void> _scanAllFolderContents() async {
    // Scan each folder
    for (MediaFolder m in localMediaFolders) {
      await _scanFolderContents(m);
    }

    // Update the last synced time once done
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
                // Recently uploaded header
                ListTile(
                  horizontalTitleGap: 0,
                  title: const Text("Recently Uploaded"),
                  contentPadding: const EdgeInsets.only(left: 14),
                  subtitle: Text("Last sync: " +
                      (lastSync.year != 1970
                          ? lastSync.year.toString() +
                              "/" +
                              lastSync.month.toString() +
                              "/" +
                              lastSync.day.toString() +
                              " " +
                              ((lastSync.hour + 11) % 12 + 1).toString() +
                              ":" +
                              lastSync.minute.toString().padLeft(2, '0') +
                              ((lastSync.hour >= 12) ? " pm" : " am")
                          : "Never")),
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
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Cleared recently uploaded list.')));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.loop), // Resync button
                        onPressed: () {
                          _scanAllFolderContents();
                          // Show a little message at the bottom of the screen
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resyncing...')));
                        },
                      ),
                    ],
                  ),
                ),

                // Recently uploaded list
                const Divider(),
                Expanded(
                  child: recentlyUploaded.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, int index) {
                            return ListTile(
                              leading:
                                  SizedBox(width: 56, height: 56, child: MediaIcon(recentlyUploaded[index], jwt, "")),
                              title: Text(recentlyUploaded[index].localPath),
                              subtitle: Text("Uploaded: " +
                                  recentlyUploaded[index].uploadedTimestamp.year.toString() +
                                  "/" +
                                  recentlyUploaded[index].uploadedTimestamp.month.toString() +
                                  "/" +
                                  recentlyUploaded[index].uploadedTimestamp.day.toString() +
                                  " " +
                                  ((recentlyUploaded[index].uploadedTimestamp.hour + 11) % 12 + 1).toString() +
                                  ":" +
                                  recentlyUploaded[index].uploadedTimestamp.minute.toString().padLeft(2, '0') +
                                  ((recentlyUploaded[index].uploadedTimestamp.hour >= 12) ? " pm" : " am")),
                            );
                          },
                          itemCount: recentlyUploaded.length,
                        )
                      : const Text("No recently uploaded media items."),
                ),

                // Header for automatic upload configuration
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

                // Automatic upload folder list
                const Divider(),
                Expanded(
                  child: localMediaFolders.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
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
