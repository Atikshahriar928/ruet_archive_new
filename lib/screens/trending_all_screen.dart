import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import '../widgets/custom_components.dart';
import 'item_details_bottom_sheet.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color emerald500 = Color(0xFF10B981);
const Color orange500 = Color(0xFFF97316);
const Color blue500 = Color(0xFF3B82F6);

class TrendingAllScreen extends StatefulWidget {
  const TrendingAllScreen({super.key});

  @override
  State<TrendingAllScreen> createState() => _TrendingAllScreenState();
}

class _TrendingAllScreenState extends State<TrendingAllScreen> {
  List<LostFoundItem> _trendingItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await DatabaseManager.getRecentLostFoundItems(limitCount: 20);
      if (mounted) {
        setState(() {
          _trendingItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading trending items: $e");
      if (mounted) setState(() => _isLoading = false);
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
                      decoration: const BoxDecoration(
                        color: zinc900,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Trending Items",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  color: emerald500,
                  backgroundColor: zinc900,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: emerald500))
                      : _trendingItems.isEmpty
                          ? ListView(children: const [Center(child: Padding(padding: EdgeInsets.only(top: 100), child: Text("No trending items found", style: TextStyle(color: zinc500))))])
                          : GridView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: _trendingItems.length,
                              itemBuilder: (context, index) {
                                return _trendingCard(_trendingItems[index]);
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

  Widget _trendingCard(LostFoundItem item) {
    final modeColor = item.type.toUpperCase() == "LOST" ? orange500 : blue500;
    final image = item.imageBase64List.isNotEmpty ? item.imageBase64List.first : null;

    return GestureDetector(
      onTap: () => _showItemDetails(item),
      child: Container(
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
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: modeColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: zinc500, fontSize: 12),
                        ),
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
}
