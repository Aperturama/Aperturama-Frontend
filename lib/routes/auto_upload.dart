import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:aperturama/utils/media.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

import '../utils/main_drawer.dart';

class AutoUpload extends StatefulWidget {
  const AutoUpload({Key? key}) : super(key: key);

  @override
  State<AutoUpload> createState() => _AutoUploadState();
}

class _AutoUploadState extends State<AutoUpload> {

  List<Media> recentlyUploaded = [];
  List<MediaFolder> localMediaFolders = [];
  DateTime lastSync = DateTime.now();

  // Load settings from disk
  @override
  void initState() {
    super.initState();
    _loadAutomaticUploadSettings();
  }

  //Loading counter value on start
  void _loadAutomaticUploadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    String _recentlyUploadedString = prefs.getString("recentlyUploaded") ?? "";
    String _localMediaFoldersString = prefs.getString("localMediaFolders") ?? "";

    if(_recentlyUploadedString != "") {
      Map<String, dynamic> decodedList = jsonDecode(_recentlyUploadedString);
      List<dynamic> jsonList = decodedList['media'];

      // Convert to a list again
      List<Media> _recentlyUploadedList = [];
      jsonList.map((elem) => {
        jsonDecode(elem) as Media
      });

      setState(() {
        recentlyUploaded = jsonList as List<Media>;
      });
    }

    if(_recentlyUploadedString != "") {
      Map<String, dynamic> decodedList = jsonDecode(_localMediaFoldersString);
      List<dynamic> jsonList = decodedList['mediaFolders'];
      jsonList.map((elem) => jsonDecode(elem));

      setState(() {
        localMediaFolders = jsonList as List<MediaFolder>;
      });
    }
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

  Future<void> _handleAddingFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      // User did not cancel the picker

      // Add a new folder to the localMediaFolders
      localMediaFolders.add(MediaFolder(selectedDirectory, 0));

      // Rescan every folder for good measure
      _scanAllFolderContents();
    }
  }

  void _addFileToRecentlyUploaded(Media media) {
    recentlyUploaded.insert(0, media);
    if(recentlyUploaded.length > 64) {
      recentlyUploaded.removeAt(64);
    }
  }

  Future<void> _scanFolderContents(MediaFolder folder) async {
    String path = folder.path;

    List<FileSystemEntity> files = await dirContents(Directory(path));

    // Update the number of items in the directory
    folder.itemCount = 0;
    for (var f in files) {
      if(f is File) {
        folder.itemCount++;
      }
    }

    // Check if there are any unknown photos
    // TODO: Make a bunch of HTTP requests to the backend server

    // Add them to the recently uploaded list
    // TODO: Only if newly uploaded
    //_addFileToRecentlyUploaded(media);

    // Rerender the UI
    setState(() {});

  }

  Future<void> _scanAllFolderContents() async {
    for(MediaFolder m in localMediaFolders) {
      await _scanFolderContents(m);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
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
                  contentPadding: EdgeInsets.only(left: 14),
                  subtitle: Text("Last sync: " +
                      lastSync.year.toString() + "/" +
                      lastSync.month.toString() + "/" +
                      lastSync.day.toString() + " " +
                      ((lastSync.hour + 11) % 12 + 1).toString() + ":" +
                      lastSync.minute.toString() +
                      ((lastSync.hour >= 12) ? " pm" : " am")

                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.loop), // Resync button
                    onPressed: () {
                      // TODO: Actually trigger a resync
                      _scanAllFolderContents();
                      setState(() {
                        lastSync = DateTime.now();
                      });
                    },
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: FlutterLogo(size: 56.0),
                        title: const Text("path/Filename"),
                        subtitle: Text("Uploaded: 2022/04/05 11:25am"),
                      ),
                      ListTile(
                        leading: FlutterLogo(size: 56.0),
                        title: const Text("path/Filename"),
                        subtitle: Text("Uploaded: 2022/04/05 11:25am"),
                      ),
                      //CollectionList(snapshot.data!.collections),
                    ],
                  ),
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
                      _handleAddingFolder();
                    },
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    // This is needed for the shared media page
                    // so that it doesn't scroll within the larger scrollable list
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                          title: Text(localMediaFolders[index].path),
                          subtitle: Text(localMediaFolders[index].itemCount.toString() + " Item(s)"),
                          contentPadding: EdgeInsets.only(left: 14),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                localMediaFolders.removeAt(index);
                              });
                            },
                          ),
                      );
                        /*_createCollectionCard(
                          context, collections[index]);*/
                    },
                    itemCount: localMediaFolders.length,
                  )
                  /*ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: const Text("path"),
                        subtitle: Text("240 Items"),
                        contentPadding: EdgeInsets.only(left: 14),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            // TODO: Actually trigger a resync
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text("path"),
                        subtitle: Text("240 Items"),
                        contentPadding: EdgeInsets.only(left: 14),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            // TODO: Actually trigger a resync
                          },
                        ),
                      ),
                      //PhotoGrid(snapshot.data!.photos, _gridSize),
                    ],
                  ),*/
                ),
              ],
            ),
          ),
        ]),
        drawer: kIsWeb ? null : const MainDrawer());
  }
}
