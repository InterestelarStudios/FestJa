import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_app/models/notification_model.dart';
import 'package:ifest_app/services/notification_service.dart';
import 'package:ifest_app/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _onlyUnread = false;

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours} h';
    if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'booking_approved':
        return Icons.check_circle_rounded;
      case 'booking_declined':
        return Icons.cancel_rounded;
      case 'booking_request':
        return Iconsax.ticket;
      case 'new_message':
        return Iconsax.message;
      case 'event_reminder':
        return Iconsax.calendar_1;
      default:
        return Iconsax.notification;
    }
  }

  Color _getColorForType(BuildContext context, String type) {
    switch (type) {
      case 'booking_approved':
        return Colors.green;
      case 'booking_declined':
        return Colors.redAccent;
      case 'booking_request':
        return Colors.orange;
      case 'new_message':
        return context.secondaryColor;
      case 'event_reminder':
        return AppTheme.accentPink;
      default:
        return context.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(title: const Text('Notificações')),
        body: Center(
          child: Text(
            'Faça login para ver suas notificações.',
            style: TextStyle(color: context.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            tooltip: 'Marcar todas como lidas',
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () async {
              await _notificationService.markAllAsRead(user.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todas as notificações foram marcadas como lidas.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro Todas / Não lidas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: !_onlyUnread,
                  onSelected: (val) {
                    setState(() => _onlyUnread = false);
                  },
                  selectedColor: context.primaryColor.withValues(alpha: 0.15),
                  checkmarkColor: context.primaryColor,
                  labelStyle: TextStyle(
                    color: !_onlyUnread ? context.primaryColor : context.textSecondary,
                    fontWeight: !_onlyUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Não lidas'),
                  selected: _onlyUnread,
                  onSelected: (val) {
                    setState(() => _onlyUnread = true);
                  },
                  selectedColor: context.primaryColor.withValues(alpha: 0.15),
                  checkmarkColor: context.primaryColor,
                  labelStyle: TextStyle(
                    color: _onlyUnread ? context.primaryColor : context.textSecondary,
                    fontWeight: _onlyUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: _notificationService.streamNotifications(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var list = snapshot.data ?? [];
                if (_onlyUnread) {
                  list = list.where((n) => !n.isRead).toList();
                }

                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.notification_bing,
                            size: 64,
                            color: context.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _onlyUnread
                                ? 'Nenhuma notificação não lida'
                                : 'Você não tem notificações',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _onlyUnread
                                ? 'Você já leu todas as suas notificações recebidas.'
                                : 'Avisos sobre seus eventos, reservas e mensagens aparecerão aqui.',
                            style: TextStyle(color: context.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final color = _getColorForType(context, item.type);
                    final icon = _getIconForType(item.type);

                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        _notificationService.deleteNotification(user.uid, item.id);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: item.isRead
                              ? context.surfaceColor
                              : context.surfaceColor.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: !item.isRead
                                ? context.primaryColor.withValues(alpha: 0.3)
                                : context.isDarkMode
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                            width: !item.isRead ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: !item.isRead
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (!item.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: BoxDecoration(
                                    color: context.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatTime(item.createdAt),
                                style: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            if (!item.isRead) {
                              _notificationService.markAsRead(user.uid, item.id);
                            }
                            _notificationService.navigateToDestination(context, item.data);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
