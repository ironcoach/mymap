import 'package:flutter/material.dart';
import 'package:mymap/pages/register_page.dart';

import 'login_page.dart';

class LoginOrRegPage extends StatefulWidget {
  const LoginOrRegPage({super.key});

  @override
  State<LoginOrRegPage> createState() => _LoginOrRegPageState();
}

class _LoginOrRegPageState extends State<LoginOrRegPage> {
  // initally show login page
  bool showLoginPage = true;

  // toggle between login and reg page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        onTapRegister: togglePages,
      );
    } else {
      return RegisterPage(
        onTapRegister: togglePages,
      );
    }
  }
}
