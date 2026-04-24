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
  final Set<String> _selectedItemIds = {};
  bool _isSelectionMode = false;

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
          _selectedItemIds.clear();
          _isSelectionMode = false;
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

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
        if (_selectedItemIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedItemIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll() {
    setState(() {
      final list = _filteredList;
      if (_selectedItemIds.length == list.length) {
        _selectedItemIds.clear();
        _isSelectionMode = false;
      } else {
        for (var item in list) {
          _selectedItemIds.add(item.id);
        }
        _isSelectionMode = true;
      }
    });
  }

  void _deleteSelected() async {
    if (_selectedItemIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: zinc900,
        title: const Text("Delete Items", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete ${_selectedItemIds.length} items from your history?", style: const TextStyle(color: zinc500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        for (var id in _selectedItemIds) {
          await DatabaseManager.deleteItem("lost_found", id);
        }
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearAll() async {
    final list = _filteredList;
    if (list.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: zinc900,
        title: const Text("Clear Page", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete all ${list.length} ${_selectedTab.toLowerCase()} items?", style: const TextStyle(color: zinc500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Clear All", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        for (var item in list) {
          await DatabaseManager.deleteItem("lost_found", item.id);
        }
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
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
              if (!_isSelectionMode) _buildTabs(),
              if (_isSelectionMode) _buildSelectionActions(),
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
      floatingActionButton: _isSelectionMode 
        ? FloatingActionButton.extended(
            onPressed: _deleteSelected,
            backgroundColor: Colors.red,
            icon: const Icon(Icons.delete, color: Colors.white),
            label: Text("Delete (${_selectedItemIds.length})"),
          )
        : null,
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedItemIds.clear();
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: zinc900, shape: BoxShape.circle),
                child: Icon(_isSelectionMode ? Icons.close : Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSelectionMode ? "Selecting..." : "Resolved History",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                Text(
                  _isSelectionMode ? "${_selectedItemIds.length} items selected" : "YOUR SUCCESSFUL MATCHES",
                  style: const TextStyle(color: zinc500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ],
        ),
        if (!_isSelectionMode && _filteredList.isNotEmpty)
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_sweep, color: zinc500),
            tooltip: "Clear Page",
          ),
      ],
    );
  }

  Widget _buildSelectionActions() {
    final allSelected = _selectedItemIds.length == _filteredList.length;
    return Row(
      children: [
        GestureDetector(
          onTap: _selectAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: allSelected ? emerald500 : zinc900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: allSelected ? emerald500 : zinc800),
            ),
            child: Row(
              children: [
                Icon(allSelected ? Icons.check_circle : Icons.circle_outlined, color: allSelected ? Colors.black : zinc500, size: 18),
                const SizedBox(width: 8),
                Text(
                  allSelected ? "Deselect All" : "Select All",
                  style: TextStyle(color: allSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
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
    final isSelected = _selectedItemIds.contains(item.id);

    return GestureDetector(
      onLongPress: () => _toggleSelection(item.id),
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(item.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? emerald500.withAlpha(26) : zinc900,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? emerald500 : zinc800),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
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
                    if (isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: emerald500.withAlpha(128),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.check, color: Colors.black),
                        ),
                      ),
                  ],
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
                if (!_isSelectionMode)
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
