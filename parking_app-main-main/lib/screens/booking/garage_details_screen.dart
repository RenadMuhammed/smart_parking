import 'package:flutter/material.dart';
import 'reservation_confirmation_screen.dart';
import 'package:smart_parking_app/services/garage_service.dart';
import 'package:smart_parking_app/services/section_service.dart';
import 'package:smart_parking_app/models/section.dart';
import 'package:smart_parking_app/core/services/session_service.dart';
import 'package:smart_parking_app/core/services/notification_service.dart';
import 'package:smart_parking_app/core/services/reservation_service.dart';
import 'package:smart_parking_app/screens/home/map_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_parking_app/screens/payment/payment_screen.dart';
import 'package:smart_parking_app/core/services/app_state_manager.dart';
import 'package:smart_parking_app/core/services/storage_service.dart';
import 'package:smart_parking_app/widgets/common/profile_button.dart';

class GarageDetailsScreen extends StatefulWidget {
  final Garage garage;

  const GarageDetailsScreen({Key? key, required this.garage}) : super(key: key);

  @override
  _GarageDetailsScreenState createState() => _GarageDetailsScreenState();
}

class _GarageDetailsScreenState extends State<GarageDetailsScreen> {
  List<Section> sections = [];
  Section? selectedSection;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isLoading = true;
  String? currentUsername;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    loadSections();
    loadUsername();
  }

  Future<void> loadUsername() async {
    final username = await SessionService.getUsername();
    if (username != null) {
      setState(() {
        currentUsername = username;
      });
      // Get user ID when username is loaded
      await getUserId(username);
    }
  }

  Future<void> getUserId(String username) async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.1.15:5000/api/user/$username"),
        headers: {"Content-Type": "application/json"},
      );
      
      print("Getting user info for: $username");
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            currentUserId = data['userId'];
          });
          print("✅ User ID retrieved: $currentUserId");
        }
      } else {
        print("❌ Failed to get user info: ${response.body}");
      }
    } catch (e) {
      print("❌ Error getting user ID: $e");
    }
  }

  Future<void> loadSections() async {
    try {
      final sectionService = SectionService();
      final fetchedSections = await sectionService.fetchSectionsByGarage(widget.garage.id);

      setState(() {
        sections = fetchedSections;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading sections: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  double calculatePrice(Duration duration) {
    double hours = duration.inMinutes / 60;
    double rawPrice = hours * 10.0;
    return rawPrice.ceilToDouble();
  }

  Future<void> createReservation(DateTime startDateTime, DateTime endDateTime) async {
    if (currentUsername == null || currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a reservation')),
      );
      return;
    }

    final reservation = {
      "userId": currentUserId,
      "username": currentUsername,
      "garageId": widget.garage.id,
      "sectionId": selectedSection!.sectionId,
      "startTime": startDateTime.toIso8601String(),
      "endTime": endDateTime.toIso8601String(),
      "duration": endDateTime.difference(startDateTime).inMinutes,
      "status": "pending"
    };

    print("Sending reservation: ${jsonEncode(reservation)}");

    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.15:5000/api/reservation"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reservation),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

  if (response.statusCode == 201) {
    print("✅ Reservation inserted successfully");
    
    // Get the reservation ID from response as int
    final responseData = jsonDecode(response.body);
    final reservationId = responseData['reservationId'] as int; // Keep as int
    await StorageService.saveCurrentReservationId(reservationId);
    // Store reservation ID for later use (SessionService expects int)
    await SessionService.saveReservationId(reservationId);
    
    // Save reservation state (convert to String only for the key if needed)
    await AppStateManager.saveReservationState(
      reservationId: reservationId.toString(), // Convert to String only if AppStateManager expects String
      status: 'pending',
      expiryTime: DateTime.now().add(Duration(minutes: 20)),
      reservationData: {
        'reservationId': reservationId, // Keep as int in data
        'garageId': widget.garage.id,
        'garageName': widget.garage.name,
        'garageLat': widget.garage.latitude,
        'garageLng': widget.garage.longitude,
        'sectionId': selectedSection!.sectionId.toString(),
        'startTime': startDateTime.toIso8601String(),
        'endTime': endDateTime.toIso8601String(),
        'duration': endDateTime.difference(startDateTime).inMinutes,
        'price': calculatePrice(endDateTime.difference(startDateTime)),
        'userId': currentUserId,
        'username': currentUsername,
      },
    );
    
    // Show countdown notification
    print("🚀 Starting countdown notification...");
    await NotificationService.showCountdownNotification(
      garageName: widget.garage.name,
      section: selectedSection!.sectionId.toString(),
      onCountdownComplete: () async {
        print("⏰ Countdown completed - Cancelling reservation");
        
        // Update status to cancelled in database (keep as int)
        final updated = await ReservationService.updateReservationStatus(
          reservationId: reservationId, // Keep as int
          status: 'cancelled',
        );
        
        if (updated) {
          print("✅ Reservation cancelled in database");
        }
        
        // Use the global navigator
        final context = NotificationService.navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation cancelled - Time limit exceeded'),
              backgroundColor: Colors.red,
            ),
          );
          
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MapScreen()),
            (route) => false,
          );
        }
      },
      onCancelPressed: () async {
        print("❌ User cancelled reservation");
        final savedReservationId = await StorageService.getCurrentReservationId();
        // Update status to cancelled in database (keep as int)
        if (savedReservationId != null) {
    // Update status to cancelled in database
    final updated = await ReservationService.updateReservationStatus(
      reservationId: savedReservationId,
      status: 'cancelled',
    );
        
        if (updated) {
          print("✅ Reservation cancelled in database");
        }
        }
        await StorageService.clearCurrentReservationId();
        // Use the global navigator
        final context = NotificationService.navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
          
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MapScreen()),
            (route) => false,
          );
        }
      },
      onPaymentPressed: () async {
        print("💳 Navigating to payment from notification");
        
        // Calculate the price
        final duration = endDateTime.difference(startDateTime);
        final price = calculatePrice(duration);
        
        // Use the global navigator
        final context = NotificationService.navigatorKey.currentContext;
        if (context != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PaymentScreen(
                price: price,
                garage: widget.garage,
              ),
            ),
          );
        }
      },
    );
    print("✅ Countdown notification started");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservation created! Complete payment within 20 minutes.')),
    );
    
    // Navigate to confirmation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationConfirmationScreen(
          garage: widget.garage,
          section: selectedSection!.sectionId.toString(),
          startTime: startDateTime,
          endTime: endDateTime,
          duration: endDateTime.difference(startDateTime),
          price: calculatePrice(endDateTime.difference(startDateTime)),
        ),
      ),
    );
  } else {
        final errorData = jsonDecode(response.body);
        print("❌ Failed to insert reservation: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Failed to create reservation')),
        );
      }
    } catch (e) {
      print("❌ Error creating reservation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.garage.name),
        actions: [
          const ProfileButton(), // Add this
          
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("Garage ID: ${widget.garage.id}"),
                  if (currentUserId != null)
                    Text("User ID: $currentUserId", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Section>(
                    value: selectedSection,
                    items: sections.map((section) {
                      return DropdownMenuItem(
                        value: section.available > 0 ? section : null,
                        enabled: section.available > 0,
                        child: Row(
                          children: [
                            Text(
                              "Section ${section.sectionId} (${section.available} spots)",
                              style: TextStyle(
                                color: section.available > 0 ? Colors.black : Colors.grey,
                              ),
                            ),
                            if (section.available == 0) ...[
                              const SizedBox(width: 5),
                              const Icon(Icons.block, size: 16, color: Colors.red),
                            ]
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedSection = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: "Select Section"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() => startTime = pickedTime);
                      }
                    },
                    child: Text(startTime == null
                        ? "Pick Start Time"
                        : "Start: ${startTime!.format(context)}"),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          DateTime.now().add(const Duration(hours: 2))
                        ),
                      );
                      if (pickedTime != null) {
                        setState(() => endTime = pickedTime);
                      }
                    },
                    child: Text(endTime == null
                        ? "Pick End Time"
                        : "End: ${endTime!.format(context)}"),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: selectedSection != null && 
                              startTime != null && 
                              endTime != null && 
                              currentUsername != null && 
                              currentUserId != null
                        ? () async {
                            final startDateTime = DateTime(
                              now.year, now.month, now.day,
                              startTime!.hour, startTime!.minute);
                            final endDateTime = DateTime(
                              now.year, now.month, now.day,
                              endTime!.hour, endTime!.minute);
                            
                            if (endDateTime.isAfter(startDateTime)) {
                              await createReservation(startDateTime, endDateTime);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('End time must be after start time')),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedSection != null && 
                                      startTime != null && 
                                      endTime != null && 
                                      currentUsername != null && 
                                      currentUserId != null
                          ? const Color.fromARGB(219, 1, 44, 86)
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text("Reserve Spot"),
                  ),
                  if (currentUsername == null || currentUserId == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        "Please log in to make a reservation",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}