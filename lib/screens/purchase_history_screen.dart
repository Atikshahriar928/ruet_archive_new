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

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  List<BookListing> _purchasedBooks = [];
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
      final books = await DatabaseManager.getPurchaseHistory(user.uid);
      if (mounted) {
        setState(() {
          _purchasedBooks = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading purchase history: $e");
      if (mounted) setState(() => _isLoading = false);
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
              "Purchase History",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(
              "YOUR CAMPUS ACQUISITIONS",
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

  Widget _acquisitionCard(BookListing book) {
    final image = book.imageBase64List.isNotEmpty ? book.imageBase64List.first : null;
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
                  placeholderIcon: Icons.book,
                ),
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
    );
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return "N/A";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}";
  }
}
