import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ifest_app/firebase_options.dart';
import 'package:ifest_app/screens/base/base_screen.dart';
import 'package:ifest_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iFest',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const BaseScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
