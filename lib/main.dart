import 'package:aperturama/routes/login.dart';
import 'package:aperturama/routes/media_viewer.dart';
import 'package:flutter/material.dart';
import 'package:aperturama/routes/auto_upload.dart';
import 'package:aperturama/routes/collection_viewer.dart';
import 'package:aperturama/routes/media_list.dart';
import 'package:aperturama/routes/settings.dart';
import 'package:aperturama/routes/collections_list.dart';
import 'package:aperturama/routes/shared.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aperturama',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AppLogin(),
        '/media': (context) => const MediaList(),
        '/media_viewer': (context) => const MediaViewer(),
        '/collections': (context) => const Collections(),
        '/collection_viewer': (context) => const CollectionViewer(),
        '/shared': (context) => const Shared(),
        '/auto_upload': (context) => const AutoUpload(),
        '/settings': (context) => const AppSettings(),
      },
    );
  }
}
