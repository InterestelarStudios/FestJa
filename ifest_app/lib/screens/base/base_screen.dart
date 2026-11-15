import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_app/models/user.dart';
import 'package:ifest_app/screens/profile/profile_screen.dart';
import 'package:ifest_app/screens/auth/login_screen.dart';
import 'package:ifest_app/screens/marketplace/marketplace_screen.dart';
import 'package:ifest_app/screens/marketplace/map_selection_screen.dart';
import 'package:ifest_app/screens/events/my_events_screen.dart';
import 'package:ifest_app/screens/home/explore_screen.dart';
import 'package:ifest_app/screens/notifications/notifications_screen.dart';
import 'package:ifest_app/screens/chat/chat_list_screen.dart';
import 'package:ifest_app/services/notification_service.dart';
import 'package:ifest_app/services/chat_service.dart';
import 'package:ifest_app/services/review_service.dart';
import 'package:ifest_app/screens/marketplace/widgets/review_bottom_sheet.dart';
import 'package:ifest_app/theme/app_theme.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  int _currentIndex = 0;
  String? _userRegion;
  GeoPoint? _userGeoPoint;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return; // Fallback handled by MarketplaceScreen
      }
      
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userGeoPoint = GeoPoint(position.latitude, position.longitude);
        });
      }
      
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.subAdministrativeArea ?? place.locality ?? place.administrativeArea ?? '';
        final state = place.administrativeArea ?? '';
        
        String regionStr = '$city - $state'.trim();
        if (regionStr.startsWith('-')) regionStr = regionStr.substring(1).trim();
        
        if (mounted) {
          setState(() {
            _userRegion = regionStr;
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar localização: $e');
    }
  }



  Future<void> _openMapSelection() async {
    final result = await Navigator.push<MapSelectionResult>(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          initialLocation: _userGeoPoint,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _userGeoPoint = result.geoPoint;
        if (result.region.isNotEmpty) {
          _userRegion = result.region;
        }
      });
    }
  }

  bool _checkedPendingReview = false;

  void _checkPendingReviews(String uid) {
    if (_checkedPendingReview) return;
    _checkedPendingReview = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pendingBooking = await ReviewService().checkPendingReview(uid);
      if (pendingBooking != null && mounted) {
        ReviewBottomSheet.show(context, pendingBooking);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (user != null) {
          _checkPendingReviews(user.uid);
        } else {
          _checkedPendingReview = false;
        }

        final List<BottomNavigationBarItem> navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.home),
            activeIcon: Icon(Iconsax.home, color: context.secondaryColor),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.building),
            activeIcon: Icon(Iconsax.building, color: context.secondaryColor),
            label: 'Serviços',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.calendar_1),
            activeIcon: Icon(Iconsax.calendar_1, color: context.secondaryColor),
            label: 'Eventos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ];

        if (user == null) {
          final List<Widget> screens = [
            ExploreScreen(
              region: _userRegion,
              geoPoint: _userGeoPoint,
              onLocationTap: _openMapSelection,
              onNavigateToTab: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ), // Explore
            MarketplaceScreen(
              region: _userRegion,
              geoPoint: _userGeoPoint,
              onLocationTap: _openMapSelection,
            ), // Serviços
            _buildLoginPrompt(context), // Eventos
            _buildLoginPrompt(context), // Perfil
          ];
          return _buildScaffold(screens, navItems);
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            Usuario? usuario;
            if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>;
              usuario = Usuario(
                id: data['id'] ?? user.uid,
                username: data['username'] ?? user.displayName ?? "Usuário Fest'Ja",
                email: data['email'] ?? user.email ?? user.phoneNumber ?? '',
                image: data['image'] ?? user.photoURL ?? '',
              );
            } else {
              usuario = Usuario(
                id: user.uid,
                username: user.displayName ?? "Usuário Fest'Ja",
                email: user.email ?? user.phoneNumber ?? '',
                image: user.photoURL ?? '',
              );
            }

            final List<Widget> screens = [
              ExploreScreen(
                region: _userRegion,
                geoPoint: _userGeoPoint,
                onLocationTap: _openMapSelection,
                onNavigateToTab: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ), // Explore
              MarketplaceScreen(
                region: _userRegion,
                geoPoint: _userGeoPoint,
                onLocationTap: _openMapSelection,
              ), // Serviços
              const MyEventsScreen(), // Eventos
              ProfileScreen(usuario: usuario), // Perfil
            ];
            return _buildScaffold(screens, navItems);
          },
        );
      },
    );
  }

  Widget _buildScaffold(List<Widget> screens, List<BottomNavigationBarItem> navItems) {
    // Prevent out-of-bounds index when items change
    int safeIndex = _currentIndex;
    if (safeIndex >= screens.length) {
      safeIndex = screens.length - 1;
    }

    final isExplore = safeIndex == 0;

    return Scaffold(
      body: Stack(
        children: [
          FadeIndexedStack(index: safeIndex, children: screens),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTopNotificationButton(context, isExplore),
                    _buildTopChatButton(context, isExplore),
                  ],
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
          currentIndex: safeIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: navItems,
        ),
      ),
    );
  }

  Widget _buildTopNotificationButton(BuildContext context, bool isExplore) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return _buildTopButton(
        context: context,
        icon: Iconsax.notification,
        badgeCount: 0,
        badgeColor: AppTheme.accentPink,
        isExplore: isExplore,
        tooltip: 'Notificações',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
      );
    }

    return StreamBuilder<int>(
      stream: NotificationService().streamUnreadCount(currentUid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return _buildTopButton(
          context: context,
          icon: Iconsax.notification,
          badgeCount: unreadCount,
          badgeColor: AppTheme.accentPink,
          isExplore: isExplore,
          tooltip: 'Notificações',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildTopChatButton(BuildContext context, bool isExplore) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return _buildTopButton(
        context: context,
        icon: Iconsax.message_text,
        badgeCount: 0,
        badgeColor: AppTheme.secondaryPurple,
        isExplore: isExplore,
        tooltip: 'Mensagens & Chat',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
      );
    }

    return StreamBuilder<int>(
      stream: ChatService().streamTotalUnreadCount(currentUid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return _buildTopButton(
          context: context,
          icon: Iconsax.message_text,
          badgeCount: unreadCount,
          badgeColor: AppTheme.accentPink,
          isExplore: isExplore,
          tooltip: 'Mensagens & Chat',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatListScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildTopButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required int badgeCount,
    required Color badgeColor,
    required bool isExplore,
    required String tooltip,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isExplore
        ? Colors.white.withValues(alpha: 0.18)
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    final borderColor = isExplore
        ? Colors.white.withValues(alpha: 0.28)
        : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08));

    final iconColor = isExplore
        ? Colors.white
        : (isDark ? Colors.white : AppTheme.primaryDark);

    final boxShadow = isExplore
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ];

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: boxShadow,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isExplore
                          ? AppTheme.primaryDark
                          : (isDark ? const Color(0xFF0F172A) : Colors.white),
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: context.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'Entre para ver seu perfil',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Você precisa estar logado para acessar seus dados.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text(
                    'Fazer Login',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<bool> _activated;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _activated = List.generate(
      widget.children.length,
      (i) => i == widget.index,
    );
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activated[widget.index] == false) {
      setState(() {
        _activated[widget.index] = true;
      });
    }
    if (oldWidget.index != widget.index) {
      setState(() {
        _currentIndex = widget.index;
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: _currentIndex,
        children: List.generate(widget.children.length, (i) {
          return _activated[i] ? widget.children[i] : const SizedBox.shrink();
        }),
      ),
    );
  }
}
