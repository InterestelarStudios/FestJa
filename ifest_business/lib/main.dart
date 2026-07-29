import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ifest_business/firebase_options.dart';
import 'package:ifest_business/theme/app_theme.dart';
import 'package:ifest_business/screens/auth/login_screen.dart';
import 'package:ifest_business/screens/business/business_registration_screen.dart';
import 'package:ifest_business/screens/business/business_management_screen.dart';
import 'package:ifest_business/models/business.dart';
import 'package:ifest_business/models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BusinessApp());
}

class BusinessApp extends StatelessWidget {
  const BusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iFest para Empresas',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
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
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundLight,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // Fetch User and check Business
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppTheme.backgroundLight,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            Usuario usuario;
            if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>;
              usuario = Usuario(
                id: data['id'] ?? user.uid,
                username: data['username'] ?? user.displayName ?? 'Lojista',
                email: data['email'] ?? user.email ?? user.phoneNumber ?? '',
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

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('businesses')
                  .where('creator.id', isEqualTo: usuario.id)
                  .limit(1)
                  .snapshots(),
              builder: (context, businessSnapshot) {
                if (businessSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: AppTheme.backgroundLight,
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final hasBusiness = businessSnapshot.hasData && businessSnapshot.data!.docs.isNotEmpty;

                if (hasBusiness) {
                  final data = businessSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                  if (!data.containsKey('id')) {
                    data['id'] = businessSnapshot.data!.docs.first.id;
                  }
                  final business = Business.fromMap(data);
                  return BusinessManagementScreen(business: business);
                }

                return BusinessRegistrationScreen(usuario: usuario);
              },
            );
          },
        );
      },
    );
  }
}
