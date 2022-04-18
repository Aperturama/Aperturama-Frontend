import 'package:aperturama/utils/main_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/user.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({Key? key}) : super(key: key);

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String email = '';
  String password = '';
  bool enableSharing = true;
  bool initialDataPending = true;

  void _populateInfoCached() async {
    firstName = await User.getFirstName();
    lastName = await User.getLastName();
    email = await User.getEmail();
    initialDataPending = false;
    setState(() {});
  }

  void _populateInfoRefresh() async {
    await User.getAccountInfo();
    firstName = await User.getFirstName();
    lastName = await User.getLastName();
    email = await User.getEmail();
    setState(() {});
  }

  // Load info on first load
  @override
  void initState() {
    super.initState();
    _populateInfoCached();
    _populateInfoRefresh();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: Form(
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
                      const ListTile(
                        title: Text("Your Name"),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                filled: true,
                                hintText: 'First Name',
                                labelText: 'First Name',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  firstName = value;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                filled: true,
                                hintText: 'Last Name',
                                labelText: 'Last Name',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  lastName = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      TextFormField(
                        decoration: const InputDecoration(
                          filled: true,
                          hintText: 'Email Address',
                          labelText: 'Email Address',
                        ),
                        onChanged: (value) {
                          email = value;
                        },
                      ),
                      const Divider(),
                      TextFormField(
                        decoration: const InputDecoration(
                          filled: true,
                          hintText: 'Password',
                          labelText: 'Password (if changing)',
                        ),
                        onChanged: (value) {
                          password = value;
                        },
                      ),
                      const Divider(),
                      Center(
                        child: ElevatedButton(
                          child: const Text('Save Changes'),
                          onPressed: () async {
                            bool success = await User.updateAccountInfo(firstName, lastName, email, password);
                            if (success) {
                              // Updating succeeded
                              // Show a snackbar message
                              ScaffoldMessenger.of(context).removeCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Account info updated successfully!')),
                              );
                              _populateInfoRefresh();
                            } else {
                              // Updating failed
                              // Show a snackbar message
                              ScaffoldMessenger.of(context).removeCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to update account info.')),
                              );
                            }
                          },
                        ),
                      ),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(primary: Colors.red),
                            child: const Text('Log Out'),
                          onPressed: () {
                            User.logOut();
                            // Show a snackbar message
                            ScaffoldMessenger.of(context).removeCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out successfully!')),
                            );
                            // Redirect to login page
                            Navigator.pushReplacementNamed(context, '/');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: kIsWeb ? null : const MainDrawer(),
    );
  }
}
