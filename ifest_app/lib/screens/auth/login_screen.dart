import 'package:flutter/material.dart';
import 'package:ifest_app/theme/app_theme.dart';
import 'package:ifest_app/screens/auth/phone_auth_screen.dart';
import 'package:ifest_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleLoading = false;
  final AuthService _authService = AuthService();

  void _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });
    try {
      await _authService.signInWithGoogle();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao entrar com Google.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              image: DecorationImage(
                image: AssetImage("assets/auth1.jpg"),
                fit: BoxFit.cover,
                opacity: 0.2,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                // Back Button
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
                // Header Area (Logo/Branding)
                Expanded(
                  flex: 4,
                  child: SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: const Icon(
                              Icons.celebration_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'iFest',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tudo para a sua festa.',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Login Options Card
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: const BoxDecoration(
                      color: AppTheme.cardLight,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Entrar',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selecione a forma de acesso para continuar',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Phone Login Button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PhoneAuthScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.phone_iphone_rounded),
                          label: const Text('Entrar com Telefone'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryDark,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Google Login Button
                        OutlinedButton.icon(
                          onPressed: _isGoogleLoading
                              ? null
                              : _handleGoogleSignIn,
                          icon: _isGoogleLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Image.network(
                                  'https://developers.google.com/identity/images/g-logo.png',
                                  height: 24,
                                ),
                          label: Text(
                            _isGoogleLoading
                                ? 'Entrando...'
                                : 'Entrar com Google',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(
                              color: Colors.black12,
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Facebook Login Button (Disabled/Placeholder for now)
                        OutlinedButton.icon(
                          onPressed: null, // Disabled
                          icon: const Icon(
                            Icons.facebook_rounded,
                            color: Colors.blue,
                          ),
                          label: const Text('Entrar com Facebook (Em breve)'),
                          style: OutlinedButton.styleFrom(
                            disabledForegroundColor: Colors.grey,
                            side: const BorderSide(
                              color: Colors.black12,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
