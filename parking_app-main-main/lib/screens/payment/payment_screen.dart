import 'package:flutter/material.dart';
import 'package:smart_parking_app/core/services/payment_service.dart';
import 'package:smart_parking_app/core/services/session_service.dart';
import 'package:smart_parking_app/screens/home/map_screen.dart';
import 'package:smart_parking_app/services/garage_service.dart';
import 'package:smart_parking_app/core/services/reservation_service.dart';
import 'package:smart_parking_app/core/services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_parking_app/core/services/app_state_manager.dart';
import 'package:smart_parking_app/core/services/storage_service.dart';
import 'package:smart_parking_app/widgets/common/profile_button.dart';

class PaymentScreen extends StatefulWidget {
  final double price;
  final Garage? garage;
  final bool isExtension; // Add this
  final int? extensionReservationId; // Add this

  const PaymentScreen({
    Key? key, 
    required this.price,
    this.garage,
    this.isExtension = false, // Add this
    this.extensionReservationId, // Add this
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedCard = 'Visa';
  final _cardNumberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _otpController = TextEditingController();

  final String staticOTP = "466616";
  
  String? currentUsername;
  int? currentUserId;

  bool _isCardNumberValid = true;
  bool _isCvvValid = true;
  bool _isExpiryDateValid = true;
  String? _expiryDateError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _expiryDateController.addListener(_formatExpiryDate);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final username = await SessionService.getUsername();
    if (username != null) {
      setState(() {
        currentUsername = username;
      });
      await _getUserId(username);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getUserId(String username) async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.1.15:5000/api/user/$username"),
        headers: {"Content-Type": "application/json"},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            currentUserId = data['userId'];
          });
        }
      }
    } catch (e) {
      print("❌ Error getting user ID: $e");
    }
  }

  void _formatExpiryDate() {
    final text = _expiryDateController.text;
    
    // Remove any non-numeric characters
    final numericText = text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numericText.length >= 2 && !text.contains("/")) {
      final month = numericText.substring(0, 2);
      final year = numericText.substring(2);
      _expiryDateController.text = "$month/$year";
      _expiryDateController.selection = TextSelection.fromPosition(
        TextPosition(offset: _expiryDateController.text.length),
      );
    }
  }

  String? _validateExpiryDate(String value) {
    // Check format
    final regex = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$');
    if (!regex.hasMatch(value)) {
      return 'Invalid format. Use MM/YY';
    }

    // Parse month and year
    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]) + 2000; // Convert YY to YYYY

    // Get current date
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Check if card is expired
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Card has expired';
    }

    // Check if year is too far in the future (e.g., more than 20 years)
    if (year > currentYear + 20) {
      return 'Invalid expiry year';
    }

    return null; // Valid
  }

  void _showOtpDialog() {
    if (currentUserId == null || currentUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please log in to make a payment.")),
      );
      return;
    }

    final cardNumber = _cardNumberController.text.trim();
    final cvv = _cvvController.text.trim();
    final expiryDate = _expiryDateController.text.trim();

    // Validate card number
    setState(() {
      _isCardNumberValid = RegExp(r'^\d{16}$').hasMatch(cardNumber);
    });

    // Validate CVV
    setState(() {
      _isCvvValid = RegExp(r'^\d{3}$').hasMatch(cvv);
    });

    // Validate expiry date
    final expiryError = _validateExpiryDate(expiryDate);
    setState(() {
      _isExpiryDateValid = expiryError == null;
      _expiryDateError = expiryError;
    });

    if (!_isCardNumberValid || !_isCvvValid || !_isExpiryDateValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !_isCardNumberValid
                ? "❌ Card number must be exactly 16 digits."
                : !_isCvvValid
                    ? "❌ CVV must be exactly 3 digits."
                    : "❌ $_expiryDateError",
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter OTP"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "We've sent a verification code to your registered mobile number.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: "OTP",
                  hintText: "Enter 6-digit code",
                  counterText: "",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (_otpController.text == staticOTP) {
                  final success = await PaymentService().createPayment(
                    userId: currentUserId!,
                    username: currentUsername!,
                    cardNumber: cardNumber,
                    cardType: selectedCard,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Payment Success! Reservation Active.")),
                  );
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(
                          selectedGarage: widget.garage, // ✅ this must be non-null
                        ),
                      ),
                      (route) => false,
                    );
                  if (success) {
                    await NotificationService.cancelNotification();
                    await StorageService.clearCurrentReservationId();
                    
                    final savedReservation = await StorageService.getPendingReservation();
                    
                    if (widget.isExtension && widget.extensionReservationId != null) {
                          // Handle extension payment
                          final response = await http.post(
                            Uri.parse('http://192.168.1.15:5000/api/extension/confirm/${widget.extensionReservationId}'),
                            headers: {'Content-Type': 'application/json'},
                          );
                          
                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ Reservation Extended Successfully!")),
                            );
                            
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const MapScreen()),
                              (route) => false,
                            );
                          }}

                    if (savedReservation != null) {
                      final reservationId = savedReservation['reservationId'];
                      final reservationData = savedReservation['reservationData'];
                      final endTime = DateTime.parse(reservationData['endTime']);
                      
                      await AppStateManager.saveReservationState(
                        reservationId: reservationId,
                        status: 'active',
                        expiryTime: endTime,
                        reservationData: reservationData,
                      );
                      
                      await ReservationService.updateReservationStatus(
                        reservationId: reservationId,
                        status: 'active',
                      );
                      
                      await SessionService.clearReservationId();
                      await NotificationService.cancelNotification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Payment Success! Reservation Active.")),
                      );
                      
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapScreen(
                            selectedGarage: widget.garage,
                          ),
                        ),
                        (route) => false,
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("❌ Payment failed while inserting to DB.")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Invalid OTP. Payment Failed.")),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cvvController.dispose();
    _expiryDateController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        actions: const [
          ProfileButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.payment, size: 48, color: Colors.blue),
                          const SizedBox(height: 8),
                          Text(
                            'Total Amount',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.price.toStringAsFixed(2)} EGP',
                            style: const TextStyle(
                              fontSize: 28, 
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: selectedCard,
                    decoration: const InputDecoration(
                      labelText: 'Card Type',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Visa', child: Text('Visa')),
                      DropdownMenuItem(value: 'MasterCard', child: Text('MasterCard')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCard = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    decoration: InputDecoration(
                      labelText: 'Card Number',
                      hintText: '1234 5678 9012 3456',
                      prefixIcon: const Icon(Icons.credit_card),
                      border: const OutlineInputBorder(),
                      errorText: _isCardNumberValid ? null : 'Card number must be 16 digits',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _expiryDateController,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          decoration: InputDecoration(
                            labelText: 'Expiry Date (MM/YY)',
                            hintText: '12/25',
                            prefixIcon: const Icon(Icons.date_range),
                            border: const OutlineInputBorder(),
                            errorText: _isExpiryDateValid ? null : _expiryDateError,
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'CVV',
                            hintText: '123',
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            errorText: _isCvvValid ? null : 'Invalid CVV',
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: currentUserId != null && currentUsername != null 
                        ? _showOtpDialog 
                        : null,
                    icon: const Icon(Icons.payment),
                    label: const Text("Pay Now"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (currentUserId == null || currentUsername == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        "Please log in to make a payment",
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your payment information is encrypted and secure',
                              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}