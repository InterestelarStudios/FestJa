import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_app/models/chat_model.dart';
import 'package:ifest_app/screens/chat/chat_room_screen.dart';
import 'package:ifest_app/services/chat_service.dart';
import 'package:ifest_app/theme/app_theme.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  Stream<List<ChatRoom>>? _chatsStream;
  String? _cachedUid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _cachedUid = user.uid;
      _chatsStream = _chatService.streamClientChats(user.uid);
    }
  }

  String _formatRelativeTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (_chatsStream == null || _cachedUid != user.uid)) {
      _cachedUid = user.uid;
      _chatsStream = _chatService.streamClientChats(user.uid);
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Mensagens & Pedidos'),
      ),
      body: user == null
          ? _buildLoginPrompt(context)
          : StreamBuilder<List<ChatRoom>>(
              stream: _chatsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chats = snapshot.data ?? [];

                if (chats.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: chats.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _buildChatCard(context, chat);
                  },
                );
              },
            ),
    );
  }

  Widget _buildChatCard(BuildContext context, ChatRoom chat) {
    final hasUnread = chat.unreadCountClient > 0;
    final hasImage = chat.serviceImage.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasUnread
              ? AppTheme.accentPink.withValues(alpha: 0.4)
              : context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
          width: hasUnread ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.25 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomScreen(chat: chat),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Service thumbnail or store icon
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: context.isDarkMode
                        ? const Color(0xFF0F172A)
                        : Colors.grey.shade100,
                    image: hasImage
                        ? DecorationImage(
                            image: NetworkImage(chat.serviceImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasImage
                      ? Icon(
                          Icons.celebration_rounded,
                          color: context.secondaryColor,
                          size: 26,
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Chat Info & Last Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat.businessName,
                              style: TextStyle(
                                fontWeight: hasUnread
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 14,
                                color: context.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatRelativeTime(chat.lastMessageTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: hasUnread
                                  ? AppTheme.accentPink
                                  : context.textMuted,
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Service title tag
                      Text(
                        chat.serviceTitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.secondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Last message snippet & unread badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage.isNotEmpty
                                  ? chat.lastMessage
                                  : 'Sem mensagens recentes',
                              style: TextStyle(
                                fontSize: 13,
                                color: hasUnread
                                    ? context.textPrimary
                                    : context.textSecondary,
                                fontWeight: hasUnread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPink,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${chat.unreadCountClient}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.secondaryColor.withValues(
                  alpha: context.isDarkMode ? 0.2 : 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.message_notif,
                size: 48,
                color: context.secondaryColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nenhuma conversa ainda',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ao contratar um serviço ou enviar uma mensagem para um fornecedor, sua conversa aparecerá aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.lock, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Acesse sua conta para ver suas mensagens',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
