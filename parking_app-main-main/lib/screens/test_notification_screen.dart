// lib/screens/test_notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class TestNotificationScreen extends StatefulWidget {
  @override
  _TestNotificationScreenState createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends State<TestNotificationScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.notification.status;
    setState(() {
      _notificationsEnabled = status.isGranted;
    });
  }

  Future<void> _initializeNotifications() async {
    // Initialize settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'test_channel', // id
      'Test Notifications', // title
      description: 'This channel is used for test notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(channel);
    print("✅ Notification channel created");
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationsEnabled = status.isGranted;
    });
  }

  Future<void> _showSimpleNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'This channel is used for test notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Notification',
      'This is a test notification. If you see this, notifications are working!',
      platformChannelSpecifics,
    );
    
    print("📢 Notification should be shown now");
  }

  Future<void> _showPersistentNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'This channel is used for test notifications.',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: 75,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      1,
      'Persistent Notification',
      'This notification cannot be dismissed',
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Notifications Enabled: $_notificationsEnabled',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            if (!_notificationsEnabled)
              ElevatedButton(
                onPressed: _requestPermissions,
                child: Text('Request Notification Permission'),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showSimpleNotification,
              child: Text('Show Simple Notification'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showPersistentNotification,
              child: Text('Show Persistent Notification'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await flutterLocalNotificationsPlugin.cancelAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('All notifications cancelled')),
                );
              },
              child: Text('Cancel All Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}