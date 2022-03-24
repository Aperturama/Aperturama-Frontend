import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../utils/main_drawer.dart';

class Collections extends StatefulWidget {
  const Collections({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<Collections> createState() => _CollectionsState();
}

class _CollectionsState extends State<Collections> {

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("Collections"),
          centerTitle: true,
        ),
        body: Column(
          children: [
            GestureDetector(
              onTap: () => {
                Navigator.pushNamed(context, '/collection_viewer',
                  arguments: CollectionDetails(
                    'Collection 1',
                    '42 Photos, 0 Videos',
                  ),
                )
              },
              child: Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      children: List.generate(4, (index) {
                        return Center(
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: 'https://picsum.photos/250?random=' +
                                  index.toString(),
                              progressIndicatorBuilder:
                                  (context, url, downloadProgress) =>
                                  CircularProgressIndicator(
                                      value: downloadProgress.progress),
                              errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                            ),
                          ),
                        );
                      }),
                    ),
                    ListTile(
                      horizontalTitleGap: 0,
                      title: ListTile(
                        title: Transform(
                          transform: Matrix4.translationValues(-16, 0.0, 0.0), // Fix the indention issue
                          child: Text('Collection 1'),
                        ),
                        trailing: Text('Shared'),
                      ),
                      subtitle: Text('42 Photos, 0 Videos'),
                      contentPadding: EdgeInsets.only(left: 14, bottom: 10),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 4,
                    children: List.generate(4, (index) {
                      return Center(
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: 'https://picsum.photos/250?random=' +
                                index.toString() * 2,
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) =>
                                CircularProgressIndicator(
                                    value: downloadProgress.progress),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                          ),
                        ),
                      );
                    }),
                  ),
                  ListTile(
                    horizontalTitleGap: 0,
                    title: ListTile(
                      title: Transform(
                        transform: Matrix4.translationValues(-16, 0.0, 0.0), // Fix the indention issue
                        child: Text('Collection 2'),
                      ),
                    ),
                    subtitle: Text('6 Photos, 9 Videos'),
                    contentPadding: EdgeInsets.only(left: 14, bottom: 10),
                  ),
                ],
              ),
            ),
            Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 4,
                    children: List.generate(4, (index) {
                      return Center(
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: 'https://picsum.photos/250?random=' +
                                index.toString() * 3,
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) =>
                                CircularProgressIndicator(
                                    value: downloadProgress.progress),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                          ),
                        ),
                      );
                    }),
                  ),
                  ListTile(
                    horizontalTitleGap: 0,
                    title: ListTile(
                      title: Transform(
                        transform: Matrix4.translationValues(-16, 0.0, 0.0), // Fix the indention issue
                        child: Text('Collection 3'),
                      ),
                    ),
                    subtitle: Text('5 Photos, 6 Videos'),
                    contentPadding: EdgeInsets.only(left: 14, bottom: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        drawer: const MainDrawer());
  }
}


class CollectionDetails {
  final String title;
  final String message;

  CollectionDetails(this.title, this.message);
}