import 'package:flutter/material.dart';
import 'package:aperturama/utils/media.dart';
import 'package:flutter/services.dart';
import 'package:aperturama/utils/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import '../utils/user.dart';

class CollectionCreator extends StatefulWidget {
  const CollectionCreator({Key? key}) : super(key: key);

  @override
  State<CollectionCreator> createState() => _CollectionCreatorState();
}

class _CollectionCreatorState extends State<CollectionCreator> {
  final _formKey = GlobalKey<FormState>();

  var collectionNameController = TextEditingController();

  // Load info on first load
  @override
  void initState() {
    super.initState();
  }

  Future<bool> createCollection(String name) async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();
    http.Response resp;
    try {
      resp = await http.post(Uri.parse(serverAddress + '/api/v1/collections'),
        headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },
        body: { "name": name }
      );

      if(resp.statusCode != 200) {
        log("createCollection Non 200 status code: " + resp.statusCode.toString());
        return false;
      } else {
        return true;
      }

    } on SocketException {
      log("createCollection socket exception");
      return false;
    }

  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        height: MediaQuery.of(context).size.height / 1.2,
        width: MediaQuery.of(context).size.width / 1.1,
        child: Form(
          key: _formKey,
          child: Scrollbar(
            child: Align(
              alignment: Alignment.topCenter,
              child: Card(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            filled: true,
                            hintText: 'Enter a name for the collection.',
                            labelText: 'Collection Name',
                          ),
                          controller: collectionNameController,
                        ),
                        TextButton(
                          child: const Text('Create Collection'),
                          onPressed: () async {
                            if (await createCollection(collectionNameController.text)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Collection created')));
                              Navigator.pushReplacementNamed(context, '/collections');
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(content: Text('Failed to create collection')));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
