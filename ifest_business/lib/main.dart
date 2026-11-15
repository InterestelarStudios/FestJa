import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ifest_business/firebase_options.dart';
import 'package:ifest_business/theme/app_theme.dart';
import 'package:ifest_business/screens/auth/login_screen.dart';
import 'package:ifest_business/screens/business/business_management_screen.dart';
import 'package:ifest_business/screens/business/business_intro_screen.dart';
import 'package:ifest_business/models/business.dart';
import 'package:ifest_business/models/user.dart';

import 'package:ifest_business/services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init(navKey: navigatorKey);
  runApp(const BusinessApp());
}

class BusinessApp extends StatelessWidget {
  const BusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: "Fest'Ja Empresas",
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: isDark
              ? const Color(0xFF0F172A)
              : Colors.white,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const RootController(),
    );
  }
}

class RootController extends StatelessWidget {
  const RootController({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting &&
            !authSnapshot.hasData) {
          return Scaffold(
            backgroundColor: context.backgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // Query the business directly using the authenticated user UID
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('businesses')
              .where('creator.id', isEqualTo: user.uid)
              .limit(1)
              .snapshots(),
          builder: (context, businessSnapshot) {
            if (businessSnapshot.connectionState == ConnectionState.waiting &&
                !businessSnapshot.hasData) {
              return Scaffold(
                backgroundColor: context.backgroundColor,
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final hasBusiness =
                businessSnapshot.hasData &&
                businessSnapshot.data != null &&
                businessSnapshot.data!.docs.isNotEmpty;

            if (hasBusiness) {
              final doc = businessSnapshot.data!.docs.first;
              final data = doc.data() as Map<String, dynamic>;
              if (!data.containsKey('id')) {
                data['id'] = doc.id;
              }
              final business = Business.fromMap(data);
              return BusinessManagementScreen(
                key: ValueKey(business.id),
                business: business,
              );
            }

            // User does not have a business yet -> Fetch user data once and show intro
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, userSnapshot) {
                Usuario usuario;
                if (userSnapshot.hasData &&
                    userSnapshot.data != null &&
                    userSnapshot.data!.exists) {
                  final data =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  usuario = Usuario(
                    id: data['id'] ?? user.uid,
                    username: data['username'] ?? user.displayName ?? 'Lojista',
                    email:
                        data['email'] ?? user.email ?? user.phoneNumber ?? '',
                    image: data['image'] ?? user.photoURL ?? '',
                  );
                } else {
                  usuario = Usuario(
                    id: user.uid,
                    username: user.displayName ?? 'Lojista',
                    email: user.email ?? user.phoneNumber ?? '',
                    image: user.photoURL ?? '',
                  );
                }

                return BusinessIntroScreen(usuario: usuario);
              },
            );
          },
        );
      },
    );
  }
}
