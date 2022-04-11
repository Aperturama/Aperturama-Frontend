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

import '../utils/main_drawer.dart';

class AutoUpload extends StatefulWidget {
  const AutoUpload({Key? key}) : super(key: key);

  @override
  State<AutoUpload> createState() => _AutoUploadState();
}

class _AutoUploadState extends State<AutoUpload> {

  List<Media> recentlyUploaded = [];
  List<MediaFolder> localMediaFolders = [];
  DateTime lastSync = DateTime.parse("1970-01-01 00:00:00");

  // Load settings from disk
  @override
  void initState() {
    super.initState();
    _loadAutomaticUploadSettings();
  }

  void _loadAutomaticUploadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    String _recentlyUploadedString = prefs.getString("recentlyUploaded") ?? "";
    String _localMediaFoldersString = prefs.getString("localMediaFolders") ?? "";

    log("Loading preferences");
    log(_recentlyUploadedString);
    log(_localMediaFoldersString);

    if(_recentlyUploadedString != "") {
      //Map<String, dynamic> decodedList = jsonDecode(_recentlyUploadedString);
      //List<dynamic> jsonList = decodedList['media'];
      List<dynamic> jsonList = jsonDecode(_recentlyUploadedString);

/*      // Convert to a list again
      List<Media> _recentlyUploadedList = [];
      jsonList.map<Media>((elem) => {
        jsonDecode(elem) as Media
      }).toList();

      log(jsonList.toString());

      setState(() {
        recentlyUploaded = jsonList as List<Media>;
      });*/

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

    prefs.setString("recentlyUploaded", _recentlyUploadedJSON);
    prefs.setString("localMediaFolders", _localMediaFoldersJSON);
    prefs.setString("lastSync", lastSync.toIso8601String());

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

  Future<void> _scanFolderContents(MediaFolder folder) async {
    String path = folder.path;

    List<FileSystemEntity> files = await dirContents(Directory(path));

    // Update the number of items in the directory
    folder.itemCount = 0;
    for (var f in files) {
      if(f is File) {
        folder.itemCount++;

        // Add them to the recently uploaded list
        // TODO: Only if newly uploaded
        Media m = Media.uploaded(
          folder.itemCount.toString(), MediaType.photo,
          'https://picsum.photos/seed/' + folder.itemCount.toString() + '/256',
          'https://picsum.photos/seed/' + folder.itemCount.toString() + '/4096',
          f.path,
          DateTime.now()
        );
        _addMediaToRecentlyUploaded(m);
      }
    }

    // Check if there are any unknown photos
    // TODO: Make a bunch of HTTP requests to the backend server

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
                        icon: const Icon(Icons.clear), // Clear recents button
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
                  child: /*ListView(
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
                  )*/
                  recentlyUploaded.isNotEmpty ? ListView.builder(
                    shrinkWrap: true,
                    // This is needed for the shared media page
                    // so that it doesn't scroll within the larger scrollable list
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        leading: Container(
                            width: 56,
                            height: 56,
                            child: MediaIcon(recentlyUploaded[index])),
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
                      /*_createCollectionCard(
                          context, collections[index]);*/
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
                        /*_createCollectionCard(
                          context, collections[index]);*/
                    },
                    itemCount: localMediaFolders.length,
                  )
                      : const Text("No configured folders."),
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
