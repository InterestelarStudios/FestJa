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
import 'package:ifest_app/screens/events/my_events_screen.dart';
import 'package:ifest_app/screens/home/explore_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        final List<BottomNavigationBarItem> navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.home),
            activeIcon: Icon(Iconsax.home, color: AppTheme.secondaryPurple),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.building),
            activeIcon: Icon(Iconsax.building, color: AppTheme.secondaryPurple),
            label: 'Serviços',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.calendar_1),
            activeIcon: Icon(Iconsax.calendar_1, color: AppTheme.secondaryPurple),
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
            ExploreScreen(region: _userRegion), // Explore
            MarketplaceScreen(region: _userRegion, geoPoint: _userGeoPoint), // Serviços
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
                username: data['username'] ?? user.displayName ?? 'Usuário iFest',
                email: data['email'] ?? user.email ?? user.phoneNumber ?? '',
                image: data['image'] ?? user.photoURL ?? '',
              );
            } else {
              usuario = Usuario(
                id: user.uid,
                username: user.displayName ?? 'Usuário iFest',
                email: user.email ?? user.phoneNumber ?? '',
                image: user.photoURL ?? '',
              );
            }

            final List<Widget> screens = [
              ExploreScreen(region: _userRegion), // Explore
              MarketplaceScreen(region: _userRegion, geoPoint: _userGeoPoint), // Serviços
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

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
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

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'Entre para ver seu perfil',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Você precisa estar logado para acessar seus dados.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
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
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: Colors.white,
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
