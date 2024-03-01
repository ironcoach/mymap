import 'package:flutter/material.dart';

class DrawBanner extends StatelessWidget {
  const DrawBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(200.0),
          child: Image.asset(
            fit: BoxFit.fitHeight,
            "assets/images/ridebikes.jpg",
            height: 200,
          ),
        ),
        const Positioned(
          left: 60,
          top: 10,
          child: Text(
            'Find My Ride',
            style: TextStyle(
              fontSize: 30,
            ),
          ),
        ),
      ],
    );
  }
}
