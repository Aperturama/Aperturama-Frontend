import 'package:flutter/material.dart';
import 'package:frontend/routes/auto_upload.dart';
import 'package:frontend/routes/collection_viewer.dart';
import 'package:frontend/routes/photos.dart';
import 'package:frontend/routes/settings.dart';
import 'package:frontend/routes/collections.dart';
import 'package:frontend/routes/shared.dart';
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
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/': (context) => const Photos(),
        '/photos': (context) => const Photos(),
        // When navigating to the "/second" route, build the SecondScreen widget.
        '/collections': (context) => const Collections(),
        '/collection_viewer': (context) => const CollectionViewer(),
        '/shared': (context) => const Shared(),
        '/auto_upload': (context) => const AutoUpload(),
        '/settings': (context) => const Settings(),
      },
    );
  }
}
