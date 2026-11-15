import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_business/models/booking.dart';
import 'package:ifest_business/models/business.dart';
import 'package:ifest_business/screens/chat/chat_room_screen.dart';
import 'package:ifest_business/services/booking_service.dart';
import 'package:ifest_business/services/chat_service.dart';
import 'package:ifest_business/theme/app_theme.dart';

class BookingsScreen extends StatefulWidget {
  final Business business;

  const BookingsScreen({super.key, required this.business});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with AutomaticKeepAliveClientMixin {
  final BookingService _bookingService = BookingService();
  late Stream<List<Booking>> _bookingsStream;
  List<Booking>? _cachedBookings;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    _bookingsStream = _bookingService.streamBusinessBookings(widget.business.id);
  }

  @override
  void didUpdateWidget(BookingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business.id != widget.business.id) {
      _cachedBookings = null;
      _initStream();
    }
  }

  String _formatDate(Timestamp timestamp) {
    final d = timestamp.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _openBookingChat(BuildContext context, Booking b) async {
    try {
      final chat = await ChatService().getOrCreateBookingChat(
        bookingId: b.id,
        orderId: b.id,
        serviceId: b.serviceId,
        serviceTitle: b.serviceTitle,
        serviceImage: '',
        servicePrice: b.price.toDouble(),
        businessId: widget.business.id,
        businessName: widget.business.name,
        businessLogo: widget.business.logo,
        businessOwnerId: widget.business.creator.id,
        clientId: b.clientId,
        clientName: b.clientName,
        clientPhone: b.clientPhone,
        bookingStatus: b.status,
        eventDate: b.eventDate,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(chat: chat),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir chat: $e')),
        );
      }
    }
  }

  void _updateStatus(BuildContext context, Booking booking, String newStatus) async {
    final isCompleted = newStatus == 'completed';
    final titleText = isCompleted ? 'Finalizar Serviço' : 'Cancelar Pedido';
    final buttonColor = isCompleted
        ? (context.isDarkMode ? context.secondaryColor : context.primaryColor)
        : Colors.redAccent;
    final confirmButtonLabel = isCompleted ? 'Finalizar Serviço' : 'Cancelar Pedido';
    final message = isCompleted
        ? 'Confirmar que o serviço "${booking.serviceTitle}" foi realizado com sucesso? O cliente receberá um aviso para avaliar a sua empresa.'
        : 'Tem certeza que deseja cancelar o pedido de "${booking.clientName}"? O cliente será notificado sobre o cancelamento.';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: context.surfaceColor,
          title: Text(titleText),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Voltar', style: TextStyle(color: context.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                try {
                  await _bookingService.updateBookingStatus(booking.id, newStatus);
                  if (context.mounted) {
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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao atualizar status: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmButtonLabel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabWithBadge({
    required BuildContext context,
    required String label,
    required int count,
    required Color badgeColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<Booking>>(
      stream: _bookingsStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          _cachedBookings = snapshot.data;
        }

        final bookings = _cachedBookings ?? [];
        final inProgressBookings = bookings
            .where((b) =>
                b.status == 'in_progress' ||
                b.status == 'approved' ||
                b.status == 'pending')
            .toList();
        final completedBookings =
            bookings.where((b) => b.status == 'completed').toList();
        final cancelledBookings = bookings
            .where((b) => b.status == 'cancelled' || b.status == 'declined')
            .toList();

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: context.backgroundColor,
            appBar: AppBar(
              title: const Text('Pedidos e Reservas'),
              bottom: TabBar(
                labelColor: context.primaryColor,
                unselectedLabelColor: context.textSecondary,
                indicatorColor: context.primaryColor,
                tabs: [
                  Tab(
                    child: _buildTabWithBadge(
                      context: context,
                      label: 'Em Andamento',
                      count: inProgressBookings.length,
                      badgeColor: context.secondaryColor,
                    ),
                  ),
                  const Tab(text: 'Finalizados'),
                  const Tab(text: 'Cancelados'),
                ],
              ),
            ),
            body: _cachedBookings == null &&
                    snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : snapshot.hasError && _cachedBookings == null
                    ? Center(
                        child: Text(
                          'Erro ao carregar reservas.',
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                      )
                    : TabBarView(
                        children: [
                          _buildBookingList(
                            context,
                            inProgressBookings,
                            'in_progress',
                          ),
                          _buildBookingList(
                            context,
                            completedBookings,
                            'completed',
                          ),
                          _buildBookingList(
                            context,
                            cancelledBookings,
                            'cancelled',
                          ),
                        ],
                      ),
          ),
        );
      },
    );
  }

  Widget _buildBookingList(BuildContext context, List<Booking> items, String status) {
    if (items.isEmpty) {
      IconData emptyIcon;
      String emptyTitle;
      String emptySubtitle;

      if (status == 'completed') {
        emptyIcon = Iconsax.tick_circle;
        emptyTitle = 'Nenhum pedido finalizado';
        emptySubtitle = 'Os serviços que você finalizar aparecerão arquivados aqui.';
      } else if (status == 'cancelled') {
        emptyIcon = Iconsax.close_circle;
        emptyTitle = 'Nenhum pedido cancelado';
        emptySubtitle = 'Os pedidos que forem cancelados aparecerão aqui.';
      } else {
        emptyIcon = Iconsax.clock;
        emptyTitle = 'Nenhum pedido em andamento';
        emptySubtitle = 'Os pedidos confirmados e em andamento aparecerão nesta lista.';
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emptyIcon,
                size: 64,
                color: context.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                style: TextStyle(color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: PageStorageKey<String>('bookings_list_$status'),
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final b = items[index];
        return _buildBookingCard(context, b);
      },
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking b) {
    final isCompleted = b.status == 'completed';
    final isCancelled = b.status == 'cancelled' || b.status == 'declined';
    final isInProgress = !isCompleted && !isCancelled;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.3 : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.serviceTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: context.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${b.price.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.secondaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(context, b.status),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 14),
          _buildDetailRow(context, Iconsax.user, 'Cliente', b.clientName),
          const SizedBox(height: 8),
          _buildDetailRow(context, Iconsax.call, 'Contato', b.clientPhone),
          const SizedBox(height: 8),
          _buildDetailRow(context, Iconsax.calendar_1, 'Data do Evento', _formatDate(b.eventDate)),
          if (isInProgress) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(context, b, 'cancelled'),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Cancelar Pedido'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(context, b, 'completed'),
                    icon: const Icon(Icons.task_alt_rounded, size: 16),
                    label: const Text('Finalizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.isDarkMode ? context.secondaryColor : context.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isCompleted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    b.reviewed ? Icons.star_rounded : Icons.check_circle_rounded,
                    color: b.reviewed ? Colors.amber : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b.reviewed
                          ? 'Avaliado pelo cliente com ⭐ ${b.reviewRating?.toStringAsFixed(1) ?? "5.0"}'
                          : 'Serviço Finalizado! Aguardando avaliação do cliente.',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isCancelled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pedido Cancelado',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openBookingChat(context, b),
              icon: const Icon(Iconsax.message_text, size: 16),
              label: const Text('Conversar com o Cliente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.secondaryColor,
                side: BorderSide(
                  color: context.secondaryColor.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    String label;
    if (status == 'completed') {
      color = Colors.green;
      label = 'Finalizado';
    } else if (status == 'cancelled' || status == 'declined') {
      color = Colors.redAccent;
      label = 'Cancelado';
    } else {
      color = context.secondaryColor;
      label = 'Em Andamento';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDarkMode ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.secondaryColor.withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: context.secondaryColor),
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
