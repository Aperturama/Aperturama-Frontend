import 'package:flutter/material.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
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
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: const [
                    ListTile(
                      dense: true,
                      title: Text(
                        'Logged in as Hunter',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: Text(
                        '1268 Photos',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: Text(
                        '72 Videos',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: Text(
                        '13 Collections',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: Text(
                        '6 Shared Items',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: Text(
                        '30GB / 2TB Used',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
