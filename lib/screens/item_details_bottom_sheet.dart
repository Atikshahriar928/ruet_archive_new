import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import '../widgets/custom_components.dart';
import 'messaging_screen.dart';

class ItemDetailsBottomSheet extends StatelessWidget {
  final LostFoundItem item;
  final ReportMode mode;
  final String currentUid;
  final VoidCallback onMessageClick;

  const ItemDetailsBottomSheet({
    super.key,
    required this.item,
    required this.mode,
    required this.currentUid,
    required this.onMessageClick,
  });

  @override
  Widget build(BuildContext context) {
    final Color modeColor = mode == ReportMode.lost ? const Color(0xFFF97316) : const Color(0xFF3B82F6);
    final bool isMyItem = item.ownerUid == currentUid;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery (First image for now)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AppImage(
                      source: item.imageBase64List.isNotEmpty ? item.imageBase64List.first : null,
                      width: double.infinity,
                      height: 250,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: modeColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: modeColor, width: 1.5),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: TextStyle(color: modeColor, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    item.title,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(Icons.location_on, color: modeColor, size: 16),
                      const SizedBox(width: 8),
                      Text(item.location, style: const TextStyle(color: Color(0xFF71717A), fontSize: 16)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFF18181B)),
                  const SizedBox(height: 24),
                  
                  const Text("Description", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    item.description.isEmpty ? "No description provided." : item.description,
                    style: const TextStyle(color: Color(0xFF71717A), fontSize: 16, height: 1.5),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Reporter Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF09090B),
                          child: Icon(Icons.person, color: Color(0xFF71717A)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.reporterName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const Text("Reporter", style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Action Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: isMyItem ? null : () async {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    final chatId = await DatabaseManager.createOrGetChat(
                      currentUser.uid,
                      currentUser.displayName ?? "User",
                      item.ownerUid,
                      item.reporterName,
                    );
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessagingScreen(
                            chatId: chatId,
                            otherUserName: item.reporterName,
                          ),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: modeColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  disabledBackgroundColor: const Color(0xFF18181B),
                ),
                child: Text(
                  isMyItem ? "YOUR REPORT" : "CONTACT REPORTER",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
