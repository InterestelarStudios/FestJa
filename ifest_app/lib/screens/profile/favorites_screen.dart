import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ifest_app/models/business.dart';
import 'package:ifest_app/models/service_ads.dart';
import 'package:ifest_app/theme/app_theme.dart';
import 'package:ifest_app/screens/marketplace/business_profile_screen.dart';
import 'package:ifest_app/screens/marketplace/service_details_screen.dart';
import 'package:ifest_app/services/favorites_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.primaryColor,
          title: Text(
            'Favoritos',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
            indicatorColor: AppTheme.accentGreen,
            tabs: const [
              Tab(text: 'Produtos'),
              Tab(text: 'Empresas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFavoriteServicesTab(),
            _buildFavoriteBusinessesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteServicesTab() {
    return StreamBuilder<List<String>>(
      stream: FavoritesService().getFavoriteServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final favIds = snapshot.data ?? [];

        if (favIds.isEmpty) {
          return Center(
            child: Text(
              'Você não tem produtos favoritos.',
              style: TextStyle(color: context.textSecondary),
            ),
          );
        }

        return FutureBuilder<List<ServiceAds>>(
          future: _fetchServices(favIds),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final services = futureSnapshot.data ?? [];

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                return _buildProductCard(context, services[index]);
              },
            );
          },
        );
      },
    );
  }

  Future<List<ServiceAds>> _fetchServices(List<String> ids) async {
    List<ServiceAds> results = [];
    // Firestore whereIn has a limit of 10. For scalability, we fetch chunks.
    final db = FirebaseFirestore.instance;
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final querySnapshot = await db.collection('service_ads').where(FieldPath.documentId, whereIn: chunk).get();
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('id')) data['id'] = doc.id;
        final ad = ServiceAds.fromMap(data);
        if (ad.isAvailable) {
          results.add(ad);
        }
      }
    }
    return results;
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
            // Imagem
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${ad.price.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
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

  Widget _buildFavoriteBusinessesTab() {
    return StreamBuilder<List<String>>(
      stream: FavoritesService().getFavoriteBusinesses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final favIds = snapshot.data ?? [];

        if (favIds.isEmpty) {
          return Center(
            child: Text(
              'Você não tem empresas favoritas.',
              style: TextStyle(color: context.textSecondary),
            ),
          );
        }

        return FutureBuilder<List<Business>>(
          future: _fetchBusinesses(favIds),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final businesses = futureSnapshot.data ?? [];

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: businesses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildBusinessCard(context, businesses[index]);
              },
            );
          },
        );
      },
    );
  }

  Future<List<Business>> _fetchBusinesses(List<String> ids) async {
    List<Business> results = [];
    final db = FirebaseFirestore.instance;
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final querySnapshot = await db.collection('businesses').where(FieldPath.documentId, whereIn: chunk).get();
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('id')) data['id'] = doc.id;
        results.add(Business.fromMap(data));
      }
    }
    return results;
  }

  Widget _buildBusinessCard(BuildContext context, Business business) {
    final hasLogo = business.logo.isNotEmpty;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessProfileScreen(businessDetails: business.toDetails()),
          ),
        );
      },
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
                image: hasLogo
                    ? DecorationImage(image: NetworkImage(business.logo), fit: BoxFit.cover)
                    : null,
              ),
              child: !hasLogo
                  ? const Icon(Icons.storefront_rounded, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: context.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          business.region,
                          style: TextStyle(color: context.textSecondary, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.primaryColor),
          ],
        ),
      ),
    );
  }
}
