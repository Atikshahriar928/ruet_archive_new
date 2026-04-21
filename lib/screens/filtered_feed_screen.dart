import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import '../widgets/custom_components.dart';
import 'reporting_form_screen.dart';
import 'item_details_bottom_sheet.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color emerald500 = Color(0xFF10B981);
const Color orange500 = Color(0xFFF97316);
const Color blue500 = Color(0xFF3B82F6);

class FilteredFeedScreen extends StatefulWidget {
  final ReportMode mode;

  const FilteredFeedScreen({
    super.key,
    required this.mode,
  });

  @override
  State<FilteredFeedScreen> createState() => _FilteredFeedScreenState();
}

class _FilteredFeedScreenState extends State<FilteredFeedScreen> {
  final List<String> _categories = ["All", "Electronics", "Books", "Wallets", "Accessories", "Identity Cards", "Keys", "Other"];
  String _selectedCategory = "All";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  List<LostFoundItem> _allItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    try {
      List<LostFoundItem> items;
      if (widget.mode == ReportMode.lost) {
        items = await DatabaseManager.getAllLostItems();
      } else {
        items = await DatabaseManager.getAllFoundItems();
      }
      
      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading feed: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LostFoundItem> get _filteredItems {
    return _allItems.where((item) {
      final matchesQuery = _searchQuery.isEmpty || 
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == "All" || 
          item.category.toLowerCase() == _selectedCategory.toLowerCase();
      
      return matchesQuery && matchesCategory;
    }).toList();
  }

  void _showItemDetails(LostFoundItem item, Color modeColor) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemDetailsBottomSheet(
        item: item,
        mode: widget.mode,
        currentUid: currentUid,
        onMessageClick: () {
          Navigator.pop(context);
        },
      ),
    ).then((_) => _loadData()); 
  }

  void _onFabClick() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportingFormScreen(mode: widget.mode),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final modeColor = widget.mode == ReportMode.lost ? orange500 : blue500;
    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: backgroundBlack,
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabClick,
        backgroundColor: modeColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add, size: 32),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(filteredItems.length),
              const SizedBox(height: 32),
              _buildSearchBar(modeColor),
              const SizedBox(height: 20),
              _buildCategoryFilters(),
              const SizedBox(height: 32),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  color: modeColor,
                  backgroundColor: zinc900,
                  child: _isLoading 
                    ? Center(child: CircularProgressIndicator(color: modeColor))
                    : filteredItems.isEmpty 
                      ? const Center(child: Text("No items found", style: TextStyle(color: zinc500, fontSize: 16)))
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 32),
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 24),
                          itemBuilder: (context, index) => _lostItemCard(filteredItems[index], modeColor),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
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
        Text(
          widget.mode == ReportMode.lost ? "Lost Items" : "Found Items",
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 12),
        if (!_isLoading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: zinc800, borderRadius: BorderRadius.circular(8)),
            child: Text(
              "$count Reports",
              style: const TextStyle(color: zinc500, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar(Color modeColor) {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val),
      style: const TextStyle(color: Colors.white),
      cursorColor: modeColor,
      decoration: InputDecoration(
        hintText: "Search items...",
        hintStyle: const TextStyle(color: zinc500),
        prefixIcon: const Icon(Icons.search_outlined, color: zinc500),
        filled: true,
        fillColor: zinc900,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: zinc800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: zinc800),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? emerald500 : zinc900,
                borderRadius: BorderRadius.circular(16),
                border: !isSelected ? Border.all(color: zinc800) : null,
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _lostItemCard(LostFoundItem item, Color modeColor) {
    final image = item.imageBase64List.isNotEmpty ? item.imageBase64List.first : null;
    return GestureDetector(
      onTap: () => _showItemDetails(item, modeColor),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: zinc900,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: zinc800),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: Stack(
                  children: [
                    AppImage(
                      source: image,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: modeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: modeColor, width: 1.5),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: TextStyle(color: modeColor, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text(item.date, style: const TextStyle(color: zinc500, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: modeColor, size: 16),
                      const SizedBox(width: 8),
                      Text(item.location, style: const TextStyle(color: zinc500, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.description,
                    style: const TextStyle(color: zinc500, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _showItemDetails(item, modeColor),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: zinc800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("View Details", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
