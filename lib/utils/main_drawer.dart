import 'package:flutter/material.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({Key? key}) : super(key: key);

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
    return Drawer(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible( // Menu options at the top of the screen
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text('Photos'),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/photos');
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
        ));
  }
}
