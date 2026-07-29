
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_app/models/user.dart';
import 'package:ifest_app/services/auth_service.dart';
import 'package:ifest_app/theme/app_theme.dart';
import 'package:ifest_app/screens/profile/favorites_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Usuario? usuario;
  
  const ProfileScreen({super.key, this.usuario});

  @override
  Widget build(BuildContext context) {
    final displayName = usuario?.username ?? 'Usuário iFest';
    final email = usuario?.email ?? 'Sem email cadastrado';
    final photoUrl = (usuario != null && usuario!.image.isNotEmpty) ? usuario!.image : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        automaticallyImplyLeading: false,
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
                    backgroundColor: AppTheme.primaryDark.withValues(alpha: 0.1),
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 56,
                            color: AppTheme.primaryDark,
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
                          color: AppTheme.textSecondary,
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
            _buildOptionItem(
              context,
              icon: Icons.person_outline_rounded,
              title: 'Detalhes da Conta',
              onTap: () {},
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
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
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
        leading: Icon(icon, color: AppTheme.primaryDark),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textMuted),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
