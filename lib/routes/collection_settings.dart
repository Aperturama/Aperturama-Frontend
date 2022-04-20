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
  late Collection collection;

  var sharingLinkController = TextEditingController();
  var sharingUserController = TextEditingController();
  var sharingCanEdit = false;

  String jwt = "";

  // Load info on first load
  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Collection Settings"),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Flexible(
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
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () async {
                          if (await collection.unshareWithUser(collection.sharingUsers[index])) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Collection unshared with ' + collection.sharingUsers[index] + '.')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text('Failed to unshare collection with ' + collection.sharingUsers[index] + '.')));
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
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to share media with ' + sharingUserController.text + '.')));
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
                      '/collection_media_manager',
                      arguments: <String, dynamic>{
                        'collection': collection,
                        'mode': 'add',
                      },
                    );
                  },
                ),
                TextButton(
                  child: const Text('Remove Media'),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/collection_media_manager',
                      arguments: <String, dynamic>{
                        'collection': collection,
                        'mode': 'remove',
                      },
                    );
                  },
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
    );
  }
}
