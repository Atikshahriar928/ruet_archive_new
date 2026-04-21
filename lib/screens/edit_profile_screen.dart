import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import '../widgets/custom_components.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color zinc400 = Color(0xFFA1A1AA);
const Color emerald500 = Color(0xFF10B981);

class EditProfileScreen extends StatefulWidget {
  final VoidCallback onSaveClick;

  const EditProfileScreen({
    super.key,
    required this.onSaveClick,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final _nameController = TextEditingController();
  final _deptController = TextEditingController();
  final _seriesController = TextEditingController();
  final _mobileController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGoogleUser = false;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _deptController.dispose();
    _seriesController.dispose();
    _mobileController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    
    try {
      final profile = await DatabaseManager.getUserProfile(user.uid);
      
      if (mounted) {
        setState(() {
          _nameController.text = profile?.fullName ?? user.displayName ?? "";
          _deptController.text = profile?.dept ?? "";
          _seriesController.text = profile?.series ?? "";
          _mobileController.text = profile?.mobile ?? "";
          _profileImageUrl = profile?.profileImageBase64 ?? user.photoURL;
          
          for (final userInfo in user.providerData) {
            if (userInfo.providerId == "google.com") {
              _isGoogleUser = true;
              break;
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 400,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profileImageUrl = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _handleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    
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
        setState(() => _isSaving = false);
        widget.onSaveClick();
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
      if (mounted) {
        setState(() => _isSaving = false);
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
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SafeArea(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: emerald500))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: zinc900, shape: BoxShape.circle),
                              child: const Icon(Icons.chevron_left, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            "Edit Profile",
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Profile Picture
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 128,
                                height: 128,
                                decoration: BoxDecoration(
                                  color: zinc900,
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(color: zinc900, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: ProfileImage(
                                    imageSource: _profileImageUrl,
                                    size: 128,
                                    borderRadius: 40,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -4,
                                right: -4,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: emerald500,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 24.0),
                          child: Text(
                            "UPLOAD NEW PICTURE",
                            style: TextStyle(
                              color: zinc500,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      _fieldWithLabel("Full Name", _nameController, "Full Name"),
                      _fieldWithLabel("Department", _deptController, "e.g. CSE, EEE"),
                      _fieldWithLabel("Series", _seriesController, "e.g. 20, 21"),
                      _fieldWithLabel("Mobile Number", _mobileController, "01xxxxxxxxx"),

                      const SizedBox(height: 32),
                      const Divider(color: zinc800, thickness: 1),
                      const SizedBox(height: 24),
                      const Text(
                        "SECURITY",
                        style: TextStyle(color: emerald500, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 24),

                      if (_isGoogleUser)
                        const Text(
                          "You are signed in with Google. Passwords are managed by your Google account.",
                          style: TextStyle(color: zinc400, fontSize: 14),
                        )
                      else
                        Column(
                          children: [
                            _fieldWithLabel("Current Password", _currentPasswordController, "••••••••", isPassword: true),
                            _fieldWithLabel("New Password", _newPasswordController, "••••••••", isPassword: true),
                            _fieldWithLabel("Confirm New Password", _confirmPasswordController, "••••••••", isPassword: true),
                          ],
                        ),

                      const SizedBox(height: 48),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: emerald500,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                            elevation: 16,
                            shadowColor: emerald500.withOpacity(0.3),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Text(
                                  "SAVE CHANGES",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
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

  Widget _fieldWithLabel(String label, TextEditingController controller, String placeholder, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            label,
            style: const TextStyle(color: zinc500, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: zinc500),
            filled: true,
            fillColor: zinc900,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: zinc800),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: emerald500),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
