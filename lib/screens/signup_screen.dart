import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_components.dart';
import '../managers/auth_manager.dart';

// --- COLORS (Matching your RUET App Pink/Dark Theme) ---
const Color backgroundBlack = Color(0xFF000000);
const Color primaryPink = Color(0xFFE91E63);
const Color textGray = Color(0xFF9E9E9E);
const Color surfaceGray = Color(0xFF1C1C1C);

class SignUpScreen extends StatefulWidget {
  final Function(String email, String password) onSignUpSuccess;
  final VoidCallback onLoginClick;

  const SignUpScreen({
    super.key,
    required this.onSignUpSuccess,
    required this.onLoginClick,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthManager _authManager = AuthManager();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please fill in all fields");
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = "Passwords do not match");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _authManager.signUp(email, password, (success, message) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (success) {
        widget.onSignUpSuccess(email, password);
      } else {
        setState(() => _errorMessage = message ?? "Registration failed");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),

            // Header Text
            const Text(
              "Create Your\nAccount.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Join us to manage your settings and\nexplore all features",
              style: TextStyle(color: textGray, fontSize: 16, height: 1.4),
            ),

            const SizedBox(height: 48),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: primaryPink, fontSize: 14),
                ),
              ),

            // Full Name Input
            const Text("Full Name", style: TextStyle(color: textGray, fontSize: 14)),
            const SizedBox(height: 8),
            CustomTextField(
              placeholder: "Full Name",
              controller: _fullNameController,
            ),

            const SizedBox(height: 24),

            // Email Input
            const Text("Email", style: TextStyle(color: textGray, fontSize: 14)),
            const SizedBox(height: 8),
            CustomTextField(
              placeholder: "Enter your email",
              controller: _emailController,
            ),

            const SizedBox(height: 24),

            // Password Input
            const Text("Password", style: TextStyle(color: textGray, fontSize: 14)),
            const SizedBox(height: 8),
            CustomTextField(
              placeholder: "••••••••",
              controller: _passwordController,
              isPassword: true,
            ),

            const SizedBox(height: 24),

            // Confirm Password Input
            const Text("Confirm Password", style: TextStyle(color: textGray, fontSize: 14)),
            const SizedBox(height: 8),
            CustomTextField(
              placeholder: "Confirm Password",
              controller: _confirmPasswordController,
              isPassword: true,
            ),

            const SizedBox(height: 40),

            // Create Account Button
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Create Account",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 48),

            // Login Link
            Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 15, fontFamily: 'Roboto'),
                  children: [
                    const TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: textGray),
                    ),
                    TextSpan(
                      text: "Login",
                      style: const TextStyle(color: primaryPink, fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()..onTap = widget.onLoginClick,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
