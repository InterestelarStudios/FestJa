import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:ifest_business/models/business.dart';
import 'package:ifest_business/models/service_ads.dart';
import 'package:ifest_business/screens/business/map_selection_screen.dart';
import 'package:ifest_business/theme/app_theme.dart';

class ServiceRegistrationScreen extends StatefulWidget {
  final Business business;
  final ServiceAds? adToEdit;
  
  const ServiceRegistrationScreen({
    super.key,
    required this.business,
    this.adToEdit,
  });

  @override
  State<ServiceRegistrationScreen> createState() => _ServiceRegistrationScreenState();
}

class _ServiceRegistrationScreenState extends State<ServiceRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLocating = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _loadingStatus = 'Preparando seu anúncio...';
  String _loadingDetail = 'Validando dados preenchidos';
  double _loadingProgress = 0.15;
  int _loadingStep = 1;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Location for Venues (Local/Espaço)
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  GeoPoint? _geoPoint;
  
  final List<String> _selectedCategories = [];
  final List<String> _selectedAmenities = [];
  final List<File> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  List<ProductVariant> _variants = [];
  bool _allowMultiple = false;
  bool _isAvailable = true;

  bool get _isVenue =>
      widget.business.type == 'Local/Espaço' ||
      widget.business.type.toLowerCase().contains('local') ||
      widget.business.type.toLowerCase().contains('espaço');

  bool get _isMusician =>
      widget.business.type == 'Músico e Grupos Musicais' ||
      widget.business.type.toLowerCase().contains('músic') ||
      widget.business.type.toLowerCase().contains('music');

  List<String> get _categoryOptions {
    if (_isVenue) {
      return const [
        'Salão de Festas Clássico',
        'Sítios, Chácaras e Fazendas',
        'Espaços ao Ar Livre',
        'Restaurantes e Bistrôs',
        'Rooftops e Terraços',
        'Hotéis, Pousadas e Resorts',
        'Casas de Shows e Arenas',
        'Clubes Sociais e Esportivos',
        'Mansões e Residências',
        'Espaços Minimalistas / Galpões',
      ];
    } else if (_isMusician) {
      return const [
        'DJ para Festas e Baladas',
        'Banda de Casamento / Baile',
        'Grupo Musical de Cerimônia',
        'Artista Solo / Cantor',
        'Duplas Sertanejas / Acústicas',
        'Grupo de Pagode / Samba',
        'Banda de Rock / Pop',
        'Orquestras e Big Bands',
        'Coral e Madrigais',
        'Grupo de Jazz, Blues e Bossa Nova',
        'Instrumentistas (Violinista, Saxofonista, etc.)',
      ];
    } else if (widget.business.type == 'Fornecedor de Produtos') {
      return const [
        'Buffet Completo',
        'Buffet de Finger Foods',
        'Bebidas Finitas (Consignado)',
        'Cervejas Artesanais e Chopp',
        'Doces Finos e Gourmet',
        'Bolo Artístico (Wedding Cake)',
        'Lembrancinhas Personalizadas',
        'Convites e Papelaria Fina',
        'Som e Pistas de Dança',
        'Iluminação Cênica e Laser',
        'Mobiliário para Eventos',
        'Painéis de LED e Projeção',
        'Louças e Utensílios de Mesa',
        'Geradores de Energia',
        'Brinquedos e Infláveis',
        'Efeitos Especiais (Sparkles/Fumaça)',
      ];
    } else {
      return const [
        'Organização e Cerimonial',
        'Fotografia',
        'Filmagem e Videomaker',
        'Decoração e Cenografia',
        'Design Floral',
        'Recepção e Assessoria',
        'Segurança e Portaria',
        'Limpeza e Apoio',
        'Equipe de Bar e Bartenders',
        'Garçons e Copeiros',
        'Recreação Infantil',
        'Animação e Personagens',
        'Maquiagem e Cabelo (Beauty)',
        'Alfaiataria e Vestidos',
        'Coreógrafos e Dançarinos',
        'Valet e Estacionamento',
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.adToEdit != null) {
      final ad = widget.adToEdit!;
      _titleController.text = ad.title;
      _descController.text = ad.description;
      _priceController.text = UtilBrasilFields.obterReal(ad.price.toDouble());
      _selectedCategories.addAll(ad.categories.map((c) => c.toString()));
      _selectedAmenities.addAll(ad.amenities);
      _existingImageUrls.addAll(ad.images.map((img) => img.toString()));
      _allowMultiple = (_isVenue || _isMusician) ? false : ad.allowMultiple;
      _isAvailable = ad.isAvailable;
      _addressController.text = ad.address ?? widget.business.address ?? '';
      _regionController.text = ad.region.isNotEmpty ? ad.region : widget.business.region;
      _geoPoint = ad.geoPoint;
      
      // Perform deep copy of variants including isAvailable state
      _variants = List.from(ad.variants.map((v) => ProductVariant(
        name: v.name,
        isMultiSelect: v.isMultiSelect,
        isRequired: v.isRequired,
        options: List.from(v.options.map((o) => VariantOption(
          name: o.name,
          priceAdjustment: o.priceAdjustment,
          isAvailable: o.isAvailable,
        ))),
      )));
    } else {
      _allowMultiple = false;
      _addressController.text = widget.business.address ?? '';
      _regionController.text = widget.business.region;
      _geoPoint = widget.business.geoPoint;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Permissão de localização negada permanentemente.");
      }
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _geoPoint = GeoPoint(position.latitude, position.longitude);
      });

      try {
        List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
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

          final street = place.street ?? place.thoroughfare ?? '';
          final num = place.subThoroughfare ?? '';
          final neighborhood = place.subLocality ?? '';

          String addrStr = '$street, $num - $neighborhood'.trim();
          if (addrStr.startsWith(',')) addrStr = addrStr.substring(1).trim();

          setState(() {
            _regionController.text = regionStr;
            _addressController.text = addrStr;
          });
        }
      } catch (e) {
        debugPrint("Error reverse geocoding location: $e");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Localização obtida com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter localização: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openMapSelection() async {
    final result = await Navigator.push<MapSelectionResult>(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          initialLocation: _geoPoint ?? widget.business.geoPoint,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _geoPoint = result.geoPoint;
        if (result.region.isNotEmpty) _regionController.text = result.region;
        if (result.address.isNotEmpty) _addressController.text = result.address;
      });
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 75,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((x) => File(x.path)));
      });
    }
  }
  
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _addNewVariant() {
    setState(() {
      _variants.add(ProductVariant(
        name: '',
        isMultiSelect: false,
        isRequired: false,
        options: [],
      ));
    });
  }

  List<Widget> _buildVariantsList() {
    final List<Widget> list = [];
    for (int i = 0; i < _variants.length; i++) {
      final variant = _variants[i];
      list.add(
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.primaryColor.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: variant.name,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Nome da Variação (ex: Tamanho)',
                        isDense: true,
                        filled: true,
                        fillColor: context.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.primaryColor.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.primaryColor.withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.primaryColor, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        variant.name = val.trim();
                      },
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Nome da variação é obrigatório' : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        _variants.removeAt(i);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Múltipla Escolha', style: TextStyle(fontSize: 13)),
                      value: variant.isMultiSelect,
                      onChanged: (val) {
                        setState(() {
                          variant.isMultiSelect = val ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Obrigatório', style: TextStyle(fontSize: 13)),
                      value: variant.isRequired,
                      onChanged: (val) {
                        setState(() {
                          variant.isRequired = val ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Opções da Variação',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ..._buildVariantOptions(variant, i),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    variant.options.add(VariantOption(name: '', priceAdjustment: 0, isAvailable: true));
                  });
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Adicionar Opção', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: context.primaryColor,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return list;
  }

  List<Widget> _buildVariantOptions(ProductVariant variant, int variantIndex) {
    final List<Widget> list = [];
    for (int j = 0; j < variant.options.length; j++) {
      final option = variant.options[j];
      list.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: option.name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Opção (ex: Médio)',
                    isDense: true,
                    filled: true,
                    fillColor: context.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primaryColor.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primaryColor.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primaryColor, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    option.name = val.trim();
                  },
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Obrigatório' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: option.priceAdjustment == 0
                      ? ''
                      : option.priceAdjustment.toStringAsFixed(2),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Acréscimo R\$',
                    hintText: '0.00',
                    isDense: true,
                    filled: true,
                    fillColor: context.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primaryColor.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primaryColor.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primaryColor, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    final cleanVal = val.replaceAll(',', '.');
                    option.priceAdjustment = num.tryParse(cleanVal) ?? 0;
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  option.isAvailable ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                  color: option.isAvailable ? Colors.green : Colors.grey,
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    option.isAvailable = !option.isAvailable;
                  });
                },
                tooltip: option.isAvailable ? 'Opção Ativa' : 'Opção Pausada',
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                onPressed: () {
                  setState(() {
                    variant.options.removeAt(j);
                  });
                },
              ),
            ],
          ),
        ),
      );
    }
    return list;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isVenue && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o endereço do local.')),
      );
      return;
    }
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos uma categoria.')),
      );
      return;
    }
    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos uma imagem.')),
      );
      return;
    }

    // Validate that variants have options
    for (final variant in _variants) {
      if (variant.options.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A variação "${variant.name}" precisa ter ao menos uma opção.')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _loadingStep = 1;
      _loadingProgress = 0.15;
      _loadingStatus = _isVenue
          ? 'Preparando estrutura do seu espaço...'
          : (_isMusician
              ? 'Preparando detalhes da sua apresentação...'
              : 'Preparando dados do anúncio...');
      _loadingDetail = 'Validando informações e variações';
    });

    try {
      final bool isEdit = widget.adToEdit != null;
      final docId = isEdit ? widget.adToEdit!.id : FirebaseFirestore.instance.collection('service_ads').doc().id;
      
      // Upload New Images
      List<String> uploadedUrls = [];
      if (_selectedImages.isNotEmpty) {
        setState(() {
          _loadingStep = 2;
          _loadingDetail = 'Fazendo upload seguro das imagens';
        });

        for (int i = 0; i < _selectedImages.length; i++) {
          final file = _selectedImages[i];
          final uniqueStamp = DateTime.now().millisecondsSinceEpoch;
          setState(() {
            _loadingStatus = 'Enviando foto ${i + 1} de ${_selectedImages.length}...';
            _loadingProgress = 0.2 + (0.6 * ((i + 1) / _selectedImages.length));
          });
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('services/$docId/img_${uniqueStamp}_$i.jpg');
          await storageRef.putFile(file);
          final url = await storageRef.getDownloadURL();
          uploadedUrls.add(url);
        }
      } else {
        setState(() {
          _loadingStep = 2;
          _loadingProgress = 0.75;
          _loadingStatus = 'Processando imagens...';
          _loadingDetail = 'Mantendo imagens já cadastradas';
        });
      }

      setState(() {
        _loadingStep = 3;
        _loadingProgress = 0.88;
        _loadingStatus = _isVenue
            ? 'Salvando localização e catálogo do espaço...'
            : (_isMusician
                ? 'Registrando repertório e detalhes musicais...'
                : 'Salvando anúncio no catálogo...');
        _loadingDetail = 'Gravando no FestJá!';
      });

      // Combine existing images that were kept and newly uploaded images
      final List<String> allImages = [..._existingImageUrls, ...uploadedUrls];

      // Convert Price
      final priceString = _priceController.text;
      final double price = UtilBrasilFields.converterMoedaParaDouble(priceString);

      final ad = ServiceAds(
        id: docId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        categories: _selectedCategories,
        images: allImages,
        price: price,
        business: widget.business.toDetails(),
        creted: isEdit ? widget.adToEdit!.creted : Timestamp.now(),
        region: (_isVenue && _regionController.text.trim().isNotEmpty)
            ? _regionController.text.trim()
            : widget.business.region,
        geoPoint: (_isVenue && _geoPoint != null)
            ? _geoPoint!
            : widget.business.geoPoint,
        variants: _variants,
        allowMultiple: (_isVenue || _isMusician) ? false : _allowMultiple,
        isAvailable: _isAvailable,
        address: _isVenue && _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        amenities: _isVenue ? _selectedAmenities : const [],
      );

      await FirebaseFirestore.instance.collection('service_ads').doc(docId).set(ad.toMap());

      setState(() {
        _loadingStep = 4;
        _loadingProgress = 1.0;
        _loadingStatus = 'Anúncio publicado com sucesso!';
        _loadingDetail = 'Concluído';
      });
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Anúncio atualizado com sucesso!' : 'Anúncio cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildVenueLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place_rounded, color: context.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Localização do Espaço',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Informe o endereço exato onde o espaço para eventos está localizado.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Endereço do Local *',
              hintText: 'Ex: Estrada das Flores, 1200 - Chácara Paraíso',
              prefixIcon: Icon(Icons.home_work_outlined),
            ),
            validator: (val) {
              if (_isVenue && (val == null || val.trim().isEmpty)) {
                return 'Informe o endereço do espaço';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regionController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Região / Cidade',
              hintText: 'Preenchido via GPS ou Mapa',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _geoPoint == null
                ? 'Coordenadas: Usando localização padrão da empresa'
                : 'Coordenadas no mapa: ${_geoPoint!.latitude.toStringAsFixed(4)}, ${_geoPoint!.longitude.toStringAsFixed(4)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textSecondary,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLocating ? null : _getLocation,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text('GPS Atual', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.primaryColor,
                    side: BorderSide(color: context.primaryColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openMapSelection,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Abrir Mapa', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const List<String> _venueAmenitiesOptions = [
    'Piscina',
    'Churrasqueira',
    'Palco / Pista de Dança',
    'Ar-Condicionado / Climatização',
    'Estacionamento Próprio',
    'Cozinha Completa / Buffet',
    'Wi-Fi Liberado',
    'Área Kids / Playground',
    'Campo de Futebol / Quadra',
    'Acessibilidade (PCD)',
    'Gerador de Energia',
    'Som e Luz Básicos',
    'Mesas e Cadeiras Inclusas',
    'Suítes / Quartos (Hospedagem)',
    'Área Verde / Jardim para Cerimônias',
    'Camarim / Sala da Noiva',
    'Forno de Pizza / Fogão a Lenha',
    'Portaria / Segurança',
    'Permitido Som Alto',
    'Espaço Coberto e Aberto',
  ];

  static IconData getAmenityIcon(String amenity) {
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

  Widget _buildVenueAmenitiesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.deck_rounded, color: context.primaryColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Comodidades e Infraestrutura do Espaço',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Selecione o que seu espaço oferece (piscina, palco, churrasqueira, etc.):',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _venueAmenitiesOptions.map((amenity) {
              final isSelected = _selectedAmenities.contains(amenity);
              return FilterChip(
                label: Text(amenity),
                selected: isSelected,
                avatar: Icon(
                  getAmenityIcon(amenity),
                  size: 16,
                  color: isSelected ? context.secondaryColor : context.primaryColor,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAmenities.add(amenity);
                    } else {
                      _selectedAmenities.remove(amenity);
                    }
                  });
                },
                selectedColor: context.secondaryColor.withValues(alpha: 0.2),
                checkmarkColor: context.secondaryColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.adToEdit != null;

    // Dynamic Title & Labels based on business type
    String appBarTitle;
    String titleLabel;
    String titleHint;
    String descLabel;
    String descHint;
    String priceLabel;
    String variantSectionTitle;
    String variantSectionDesc;
    String addVariantLabel;
    String submitButtonText;

    if (_isVenue) {
      appBarTitle = isEdit ? 'Editar Espaço / Local' : 'Novo Espaço / Local';
      titleLabel = 'Nome do Espaço / Local';
      titleHint = 'Ex: Chácara Recanto Verde, Salão Nobre Cristal';
      descLabel = 'Descrição do Local e Estrutura';
      descHint = 'Capacidade máxima de pessoas, piscina, churrasqueira, quartos, regras, estacionamento...';
      priceLabel = 'Preço da Diária / Período (R\$)';
      variantSectionTitle = 'Adicionais e Variações do Espaço';
      variantSectionDesc = 'Adicione opções como horas adicionais de permanência, taxa de limpeza, suítes extras, etc.';
      addVariantLabel = 'Adicionar Adicional / Variação';
      submitButtonText = isEdit ? 'Salvar Alterações' : 'Publicar Espaço';
    } else if (_isMusician) {
      appBarTitle = isEdit ? 'Editar Anúncio Musical' : 'Novo Anúncio Musical';
      titleLabel = 'Título da Apresentação / Show';
      titleHint = 'Ex: Show Acústico Voz e Violão (3h), DJ Completo com Pista';
      descLabel = 'Descrição da Apresentação e Repertório';
      descHint = 'Gêneros musicais tocados, duração padrão, estrutura inclusa (som/luz), membros da banda...';
      priceLabel = 'Valor do Cachê / Show (R\$)';
      variantSectionTitle = 'Opções e Adicionais do Show';
      variantSectionDesc = 'Adicione variações como hora extra de apresentação, equipamento extra de som ou luz, etc.';
      addVariantLabel = 'Adicionar Adicional / Variação';
      submitButtonText = isEdit ? 'Salvar Alterações' : 'Publicar Anúncio Musical';
    } else {
      appBarTitle = isEdit ? 'Editar Anúncio' : 'Novo Anúncio';
      titleLabel = 'Título do Produto/Serviço';
      titleHint = 'Ex: Pacote de Decoração Neon';
      descLabel = 'Descrição Completa';
      descHint = 'Detalhe o que está incluso no pacote...';
      priceLabel = 'Preço (R\$)';
      variantSectionTitle = 'Variações do Serviço';
      variantSectionDesc = 'Adicione variações como tamanhos, cores ou adicionais opcionais.';
      addVariantLabel = 'Adicionar Variação';
      submitButtonText = isEdit ? 'Salvar Alterações' : 'Anunciar Serviço';
    }

    return PopScope(
      canPop: !_isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aguarde a conclusão do envio antes de sair.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: _isLoading
            ? null
            : AppBar(
                title: Text(appBarTitle),
              ),
        body: _isLoading
            ? _buildLoadingScreen(isEdit)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 60,
                        decoration: InputDecoration(
                          labelText: titleLabel,
                          hintText: titleHint,
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 500,
                        decoration: InputDecoration(
                          labelText: descLabel,
                          hintText: descHint,
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CentavosInputFormatter(moeda: true),
                        ],
                        decoration: InputDecoration(
                          labelText: priceLabel,
                          hintText: 'R\$ 0,00',
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Campo obrigatório';
                          final double price = UtilBrasilFields.converterMoedaParaDouble(val);
                          if (price <= 0) return 'O valor deve ser maior que zero';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Venue Location section
                      if (_isVenue) ...[
                        _buildVenueLocationSection(),
                        const SizedBox(height: 24),
                      ],

                      Text(
                        _isVenue ? 'Tipo de Espaço / Características (Máx 3)' : (_isMusician ? 'Estilo / Gênero Musical (Máx 3)' : 'Categorias / Tags (Máx 3)'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categoryOptions.map((cat) {
                          final isSelected = _selectedCategories.contains(cat);
                          return FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  if (_selectedCategories.length < 3) {
                                    _selectedCategories.add(cat);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Máximo de 3 categorias')),
                                    );
                                  }
                                } else {
                                  _selectedCategories.remove(cat);
                                }
                              });
                            },
                            selectedColor: context.secondaryColor.withValues(alpha: 0.2),
                            checkmarkColor: context.secondaryColor,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Venue Amenities section
                      if (_isVenue) ...[
                        _buildVenueAmenitiesSection(),
                        const SizedBox(height: 24),
                      ],

                      // Availability switch
                      SwitchListTile(
                        title: const Text('Anúncio Ativo / Disponível no Marketplace'),
                        value: _isAvailable,
                        onChanged: (val) {
                          setState(() {
                            _isAvailable = val;
                          });
                        },
                        activeTrackColor: context.secondaryColor.withValues(alpha: 0.5),
                        activeThumbColor: context.secondaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),

                      // Quantity switch (hidden for venues and musicians)
                      if (!_isVenue && !_isMusician) ...[
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Permitir selecionar quantidade no carrinho'),
                          value: _allowMultiple,
                          onChanged: (val) {
                            setState(() {
                              _allowMultiple = val;
                            });
                          },
                          activeTrackColor: context.secondaryColor.withValues(alpha: 0.5),
                          activeThumbColor: context.secondaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],

                      const SizedBox(height: 24),
                      // Variants Section
                      Text(
                        variantSectionTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        variantSectionDesc,
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ..._buildVariantsList(),
                      OutlinedButton.icon(
                        onPressed: _addNewVariant,
                        icon: const Icon(Icons.add),
                        label: Text(addVariantLabel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.primaryColor,
                          side: BorderSide(color: context.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          submitButtonText,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingScreen(bool isEdit) {
    final String mainTitle = _isVenue
        ? (isEdit ? 'Atualizando seu Espaço' : 'Publicando seu Espaço')
        : (_isMusician
            ? (isEdit ? 'Atualizando seu Show' : 'Lançando Anúncio Musical')
            : (isEdit ? 'Atualizando seu Anúncio' : 'Publicando no FestJá!'));

    final IconData mainIcon = _isVenue
        ? Icons.holiday_village_rounded
        : (_isMusician ? Icons.music_note_rounded : Icons.celebration_rounded);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Glowing pulsing icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        context.primaryColor,
                        context.secondaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 4,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    mainIcon,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Main Title
              Text(
                mainTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Dynamic Status
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _loadingStatus,
                  key: ValueKey<String>(_loadingStatus),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Linear Progress Indicator with percentage
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: context.isDarkMode ? 0.3 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _loadingProgress,
                        minHeight: 10,
                        backgroundColor: context.primaryColor.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _loadingDetail,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(_loadingProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stepper Checklist Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildLoadingStepTile(
                      stepNumber: 1,
                      title: 'Validação e Detalhes',
                      subtitle: 'Conferindo dados e valores preenchidos',
                      isDone: _loadingStep > 1,
                      isActive: _loadingStep == 1,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 14,
                          child: VerticalDivider(thickness: 1.5, width: 1),
                        ),
                      ),
                    ),
                    _buildLoadingStepTile(
                      stepNumber: 2,
                      title: 'Upload das Fotos',
                      subtitle: _selectedImages.isEmpty
                          ? 'Mantendo fotos já existentes do anúncio'
                          : 'Enviando ${_selectedImages.length} foto(s) em alta resolução',
                      isDone: _loadingStep > 2,
                      isActive: _loadingStep == 2,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 14,
                          child: VerticalDivider(thickness: 1.5, width: 1),
                        ),
                      ),
                    ),
                    _buildLoadingStepTile(
                      stepNumber: 3,
                      title: 'Publicação no Catálogo',
                      subtitle: _isVenue
                          ? 'Registrando localização e regras do espaço'
                          : (_isMusician
                              ? 'Disponibilizando show no FestJá!'
                              : 'Anúncio pronto para receber pedidos'),
                      isDone: _loadingStep > 3,
                      isActive: _loadingStep == 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Security note footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_clock_rounded,
                    size: 16,
                    color: context.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Por favor, não saia do aplicativo durante o upload.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStepTile({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
  }) {
    Widget leadingWidget;
    if (isDone) {
      leadingWidget = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
      );
    } else if (isActive) {
      leadingWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: context.primaryColor, width: 2),
        ),
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            ),
          ),
        ),
      );
    } else {
      leadingWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$stepNumber',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        leadingWidget,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
                  color: isActive
                      ? context.primaryColor
                      : (isDone ? (context.isDarkMode ? Colors.white : Colors.black87) : Colors.grey),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final int totalImageCount = _selectedImages.length + _existingImageUrls.length;
    final String photoTitle = _isVenue
        ? 'Fotos do Espaço'
        : (_isMusician ? 'Fotos do Show / Apresentação' : 'Fotos do Serviço/Produto');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          photoTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Adicione até 5 fotos para o seu anúncio.',
          style: TextStyle(color: context.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: totalImageCount >= 5 ? null : _pickImages,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: totalImageCount >= 5
                        ? (context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)
                        : context.secondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: totalImageCount >= 5
                          ? (context.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300)
                          : context.secondaryColor.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: totalImageCount >= 5
                        ? (context.isDarkMode ? Colors.white38 : Colors.grey)
                        : context.secondaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ...List.generate(_existingImageUrls.length, (index) {
                final url = _existingImageUrls[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _existingImageUrls.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              ...List.generate(_selectedImages.length, (index) {
                final file = _selectedImages[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          file,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
