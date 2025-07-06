import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_parking_app/services/garage_service.dart';
import 'package:smart_parking_app/core/services/storage_service.dart';
import 'package:smart_parking_app/screens/payment/payment_screen.dart';
import 'package:smart_parking_app/core/services/reservation_service.dart'; // Add this
import 'package:smart_parking_app/screens/home/map_screen.dart'; // Add this
import 'package:smart_parking_app/screens/booking/extension_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static Timer? _countdownTimer;
  static int _remainingSeconds = 1200; // 20 minutes
  static Function? _onCountdownComplete;
  static Function? _onCancelPressed;
  static Function? _onPaymentPressed;
  static bool _isInitialized = false;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void setRemainingSeconds(int seconds) {
    _remainingSeconds = seconds;
  }

  // This is the function that initializes the notification service
  static Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    
    print("🔔 Initializing notification service...");
    
    // Request notification permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        print("📱 Notification action: ${details.actionId}");
        if (details.actionId == 'extend_reservation') {
  print("🔄 Extension button pressed in notification");

  final navContext = navigatorKey.currentContext;
  if (navContext != null && details.id != null) {
    final reservationId = details.id! - 1001; // now it's safe
    Navigator.push(
      navContext,
      MaterialPageRoute(
        builder: (_) => ExtensionScreen(reservationId: reservationId),
      ),
    );
  } else {
    print("⚠️ Cannot open ExtensionScreen - context or ID is null");
  }
}
        if (details.actionId == 'cancel_reservation') {
          print("🔴 Cancel button pressed in notification");
          // Cancel notification first
          await cancelNotification();
          // Then call the cancel callback
          _onCancelPressed?.call();
        } else if (details.actionId == 'go_to_payment') {
          print("💳 Payment button pressed in notification");
          // Don't cancel notification yet - let payment screen handle it
          _onPaymentPressed?.call();
        }
       


        
      },
    );

    // Create a high-priority notification channel
    const androidChannel = AndroidNotificationChannel(
      'parking_countdown',
      'Parking Reservation Countdown',
      description: 'Shows countdown for pending parking reservations',
      importance: Importance.max,
      playSound: false,
      enableVibration: false,
      enableLights: true,
      showBadge: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
      print("✅ Notification channel created");
    }

    _isInitialized = true;
    print("✅ Notification service initialized");
  }

  // Updated showPersistentNotification method
  static Future<void> showPersistentNotification(
    BuildContext context,
    String reservationId, {
    Duration duration = const Duration(minutes: 20),
  }) async {
    final savedReservation = await StorageService.getPendingReservation();
    
    if (savedReservation != null) {
      final reservationData = savedReservation['reservationData'];
      final garageName = reservationData['garageName'] ?? 'Parking Garage';
      final section = reservationData['sectionId'] ?? 'A';
      final price = (reservationData['price'] as num).toDouble();
      
      // Create garage object from saved data
      final garage = Garage(
        id: reservationData['garageId'],
        name: reservationData['garageName'],
        latitude: reservationData['garageLatitude'] ?? 0.0,
        longitude: reservationData['garageLongitude'] ?? 0.0,
      );
      
      await showCountdownNotification(
        garageName: garageName,
        section: section,
        onCountdownComplete: () async {
          // Update reservation status in database
          final updated = await ReservationService.updateReservationStatus(
            reservationId: int.parse(reservationId),
            status: 'cancelled',
          );
          
          if (updated) {
            print("✅ Reservation cancelled in database");
          }
          
          await StorageService.removePendingReservation();
          
          final navContext = navigatorKey.currentContext;
          if (navContext != null) {
            ScaffoldMessenger.of(navContext).showSnackBar(
              const SnackBar(
                content: Text('Reservation cancelled - Time limit exceeded'),
                backgroundColor: Colors.red,
              ),
            );
            
            Navigator.pushAndRemoveUntil(
              navContext,
              MaterialPageRoute(builder: (_) => const MapScreen()),
              (route) => false,
            );
          }
        },
        onCancelPressed: () async {
          print("❌ User cancelled reservation - ID: $reservationId");
          
          // Update reservation status in database
          final updated = await ReservationService.updateReservationStatus(
            reservationId: int.parse(reservationId),
            status: 'cancelled',
          );
          
          if (updated) {
            print("✅ Reservation cancelled in database");
          }
          
          await StorageService.removePendingReservation();
          
          final navContext = navigatorKey.currentContext;
          if (navContext != null) {
            ScaffoldMessenger.of(navContext).showSnackBar(
              const SnackBar(
                content: Text('Reservation cancelled successfully'),
                backgroundColor: Colors.orange,
              ),
            );
            
            Navigator.pushAndRemoveUntil(
              navContext,
              MaterialPageRoute(builder: (_) => const MapScreen()),
              (route) => false,
            );
          }
        },
        onPaymentPressed: () {
          if (navigatorKey.currentContext != null) {
            Navigator.pushReplacement(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  price: price,
                  garage: garage,
                ),
              ),
            );
          }
        },
      );
    }
  }

  // Add the restoreNotificationWithState method
  static Future<void> restoreNotificationWithState(
    BuildContext context,
    Map<String, dynamic> savedState,
  ) async {
    final reservationData = savedState['reservationData'];
    final reservationId = savedState['reservationId']; // Get reservation ID from saved state
    final garageName = reservationData['garageName'] ?? 'Parking Garage';
    final section = reservationData['sectionId'] ?? 'A';
    final price = (reservationData['price'] as num).toDouble();
    
    // Create garage object from saved data
    final garage = Garage(
      id: reservationData['garageId'],
      name: reservationData['garageName'],
      latitude: reservationData['garageLatitude'] ?? 0.0,
      longitude: reservationData['garageLongitude'] ?? 0.0,
    );
    
    await showCountdownNotification(
      garageName: garageName,
      section: section,
      onCountdownComplete: () async {
        // Update reservation status in database
        final updated = await ReservationService.updateReservationStatus(
          reservationId: int.parse(reservationId), // Convert string to int
          status: 'cancelled',
        );
        
        if (updated) {
          print("✅ Reservation cancelled in database");
        }
        
        await StorageService.removePendingReservation();
        
        final navContext = navigatorKey.currentContext;
        if (navContext != null) {
          ScaffoldMessenger.of(navContext).showSnackBar(
            const SnackBar(
              content: Text('Reservation cancelled - Time limit exceeded'),
              backgroundColor: Colors.red,
            ),
          );
          
          Navigator.pushAndRemoveUntil(
            navContext,
            MaterialPageRoute(builder: (_) => const MapScreen()),
            (route) => false,
          );
        }
      },
      onCancelPressed: () async {
        print("❌ User cancelled reservation - ID: $reservationId");
        
        // Update reservation status in database
        final updated = await ReservationService.updateReservationStatus(
          reservationId: int.parse(reservationId), // Convert string to int
          status: 'cancelled',
        );
        
        if (updated) {
          print("✅ Reservation cancelled in database");
        } else {
          print("❌ Failed to update reservation status in database");
        }
        
        await StorageService.removePendingReservation();
        
        final navContext = navigatorKey.currentContext;
        if (navContext != null) {
          ScaffoldMessenger.of(navContext).showSnackBar(
            const SnackBar(
              content: Text('Reservation cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
          
          Navigator.pushAndRemoveUntil(
            navContext,
            MaterialPageRoute(builder: (_) => const MapScreen()),
            (route) => false,
          );
        }
      },
      onPaymentPressed: () {
        final navContext = navigatorKey.currentContext;
        if (navContext != null) {
          Navigator.push(
            navContext,
            MaterialPageRoute(
              builder: (_) => PaymentScreen(
                price: price,
                garage: garage,
              ),
            ),
          );
        }
      },
    );
  }

  // Also update the existing restoreCountdownFromSavedState method
  static Future<void> restoreCountdownFromSavedState(
    BuildContext context,
    Map<String, dynamic> savedState,
  ) async {
    final expiryTime = DateTime.parse(savedState['expiryTime']);
    final remainingDuration = expiryTime.difference(DateTime.now());
    
    if (remainingDuration.inSeconds > 0) {
      _remainingSeconds = remainingDuration.inSeconds;
      await restoreNotificationWithState(context, savedState); // Use the new method
    }
  }

  // This is the function that shows the countdown notification
  static Future<void> showCountdownNotification({
    required String garageName,
    required String section,
    required Function onCountdownComplete,
    required Function onCancelPressed,
    required Function onPaymentPressed,
  }) async {
    if (!_isInitialized) {
      print("❌ NotificationService not initialized!");
      return;
    }

    print("🔔 Starting countdown notification for $garageName - Section $section");
    
    _onCountdownComplete = onCountdownComplete;
    _onCancelPressed = onCancelPressed;
    _onPaymentPressed = onPaymentPressed;
    
    // Don't reset to 1200 if _remainingSeconds has already been set by restore
    if (_remainingSeconds == 1200 || _remainingSeconds <= 0) {
      _remainingSeconds = 1200; // Only reset if it's the default or expired
    }

    // Show initial notification immediately
    await _updateCountdownNotification(garageName, section);

    // Cancel any existing timer
    _countdownTimer?.cancel();
    
    // Start countdown timer that updates every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _remainingSeconds--;
      
      if (_remainingSeconds <= 0) {
        print("⏰ Countdown completed!");
        timer.cancel();
        await cancelNotification();
        _onCountdownComplete?.call();
      } else {
        // Update notification every second to show real-time countdown
        await _updateCountdownNotification(garageName, section);
      }
    });
  }

  static Future<void> _updateCountdownNotification(String garageName, String section) async {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    // Calculate progress (0 to 100)
    final progress = ((1200 - _remainingSeconds) / 1200 * 100).round();
    
    // Create notification content
    final String notificationTitle = '⏱️ $timeString - Reservation Pending';
    final String notificationBody = '$garageName - Section $section';

    final androidDetails = AndroidNotificationDetails(
      'parking_countdown',
      'Parking Reservation Countdown',
      channelDescription: 'Shows countdown for pending parking reservations',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'Reservation countdown',
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      silent: true,
      showWhen: false,
      usesChronometer: false,
      chronometerCountDown: false,
      timeoutAfter: null,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      progress: progress,
      maxProgress: 100,
      showProgress: true,
      indeterminate: false,
      subText: 'Complete payment to confirm',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        '$garageName\nSection: $section\n\nTime Remaining: $timeString\n\nComplete payment within the time limit or your reservation will be cancelled.',
        contentTitle: '⏱️ $timeString - Reservation Pending',
        summaryText: 'Choose an action below',
      ),
      color: _remainingSeconds <= 300 ? Colors.red : Colors.orange,
      colorized: true,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'go_to_payment',
          'PAY NOW',
          showsUserInterface: true,
          cancelNotification: false,
          titleColor: Colors.green,
        ),
        AndroidNotificationAction(
          'cancel_reservation',
          'CANCEL',
          showsUserInterface: true,
          cancelNotification: false,
          titleColor: Colors.red,
        ),
      ],
      fullScreenIntent: _remainingSeconds <= 60,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
      subtitle: 'Reservation Countdown',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        999,
        notificationTitle,
        notificationBody,
        notificationDetails,
      );
    } catch (e) {
      print("❌ Error updating notification: $e");
    }
  }

  static Future<void> cancelNotification() async {
    print("🔕 Cancelling notification and timer");
    _countdownTimer?.cancel();
    _remainingSeconds = 1200;
    await _notifications.cancel(999);
    await _notifications.cancelAll();
  }

  

  static int getRemainingSeconds() => _remainingSeconds;
  static bool isCountdownActive() => _countdownTimer?.isActive ?? false;
static Future<void> showExtensionReminder({
  required int reservationId,
  required String garageName,
  required String section,
  required int minutesRemaining,
}) async {
  if (!_isInitialized) {
    print("❌ NotificationService not initialized!");
    return;
  }

  final  androidDetails = AndroidNotificationDetails(
    'parking_extension',
    'Parking Extension Reminder',
    channelDescription: 'Reminds users to extend their parking reservation',
    importance: Importance.max,
    priority: Priority.max,
    ticker: 'Extension reminder',
    styleInformation: BigTextStyleInformation(
      'Your parking reservation at $garageName (Section $section) will expire in $minutesRemaining minutes.\n\nWould you like to extend your parking time?',
      contentTitle: '⏰ Parking Expiring Soon!',
      summaryText: 'Tap to extend',
    ),
    color: Colors.orange,
    colorized: true,
    actions: const <AndroidNotificationAction>[
      AndroidNotificationAction(
        'extend_reservation',
        'EXTEND TIME',
        showsUserInterface: true,
        cancelNotification: true,
        titleColor: Colors.green,
      ),
      AndroidNotificationAction(
        'dismiss_reminder',
        'DISMISS',
        showsUserInterface: false,
        cancelNotification: true,
      ),
    ],
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    subtitle: 'Parking Extension',
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  final notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  try {
    await _notifications.show(
      1001 + reservationId, // Unique ID for extension notifications
      '⏰ Parking Expiring Soon!',
      '$garageName - Section $section',
      notificationDetails,
    );
  } catch (e) {
    print("❌ Error showing extension notification: $e");
  }
}
  
}