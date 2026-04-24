import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import '../widgets/custom_components.dart';
import 'item_details_bottom_sheet.dart';
import 'book_details_bottom_sheet.dart';
import 'item_context_menu.dart';
import 'reporting_form_screen.dart';
import 'sell_book_screen.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color emerald500 = Color(0xFF10B981);
const Color orange500 = Color(0xFFF97316);
const Color blue500 = Color(0xFF3B82F6);

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  String _selectedTab = "Lost";
  final List<String> _tabs = ["Lost", "Found", "Added", "Selling"];

  List<LostFoundItem> _lostItems = [];
  List<LostFoundItem> _foundItems = [];
  List<BookListing> _addedItems = [];
  List<BookListing> _sellingItems = [];
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
      final lost = await DatabaseManager.getUserLostItems(user.uid);
      final found = await DatabaseManager.getUserFoundItems(user.uid);
      final added = await DatabaseManager.getUserCartedBooks(user.uid);
      final selling = await DatabaseManager.getUserSellingBooks(user.uid);
      
      if (mounted) {
        setState(() {
          _lostItems = lost;
          _foundItems = found;
          _addedItems = added;
          _sellingItems = selling;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading my activity: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getCurrentList() {
    switch (_selectedTab) {
      case "Lost": return _lostItems;
      case "Found": return _foundItems;
      case "Added": return _addedItems;
      case "Selling": return _sellingItems;
      default: return [];
    }
  }

  void _showItemDetails(dynamic item) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (item is LostFoundItem) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ItemDetailsBottomSheet(
          item: item,
          mode: item.type == "LOST" ? ReportMode.lost : ReportMode.found,
          currentUid: currentUid,
          onMessageClick: () => Navigator.pop(context),
        ),
      ).then((_) => _loadData());
    } else if (item is BookListing) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BookDetailsBottomSheet(
          book: item,
          currentUid: currentUid,
          onAddToCart: () {
            Navigator.pop(context);
            _loadData();
          },
          onMessageSeller: () => Navigator.pop(context),
        ),
      ).then((_) => _loadData());
    }
  }

  void _handleDelete(dynamic item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (_selectedTab == "Added") {
        await DatabaseManager.discardItemFromCart(user.uid, item.id);
      } else {
        final collection = (item is LostFoundItem) ? "lost_found" : "books";
        await DatabaseManager.deleteItem(collection, item.id);
      }
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _handleMarkAction(dynamic item) async {
    try {
      if (item is LostFoundItem) {
        await DatabaseManager.updateItemStatus("lost_found", item.id, "resolved");
      } else if (item is BookListing) {
        await DatabaseManager.updateItemStatus("books", item.id, "sold");
      }
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _navigateToEdit(dynamic item) {
    if (item is LostFoundItem) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportingFormScreen(
            mode: item.type == "LOST" ? ReportMode.lost : ReportMode.found,
            editItemId: item.id,
          ),
        ),
      ).then((_) => _loadData());
    } else if (item is BookListing) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SellBookScreen(
            editItemId: item.id,
          ),
        ),
      ).then((_) => _loadData());
    }
  }

  void _showContextMenu(BuildContext context, dynamic item) {
    HapticFeedback.heavyImpact();
    
    final String title = item is LostFoundItem ? item.title : (item as BookListing).bookName;
    final String type = item is LostFoundItem 
        ? item.type 
        : (_selectedTab == "Added" ? "CART" : "SELLING");

    showDialog(
      context: context,
      builder: (context) => ItemContextMenu(
        itemTitle: title,
        itemType: type,
        onEdit: () {
          Navigator.pop(context);
          _navigateToEdit(item);
        },
        onMarkAction: () {
          Navigator.pop(context);
          _handleMarkAction(item);
        },
        onDelete: () {
          Navigator.pop(context);
          _handleDelete(item);
        },
      ),
    );
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
              
              // Header
              Row(
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
                  const Text(
                    "My Items",
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Tab Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: zinc900, borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tabs.map((tab) {
                      final isSelected = _selectedTab == tab;
                      IconData icon;
                      switch(tab) {
                        case "Lost": icon = Icons.inventory_2; break;
                        case "Found": icon = Icons.location_on; break;
                        case "Added": icon = Icons.shopping_cart; break;
                        case "Selling": icon = Icons.sell; break;
                        default: icon = Icons.circle;
                      }

                      return GestureDetector(
                        onTap: () => setState(() => _selectedTab = tab),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? emerald500 : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: isSelected ? Colors.black : zinc500, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                tab,
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
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  color: emerald500,
                  backgroundColor: zinc900,
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: emerald500))
                    : _getCurrentList().isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _getCurrentList().length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final item = _getCurrentList()[index];
                            return _myItemCard(item);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _myItemCard(dynamic item) {
    String title = "";
    String subtitle = "";
    String status = "";
    Color statusColor = emerald500;
    String? image;

    if (item is LostFoundItem) {
      title = item.title;
      subtitle = "${item.date.toUpperCase()} • ${item.location.toUpperCase()}";
      status = item.type == "LOST" ? "REPORTED" : "FOUND";
      statusColor = item.type == "LOST" ? orange500 : emerald500;
      image = item.imageBase64List.isNotEmpty ? item.imageBase64List.first : null;
    } else if (item is BookListing) {
      title = item.bookName;
      subtitle = "${item.authorName.toUpperCase()} • ৳${item.price}";
      status = _selectedTab == "Selling" ? "SELLING" : "IN CART";
      statusColor = _selectedTab == "Selling" ? blue500 : emerald500;
      image = item.imageBase64List.isNotEmpty ? item.imageBase64List.first : null;
    }

    return GestureDetector(
      onTap: () => _showItemDetails(item),
      onLongPress: () => _showContextMenu(context, item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: zinc800),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AppImage(
                source: image,
                width: 64,
                height: 64,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: zinc500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.cloud_queue, color: Color(0xFF18181B), size: 80),
            SizedBox(height: 16),
            Text("No items found here", style: TextStyle(color: zinc500, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
