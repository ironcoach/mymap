import 'package:flutter/material.dart';
import 'package:mymap/utils/extensions.dart';

class EditBox extends StatelessWidget {
  final String text;
  final String sectionName;
  final void Function()? onPressed;

  const EditBox(
      {super.key,
      required this.text,
      required this.sectionName,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.onInverseSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.only(
        left: 15.0,
        bottom: 10.0,
      ),
      margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                  onPressed: onPressed, icon: const Icon(Icons.settings)),
            ],
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
