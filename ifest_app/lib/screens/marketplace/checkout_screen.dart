import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:ifest_app/models/event.dart';
import 'package:ifest_app/models/user_data.dart';
import 'package:ifest_app/services/cart_service.dart';
import 'package:ifest_app/services/order_service.dart';
import 'package:ifest_app/screens/events/create_event_screen.dart';
import 'package:ifest_app/screens/profile/customer_data_screen.dart';
import 'package:ifest_app/screens/marketplace/order_success_screen.dart';
import 'package:ifest_app/theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _orderService = OrderService();

  bool _isLoading = false;
  bool _isLoadingData = true;

  // Selected Event
  Event? _selectedEvent;
  List<Event> _userEvents = [];

  // Customer Data State
  UserData? _userData;

  // Payment Options
  String _paymentMethod = 'pix'; // 'pix' or 'credit_card'
  int _selectedInstallment = 1;

  // Credit Card Controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // 1. Load User Data
      final savedData = await _orderService.getUserData();

      // 2. Load User Events
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('owner.id', isEqualTo: uid)
          .get();

      final events = eventsSnapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('id')) data['id'] = doc.id;
        return Event.fromMap(data);
      }).toList();

      setState(() {
        _userData = savedData;
        _userEvents = events;
        if (events.isNotEmpty) {
          _selectedEvent = events.first;
        }
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _navigateToCustomerDataScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerDataScreen()),
    );
    // Reload updated data
    final updated = await _orderService.getUserData();
    setState(() {
      _userData = updated;
    });
  }

  Future<void> _processCheckout() async {
    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione ou crie um evento de destino.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_userData == null || _userData!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha seus dados pessoais antes de finalizar o pedido.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      await _navigateToCustomerDataScreen();
      return;
    }

    if (_paymentMethod == 'credit_card') {
      if (_cardNumberController.text.trim().isEmpty ||
          _cardHolderController.text.trim().isEmpty ||
          _cardExpiryController.text.trim().isEmpty ||
          _cardCvvController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preencha todos os dados do cartão de crédito.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final orderId = await _orderService.createOrder(
        customerData: _userData!,
        event: _selectedEvent!,
        items: widget.items,
        totalAmount: widget.totalAmount,
        paymentMethod: _paymentMethod,
        installments: _selectedInstallment,
        saveCustomerInfo: true,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(
              orderId: orderId,
              event: _selectedEvent!,
              totalAmount: widget.totalAmount,
              paymentMethod: _paymentMethod,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar pedido: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCardContainer({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Finalizar Pedido')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEventSelectionCard(),
                _buildCustomerDataCard(),
                _buildPaymentMethodCard(),
                _buildOrderSummaryCard(),
              ],
            ),
          ),
          _buildBottomConfirmation(),
        ],
      ),
    );
  }

  Widget _buildEventSelectionCard() {
    return _buildCardContainer(
      title: '1. Destino do Pedido (Vincular ao Evento)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_userEvents.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.info_circle, color: context.primaryColor),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Você ainda não possui eventos cadastrados. Crie um evento para vincular este pedido.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateEventScreen()),
                );
                _loadInitialData();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar Novo Evento'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.primaryColor,
                side: BorderSide(color: context.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] else ...[
            DropdownButtonFormField<Event>(
              initialValue: _selectedEvent,
              decoration: InputDecoration(
                labelText: 'Selecione o Evento',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Iconsax.calendar_1),
              ),
              items: _userEvents.map((event) {
                final date = event.date.toDate();
                final formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                return DropdownMenuItem<Event>(
                  value: event,
                  child: Text('${event.title} ($formattedDate)', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (event) {
                setState(() => _selectedEvent = event);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateEventScreen()),
                  );
                  _loadInitialData();
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Adicionar outro evento', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerDataCard() {
    final isFilled = _userData != null && _userData!.isNotEmpty;

    return _buildCardContainer(
      title: '2. Dados do Comprador (Mercado Pago)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isFilled ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: isFilled ? Colors.green : Colors.orangeAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFilled ? 'Dados Cadastrados' : 'Dados Pendentes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isFilled ? Colors.green : Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _navigateToCustomerDataScreen,
                icon: Icon(isFilled ? Icons.edit_rounded : Icons.add_circle_outline_rounded, size: 16),
                label: Text(isFilled ? 'Alterar' : 'Preencher', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isFilled) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.primaryColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userData!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CPF: ${_userData!.cpf} • Celular: ${_userData!.phone}',
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData!.formattedAddress,
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Cadastre seus dados pessoais (CPF, celular e endereço) para compras seguras e proteção antifraude.',
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToCustomerDataScreen,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Cadastrar Dados Pessoais'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                  foregroundColor: context.primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return _buildCardContainer(
      title: '3. Forma de Pagamento',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _paymentMethod = 'pix'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 'pix'
                          ? context.primaryColor.withValues(alpha: 0.1)
                          : context.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentMethod == 'pix'
                            ? context.primaryColor
                            : context.primaryColor.withValues(alpha: 0.1),
                        width: _paymentMethod == 'pix' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.qr_code_2_rounded,
                            color: _paymentMethod == 'pix' ? context.primaryColor : Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          'Pix',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _paymentMethod == 'pix' ? context.primaryColor : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _paymentMethod = 'credit_card'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 'credit_card'
                          ? context.primaryColor.withValues(alpha: 0.1)
                          : context.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentMethod == 'credit_card'
                            ? context.primaryColor
                            : context.primaryColor.withValues(alpha: 0.1),
                        width: _paymentMethod == 'credit_card' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.credit_card_rounded,
                            color: _paymentMethod == 'credit_card' ? context.primaryColor : Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          'Cartão de Crédito',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _paymentMethod == 'credit_card' ? context.primaryColor : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_paymentMethod == 'pix') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pagamento instantâneo via Pix com compensação imediata e proteção Mercado Pago.',
                      style: TextStyle(fontSize: 13, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            TextFormField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CartaoBancarioInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Número do Cartão *',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cardHolderController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Nome Impresso no Cartão *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cardExpiryController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ValidadeCartaoInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Validade (MM/AA) *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cardCvvController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'CVV *',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _selectedInstallment,
              decoration: InputDecoration(
                labelText: 'Parcelamento (Mercado Pago)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: List.generate(12, (index) {
                final installment = index + 1;
                final installmentValue = widget.totalAmount / installment;
                return DropdownMenuItem<int>(
                  value: installment,
                  child: Text(
                    '$installment x de R\$ ${installmentValue.toStringAsFixed(2).replaceAll('.', ',')} sem juros',
                  ),
                );
              }),
              onChanged: (val) {
                if (val != null) setState(() => _selectedInstallment = val);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return _buildCardContainer(
      title: 'Resumo do Pedido',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...widget.items.map((item) {
            final summary = item.selectedOptionsSummary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.quantity}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (summary.isNotEmpty)
                          Text(summary, style: TextStyle(color: context.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(
                    'R\$ ${(item.finalPrice * item.quantity).toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryColor),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                'R\$ ${widget.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Ambiente 100% Seguro • Mercado Pago',
                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomConfirmation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          child: ElevatedButton(
            onPressed: _isLoading ? null : _processCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Confirmar Pedido',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
