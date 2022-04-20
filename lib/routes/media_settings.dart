import 'package:aperturama/utils/media.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../utils/user.dart';

class MediaSettings extends StatefulWidget {
  const MediaSettings({Key? key}) : super(key: key);

  @override
  State<MediaSettings> createState() => _MediaSettingsState();
}

class _MediaSettingsState extends State<MediaSettings> {
  final _formKey = GlobalKey<FormState>();
  bool enableSharing = true;
  late Media media;
  String jwt = "";

  bool initialDataPending = true;

  var sharingLinkController = TextEditingController();
  var sharingUserController = TextEditingController();
  var sharingCanEdit = false;

  // Load info on first load
  @override
  void initState() {
    super.initState();
    _getMediaInfo();
  }

  Future<void> _getMediaInfo() async {
    // Send a request to the backend
    String serverAddress = await User.getServerAddress();
    jwt = await User.getJWT();
    http.Response resp;
    try {
      log("JWT: " + jwt);
      resp = await http.get(Uri.parse(serverAddress + '/api/v1/media/' + media.id),
          headers: {HttpHeaders.authorizationHeader: 'Bearer ' + jwt});

      if (resp.statusCode != 200) {
        log("Media info failed: Code " + resp.statusCode.toString());
        return;
      }

      log(resp.body);
      final responseJson = jsonDecode(resp.body);
      media.shared = responseJson["shared"] == "true" ? true : false;
      if (media.shared) {
        media.sharingLink = serverAddress + "/#/s?media=" + media.id + "&code=" + responseJson["code"];
      }
      for(int i = 0; i < responseJson["sharing"].length; i++) {
        if(responseJson["sharing"][i].containsKey("email") && !media.sharingUsers.contains(responseJson["sharing"][i]["email"])) media.sharingUsers.add(responseJson["sharing"][i]["email"]);
      }
      media.uploadedTimestamp = DateTime.parse(responseJson["date_uploaded"]);

      initialDataPending = false;
      setState(() {});

    } on SocketException {
      log("Media info failed: Socket exception");
      return;
    }

    // TODO: Save and load from disk if network is unavailable
  }

  @override
  Widget build(BuildContext context) {
    // Take in information about the current media given as args,
    // or set it to no media if the args are invalid for some reason
    if (ModalRoute.of(context)!.settings.arguments != null) {
      var args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      media = args["media"];
      jwt = args.containsKey("jwt") ? args["jwt"] : "";
    } else {
      media = Media("", MediaType.photo, "", "");
      // Todo: Probably navigate back to the /photos page
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Media Settings"),
        centerTitle: true,
      ),
      body: (initialDataPending)
          ? const Text("Loading...")
          : Form(
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
                            ListTile(
                              horizontalTitleGap: 0,
                              title: Text(p.basename(media.filename)),
                              contentPadding: const EdgeInsets.only(left: 14, bottom: 10),
                              subtitle: Text(media.filename),
                            ),
                            ListTile(
                              horizontalTitleGap: 0,
                              title: Text("Date Taken: " +
                                  media.takenTimestamp.year.toString() +
                                  "/" +
                                  media.takenTimestamp.month.toString() +
                                  "/" +
                                  media.takenTimestamp.day.toString() +
                                  " " +
                                  ((media.takenTimestamp.hour + 11) % 12 + 1).toString() +
                                  ":" +
                                  media.takenTimestamp.minute.toString().padLeft(2, '0') +
                                  ((media.takenTimestamp.hour >= 12) ? " pm" : " am")),
                              contentPadding: const EdgeInsets.only(left: 14, bottom: 10),
                            ),
                            ListTile(
                              horizontalTitleGap: 0,
                              title: Text("Date Uploaded: " +
                                  media.uploadedTimestamp.year.toString() +
                                  "/" +
                                  media.uploadedTimestamp.month.toString() +
                                  "/" +
                                  media.uploadedTimestamp.day.toString() +
                                  " " +
                                  ((media.uploadedTimestamp.hour + 11) % 12 + 1).toString() +
                                  ":" +
                                  media.uploadedTimestamp.minute.toString().padLeft(2, '0') +
                                  ((media.uploadedTimestamp.hour >= 12) ? " pm" : " am")),
                              contentPadding: const EdgeInsets.only(left: 14, bottom: 10),
                            ),
                            const ListTile(
                              title: Text("Sharing Settings"),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('Enable sharing', style: Theme.of(context).textTheme.bodyText1),
                                Switch(
                                  value: media.shared,
                                  onChanged: (value) {
                                    setState(() {
                                      media.shared = value;
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
                                  Clipboard.setData(ClipboardData(text: media.sharingLink));
                                },
                              ),
                              TextButton(
                                child: const Text('Regenerate'),
                                onPressed: () async {
                                  await media.regenerateSharedLink();
                                  sharingLinkController.text = media.sharingLink;
                                },
                              ),
                            ]),
// List of people shared with
                            const ListTile(title: Text("Shared with users:")),
                            media.sharingUsers.isEmpty
                                ? const Text("Nobody :(")
                                : ListView.builder(
                              shrinkWrap: true,
                              itemBuilder: (BuildContext context, int index) {
                                return Row(
                                  children: [
                                    Text(media.sharingUsers[index]),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () async {
                                        if (await media.unshareWithUser(media.sharingUsers[index])) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                              content: Text('Media unshared with user.')));
                                          setState(() {});
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                              content: Text('Failed to unshare media with ' +
                                                  media.sharingUsers[index] + '.')));
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                              itemCount: media.sharingUsers.length,
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
                            Row(children: [
                              TextButton(
                                child: const Text('Share'),
                                onPressed: () async {
                                  if (await media.shareWithUser(sharingUserController.text)) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Media shared with ' + sharingUserController.text + '.')));
                                    sharingUserController.text = "";
                                    setState(() {});
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content:
                                            Text('Failed to share media with ' + sharingUserController.text + '.')));
                                  }
                                },
                              ),
                            ]),
                            TextButton(
                              style: TextButton.styleFrom(primary: Colors.red),
                              child: const Text('Delete Media'),
                              onPressed: () async {
                                if (await media.delete()) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(content: Text('Media deleted.')));
                                  Navigator.pushReplacementNamed(context, '/media');
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(content: Text('Failed to delete media.')));
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
    );
  }
}
