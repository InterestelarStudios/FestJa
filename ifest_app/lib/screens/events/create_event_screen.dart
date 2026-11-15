import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ifest_app/models/event.dart';
import 'package:ifest_app/models/user.dart';
import 'package:ifest_app/services/event_service.dart';
import 'package:ifest_app/theme/app_theme.dart';
import 'package:ifest_app/screens/marketplace/map_selection_screen.dart';

class CreateEventScreen extends StatefulWidget {
  final Event? eventToEdit;
  const CreateEventScreen({super.key, this.eventToEdit});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedPeopleRange;
  final List<String> _peopleRanges = [
    '0-10', '10-20', '20-50', '50-100', '100-200', '200-500', '+500'
  ];
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _imageFile;
  final List<String> _selectedCategories = [];
  bool _isLoading = false;
  bool _noLocationDefined = false;
  String _region = '';
  GeoPoint? _geoPoint;

  final List<String> _availableCategories = [
    'Casamento', 'Aniversário', 'Formatura', 'Confraternização', 'Infantil', 'Outros'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final ev = widget.eventToEdit!;
      _titleController.text = ev.title;
      _descriptionController.text = ev.description ?? '';
      _addressController.text = ev.address ?? '';
      _region = ev.region ?? '';
      _geoPoint = ev.geoPoint;
      if (ev.address == null && ev.region == null) {
        _noLocationDefined = true;
      }
      _selectedPeopleRange = ev.people?.toString();
      _selectedDate = ev.date.toDate();
      _selectedTime = TimeOfDay(hour: _selectedDate!.hour, minute: _selectedDate!.minute);
      _selectedCategories.addAll(ev.categories.map((e) => e.toString()));
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
    Future.delayed(Duration.zero, () {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
    Future.delayed(Duration.zero, () {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  Future<void> _openMapSelection() async {
    FocusScope.of(context).unfocus();
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
        _region = result.region;
        _addressController.text = result.address;
      });
    }

    Future.delayed(Duration.zero, () {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione a data do evento')));
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione o horário de início')));
      return;
    }
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione pelo menos uma categoria')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      // Fetch user details from firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      UserDetails owner;
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        owner = UserDetails(
          id: data['id'] ?? user.uid,
          username: data['username'] ?? user.displayName ?? 'Usuário',
          image: data['image'] ?? user.photoURL ?? '',
        );
      } else {
        owner = UserDetails(
          id: user.uid,
          username: user.displayName ?? 'Usuário',
          image: user.photoURL ?? '',
        );
      }

      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final newEvent = Event(
        id: widget.eventToEdit?.id ?? '', // Generated by service if empty
        title: _titleController.text,
        categories: _selectedCategories,
        date: Timestamp.fromDate(eventDateTime),
        owner: owner,
        created: widget.eventToEdit?.created ?? Timestamp.now(),
        people: _selectedPeopleRange ?? '0-10',
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        address: (!_noLocationDefined && _addressController.text.isNotEmpty) ? _addressController.text : null,
        region: (!_noLocationDefined && _region.isNotEmpty) ? _region : null,
        geoPoint: !_noLocationDefined ? _geoPoint : null,
        image: widget.eventToEdit?.image, // Keep existing image if not replacing
      );

      if (widget.eventToEdit != null) {
        await EventService().updateEvent(newEvent, _imageFile);
      } else {
        await EventService().createEvent(newEvent, _imageFile);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento criado com sucesso!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
        title: Text(widget.eventToEdit != null ? 'Editar Evento' : 'Criar Evento'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F26),
                          borderRadius: BorderRadius.circular(16),
                          image: _imageFile != null
                              ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                              : null,
                          border: Border.all(color: const Color(0xFF282F3B)),
                        ),
                        child: _imageFile == null && widget.eventToEdit?.image == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.white54),
                                  SizedBox(height: 8),
                                  Text('Adicionar Capa', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                                ],
                              )
                            : (_imageFile == null && widget.eventToEdit?.image != null)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(widget.eventToEdit!.image!, fit: BoxFit.cover, width: double.infinity),
                                  )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Evento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 400,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                              ),
                              child: Text(
                                _selectedDate == null
                                    ? 'Selecionar'
                                    : '${_selectedDate!.day.toString().padLeft(2,'0')}/${_selectedDate!.month.toString().padLeft(2,'0')}/${_selectedDate!.year}',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _pickTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Horário',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time_rounded),
                              ),
                              child: Text(
                                _selectedTime == null
                                    ? 'Selecionar'
                                    : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Convidados (Guests)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPeopleRange,
                      decoration: const InputDecoration(
                        labelText: 'Estimativa de Convidados',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                      isExpanded: true,
                      items: _peopleRanges.map((range) {
                        return DropdownMenuItem<String>(
                          value: range,
                          child: Text(range),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPeopleRange = value;
                        });
                      },
                      validator: (value) => value == null ? 'Obg' : null,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      readOnly: true,
                      enabled: !_noLocationDefined,
                      onTap: _noLocationDefined ? null : _openMapSelection,
                      decoration: const InputDecoration(
                        labelText: 'Endereço (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _noLocationDefined,
                            activeColor: context.primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _noLocationDefined = value ?? false;
                                if (_noLocationDefined) {
                                  _addressController.clear();
                                  _geoPoint = null;
                                  _region = '';
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Ainda não defini o local',
                          style: TextStyle(fontSize: 14, color: context.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Categories
                    const Text('Categorias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableCategories.map((cat) {
                        final isSelected = _selectedCategories.contains(cat);
                        return FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(cat);
                              } else {
                                _selectedCategories.remove(cat);
                              }
                            });
                          },
                          selectedColor: context.primaryColor.withValues(alpha: 0.2),
                          checkmarkColor: context.primaryColor,
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Salvar Evento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
    );
  }
}
