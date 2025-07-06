import 'package:flutter/material.dart';

class ActiveBookingsScreen extends StatelessWidget {
  const ActiveBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Bookings')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Your Active Bookings'),
          ],
        ),
      ),
    );
  }
}
