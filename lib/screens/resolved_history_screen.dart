import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import '../widgets/custom_components.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color emerald500 = Color(0xFF10B981);

class ResolvedHistoryScreen extends StatefulWidget {
  const ResolvedHistoryScreen({super.key});

  @override
  State<ResolvedHistoryScreen> createState() => _ResolvedHistoryScreenState();
}

class _ResolvedHistoryScreenState extends State<ResolvedHistoryScreen> {
  String _selectedTab = "Lost";
  List<LostFoundItem> _resolvedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    
    try {
      final items = await DatabaseManager.getResolvedItems(user.uid);
      if (mounted) {
        setState(() {
          _resolvedItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading resolved items: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LostFoundItem> get _filteredList {
    return _resolvedItems.where((item) {
      if (_selectedTab == "Lost") return item.type == "LOST";
      return item.type == "FOUND";
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildTabs(),
              const SizedBox(height: 24),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  color: emerald500,
                  backgroundColor: zinc900,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: emerald500))
                      : _filteredList.isEmpty
                          ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.only(top: 100), child: Text("No resolved ${_selectedTab.toLowerCase()} items yet", style: const TextStyle(color: zinc500))))])
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: _filteredList.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) => _resolvedItemCard(_filteredList[index]),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: zinc900, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Resolved History",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(
              "YOUR SUCCESSFUL MATCHES",
              style: TextStyle(
                color: zinc500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: zinc900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabItem(
              label: "Lost Items",
              icon: Icons.inventory_2,
              isSelected: _selectedTab == "Lost",
              onTap: () => setState(() => _selectedTab = "Lost"),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _tabItem(
              label: "Found Items",
              icon: Icons.location_on,
              isSelected: _selectedTab == "Found",
              onTap: () => setState(() => _selectedTab = "Found"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? emerald500 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.black : zinc500, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : zinc500,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resolvedItemCard(LostFoundItem item) {
    final image = item.imageBase64List.isNotEmpty ? item.imageBase64List.first : null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: zinc900,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: zinc800),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppImage(
                  source: image,
                  width: 56,
                  height: 56,
                  placeholderIcon: Icons.inventory_2,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "${item.location} • ${item.date}",
                      style: const TextStyle(color: zinc500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: emerald500.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: emerald500),
                ),
                child: const Text(
                  "RESOLVED",
                  style: TextStyle(color: emerald500, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _infoBox(label: "RESOLUTION", value: "Returned"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoBox(label: "RESOLVED ON", value: _formatDate(item.resolvedDate)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(77),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: zinc500, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: label == "RESOLUTION" ? emerald500 : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return "N/A";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}";
  }
}
