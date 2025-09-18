import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_email_validator/email_validator.dart';
import 'package:mymap/constants/constants.dart';
import 'package:mymap/utils/extensions.dart';

import 'package:mymap/widgets/widgets.dart';

class RegisterWebPage extends StatefulWidget {
  final Function()? onTapRegister;
  const RegisterWebPage({super.key, required this.onTapRegister});

  @override
  State<RegisterWebPage> createState() => _RegisterWebPageState();
}

class _RegisterWebPageState extends State<RegisterWebPage> {
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
          backgroundColor: Colors.deepPurple,
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
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
                Positioned(
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/SuzyBike1.jpg',
                    fit: BoxFit.fill,
                    width: MediaQuery.of(context).size.width / 3, // Half width

                    height: MediaQuery.of(context).size.height, // Full height
                  ),
                ),
                Positioned(
                  left: MediaQuery.of(context).size.width / 3,
                  right: 0,
                  child: Image.asset(
                    'assets/images/cennaRide1.jpg',
                    fit: BoxFit.fitWidth,
                    width: MediaQuery.of(context).size.width / 3, // Half width
                    height: MediaQuery.of(context).size.height, // Full height
                  ),
                ),
                // Background image 2 (modify positions and sizes for each image)
                Positioned(
                  top: 0.0,
                  left: MediaQuery.of(context).size.width / 1.5,
                  child: Image.asset(
                    '/images/tonyFoCo.jpg',
                    fit: BoxFit.fill,
                    width: MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).size.height,
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
                )),

                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 3.25,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              //const SizedBox(height: 10),

                              const DrawBanner(),

                              const SizedBox(height: 20),

                              // welcome back, you've been missed!
                              Text(
                                "Let's create an account for you.",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 25),

                              TextFormField(
                                keyboardType: TextInputType.name,
                                controller: firstNameController,
                                cursorColor: Colors.black,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                    labelText: 'FirstName',
                                    prefixIcon: Icon(Icons.person)),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                              ),
                              const SizedBox(height: sizeBetweenFields),

                              TextFormField(
                                keyboardType: TextInputType.name,
                                controller: lastNameController,
                                cursorColor: Colors.black,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                    labelText: 'LastName',
                                    prefixIcon: Icon(Icons.person)),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                              ),
                              const SizedBox(height: sizeBetweenFields),

                              TextFormField(
                                keyboardType: TextInputType.phone,
                                controller: phoneController,
                                cursorColor: Colors.black,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                    labelText: 'Phone',
                                    prefixIcon: Icon(Icons.phone)),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                              ),

                              const SizedBox(height: sizeBetweenFields),

                              TextFormField(
                                keyboardType: TextInputType.emailAddress,
                                controller: emailController,
                                cursorColor: Colors.black,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email)),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (email) {
                                  email != null &&
                                          !EmailValidator.validate(email)
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
                                cursorColor: Colors.black,
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
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (password) {
                                  password != null &&
                                          !EmailValidator.validate(password)
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
                                cursorColor: Colors.black,
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
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (password) {
                                  password != null &&
                                          !EmailValidator.validate(password)
                                      ? 'Enter a valid email'
                                      : null;
                                  return null;
                                  // return null;
                                },
                              ),

                              const SizedBox(height: 25),

                              SignInSignUpButton(
                                  text: "Sign Up", onTap: signUserUp),
                              // sign up button
                              // MyButton(
                              //   text: "Sign Up",
                              //   onTap: signUserUp,
                              // ),

                              const SizedBox(height: 10),

                              // or continue with
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        thickness: 0.5,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0),
                                      child: Text(
                                        'Or continue with',
                                        style:
                                            TextStyle(color: Colors.grey[700]),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        thickness: 0.5,
                                        color: Colors.grey[400],
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
                                    'Already have an Account?',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: widget.onTapRegister,
                                    child: const Text(
                                      'Login now',
                                      style: TextStyle(
                                        color: Colors.blue,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: const Color.fromARGB(255, 218, 43, 43),
  //     body: SafeArea(
  //       child: Center(
  //         child: SingleChildScrollView(
  //           child: Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 const DrawBanner(),

  //                 const SizedBox(height: 20),

  //                 // welcome back, you've been missed!
  //                 Text(
  //                   "Let's create an account for you.",
  //                   style: TextStyle(
  //                     color: Colors.grey[700],
  //                     fontSize: 16,
  //                   ),
  //                 ),

  //                 const SizedBox(height: 25),

  //                 TextFormField(
  //                   keyboardType: TextInputType.name,
  //                   controller: firstNameController,
  //                   cursorColor: Colors.black,
  //                   textInputAction: TextInputAction.next,
  //                   decoration: const InputDecoration(
  //                       labelText: 'FirstName', prefixIcon: Icon(Icons.person)),
  //                   autovalidateMode: AutovalidateMode.onUserInteraction,
  //                 ),
  //                 const SizedBox(height: sizeBetweenFields),

  //                 TextFormField(
  //                   keyboardType: TextInputType.name,
  //                   controller: lastNameController,
  //                   cursorColor: Colors.black,
  //                   textInputAction: TextInputAction.next,
  //                   decoration: const InputDecoration(
  //                       labelText: 'LastName', prefixIcon: Icon(Icons.person)),
  //                   autovalidateMode: AutovalidateMode.onUserInteraction,
  //                 ),
  //                 const SizedBox(height: sizeBetweenFields),

  //                 TextFormField(
  //                   keyboardType: TextInputType.phone,
  //                   controller: phoneController,
  //                   cursorColor: Colors.black,
  //                   textInputAction: TextInputAction.next,
  //                   decoration: const InputDecoration(
  //                       labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
  //                   autovalidateMode: AutovalidateMode.onUserInteraction,
  //                 ),

  //                 const SizedBox(height: sizeBetweenFields),

  //                 TextFormField(
  //                   keyboardType: TextInputType.emailAddress,
  //                   controller: emailController,
  //                   cursorColor: Colors.black,
  //                   textInputAction: TextInputAction.next,
  //                   decoration: const InputDecoration(
  //                       labelText: 'Email', prefixIcon: Icon(Icons.email)),
  //                   autovalidateMode: AutovalidateMode.onUserInteraction,
  //                   validator: (email) {
  //                     email != null && !EmailValidator.validate(email)
  //                         ? 'Enter a valid email'
  //                         : null;
  //                     return null;
  //                   },
  //                 ),

  //                 const SizedBox(height: sizeBetweenFields),

  //                 // password textfield
  //                 TextFormField(
  //                   obscureText: passToggle,
  //                   obscuringCharacter: "*",
  //                   controller: passwordController,
  //                   cursorColor: Colors.black,
  //                   textInputAction: TextInputAction.next,
  //                   decoration: InputDecoration(
  //                     labelText: 'Password',
  //                     prefixIcon: const Icon(Icons.lock),
  //                     suffix: InkWell(
  //                       onTap: () {
  //                         setState(() {
  //                           passToggle = !passToggle;
  //                         });
  //                       },
  //                       child: Icon(passToggle
  //                           ? Icons.visibility
  //                           : Icons.visibility_off),
  //                     ),
  //                   ),
  //                   autovalidateMode: AutovalidateMode.onUserInteraction,
  //                   validator: (password) {
  //                     password != null && !EmailValidator.validate(password)
  //                         ? 'Enter a valid email'
  //                         : null;
  //                     return null;
  //                   },
  //                 ),
  //                 const SizedBox(height: sizeBetweenFields),

  //                 // password textfield
  //                 TextFormField(
  //                   obscureText: passToggle,
  //                   obscuringCharacter: "*",
  //                   controller: confirmPassController,
  //                   cursorColor: Colors.black,
  //                   textInputAction: TextInputAction.next,
  //                   decoration: InputDecoration(
  //                     labelText: 'Confirm',
  //                     prefixIcon: const Icon(Icons.lock),
  //                     suffix: InkWell(
  //                       onTap: () {
  //                         setState(() {
  //                           passToggle = !passToggle;
  //                         });
  //                       },
  //                       child: Icon(passToggle
  //                           ? Icons.visibility
  //                           : Icons.visibility_off),
  //                     ),
  //                   ),
  //                   autovalidateMode: AutovalidateMode.onUserInteraction,
  //                   validator: (password) {
  //                     password != null && !EmailValidator.validate(password)
  //                         ? 'Enter a valid email'
  //                         : null;
  //                     return null;
  //                     // return null;
  //                   },
  //                 ),

  //                 const SizedBox(height: 25),

  //                 SignInSignUpButton(text: "Sign Up", onTap: signUserUp),
  //                 // sign up button
  //                 // MyButton(
  //                 //   text: "Sign Up",
  //                 //   onTap: signUserUp,
  //                 // ),

  //                 const SizedBox(height: 10),

  //                 // or continue with
  //                 Padding(
  //                   padding: const EdgeInsets.symmetric(horizontal: 25.0),
  //                   child: Row(
  //                     children: [
  //                       Expanded(
  //                         child: Divider(
  //                           thickness: 0.5,
  //                           color: Colors.grey[400],
  //                         ),
  //                       ),
  //                       Padding(
  //                         padding: const EdgeInsets.symmetric(horizontal: 10.0),
  //                         child: Text(
  //                           'Or continue with',
  //                           style: TextStyle(color: Colors.grey[700]),
  //                         ),
  //                       ),
  //                       Expanded(
  //                         child: Divider(
  //                           thickness: 0.5,
  //                           color: Colors.grey[400],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),

  //                 const SizedBox(height: 30),

  //                 //google + apple sign in buttons
  //                 const Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     // google button
  //                     SquareTile(imagePath: 'assets/images/google.png'),

  //                     SizedBox(width: 25),

  //                     // apple button
  //                     SquareTile(imagePath: 'assets/images/apple.png')
  //                   ],
  //                 ),

  //                 const SizedBox(height: 30),

  //                 // not a member? register now
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Text(
  //                       'Already have an Account?',
  //                       style: TextStyle(color: Colors.grey[700]),
  //                     ),
  //                     const SizedBox(width: 4),
  //                     GestureDetector(
  //                       onTap: widget.onTapRegister,
  //                       child: const Text(
  //                         'Login now',
  //                         style: TextStyle(
  //                           color: Colors.blue,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 )
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
