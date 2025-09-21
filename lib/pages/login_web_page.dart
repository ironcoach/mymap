import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:flutter_email_validator/email_validator.dart';
import 'package:mymap/constants/constants.dart';
import 'package:mymap/utils/extensions.dart';

import 'package:mymap/widgets/widgets.dart';

class LoginWebPage extends StatefulWidget {
  final Function()? onTapRegister;
  const LoginWebPage({super.key, required this.onTapRegister});

  @override
  State<LoginWebPage> createState() => _LoginWebPageState();
}

class _LoginWebPageState extends State<LoginWebPage> {
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool passToggle = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // sign user in method
  void signUserIn() async {
    // show loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // try sign in
    try {
      debugPrint('Login: Attempting sign in with email: ${emailController.text.trim()}');

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      debugPrint('Login: ✅ Sign in successful');
      // pop the loading circle
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint("Login Firebase Auth Error: ${e.code} - ${e.message}");
      // pop the loading circle
      if (mounted) Navigator.pop(context);

      // Show Error Message with more descriptive text
      String userFriendlyMessage = _getUserFriendlyMessage(e.code);
      showErrorMessage(userFriendlyMessage);
    } catch (e) {
      debugPrint("Login General Error: $e");
      // pop the loading circle
      if (mounted) Navigator.pop(context);

      // Show Error Message
      showErrorMessage('Unknown Error: $e');
    }
  }

  String _getUserFriendlyMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later';
      case 'internal-error':
        return 'Internal server error. Please try again';
      default:
        return 'Login failed: $errorCode';
    }
  }

  // wrong email message popup
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          //backgroundColor: Colors.deepPurple,
          title: Center(
            child: Text(
              message,
              //style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  // wrong password message popup
  void wrongPasswordMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          //backgroundColor: Colors.deepPurple,
          title: Center(
            child: Text(
              'Incorrect Password',
              //style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Full background with gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                // Left side - First image
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.33,
                  child: ClipRect(
                    child: Image.asset(
                      'assets/images/SuzyBike1.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Center - Second image
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.33,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.34,
                  child: ClipRect(
                    child: Image.asset(
                      'assets/images/cennaRide1.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Right side - Third image
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.33,
                  child: ClipRect(
                    child: Image.asset(
                      'assets/images/tonyFoCo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Positioned(
                    // top: 30,
                    // left: 30,
                    child: Container(
                  color: context.colorScheme.onTertiary,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Find your Ride',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Login',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),  // Close Container
                ),  // Close Positioned

                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: MediaQuery.of(context).size.width / 3.25,
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              //const SizedBox(height: 10),

                              const DrawBanner(),

                              const SizedBox(height: 50),

                              TextFormField(
                                keyboardType: TextInputType.emailAddress,
                                controller: emailController,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (email) {
                                  return email != null &&
                                          !EmailValidator.validate(email)
                                      ? 'Enter a valid email'
                                      : null;
                                },
                              ),

                              const SizedBox(height: sizeBetweenFields),

                              TextFormField(
                                obscureText: passToggle,
                                obscuringCharacter: "*",
                                controller: passwordController,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                                      width: 2,
                                    ),
                                  ),
                                  suffixIcon: InkWell(
                                    onTap: () {
                                      setState(() {
                                        passToggle = !passToggle;
                                      });
                                    },
                                    child: Icon(passToggle
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                  ),
                                ),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (password) {
                                  if (password == null || password.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (password.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: sizeBetweenFields),

                              // forgot password?
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: sizeBetweenFields * 1.5),

                              SignInSignUpButton(
                                  text: "Sign In", onTap: signUserIn),

                              const SizedBox(height: 20),

                              // or continue with
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(
                                        thickness: 0.5,
                                        //color: Colors.grey[400],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0),
                                      child: Text(
                                        'Or continue with',
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(
                                        thickness: 0.5,
                                        //color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              //google + apple sign in buttons
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // google button
                                  SquareTile(
                                      imagePath: 'assets/images/google.png'),

                                  SizedBox(width: 25),

                                  // apple button
                                  SquareTile(
                                      imagePath: 'assets/images/apple.png')
                                ],
                              ),

                              const SizedBox(height: 30),

                              // not a member? register now
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Not a member?',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 15),
                                  GestureDetector(
                                    onTap: widget.onTapRegister,
                                    child: Text(
                                      'Register now',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                    ),
                      ),
                ),  // Close Center
              ],
            ),  // Close Stack
          ),    // Close Expanded
        ],
      ),
    );

    // return Scaffold(
    //   backgroundColor: const Color.fromARGB(255, 9, 175, 11),
    //   body: SafeArea(
    //     child: Center(
    //       child: SingleChildScrollView(
    //         child: Padding(
    //           padding: const EdgeInsets.all(16.0),
    //           child: Column(
    //             mainAxisAlignment: MainAxisAlignment.center,
    //             children: [
    //               const SizedBox(height: 10),

    //               const DrawBanner(),

    //               const SizedBox(height: 30),

    //               TextFormField(
    //                 keyboardType: TextInputType.emailAddress,
    //                 controller: emailController,
    //                 //cursorColor: Colors.black,
    //                 textInputAction: TextInputAction.next,
    //                 decoration: const InputDecoration(
    //                     labelText: 'Email', prefixIcon: Icon(Icons.email)),
    //                 autovalidateMode: AutovalidateMode.onUserInteraction,
    //                 validator: (email) {
    //                   email != null && !EmailValidator.validate(email)
    //                       ? 'Enter a valid email'
    //                       : null;
    //                   return null;
    //                   // return null;
    //                 },
    //               ),

    //               const SizedBox(height: sizeBetweenFields),

    //               TextFormField(
    //                 obscureText: passToggle,
    //                 obscuringCharacter: "*",
    //                 controller: passwordController,
    //                 //cursorColor: Colors.black,
    //                 textInputAction: TextInputAction.next,
    //                 decoration: InputDecoration(
    //                   labelText: 'Password',
    //                   prefixIcon: const Icon(Icons.lock),
    //                   suffix: InkWell(
    //                     onTap: () {
    //                       setState(() {
    //                         passToggle = !passToggle;
    //                       });
    //                     },
    //                     child: Icon(passToggle
    //                         ? Icons.visibility
    //                         : Icons.visibility_off),
    //                   ),
    //                 ),
    //                 autovalidateMode: AutovalidateMode.onUserInteraction,
    //                 validator: (password) {
    //                   password != null && !EmailValidator.validate(password)
    //                       ? 'Enter a valid email'
    //                       : null;
    //                   return null;
    //                   // return null;
    //                 },
    //               ),

    //               const SizedBox(height: sizeBetweenFields),

    //               // forgot password?
    //               const Padding(
    //                 padding: EdgeInsets.symmetric(horizontal: 25.0),
    //                 child: Row(
    //                   mainAxisAlignment: MainAxisAlignment.end,
    //                   children: [
    //                     Text(
    //                       'Forgot Password?',
    //                       //style: TextStyle(color: Colors.grey[600]),
    //                     ),
    //                   ],
    //                 ),
    //               ),

    //               const SizedBox(height: sizeBetweenFields * 1.5),

    //               SignInSignUpButton(text: "Sign In", onTap: signUserIn),

    //               const SizedBox(height: 20),

    //               // or continue with
    //               const Padding(
    //                 padding: EdgeInsets.symmetric(horizontal: 25.0),
    //                 child: Row(
    //                   children: [
    //                     Expanded(
    //                       child: Divider(
    //                         thickness: 0.5,
    //                         //color: Colors.grey[400],
    //                       ),
    //                     ),
    //                     Padding(
    //                       padding: EdgeInsets.symmetric(horizontal: 10.0),
    //                       child: Text(
    //                         'Or continue with',
    //                         //style: TextStyle(color: Colors.grey[700]),
    //                       ),
    //                     ),
    //                     Expanded(
    //                       child: Divider(
    //                         thickness: 0.5,
    //                         //color: Colors.grey[400],
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               ),

    //               const SizedBox(height: 30),

    //               //google + apple sign in buttons
    //               const Row(
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 children: [
    //                   // google button
    //                   SquareTile(imagePath: 'assets/images/google.png'),

    //                   SizedBox(width: 25),

    //                   // apple button
    //                   SquareTile(imagePath: 'assets/images/apple.png')
    //                 ],
    //               ),

    //               const SizedBox(height: 30),

    //               // not a member? register now
    //               Row(
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 children: [
    //                   const Text(
    //                     'Not a member?',
    //                     //style: TextStyle(color: Colors.grey[700]),
    //                   ),
    //                   const SizedBox(width: 4),
    //                   GestureDetector(
    //                     onTap: widget.onTapRegister,
    //                     child: const Text(
    //                       'Register now',
    //                       // style: TextStyle(
    //                       //   color: Colors.blue,
    //                       //   fontWeight: FontWeight.bold,
    //                       // ),
    //                     ),
    //                   ),
    //                 ],
    //               )
    //             ],
    //           ),
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }
}
