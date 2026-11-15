import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_app/models/service_ads.dart';
import 'package:ifest_app/models/business.dart';
import 'package:ifest_app/screens/marketplace/business_profile_screen.dart';
import 'package:ifest_app/screens/marketplace/map_selection_screen.dart';
import 'package:ifest_app/theme/app_theme.dart';
import 'package:ifest_app/screens/marketplace/service_details_screen.dart';
import 'package:ifest_app/screens/marketplace/cart_screen.dart';
import 'package:ifest_app/services/cart_service.dart';

class MarketplaceScreen extends StatefulWidget {
  final String? region;
  final GeoPoint? geoPoint;
  final String? initialCategory;
  final VoidCallback? onLocationTap;

  const MarketplaceScreen({
    super.key,
    required this.region,
    required this.geoPoint,
    this.initialCategory,
    this.onLocationTap,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with AutomaticKeepAliveClientMixin {
  late String _selectedCategory;
  Stream<QuerySnapshot>? _productsStream;
  String? _region;
  GeoPoint? _geoPoint;
  bool _isLoadingLocation = false;
  bool _showAllRegions = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Todos';
    _region = widget.region;
    _geoPoint = widget.geoPoint;

    if (_region != null && _region!.trim().isNotEmpty) {
      _initStream();
    } else {
      _fetchDeviceLocation();
    }
  }

  @override
  void didUpdateWidget(MarketplaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.region != widget.region) {
      setState(() {
        _region = widget.region;
        _geoPoint = widget.geoPoint;
        if (_region != null && _region!.trim().isNotEmpty) {
          _showAllRegions = false;
        }
      });
      _initStream();
    }
  }

  Future<void> _fetchDeviceLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 5),
      );

      if (mounted) {
        _geoPoint = GeoPoint(position.latitude, position.longitude);
      }

      final placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.subAdministrativeArea ??
            place.locality ??
            place.administrativeArea ??
            '';
        final state = place.administrativeArea ?? '';

        String regionStr = '$city - $state'.trim();
        if (regionStr.startsWith('-')) regionStr = regionStr.substring(1).trim();

        if (mounted) {
          setState(() {
            _region = regionStr;
            _isLoadingLocation = false;
            _showAllRegions = false;
          });
          _initStream();
          return;
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar localização no Marketplace: $e');
    }

    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _handleLocationTap() async {
    if (widget.onLocationTap != null) {
      widget.onLocationTap!();
      return;
    }

    final result = await Navigator.push<MapSelectionResult>(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          initialLocation: _geoPoint,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _geoPoint = result.geoPoint;
        if (result.region.isNotEmpty) {
          _region = result.region;
          _showAllRegions = false;
        }
      });
      _initStream();
    }
  }

  void _initStream() {
    Query query = FirebaseFirestore.instance.collection('service_ads');

    if (!_showAllRegions && _region != null && _region!.trim().isNotEmpty) {
      query = query.where('region', isEqualTo: _region!.trim());
    }

    if (_selectedCategory != 'Todos') {
      query = query.where('categories', arrayContains: _selectedCategory);
    }

    setState(() {
      _productsStream = query.snapshots();
    });
  }

  Widget _buildTopCompaniesSection() {
    Query query = FirebaseFirestore.instance.collection('businesses');
    if (!_showAllRegions && _region != null && _region!.trim().isNotEmpty) {
      query = query.where('region', isEqualTo: _region!.trim());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final businesses = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (!data.containsKey('id')) data['id'] = doc.id;
          return Business.fromMap(data);
        }).toList();

        businesses.sort((a, b) => b.created.compareTo(a.created));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
              child: Text(
                'Top Empresas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 95,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: businesses.length,
                itemBuilder: (context, index) {
                  final biz = businesses[index];
                  final hasLogo = biz.logo.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessProfileScreen(
                              businessDetails: biz.toDetails(),
                            ),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 75,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.surfaceColor,
                                border: Border.all(
                                  color: context.primaryColor.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                                image: hasLogo
                                    ? DecorationImage(
                                        image: NetworkImage(biz.logo),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: !hasLogo
                                  ? Icon(
                                      Icons.business_rounded,
                                      color: context.primaryColor,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              biz.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  final List<String> _categoryOptions = [
    'Todos',
    'Local',
    'Decoração',
    'Atração',
    'Som e Iluminação',
    'Alimentação',
    'Bebidas',
    'Fotografia/Vídeo',
    'Equipe de Apoio',
    'Estrutura',
    'Outros',
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 60,
        leading: const SizedBox(width: 60),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Serviços',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: _handleLocationTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: context.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      (_region != null && _region!.trim().isNotEmpty)
                          ? _region!
                          : (_showAllRegions
                              ? 'Todas as regiões'
                              : 'Selecionar região'),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 16,
                    color: context.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.search_normal),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          StreamBuilder<List<CartItem>>(
            stream: CartService().getCartItems(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              final count = items.length;
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(count.toString()),
                  child: const Icon(Iconsax.shopping_cart),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 60),
        ],
      ),
      body: Column(
        children: [
          if (widget.region != null) _buildTopCompaniesSection(),
          // Filtros de Categoria
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categoryOptions.length,
              itemBuilder: (context, index) {
                final category = _categoryOptions[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategory = category;
                        _initStream();
                      });
                    },
                    selectedColor: context.primaryColor.withValues(alpha: 0.15),
                    checkmarkColor: context.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? context.primaryColor
                          : context.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Lista de Produtos
          Expanded(
            child: (!_showAllRegions && (_region == null || _region!.trim().isEmpty))
                ? _buildLocationRequiredState()
                : _buildProductsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar anúncios: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final ads = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (!data.containsKey('id')) data['id'] = doc.id;
          return ServiceAds.fromMap(data);
        }).where((ad) => ad.isAvailable).toList();

        if (ads.isEmpty) {
          return _buildEmptyState();
        }

        // Sort in memory to avoid needing a Firestore composite index!
        ads.sort((a, b) => b.creted.compareTo(a.creted));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: ads.length,
          itemBuilder: (context, index) {
            return _buildProductCard(ads[index]);
          },
        );
      },
    );
  }

  Widget _buildProductCard(ServiceAds ad) {
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: 12,
                        color: context.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ad.business.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box_search, size: 64, color: context.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Nenhum serviço encontrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _showAllRegions
                  ? 'Ainda não há anúncios disponíveis nesta categoria.'
                  : 'Ainda não há anúncios nesta categoria para a sua região.',
              style: TextStyle(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (!_showAllRegions) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showAllRegions = true;
                  });
                  _initStream();
                },
                icon: const Icon(Icons.public, size: 18),
                label: const Text('Ver anúncios de todas as regiões'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.primaryColor,
                  side: BorderSide(color: context.primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRequiredState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isLoadingLocation
                  ? Icons.location_searching_rounded
                  : Icons.location_off_rounded,
              size: 64,
              color: _isLoadingLocation ? context.primaryColor : context.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _isLoadingLocation
                  ? 'Buscando sua localização'
                  : 'Localização não identificada',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isLoadingLocation
                  ? 'Identificando sua região para listar fornecedores próximos...'
                  : 'Defina sua região no mapa ou visualize todos os fornecedores disponíveis.',
              style: TextStyle(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_isLoadingLocation) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleLocationTap,
                icon: const Icon(Iconsax.map_1, size: 20),
                label: const Text('Selecionar Cidade no Mapa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showAllRegions = true;
                  });
                  _initStream();
                },
                icon: const Icon(Icons.public, size: 20),
                label: const Text('Ver Todos os Serviços'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.primaryColor,
                  side: BorderSide(color: context.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (!_isLoadingLocation) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _fetchDeviceLocation,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tentar GPS novamente'),
                style: TextButton.styleFrom(
                  foregroundColor: context.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
