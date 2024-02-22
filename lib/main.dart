import 'package:flutter/material.dart';
import 'package:mymap/config/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mymap/screens/mapscreen.dart';
import 'package:mymap/screens/splash_screen.dart';

void main() => runApp(
      const ProviderScope(child: MyApp()),
    );

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
      home: const MapScreen(),
    );
  }
}
