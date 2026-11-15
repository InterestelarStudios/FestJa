import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_business/models/chat_model.dart';
import 'package:ifest_business/services/booking_service.dart';
import 'package:ifest_business/services/chat_service.dart';
import 'package:ifest_business/theme/app_theme.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chat;

  const ChatRoomScreen({super.key, required this.chat});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final BookingService _bookingService = BookingService();
  bool _isSending = false;
  late String _currentStatus;
  late Stream<List<ChatMessage>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.chat.bookingStatus ?? 'pending';
    _messagesStream = _chatService.streamMessages(widget.chat.id);
    // Mark messages as read by the business
    _chatService.markChatAsRead(chatId: widget.chat.id, isClient: false);
  }

  @override
  void didUpdateWidget(ChatRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chat.id != oldWidget.chat.id) {
      _messagesStream = _chatService.streamMessages(widget.chat.id);
      _chatService.markChatAsRead(chatId: widget.chat.id, isClient: false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        chatId: widget.chat.id,
        senderId: user.uid,
        senderName: widget.chat.businessName,
        text: text,
        isClient: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar mensagem: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _updateBookingStatus(String status) async {
    if (widget.chat.bookingId == null || widget.chat.bookingId!.isEmpty) return;

    final isCompleted = status == 'completed';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: Text(isCompleted ? 'Finalizar Serviço' : 'Cancelar Pedido'),
        content: Text(
          isCompleted
              ? 'Confirmar que o serviço "${widget.chat.serviceTitle}" foi realizado com sucesso? O cliente receberá um aviso para avaliar a sua empresa.'
              : 'Tem certeza que deseja cancelar este pedido? O cliente será notificado sobre o cancelamento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dContext, false),
            child: Text('Voltar', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted
                  ? (context.isDarkMode ? context.secondaryColor : context.primaryColor)
                  : Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(isCompleted ? 'Finalizar Serviço' : 'Cancelar Pedido'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _bookingService.updateBookingStatus(widget.chat.bookingId!, status);
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .update({'bookingStatus': status});

      setState(() => _currentStatus = status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCompleted
                  ? 'Serviço finalizado com sucesso!'
                  : 'Pedido cancelado.',
            ),
            backgroundColor: isCompleted ? Colors.green : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar reserva: $e')),
        );
      }
    }
  }

  String _formatMessageTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatEventDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: context.secondaryColor
                  .withValues(alpha: context.isDarkMode ? 0.25 : 0.12),
              backgroundImage: widget.chat.clientImage.isNotEmpty
                  ? NetworkImage(widget.chat.clientImage)
                  : null,
              child: widget.chat.clientImage.isEmpty
                  ? Text(
                      widget.chat.clientName.isNotEmpty
                          ? widget.chat.clientName[0].toUpperCase()
                          : 'C',
                      style: TextStyle(
                        color: context.secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.clientName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.chat.clientPhone.isNotEmpty
                        ? widget.chat.clientPhone
                        : 'Cliente Fest\'Ja',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Pinned Marketplace Context Header (Item / Order Info)
          _buildMarketplaceContextHeader(context),

          // 2. Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyChatState(context);
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUid;
                    return _buildMessageBubble(context, msg, isMe);
                  },
                );
              },
            ),
          ),

          // 3. Message Input Bar
          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildMarketplaceContextHeader(BuildContext context) {
    final hasImage = widget.chat.serviceImage.isNotEmpty;
    final eventDateStr = _formatEventDate(widget.chat.eventDate);

    Color statusColor;
    String statusLabel;
    if (_currentStatus == 'completed') {
      statusColor = Colors.green;
      statusLabel = 'Finalizado';
    } else if (_currentStatus == 'cancelled' || _currentStatus == 'declined') {
      statusColor = Colors.redAccent;
      statusLabel = 'Cancelado';
    } else if (_currentStatus == 'inquiry') {
      statusColor = context.secondaryColor;
      statusLabel = 'Dúvida';
    } else {
      statusColor = context.secondaryColor;
      statusLabel = 'Em Andamento';
    }

    final isInProgress = _currentStatus == 'in_progress' ||
        _currentStatus == 'approved' ||
        _currentStatus == 'pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.2 : 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Service image thumbnail
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: context.isDarkMode
                      ? const Color(0xFF0F172A)
                      : Colors.grey.shade100,
                  border: Border.all(
                    color: context.isDarkMode
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(widget.chat.serviceImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasImage
                    ? Icon(
                        Icons.celebration_rounded,
                        color: context.secondaryColor,
                        size: 24,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Service details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chat.serviceTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'R\$ ${widget.chat.servicePrice.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            color: AppTheme.accentPink,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (eventDateStr.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•  $eventDateStr',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: context.isDarkMode ? 0.2 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Quick actions if in progress
          if (isInProgress &&
              widget.chat.bookingId != null &&
              widget.chat.bookingId!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _updateBookingStatus('cancelled'),
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: const Text('Cancelar Pedido', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _updateBookingStatus('completed'),
                  icon: const Icon(Icons.task_alt_rounded, size: 14),
                  label: const Text('Finalizar Serviço', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDarkMode ? context.secondaryColor : context.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage msg,
    bool isMe,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: context.isDarkMode
                            ? const [Color(0xFF7209B7), Color(0xFF5A189A)]
                            : const [Color(0xFF0D1B2A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : context.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: context.isDarkMode ? 0.2 : 0.04,
                    ),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : context.textPrimary,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(msg.timestamp),
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : context.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.secondaryColor.withValues(
                  alpha: context.isDarkMode ? 0.2 : 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.message_text,
                size: 40,
                color: context.secondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Conversa iniciada!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Responda às dúvidas do cliente e combine os preparativos do evento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          top: BorderSide(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? const Color(0xFF0F172A)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Responder ao cliente...',
                  hintStyle: TextStyle(
                    color: context.textMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.secondaryColor,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
