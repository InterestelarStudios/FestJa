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
import 'package:ifest_business/models/user.dart';
import 'package:ifest_business/theme/app_theme.dart';
import 'package:ifest_business/screens/business/map_selection_screen.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  final Usuario usuario;
  const BusinessRegistrationScreen({super.key, required this.usuario});

  @override
  State<BusinessRegistrationScreen> createState() =>
      _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState
    extends State<BusinessRegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Step 1
  String _type = 'Prestador de Serviço';
  final List<String> _selectedCategories = [];

  final List<String> _typeOptions = [
    'Prestador de Serviço',
    'Local/Espaço',
    'Fornecedor de Produtos',
  ];
  final List<String> _categoryOptions = [
    'Organização e Planejamento',
    'Espaços e Ambientes',
    'Alimentos e Bebidas',
    'Doces e Confeitaria',
    'Decoração e Cenografia',
    'Música e Atrações',
    'Fotografia e Vídeo',
    'Estrutura e Equipamentos',
    'Vestuário e Beleza',
  ];

  // Step 2
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  GeoPoint? _geoPoint;

  // Step 3
  final TextEditingController _nameController = TextEditingController();
  File? _logoImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _regionController.dispose();
    _addressController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
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
        List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final city = place.subAdministrativeArea ?? place.locality ?? place.administrativeArea ?? '';
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openMapSelection() async {
    final result = await Navigator.push<MapSelectionResult>(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          initialLocation: _geoPoint,
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

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logoImage = File(image.path);
      });
    }
  }

  Future<void> _submitBusiness() async {
    if (!_formKey3.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('businesses').doc();
      
      String logoUrl = "";
      if (_logoImage != null) {
        try {
          final storageRef = FirebaseStorage.instance.ref().child('businesses/logos/${docRef.id}.jpg');
          await storageRef.putFile(_logoImage!);
          logoUrl = await storageRef.getDownloadURL();
        } catch (e) {
          debugPrint("Error uploading logo: $e");
        }
      }

      final business = Business(
        id: docRef.id,
        name: _nameController.text.trim(),
        logo: logoUrl,
        region: _regionController.text.trim(),
        type: _type,
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        images: [],
        creator: widget.usuario.toDetails(),
        categories: _selectedCategories,
        geoPoint: _geoPoint ?? const GeoPoint(0, 0),
        created: Timestamp.now(),
      );

      await docRef.set(business.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sua empresa foi cadastrada com sucesso no iFest!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao cadastrar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextPage(GlobalKey<FormState> key) {
    if (key.currentState!.validate()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Empresa'),
        backgroundColor: AppTheme.backgroundLight,
      ),
      body: Column(
        children: [
          // Linear Progress Indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / 3,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.secondaryPurple,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Passo 1: Segmento',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Qual é o tipo e a categoria do seu negócio?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo de Negócio'),
              items: _typeOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _type = val!),
            ),
            const SizedBox(height: 16),
            Text(
              'Categorias Principais (Máx 3)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            FormField<List<String>>(
              initialValue: _selectedCategories,
              validator: (val) => _selectedCategories.isEmpty
                  ? 'Selecione pelo menos uma categoria'
                  : null,
              builder: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categoryOptions.map((c) {
                        final isSelected = _selectedCategories.contains(c);
                        return FilterChip(
                          label: Text(c, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          selectedColor: AppTheme.secondaryPurple.withValues(alpha: 0.2),
                          checkmarkColor: AppTheme.secondaryPurple,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (_selectedCategories.length < 3) {
                                  _selectedCategories.add(c);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Você pode selecionar no máximo 3 categorias.'),
                                    ),
                                  );
                                }
                              } else {
                                _selectedCategories.remove(c);
                              }
                              state.didChange(_selectedCategories);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          state.errorText!,
                          style: TextStyle(color: Colors.red[700], fontSize: 12),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _nextPage(_formKey1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Próximo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Passo 2: Localização',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Onde sua empresa atende?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _regionController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Região de Atendimento',
                hintText: 'Preenchido automaticamente',
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Informe a região através do mapa ou GPS' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Endereço Comercial (Opcional)',
                hintText: 'Rua, Número, Bairro',
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryDark.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Localização no Mapa',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _geoPoint == null
                        ? 'Nenhuma localização definida.'
                        : 'Coordenadas salvas: ${_geoPoint!.latitude.toStringAsFixed(4)}, ${_geoPoint!.longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _getLocation,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location_rounded, size: 20),
                          label: const Text('GPS Atual', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _openMapSelection,
                          icon: const Icon(Icons.map_outlined, size: 20),
                          label: const Text('Abrir Mapa', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryDark,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('Voltar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _nextPage(_formKey2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('Próximo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Passo 3: Detalhes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Informações públicas da empresa',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryDark.withValues(alpha: 0.2),
                    ),
                    image: _logoImage != null
                        ? DecorationImage(
                            image: FileImage(_logoImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _logoImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: AppTheme.primaryDark),
                            SizedBox(height: 4),
                            Text('Logo', style: TextStyle(fontSize: 12, color: AppTheme.primaryDark)),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Nome da Empresa / Profissional',
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Nome é obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Descrição do Serviço (Opcional)',
                hintText: 'Descreva o que você oferece...',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TelefoneInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Telefone para Contato (Opcional)',
                hintText: '(11) 99999-9999',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email de Contato (Opcional)',
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return null;
                if (!val.contains('@') || !val.contains('.')) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website / Instagram (Opcional)',
              ),
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('Voltar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitBusiness,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Finalizar Cadastro'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
