import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ifest_app/theme/app_theme.dart';
import 'package:ifest_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nenhum usuário encontrado com este e-mail.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado em outra conta.';
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      case 'weak-password':
        return 'A senha deve conter pelo menos 6 caracteres.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas sem sucesso. Tente novamente mais tarde.';
      default:
        return e.message ?? 'Ocorreu um erro na autenticação.';
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isLogin) {
        await _authService.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _authService.registerWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getFirebaseAuthErrorMessage(e)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _handleForgotPassword() {
    final emailResetController =
        TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: context.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Recuperar Senha'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informe seu e-mail cadastrado para enviarmos um link de redefinição de senha.',
                    style: TextStyle(color: context.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailResetController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: context.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: context.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = emailResetController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Informe um e-mail válido.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSending = true);
                          try {
                            await _authService.sendPasswordResetEmail(email);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'E-mail de recuperação enviado! Verifique sua caixa de entrada.',
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSending = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Falha ao enviar e-mail: $e'),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          // Header Background Gradient
          Container(
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
              image: DecorationImage(
                image: AssetImage("assets/auth1.jpg"),
                fit: BoxFit.cover,
                opacity: 0.2,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Bar with Close Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),

                          // Header Branding (Centered vertically between top and Card)
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(13),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                      child: const Icon(
                                        Icons.celebration_rounded,
                                        size: 42,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Fest'Ja",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Tudo para a sua festa.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.white70,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Card with Email & Password Form and Secondary Social Logins (Snug to bottom)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(36),
                                topRight: Radius.circular(36),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, -6),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.fromLTRB(
                              24,
                              22,
                              24,
                              28 + MediaQuery.of(context).padding.bottom,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Toggle Login / Register (Flicker-Free with high contrast)
                                  _buildModeToggle(isDark),
                                  const SizedBox(height: 18),

                                  // Name Field (Only on Register - Smooth CrossFade)
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: Padding(
                                      padding: const EdgeInsets.only(bottom: 14.0),
                                      child: TextFormField(
                                        controller: _nameController,
                                        textCapitalization: TextCapitalization.words,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Seu Nome Completo',
                                          labelStyle: TextStyle(
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                          ),
                                          hintText: 'Ex: Maria Silva',
                                          hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white30
                                                : Colors.black26,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.person_outline_rounded,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                          ),
                                          filled: true,
                                          fillColor: isDark
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFF8FAFC),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: isDark
                                                  ? const Color(0xFF334155)
                                                  : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: isDark
                                                  ? const Color(0xFF334155)
                                                  : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: isDark
                                                  ? const Color(0xFF9D4EDD)
                                                  : const Color(0xFF7209B7),
                                              width: 1.8,
                                            ),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (!_isLogin &&
                                              (value == null ||
                                                  value.trim().isEmpty)) {
                                            return 'Informe seu nome';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    crossFadeState: _isLogin
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                    duration: const Duration(milliseconds: 220),
                                  ),

                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'E-mail',
                                      labelStyle: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                      hintText: 'seuemail@exemplo.com',
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white30
                                            : Colors.black26,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF9D4EDD)
                                              : const Color(0xFF7209B7),
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Informe seu e-mail';
                                      }
                                      if (!value.contains('@') ||
                                          !value.contains('.')) {
                                        return 'Informe um e-mail válido';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Senha',
                                      labelStyle: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF9D4EDD)
                                              : const Color(0xFF7209B7),
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Informe sua senha';
                                      }
                                      if (value.length < 6) {
                                        return 'A senha deve ter pelo menos 6 caracteres';
                                      }
                                      return null;
                                    },
                                  ),

                                  // Forgot Password (Only on Login - Smooth CrossFade)
                                  AnimatedCrossFade(
                                    firstChild: Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: TextButton(
                                          onPressed: _handleForgotPassword,
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            'Esqueceu a senha?',
                                            style: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFFC084FC)
                                                  : const Color(0xFF7209B7),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    secondChild: const SizedBox.shrink(),
                                    crossFadeState: _isLogin
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                    duration: const Duration(milliseconds: 200),
                                  ),
                                  const SizedBox(height: 16),

                                  // Primary Submit Button
                                  ElevatedButton(
                                    onPressed: _isSubmitting ? null : _handleSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? const Color(0xFF7209B7)
                                          : const Color(0xFF0D1B2A),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: isDark
                                          ? const Color(0xFF7209B7).withValues(alpha: 0.5)
                                          : const Color(0xFF0D1B2A).withValues(alpha: 0.5),
                                      disabledForegroundColor: Colors.white70,
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: isDark ? 0 : 2,
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            _isLogin
                                                ? 'Entrar na Conta'
                                                : 'Criar Minha Conta',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(bool isDark) {
    final activeBgColor = isDark ? const Color(0xFF7209B7) : const Color(0xFF0D1B2A);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (!_isLogin) {
                    setState(() => _isLogin = true);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isLogin ? activeBgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isLogin
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Entrar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: _isLogin
                          ? Colors.white
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_isLogin) {
                    setState(() => _isLogin = false);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !_isLogin ? activeBgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: !_isLogin
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Cadastrar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: !_isLogin
                          ? Colors.white
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
