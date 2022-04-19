import 'package:aperturama/utils/media.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';

class MediaSettings extends StatefulWidget {
  const MediaSettings({Key? key}) : super(key: key);

  @override
  State<MediaSettings> createState() => _MediaSettingsState();
}

class _MediaSettingsState extends State<MediaSettings> {
  final _formKey = GlobalKey<FormState>();
  String collectionName = '';
  bool enableSharing = true;
  late final Media media;

  var sharingLinkController = TextEditingController();
  var sharingUserController = TextEditingController();
  var sharingCanEdit = false;

  // Load info on first load
  @override
  void initState() {
    super.initState();

    // Take in information about the current media given as args,
    // or set it to no media if the args are invalid for some reason
    if (ModalRoute.of(context)!.settings.arguments != null) {
      media = ModalRoute.of(context)!.settings.arguments as Media;
    } else {
      media = Media("", MediaType.photo, "", "");
      // Todo: Probably navigate back to the /photos page
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
                        ListTile(
                          horizontalTitleGap: 0,
                          title: Text(p.basename(media.localPath)),
                          contentPadding: const EdgeInsets.only(left: 14, bottom: 10),
                          subtitle: Text(media.localPath),
                        ),
                        ListTile(
                          horizontalTitleGap: 0,
                          title: Text("Date Taken: " +
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
                          subtitle: Text(media.localPath),
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
                          initialValue: media.sharingLink,
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
                        ListView.builder(
                          itemBuilder: (BuildContext context, int index) {
                            return Row(
                              children: [
                                Text(media.sharingUsers[index]),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () async {
                                    if (await media.unshareWithUser(media.sharingUsers[index])) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text('Media unshared with ' + media.sharingUsers[index] + '.')));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content:
                                              Text('Failed to unshare media with ' + media.sharingUsers[index] + '.')));
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                          itemCount: media.sharingUsers.length,
                        ),
                        Row(children: [
                          TextFormField(
                            decoration: const InputDecoration(
                              filled: true,
                              hintText: "User's email",
                              labelText: 'Share to new user',
                            ),
                            controller: sharingUserController,
                          ),
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
                              if (await media.shareWithUser(sharingUserController.text, sharingCanEdit)) {
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
                        TextButton(
                          style: TextButton.styleFrom(primary: Colors.red),
                          child: const Text('Delete Media'),
                          onPressed: () async {
                            if (await media.delete()) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(content: Text('Media deleted.')));
                              Navigator.pop(context);
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
      ),
    );
  }
}
