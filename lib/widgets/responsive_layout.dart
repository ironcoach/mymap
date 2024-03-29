import 'package:flutter/material.dart';
import 'package:mymap/constants/constants.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget webBody;

  const ResponsiveLayout(
      {super.key, required this.mobileBody, required this.webBody});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileWidth) {
          return mobileBody;
        } else {
          return webBody;
        }
      },
    );
  }
}
