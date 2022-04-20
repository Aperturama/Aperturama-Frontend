import 'package:aperturama/routes/collection_creator.dart';
import 'package:aperturama/routes/collection_media_manager.dart';
import 'package:aperturama/routes/collection_settings.dart';
import 'package:aperturama/routes/login.dart';
import 'package:aperturama/routes/media_settings.dart';
import 'package:aperturama/routes/media_viewer.dart';
import 'package:aperturama/routes/shared_item_access.dart';
import 'package:flutter/material.dart';
import 'package:aperturama/routes/auto_upload.dart';
import 'package:aperturama/routes/collection_viewer.dart';
import 'package:aperturama/routes/media_list.dart';
import 'package:aperturama/routes/settings.dart';
import 'package:aperturama/routes/collections_list.dart';
import 'package:aperturama/routes/shared.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';



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
        '/media_settings': (context) => const MediaSettings(),
        '/collections': (context) => const Collections(),
        '/collections/new': (context) => const CollectionCreator(),
        '/collection_viewer': (context) => const CollectionViewer(),
        '/collection_settings': (context) => const CollectionSettings(),
        '/collection_media_manager': (context) => const CollectionMediaManager(),
        '/shared': (context) => const Shared(),
        '/auto_upload': (context) => const AutoUpload(),
        '/settings': (context) => const AppSettings(),
        //'/s': (context) => const SharedItemAccess(),
      },
      onGenerateRoute: (settings) {
        String sname = settings.name ?? "No name";

        // Check the page URL to see if it is a shared media/collection link
        if (sname.startsWith("/s?")) {
          // Must be the shared media route
          final settingsUri = Uri.parse(sname);
          final String code = settingsUri.queryParameters['code'] ?? "";
          final String collection = settingsUri.queryParameters['collection'] ?? "";
          final String media = settingsUri.queryParameters['media'] ?? "";
          return MaterialPageRoute(
              builder: (context) {
                return SharedItemAccess(code: code, collection: collection, media: media);
              },
          );

        } else {
          // Unknown route, return them to the login page
          return MaterialPageRoute(
            builder: (context) {
              return const AppLogin();
            },
          );
        }
      },
    );
  }
}
