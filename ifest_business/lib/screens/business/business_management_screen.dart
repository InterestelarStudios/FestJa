import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_business/models/business.dart';
import 'package:ifest_business/theme/app_theme.dart';
import 'package:ifest_business/screens/business/business_edit_screen.dart';
import 'package:ifest_business/screens/business/my_services_screen.dart';
import 'package:ifest_business/screens/business/bookings_screen.dart';
import 'package:ifest_business/screens/business/reviews_screen.dart';
import 'package:ifest_business/screens/chat/chat_list_screen.dart';
import 'package:ifest_business/screens/notifications/notifications_screen.dart';
import 'package:ifest_business/services/chat_service.dart';
import 'package:ifest_business/services/notification_service.dart';
import 'package:ifest_business/screens/business/widgets/account_security_dialogs.dart';

class BusinessManagementScreen extends StatefulWidget {
  final Business business;

  const BusinessManagementScreen({super.key, required this.business});

  @override
  State<BusinessManagementScreen> createState() =>
      _BusinessManagementScreenState();
}

class _BusinessManagementScreenState extends State<BusinessManagementScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late Business _currentBusiness;
  late final PageController _pageController;
  late final AnimationController _fadeAnimationController;
  late final Animation<double> _fadeAnimation;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _currentBusiness = widget.business;
    _pageController = PageController(initialPage: _currentIndex);
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );
    NotificationService().currentBusiness = _currentBusiness;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      NotificationService().syncFcmToken(
        uid: user.uid,
        businessId: _currentBusiness.id,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) async {
    if (_currentIndex == index || _isTransitioning) return;
    _isTransitioning = true;
    try {
      await _fadeAnimationController.reverse();
      if (!mounted) return;
      _pageController.jumpToPage(index);
      setState(() {
        _currentIndex = index;
      });
      await _fadeAnimationController.forward();
    } finally {
      if (mounted) {
        _isTransitioning = false;
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: context.surfaceColor,
          title: const Text('Sair da Conta'),
          content: const Text(
            "Tem certeza que deseja sair do Fest'Ja Empresas?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: TextStyle(color: context.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await FirebaseAuth.instance.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time changes to the business document so that profile edits reflect instantly
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(_currentBusiness.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (!data.containsKey('id')) data['id'] = snapshot.data!.id;
          _currentBusiness = Business.fromMap(data);
        }

        return Scaffold(
          body: Stack(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    BusinessDashboardTab(business: _currentBusiness),
                    BookingsScreen(business: _currentBusiness),
                    MyServicesScreen(business: _currentBusiness),
                    BusinessSettingsTab(
                      business: _currentBusiness,
                      onLogout: _logout,
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: StreamBuilder<int>(
                      stream: NotificationService().streamBusinessUnreadCount(
                        _currentBusiness.id,
                      ),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BusinessNotificationsScreen(
                                      business: _currentBusiness,
                                    ),
                              ),
                            );
                          },
                          icon: unreadCount > 0
                              ? Badge.count(
                                  count: unreadCount,
                                  backgroundColor: context.secondaryColor,
                                  child: const Icon(Iconsax.notification),
                                )
                              : const Icon(Iconsax.notification),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: StreamBuilder<int>(
                      stream: ChatService().streamTotalUnreadCount(
                        _currentBusiness.id,
                      ),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatListScreen(business: _currentBusiness),
                              ),
                            );
                          },
                          icon: unreadCount > 0
                              ? Badge.count(
                                  count: unreadCount,
                                  backgroundColor: AppTheme.accentPink,
                                  child: const Icon(Iconsax.message),
                                )
                              : const Icon(Iconsax.message),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              onTap: _onTabTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Iconsax.home),
                  activeIcon: Icon(Iconsax.home_15),
                  label: 'Painel',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Iconsax.calendar),
                  activeIcon: Icon(Iconsax.calendar_tick5),
                  label: 'Pedidos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Iconsax.box),
                  activeIcon: Icon(Iconsax.box_1),
                  label: 'Serviços',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BusinessDashboardTab extends StatefulWidget {
  final Business business;

  const BusinessDashboardTab({super.key, required this.business});

  @override
  State<BusinessDashboardTab> createState() => _BusinessDashboardTabState();
}

class _BusinessDashboardTabState extends State<BusinessDashboardTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Painel de Gestão'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        key: const PageStorageKey<String>('dashboard_scroll'),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBusinessHeader(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            Text(
              'Ações Rápidas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildQuickActionCard(
              icon: Iconsax.edit,
              title: 'Editar Perfil Comercial',
              subtitle: 'Nome, descrição, localização e telefone',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BusinessEditScreen(business: widget.business),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildQuickActionCard(
              icon: Iconsax.add_circle,
              title: 'Criar Novo Anúncio',
              subtitle: 'Cadastre um novo serviço ou produto',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MyServicesScreen(business: widget.business),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: context.secondaryColor.withValues(alpha: 0.1),
            backgroundImage: widget.business.logo.isNotEmpty
                ? NetworkImage(widget.business.logo)
                : null,
            child: widget.business.logo.isEmpty
                ? Icon(
                    Icons.storefront,
                    size: 32,
                    color: context.secondaryColor,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.business.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.business.region,
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Iconsax.edit_2, color: context.secondaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BusinessEditScreen(business: widget.business),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_ads')
          .where('business.id', isEqualTo: widget.business.id)
          .snapshots(),
      builder: (context, adsSnapshot) {
        final int activeAdsCount = adsSnapshot.hasData
            ? adsSnapshot.data!.docs.length
            : 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('businessId', isEqualTo: widget.business.id)
              .snapshots(),
          builder: (context, bookingsSnapshot) {
            final bookings = bookingsSnapshot.hasData
                ? bookingsSnapshot.data!.docs
                : [];
            final int inProgressBookingsCount = bookings.where((doc) {
              final s =
                  (doc.data() as Map<String, dynamic>)['status'] as String? ??
                  '';
              return s == 'in_progress' || s == 'approved' || s == 'pending';
            }).length;
            final double totalRevenue = bookings
                .where((doc) {
                  final s =
                      (doc.data() as Map<String, dynamic>)['status']
                          as String? ??
                      '';
                  return s == 'in_progress' ||
                      s == 'approved' ||
                      s == 'completed';
                })
                .fold(
                  0.0,
                  (acc, doc) =>
                      acc +
                      (((doc.data() as Map<String, dynamic>)['price']
                                  as num?) ??
                              0)
                          .toDouble(),
                );

            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  icon: Iconsax.wallet,
                  title: 'Faturamento',
                  value:
                      'R\$ ${totalRevenue.toStringAsFixed(0).replaceAll('.', ',')}',
                  color: Colors.green,
                ),
                _buildStatCard(
                  icon: Iconsax.box,
                  title: 'Serviços Ativos',
                  value: '$activeAdsCount',
                  color: context.secondaryColor,
                ),
                _buildStatCard(
                  icon: Iconsax.clock,
                  title: 'Em Andamento',
                  value: '$inProgressBookingsCount',
                  color: Colors.blueAccent,
                ),
                _buildStatCard(
                  icon: Iconsax.chart_21,
                  title: 'Visualizações',
                  value: '312',
                  color: Colors.purple,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.3 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.3 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.secondaryColor.withValues(
                      alpha: context.isDarkMode ? 0.2 : 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: context.secondaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BusinessSettingsTab extends StatefulWidget {
  final Business business;
  final VoidCallback onLogout;

  const BusinessSettingsTab({
    super.key,
    required this.business,
    required this.onLogout,
  });

  @override
  State<BusinessSettingsTab> createState() => _BusinessSettingsTabState();
}

class _BusinessSettingsTabState extends State<BusinessSettingsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Configurações'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        key: const PageStorageKey<String>('settings_scroll'),
        padding: const EdgeInsets.all(24),
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: context.isDarkMode ? 0.3 : 0.04,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: context.secondaryColor.withValues(
                    alpha: 0.15,
                  ),
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Icon(
                          Icons.person,
                          size: 28,
                          color: context.secondaryColor,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Proprietário',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? user?.phoneNumber ?? '',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Gerenciamento',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: context.isDarkMode ? 0.3 : 0.04,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Iconsax.edit_2),
                  title: const Text('Editar Perfil Comercial'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BusinessEditScreen(business: widget.business),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                ListTile(
                  leading: const Icon(Iconsax.star),
                  title: const Text('Avaliações dos Clientes'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReviewsScreen(business: widget.business),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                ListTile(
                  leading: const Icon(Icons.alternate_email_rounded),
                  title: const Text('Alterar E-mail'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => AccountSecurityDialogs.showChangeEmailDialog(context),
                ),
                Divider(
                  height: 1,
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded),
                  title: const Text('Alterar Senha'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => AccountSecurityDialogs.showChangePasswordDialog(context),
                ),
                Divider(
                  height: 1,
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                ListTile(
                  leading: const Icon(Iconsax.logout),
                  title: const Text('Sair da Conta'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: widget.onLogout,
                ),
                Divider(
                  height: 1,
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                  title: const Text(
                    'Excluir Minha Conta',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.redAccent),
                  onTap: () => AccountSecurityDialogs.showDeleteAccountDialog(
                    context,
                    businessId: widget.business.id,
                    onDeleted: widget.onLogout,
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
