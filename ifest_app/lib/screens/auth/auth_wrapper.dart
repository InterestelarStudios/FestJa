import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ifest_app/screens/auth/login_screen.dart';
import 'package:ifest_app/screens/base/base_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While checking auth state, show a loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If the user is authenticated, go to the BaseScreen
        if (snapshot.hasData && snapshot.data != null) {
          return const BaseScreen();
        }

        // Otherwise, show the LoginScreen
        return const LoginScreen();
      },
    );
  }
}
