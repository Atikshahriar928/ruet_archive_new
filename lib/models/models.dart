import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportMode { lost, found }

const List<String> itemCategories = [
  "Electronics",
  "Books",
  "Wallets",
  "Accessories",
  "Identity Cards",
  "Keys",
  "Other"
];

class LostFoundItem {
  final String id;
  final String title;
  final String category;
  final String location;
  final String date;
  final String description;
  final List<String> imageBase64List;
  final String type; 
  final String ownerUid;
  final String reporterName;
  final int timestamp;
  final String status;
  final int resolvedDate;

  LostFoundItem({
    this.id = "",
    this.title = "",
    this.category = "",
    this.location = "",
    this.date = "",
    this.description = "",
    this.imageBase64List = const [],
    this.type = "",
    this.ownerUid = "",
    this.reporterName = "",
    int? timestamp,
    this.status = "available",
    this.resolvedDate = 0,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory LostFoundItem.fromJson(Map<String, dynamic> json) {
    return LostFoundItem(
      id: json['id'] ?? "",
      title: json['title'] ?? "",
      category: json['category'] ?? "",
      location: json['location'] ?? "",
      date: json['date'] ?? "",
      description: json['description'] ?? "",
      imageBase64List: List<String>.from(json['imageBase64List'] ?? []),
      type: json['type'] ?? "",
      ownerUid: json['ownerUid'] ?? "",
      reporterName: json['reporterName'] ?? "",
      timestamp: json['timestamp'] is int ? json['timestamp'] : 0,
      status: json['status'] ?? "available",
      resolvedDate: json['resolvedDate'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'location': location,
      'date': date,
      'description': description,
      'imageBase64List': imageBase64List,
      'type': type,
      'ownerUid': ownerUid,
      'reporterName': reporterName,
      'timestamp': timestamp,
      'status': status,
      'resolvedDate': resolvedDate,
    };
  }
}

class BookListing {
  final String id;
  final String bookName;
  final String authorName;
  final String deptName;
  final String courseCode;
  final String courseName;
  final String year;
  final String semester;
  final String condition;
  final double price;
  final String description;
  final List<String> imageBase64List;
  final String ownerUid;
  final String reporterName;
  final int timestamp;
  final String status; 
  final int resolvedDate;

  BookListing({
    this.id = "",
    this.bookName = "",
    this.authorName = "",
    this.deptName = "",
    this.courseCode = "",
    this.courseName = "",
    this.year = "",
    this.semester = "",
    this.condition = "",
    this.price = 0.0,
    this.description = "",
    this.imageBase64List = const [],
    this.ownerUid = "",
    this.reporterName = "",
    int? timestamp,
    this.status = "available",
    this.resolvedDate = 0,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory BookListing.fromJson(Map<String, dynamic> json) {
    return BookListing(
      id: json['id'] ?? "",
      bookName: json['bookName'] ?? "",
      authorName: json['authorName'] ?? "",
      deptName: json['deptName'] ?? "",
      courseCode: json['courseCode'] ?? "",
      courseName: json['courseName'] ?? "",
      year: json['year'] ?? "",
      semester: json['semester'] ?? "",
      condition: json['condition'] ?? "",
      price: (json['price'] ?? 0.0).toDouble(),
      description: json['description'] ?? "",
      imageBase64List: List<String>.from(json['imageBase64List'] ?? []),
      ownerUid: json['ownerUid'] ?? "",
      reporterName: json['reporterName'] ?? "",
      timestamp: json['timestamp'] is int ? json['timestamp'] : 0,
      status: json['status'] ?? "available",
      resolvedDate: json['resolvedDate'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookName': bookName,
      'authorName': authorName,
      'deptName': deptName,
      'courseCode': courseCode,
      'courseName': courseName,
      'year': year,
      'semester': semester,
      'condition': condition,
      'price': price,
      'description': description,
      'imageBase64List': imageBase64List,
      'ownerUid': ownerUid,
      'reporterName': reporterName,
      'timestamp': timestamp,
      'status': status,
      'resolvedDate': resolvedDate,
    };
  }
}

class UserProfile {
  final String uid;
  final String fullName;
  final String dept;
  final String series;
  final String mobile;
  final String? profileImageBase64;
  final int timestamp;
  final List<String> cartedBookIds;
  final List<String> purchasedBookIds;
  final String status;
  final int lastSeen;

  UserProfile({
    this.uid = "",
    this.fullName = "",
    this.dept = "",
    this.series = "",
    this.mobile = "",
    this.profileImageBase64,
    int? timestamp,
    this.cartedBookIds = const [],
    this.purchasedBookIds = const [],
    this.status = "offline",
    this.lastSeen = 0,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? json['id'] ?? "",
      fullName: json['fullName'] ?? json['displayName'] ?? json['name'] ?? "",
      dept: json['dept'] ?? json['department'] ?? "",
      series: json['series'] ?? "",
      mobile: json['mobile'] ?? json['phoneNumber'] ?? json['phone'] ?? "",
      profileImageBase64: json['profileImageBase64'] ?? json['photoURL'] ?? json['imageUrl'],
      timestamp: json['timestamp'] is int ? json['timestamp'] : 0,
      cartedBookIds: List<String>.from(json['cartedBookIds'] ?? []),
      purchasedBookIds: List<String>.from(json['purchasedBookIds'] ?? []),
      status: json['status'] ?? "offline",
      lastSeen: json['lastSeen'] is int ? json['lastSeen'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'dept': dept,
      'series': series,
      'mobile': mobile,
      'profileImageBase64': profileImageBase64,
      'timestamp': timestamp,
      'cartedBookIds': cartedBookIds,
      'purchasedBookIds': purchasedBookIds,
      'status': status,
      'lastSeen': lastSeen,
    };
  }
}

class UserStats {
  final int itemsSold;
  final int itemsFound;
  final int itemsLost;

  UserStats({
    this.itemsSold = 0,
    this.itemsFound = 0,
    this.itemsLost = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      itemsSold: json['itemsSold'] ?? 0,
      itemsFound: json['itemsFound'] ?? 0,
      itemsLost: json['itemsLost'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemsSold': itemsSold,
      'itemsFound': itemsFound,
      'itemsLost': itemsLost,
    };
  }
}

class Chat {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final int timestamp;

  Chat({
    this.id = "",
    this.participants = const [],
    this.participantNames = const {},
    this.lastMessage = "",
    this.timestamp = 0,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? "",
      participants: List<String>.from(json['participants'] ?? []),
      participantNames: Map<String, String>.from(json['participantNames'] ?? {}),
      lastMessage: json['lastMessage'] ?? "",
      timestamp: json['timestamp'] is int ? json['timestamp'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
    };
  }
}

class Message {
  final String id;
  final String senderId;
  final String text;
  final int timestamp;

  Message({
    this.id = "",
    this.senderId = "",
    this.text = "",
    this.timestamp = 0,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? "",
      senderId: json['senderId'] ?? "",
      text: json['text'] ?? "",
      timestamp: json['timestamp'] is int ? json['timestamp'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
