import 'package:flutter/material.dart';
import 'package:smart_parking_app/core/services/storage_service.dart';
import 'package:smart_parking_app/core/services/auth_service.dart';
import 'package:smart_parking_app/screens/profile/profile_screen.dart';
import 'package:smart_parking_app/screens/profile/history_screen.dart';
import 'package:smart_parking_app/screens/auth/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileButton extends StatefulWidget {
  const ProfileButton({Key? key}) : super(key: key);

  @override
  State<ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<ProfileButton> {
  String? username;
  String? profilePictureBase64;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await StorageService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        username = userData['username'];
      });
      
      // Load profile picture
      try {
        final response = await http.get(
          Uri.parse("http://192.168.1.15:5000/api/profile/${userData['username']}"),
          headers: {"Content-Type": "application/json"},
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && mounted) {
            setState(() {
              profilePictureBase64 = data['profilePicture'];
            });
          }
        }
      } catch (e) {
        print("Error loading profile picture: $e");
      }
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildAvatar() {
    if (profilePictureBase64 != null && profilePictureBase64!.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: MemoryImage(base64Decode(profilePictureBase64!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _getInitials(username),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      icon: _buildAvatar(),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.grey[700], size: 20),
              const SizedBox(width: 12),
              const Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'history',
          child: Row(
            children: [
              Icon(Icons.history, color: Colors.grey[700], size: 20),
              const SizedBox(width: 12),
              const Text('History'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red[700], size: 20),
              const SizedBox(width: 12),
              Text('Logout', style: TextStyle(color: Colors.red[700])),
            ],
          ),
        ),
      ],
      onSelected: (String value) async {
        switch (value) {
          case 'profile':
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            // Reload user data after returning from profile
            _loadUserData();
            break;
          case 'history':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
            break;
          case 'logout':
            // Clear all saved data
            await AuthService.logout();
            await StorageService.clearAll();
            
            // Navigate to login and remove all routes
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
            );
            break;
        }
      },
    );
  }
}