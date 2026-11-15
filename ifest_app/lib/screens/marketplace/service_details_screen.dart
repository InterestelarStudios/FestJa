import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_app/models/service_ads.dart';
import 'package:ifest_app/theme/app_theme.dart';
import 'package:ifest_app/screens/marketplace/business_profile_screen.dart';
import 'package:ifest_app/screens/chat/chat_room_screen.dart';
import 'package:ifest_app/services/chat_service.dart';
import 'package:ifest_app/services/favorites_service.dart';
import 'package:ifest_app/services/cart_service.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final ServiceAds serviceAd;

  const ServiceDetailsScreen({super.key, required this.serviceAd});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: _buildBody(),
              ),
            ],
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final hasImages = widget.serviceAd.images.isNotEmpty;
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: context.backgroundColor,
      elevation: 0,
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.3),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
              onSelected: _handleMenuOption,
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Compartilhar'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report_problem_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Relatar Problema'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'flag',
                  child: Row(
                    children: [
                      Icon(Icons.flag_rounded, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Denunciar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: hasImages
            ? Stack(
                children: [
                  PageView.builder(
                    itemCount: widget.serviceAd.images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.serviceAd.images[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  if (widget.serviceAd.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.serviceAd.images.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == index ? 12 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? context.tertiaryColor
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.image_not_supported_rounded, size: 64, color: Colors.grey),
                ),
              ),
      ),
    );
  }

  void _handleMenuOption(String option) {
    String message = '';
    if (option == 'share') {
      message = 'Link copiado para compartilhar!';
    } else if (option == 'report') {
      message = 'Obrigado por relatar o problema. Analisaremos em breve.';
    } else if (option == 'flag') {
      message = 'Anúncio denunciado. Obrigado pelo feedback!';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.primaryColor,
        ),
      );
    }
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBody() {
    return Container(
      color: context.backgroundColor,
      padding: const EdgeInsets.only(top: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.serviceAd.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.serviceAd.categories.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.serviceAd.categories.map((cat) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: context.secondaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: context.secondaryColor.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                cat.toString(),
                                style: TextStyle(
                                  color: context.secondaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                StreamBuilder<bool>(
                  stream: FavoritesService().isServiceFavorite(widget.serviceAd.id),
                  builder: (context, snapshot) {
                    final isFav = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? Colors.redAccent : context.primaryColor,
                        size: 26,
                      ),
                      onPressed: () {
                        FavoritesService().toggleFavoriteService(widget.serviceAd.id, !isFav);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // 1. Description of the Service
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Descrição do Serviço',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.serviceAd.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Venue Location (if specified on the ad)
          if (widget.serviceAd.address != null && widget.serviceAd.address!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place_rounded, color: context.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Endereço do Espaço / Local',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.serviceAd.address!,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.serviceAd.region.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.serviceAd.region,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Venue Amenities (if specified on the ad)
          if (widget.serviceAd.amenities.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.deck_rounded, color: context.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'O que este espaço oferece',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.serviceAd.amenities.map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.primaryColor.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getAmenityIcon(amenity),
                              size: 16,
                              color: context.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              amenity,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 2. Business Provider Information
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prestador do Serviço',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BusinessProfileScreen(businessDetails: widget.serviceAd.business),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                        child: Icon(Icons.storefront_rounded, color: context.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.serviceAd.business.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 12, color: context.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.serviceAd.business.region,
                                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    final Map<String, List<VariantOption>> localSelectedOptions = {};
    for (final variant in widget.serviceAd.variants) {
      localSelectedOptions[variant.name] = [];
    }
    int localQuantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isOptionSelected(String variantName, String optionName) {
              final list = localSelectedOptions[variantName] ?? [];
              return list.any((opt) => opt.name == optionName);
            }

            void toggleOption(ProductVariant variant, VariantOption option) {
              setModalState(() {
                final list = localSelectedOptions[variant.name] ?? [];
                if (variant.isMultiSelect) {
                  final index = list.indexWhere((opt) => opt.name == option.name);
                  if (index >= 0) {
                    list.removeAt(index);
                  } else {
                    list.add(option);
                  }
                } else {
                  list.clear();
                  list.add(option);
                }
                localSelectedOptions[variant.name] = list;
              });
            }

            double getUnitPrice() {
              double base = widget.serviceAd.price.toDouble();
              double adjustments = 0;
              localSelectedOptions.forEach((varName, opts) {
                for (final opt in opts) {
                  adjustments += opt.priceAdjustment.toDouble();
                }
              });
              return base + adjustments;
            }

            double getTotalPrice() => getUnitPrice() * localQuantity;

            bool validateSelections() {
              for (final variant in widget.serviceAd.variants) {
                if (variant.isRequired) {
                  final list = localSelectedOptions[variant.name] ?? [];
                  if (list.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Por favor, selecione uma opção para "${variant.name}"'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return false;
                  }
                }
              }
              return true;
            }

            List<SelectedVariantOption> buildSelectedOptionsForCart() {
              final List<SelectedVariantOption> list = [];
              localSelectedOptions.forEach((varName, opts) {
                for (final opt in opts) {
                  list.add(SelectedVariantOption(
                    variantName: varName,
                    optionName: opt.name,
                    priceAdjustment: opt.priceAdjustment.toDouble(),
                  ));
                }
              });
              return list;
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Opções do Serviço',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          children: [
                            ...widget.serviceAd.variants.map((variant) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        variant.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (variant.isRequired)
                                        const Text(
                                          ' *',
                                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                        ),
                                      if (!variant.isRequired)
                                        Text(
                                          ' (Opcional)',
                                          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 11),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...variant.options.map((opt) {
                                    final isSelected = isOptionSelected(variant.name, opt.name);
                                    final isAvailable = opt.isAvailable;

                                    return GestureDetector(
                                      onTap: isAvailable ? () => toggleOption(variant, opt) : null,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: !isAvailable
                                              ? Colors.grey.withValues(alpha: 0.05)
                                              : (isSelected
                                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                                                  : Theme.of(context).cardColor),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: !isAvailable
                                                ? Colors.grey.shade300
                                                : (isSelected
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              variant.isMultiSelect
                                                  ? (isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                                                  : (isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                                              color: !isAvailable
                                                  ? Colors.grey.shade400
                                                  : (isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                opt.name + (isAvailable ? '' : ' (Indisponível)'),
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  fontSize: 13,
                                                  color: isAvailable ? null : Colors.grey.shade500,
                                                  decoration: isAvailable ? null : TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              opt.priceAdjustment > 0
                                                  ? '+ R\$ ${opt.priceAdjustment.toStringAsFixed(2).replaceAll('.', ',')}'
                                                  : 'Grátis',
                                              style: TextStyle(
                                                color: !isAvailable
                                                    ? Colors.grey.shade400
                                                    : (opt.priceAdjustment > 0 ? Theme.of(context).colorScheme.primary : Colors.grey),
                                                fontWeight: opt.priceAdjustment > 0 ? FontWeight.bold : FontWeight.normal,
                                                fontSize: 12,
                                                decoration: isAvailable ? null : TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 12),
                                ],
                              );
                            }),

                            if (widget.serviceAd.allowMultiple) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Quantidade',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove, size: 18, color: Theme.of(context).colorScheme.primary),
                                          onPressed: () {
                                            if (localQuantity > 1) {
                                              setModalState(() => localQuantity--);
                                            }
                                          },
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            localQuantity.toString(),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.primary),
                                          onPressed: () {
                                            setModalState(() => localQuantity++);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Valor Total',
                                      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                                    ),
                                    Text(
                                      'R\$ ${getTotalPrice().toStringAsFixed(2).replaceAll('.', ',')}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (!validateSelections()) return;
                                    try {
                                      await CartService().addToCart(
                                        widget.serviceAd,
                                        buildSelectedOptionsForCart(),
                                        localQuantity,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Item adicionado ao carrinho!')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Erro: $e')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Iconsax.shopping_cart),
                                  label: const Text(
                                    'Adicionar',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final hasVariantsOrQty = widget.serviceAd.variants.isNotEmpty || widget.serviceAd.allowMultiple;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valor Total',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                    Text(
                      'R\$ ${widget.serviceAd.price.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Chat inquiry button
              Container(
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  border: Border.all(
                    color: context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Faça login para conversar com o fornecedor'),
                        ),
                      );
                      return;
                    }
                    final chat = await ChatService().getOrCreateInquiryChat(
                      serviceId: widget.serviceAd.id,
                      serviceTitle: widget.serviceAd.title,
                      serviceImage: widget.serviceAd.images.isNotEmpty
                          ? widget.serviceAd.images.first
                          : '',
                      servicePrice: widget.serviceAd.price.toDouble(),
                      businessId: widget.serviceAd.business.id,
                      businessName: widget.serviceAd.business.name,
                      clientId: user.uid,
                      clientName: user.displayName ?? 'Cliente',
                      clientPhone: user.phoneNumber ?? '',
                    );
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomScreen(chat: chat),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    Iconsax.message_text,
                    color: context.secondaryColor,
                  ),
                  tooltip: 'Tirar dúvidas com o fornecedor',
                ),
              ),
              Expanded(
                flex: 3,
                child: hasVariantsOrQty
                    ? ElevatedButton.icon(
                        onPressed: () => _showOptionsBottomSheet(context),
                        icon: const Icon(Iconsax.shopping_cart),
                        label: const Text(
                          'Adicionar',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )
                    : StreamBuilder<List<CartItem>>(
                        stream: CartService().getCartItems(),
                        builder: (context, snapshot) {
                          final cartItems = snapshot.data ?? [];
                          final inCart = cartItems.any((item) => item.serviceAdId == widget.serviceAd.id);

                          return ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                if (inCart) {
                                  final item = cartItems.firstWhere((item) => item.serviceAdId == widget.serviceAd.id);
                                  await CartService().removeFromCart(item.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Item removido do carrinho')),
                                    );
                                  }
                                } else {
                                  await CartService().addToCart(
                                    widget.serviceAd,
                                    [],
                                    1,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Item adicionado ao carrinho!')),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erro: $e')),
                                  );
                                }
                              }
                            },
                            icon: Icon(inCart ? Icons.check_rounded : Iconsax.shopping_cart),
                            label: Text(
                              inCart ? 'Adicionado' : 'Adicionar',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: inCart ? Colors.green : context.primaryColor,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity) {
      case 'Piscina':
        return Icons.pool_rounded;
      case 'Churrasqueira':
        return Icons.outdoor_grill_rounded;
      case 'Palco / Pista de Dança':
        return Icons.mic_external_on_rounded;
      case 'Ar-Condicionado / Climatização':
        return Icons.ac_unit_rounded;
      case 'Estacionamento Próprio':
        return Icons.local_parking_rounded;
      case 'Cozinha Completa / Buffet':
        return Icons.kitchen_rounded;
      case 'Wi-Fi Liberado':
        return Icons.wifi_rounded;
      case 'Área Kids / Playground':
        return Icons.child_care_rounded;
      case 'Campo de Futebol / Quadra':
        return Icons.sports_soccer_rounded;
      case 'Acessibilidade (PCD)':
        return Icons.accessible_rounded;
      case 'Gerador de Energia':
        return Icons.bolt_rounded;
      case 'Som e Luz Básicos':
        return Icons.speaker_group_rounded;
      case 'Mesas e Cadeiras Inclusas':
        return Icons.table_restaurant_rounded;
      case 'Suítes / Quartos (Hospedagem)':
        return Icons.bed_rounded;
      case 'Área Verde / Jardim para Cerimônias':
        return Icons.park_rounded;
      case 'Camarim / Sala da Noiva':
        return Icons.face_retouching_natural_rounded;
      case 'Forno de Pizza / Fogão a Lenha':
        return Icons.local_pizza_rounded;
      case 'Portaria / Segurança':
        return Icons.security_rounded;
      case 'Permitido Som Alto':
        return Icons.volume_up_rounded;
      case 'Espaço Coberto e Aberto':
        return Icons.roofing_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }
}
