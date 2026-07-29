import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:ifest_app/models/business.dart';
import 'package:ifest_app/models/service_ads.dart';
import 'package:ifest_app/theme/app_theme.dart';
import 'package:ifest_app/screens/marketplace/service_details_screen.dart';
import 'package:ifest_app/services/favorites_service.dart';

class BusinessProfileScreen extends StatelessWidget {
  final BusinessDetails businessDetails;

  const BusinessProfileScreen({super.key, required this.businessDetails});

  Future<Business?> _fetchFullBusiness() async {
    final doc = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessDetails.id)
        .get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (!data.containsKey('id')) data['id'] = doc.id;
      return Business.fromMap(data);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: FutureBuilder<Business?>(
        future: _fetchFullBusiness(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final business = snapshot.data;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(business),
              if (business != null)
                SliverToBoxAdapter(
                  child: _buildBusinessInfo(context, business),
                ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    'Serviços e Produtos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              ),
              _buildBusinessServices(),
              if (business != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Empresa parceira desde ${business.created.toDate().day.toString().padLeft(2, '0')}/${business.created.toDate().month.toString().padLeft(2, '0')}/${business.created.toDate().year}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(Business? fullBusiness) {
    final logo = fullBusiness?.logo ?? businessDetails.logo;
    final hasLogo = logo.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppTheme.primaryDark,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        StreamBuilder<bool>(
          stream: FavoritesService().isBusinessFavorite(businessDetails.id),
          builder: (context, snapshot) {
            final isFav = snapshot.data ?? false;
            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? Colors.redAccent : Colors.white,
              ),
              onPressed: () {
                FavoritesService().toggleFavoriteBusiness(businessDetails.id, !isFav);
              },
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Fundo Genérico
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.headerGradient,
              ),
            ),
            // Pattern overlay
            Opacity(
              opacity: 0.1,
              child: Image.asset('assets/auth1.jpg', fit: BoxFit.cover),
            ),
            // Informações da Capa
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: hasLogo
                          ? DecorationImage(
                              image: NetworkImage(logo),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !hasLogo
                        ? const Icon(
                            Icons.storefront_rounded,
                            size: 40,
                            color: AppTheme.primaryDark,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullBusiness?.name ?? businessDetails.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                fullBusiness?.region ?? businessDetails.region,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfo(BuildContext context, Business business) {
    return Container(
      color: AppTheme.backgroundLight,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categorias
          if (business.categories.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: business.categories.map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Endereço
          if (business.address != null && business.address!.isNotEmpty) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: AppTheme.primaryDark,
                ),
              ),
              title: const Text(
                'Endereço',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                business.address!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
              onTap: () async {
                final lat = business.geoPoint.latitude;
                final lng = business.geoPoint.longitude;
                final url = Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Não foi possível abrir o mapa.'),
                      ),
                    );
                  }
                }
              },
            ),
          ],

          if (business.description != null &&
              business.description!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Sobre a Empresa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              business.description!,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBusinessServices() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_ads')
          .where('business.id', isEqualTo: businessDetails.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('Erro ao carregar serviços.')),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Nenhum serviço anunciado ainda.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          );
        }

        final ads = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (!data.containsKey('id')) data['id'] = doc.id;
          return ServiceAds.fromMap(data);
        }).toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildProductCard(context, ads[index]),
              childCount: ads.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, ServiceAds ad) {
    final hasImage = ad.images.isNotEmpty;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(serviceAd: ad),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: Colors.grey.shade200,
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(ad.images.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasImage
                    ? const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
            ),
            // Detalhes
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${ad.price.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
