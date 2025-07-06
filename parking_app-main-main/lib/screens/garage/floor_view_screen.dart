import 'package:flutter/material.dart';

class FloorViewScreen extends StatelessWidget {
  const FloorViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Floor View')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Floor Layout Here'),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/spotSelection');
              },
              child: const Text('Select a Spot'),
            ),
          ],
        ),
      ),
    );
  }
}
