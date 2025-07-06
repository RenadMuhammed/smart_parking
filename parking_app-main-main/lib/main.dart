import 'dart:async'; // ✅ Needed for Timer
import 'package:flutter/material.dart';
import 'package:smart_parking_app/core/services/notification_service.dart';
import 'package:smart_parking_app/core/services/auth_service.dart';
import 'package:smart_parking_app/core/services/app_state_manager.dart';
import 'package:smart_parking_app/core/services/storage_service.dart'; // ✅ Needed for reservation check
import 'package:smart_parking_app/screens/auth/login_screen.dart';
import 'package:smart_parking_app/screens/home/map_screen.dart';
import 'package:smart_parking_app/screens/payment/payment_screen.dart';
import 'package:smart_parking_app/services/garage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Parking',
      navigatorKey: NotificationService.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _pendingReservation;

  Timer? _extensionCheckTimer; // ✅ Declare it here

  @override
  void initState() {
    super.initState();
    _initialize();
    _startExtensionCheck(); // ✅ Start timer
  }

  @override
  void dispose() {
    _extensionCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await NotificationService.initialize(context);
    _isAuthenticated = await AuthService.validateToken();

    if (_isAuthenticated) {
      _pendingReservation = await AppStateManager.restoreReservationState();
      if (_pendingReservation != null && _pendingReservation!['status'] == 'pending') {
        await AppStateManager.restoreNotificationIfNeeded(context);
      }
    }

    setState(() {
      _isInitialized = true;
    });
  }

  void _startExtensionCheck() {
    _extensionCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkForExpiringReservations();
    });
  }

  Future<void> _checkForExpiringReservations() async {
    try {
      final activeReservation = await StorageService.getActiveReservation();

      if (activeReservation != null) {
        final endTime = DateTime.parse(activeReservation['reservationData']['endTime']);
        final minutesRemaining = endTime.difference(DateTime.now()).inMinutes;

        if (minutesRemaining <= 20 && minutesRemaining > 15) {
          await NotificationService.showExtensionReminder(
            reservationId: int.parse(activeReservation['reservationId']),
            garageName: activeReservation['reservationData']['garageName'],
            section: activeReservation['reservationData']['sectionId'],
            minutesRemaining: minutesRemaining,
          );
        }
      }
    } catch (e) {
      print('❌ Error checking for expiring reservations: $e');
    }
  }

  Widget _getInitialScreen() {
    if (!_isAuthenticated) return LoginScreen();

    if (_pendingReservation != null && _pendingReservation!['status'] == 'pending') {
      final reservationData = _pendingReservation!['reservationData'];
      final garage = Garage(
        id: reservationData['garageId'],
        name: reservationData['garageName'],
        latitude: reservationData['garageLat'] ?? 0.0,
        longitude: reservationData['garageLng'] ?? 0.0,
      );
      return PaymentScreen(
        price: reservationData['price'].toDouble(),
        garage: garage,
      );
    }

    return const MapScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    return _getInitialScreen();
  }
}
