import 'package:flutter/material.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color emerald500 = Color(0xFF10B981);
const Color zinc400 = Color(0xFFA1A1AA);
const Color textGray = Color(0xFF9E9E9E);

class EmailVerificationScreen extends StatefulWidget {
  final VoidCallback onVerificationSuccess;
  final VoidCallback onBackToLogin;

  const EmailVerificationScreen({
    super.key,
    required this.onVerificationSuccess,
    required this.onBackToLogin,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;

  void _checkVerification() async {
    setState(() => _isLoading = true);
    
    // Simulation of Firebase user reload and verification check
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real app:
    // await FirebaseAuth.instance.currentUser?.reload();
    // if (FirebaseAuth.instance.currentUser?.emailVerified == true) { ... }
    
    setState(() => _isLoading = false);
    
    // For now, let's just trigger success for demo purposes or show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Checking verification status...")),
    );
    
    // Uncomment when ready:
    // widget.onVerificationSuccess();
  }

  void _resendEmail() async {
    // Simulation of sending verification email
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Verification email resent.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email,
                color: emerald500,
                size: 80,
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                "Verify Your Email",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                "A verification link has been sent to your email. Please verify it to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGray,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emerald500,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                        )
                      : const Text(
                          "I'VE VERIFIED",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: _resendEmail,
                child: const Text(
                  "Resend Email",
                  style: TextStyle(
                    color: zinc400,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: widget.onBackToLogin,
                child: const Text(
                  "Back to Login",
                  style: TextStyle(
                    color: emerald500,
                    fontSize: 14,
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
