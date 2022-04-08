import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:aperturama/utils/media.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


import '../utils/main_drawer.dart';

class AutoUpload extends StatefulWidget {
  const AutoUpload({Key? key}) : super(key: key);

  @override
  State<AutoUpload> createState() => _AutoUploadState();
}

class _AutoUploadState extends State<AutoUpload> {

  List<Media> recentlyUploaded = [];
  List<MediaFolder> localMediaFolders = [];

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
                  subtitle: Text("Last sync: 2022/04/05 11:25am"),
                  trailing: IconButton(
                    icon: const Icon(Icons.loop),
                    onPressed: () {
                      // TODO: Actually trigger a resync
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
                  title: const Text("Configured Folders"),
                  contentPadding: EdgeInsets.only(left: 14),
                  subtitle: Text("3 Folders"),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      // TODO: Actually trigger a resync
                    },
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
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
                  ),
                ),
              ],
            ),
          ),
        ]),
        drawer: kIsWeb ? null : const MainDrawer());
  }
}
