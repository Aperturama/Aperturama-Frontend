import 'package:flutter/material.dart';
import 'package:aperturama/utils/media.dart';
import 'package:flutter/services.dart';

class CollectionSettings extends StatefulWidget {
  const CollectionSettings({Key? key}) : super(key: key);

  @override
  State<CollectionSettings> createState() => _CollectionSettingsState();
}

class _CollectionSettingsState extends State<CollectionSettings> {
  final _formKey = GlobalKey<FormState>();
  bool sharingEnabled = true;
  late final Collection collection;

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
      collection = ModalRoute.of(context)!.settings.arguments as Collection;
    } else {
      collection = Collection("", "", "", false, []);
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
                        Text("Collection Name:"),
                        TextFormField(
                          decoration: const InputDecoration(
                            filled: true,
                            hintText: 'Enter a name for the collection.',
                            labelText: 'Collection Name',
                          ),
                          initialValue: collection.name,
                          onChanged: (value) {
                            setState(() {
                              collection.name = value;
                            });
                          },
                        ),
                        ListTile(
                          title: Text("Sharing Settings:"),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Enable sharing', style: Theme.of(context).textTheme.bodyText1),
                            Switch(
                              value: collection.shared,
                              onChanged: (value) {
                                setState(() {
                                  collection.shared = value;
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
                          initialValue: collection.sharingLink,
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
                        ListView.builder(
                          itemBuilder: (BuildContext context, int index) {
                            return Row(
                              children: [
                                Text(collection.sharingUsers[index]),
                                Text('Can Edit:', style: Theme.of(context).textTheme.bodyText1),
                                Switch(
                                  value: sharingCanEdit,
                                  onChanged: (value) async {
                                    if (await collection.shareWithUser(sharingUserController.text, sharingCanEdit)) {
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
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () async {
                                    if (await collection.unshareWithUser(collection.sharingUsers[index])) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(
                                              'Collection unshared with ' + collection.sharingUsers[index] + '.')));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text('Failed to unshare collection with ' +
                                              collection.sharingUsers[index] +
                                              '.')));
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                          itemCount: collection.sharingUsers.length,
                        ),
                        // Adding a new person to share with
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
                        ListTile(
                          title: Text("Manage Media:"),
                        ),
                        Row(children: [
                          TextButton(
                            child: const Text('Add'),
                            onPressed: () {},
                          ),
                          TextButton(
                            child: const Text('Delete'),
                            onPressed: () {},
                          ),
                        ]),
                        TextButton(
                          style: TextButton.styleFrom(primary: Colors.red),
                          child: const Text('Delete Collection'),
                          onPressed: () {},
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
