import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/post_service.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String postText;

  const CommentsScreen({super.key, required this.postId, required this.postText});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _controller = TextEditingController();
  final _postService = PostService();

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _postService.addComment(widget.postId, text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التعليقات')),
      body: Column(
        children: [
          if (widget.postText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A1A24),
              child: Text(widget.postText, style: const TextStyle(fontSize: 15)),
            ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _postService.getComments(widget.postId),
              builder: (context, snapshot) {
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Center(child: Text('لا توجد تعليقات بعد', style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF6C5CE7),
                        backgroundImage: c['userPhoto'] != null ? NetworkImage(c['userPhoto']) : null,
                        child: c['userPhoto'] == null
                            ? Text((c['userName'] as String? ?? '?')[0])
                            : null,
                      ),
                      title: Text(c['userName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(c['text'] ?? ''),
                      trailing: c['createdAt'] != null
                          ? Text(timeago.format(c['createdAt'], locale: 'ar'),
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]))
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'أضف تعليقاً...'),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF6C5CE7),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendComment,
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
