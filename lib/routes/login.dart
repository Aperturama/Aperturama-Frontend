import 'dart:developer';

import 'package:aperturama/utils/main_drawer.dart';
import 'package:aperturama/utils/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLogin extends StatefulWidget {
  const AppLogin({Key? key}) : super(key: key);

  @override
  State<AppLogin> createState() => _AppLoginState();
}

class _AppLoginState extends State<AppLogin> {
  final _formKey = GlobalKey<FormState>();
  String email = "";
  String password = "";
  String serverAddress = "";
  bool initialDataPending = true;

  void _populateInfo() async {
    serverAddress = await User.getServerAddress();
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

  List<Widget> loginForm(BuildContext context) {
    return [
      const SizedBox(height: 30),
      TextFormField(
        decoration: const InputDecoration(
          filled: true,
          hintText: 'Server Address',
          labelText: 'Server Address',
        ),
        initialValue: serverAddress,
        onChanged: (value) {
          serverAddress = value;
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your server address';
          }
          return null;
        },
      ),
      const SizedBox(height: 10),
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email address';
          }
          return null;
        },
      ),
      const SizedBox(height: 10),
      TextFormField(
        decoration: const InputDecoration(
          filled: true,
          hintText: 'Password',
          labelText: 'Password',
        ),
        obscureText: true,
        onChanged: (value) {
          password = value;
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          return null;
        },
      ),
      const SizedBox(height: 10),
      Center(
          child: ElevatedButton(
        child: const Text('Log in'),
        onPressed: () async {
          // Drop the keyboard
          FocusManager.instance.primaryFocus?.unfocus();

          // Validate returns true if the form is valid, or false otherwise.
          if (_formKey.currentState!.validate()) {
            // Show a snackbar message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logging in...')),
            );

            bool result = await User.tryLogIn(serverAddress, email, password);
            if (result) {
              // Login succeeded
              // Show a snackbar message
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged in successfully!.')),
              );
              Navigator.pushReplacementNamed(context, '/media');
            } else {
              // Login failed
              // Show a snackbar message
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login failed.')),
              );
            }
          } else {
            // Show a snackbar message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please correct the issues above.')),
            );
          }
        },
      ))
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log in"),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                      child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width / 2,
                          ),
                          child: const Image(
                              image: AssetImage('assets/logo.png')))),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text("Welcome to Aperturama",
                        style: TextStyle(fontSize: 24)),
                  ),
                  const Center(
                    child: Text("Please log in below",
                        style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 30),
                  if (initialDataPending)
                    const CircularProgressIndicator()
                  else
                     ...loginForm(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
