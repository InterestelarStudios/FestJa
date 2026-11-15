import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_business/models/business.dart';
import 'package:ifest_business/models/chat_model.dart';
import 'package:ifest_business/screens/chat/chat_room_screen.dart';
import 'package:ifest_business/services/chat_service.dart';
import 'package:ifest_business/theme/app_theme.dart';

class ChatListScreen extends StatefulWidget {
  final Business business;

  const ChatListScreen({super.key, required this.business});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  late Stream<List<ChatRoom>> _chatsStream;

  @override
  void initState() {
    super.initState();
    _chatsStream = _chatService.streamBusinessChats(widget.business.id);
  }

  @override
  void didUpdateWidget(ChatListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.business.id != oldWidget.business.id) {
      _chatsStream = _chatService.streamBusinessChats(widget.business.id);
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
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Mensagens dos Clientes'),
      ),
      body: StreamBuilder<List<ChatRoom>>(
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
    final hasUnread = chat.unreadCountBusiness > 0;

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
                // Client Avatar or Service Thumbnail
                CircleAvatar(
                  radius: 26,
                  backgroundColor: context.secondaryColor
                      .withValues(alpha: context.isDarkMode ? 0.25 : 0.12),
                  backgroundImage: chat.clientImage.isNotEmpty
                      ? NetworkImage(chat.clientImage)
                      : null,
                  child: chat.clientImage.isEmpty
                      ? Text(
                          chat.clientName.isNotEmpty
                              ? chat.clientName[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                            color: context.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                              chat.clientName,
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
                        '${chat.serviceTitle} • R\$ ${chat.servicePrice.toStringAsFixed(2).replaceAll('.', ',')}',
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
                                '${chat.unreadCountBusiness}',
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
              'Nenhuma mensagem recebida',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quando os clientes solicitarem orçamentos ou contratarem seus serviços, as conversas aparecerão aqui.',
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
}
