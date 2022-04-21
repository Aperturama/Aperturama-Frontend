import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'package:aperturama/utils/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MainDrawer extends StatefulWidget {
  const MainDrawer({Key? key}) : super(key: key);

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {

  int numPhotos = 0;
  int numCollections = 0;
  int numSharedItems = 0;
  int storageUsed = 0;
  int storageTotal = 0;
  String firstName = "";
  bool initialDataPending = true;

  // Sourced from https://gist.github.com/zzpmaster/ec51afdbbfa5b2bf6ced13374ff891d9
  static String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return ((bytes / math.pow(1024, i)).toStringAsFixed(decimals)) +
        '' + suffixes[i];
  }

  // Queries the backend for stats about the user and their data storage
  void _populateStats() async {
    String jwt = await User.getJWT();
    String serverAddress = await User.getServerAddress();
    firstName = await User.getFirstName();

    http.Response resp;
    try {
      resp = await http.get(Uri.parse(serverAddress + '/api/v1/user/statistics'),
          headers: {"Authorization": "Bearer " + jwt});
      if(resp.statusCode == 200) {
        // Success, do a login now
        Map<String, dynamic> data = jsonDecode(resp.body);

        numPhotos = data["n_media"] ?? 0;
        numCollections = data["n_collections"] ?? 0;
        numSharedItems = data["n_shared"] ?? 0;
        storageUsed = data["bytes_used"] ?? 0;
        storageTotal = data["bytes_total"] ?? 0;
        initialDataPending = false;
        setState(() {});

      } else {
        log("Non 200 Main Drawer status code: " + resp.statusCode.toString());
      }

    } on SocketException {
      log("Main Drawer socket exception");
    }
  }

  // Load info on first load
  @override
  void initState() {
    super.initState();
    _populateStats();
  }

  // Small wrapper widget to make some nice padding between stats
  Widget stat(String t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      child: Text(t,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }

  // Small widget to insert some padding between the divider and the bottom of the screen
  Widget statPad() {
    return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 0)
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 215,
      child: Drawer(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Menu options at the top of the screen
            Flexible(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text('Photos and Videos'),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/media');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.collections),
                    title: const Text('Collections'),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/collections');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_shared),
                    title: const Text('Shared with me'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/shared');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.autorenew),
                    title: const Text('Auto upload'),
                    onTap: () {
                      Navigator.pushNamed(context, '/auto_upload');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),
            ),
            // Stats at the bottom of the screen
            const Divider(height: 1.0),
            if (initialDataPending)
              const CircularProgressIndicator()
            else
              ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  statPad(),
                  stat('Logged in as ' + firstName),
                  stat(numPhotos.toString() + ' Photos'),
                  stat(numCollections.toString() + ' Collections'),
                  stat(numSharedItems.toString() + ' Shared Items'),
                  stat(formatBytes(storageUsed, 0) + " Used / " + formatBytes(storageTotal, 0) + " Total"),
                  statPad(),
                ],
              ),
          ],
        )),
    );
  }
}
