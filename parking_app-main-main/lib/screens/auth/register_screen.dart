import 'package:flutter/material.dart';
import 'package:smart_parking_app/core/services/register_service.dart';
import 'package:smart_parking_app/widgets/forms/registerform.dart';
import 'package:smart_parking_app/screens/auth/login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  bool _isPasswordStrong(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    );
    return regex.hasMatch(password);
  }

  bool _isEmailValid(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(email)) return false;

    final allowedDomains = [
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
      'icloud.com',
      'outlook.com',
      'aol.com',
    ];
    final domain = email.split('@').last.toLowerCase();
    return allowedDomains.contains(domain);
  }

  bool _isNationalIdValid(String nationalId) => nationalId.length == 14;

  bool _isArabicLettersWithSpaces(String input) =>
      RegExp(r'^[\u0600-\u06FF\s]+$').hasMatch(input); // Arabic letters + spaces

  bool _isNumbersOnly(String input) =>
      RegExp(r'^\d+$').hasMatch(input); // Only digits

  void handleRegister(BuildContext context, Map<String, dynamic> formData) async {
    final password = formData["password"] ?? "";
    final email = formData["email"] ?? "";
    final nationalId = formData["nationalId"] ?? "";
    final plateLetters = (formData["plateLetters"] ?? "").trim();
    final plateNumbers = formData["plateNumbers"] ?? "";

    if (!_isPasswordStrong(password)) {
      _showSnack(context, 'Password must be at least 8 characters and include uppercase, lowercase, number, and symbol.');
      return;
    }

    if (!_isEmailValid(email)) {
      _showSnack(context, 'Please enter a valid email like name@gmail.com');
      return;
    }

    if (!_isNationalIdValid(nationalId)) {
      _showSnack(context, 'National ID must be exactly 14 digits.');
      return;
    }

    if (!_isArabicLettersWithSpaces(plateLetters)) {
      _showSnack(context, 'Plate letters must be Arabic letters only (spaces allowed).');
      return;
    }

    if (!_isNumbersOnly(plateNumbers)) {
      _showSnack(context, 'Plate numbers must contain only digits.');
      return;
    }

    final requestBody = {
      "nationalId": nationalId.trim(),
      "username": formData["username"],
      "email": email.trim(),
      "password": password.trim(),
      "plateLetters": plateLetters,
      "plateNumbers": plateNumbers,
      "disability": formData["disability"] ?? false,
    };

    final success = await RegisterService().register(requestBody);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } else {
      _showSnack(context, 'Registration failed. Please try again.');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: RegisterForm(
          onSubmit: (data) => handleRegister(context, data),
        ),
      ),
    );
  }
}
