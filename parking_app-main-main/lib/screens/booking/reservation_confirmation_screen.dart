import 'package:flutter/material.dart';
import 'package:smart_parking_app/services/garage_service.dart';
import 'package:smart_parking_app/screens/payment/payment_screen.dart';
import 'package:smart_parking_app/screens/home/map_screen.dart';
import 'package:smart_parking_app/widgets/common/profile_button.dart';


class ReservationConfirmationScreen extends StatelessWidget {
  final Garage garage;
  final String section;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double price;

  const ReservationConfirmationScreen({
    Key? key,
    required this.garage,
    required this.section,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.price,
  }) : super(key: key);

  String formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')} hours';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [
    ProfileButton(), // Add this
  ],
        title: const Text("Reservation Confirmation")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Garage: ${garage.name}"),
            Text("Section: $section"),
            Text("Start: ${startTime.toString()}"),
            Text("End: ${endTime.toString()}"),
            Text("Duration: ${formatDuration(duration)}"),
            Text("💰 Price: ${price.toStringAsFixed(2)} EGP"),
            const SizedBox(height: 10),
            const Text("🔄 Status: Pending"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to MapScreen while keeping the stack
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreen(
                      selectedGarage: garage, // Pass the garage to show on map
                    ),
                  ),
                );
              },
              child: const Text("Directions"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // When navigating to payment screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      price: price,
                      garage: garage, // Add this
                    ),
                  ),
                );
              },
              child: const Text("Proceed to Payment"),
            ),
          ],
        ),
      ),
    );
  }
}
