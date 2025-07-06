import 'package:flutter/material.dart';
import 'package:smart_parking_app/core/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> reservations = [];
  bool isLoading = true;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    try {
      final userData = await StorageService.getUserData();
      
      if (userData != null && userData['username'] != null) {
        // Get user profile first to get userId
        final profileResponse = await http.get(
          Uri.parse("http://192.168.1.15:5000/api/profile/${userData['username']}"),
          headers: {"Content-Type": "application/json"},
        );
        
        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          userId = profileData['userId'];
          
          // Get reservations using the new endpoint
          final response = await http.get(
            Uri.parse("http://192.168.1.15:5000/api/profile/$userId/reservations"),
            headers: {"Content-Type": "application/json"},
          );
          
          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            setState(() {
              reservations = data.map((e) => e as Map<String, dynamic>).toList();
              isLoading = false;
            });
            
            // Debug print to see the actual data structure
            print("Reservations data: ${jsonEncode(reservations)}");
            return;
          }
        }
      }
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error loading reservations: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.info;
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown';
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),

      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reservations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No reservations yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    // Use correct case for field names from API
                    final status = reservation['status'] ?? reservation['Status'] ?? 'unknown';
                    final garageName = reservation['garageName'] ?? reservation['GarageName'] ?? 'Unknown Garage';
                    final sectionId = reservation['sectionId'] ?? reservation['SectionId'] ?? 'Unknown';
                    final startTime = reservation['startTime'] ?? reservation['StartTime'];
                    final endTime = reservation['endTime'] ?? reservation['EndTime'];
                    final paidAmount = reservation['paidAmount'] ?? reservation['PaidAmount'];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(status),
                          child: Icon(
                            _getStatusIcon(status),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          garageName.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Section: ${sectionId.toString()}'),
                            Text(
                              '${_formatDateTime(startTime?.toString())} - ${_formatDateTime(endTime?.toString())}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (paidAmount != null && (status?.toString().toLowerCase() == 'active' || status?.toString().toLowerCase() == 'confirmed'))
                              Text(
                                'Paid: ${paidAmount.toString()} EGP',
                                style: const TextStyle(fontSize: 12, color: Colors.green),
                              ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            status.toString().toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: _getStatusColor(status)?.withOpacity(0.1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}