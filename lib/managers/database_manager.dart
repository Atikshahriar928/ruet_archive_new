import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class DatabaseManager {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _tag = "FIREBASE_DEBUG";

  static String _getCurrentUserName() {
    final user = _auth.currentUser;
    return user?.displayName ?? user?.email?.split("@").first ?? "Anonymous Student";
  }

  static Future<bool> checkUserProfileExists(String uid) async {
    try {
      final doc = await _db.collection("users").doc(uid).get();
      return doc.exists;
    } catch (e) {
      print("$_tag: checkUserProfileExists ERROR: $e");
      return false;
    }
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _db.collection("users").doc(profile.uid).set(profile.toJson());
    } catch (e) {
      print("$_tag: saveUserProfile ERROR: $e");
    }
  }

  static Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection("users").doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print("$_tag: getUserProfile ERROR: $e");
      return null;
    }
  }

  static Stream<UserProfile?> getUserProfileFlow(String uid) {
    return _db.collection("users").doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  static Future<void> updateUserPresence(String uid, bool isOnline) async {
    try {
      final status = isOnline ? "online" : "offline";
      await _db.collection("users").doc(uid).update({
        "status": status,
        "lastSeen": DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print("$_tag: updateUserPresence ERROR: $e");
    }
  }

  static Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _db.collection("users").doc(uid).update({"fcmToken": token});
      print("$_tag: FCM Token updated for user: $uid");
    } catch (e) {
      print("$_tag: updateFcmToken ERROR: $e");
    }
  }

  static Future<void> resetMessageCount(String uid) async {
    try {
      await _db.collection("users").doc(uid).update({"unreadMessagesCount": 0});
    } catch (e) {
      print("$_tag: resetMessageCount ERROR: $e");
    }
  }

  static Future<void> resetNotificationCount(String uid) async {
    try {
      await _db.collection("users").doc(uid).update({"unreadNotificationsCount": 0});
    } catch (e) {
      print("$_tag: resetNotificationCount ERROR: $e");
    }
  }

  static Future<void> saveLostFoundItem(LostFoundItem item) async {
    try {
      final collection = _db.collection("lost_found");
      final docRef = item.id.isEmpty ? collection.doc() : collection.doc(item.id);

      final data = item.toJson();
      data['id'] = docRef.id;
      data['reporterName'] = _getCurrentUserName();
      if (item.timestamp == 0) {
        data['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      }
      if (item.status.isEmpty) {
        data['status'] = "available";
      }

      await docRef.set(data);
      print("$_tag: saveLostFoundItem SUCCESS: ${docRef.id}");
    } catch (e) {
      print("$_tag: saveLostFoundItem ERROR: $e");
      rethrow;
    }
  }

  static Future<LostFoundItem?> getLostFoundItem(String itemId) async {
    try {
      final doc = await _db.collection("lost_found").doc(itemId).get();
      if (doc.exists && doc.data() != null) {
        return LostFoundItem.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print("$_tag: getLostFoundItem ERROR: $e");
      return null;
    }
  }

  static Future<void> saveBookListing(BookListing book) async {
    try {
      final collection = _db.collection("books");
      final docRef = book.id.isEmpty ? collection.doc() : collection.doc(book.id);

      final data = book.toJson();
      data['id'] = docRef.id;
      data['reporterName'] = _getCurrentUserName();
      if (book.timestamp == 0) {
        data['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      }
      if (book.status.isEmpty) {
        data['status'] = "available";
      }

      await docRef.set(data);
      print("$_tag: saveBookListing SUCCESS: ${docRef.id}");
    } catch (e) {
      print("$_tag: saveBookListing ERROR: $e");
      rethrow;
    }
  }

  static Future<BookListing?> getBookListing(String bookId) async {
    try {
      final doc = await _db.collection("books").doc(bookId).get();
      if (doc.exists && doc.data() != null) {
        return BookListing.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print("$_tag: getBookListing ERROR: $e");
      return null;
    }
  }

  static Future<List<LostFoundItem>> getRecentLostFoundItems({int limitCount = 5}) async {
    try {
      final snapshot = await _db
          .collection("lost_found")
          .where("status", isEqualTo: "available")
          .orderBy("timestamp", descending: true)
          .limit(limitCount)
          .get();

      return snapshot.docs.map((doc) => LostFoundItem.fromJson(doc.data())).toList();
    } catch (e) {
      print("$_tag: getRecentLostFoundItems ERROR: $e");
      return [];
    }
  }

  static Future<List<BookListing>> getRecentBookListings({int limitCount = 5}) async {
    try {
      final snapshot = await _db
          .collection("books")
          .where("status", isEqualTo: "available")
          .orderBy("timestamp", descending: true)
          .limit(limitCount)
          .get();

      return snapshot.docs.map((doc) => BookListing.fromJson(doc.data())).toList();
    } catch (e) {
      print("$_tag: getRecentBookListings ERROR: $e");
      return [];
    }
  }

  static Future<List<LostFoundItem>> getAllLostItems() async {
    try {
      final snapshot = await _db
          .collection("lost_found")
          .where("status", isEqualTo: "available")
          .orderBy("timestamp", descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LostFoundItem.fromJson(doc.data()))
          .where((item) => item.type.toUpperCase() == "LOST")
          .toList();
    } catch (e) {
      print("$_tag: getAllLostItems ERROR: $e");
      return [];
    }
  }

  static Future<List<LostFoundItem>> getAllFoundItems() async {
    try {
      final snapshot = await _db
          .collection("lost_found")
          .where("status", isEqualTo: "available")
          .orderBy("timestamp", descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LostFoundItem.fromJson(doc.data()))
          .where((item) => item.type.toUpperCase() == "FOUND")
          .toList();
    } catch (e) {
      print("$_tag: getAllFoundItems ERROR: $e");
      return [];
    }
  }

  static Future<List<LostFoundItem>> getUserLostItems(String uid) async {
    try {
      final snapshot = await _db
          .collection("lost_found")
          .where("ownerUid", isEqualTo: uid)
          .where("status", isEqualTo: "available")
          .get();

      final list = snapshot.docs
          .map((doc) => LostFoundItem.fromJson(doc.data()))
          .where((item) => item.type.toUpperCase() == "LOST")
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      print("$_tag: getUserLostItems ERROR: $e");
      return [];
    }
  }

  static Future<List<LostFoundItem>> getUserFoundItems(String uid) async {
    try {
      final snapshot = await _db
          .collection("lost_found")
          .where("ownerUid", isEqualTo: uid)
          .where("status", isEqualTo: "available")
          .get();

      final list = snapshot.docs
          .map((doc) => LostFoundItem.fromJson(doc.data()))
          .where((item) => item.type.toUpperCase() == "FOUND")
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      print("$_tag: getUserFoundItems ERROR: $e");
      return [];
    }
  }

  static Future<List<BookListing>> getUserSellingBooks(String uid) async {
    try {
      final snapshot = await _db
          .collection("books")
          .where("ownerUid", isEqualTo: uid)
          .where("status", isEqualTo: "available")
          .get();

      final list = snapshot.docs.map((doc) => BookListing.fromJson(doc.data())).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      print("$_tag: getUserSellingBooks ERROR: $e");
      return [];
    }
  }

  static Future<String> addToCart(String uid, String bookId) async {
    try {
      final userRef = _db.collection("users").doc(uid);
      final doc = await userRef.get();
      if (!doc.exists) return "User profile not found";
      
      final cartIds = List<String>.from(doc.data()?["cartedBookIds"] ?? []);

      if (cartIds.contains(bookId)) {
        return "Already in cart!";
      } else {
        await userRef.update({
          "cartedBookIds": FieldValue.arrayUnion([bookId])
        });
        return "Added to Cart!";
      }
    } catch (e) {
      print("$_tag: addToCart ERROR: $e");
      return "Error adding to cart";
    }
  }

  static Future<List<BookListing>> getUserCartedBooks(String uid) async {
    try {
      final userDoc = await _db.collection("users").doc(uid).get();
      if (!userDoc.exists) return [];
      
      final cartIds = List<String>.from(userDoc.data()?["cartedBookIds"] ?? []);

      if (cartIds.isEmpty) return [];

      final snapshot = await _db
          .collection("books")
          .where(FieldPath.documentId, whereIn: cartIds.take(10).toList())
          .get();

      final list = snapshot.docs
          .map((doc) => BookListing.fromJson(doc.data()))
          .where((item) => item.status == "available")
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      print("$_tag: getUserCartedBooks ERROR: $e");
      return [];
    }
  }

  static Future<UserStats> fetchUserStats(String uid) async {
    try {
      final soldSnapshot = await _db
              .collection("books")
              .where("ownerUid", isEqualTo: uid)
              .where("status", isEqualTo: "sold")
              .get();
      final soldCount = soldSnapshot.docs.length;

      final foundSnapshot = await _db
              .collection("lost_found")
              .where("ownerUid", isEqualTo: uid)
              .where("type", isEqualTo: "FOUND")
              .get();
      final foundCount = foundSnapshot.docs.length;

      final lostSnapshot = await _db
              .collection("lost_found")
              .where("ownerUid", isEqualTo: uid)
              .where("type", isEqualTo: "LOST")
              .get();
      final lostCount = lostSnapshot.docs.length;

      return UserStats(
        itemsSold: soldCount,
        itemsFound: foundCount,
        itemsLost: lostCount,
      );
    } catch (e) {
      print("$_tag: fetchUserStats ERROR: $e");
      return UserStats();
    }
  }

  static Future<void> deleteItem(String collectionPath, String itemId) async {
    try {
      await _db.collection(collectionPath).doc(itemId).delete();
    } catch (e) {
      print("$_tag: deleteItem ERROR: $e");
      rethrow;
    }
  }

  static Future<void> discardItemFromCart(String uid, String itemId) async {
    try {
      await _db.collection("users").doc(uid).update({
        "cartedBookIds": FieldValue.arrayRemove([itemId])
      });
    } catch (e) {
      print("$_tag: discardItemFromCart ERROR: $e");
      rethrow;
    }
  }

  static Future<void> updateItemStatus(String collectionPath, String itemId, String newStatus) async {
    try {
      final updates = {
        "status": newStatus,
        "resolvedDate": DateTime.now().millisecondsSinceEpoch,
      };
      await _db.collection(collectionPath).doc(itemId).update(updates);

      if (newStatus == "purchased" && collectionPath == "books") {
        final currentUid = _auth.currentUser?.uid;
        if (currentUid != null) {
          await _db.collection("users").doc(currentUid).update({
            "purchasedBookIds": FieldValue.arrayUnion([itemId])
          });
          await discardItemFromCart(currentUid, itemId);
        }
      }
    } catch (e) {
      print("$_tag: updateItemStatus ERROR: $e");
      rethrow;
    }
  }

  static Future<List<LostFoundItem>> getResolvedItems(String uid) async {
    try {
      final snapshot = await _db
          .collection("lost_found")
          .where("ownerUid", isEqualTo: uid)
          .where("status", isEqualTo: "resolved")
          .get();

      final list = snapshot.docs.map((doc) => LostFoundItem.fromJson(doc.data())).toList();
      list.sort((a, b) => b.resolvedDate.compareTo(a.resolvedDate));
      return list;
    } catch (e) {
      print("$_tag: getResolvedItems ERROR: $e");
      return [];
    }
  }

  static Future<List<BookListing>> getPurchaseHistory(String uid) async {
    try {
      final userDoc = await _db.collection("users").doc(uid).get();
      final purchasedIds = List<String>.from(userDoc.data()?["purchasedBookIds"] ?? []);

      if (purchasedIds.isEmpty) return [];

      final snapshot = await _db
          .collection("books")
          .where(FieldPath.documentId, whereIn: purchasedIds.take(10).toList())
          .get();

      final list = snapshot.docs.map((doc) => BookListing.fromJson(doc.data())).toList();
      list.sort((a, b) => b.resolvedDate.compareTo(a.resolvedDate));
      return list;
    } catch (e) {
      print("$_tag: getPurchaseHistory ERROR: $e");
      return [];
    }
  }

  static String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? "${uid1}_$uid2" : "${uid2}_$uid1";
  }

  static Future<String> createOrGetChat(
      String currentUid, String currentName, String targetUid, String targetName) async {
    final chatId = getChatId(currentUid, targetUid);
    final chatRef = _db.collection("chats").doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      final chat = Chat(
        id: chatId,
        participants: [currentUid, targetUid],
        participantNames: {currentUid: currentName, targetUid: targetName},
        timestamp: DateTime.now().millisecondsSinceEpoch,
        lastMessage: "",
      );
      await chatRef.set(chat.toJson());
    } else {
      await chatRef.update({
        "participants": FieldValue.arrayUnion([currentUid, targetUid])
      });
    }
    return chatId;
  }

  static Stream<List<Chat>> getInboxFlow(String uid) {
    return _db
        .collection("chats")
        .where("participants", arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Chat.fromJson(doc.data())).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  static Stream<List<Message>> getMessagesFlow(String chatId) {
    return _db
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  static Future<void> sendMessage(String chatId, String senderId, String text) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final chatRef = _db.collection("chats").doc(chatId);

      final messageId = chatRef.collection("messages").doc().id;
      final message = Message(
        id: messageId,
        senderId: senderId,
        text: text,
        timestamp: timestamp,
      );
      await chatRef.collection("messages").doc(messageId).set(message.toJson());

      final userIds = chatId.split("_");
      final p1 = userIds.isNotEmpty ? userIds[0] : "";
      final p2 = userIds.length > 1 ? userIds[1] : "";

      await chatRef.update({
        "lastMessage": text,
        "timestamp": timestamp,
        "participants": FieldValue.arrayUnion([p1, p2])
      });
    } catch (e) {
      print("$_tag: sendMessage ERROR: $e");
    }
  }

  static Future<void> deleteChatForUser(String chatId, String currentUid) async {
    try {
      await _db.collection("chats").doc(chatId).update({
        "participants": FieldValue.arrayRemove([currentUid])
      });
    } catch (e) {
      print("$_tag: deleteChatForUser ERROR: $e");
    }
  }
}
