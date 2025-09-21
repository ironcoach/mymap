import 'package:flutter/material.dart';
import 'package:mymap/config/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mymap/pages/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

///
///
///  flutter run -d chrome --web-browser-flag "--disable-web-security"
///
///

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Add this debug check
    final firestore = FirebaseFirestore.instance;
    debugPrint('Firebase initialized successfully');
    debugPrint('Firestore app: ${firestore.app.name}');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized');
    } else {
      debugPrint('Firebase initialization error: $e');
      rethrow;
    }
  }

  // Clear Firestore cache on startup to avoid stale data
  try {
    await FirebaseFirestore.instance.clearPersistence();
    debugPrint('✅ Firestore cache cleared');
  } catch (e) {
    debugPrint('Failed to clear Firestore cache: $e');
  }

  // Configure Firestore settings
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

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
      title: 'Find My Ride',
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AuthPage(),
    );
  }
}
