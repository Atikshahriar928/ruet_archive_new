import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import 'messaging_screen.dart';

// RUET Theme Colors
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color emerald500 = Color(0xFF10B981);

class BookDetailsBottomSheet extends StatelessWidget {
  final BookListing book;
  final String currentUid;
  final VoidCallback onAddToCart;
  final VoidCallback onMessageSeller;

  const BookDetailsBottomSheet({
    super.key,
    required this.book,
    required this.currentUid,
    required this.onAddToCart,
    required this.onMessageSeller,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOwner = currentUid == book.ownerUid;

    return Container(
      decoration: const BoxDecoration(
        color: zinc900,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: zinc800,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Image
                  Stack(
                    children: [
                      Container(
                        height: 350,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: zinc800,
                        ),
                        child: book.imageBase64List.isNotEmpty
                            ? Image.memory(
                                base64Decode(book.imageBase64List.first),
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(Icons.image, color: zinc500, size: 64),
                              ),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 24,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: emerald500,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                book.deptName,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Text(
                                book.condition,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.bookName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          book.authorName,
                          style: const TextStyle(
                            color: zinc500,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: _metadataDetailCard(
                                label: "SELLER",
                                value: book.reporterName.isEmpty ? "Anonymous" : book.reporterName,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _metadataDetailCard(
                                label: "ACADEMIC YEAR",
                                value: book.year,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _metadataDetailCard(
                                label: "COURSE",
                                value: book.courseName.isEmpty ? "N/A" : book.courseName,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _metadataDetailCard(
                                label: "QUALITY/SEM",
                                value: "${book.condition} / ${book.semester}",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        const Text(
                          "DESCRIPTION",
                          style: TextStyle(
                            color: zinc500,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          book.description.isEmpty ? "No description provided." : book.description,
                          style: const TextStyle(
                            color: zinc500,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),

                        if (!isOwner) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final currentUser = FirebaseAuth.instance.currentUser;
                                if (currentUser != null) {
                                  final chatId = await DatabaseManager.createOrGetChat(
                                    currentUser.uid,
                                    currentUser.displayName ?? "User",
                                    book.ownerUid,
                                    book.reporterName,
                                  );
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MessagingScreen(
                                          chatId: chatId,
                                          otherUserName: book.reporterName,
                                          otherUid: book.ownerUid,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.chat_bubble_outline, color: emerald500),
                              label: const Text(
                                "MESSAGE SELLER",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: zinc800),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "TOTAL PRICE",
                                    style: TextStyle(
                                      color: zinc500,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "৳${book.price}",
                                    style: const TextStyle(
                                      color: emerald500,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isOwner)
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 64,
                                  child: ElevatedButton(
                                    onPressed: onAddToCart,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: emerald500,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    ),
                                    child: const Text(
                                      "ADD TO CART",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metadataDetailCard({required String label, required String value}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: zinc800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: zinc500,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
