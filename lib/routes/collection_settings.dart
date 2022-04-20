import 'package:flutter/material.dart';
import 'package:aperturama/utils/media.dart';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../utils/user.dart';

class CollectionSettings extends StatefulWidget {
  const CollectionSettings({Key? key}) : super(key: key);

  @override
  State<CollectionSettings> createState() => _CollectionSettingsState();
}

class _CollectionSettingsState extends State<CollectionSettings> {
  final _formKey = GlobalKey<FormState>();
  bool sharingEnabled = true;
  late Collection collection;

  bool initialDataPending = true;

  var sharingLinkController = TextEditingController();
  var sharingUserController = TextEditingController();
  var sharingCanEdit = false;

  String jwt = "";

  // Load info on first load
  @override
  void initState() {
    super.initState();
    _getCollectionInfo();
  }

  Future<void> _getCollectionInfo() async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    jwt = await User.getJWT();
    http.Response resp;
    try {
      log("JWT: " + jwt);
      resp = await http.get(Uri.parse(serverAddress + '/api/v1/collections/' + collection.id),
          headers: {HttpHeaders.authorizationHeader: 'Bearer ' + jwt});

      if (resp.statusCode != 200) {
        log("collection info failed: Code " + resp.statusCode.toString());
        return;
      }

      log(resp.body);
      final responseJson = jsonDecode(resp.body);
      collection.shared = responseJson["shared"] == "true" ? true : false;
      if (collection.shared) {
        collection.sharingCode = responseJson["code"];
        collection.sharingLink = serverAddress + "/#/s?collection=" + collection.id + "&code=" + collection.sharingCode;
      }
      for(int i = 0; i < responseJson["sharing"].length; i++) {
        collection.sharingUsers.add(responseJson["sharing"][i]["email"]);
      }
      sharingLinkController.text = collection.sharingLink;
      initialDataPending = false;
      setState(() {});
    } on SocketException {
      log("collection info failed: Socket exception");
      return;
    }

    // TODO: Save and load from disk if network is unavailable
  }

  Future<bool> _onBackPressed() async {
    Navigator.pushReplacementNamed(context, '/collections');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Take in information about the current collection given as args,
    // or set it to no collection if the args are invalid for some reason
    if (ModalRoute.of(context)!.settings.arguments != null) {
      var args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      collection = args["collection"];
      jwt = args["jwt"];
    } else {
      collection = Collection("", "", "", false, []);
      // Todo: Probably navigate back to the /photos page
    }

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Collection Settings"),
          centerTitle: true,
        ),
        body: (initialDataPending)
            ? const Text("Loading...")
            : Form(
                key: _formKey,
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const ListTile(title: Text("General Settings")),
                          TextFormField(
                            decoration: const InputDecoration(
                              filled: true,
                              hintText: 'Enter a name for the collection.',
                              labelText: 'Collection Name',
                            ),
                            initialValue: collection.name,
                            onChanged: (value) {
                              setState(() {
                                collection.updateName(value);
                              });
                            },
                          ),
                          const Divider(),
                          const ListTile(title: Text("Sharing Settings")),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Enable sharing', style: Theme.of(context).textTheme.bodyText1),
                              Switch(
                                value: collection.shared,
                                onChanged: (value) {
                                  setState(() {
                                    collection.updateSharing(value);
                                  });
                                },
                              ),
                            ],
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              filled: true,
                              labelText: 'Sharing Link',
                            ),
                            readOnly: true,
                            controller: sharingLinkController,
                          ),
                          Row(children: [
                            TextButton(
                              child: const Text('Copy Link'),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: collection.sharingLink));
                              },
                            ),
                            TextButton(
                              child: const Text('Regenerate'),
                              onPressed: () async {
                                await collection.regenerateSharedLink();
                                sharingLinkController.text = collection.sharingLink;
                              },
                            ),
                          ]),

                          // List of people shared with
                          const ListTile(title: Text("Shared with users:")),
                          collection.sharingUsers.isEmpty
                            ? const Text("Nobody :(")
                            : ListView.builder(
                            shrinkWrap: true,
                            itemBuilder: (BuildContext context, int index) {
                              return Row(
                                children: [
                                  Text(collection.sharingUsers[index]),
                                  const SizedBox(width: 20),
                                  Text('Can Edit:', style: Theme.of(context).textTheme.bodyText1),
                                  Switch(
                                    value: sharingCanEdit,
                                    onChanged: (value) async {
                                      sharingCanEdit = value;
                                      if (await collection.shareWithUser(sharingUserController.text, sharingCanEdit)) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                            content: Text('Collection shared with ' + sharingUserController.text + '.')));
                                        setState(() {});
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                            content:
                                            Text('Failed to share collection with ' + sharingUserController.text + '.')));
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () async {
                                      if (await collection.unshareWithUser(collection.sharingUsers[index])) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                            content: Text('Collection unshared with user.')));
                                        setState(() {});
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                            content: Text('Failed to unshare collection with ' +
                                                collection.sharingUsers[index] + '.')));
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                            itemCount: collection.sharingUsers.length,
                          ),

                          const SizedBox(height: 30),
                          // Adding a new person to share with
                          TextFormField(
                            decoration: const InputDecoration(
                              filled: true,
                              hintText: "User's email",
                              labelText: 'Share to new user',
                            ),
                            controller: sharingUserController,
                          ),
                          Row(
                              children: [
                            Text('Can Edit:', style: Theme.of(context).textTheme.bodyText1),
                            Switch(
                              value: sharingCanEdit,
                              onChanged: (value) {
                                setState(() {
                                  sharingCanEdit = value;
                                });
                              },
                            ),
                            TextButton(
                              child: const Text('Share'),
                              onPressed: () async {
                                if (await collection.shareWithUser(sharingUserController.text, sharingCanEdit)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Media shared with ' + sharingUserController.text + '.')));
                                  sharingUserController.text = "";
                                  setState(() {});
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('Failed to share media with ' + sharingUserController.text + '.')));
                                }
                              },
                            ),
                          ]),
                          const ListTile(
                            title: Text("Manage Media"),
                          ),
                          Row(children: [
                            TextButton(
                              child: const Text('Add Media'),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/collection_media_manager_add',
                                  arguments: <String, dynamic>{
                                    'collection': collection,
                                    'jwt': jwt,
                                  },
                                );
                              },
                            ),
                            TextButton(
                              child: const Text('Remove Media'),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/collection_media_manager_remove',
                                  arguments: <String, dynamic>{
                                    'collection': collection,
                                    'jwt': jwt,
                                  },
                                );
                              },
                            ),
                          ]),
                          TextButton(
                            style: TextButton.styleFrom(primary: Colors.red),
                            child: const Text('Delete Collection'),
                            onPressed: () async {
                              if (await collection.delete()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(content: Text('Collection deleted.')));
                                Navigator.pushReplacementNamed(context, '/collections');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Failed to delete collection.')));
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
    );
  }
}
