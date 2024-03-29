import 'package:flutter/material.dart';
import 'package:mymap/pages/login_web_page.dart';
import 'package:mymap/pages/register_page.dart';
import 'package:mymap/pages/register_web_page.dart';
import 'package:mymap/widgets/responsive_layout.dart';

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
      return ResponsiveLayout(
        mobileBody: LoginPage(
          onTapRegister: togglePages,
        ),
        //mobileBody: const MobileBody(),
        webBody: LoginWebPage(
          onTapRegister: togglePages,
        ),
      );
    } else {
      return ResponsiveLayout(
        mobileBody: RegisterPage(
          onTapRegister: togglePages,
        ),
        //mobileBody: const MobileBody(),
        webBody: RegisterWebPage(
          onTapRegister: togglePages,
        ),
      );
    }
  }
}
