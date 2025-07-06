import 'package:flutter/material.dart';
import 'package:smart_parking_app/core/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? profilePictureBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final storedData = await StorageService.getUserData();
      
      if (storedData != null && storedData['username'] != null) {
        // Use the new profile endpoint
        final response = await http.get(
          Uri.parse("http://192.168.1.15:5000/api/profile/${storedData['username']}"),
          headers: {"Content-Type": "application/json"},
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            setState(() {
              userData = {
                'username': data['username'],
                'email': data['email'] ?? 'Not provided',
                'licensePlate': data['licensePlate'] ?? 'Not provided',
                'userId': data['userId'],
              };
              profilePictureBase64 = data['profilePicture'];
              isLoading = false;
            });
            return;
          }
        }
      }
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      
      if (image != null && userData != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        
        // Upload to server
        final response = await http.post(
          Uri.parse("http://192.168.1.15:5000/api/profile/${userData!['userId']}/picture"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "imageBase64": base64Image,
          }),
        );
        
        if (response.statusCode == 200) {
          setState(() {
            profilePictureBase64 = base64Image;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile picture')),
      );
    }
  }

  Future<void> _removeProfilePicture() async {
    if (userData == null) return;
    
    try {
      final response = await http.delete(
        Uri.parse("http://192.168.1.15:5000/api/profile/${userData!['userId']}/picture"),
        headers: {"Content-Type": "application/json"},
      );
      
      if (response.statusCode == 200) {
        setState(() {
          profilePictureBase64 = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed!')),
        );
      }
    } catch (e) {
      print("Error removing profile picture: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove profile picture')),
      );
    }
  }

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (profilePictureBase64 != null && profilePictureBase64!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Profile Picture'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRemoveConfirmationDialog();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(profilePictureBase64 != null && profilePictureBase64!.isNotEmpty 
                    ? 'Change Profile Picture' 
                    : 'Add Profile Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRemoveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Profile Picture'),
          content: const Text('Are you sure you want to remove your profile picture?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeProfilePicture();
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileImage() {
    if (profilePictureBase64 != null && profilePictureBase64!.isNotEmpty) {
      return Container(
        width: 120,
        height: 120,
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
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            userData!['username'][0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),


      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text('Failed to load user data'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          _buildProfileImage(),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                onPressed: _showProfilePictureOptions,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Username'),
                          subtitle: Text(userData!['username']),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(userData!['email']),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: const Text('License Plate'),
                          subtitle: Text(userData!['licensePlate']),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}