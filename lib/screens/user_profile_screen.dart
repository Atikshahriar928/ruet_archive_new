import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import '../managers/auth_manager.dart';
import '../widgets/custom_components.dart';
import 'edit_profile_screen.dart';
import 'my_activity_screen.dart';
import 'purchase_history_screen.dart';
import 'resolved_history_screen.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color emerald500 = Color(0xFF10B981);

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  UserProfile? _userProfile;
  UserStats? _userStats;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  final AuthManager _authManager = AuthManager();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _loadData();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    
    try {
      final profile = await DatabaseManager.getUserProfile(user.uid);
      final stats = await DatabaseManager.fetchUserStats(user.uid);
      
      if (mounted) {
        setState(() {
          _userProfile = profile ?? UserProfile(
            uid: user.uid,
            fullName: user.displayName ?? "User",
            profileImageBase64: user.photoURL,
          );
          
          if (_userProfile?.profileImageBase64 == null) {
            _userProfile = UserProfile(
              uid: _userProfile!.uid,
              fullName: _userProfile!.fullName,
              dept: _userProfile!.dept,
              series: _userProfile!.series,
              mobile: _userProfile!.mobile,
              profileImageBase64: user.photoURL,
            );
          }
          
          _userStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: backgroundBlack,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: emerald500))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildHeader(),
                          const SizedBox(height: 48),
                          _buildUserIdentity(),
                          const SizedBox(height: 40),
                          _buildStatsGrid(),
                          const SizedBox(height: 40),
                          _buildMenu(),
                          const SizedBox(height: 32),
                          _buildLogoutButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
              ),
            ),
          ),
        ),
        if (_isLoggingOut)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: const Center(child: CircularProgressIndicator(color: emerald500)),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: zinc900, shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: Colors.white),
            ),
          ),
        ),
        const Text(
          "Profile",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildUserIdentity() {
    return Column(
      children: [
        ProfileImage(
          imageSource: _userProfile?.profileImageBase64,
          size: 128,
          borderRadius: 32,
        ),
        const SizedBox(height: 24),
        Text(
          _userProfile?.fullName ?? "Anonymous",
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(
          "${_userProfile?.dept ?? "Dept"} '${_userProfile?.series ?? "Series"} • RUET",
          style: const TextStyle(color: zinc500, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.inventory_2, _userStats?.itemsSold.toString() ?? "0", "ITEMS SOLD")),
        const SizedBox(width: 16),
        Expanded(child: _statCard(Icons.location_on, _userStats?.itemsFound.toString() ?? "0", "ITEMS FOUND")),
        const SizedBox(width: 16),
        Expanded(child: _statCard(Icons.search, _userStats?.itemsLost.toString() ?? "0", "ITEMS LOST")),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: zinc900,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: zinc800),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: emerald500, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: zinc500, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Column(
      children: [
        _profileMenuItem(
          icon: Icons.person_add_alt_outlined, 
          label: "Edit Profile",
          onTap: () async {
            await Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => EditProfileScreen(onSaveClick: () => Navigator.pop(context)))
            );
            _loadData(); 
          },
        ),
        const SizedBox(height: 16),
        _profileMenuItem(
          icon: Icons.inventory_2_outlined, 
          label: "My Listings",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyActivityScreen())),
        ),
        const SizedBox(height: 16),
        _profileMenuItem(
          icon: Icons.book_outlined, 
          label: "Purchase History",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseHistoryScreen())),
        ),
        const SizedBox(height: 16),
        _profileMenuItem(
          icon: Icons.task_alt_outlined, 
          label: "Resolved History",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResolvedHistoryScreen())),
        ),
        const SizedBox(height: 16),
        _profileMenuItem(icon: Icons.notifications_outlined, label: "Settings", isEmerald: true),
        const SizedBox(height: 16),
        _profileMenuItem(icon: Icons.info_outlined, label: "Help & Support"),
      ],
    );
  }

  Widget _profileMenuItem({required IconData icon, required String label, bool isEmerald = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: zinc900.withAlpha(128),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: zinc800),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: zinc800, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: isEmerald ? emerald500 : zinc500, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.chevron_right, color: zinc500, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton(
        onPressed: () async {
          setState(() => _isLoggingOut = true);
          
          try {
            // 1. Sign out from Firebase/Google
            await _authManager.logout();
            
            if (mounted) {
              // 2. Simply pop everything back to the root.
              // Since StreamBuilder in main.dart has now swapped the root to LoginScreen,
              // this will reveal the LoginScreen instantly.
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } catch (e) {
            debugPrint("Logout error: $e");
            if (mounted) setState(() => _isLoggingOut = false);
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0xFFEF4444).withAlpha(51)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        ),
        child: const Text(
          "Logout Account",
          style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
