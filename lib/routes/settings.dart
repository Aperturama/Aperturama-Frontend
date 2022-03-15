import 'package:flutter/material.dart';
import 'package:frontend/routes/collections.dart';

class SecondRoute extends StatelessWidget {
  const SecondRoute({Key? key}) : super(key: key);

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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FirstRoute()),
            );
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }
}