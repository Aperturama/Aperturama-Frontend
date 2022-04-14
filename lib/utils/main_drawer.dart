import 'dart:convert';

import 'package:aperturama/utils/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class MainDrawer extends StatefulWidget {
  const MainDrawer({Key? key}) : super(key: key);

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {

  int photos = 0;
  int collections = 0;
  int sharedItems = 0;
  int storageUsed = 0;
  String storageUsedUnit = "";
  int storageMax = 0;
  String storageMaxUnit = "";

  void _populateStats() async {
    String jwt = await User.getJWT();
    String serverAddress = await User.getServerAddress();
    http.Response resp = await http.get(Uri.parse(serverAddress + '/api/v1/stats'), headers: {"Authorization": "Bearer " + jwt});
    Map<String, String> data = jsonDecode(resp.body);
    photos = int.parse(data["photos"] ?? "0");
    sharedItems = int.parse(data["sharedItems"] ?? "0");
    storageUsed = int.parse(data["storageUsed"] ?? "0");
    storageUsedUnit = data["storageUsedUnit"] ?? "B";
    storageMax = int.parse(data["storageMax"] ?? "0");
    storageMaxUnit = data["storageMaxUnit"] ?? "B";
    setState(() {});
  }

  // Load info on first load
  @override
  void initState() {
    super.initState();
    _populateStats();
  }


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
              Flexible( // Menu options at the top of the screen
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
              const Divider(height: 1.0),
              ListView( // Stats at the bottom of the screen
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  statPad(),
                  stat('Logged in as Hunter'),
                  stat('1268 Photos'),
                  stat('13 Collections'),
                  stat('6 Shared Items'),
                  stat('30GB / 2TB Used'),
                  statPad(),
                ],
              ),
            ],
          )),
    );
  }
}
