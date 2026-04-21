import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_components.dart';
import '../managers/auth_manager.dart';

// --- COLORS (Modern High-Contrast Zinc/Emerald Palette) ---
const Color backgroundBlack = Color(0xFF000000);
const Color emerald500 = Color(0xFF10B981);
const Color zinc900 = Color(0xFF18181B);
const Color zinc800 = Color(0xFF27272A);
const Color zinc500 = Color(0xFF71717A);
const Color zinc400 = Color(0xFFA1A1AA);

enum AuthMode { login, signup }

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final Function(String, String) onSignUpSuccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onSignUpSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  AuthMode _authMode = AuthMode.login;
  final AuthManager _authManager = AuthManager();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _authMode = _authMode == AuthMode.login ? AuthMode.signup : AuthMode.login;
      _errorMessage = null;
    });
  }

  void _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Required fields are missing");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_authMode == AuthMode.login) {
      _authManager.login(email, password, (success, message) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (success) widget.onLoginSuccess();
        else setState(() => _errorMessage = message);
      });
    } else {
      if (password != _confirmPasswordController.text) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Passwords do not match";
        });
        return;
      }
      _authManager.signUp(email, password, (success, message) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (success) widget.onSignUpSuccess(email, password);
        else setState(() => _errorMessage = message);
      });
    }
  }

  void _handleGoogleSignIn() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _authManager.signInWithGoogle((success, message) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (success) widget.onLoginSuccess();
      else setState(() => _errorMessage = message);
    });
  }

  // --- FORGOT PASSWORD LOGIC ---

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Reset Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your RUET email address. If you signed up with Google, this will send a link to let you set a manual password.",
              style: TextStyle(color: zinc500, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: resetEmailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Email address",
                hintStyle: const TextStyle(color: zinc500),
                filled: true,
                fillColor: backgroundBlack,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: zinc500)),
          ),
          ElevatedButton(
            onPressed: () {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter your email address"), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context);
              _resetPassword(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: emerald500,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Send Link", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(String email) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: emerald500)),
    );

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      Navigator.pop(context); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset link sent! Please check your inbox and spam folder."),
          backgroundColor: emerald500,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "An error occurred"), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              _buildBrandLogo(),
              const SizedBox(height: 60),
              _buildAuthToggleForm(),
              const SizedBox(height: 40),
              _buildSocialLogin(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandLogo() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: zinc900,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: zinc800),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: emerald500, size: 40),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: backgroundBlack, shape: BoxShape.circle),
                child: const Icon(Icons.search, color: emerald500, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          "RUET ARCHIVE",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: emerald500, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildAuthToggleForm() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.1),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
      child: _authMode == AuthMode.login ? _buildLoginForm() : _buildSignUpForm(),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey("login_form"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField("Email", _emailController, "Enter your email"),
        const SizedBox(height: 20),
        _buildInputField("Password", _passwordController, "••••••••", isPassword: true),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text("Forgot password?", style: TextStyle(color: emerald500, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (_errorMessage != null) _buildErrorText(),
        const SizedBox(height: 24),
        _buildPrimaryButton("Login"),
        const SizedBox(height: 24),
        _buildBottomToggle("Don't have an account?", "Sign Up"),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      key: const ValueKey("signup_form"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField("Full Name", _fullNameController, "e.g. John Doe"),
        const SizedBox(height: 20),
        _buildInputField("Email", _emailController, "Enter your email"),
        const SizedBox(height: 20),
        _buildInputField("Password", _passwordController, "••••••••", isPassword: true),
        const SizedBox(height: 20),
        _buildInputField("Confirm Password", _confirmPasswordController, "••••••••", isPassword: true),
        if (_errorMessage != null) _buildErrorText(),
        const SizedBox(height: 32),
        _buildPrimaryButton("Sign Up"),
        const SizedBox(height: 24),
        _buildBottomToggle("Already have an account?", "Login"),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: zinc400, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: zinc500),
            filled: true,
            fillColor: zinc900,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: emerald500, width: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: emerald500,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildBottomToggle(String leadText, String actionText) {
    return Center(
      child: GestureDetector(
        onTap: _toggleMode,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: zinc500),
            children: [
              TextSpan(text: "$leadText "),
              TextSpan(text: actionText, style: const TextStyle(color: emerald500, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorText() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: Divider(color: zinc900)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("OR", style: TextStyle(color: zinc500, fontSize: 12, fontWeight: FontWeight.bold))),
            Expanded(child: Divider(color: zinc900)),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: zinc900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: zinc800),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "G",
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 16),
                Text("Sign in with Google", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
