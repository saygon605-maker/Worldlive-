import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storage = StorageService();

  String get currentUserId => _auth.currentUser!.uid;

  String getChatId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> sendMessage({
    required String receiverId,
    String text = '',
    File? mediaFile,
    String mediaType = 'text',
  }) async {
    final senderId = currentUserId;
    final chatId = getChatId(senderId, receiverId);
    final timestamp = DateTime.now();

    String? mediaUrl;
    if (mediaFile != null) {
      if (mediaType == 'image') {
        mediaUrl = await _storage.uploadImage(mediaFile, folder: 'chat_images');
      } else if (mediaType == 'video') {
        mediaUrl = await _storage.uploadVideo(mediaFile, folder: 'chat_videos');
      }
    }

    final message = MessageModel(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      timestamp: timestamp,
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    String lastMsg = text;
    if (mediaType == 'image') lastMsg = '📷 صورة';
    if (mediaType == 'video') lastMsg = '🎥 فيديو';

    await _firestore.collection('chats').doc(chatId).set({
      'participants': [senderId, receiverId],
      'lastMessage': lastMsg,
      'lastMessageTime': Timestamp.fromDate(timestamp),
      'lastSenderId': senderId,
    }, SetOptions(merge: true));
  }

  Stream<List<MessageModel>> getMessages(String otherUserId) {
    final chatId = getChatId(currentUserId, otherUserId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getChatList() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> chats = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
        if (otherUserId.isEmpty) continue;

        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (!userDoc.exists) continue;

        final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
        chats.add({
          'chatId': doc.id,
          'user': user,
          'lastMessage': data['lastMessage'] ?? '',
          'lastMessageTime': (data['lastMessageTime'] as Timestamp?)?.toDate(),
          'lastSenderId': data['lastSenderId'],
        });
      }
      return chats;
    });
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> markMessagesAsRead(String otherUserId) async {
    final chatId = getChatId(currentUserId, otherUserId);
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }
}
