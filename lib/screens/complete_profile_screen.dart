import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color zinc400 = Color(0xFFA1A1AA);
const Color emerald500 = Color(0xFF10B981);

class CompleteProfileScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const CompleteProfileScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _nameController = TextEditingController();
  final _deptController = TextEditingController();
  final _seriesController = TextEditingController();
  final _mobileController = TextEditingController();

  bool _isLoading = false;
  String? _profileImageUrl; 

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
    
    // Set initial name if available from Google
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? "";
      _profileImageUrl = user.photoURL;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _deptController.dispose();
    _seriesController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // TODO: Implement image_picker and Firebase Storage if needed
    // For now, we keep the existing photoURL if it exists
  }

  void _handleContinue() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your full name")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = UserProfile(
        uid: user.uid,
        fullName: _nameController.text.trim(),
        dept: _deptController.text.trim(),
        series: _seriesController.text.trim(),
        mobile: _mobileController.text.trim(),
        profileImageBase64: _profileImageUrl,
      );

      await DatabaseManager.saveUserProfile(profile);
      
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onComplete();
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving profile: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  
                  // Header
                  const Text(
                    "Complete Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Help others recognize you on campus.",
                    style: TextStyle(color: zinc400, fontSize: 14),
                  ),

                  const SizedBox(height: 48),

                  // Profile Picture
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              color: zinc900,
                              borderRadius: BorderRadius.circular(40),
                              image: (_profileImageUrl != null)
                                ? DecorationImage(
                                    image: NetworkImage(_profileImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            ),
                            child: (_profileImageUrl == null)
                                ? const Icon(Icons.person, color: zinc400, size: 48)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: -8,
                          right: -8,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: emerald500,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 4),
                            ),
                            child: const Icon(Icons.add, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 24.0),
                      child: Text(
                        "UPLOAD PROFILE PICTURE",
                        style: TextStyle(
                          color: zinc400,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Input Form
                  _onboardingTextField(
                    label: "FULL NAME",
                    controller: _nameController,
                    placeholder: "Enter your name",
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _onboardingTextField(
                          label: "DEPT",
                          controller: _deptController,
                          placeholder: "e.g. CSE",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _onboardingTextField(
                          label: "SERIES",
                          controller: _seriesController,
                          placeholder: "e.g. '21",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _onboardingTextField(
                    label: "MOBILE NO",
                    controller: _mobileController,
                    placeholder: "+880 1XXX XXXXXX",
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 60),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emerald500,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        disabledBackgroundColor: emerald500.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : const Text(
                              "CONTINUE",
                              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: widget.onComplete,
                      child: const Text(
                        "Skip for now",
                        style: TextStyle(color: zinc400, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _onboardingTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: zinc400,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: zinc400.withOpacity(0.5)),
            filled: true,
            fillColor: zinc900,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: emerald500),
            ),
          ),
        ),
      ],
    );
  }
}
