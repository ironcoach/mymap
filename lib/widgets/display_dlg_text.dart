import 'package:flutter/material.dart';

class DisplayDlgText extends StatelessWidget {
  const DisplayDlgText({
    Key? key,
    this.topic,
    required this.text,
  }) : super(key: key);

  final String text;
  final String? topic;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(
            text: topic != null ? '$topic: ' : "",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: text,
            //style: TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
