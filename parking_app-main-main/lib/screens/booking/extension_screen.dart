import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_parking_app/screens/payment/payment_screen.dart';
import 'package:smart_parking_app/services/garage_service.dart';
import 'package:smart_parking_app/widgets/common/profile_button.dart';
import 'package:smart_parking_app/core/services/storage_service.dart';


class ExtensionScreen extends StatefulWidget {
  final int reservationId;

  const ExtensionScreen({
    Key? key,
    required this.reservationId,
  }) : super(key: key);

  @override
  State<ExtensionScreen> createState() => _ExtensionScreenState();
}


class _ExtensionScreenState extends State<ExtensionScreen> {
  bool _loading = true;
  Map<String, dynamic>? _reservationData;

  @override
  void initState() {
    super.initState();
    _loadReservation();
  }

  Future<void> _loadReservation() async {
    try {
      // Simulate loading or fetch from StorageService
      await Future.delayed(Duration(seconds: 2)); // simulate loading
      final reservation = await StorageService.getActiveReservation();

      if (reservation != null) {
        setState(() {
          _reservationData = reservation;
          _loading = false;
        });
      } else {
        // no active reservation
        setState(() {
          _reservationData = null;
          _loading = false;
        });
      }
    } catch (e) {
      print("❌ Failed to load reservation: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_reservationData == null) {
      return const Scaffold(
        body: Center(child: Text("No active reservation found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Extend Reservation")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Garage: ${_reservationData!['reservationData']['garageName']}"),
            Text("End time: ${_reservationData!['reservationData']['endTime']}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement your extension logic here
                print("🚗 Extend reservation clicked");
              },
              child: const Text("Extend Reservation"),
            ),
          ],
        ),
      ),
    );
  }
}
