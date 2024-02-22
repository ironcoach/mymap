import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import 'package:mymap/utils/extensions.dart';

class CommonTextField extends StatelessWidget {
  const CommonTextField({
    Key? key,
    required this.title,
    required this.hintText,
    this.controller,
    this.maxLines,
    this.suffixIcon,
    this.readOnly = false,
    this.isNumeric = false,
  }) : super(key: key);

  final String title;
  final String hintText;
  final TextEditingController? controller;
  final int? maxLines;
  final Widget? suffixIcon;
  final bool readOnly;
  final bool isNumeric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: context.textTheme.titleLarge,
        ),
        const Gap(10),
        TextField(
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          inputFormatters: [
            isNumeric
                ? FilteringTextInputFormatter.digitsOnly
                : FilteringTextInputFormatter.allow(
                    RegExp(r'^[a-zA-Z0-9_\-=@,\.; ]+$'))
          ],
          readOnly: readOnly,
          controller: controller,
          maxLines: maxLines,
          onTapOutside: (event) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
          ),
          onChanged: (value) {},
        ),
      ],
    );
  }
}
