import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:mymap/config/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mymap/pages/splash_screen.dart';

import 'package:mymap/pages/auth_page.dart';
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
    print(
        "Date: ${DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour, DateTime.now().minute)}");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Find My Ride',
      //theme: AppTheme.light,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      //theme: ThemeData(primaryColor: Colors.white),
      //home: const SplashScreen(),
      //home: const MapScreen(),
      home: const AuthPage(),
    );
  }
}
