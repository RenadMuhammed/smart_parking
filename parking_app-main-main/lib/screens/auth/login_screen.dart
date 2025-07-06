import 'package:flutter/material.dart';
import 'package:smart_parking_app/screens/auth/forgot_password_screen.dart';
import 'package:smart_parking_app/screens/auth/register_screen.dart';
import 'package:smart_parking_app/screens/home/map_screen.dart';
import 'package:smart_parking_app/widgets/forms/loginform.dart';
import 'package:smart_parking_app/core/services/auth_service.dart';
import 'package:smart_parking_app/core/services/session_service.dart'; // Add this import
import 'package:smart_parking_app/core/services/storage_service.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      final response = await AuthService.login(username, password);

      if (response['success'] == true) {
        // Save username to session
        await SessionService.saveUsername(username);
        await StorageService.saveUserData({
        'username': username,
        'loginTime': DateTime.now().toIso8601String(),
      });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                LoginForm(
                  emailController: _usernameController,
                  passwordController: _passwordController,
                  formKey: _formKey,
                  onSubmit: () => _login(context),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text("Forgot Password?"),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text("Create Account"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
