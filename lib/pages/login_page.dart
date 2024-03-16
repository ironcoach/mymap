import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:flutter_email_validator/email_validator.dart';
import 'package:mymap/constants/constants.dart';

import 'package:mymap/widgets/widgets.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTapRegister;
  const LoginPage({super.key, required this.onTapRegister});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // pop the loading circle
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      print("SignIn Error: ${e.code}");
      // pop the loading circle
      Navigator.pop(context);

      // Show Error Message
      showErrorMessage(e.code);
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
      //backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  const DrawBanner(),

                  const SizedBox(height: 30),

                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    controller: emailController,
                    //cursorColor: Colors.black,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (email) {
                      email != null && !EmailValidator.validate(email)
                          ? 'Enter a valid email'
                          : null;
                      return null;
                      // return null;
                    },
                  ),

                  const SizedBox(height: sizeBetweenFields),

                  TextFormField(
                    obscureText: passToggle,
                    obscuringCharacter: "*",
                    controller: passwordController,
                    //cursorColor: Colors.black,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffix: InkWell(
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
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (password) {
                      password != null && !EmailValidator.validate(password)
                          ? 'Enter a valid email'
                          : null;
                      return null;
                      // return null;
                    },
                  ),

                  const SizedBox(height: sizeBetweenFields),

                  // forgot password?
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Forgot Password?',
                          //style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: sizeBetweenFields * 1.5),

                  SignInSignUpButton(text: "Sign In", onTap: signUserIn),

                  const SizedBox(height: 20),

                  // or continue with
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            //color: Colors.grey[400],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            'Or continue with',
                            //style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        Expanded(
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
                      SquareTile(imagePath: 'assets/images/google.png'),

                      SizedBox(width: 25),

                      // apple button
                      SquareTile(imagePath: 'assets/images/apple.png')
                    ],
                  ),

                  const SizedBox(height: 30),

                  // not a member? register now
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Not a member?',
                        //style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTapRegister,
                        child: const Text(
                          'Register now',
                          // style: TextStyle(
                          //   color: Colors.blue,
                          //   fontWeight: FontWeight.bold,
                          // ),
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
    );
  }
}
