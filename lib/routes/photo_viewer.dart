import 'package:flutter/material.dart';
import 'package:frontend/routes/settings.dart';

class PhotoViewer extends StatelessWidget {
  const PhotoViewer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Route'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Open route'),
          onPressed: () {
            // Navigate to second route when tapped.
            Navigator.pushNamed(context, '/second');
          },
        ),
      ),
    );
  }
}