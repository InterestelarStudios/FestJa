import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifest_business/models/business.dart';
import 'package:ifest_business/models/service_ads.dart';
import 'package:ifest_business/theme/app_theme.dart';
import 'package:ifest_business/screens/business/service_registration_screen.dart';

class MyServicesScreen extends StatefulWidget {
  final Business business;

  const MyServicesScreen({super.key, required this.business});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen>
    with AutomaticKeepAliveClientMixin {
  late Stream<QuerySnapshot> _servicesStream;
  List<ServiceAds>? _cachedAds;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    _servicesStream = FirebaseFirestore.instance
        .collection('service_ads')
        .where('business.id', isEqualTo: widget.business.id)
        .orderBy('creted', descending: true)
        .snapshots();
  }

  @override
  void didUpdateWidget(MyServicesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business.id != widget.business.id) {
      _cachedAds = null;
      _initStream();
    }
  }

  void _confirmDeleteAd(BuildContext context, ServiceAds ad) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Navigator.of(context).canPop()
            ? AlertDialog(
                backgroundColor: context.surfaceColor,
                title: const Text('Excluir Anúncio'),
                content: Text(
                  'Tem certeza que deseja excluir "${ad.title}"? Esta ação não pode ser desfeita.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: context.textSecondary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext); // Close dialog
                      try {
                        await FirebaseFirestore.instance
                            .collection('service_ads')
                            .doc(ad.id)
                            .delete();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Anúncio excluído com sucesso!'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao excluir: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Excluir'),
                  ),
                ],
              )
            : Container();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Produtos/Serviços')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _servicesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            _cachedAds = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (!data.containsKey('id')) data['id'] = doc.id;
              return ServiceAds.fromMap(data);
            }).toList();
          }

          if (_cachedAds == null &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && _cachedAds == null) {
            return Center(
              child: Text(
                'Erro ao carregar anúncios.',
                style: TextStyle(color: Colors.red.shade400),
              ),
            );
          }

          final ads = _cachedAds ?? [];

          if (ads.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            key: const PageStorageKey<String>('my_services_list'),
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              return _buildAdCard(context, ads[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ServiceRegistrationScreen(business: widget.business),
            ),
          );
        },
        backgroundColor: context.primaryColor,
        heroTag: "newServiceAd",
        icon: Icon(
          Icons.add_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        label: Text(
          'Novo Anúncio',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: context.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Seu catálogo está vazio!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Comece a anunciar seus serviços ou produtos para os clientes do Fest\'Ja.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(BuildContext context, ServiceAds ad) {
    final hasImage = ad.images.isNotEmpty;
    final displayImage = hasImage ? ad.images.first : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: context.surfaceColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (bottomSheetContext) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.edit_rounded,
                          color: context.primaryColor,
                        ),
                        title: const Text('Editar Anúncio'),
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceRegistrationScreen(
                                business: widget.business,
                                adToEdit: ad,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          ad.isAvailable
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          color: ad.isAvailable
                              ? Colors.orangeAccent
                              : Colors.green,
                        ),
                        title: Text(
                          ad.isAvailable ? 'Pausar Anúncio' : 'Ativar Anúncio',
                        ),
                        onTap: () async {
                          Navigator.pop(bottomSheetContext);
                          try {
                            await FirebaseFirestore.instance
                                .collection('service_ads')
                                .doc(ad.id)
                                .update({'isAvailable': !ad.isAvailable});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ad.isAvailable
                                        ? 'Anúncio pausado com sucesso!'
                                        : 'Anúncio ativado com sucesso!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao atualizar: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_rounded,
                          color: Colors.redAccent,
                        ),
                        title: const Text('Excluir Anúncio'),
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _confirmDeleteAd(context, ad);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(19),
                  ),
                  color: context.isDarkMode
                      ? const Color(0xFF0F172A)
                      : Colors.grey.shade100,
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(displayImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasImage
                    ? Icon(
                        Icons.image_not_supported_rounded,
                        color: context.textMuted,
                        size: 32,
                      )
                    : null,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ad.description,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'R\$ ${ad.price.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: context.primaryColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ad.isAvailable
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ad.isAvailable
                                    ? Colors.green
                                    : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              ad.isAvailable ? 'Ativo' : 'Pausado',
                              style: TextStyle(
                                color: ad.isAvailable
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
