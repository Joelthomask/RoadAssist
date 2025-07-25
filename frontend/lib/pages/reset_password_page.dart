import 'package:flutter/material.dart';
import 'package:frontend/api_service.dart';

class ResetPasswordPage extends StatefulWidget {
  final ApiService apiService;

  const ResetPasswordPage({Key? key, required this.apiService}) : super(key: key);

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String errorMessage = '';

  void _resetPassword() async {
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        errorMessage = 'Password fields cannot be empty';
      });
      return;
    }
    if (newPassword.length < 8) {
      setState(() {
        errorMessage = 'Password must be at least 8 characters long';
      });
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      setState(() {
        errorMessage = 'Password must contain at least one uppercase letter';
      });
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(newPassword)) {
      setState(() {
        errorMessage = 'Password must contain at least one number';
      });
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() {
        errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      errorMessage = '';
    });

    final data = {'newPassword': newPassword};

    try {
      final response = await widget.apiService.postRequest('/reset-password', data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset successful: ${response.toString()}')),
      );
      Navigator.pushNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
              ),
              const SizedBox(height: 20),
              if (errorMessage.isNotEmpty)
                Text(errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetPassword,
                child: const Text('Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
