import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:brasil_fields/brasil_fields.dart';
import 'package:ifest_app/models/user_data.dart';
import 'package:ifest_app/services/order_service.dart';
import 'package:ifest_app/theme/app_theme.dart';

class CustomerDataScreen extends StatefulWidget {
  const CustomerDataScreen({super.key});

  @override
  State<CustomerDataScreen> createState() => _CustomerDataScreenState();
}

class _CustomerDataScreenState extends State<CustomerDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSearchingCep = false;

  final _numberFocusNode = FocusNode();

  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _numberFocusNode.dispose();
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final savedData = await _orderService.getUserData();
      if (savedData != null) {
        _nameController.text = savedData.name;
        _cpfController.text = savedData.cpf;
        _phoneController.text = savedData.phone;
        _cepController.text = savedData.cep;
        _streetController.text = savedData.street;
        _numberController.text = savedData.number;
        _complementController.text = savedData.complement;
        _neighborhoodController.text = savedData.neighborhood;
        _cityController.text = savedData.city;
        _stateController.text = savedData.state;
      }
    } catch (e) {
      // Ignored
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'\D'), '');
    if (cleanCep.length != 8) return;

    setState(() => _isSearchingCep = true);

    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (data.containsKey('erro') && (data['erro'] == true || data['erro'] == 'true')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CEP não encontrado. Por favor, verifique o número digitado.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } else {
          setState(() {
            _streetController.text = data['logradouro'] as String? ?? '';
            _neighborhoodController.text = data['bairro'] as String? ?? '';
            _cityController.text = data['localidade'] as String? ?? '';
            _stateController.text = data['uf'] as String? ?? '';
          });
          // Auto-focus number field for seamless UX
          _numberFocusNode.requestFocus();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao consultar CEP: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearchingCep = false);
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = UserData(
        name: _nameController.text.trim(),
        cpf: _cpfController.text.trim(),
        phone: _phoneController.text.trim(),
        cep: _cepController.text.trim(),
        street: _streetController.text.trim(),
        number: _numberController.text.trim(),
        complement: _complementController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
      );

      await _orderService.saveUserData(data);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados salvos com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar dados: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Dados Pessoais e Faturamento'),
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
                    Text(
                      'Identificação e Contato',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.primaryColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Necessários para autenticação segura no Mercado Pago.',
                      style: TextStyle(color: context.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nome Completo *',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nome é obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cpfController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CpfInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              labelText: 'CPF *',
                              hintText: '000.000.000-00',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'CPF é obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              TelefoneInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Celular (DDD) *',
                              hintText: '(00) 00000-0000',
                              prefixIcon: const Icon(Icons.phone_iphone_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Celular é obrigatório' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Endereço de Faturamento / Entrega',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.primaryColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Digite seu CEP para preencher o endereço automaticamente via ViaCEP.',
                      style: TextStyle(color: context.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CepInputFormatter(),
                      ],
                      onChanged: (val) {
                        if (val.replaceAll(RegExp(r'\D'), '').length == 8) {
                          _searchCep(val);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'CEP *',
                        hintText: '00000-000',
                        prefixIcon: const Icon(Icons.local_post_office_outlined),
                        suffixIcon: _isSearchingCep
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search_rounded),
                                onPressed: () => _searchCep(_cepController.text),
                                tooltip: 'Consultar CEP',
                              ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'CEP é obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _streetController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Logradouro / Rua (Automático)',
                        prefixIcon: const Icon(Icons.place_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Preencha um CEP válido para carregar a rua' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _numberController,
                            focusNode: _numberFocusNode,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: 'Número *',
                              hintText: '123',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _complementController,
                            decoration: InputDecoration(
                              labelText: 'Complemento',
                              hintText: 'Apto, Bloco (Opcional)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _neighborhoodController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Bairro',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cityController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Cidade',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _stateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'UF',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'UF' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Salvar Dados',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
