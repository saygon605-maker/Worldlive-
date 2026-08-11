import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import 'storage_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storage = StorageService();

  String get currentUserId => _auth.currentUser!.uid;

  Future<void> createPost({
    String? text,
    File? mediaFile,
    String mediaType = 'none',
    bool isLive = false,
  }) async {
    final user = _auth.currentUser!;
    String? mediaUrl;

    if (mediaFile != null) {
      if (mediaType == 'image') {
        mediaUrl = await _storage.uploadImage(mediaFile, folder: 'posts');
      } else if (mediaType == 'video') {
        mediaUrl = await _storage.uploadVideo(mediaFile, folder: 'posts');
      }
    }

    final post = PostModel(
      id: '',
      userId: user.uid,
      userName: user.displayName ?? 'مستخدم',
      userPhoto: user.photoURL,
      text: text,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      createdAt: DateTime.now(),
      isLive: isLive,
    );

    await _firestore.collection('posts').add(post.toMap());
  }

  Stream<List<PostModel>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> toggleLike(PostModel post) async {
    final uid = currentUserId;
    final ref = _firestore.collection('posts').doc(post.id);

    if (post.isLikedBy(uid)) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([uid]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([uid]),
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> addComment(String postId, String text) async {
    final user = _auth.currentUser!;
    await _firestore.collection('posts').doc(postId).collection('comments').add({
      'userId': user.uid,
      'userName': user.displayName ?? 'مستخدم',
      'userPhoto': user.photoURL,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('posts').doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userId': data['userId'],
          'userName': data['userName'],
          'userPhoto': data['userPhoto'],
          'text': data['text'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    });
  }

  // بدء بث مباشر (هيكل أساسي)
  Future<String> startLiveStream(String title) async {
    final user = _auth.currentUser!;
    final doc = await _firestore.collection('lives').add({
      'userId': user.uid,
      'userName': user.displayName ?? 'مستخدم',
      'userPhoto': user.photoURL,
      'title': title,
      'isLive': true,
      'viewersCount': 0,
      'startedAt': FieldValue.serverTimestamp(),
    });

    // إنشاء منشور بث مباشر
    await createPost(text: title, isLive: true);

    return doc.id;
  }

  Future<void> endLiveStream(String liveId) async {
    await _firestore.collection('lives').doc(liveId).update({
      'isLive': false,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getLiveStreams() {
    return _firestore
        .collection('lives')
        .where('isLive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }
}
