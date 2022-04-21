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
  bool initialDataPending = true;

  void _populateInfo() async {
    await User.getAccountInfo(); // Refresh cache
    firstName = await User.getFirstName();
    lastName = await User.getLastName();
    email = await User.getEmail();
    initialDataPending = false;
    setState(() {});
  }

  // Load info on first load
  @override
  void initState() {
    super.initState();
    _populateInfo();
  }

  List<Widget> settingsForm(context) {
    return [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration(
                filled: true,
                hintText: 'First Name',
                labelText: 'First Name',
              ),
              initialValue: firstName,
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
              initialValue: lastName,
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
        initialValue: email,
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
            bool success =
                await User.setAccountInfo(firstName, lastName, email, password);
            if (success) {
              // Updating succeeded
              // Show a snackbar message
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Account info updated successfully!')),
              );
              _populateInfo();
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
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                      if (initialDataPending)
                        const CircularProgressIndicator()
                      else
                        ...settingsForm(context),
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
