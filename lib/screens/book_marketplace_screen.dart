import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import '../widgets/custom_components.dart';
import 'book_details_bottom_sheet.dart';
import 'sell_book_screen.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color emerald500 = Color(0xFF10B981);

class BookMarketplaceScreen extends StatefulWidget {
  const BookMarketplaceScreen({super.key});

  @override
  State<BookMarketplaceScreen> createState() => _BookMarketplaceScreenState();
}

class _BookMarketplaceScreenState extends State<BookMarketplaceScreen> {
  String _selectedDept = "All";
  final List<String> _departments = ["All", "CSE", "EEE", "ME", "CE", "ETE", "MTE", "GCE", "CFPE"];

  String _sortBy = "Newest";
  final List<String> _sortOptions = ["Newest", "Price: Low to High", "Price: High to Low"];

  final _searchController = TextEditingController();
  String _searchQuery = "";

  List<BookListing> _allBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetching all available books from Firestore
      // Using getRecentBookListings with a large limit or we can add a better method to DatabaseManager
      final books = await DatabaseManager.getRecentBookListings(limitCount: 50); 
      if (mounted) {
        setState(() {
          _allBooks = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading books: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<BookListing> get _filteredBooks {
    var list = _allBooks.where((book) {
      final deptMatch = _selectedDept == "All" || book.deptName == _selectedDept;
      final queryMatch = _searchQuery.isEmpty || 
          book.bookName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.authorName.toLowerCase().contains(_searchQuery.toLowerCase());
      return deptMatch && queryMatch;
    }).toList();

    if (_sortBy == "Price: Low to High") {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == "Price: High to Low") {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return list;
  }

  void _showBookDetails(BookListing book) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookDetailsBottomSheet(
        book: book,
        currentUid: currentUid,
        onAddToCart: () async {
          Navigator.pop(context);
          final result = await DatabaseManager.addToCart(currentUid, book.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
        },
        onMessageSeller: () {
          Navigator.pop(context);
          // Navigate to chat logic
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  _buildDeptChips(),
                  const SizedBox(height: 24),
                  _buildSortBy(),
                  const SizedBox(height: 24),
                  _buildBookGrid(),
                ],
              ),
            ),
          ),
          _buildSellFAB(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
              "Browse Books",
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(color: zinc900, shape: BoxShape.circle),
          child: const Icon(Icons.inventory_2, color: zinc500, size: 20),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: zinc900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: zinc800),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: zinc500),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                hintText: "Search by title or author...",
                hintStyle: TextStyle(color: zinc500),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              },
              child: const Icon(Icons.close, color: zinc500, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildDeptChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _departments.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final dept = _departments[index];
          final isSelected = _selectedDept == dept;
          return GestureDetector(
            onTap: () => setState(() => _selectedDept = dept),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? emerald500 : zinc900,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                dept,
                style: TextStyle(
                  color: isSelected ? Colors.black : zinc500,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortBy() {
    return Row(
      children: [
        const Text("SORT BY:", style: TextStyle(color: zinc500, fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
          onSelected: (val) => setState(() => _sortBy = val),
          color: zinc900,
          offset: const Offset(0, 40),
          itemBuilder: (context) => _sortOptions.map((opt) => PopupMenuItem(
            value: opt,
            child: Text(opt, style: TextStyle(color: _sortBy == opt ? emerald500 : Colors.white)),
          )).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: zinc900, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Text(_sortBy, style: const TextStyle(color: emerald500, fontSize: 14, fontWeight: FontWeight.bold)),
                const Icon(Icons.keyboard_arrow_down, color: emerald500),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookGrid() {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator(color: emerald500)));
    }
    final books = _filteredBooks;
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: emerald500,
        backgroundColor: zinc900,
        child: books.isEmpty
          ? const Center(child: Text("No books found", style: TextStyle(color: zinc500)))
          : GridView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.65,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) => _bookCard(books[index]),
            ),
      ),
    );
  }

  Widget _bookCard(BookListing book) {
    final image = book.imageBase64List.isNotEmpty ? book.imageBase64List.first : null;
    return GestureDetector(
      onTap: () => _showBookDetails(book),
      child: Container(
        decoration: BoxDecoration(
          color: zinc900,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: zinc800),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: AppImage(
                        source: image,
                        width: double.infinity,
                        height: double.infinity,
                        placeholderIcon: Icons.book,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                      child: Text(book.deptName, style: const TextStyle(color: emerald500, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.bookName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(book.authorName, style: const TextStyle(color: zinc500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, color: zinc500, size: 14),
                      const SizedBox(width: 6),
                      Text(book.year, style: const TextStyle(color: zinc500, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("৳${book.price}", style: const TextStyle(color: emerald500, fontSize: 18, fontWeight: FontWeight.w900)),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: emerald500, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add, color: Colors.black, size: 24),
                      ),
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

  Widget _buildSellFAB() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SellBookScreen())).then((_) => _loadData()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: emerald500,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: emerald500.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
          ),
          child: Row(
            children: const [
              Icon(Icons.add, color: Colors.black),
              SizedBox(width: 8),
              Text("Sell", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
