import 'package:aperturama/utils/main_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLogin extends StatefulWidget {
  const AppLogin({Key? key}) : super(key: key);

  @override
  State<AppLogin> createState() => _AppLoginState();
}

class _AppLoginState extends State<AppLogin> {
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
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Log in"),
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
                      Center(
                          child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width / 2,
                              ),
                              child: const Image(
                                  image: AssetImage('assets/logo.png')
                              )
                          )
                      ),
                      const Center(
                        child: Text("Welcome to Aperturama", style: TextStyle(fontSize: 24)),
                      ),
                      const Center(
                        child: Text("Please log in below", style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        decoration: const InputDecoration(
                          filled: true,
                          hintText: 'Email Address',
                          labelText: 'Email Address',
                        ),
                        onChanged: (value) {
                          collectionName = value;
                        },
                      ),
                      const Divider(),
                      TextFormField(
                        decoration: const InputDecoration(
                          filled: true,
                          hintText: 'Password',
                          labelText: 'Password',
                        ),
                        onChanged: (value) {
                          collectionName = value;
                        },
                      ),
                      const Divider(),
                      Center(
                        child: ElevatedButton(
                          child: const Text('Log in'),
                          onPressed: () {},
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
