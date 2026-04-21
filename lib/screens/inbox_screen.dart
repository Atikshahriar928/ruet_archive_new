import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import '../widgets/custom_components.dart';
import 'messaging_screen.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color emerald500 = Color(0xFF10B981);

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  bool _isSearchExpanded = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

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
                child: currentUid == null 
                  ? const Center(child: Text("Please login to see messages", style: TextStyle(color: zinc500)))
                  : StreamBuilder<List<Chat>>(
                      stream: DatabaseManager.getInboxFlow(currentUid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: emerald500));
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: zinc500)));
                        }
                        
                        final chats = snapshot.data ?? [];
                        
                        // We can't filter by 'live' names easily here without fetching all profiles first, 
                        // so we'll filter by the cached names in participantNames for the search.
                        final filtered = chats.where((chat) {
                          final otherName = chat.participantNames.entries
                              .firstWhere((e) => e.key != currentUid, orElse: () => MapEntry("", "Unknown"))
                              .value;
                          return otherName.toLowerCase().contains(_searchQuery.toLowerCase());
                        }).toList();

                        if (filtered.isEmpty && _searchQuery.isEmpty) {
                          return _buildEmptyInbox();
                        }

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => Divider(color: zinc900.withAlpha(128), height: 1),
                          itemBuilder: (context, index) {
                            final chat = filtered[index];
                            final otherUid = chat.participants.firstWhere((id) => id != currentUid, orElse: () => "");
                            
                            return _ConversationItem(
                              chat: chat,
                              currentUid: currentUid,
                              otherUid: otherUid,
                              onDelete: () {
                                DatabaseManager.deleteChatForUser(chat.id, currentUid);
                              },
                            );
                          },
                        );
                      },
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
        if (!_isSearchExpanded)
          const Expanded(
            child: Text(
              "Messages",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        if (_isSearchExpanded)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Search chats...",
                  hintStyle: TextStyle(color: zinc500),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (_isSearchExpanded) {
                _isSearchExpanded = false;
                _searchQuery = "";
                _searchController.clear();
              } else {
                _isSearchExpanded = true;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: zinc900, shape: BoxShape.circle),
            child: Icon(
              _isSearchExpanded ? Icons.close : Icons.search,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyInbox() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.message_outlined, color: zinc800, size: 80),
          SizedBox(height: 24),
          Text(
            "Your inbox is empty",
            style: TextStyle(color: zinc500, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ConversationItem extends StatefulWidget {
  final Chat chat;
  final String currentUid;
  final String otherUid;
  final VoidCallback onDelete;

  const _ConversationItem({
    required this.chat,
    required this.currentUid,
    required this.otherUid,
    required this.onDelete,
  });

  @override
  State<_ConversationItem> createState() => _ConversationItemState();
}

class _ConversationItemState extends State<_ConversationItem> {
  bool _showDelete = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: DatabaseManager.getUserProfileFlow(widget.otherUid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        // Fallback to cached chat name if profile stream isn't ready
        final name = profile?.fullName ?? widget.chat.participantNames[widget.otherUid] ?? "User";
        final image = profile?.profileImageBase64;

        return InkWell(
          onTap: () {
            if (_showDelete) {
              setState(() => _showDelete = false);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessagingScreen(
                    chatId: widget.chat.id,
                    otherUserName: name,
                    otherUid: widget.otherUid,
                  ),
                ),
              );
            }
          },
          onLongPress: () => setState(() => _showDelete = true),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Row(
              children: [
                ProfileImage(
                  imageSource: image,
                  size: 56,
                  borderRadius: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.chat.lastMessage.isEmpty ? "No messages yet" : widget.chat.lastMessage,
                        style: const TextStyle(color: zinc500, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_showDelete)
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete, color: Colors.red),
                      )
                    else
                      Text(
                        _formatTime(widget.chat.timestamp),
                        style: const TextStyle(color: zinc500, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
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
