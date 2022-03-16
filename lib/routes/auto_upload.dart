import 'package:flutter/material.dart';
import 'package:aperturama/routes/collections.dart';

class AutoUpload extends StatelessWidget {
  const AutoUpload({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Route'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to first route when tapped.
            Navigator.pushNamed(context, '/first');
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }
}