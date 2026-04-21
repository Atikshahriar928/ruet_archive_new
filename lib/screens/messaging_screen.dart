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

class MessagingScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? otherUid;

  const MessagingScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.otherUid,
  });

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUid == null) return;

    DatabaseManager.sendMessage(widget.chatId, currentUid, text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: backgroundBlack,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: currentUid == null
              ? const Center(child: Text("Authentication required"))
              : StreamBuilder<List<Message>>(
                  stream: DatabaseManager.getMessagesFlow(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: emerald500));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: zinc500)));
                    }

                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          "No messages yet. Say hi!",
                          style: const TextStyle(color: zinc500),
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return _MessageBubble(
                          message: message,
                          isMe: message.senderId == currentUid,
                        );
                      },
                    );
                  },
                ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: zinc900.withAlpha(128),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: widget.otherUid == null 
        ? _appBarTitle(widget.otherUserName, null)
        : StreamBuilder<UserProfile?>(
            stream: DatabaseManager.getUserProfileFlow(widget.otherUid!),
            builder: (context, snapshot) {
              final profile = snapshot.data;
              return _appBarTitle(profile?.fullName ?? widget.otherUserName, profile?.profileImageBase64);
            },
          ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: zinc800, height: 1),
      ),
    );
  }

  Widget _appBarTitle(String name, String? image) {
    return Row(
      children: [
        ProfileImage(
          imageSource: image,
          size: 40,
          borderRadius: 20,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Text(
              "CHAT",
              style: TextStyle(
                color: emerald500,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF18181B),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: zinc900,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: zinc800),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: emerald500,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: zinc500),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: emerald500,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.send, color: Colors.black, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? emerald500 : zinc900,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(24),
                bottomLeft: const Radius.circular(24),
                bottomRight: const Radius.circular(24),
                topRight: isMe ? Radius.zero : const Radius.circular(24),
              ),
              border: isMe ? null : Border.all(color: zinc800),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatTime(message.timestamp),
            style: const TextStyle(
              color: zinc500,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    if (timestamp == 0) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? "PM" : "AM";
    return "$hour:${date.minute.toString().padLeft(2, '0')} $ampm";
  }
}
