import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_app/models/event.dart';
import 'package:ifest_app/theme/app_theme.dart';
import 'package:ifest_app/screens/events/create_event_screen.dart';
import 'package:ifest_app/screens/marketplace/marketplace_screen.dart';

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
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildEventInfo(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildCategorySection(context, _categories[index]);
                },
                childCount: _categories.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100), // padding no final
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateEventScreen(eventToEdit: event),
            ),
          );
        },
        backgroundColor: AppTheme.primaryDark,
        child: const Icon(Iconsax.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final hasImage = event.image != null && event.image!.isNotEmpty;
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppTheme.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          event.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
          ),
        ),
        background: hasImage
            ? Image.network(
                event.image!,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.3),
                colorBlendMode: BlendMode.darken,
              )
            : Container(
                color: AppTheme.primaryDark,
                child: const Center(
                  child: Icon(
                    Iconsax.calendar_1,
                    size: 80,
                    color: Colors.white24,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEventInfo(BuildContext context) {
    final date = event.date.toDate();
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _infoTile(Iconsax.calendar_1, dateStr),
              const SizedBox(width: 24),
              _infoTile(Iconsax.clock, timeStr),
              const SizedBox(width: 24),
              _infoTile(Iconsax.people, '${event.people} conv.'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.primaryDark, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (event.address != null && event.address!.isNotEmpty)
                      ? event.address!
                      : 'Localização a definir',
                  style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Sobre o Evento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
            ),
            const SizedBox(height: 8),
            Text(
              event.description!,
              style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Serviços e Fornecedores',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gerencie os fornecedores e adicione itens para o seu evento.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryDark, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, String categoryName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
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
        title: Text(
          categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
        subtitle: const Text('Nenhum item selecionado', style: TextStyle(fontSize: 12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryDark.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Iconsax.box, color: AppTheme.primaryDark, size: 20),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                label: Text('Buscar $categoryName'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryDark,
                  side: const BorderSide(color: AppTheme.primaryDark),
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
