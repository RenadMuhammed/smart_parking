// core/services/app_state_manager.dart
import 'package:flutter/material.dart';
import 'package:smart_parking_app/core/services/storage_service.dart';
import 'package:smart_parking_app/core/services/notification_service.dart';
import 'package:smart_parking_app/screens/payment/payment_screen.dart';
import 'package:smart_parking_app/services/garage_service.dart';

class AppStateManager {
  static Future<void> saveReservationState({
    required String reservationId,
    required String status,
    required DateTime expiryTime,
    required Map<String, dynamic> reservationData,
  }) async {
    final stateData = {
      'reservationId': reservationId,
      'status': status,
      'expiryTime': expiryTime.toIso8601String(),
      'reservationData': reservationData,
      'savedAt': DateTime.now().toIso8601String(),
    };

    if (status == 'pending') {
      await StorageService.savePendingReservation(stateData);
    } else if (status == 'active') {
      await StorageService.saveActiveReservation(stateData);
      await StorageService.removePendingReservation();
    }
  }

  static Future<Map<String, dynamic>?> restoreReservationState() async {
    // Check for pending reservation first
    final pendingReservation = await StorageService.getPendingReservation();
    if (pendingReservation != null) {
      final expiryTime = DateTime.parse(pendingReservation['expiryTime']);
      
      // Check if reservation is still valid
      if (DateTime.now().isBefore(expiryTime)) {
        return pendingReservation;
      } else {
        // Expired, remove it
        await StorageService.removePendingReservation();
      }
    }

    // Check for active reservation
    final activeReservation = await StorageService.getActiveReservation();
    if (activeReservation != null) {
      return activeReservation;
    }

    return null;
  }

  static Future<void> restoreNotificationIfNeeded(BuildContext context) async {
    final pendingReservation = await StorageService.getPendingReservation();
    
    if (pendingReservation != null) {
      final expiryTime = DateTime.parse(pendingReservation['expiryTime']);
      final remainingTime = expiryTime.difference(DateTime.now());
      
      if (remainingTime.inSeconds > 0) {
        final reservationData = pendingReservation['reservationData'];
        
        // Update remaining seconds in NotificationService
        NotificationService.setRemainingSeconds(remainingTime.inSeconds);
        
        // Create garage object from saved data
        final garage = Garage(
          id: reservationData['garageId'],
          name: reservationData['garageName'],
          latitude: reservationData['garageLat'] ?? 0.0,
          longitude: reservationData['garageLng'] ?? 0.0,
        );
        
        // Restore the notification
        await NotificationService.showCountdownNotification(
          garageName: reservationData['garageName'],
          section: reservationData['sectionId'],
          onCountdownComplete: () async {
            await StorageService.removePendingReservation();
            // Handle countdown completion
          },
          onCancelPressed: () async {
            await StorageService.removePendingReservation();
            // Handle cancellation
          },
          onPaymentPressed: () {
            final navContext = NotificationService.navigatorKey.currentContext;
            if (navContext != null) {
              Navigator.push(
                navContext,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    price: (reservationData['price'] as num).toDouble(),
                    garage: garage,
                  ),
                ),
              );
            }
          },
        );
      }
    }
  }

  static Future<void> clearReservationState() async {
    await StorageService.removePendingReservation();
    await StorageService.removeActiveReservation();
  }
}