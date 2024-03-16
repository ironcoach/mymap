import 'package:flutter/material.dart';
import 'package:mymap/utils/extensions.dart';

class SignInSignUpButton extends StatelessWidget {
  final Function()? onTap;
  final String text;
  const SignInSignUpButton({super.key, this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        //backgroundColor: context.colorScheme.secondary,
        minimumSize: const Size.fromHeight(50),
      ),
      icon: const Icon(
        Icons.lock_open,
        size: 28,
      ),
      label: Text(
        text,
        //style: const TextStyle(fontSize: 24),
      ),
      onPressed: onTap,
    );
  }
}
