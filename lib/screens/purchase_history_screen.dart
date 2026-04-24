import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import '../widgets/custom_components.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color emerald500 = Color(0xFF10B981);

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  List<BookListing> _purchasedBooks = [];
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
      final books = await DatabaseManager.getPurchaseHistory(user.uid);
      if (mounted) {
        setState(() {
          _purchasedBooks = books;
          _isLoading = false;
          _selectedItemIds.clear();
          _isSelectionMode = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading purchase history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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

  void _deleteSelected() async {
    if (_selectedItemIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: zinc900,
        title: const Text("Remove from History", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to remove ${_selectedItemIds.length} items from your purchase history?", style: const TextStyle(color: zinc500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remove", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          "purchasedBookIds": FieldValue.arrayRemove(_selectedItemIds.toList())
        });
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearAll() async {
    if (_purchasedBooks.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: zinc900,
        title: const Text("Clear History", style: TextStyle(color: Colors.white)),
        content: const Text("Delete your entire purchase history? This cannot be undone.", style: TextStyle(color: zinc500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Clear All", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          "purchasedBookIds": []
        });
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
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  color: emerald500,
                  backgroundColor: zinc900,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: emerald500))
                      : _purchasedBooks.isEmpty
                          ? ListView(children: const [Center(child: Padding(padding: EdgeInsets.only(top: 100), child: Text("No purchases yet", style: TextStyle(color: zinc500))))])
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: _purchasedBooks.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) => _acquisitionCard(_purchasedBooks[index]),
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
            label: Text("Remove (${_selectedItemIds.length})"),
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
                  _isSelectionMode ? "Selecting..." : "Purchase History",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                Text(
                  _isSelectionMode ? "${_selectedItemIds.length} items selected" : "YOUR CAMPUS ACQUISITIONS",
                  style: const TextStyle(color: zinc500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ],
        ),
        if (!_isSelectionMode && _purchasedBooks.isNotEmpty)
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_sweep, color: zinc500),
            tooltip: "Clear All",
          ),
      ],
    );
  }

  Widget _acquisitionCard(BookListing book) {
    final image = book.imageBase64List.isNotEmpty ? book.imageBase64List.first : null;
    final isSelected = _selectedItemIds.contains(book.id);

    return GestureDetector(
      onLongPress: () => _toggleSelection(book.id),
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(book.id);
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
                        placeholderIcon: Icons.book,
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
                        book.bookName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "BOOK • ${_formatDate(book.resolvedDate)}",
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
                    "PURCHASED",
                    style: TextStyle(color: emerald500, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(77),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PRICE PAID",
                          style: TextStyle(color: zinc500, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "৳${book.price}",
                          style: const TextStyle(color: emerald500, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(77),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "STATUS",
                          style: TextStyle(color: zinc500, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Acquired",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
