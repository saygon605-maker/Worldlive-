class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? status;
  final DateTime? lastSeen;
  final bool isOnline;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.status,
    this.lastSeen,
    this.isOnline = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'مستخدم',
      photoUrl: map['photoUrl'],
      status: map['status'] ?? 'مرحباً، أنا أستخدم دردشتي!',
      lastSeen: map['lastSeen']?.toDate(),
      isOnline: map['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'status': status,
      'lastSeen': lastSeen,
      'isOnline': isOnline,
    };
  }
}
