import 'package:flutter/material.dart';
import '../services/post_service.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final _postService = PostService();
  final _titleController = TextEditingController();

  void _startLive() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('بدء بث مباشر'),
        content: TextField(
          controller: _titleController,
          decoration: const InputDecoration(hintText: 'عنوان البث...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final liveId = await _postService.startLiveStream(_titleController.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم بدء البث! (ID: $liveId)\nملاحظة: لربط WebRTC أو Agora أضف المفاتيح لاحقاً'),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            child: const Text('بدء البث'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البث المباشر'),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _startLive,
            tooltip: 'بدء بث',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postService.getLiveStreams(),
        builder: (context, snapshot) {
          final lives = snapshot.data ?? [];

          if (lives.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.live_tv_rounded, size: 90, color: Colors.grey[700]),
                  const SizedBox(height: 20),
                  Text('لا يوجد بث مباشر حالياً', style: TextStyle(color: Colors.grey[500], fontSize: 17)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _startLive,
                    icon: const Icon(Icons.sensors),
                    label: const Text('ابدأ بثاً مباشراً'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: lives.length,
            itemBuilder: (context, index) {
              final live = lives[index];
              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('مشاهدة البث - يحتاج تكامل Agora/WebRTC')),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Stack(
                            children: [
                              const Center(child: Icon(Icons.play_circle, size: 50, color: Colors.white54)),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('مباشر', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              live['title'] ?? 'بث مباشر',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              live['userName'] ?? '',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startLive,
        icon: const Icon(Icons.sensors),
        label: const Text('بث مباشر'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
