import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_app/models/business.dart';
import 'package:ifest_app/models/event.dart';
import 'package:ifest_app/models/service_ads.dart';
import 'package:ifest_app/screens/events/create_event_screen.dart';
import 'package:ifest_app/screens/events/event_details_screen.dart';
import 'package:ifest_app/screens/marketplace/business_profile_screen.dart';
import 'package:ifest_app/screens/marketplace/marketplace_screen.dart';
import 'package:ifest_app/screens/marketplace/service_details_screen.dart';
import 'package:ifest_app/services/event_service.dart';
import 'package:ifest_app/theme/app_theme.dart';

class ExploreScreen extends StatelessWidget {
  final String? region;
  final GeoPoint? geoPoint;
  final VoidCallback? onLocationTap;
  final Function(int)? onNavigateToTab;

  const ExploreScreen({
    super.key,
    this.region,
    this.geoPoint,
    this.onLocationTap,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildOngoingEventsSection(context),
            _buildCategoriesSection(context),
            const SizedBox(height: 20),
            _buildCtaBanner(context),
            const SizedBox(height: 24),
            _buildFeaturedBusinessesSection(context),
            const SizedBox(height: 24),
            _buildFeaturedServicesSection(context),
            const SizedBox(height: 24),
            _buildPlanningTipsSection(context),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. CABEÇALHO COM LOCALIZAÇÃO E PESQUISA
  // ==========================================
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/auth1.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: context.isDarkMode ? 0.45 : 0.25),
            BlendMode.darken,
          ),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryDark.withValues(alpha: 0.95),
                  AppTheme.primaryDark.withValues(alpha: 0.7),
                  AppTheme.primaryDark.withValues(alpha: 0.25),
                ],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 7,
              left: 16,
              right: 16,
              bottom: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha superior: Título e Localização alinhados à esquerda (com recuo para não ficar atrás dos botões)
                SizedBox(
                  height: 42,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 48), // Espaço para o botão de Notificação
                      Expanded(
                        child: GestureDetector(
                          onTap: onLocationTap,
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sua Localização',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 13,
                                    color: AppTheme.accentPink,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      (region != null && region!.trim().isNotEmpty)
                                          ? region!
                                          : 'Selecionar região',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Espaço para o botão de Chat
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Saudação / Mensagem de boas-vindas
                Text(
                  'Tudo para a sua festa inesquecível ✨',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Encontre espaços, buffets, DJs, decoração e muito mais.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // Barra de Busca Interativa adaptada ao Dark/Light
                GestureDetector(
                  onTap: () {
                    if (onNavigateToTab != null) {
                      onNavigateToTab!(1);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MarketplaceScreen(
                            region: region,
                            geoPoint: geoPoint,
                            onLocationTap: onLocationTap,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.transparent,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: context.isDarkMode ? 0.3 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.search_normal,
                          color: context.secondaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Buscar serviços, atrações, locais...',
                            style: TextStyle(
                              color: context.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.secondaryColor
                                .withValues(alpha: context.isDarkMode ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Iconsax.setting_4,
                            color: context.secondaryColor,
                            size: 16,
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
      ),
    );
  }

  // ==========================================
  // 2. EVENTOS EM ANDAMENTO / PRÓXIMOS EVENTOS
  // ==========================================
  Widget _buildOngoingEventsSection(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<Event>>(
      stream: EventService().getUserEvents(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        // Filter events that are today or in the future
        final upcomingEvents = snapshot.data!.where((event) {
          final eventDate = event.date.toDate();
          return eventDate.isAfter(todayStart.subtract(const Duration(days: 1)));
        }).toList();

        // If no events ongoing/upcoming, DO NOT DISPLAY ANYTHING
        if (upcomingEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.secondaryColor
                              .withValues(alpha: context.isDarkMode ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.calendar_tick,
                          color: context.secondaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Seus Próximos Eventos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      if (onNavigateToTab != null) {
                        onNavigateToTab!(2);
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Ver todos',
                      style: TextStyle(
                        color: context.secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 165,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: upcomingEvents.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  return _buildOngoingEventCard(context, upcomingEvents[index]);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildOngoingEventCard(BuildContext context, Event event) {
    final hasImage = event.image != null && event.image!.isNotEmpty;
    final date = event.date.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    final diffDays = eventDay.difference(today).inDays;

    String countdownBadge;
    Color badgeColor;
    if (diffDays == 0) {
      countdownBadge = 'É Hoje! 🎉';
      badgeColor = AppTheme.accentGreen;
    } else if (diffDays == 1) {
      countdownBadge = 'Amanhã';
      badgeColor = AppTheme.accentPink;
    } else if (diffDays > 1) {
      countdownBadge = 'Faltam $diffDays dias';
      badgeColor = context.secondaryColor;
    } else {
      countdownBadge = 'Em andamento';
      badgeColor = AppTheme.primaryDark;
    }

    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: context.surfaceColor,
          border: Border.all(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.25 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Fundo da imagem ou gradiente
              Positioned.fill(
                child: hasImage
                    ? Image.network(
                        event.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackGradient(),
                      )
                    : _buildFallbackGradient(),
              ),

              // Overlay gradiente para legibilidade
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),

              // Conteúdo do Card
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge Superior
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            countdownBadge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.people,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${event.people} conv.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Título e Data Inferiores
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Iconsax.calendar_1,
                              color: Colors.white70,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            if (event.region != null &&
                                event.region!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Text(
                                '•',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.region!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3A0CA3), Color(0xFF7209B7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // ==========================================
  // 3. CATEGORIAS POPULARES / ATALHOS
  // ==========================================
  Widget _buildCategoriesSection(BuildContext context) {
    final categories = [
      {'title': 'Espaços', 'icon': Icons.castle_rounded, 'tag': 'Local', 'color': const Color(0xFF4361EE)},
      {'title': 'Buffet', 'icon': Icons.restaurant_rounded, 'tag': 'Alimentação', 'color': const Color(0xFFF72585)},
      {'title': 'Decoração', 'icon': Icons.auto_awesome_rounded, 'tag': 'Decoração', 'color': const Color(0xFF9D4EDD)},
      {'title': 'Bebidas', 'icon': Icons.local_bar_rounded, 'tag': 'Bebidas', 'color': const Color(0xFF4CC9F0)},
      {'title': 'DJs & Som', 'icon': Icons.music_note_rounded, 'tag': 'Som e Iluminação', 'color': const Color(0xFF5E60CE)},
      {'title': 'Foto & Vídeo', 'icon': Icons.camera_alt_rounded, 'tag': 'Fotografia/Vídeo', 'color': const Color(0xFFF3722C)},
      {'title': 'Atrações', 'icon': Icons.theater_comedy_rounded, 'tag': 'Atração', 'color': const Color(0xFF52B788)},
      {'title': 'Equipe', 'icon': Icons.groups_rounded, 'tag': 'Equipe de Apoio', 'color': const Color(0xFF48CAE4)},
      {'title': 'Estrutura', 'icon': Icons.holiday_village_rounded, 'tag': 'Estrutura', 'color': const Color(0xFFF8961E)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'O que você procura?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
              ),
              TextButton(
                onPressed: () {
                  if (onNavigateToTab != null) {
                    onNavigateToTab!(1);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarketplaceScreen(
                          region: region,
                          geoPoint: geoPoint,
                          onLocationTap: onLocationTap,
                        ),
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Ver todas',
                  style: TextStyle(
                    color: context.secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final catColor = cat['color'] as Color;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarketplaceScreen(
                        region: region,
                        geoPoint: geoPoint,
                        initialCategory: cat['tag'] as String,
                        onLocationTap: onLocationTap,
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: catColor.withValues(
                            alpha: context.isDarkMode ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: catColor.withValues(
                              alpha: context.isDarkMode ? 0.4 : 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        cat['icon'] as IconData,
                        color: catColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat['title'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 4. BANNER PROMOCIONAL / CTA "CRIE SEU EVENTO"
  // ==========================================
  Widget _buildCtaBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.isDarkMode
                ? const [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                    Color(0xFF3A0CA3),
                  ]
                : const [
                    Color(0xFF0D1B2A),
                    Color(0xFF1B263B),
                    Color(0xFF415A77),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.35 : 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPink.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.accentPink.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Planejador Gratuito ✨',
                      style: TextStyle(
                        color: AppTheme.accentPink,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Organize sua festa dos sonhos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Controle convidados, datas e contrate fornecedores ideais.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateEventScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Criar Evento',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 5. EMPRESAS EM DESTAQUE NA REGIÃO
  // ==========================================
  Widget _buildFeaturedBusinessesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.secondaryColor
                              .withValues(alpha: context.isDarkMode ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          color: context.secondaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Empresas em Destaque',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                      ),
                    ],
                  ),
                  if (region != null)
                    TextButton(
                      onPressed: () {
                        if (onNavigateToTab != null) {
                          onNavigateToTab!(1);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Ver todas',
                        style: TextStyle(
                          color: context.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              if (region != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 2),
                  child: Text(
                    'Parceiros verificados em $region',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (region == null)
          _buildLocationRequiredCard(context)
        else
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('businesses')
                .where('region', isEqualTo: region)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorCard(context, 'Erro ao carregar empresas.');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyBusinessesCard(context);
              }

              final businesses = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (!data.containsKey('id')) data['id'] = doc.id;
                return Business.fromMap(data);
              }).toList();

              // Sort by newest
              businesses.sort((a, b) => b.created.compareTo(a.created));

              return SizedBox(
                height: 180,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: businesses.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return _buildBusinessCard(context, businesses[index]);
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBusinessCard(BuildContext context, Business business) {
    final hasLogo = business.logo.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessProfileScreen(
              businessDetails: business.toDetails(),
            ),
          ),
        );
      },
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : context.primaryColor.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo adaptada para ambos os temas
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF3F4F6),
                border: Border.all(
                  color: context.secondaryColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                image: hasLogo
                    ? DecorationImage(
                        image: NetworkImage(business.logo),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasLogo
                  ? Icon(
                      Icons.storefront_rounded,
                      color: context.secondaryColor,
                      size: 28,
                    )
                  : null,
            ),
            const SizedBox(height: 10),

            // Nome da Empresa
            Text(
              business.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Categoria principal
            if (business.categories.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.secondaryColor
                      .withValues(alpha: context.isDarkMode ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  business.categories.first.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.secondaryColor,
                  ),
                ),
              ),

            const Spacer(),

            // Badge Parceiro
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppTheme.accentGreen,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Verificado',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 6. SERVIÇOS EM ALTA NA REGIÃO
  // ==========================================
  Widget _buildFeaturedServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPink
                              .withValues(alpha: context.isDarkMode ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.star_1,
                          color: AppTheme.accentPink,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Serviços em Alta',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                      ),
                    ],
                  ),
                  if (region != null)
                    TextButton(
                      onPressed: () {
                        if (onNavigateToTab != null) {
                          onNavigateToTab!(1);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MarketplaceScreen(
                                region: region,
                                geoPoint: geoPoint,
                                onLocationTap: onLocationTap,
                              ),
                            ),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Ver vitrine',
                        style: TextStyle(
                          color: context.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              if (region != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 2),
                  child: Text(
                    'Mais procurados na sua região',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (region == null)
          _buildLocationRequiredCard(context)
        else
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('service_ads')
                .where('region', isEqualTo: region)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorCard(context, 'Erro ao carregar serviços.');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyServicesCard(context);
              }

              final ads = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (!data.containsKey('id')) data['id'] = doc.id;
                return ServiceAds.fromMap(data);
              }).where((ad) => ad.isAvailable).toList();

              if (ads.isEmpty) {
                return _buildEmptyServicesCard(context);
              }

              ads.sort((a, b) => b.creted.compareTo(a.creted));

              // Show top 6 items in home
              final displayAds = ads.take(6).toList();

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.76,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: displayAds.length,
                itemBuilder: (context, index) {
                  return _buildServiceCard(context, displayAds[index]);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceAds ad) {
    final hasImage = ad.images.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(serviceAd: ad),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.25 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto do serviço
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  color: context.isDarkMode
                      ? const Color(0xFF0F172A)
                      : Colors.grey.shade200,
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(ad.images.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasImage
                    ? Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: context.textMuted,
                        ),
                      )
                    : null,
              ),
            ),

            // Informações do serviço
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: 11,
                        color: context.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ad.business.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'R\$ ${ad.price.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      color: AppTheme.accentPink,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 7. DICAS E CHECKLIST DE PLANEJAMENTO
  // ==========================================
  Widget _buildPlanningTipsSection(BuildContext context) {
    final tips = [
      {
        'title': 'Contratação Segura',
        'desc': 'Fornecedores verificados e histórico de avaliações.',
        'icon': Icons.security_rounded,
        'color': AppTheme.accentGreen,
      },
      {
        'title': 'Tudo em um Só Lugar',
        'desc': 'Espaço, buffet, som, decoração e atrações no app.',
        'icon': Icons.all_inclusive_rounded,
        'color': context.secondaryColor,
      },
      {
        'title': 'Planejamento Fácil',
        'desc': 'Acompanhe datas, convidados e serviços contratados.',
        'icon': Icons.checklist_rounded,
        'color': AppTheme.accentPink,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por que usar o Fest\'Ja?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
          ),
          const SizedBox(height: 12),
          Column(
            children: tips.map((tip) {
              final color = tip['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(
                            alpha: context.isDarkMode ? 0.2 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        tip['icon'] as IconData,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tip['desc'] as String,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INDICADORES DE ITENS VAZIOS / LOCALIZAÇÃO
  // ==========================================
  Widget _buildEmptyBusinessesCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF0F172A)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 32,
              color: context.secondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma empresa cadastrada em $region',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estamos expandindo! Você pode alterar a localização para explorar empresas em cidades vizinhas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onLocationTap,
            icon: const Icon(Iconsax.location, size: 14),
            label: const Text('Trocar Região', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.secondaryColor,
              side: BorderSide(color: context.secondaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyServicesCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentPink
                  .withValues(alpha: context.isDarkMode ? 0.18 : 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration_outlined,
              size: 32,
              color: AppTheme.accentPink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum serviço disponível em $region',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Novos pacotes e serviços são publicados diariamente pelos nossos parceiros.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onLocationTap,
            icon: const Icon(Iconsax.location, size: 14),
            label: const Text('Trocar Região', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.secondaryColor,
              side: BorderSide(color: context.secondaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRequiredCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.secondaryColor
              .withValues(alpha: context.isDarkMode ? 0.35 : 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.secondaryColor
                  .withValues(alpha: context.isDarkMode ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.location5,
              color: context.secondaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Definir Localização',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Selecione sua cidade para ver fornecedores e serviços próximos.',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onLocationTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Definir',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}
