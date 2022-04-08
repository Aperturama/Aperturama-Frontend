import 'package:flutter/material.dart';
import 'package:aperturama/utils/media.dart';

class CollectionSettings extends StatefulWidget {
  const CollectionSettings(this.collection, {Key? key}) : super(key: key);

  final Collection collection;

  @override
  State<CollectionSettings> createState() => _CollectionSettingsState();
}

class _CollectionSettingsState extends State<CollectionSettings> {

  final _formKey = GlobalKey<FormState>();
  String collectionName = '';
  bool enableSharing = true;

  @override
  Widget build(BuildContext context) {

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return AlertDialog(
      content: SizedBox(
        //HERE THE SIZE YOU WANT
        height: MediaQuery.of(context).size.height / 1.2,
        width: MediaQuery.of(context).size.width / 1.1,
        //your content
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
                          onChanged: (value) {
                            setState(() {
                              collectionName = value;
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
                            Text('Enable sharing',
                                style: Theme.of(context).textTheme.bodyText1),
                            Switch(
                              value: enableSharing,
                              onChanged: (enabled) {
                                setState(() {
                                  enableSharing = enabled;
                                });
                              },
                            ),
                          ],
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            filled: true,
                            hintText: 'A link you can share with others to access this collection.',
                            labelText: 'Sharing Link:',
                          ),
                          onChanged: (value) {
                            collectionName = value;
                          },
                        ),
                        Row(
                          children: [
                            TextButton(
                              child: const Text('Copy Link'),
                              onPressed: () {

                              },
                            ),
                            TextButton(
                              child: const Text('Regenerate'),
                              onPressed: () {

                              },
                            ),
                          ]
                        ),
                        DropdownButton<String>(
                          value: "Username here", //dropdownValue
                          icon: const Icon(Icons.arrow_downward),
                          elevation: 16,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.blue),
                          underline: Container(
                            height: 2,
                            color: Colors.blue,
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              //dropdownValue = newValue!;
                            });
                          },
                          items: <String>['Username here', 'Two', 'Free', 'Four']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        Row(
                          children: [
                            TextButton(
                              child: const Text('Shared'),
                              onPressed: () {

                              },
                            ),
                            TextButton(
                              child: const Text('Editing Allowed'),
                              onPressed: () {

                              },
                            ),
                          ]
                        ),
                        ListTile(
                          title: Text("Manage Media:"),
                        ),
                        Row(
                            children: [
                              TextButton(
                                child: const Text('Add'),
                                onPressed: () {

                                },
                              ),
                              TextButton(
                                child: const Text('Delete'),
                                onPressed: () {

                                },
                              ),
                            ]
                        ),
                        TextButton(
                            style: TextButton.styleFrom(primary: Colors.red),
                          child: const Text('Delete Collection'),

                          onPressed: () {

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
