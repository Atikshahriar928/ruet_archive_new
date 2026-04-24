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
  final List<String> _departments = [
    "All", "EEE", "CSE", "ECE", "ETE", "CE", "Arch", "URP", "BECM", "Chem", "Math", "Phy", "Hum"
  ];

  String _sortBy = "Newest";
  final List<String> _sortOptions = ["Newest", "Price: Low to High", "Price: High to Low"];

  final _searchController = TextEditingController();
  String _searchQuery = "";

  // Advanced Filters
  String _filterYear = "All";
  String _filterSemester = "All";
  String _filterCourseName = "";
  String _filterCourseCode = "";

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
      
      final yearMatch = _filterYear == "All" || book.year == _filterYear;
      final semMatch = _filterSemester == "All" || book.semester == _filterSemester;
      final courseNameMatch = _filterCourseName.isEmpty || book.courseName.toLowerCase().contains(_filterCourseName.toLowerCase());
      final courseCodeMatch = _filterCourseCode.isEmpty || book.courseCode.toLowerCase().contains(_filterCourseCode.toLowerCase());

      return deptMatch && queryMatch && yearMatch && semMatch && courseNameMatch && courseCodeMatch;
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: zinc900,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: zinc800, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 24),
              const Text("Advanced Filters", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              
              _dropdownFilter(
                "Department",
                _departments,
                _selectedDept,
                (val) => setSheetState(() {
                  _selectedDept = val!;
                }),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _dropdownFilter(
                      "Academic Year",
                      ["All", "1st Year", "2nd Year", "3rd Year", "4th Year"],
                      _filterYear,
                      (val) => setSheetState(() => _filterYear = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _dropdownFilter(
                      "Semester",
                      ["All", "Odd", "Even"],
                      _filterSemester,
                      (val) => setSheetState(() => _filterSemester = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _textFieldFilter("Course Name", (val) => setSheetState(() => _filterCourseName = val), initial: _filterCourseName),
              const SizedBox(height: 24),
              _textFieldFilter("Course Code", (val) => setSheetState(() => _filterCourseCode = val), initial: _filterCourseCode),
              const SizedBox(height: 40),
              
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDept = "All";
                          _filterYear = "All";
                          _filterSemester = "All";
                          _filterCourseName = "";
                          _filterCourseCode = "";
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Reset All", style: TextStyle(color: zinc500, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {}); 
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emerald500,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownFilter(String label, List<String> options, String current, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: zinc500, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: backgroundBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: zinc800)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isExpanded: true,
              dropdownColor: zinc900,
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _textFieldFilter(String label, Function(String) onChanged, {String initial = ""}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: zinc500, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          onChanged: onChanged,
          controller: TextEditingController(text: initial)..selection = TextSelection.fromPosition(TextPosition(offset: initial.length)),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter $label...",
            hintStyle: const TextStyle(color: zinc500, fontSize: 14),
            filled: true,
            fillColor: backgroundBlack,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: zinc800)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: emerald500)),
          ),
        ),
      ],
    );
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
    bool isFiltered = _selectedDept != "All" || _filterYear != "All" || _filterSemester != "All" || _filterCourseName.isNotEmpty || _filterCourseCode.isNotEmpty;
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
        GestureDetector(
          onTap: _showFilterSheet,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isFiltered ? emerald500.withAlpha(51) : zinc900,
              shape: BoxShape.circle,
              border: Border.all(
                color: isFiltered ? emerald500 : Colors.transparent,
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: isFiltered ? emerald500 : Colors.white,
              size: 20,
            ),
          ),
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
          ? const Center(child: Text("No books found with current filters", style: TextStyle(color: zinc500)))
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
