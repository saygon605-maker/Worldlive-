import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _chatService.markMessagesAsRead(widget.otherUser.uid);
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _chatService.sendMessage(receiverId: widget.otherUser.uid, text: text);
  }

  Future<void> _sendMedia(ImageSource source, {bool isVideo = false}) async {
    final XFile? picked = isVideo
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source, imageQuality: 75);

    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      await _chatService.sendMessage(
        receiverId: widget.otherUser.uid,
        mediaFile: File(picked.path),
        mediaType: isVideo ? 'video' : 'image',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإرسال: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF00CEC9)),
                title: const Text('صورة من المعرض'),
                onTap: () {
                  Navigator.pop(context);
                  _sendMedia(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF6C5CE7)),
                title: const Text('التقاط صورة'),
                onTap: () {
                  Navigator.pop(context);
                  _sendMedia(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.orange),
                title: const Text('فيديو من المعرض'),
                onTap: () {
                  Navigator.pop(context);
                  _sendMedia(ImageSource.gallery, isVideo: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startCall({bool isVideo = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isVideo
            ? 'مكالمة فيديو - أضف مفتاح Agora لتفعيلها'
            : 'مكالمة صوتية - أضف مفتاح Agora لتفعيلها'),
        backgroundColor: const Color(0xFF6C5CE7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF6C5CE7),
              backgroundImage: widget.otherUser.photoUrl != null
                  ? NetworkImage(widget.otherUser.photoUrl!)
                  : null,
              child: widget.otherUser.photoUrl == null
                  ? Text(widget.otherUser.displayName.isNotEmpty ? widget.otherUser.displayName[0] : '؟')
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUser.displayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(
                    widget.otherUser.isOnline ? 'متصل الآن' : 'غير متصل',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.otherUser.isOnline ? const Color(0xFF00CEC9) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () => _startCall(isVideo: true),
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () => _startCall(isVideo: false),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(widget.otherUser.uid),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.waving_hand, size: 50, color: Colors.grey[600]),
                        const SizedBox(height: 12),
                        Text('قل مرحباً لـ ${widget.otherUser.displayName}!',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: message.mediaType != 'text'
                            ? const EdgeInsets.all(6)
                            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF6C5CE7).withOpacity(0.25) : const Color(0xFF1A1A24),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(4) : const Radius.circular(16),
                            bottomRight: isMe ? const Radius.circular(16) : const Radius.circular(4),
                          ),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (message.mediaType == 'image' && message.mediaUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: message.mediaUrl!,
                                  width: 220,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    height: 160,
                                    width: 220,
                                    color: Colors.black26,
                                    child: const Center(child: CircularProgressIndicator()),
                                  ),
                                ),
                              ),
                            if (message.mediaType == 'video' && message.mediaUrl != null)
                              Container(
                                width: 220,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white70),
                                ),
                              ),
                            if (message.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(message.text, style: const TextStyle(fontSize: 15)),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(message.timestamp),
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message.isRead ? Icons.done_all : Icons.done,
                                    size: 14,
                                    color: message.isRead ? const Color(0xFF00CEC9) : Colors.grey,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading)
            const LinearProgressIndicator(color: Color(0xFF6C5CE7), minHeight: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: Colors.grey),
                    onPressed: _showMediaOptions,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        filled: true,
                        fillColor: const Color(0xFF0F0F13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF6C5CE7),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sendText,
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
}
