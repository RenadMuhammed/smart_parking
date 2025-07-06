import 'package:flutter/material.dart';

class RegisterForm extends StatefulWidget {
  final void Function(Map<String, dynamic> data) onSubmit;

  const RegisterForm({super.key, required this.onSubmit});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController plateLettersController = TextEditingController();
  final TextEditingController plateNumbersController = TextEditingController();

  bool? hasDisability;

  String? _validateNationalId(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter National ID';
    if (value.trim().length != 14) return 'National ID must be 14 digits';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter Email';
    final formatRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!formatRegex.hasMatch(value)) {
      return 'Enter a valid email format (e.g. name@gmail.com)';
    }

    final validDomains = [
      'gmail.com', 'yahoo.com', 'hotmail.com',
      'icloud.com', 'outlook.com', 'aol.com'
    ];

    final domain = value.split('@').last.toLowerCase();
    if (!validDomains.contains(domain)) {
      return 'Use a real domain like gmail.com or outlook.com';
    }

    return null;
  }

  String? _validatePlateLetters(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter plate letters';
    final arabicRegex = RegExp(r'^[\u0600-\u06FF\s]+$');
    if (!arabicRegex.hasMatch(value.trim())) {
      return 'Plate letters must be Arabic only';
    }
    return null;
  }

  String? _validatePlateNumbers(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter plate numbers';
    final numberRegex = RegExp(r'^\d+$');
    if (!numberRegex.hasMatch(value.trim())) {
      return 'Plate numbers must be digits only';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (hasDisability == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a disability option.')),
        );
        return;
      }

      widget.onSubmit({
        'nationalId': nationalIdController.text.trim(),
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'plateLetters': plateLettersController.text.trim(),
        'plateNumbers': plateNumbersController.text.trim(),
        'disability': hasDisability,
      });
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            Center(
              child: Text(
                'Register',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xDB014486),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextFormField(
                    controller: nationalIdController,
                    decoration: _buildInputDecoration('National ID *', Icons.credit_card),
                    keyboardType: TextInputType.number,
                    validator: _validateNationalId,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: usernameController,
                    decoration: _buildInputDecoration('Username *', Icons.person),
                    validator: (value) => value!.isEmpty ? 'Enter Username' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: emailController,
                    decoration: _buildInputDecoration('Email *', Icons.email),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: passwordController,
                    decoration: _buildInputDecoration('Password *', Icons.lock),
                    obscureText: true,
                    validator: (value) => value!.length < 8 ? 'Minimum 8 characters' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: plateLettersController,
                    decoration: _buildInputDecoration('Plate Letters (e.g. س ج ل) *', Icons.text_fields),
                    validator: _validatePlateLetters,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right, // ✅ Fix added
                    style: const TextStyle(fontFamily: 'Cairo'), // ✅ Arabic font
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: plateNumbersController,
                    decoration: _buildInputDecoration('Plate Numbers (e.g. 1234) *', Icons.confirmation_number),
                    keyboardType: TextInputType.number,
                    validator: _validatePlateNumbers,
                  ),
                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Do you have a disability?',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Yes'),
                        selected: hasDisability == true,
                        onSelected: (_) => setState(() => hasDisability = true),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('No'),
                        selected: hasDisability == false,
                        onSelected: (_) => setState(() => hasDisability = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: const Color.fromARGB(255, 84, 127, 161),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
