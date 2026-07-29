import 'package:flutter/material.dart';
import 'package:ifest_business/services/auth_service.dart';
import 'package:ifest_business/screens/auth/otp_verification_screen.dart';
import 'package:ifest_business/theme/app_theme.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  void _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Por favor, insira um número válido.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    await _authService.verifyPhoneNumber(
      // Make sure the format is E.164. User should type like +5511999999999
      phoneNumber: phone.startsWith('+') ? phone : '+55$phone',
      codeSent: (verificationId, resendToken) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              verificationId: verificationId,
              phoneNumber: phone,
            ),
          ),
        );
      },
      verificationFailed: (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message ?? 'Erro ao verificar o número.';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar com Telefone'),
        backgroundColor: AppTheme.backgroundLight,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Qual é o seu número?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Enviaremos um código SMS para verificar a sua conta.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '(DD) 90000-0000',
                prefixIcon: const Icon(Icons.phone_android),
                errorText: _errorMessage.isEmpty ? null : _errorMessage,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendCode,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Receber Código'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
