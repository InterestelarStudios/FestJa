import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_app/models/user.dart';
import 'package:ifest_app/models/user_data.dart';
import 'package:ifest_app/services/auth_service.dart';
import 'package:ifest_app/services/order_service.dart';
import 'package:ifest_app/theme/app_theme.dart';
import 'package:ifest_app/screens/profile/favorites_screen.dart';
import 'package:ifest_app/screens/profile/customer_data_screen.dart';
import 'package:ifest_app/screens/profile/widgets/account_security_dialogs.dart';

class ProfileScreen extends StatefulWidget {
  final Usuario? usuario;
  
  const ProfileScreen({super.key, this.usuario});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final displayName = widget.usuario?.username ?? "Usuário Fest'Ja";
    final email = widget.usuario?.email ?? 'Sem email cadastrado';
    final photoUrl = (widget.usuario != null && widget.usuario!.image.isNotEmpty) ? widget.usuario!.image : null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 60,
        leading: const SizedBox(width: 60),
        centerTitle: true,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [SizedBox(width: 60)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User profile header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Icon(
                            Icons.person_rounded,
                            size: 56,
                            color: context.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Settings options list
            _buildOptionItem(
              context,
              icon: Iconsax.heart,
              title: 'Meus Favoritos',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                );
              },
            ),
            FutureBuilder<UserData?>(
              future: OrderService().getUserData(),
              builder: (context, snapshot) {
                final isFilled = snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty;
                return _buildOptionItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Dados Pessoais (Mercado Pago)',
                  subtitle: isFilled ? 'Cadastrado • CPF e Endereço' : 'Pendente • Preencha seus dados',
                  trailingWidget: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isFilled ? Colors.green : Colors.orangeAccent).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isFilled ? 'Cadastrado' : 'Pendente',
                      style: TextStyle(
                        color: isFilled ? Colors.green : Colors.orangeAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomerDataScreen()),
                    );
                    setState(() {});
                  },
                );
              },
            ),
            _buildOptionItem(
              context,
              icon: Icons.alternate_email_rounded,
              title: 'Alterar E-mail',
              subtitle: 'Atualizar endereço de e-mail de acesso',
              onTap: () => AccountSecurityDialogs.showChangeEmailDialog(context),
            ),
            _buildOptionItem(
              context,
              icon: Icons.lock_reset_rounded,
              title: 'Alterar Senha',
              subtitle: 'Redefinir senha de acesso',
              onTap: () => AccountSecurityDialogs.showChangePasswordDialog(context),
            ),
            _buildOptionItem(
              context,
              icon: Icons.notifications_none_rounded,
              title: 'Notificações',
              onTap: () {},
            ),
            _buildOptionItem(
              context,
              icon: Icons.security_rounded,
              title: 'Privacidade e Segurança',
              onTap: () {},
            ),
            _buildOptionItem(
              context,
              icon: Icons.help_outline_rounded,
              title: 'Ajuda e Suporte',
              onTap: () {},
            ),
            _buildOptionItem(
              context,
              icon: Icons.delete_forever_rounded,
              iconColor: Colors.redAccent,
              textColor: Colors.redAccent,
              title: 'Excluir Minha Conta',
              subtitle: 'Exclusão definitiva e remoção de dados',
              onTap: () => AccountSecurityDialogs.showDeleteAccountDialog(context),
            ),
            
            const SizedBox(height: 40),
            
            // Sign out button
            OutlinedButton.icon(
              onPressed: () async {
                await AuthService().signOut();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair da Conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailingWidget,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? context.primaryColor),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: textColor?.withValues(alpha: 0.8) ?? context.textSecondary,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?trailingWidget,
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textColor ?? context.textMuted),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
