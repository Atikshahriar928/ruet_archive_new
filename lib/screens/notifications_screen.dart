import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String itemId;
  final String type;
  final Timestamp timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.itemId,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? 'New Notification',
      message: data['message'] ?? data['body'] ?? '', 
      // Robust key checking for different notification payloads
      itemId: data['itemId'] ?? data['item_id'] ?? data['chatId'] ?? data['id'] ?? '',
      type: data['type'] ?? 'general',
      timestamp: data['timestamp'] is Timestamp 
          ? data['timestamp'] 
          : Timestamp.now(),
      isRead: data['isRead'] ?? false,
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  final Function(String itemId, String type) onNotificationClick;

  const NotificationsScreen({
    super.key,
    required this.onNotificationClick,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('message') || t.contains('chat')) return Icons.message_rounded;
    if (t.contains('lost')) return Icons.search_rounded;
    if (t.contains('found')) return Icons.inventory_2_rounded;
    if (t.contains('book')) return Icons.menu_book_rounded;
    return Icons.notifications_active_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading notifications", style: TextStyle(color: Colors.white.withOpacity(0.5))),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No new notifications",
                style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final notification = NotificationModel.fromFirestore(docs[index]);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Material(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      final itemId = notification.itemId;
                      final type = notification.type;
                      final id = notification.id;

                      // Dismiss notifications screen
                      Navigator.pop(context);
                      
                      // Trigger navigation in home screen
                      widget.onNotificationClick(itemId, type);
                      
                      // Delete notification from DB
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_uid)
                          .collection('notifications')
                          .doc(id)
                          .delete();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconForType(notification.type),
                              color: const Color(0xFF10B981),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  style: const TextStyle(
                                    color: Color(0xFFA1A1AA),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatTimestamp(notification.timestamp),
                                  style: const TextStyle(
                                    color: Color(0xFF71717A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
