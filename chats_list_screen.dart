import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';
import 'users_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدردشات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getChatList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text('لا توجد محادثات', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('ابدأ محادثة'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.05), indent: 80),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final user = chat['user'] as UserModel;
              final lastMessage = chat['lastMessage'] as String;
              final lastTime = chat['lastMessageTime'] as DateTime?;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF6C5CE7),
                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null
                          ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '؟',
                              style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    if (user.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00CEC9),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0F0F13), width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[500])),
                trailing: lastTime != null
                    ? Text(
                        DateFormat('HH:mm').format(lastTime),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()));
        },
        child: const Icon(Icons.message_rounded),
      ),
    );
  }
}
