import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController emailController; // still named emailController for reuse
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final void Function() onSubmit;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🌀 Logo
              const Padding(
                padding: EdgeInsets.only(bottom: 24.0, top: 10.0),
                child: Image(
                  image: AssetImage('assets/images/logo.png'),
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),

              // 🔵 Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Login Your Account",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(219, 1, 44, 86),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 👤 Username Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter username' : null,
                ),
              ),
              const SizedBox(height: 20),

              // 🔒 Password Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter password' : null,
                ),
              ),
              const SizedBox(height: 30),

              // 🔘 Login Button (Reduced Width)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 7, 65, 112),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Login",
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
      ),
    );
  }
}
