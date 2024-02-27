import 'package:flutter/material.dart';
import 'package:mymap/config/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mymap/screens/mapscreen.dart';
import 'package:mymap/screens/splash_screen.dart';

import 'package:mymap/screens/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      //options: DefaultFirebaseOptions.currentPlatform,
      );
  //runApp(const MyApp());
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Map Demo',
      theme: AppTheme.light,
      //theme: ThemeData(primaryColor: Colors.white),
      //home: const SplashScreen(),
      //home: const MapScreen(),
      home: const AuthPage(),
    );
  }
}
