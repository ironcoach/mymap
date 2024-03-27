import 'package:flutter/material.dart';
import 'package:mymap/utils/extensions.dart';

class MyTextField extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.colorScheme.outline),
          ),
          fillColor: context.colorScheme.onInverseSurface,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: context.colorScheme.outlineVariant),
        ),
      ),
    );
  }
}
