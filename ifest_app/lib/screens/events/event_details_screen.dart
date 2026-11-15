import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_app/models/event.dart';
import 'package:ifest_app/models/booking.dart';
import 'package:ifest_app/screens/marketplace/widgets/review_bottom_sheet.dart';
import 'package:ifest_app/theme/app_theme.dart';
import 'package:ifest_app/screens/events/create_event_screen.dart';
import 'package:ifest_app/screens/marketplace/marketplace_screen.dart';
import 'package:ifest_app/services/event_service.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event event;

  const EventDetailsScreen({super.key, required this.event});

  final List<String> _categories = const [
    'Local',
    'Decoração',
    'Atração',
    'Som e Iluminação',
    'Alimentação',
    'Bebidas',
    'Outros',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(event.id)
            .collection('services')
            .snapshots(),
        builder: (context, snapshot) {
          final bookedDocs = snapshot.data?.docs ?? [];
          final bookedServices = bookedDocs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: _buildEventInfo(context, bookedServices),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final categoryName = _categories[index];
                      final categoryServices = bookedServices.where((s) {
                        final cats = (s['categories'] as List?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            [];
                        if (cats.contains(categoryName)) return true;
                        if (cats.isEmpty && categoryName == 'Outros') return true;
                        return false;
                      }).toList();

                      return _buildCategorySection(
                          context, categoryName, categoryServices);
                    },
                    childCount: _categories.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: GestureDetector(
          onTapDown: (details) {
            _showOptionsMenu(context, details);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.more_vert_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
    );
  }

  void _showOptionsMenu(BuildContext context, TapDownDetails details) async {
    final double left = details.globalPosition.dx;
    final double top = details.globalPosition.dy;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(left - 100, top, left, top + 100),
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Iconsax.edit, size: 18),
              SizedBox(width: 8),
              Text('Editar Evento'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Iconsax.trash, size: 18, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Excluir Evento', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );

    if (result == 'edit') {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateEventScreen(eventToEdit: event),
          ),
        );
      }
    } else if (result == 'delete') {
      if (context.mounted) {
        _showDeleteConfirmationDialog(context);
      }
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Excluir Evento'),
          content: const Text(
            'Tem certeza que deseja excluir este evento? Esta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: context.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await EventService().deleteEvent(event.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Evento excluído com sucesso!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao excluir evento: $e')),
                    );
                  }
                }
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final hasImage = event.image != null && event.image!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: context.backgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          event.title,
          style: TextStyle(
            color: hasImage ? Colors.white : context.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: hasImage
                ? const [Shadow(color: Colors.black87, blurRadius: 8)]
                : null,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(
                event.image!,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: context.primaryColor.withValues(alpha: 0.1),
                child: Center(
                  child: Icon(
                    Iconsax.calendar_1,
                    size: 80,
                    color: context.primaryColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
            if (hasImage)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final date = event.date.toDate();
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final formattedTime =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  context,
                  Iconsax.calendar,
                  formattedDate,
                ),
              ),
              Expanded(
                child: _infoTile(
                  context,
                  Iconsax.clock,
                  formattedTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  context,
                  Iconsax.people,
                  '${event.people} convidados',
                ),
              ),
              if (event.region != null && event.region!.isNotEmpty)
                Expanded(
                  child: _infoTile(
                    context,
                    Iconsax.location,
                    event.region!,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    if (event.description == null || event.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descrição',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.description!,
            style: TextStyle(color: context.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planejamento por Categoria',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Acompanhe o que já foi contratado e o que ainda falta para a sua festa.',
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo(
      BuildContext context, List<Map<String, dynamic>> bookedServices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildDetailsCard(context),
        _buildDescriptionCard(context),
        if (bookedServices.isNotEmpty)
          _buildContractedServicesSummary(context, bookedServices),
        _buildServicesHeader(context),
      ],
    );
  }

  Widget _buildContractedServicesSummary(
      BuildContext context, List<Map<String, dynamic>> bookedServices) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Visão Geral dos Contratados (${bookedServices.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...bookedServices.map((data) {
            final title = data['serviceTitle'] as String? ?? 'Serviço';
            final businessName = data['businessName'] as String? ?? '';
            final image = data['image'] as String?;
            final price = (data['price'] as num? ?? 0).toDouble();
            final quantity = data['quantity'] as int? ?? 1;

            return GestureDetector(
              onTap: () => _handleServiceTap(context, data),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: context.primaryColor.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: image != null && image.isNotEmpty
                            ? Image.network(image, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.storefront_rounded,
                                    color: Colors.grey),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (businessName.isNotEmpty)
                            Text(
                              businessName,
                              style: TextStyle(
                                  color: context.textSecondary, fontSize: 11),
                            ),
                          Text(
                            'Qtd: $quantity • R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: TextStyle(
                              color: context.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Confirmado',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 14, color: Colors.green),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _handleServiceTap(BuildContext context, Map<String, dynamic> data) async {
    final bookingId = data['id'] as String?;
    if (bookingId == null || bookingId.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance.collection('bookings').doc(bookingId).get();
      if (!snap.exists || !context.mounted) return;

      final bookingData = snap.data()!;
      if (!bookingData.containsKey('id')) bookingData['id'] = snap.id;
      final booking = Booking.fromMap(bookingData);

      if (booking.status == 'completed') {
        if (booking.reviewed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Serviço já avaliado com ⭐ ${booking.reviewRating?.toStringAsFixed(1) ?? "5.0"}!'),
            ),
          );
        } else {
          ReviewBottomSheet.show(context, booking);
        }
      } else {
        showDialog(
          context: context,
          builder: (dContext) => AlertDialog(
            backgroundColor: context.surfaceColor,
            title: const Text('Concluir e Avaliar Serviço'),
            content: Text('Deseja marcar o serviço "${booking.serviceTitle}" como concluído e deixar sua avaliação?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dContext),
                child: Text('Cancelar', style: TextStyle(color: context.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dContext);
                  await FirebaseFirestore.instance.collection('bookings').doc(booking.id).update({
                    'status': 'completed',
                    'completedAt': FieldValue.serverTimestamp(),
                    'reviewed': false,
                  });
                  booking.status = 'completed';
                  if (context.mounted) {
                    ReviewBottomSheet.show(context, booking);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Concluir e Avaliar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao abrir detalhes da reserva: $e');
    }
  }

  Widget _infoTile(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: context.primaryColor, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, String categoryName,
      List<Map<String, dynamic>> categoryServices) {
    final hasItems = categoryServices.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: hasItems,
        title: Text(
          categoryName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: hasItems ? Colors.green.shade700 : context.primaryColor,
          ),
        ),
        subtitle: Text(
          hasItems
              ? '${categoryServices.length} item(s) contratado(s)'
              : 'Pendente • Nenhum item contratado',
          style: TextStyle(
            fontSize: 12,
            color: hasItems ? Colors.green : context.textSecondary,
            fontWeight: hasItems ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (hasItems ? Colors.green : context.primaryColor)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            hasItems ? Icons.check_circle_rounded : Iconsax.box,
            color: hasItems ? Colors.green : context.primaryColor,
            size: 20,
          ),
        ),
        children: [
          if (hasItems) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: categoryServices.map((item) {
                  final title = item['serviceTitle'] as String? ?? 'Serviço';
                  final businessName = item['businessName'] as String? ?? '';
                  final image = item['image'] as String?;
                  final price = (item['price'] as num? ?? 0).toDouble();
                  final quantity = item['quantity'] as int? ?? 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: image != null && image.isNotEmpty
                                ? Image.network(image, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.storefront_rounded,
                                        color: Colors.grey, size: 20),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (businessName.isNotEmpty)
                                Text(
                                  businessName,
                                  style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 11),
                                ),
                              Text(
                                'Qtd: $quantity • R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: TextStyle(
                                  color: context.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Contratado',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarketplaceScreen(
                        region: event.region,
                        geoPoint: event.geoPoint,
                        initialCategory: categoryName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Iconsax.search_normal_1, size: 18),
                label: Text(hasItems
                    ? 'Buscar mais opções de $categoryName'
                    : 'Buscar $categoryName'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.primaryColor,
                  side: BorderSide(color: context.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
