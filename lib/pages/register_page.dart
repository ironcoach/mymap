import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_email_validator/email_validator.dart';
import 'package:mymap/constants/constants.dart';

import 'package:mymap/widgets/widgets.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTapRegister;
  const RegisterPage({super.key, required this.onTapRegister});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPassController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  //final lastNameController = TextEditingController();

  bool passToggle = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPassController.dispose();
    firstNameController.dispose();

    super.dispose();
  }

  // sign user Up method
  void signUserUp() async {
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

    // try sign up
    try {
      if (passwordConfirmed()) {
        //User? myUser = FirebaseAuth.instance.currentUser;
        //UserCredential user =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        User? myUser = FirebaseAuth.instance.currentUser;

        FirebaseFirestore.instance.collection("users").doc(myUser!.email).set({
          'firstname': firstNameController.text.trim(),
          'lastname': lastNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': myUser.email,
          'id': myUser.uid,
        });
      } else {
        showErrorMessage("Passwords don't match");
      }
      // pop the loading circle
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint("SignIn Error: ${e.code}");
      // pop the loading circle
      if (mounted) Navigator.pop(context);

      // Show Error Message
      showErrorMessage(e.code);
    }
  }

  bool passwordConfirmed() {
    if (passwordController.text.trim() == confirmPassController.text.trim()) {
      return true;
    } else {
      return false;
    }
  }

  // wrong email message popup
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              message,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const DrawBanner(),

                  const SizedBox(height: 20),

                  // welcome back, you've been missed!
                  Text(
                    "Let's create an account for you.",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 25),

                  TextFormField(
                    keyboardType: TextInputType.name,
                    controller: firstNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'FirstName', prefixIcon: Icon(Icons.person)),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: sizeBetweenFields),

                  TextFormField(
                    keyboardType: TextInputType.name,
                    controller: lastNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'LastName', prefixIcon: Icon(Icons.person)),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: sizeBetweenFields),

                  TextFormField(
                    keyboardType: TextInputType.phone,
                    controller: phoneController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),

                  const SizedBox(height: sizeBetweenFields),

                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    controller: emailController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (email) {
                      email != null && !EmailValidator.validate(email)
                          ? 'Enter a valid email'
                          : null;
                      return null;
                    },
                  ),

                  const SizedBox(height: sizeBetweenFields),

                  // password textfield
                  TextFormField(
                    obscureText: passToggle,
                    obscuringCharacter: "*",
                    controller: passwordController,
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
                    },
                  ),
                  const SizedBox(height: sizeBetweenFields),

                  // password textfield
                  TextFormField(
                    obscureText: passToggle,
                    obscuringCharacter: "*",
                    controller: confirmPassController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Confirm',
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

                  const SizedBox(height: 25),

                  SignInSignUpButton(text: "Sign Up", onTap: signUserUp),
                  // sign up button
                  // MyButton(
                  //   text: "Sign Up",
                  //   onTap: signUserUp,
                  // ),

                  const SizedBox(height: 10),

                  // or continue with
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            'Or continue with',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
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
                      Text(
                        'Already have an Account?',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTapRegister,
                        child: Text(
                          'Login now',
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
    );
  }
}
