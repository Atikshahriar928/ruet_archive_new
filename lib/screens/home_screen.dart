import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import '../widgets/custom_components.dart';
import 'reporting_form_screen.dart';
import 'sell_book_screen.dart';
import 'trending_all_screen.dart';
import 'book_marketplace_screen.dart';
import 'filtered_feed_screen.dart';
import 'my_activity_screen.dart';
import 'user_profile_screen.dart';
import 'inbox_screen.dart';
import 'item_details_bottom_sheet.dart';
import 'book_details_bottom_sheet.dart';
import 'notifications_screen.dart';
import 'messaging_screen.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color emerald500 = Color(0xFF10B981);
const Color orange500 = Color(0xFFF97316);
const Color blue500 = Color(0xFF3B82F6);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMenuOpen = false;

  // Data State
  List<LostFoundItem> _recentItems = [];
  bool _isLoadingItems = true;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await DatabaseManager.getUserProfile(user.uid);
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
        });
      }
    }
  }

  void _loadData() async {
    setState(() => _isLoadingItems = true);
    try {
      final items = await DatabaseManager.getRecentLostFoundItems(limitCount: 5);
      if (mounted) {
        setState(() {
          _recentItems = items;
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading items: $e");
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  void _showItemDetails(LostFoundItem item) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemDetailsBottomSheet(
        item: item,
        mode: item.type.toUpperCase() == "LOST" ? ReportMode.lost : ReportMode.found,
        currentUid: currentUid,
        onMessageClick: () {
          Navigator.pop(context);
        },
      ),
    ).then((_) => _loadData());
  }

  void _navigateToReport(ReportMode mode) {
    setState(() => _isMenuOpen = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReportingFormScreen(mode: mode)),
    ).then((_) => _loadData());
  }

  void _navigateToFeed(ReportMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FilteredFeedScreen(mode: mode)),
    ).then((_) => _loadData());
  }

  void _navigateToSellBook() {
    setState(() => _isMenuOpen = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellBookScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToTrendingAll() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TrendingAllScreen(),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToMarketplace() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookMarketplaceScreen(),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToMyActivity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyActivityScreen(),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToUserProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserProfileScreen(),
      ),
    );
    _loadUserProfile();
  }

  void _navigateToInbox() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InboxScreen(),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          onNotificationClick: (itemId, type) {
            // Using a post-frame callback or delay ensures navigation starts from the Home context after the notification screen is dismissed
            Future.delayed(const Duration(milliseconds: 100), () async {
              if (!mounted) return;
              
              final lowerType = type.toLowerCase();
              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              if (currentUid == null) return;

              if (lowerType == 'message' || lowerType == 'chat') {
                 // For messages, itemId is the chatId
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => MessagingScreen(
                       chatId: itemId,
                       otherUserName: "Chat",
                       // Logic here to fetch the other user ID from the chatId
                       otherUid: itemId.replaceAll(currentUid, "").replaceAll("_", ""),
                     ),
                   ),
                 );
              } else if (lowerType == 'lost' || lowerType == 'found') {
                 final item = await DatabaseManager.getLostFoundItem(itemId);
                 if (item != null && mounted) {
                   showModalBottomSheet(
                     context: context,
                     isScrollControlled: true,
                     backgroundColor: Colors.transparent,
                     builder: (context) => ItemDetailsBottomSheet(
                       item: item,
                       mode: item.type.toUpperCase() == "LOST" ? ReportMode.lost : ReportMode.found,
                       currentUid: currentUid,
                       onMessageClick: () => Navigator.pop(context),
                     ),
                   );
                 }
              } else if (lowerType == 'book') {
                 final book = await DatabaseManager.getBookListing(itemId);
                 if (book != null && mounted) {
                   showModalBottomSheet(
                     context: context,
                     isScrollControlled: true,
                     backgroundColor: Colors.transparent,
                     builder: (context) => BookDetailsBottomSheet(
                       book: book,
                       currentUid: currentUid,
                       onAddToCart: () async {
                          Navigator.pop(context);
                          final res = await DatabaseManager.addToCart(currentUid, book.id);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
                       },
                       onMessageSeller: () {
                          Navigator.pop(context);
                       },
                     ),
                   );
                 }
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      body: Stack(
        children: [
          _buildHomeContent(),
          if (_isMenuOpen)
            GestureDetector(
              onTap: () => setState(() => _isMenuOpen = false),
              child: Container(
                color: Colors.black.withAlpha(204),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          if (_isMenuOpen) _buildSpeedDialMenu(),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          _loadData();
          _loadUserProfile();
        },
        color: emerald500,
        backgroundColor: zinc900,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 32),
                _buildTopBar(),
                const SizedBox(height: 48),
                _buildQuickActions(),
                const SizedBox(height: 32),
                _buildTrendingSection(),
                const SizedBox(height: 32),
                _buildMarketplaceBanner(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final displayName = _userProfile?.fullName ?? "User";
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _navigateToUserProfile,
          child: Row(
            children: [
              ProfileImage(
                imageSource: _userProfile?.profileImageBase64,
                size: 52,
                borderRadius: 26,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Welcome back", style: TextStyle(color: zinc500, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              )
            ],
          ),
        ),
        GestureDetector(
          onTap: _navigateToInbox,
          child: _headerIconButton(Icons.chat_bubble_outline),
        ),
      ],
    );
  }

  Widget _headerIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: zinc900,
        shape: BoxShape.circle,
        border: Border.all(color: zinc800),
      ),
      child: Icon(icon, color: zinc500, size: 22),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _quickActionCard("LOST\nITEMS", Icons.location_off, orange500, () => _navigateToFeed(ReportMode.lost)),
        const SizedBox(width: 16),
        _quickActionCard("FOUND\nITEMS", Icons.inventory_2, blue500, () => _navigateToFeed(ReportMode.found)),
        const SizedBox(width: 16),
        _quickActionCard("BROWSE\nBOOKS", Icons.menu_book, emerald500, _navigateToMarketplace),
      ],
    );
  }

  Widget _quickActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: zinc900,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Recent Items", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: _navigateToTrendingAll,
              child: const Text("View All", style: TextStyle(color: emerald500, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 230,
          child: _isLoadingItems 
            ? const Center(child: CircularProgressIndicator(color: emerald500))
            : _recentItems.isEmpty
              ? const Center(child: Text("No recent items", style: TextStyle(color: zinc500)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentItems.length,
                  itemBuilder: (context, index) {
                    final item = _recentItems[index];
                    return _trendingCard(item);
                  },
                ),
        )
      ],
    );
  }

  Widget _trendingCard(LostFoundItem item) {
    final modeColor = item.type.toUpperCase() == "LOST" ? orange500 : blue500;
    final image = item.imageBase64List.isNotEmpty ? item.imageBase64List.first : null;

    return GestureDetector(
      onTap: () => _showItemDetails(item),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: zinc900,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: zinc800),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: AppImage(
                  source: image,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: modeColor),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item.location, style: const TextStyle(color: zinc500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMarketplaceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: zinc900,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Campus\nMarketplace", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.1)),
          const SizedBox(height: 12),
          const Text("Buy and sell textbooks, electronics, and more.", style: TextStyle(color: zinc500, fontSize: 16)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _navigateToMarketplace,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: emerald500, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Browse Books", style: TextStyle(color: emerald500, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildSpeedDialMenu() {
    return Positioned(
      bottom: 110,
      right: 36,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _speedDialItem("Post Lost Item", Icons.location_searching, orange500, () => _navigateToReport(ReportMode.lost)),
          const SizedBox(height: 16),
          _speedDialItem("Post Found Item", Icons.inventory, blue500, () => _navigateToReport(ReportMode.found)),
          const SizedBox(height: 16),
          _speedDialItem("Sell a Book", Icons.auto_stories, emerald500, _navigateToSellBook),
        ],
      ),
    );
  }

  Widget _speedDialItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: zinc900, borderRadius: BorderRadius.circular(12), border: Border.all(color: zinc800)),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.black),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, "Home", true, onTap: () {}),
              _navItem(Icons.notifications_outlined, "Notifications", false, onTap: _navigateToNotifications),
              const SizedBox(width: 60),
              _navItem(Icons.inventory_2, "Items", false, onTap: _navigateToMyActivity),
              _navItem(Icons.person, "Profile", false, onTap: _navigateToUserProfile),
            ],
          ),
          Positioned(
            top: -24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _isMenuOpen = !_isMenuOpen),
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: emerald500,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: emerald500.withAlpha(77), blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: Icon(_isMenuOpen ? Icons.close : Icons.add, color: Colors.black, size: 32),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? emerald500 : zinc500, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: active ? emerald500 : zinc500, fontSize: 10)),
        ],
      ),
    );
  }
}
