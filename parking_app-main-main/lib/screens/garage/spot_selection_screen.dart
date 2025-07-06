import 'package:flutter/material.dart';

class SpotSelectionScreen extends StatelessWidget {
  const SpotSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spot Selection')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Select your parking spot'),
          ],
        ),
      ),
    );
  }
}
