import 'package:flutter/material.dart';
import 'package:aperturama/utils/media.dart';
import 'package:flutter/services.dart';

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

  Future<bool> createCollection(String name) {
    return false;
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Collection created')));
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Failed to create collection')));
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
