import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mymap/pages/login_or_reg_page.dart';

import 'package:mymap/pages/mapscreen.dart';
import 'package:mymap/pages/testpage.dart';

//import 'home_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('Something Went Wrong!'),
            );
          } else if (snapshot.hasData) {
            //return HomePage();
            //return TestPage();
            return const MapScreen();
            //return TestHomePage();
          } else {
            return const LoginOrRegPage();
          }
        },
      ),
    );
  }
}
