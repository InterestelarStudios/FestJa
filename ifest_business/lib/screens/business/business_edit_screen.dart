import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:ifest_business/models/business.dart';
import 'package:ifest_business/theme/app_theme.dart';
import 'package:ifest_business/screens/business/map_selection_screen.dart';

class BusinessEditScreen extends StatefulWidget {
  final Business business;
  const BusinessEditScreen({super.key, required this.business});

  @override
  State<BusinessEditScreen> createState() => _BusinessEditScreenState();
}

class _BusinessEditScreenState extends State<BusinessEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _regionController;
  late final TextEditingController _addressController;

  File? _logoImage;
  final ImagePicker _picker = ImagePicker();
  GeoPoint? _geoPoint;
  final List<String> _selectedCategories = [];

  List<String> _getCategoryOptions(String type) {
    if (type == 'Local/Espaço') {
      return [
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
    } else if (type == 'Fornecedor de Produtos') {
      return [
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
    } else if (type == 'Músico e Grupos Musicais') {
      return [
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
    } else {
      return [
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
    final b = widget.business;
    _nameController = TextEditingController(text: b.name);
    _descController = TextEditingController(text: b.description ?? '');
    
    // Format phone if possible
    String formattedPhone = b.phone ?? '';
    if (formattedPhone.isNotEmpty && formattedPhone.length == 11) {
      formattedPhone = '(${formattedPhone.substring(0, 2)}) ${formattedPhone.substring(2, 7)}-${formattedPhone.substring(7)}';
    }
    _phoneController = TextEditingController(text: formattedPhone);
    
    _emailController = TextEditingController(text: b.email ?? '');
    _websiteController = TextEditingController(text: b.website ?? '');
    _regionController = TextEditingController(text: b.region);
    _addressController = TextEditingController(text: b.address ?? '');
    _geoPoint = b.geoPoint;
    _selectedCategories.addAll(b.categories.map((c) => c.toString()));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _regionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (image != null) {
      setState(() {
        _logoImage = File(image.path);
      });
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

  Future<void> _updateBusiness() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma categoria')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String logoUrl = widget.business.logo;
      if (_logoImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child('businesses/logos/${widget.business.id}.jpg');
        await storageRef.putFile(_logoImage!);
        logoUrl = await storageRef.getDownloadURL();
      }

      final cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

      final updatedData = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'phone': cleanPhone,
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'categories': _selectedCategories,
        'region': _regionController.text.trim(),
        'address': _addressController.text.trim(),
        'geoPoint': _geoPoint ?? widget.business.geoPoint,
        'logo': logoUrl,
      };

      await FirebaseFirestore.instance.collection('businesses').doc(widget.business.id).update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo Picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickLogo,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: context.secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: context.secondaryColor.withValues(alpha: 0.2),
                              width: 2,
                            ),
                            image: _logoImage != null
                                ? DecorationImage(
                                    image: FileImage(_logoImage!),
                                    fit: BoxFit.cover,
                                  )
                                : widget.business.logo.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(widget.business.logo),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: (_logoImage == null && widget.business.logo.isEmpty)
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_rounded, color: context.secondaryColor, size: 28),
                                    const SizedBox(height: 4),
                                    Text('Logo', style: TextStyle(fontSize: 12, color: context.secondaryColor, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: context.secondaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Empresa / Profissional',
                        prefixIcon: Icon(Icons.storefront_rounded),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Nome é obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Descrição do Serviço',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description_rounded),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Descrição é obrigatória' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _regionController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Região de Atendimento',
                              prefixIcon: Icon(Icons.location_on_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _openMapSelection,
                          icon: Icon(Icons.map_outlined, color: context.primaryColor),
                          tooltip: 'Escolher no mapa',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Endereço Comercial (Opcional)',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TelefoneInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Telefone para Contato',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Telefone é obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email de Contato',
                        prefixIcon: Icon(Icons.email_rounded),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email é obrigatório';
                        if (!val.contains('@') || !val.contains('.')) return 'Email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website / Instagram (Opcional)',
                        prefixIcon: Icon(Icons.language_rounded),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Categorias de Atuação (Máx 3)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getCategoryOptions(widget.business.type).map((c) {
                        final isSelected = _selectedCategories.contains(c);
                        return FilterChip(
                          label: Text(c, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          selectedColor: context.secondaryColor.withValues(alpha: 0.2),
                          checkmarkColor: context.secondaryColor,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (_selectedCategories.length < 3) {
                                  _selectedCategories.add(c);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Máximo de 3 categorias.')),
                                  );
                                }
                              } else {
                                _selectedCategories.remove(c);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 48),

                    ElevatedButton(
                      onPressed: _updateBusiness,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Salvar Alterações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
