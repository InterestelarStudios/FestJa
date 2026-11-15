import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_business/models/business.dart';
import 'package:ifest_business/models/notification_model.dart';
import 'package:ifest_business/services/notification_service.dart';
import 'package:ifest_business/theme/app_theme.dart';

class BusinessNotificationsScreen extends StatefulWidget {
  final Business business;

  const BusinessNotificationsScreen({super.key, required this.business});

  @override
  State<BusinessNotificationsScreen> createState() =>
      _BusinessNotificationsScreenState();
}

class _BusinessNotificationsScreenState
    extends State<BusinessNotificationsScreen> {
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
      case 'booking_request':
        return Iconsax.ticket;
      case 'new_message':
        return Iconsax.message;
      case 'booking_approved':
        return Icons.check_circle_rounded;
      case 'booking_declined':
        return Icons.cancel_rounded;
      case 'review_received':
        return Icons.star_rounded;
      default:
        return Iconsax.notification;
    }
  }

  Color _getColorForType(BuildContext context, String type) {
    switch (type) {
      case 'booking_request':
        return context.secondaryColor;
      case 'new_message':
        return AppTheme.accentPink;
      case 'booking_approved':
        return Colors.green;
      case 'booking_declined':
        return Colors.redAccent;
      case 'review_received':
        return Colors.amber;
      default:
        return context.secondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Notificações da Empresa'),
        actions: [
          IconButton(
            tooltip: 'Marcar todas como lidas',
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () async {
              await _notificationService.markAllAsRead(widget.business.id);
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
          // Filtros
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
                  selectedColor: context.secondaryColor.withValues(alpha: 0.15),
                  checkmarkColor: context.secondaryColor,
                  labelStyle: TextStyle(
                    color: !_onlyUnread
                        ? context.secondaryColor
                        : context.textSecondary,
                    fontWeight:
                        !_onlyUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Não lidas'),
                  selected: _onlyUnread,
                  onSelected: (val) {
                    setState(() => _onlyUnread = true);
                  },
                  selectedColor: context.secondaryColor.withValues(alpha: 0.15),
                  checkmarkColor: context.secondaryColor,
                  labelStyle: TextStyle(
                    color: _onlyUnread
                        ? context.secondaryColor
                        : context.textSecondary,
                    fontWeight:
                        _onlyUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: _notificationService
                  .streamBusinessNotifications(widget.business.id),
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
                                : 'Sua caixa de notificações está vazia',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _onlyUnread
                                ? 'Todas as notificações da sua empresa já foram lidas.'
                                : 'Novas solicitações de reserva e mensagens dos clientes aparecerão aqui.',
                            style: TextStyle(color: context.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
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
                        child:
                            const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        _notificationService.deleteNotification(
                            widget.business.id, item.id);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: item.isRead
                              ? context.surfaceColor
                              : context.surfaceColor.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: !item.isRead
                                ? context.secondaryColor.withValues(alpha: 0.3)
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
                                    color: context.secondaryColor,
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
                              _notificationService.markAsRead(
                                  widget.business.id, item.id);
                            }
                            _notificationService.navigateToDestination(
                                context, item.data);
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
