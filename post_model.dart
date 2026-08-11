import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String? text;
  final String? mediaUrl;
  final String mediaType; // image, video, none
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy;
  final bool isLive;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    this.text,
    this.mediaUrl,
    this.mediaType = 'none',
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.isLive = false,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    return PostModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'مستخدم',
      userPhoto: map['userPhoto'],
      text: map['text'],
      mediaUrl: map['mediaUrl'],
      mediaType: map['mediaType'] ?? 'none',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      isLive: map['isLive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'isLive': isLive,
    };
  }

  bool isLikedBy(String uid) => likedBy.contains(uid);
}
