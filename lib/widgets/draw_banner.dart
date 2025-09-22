import 'package:flutter/material.dart';

class DrawBanner extends StatelessWidget {
  const DrawBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipOval(
          child: SizedBox(
            height: 200,
            width: 350, // Wider than height for horizontal oval
            child: Image.asset(
              "assets/images/RideBikes2.jpg",
              fit: BoxFit.cover, // Changed to cover for better fill
            ),
          ),
        ),
        // ClipRRect(
        //   borderRadius: BorderRadius.horizontal(
        //       right: Radius.circular(40), left: Radius.circular(40)),
        //   child: Image.asset(
        //     fit: BoxFit.fitHeight,
        //     "assets/images/RideBikes2.jpg",
        //     height: 300,
        //   ),
        // ),
        // const Positioned(
        //   left: 60,
        //   top: 10,
        //   child: Text(
        //     'Find My Ride',
        //     style: TextStyle(
        //       fontSize: 30,
        //     ),
        //   ),
        // ),
        const Positioned(
          left: 80,
          top: 10,
          child: Text(
            'Find My Ride',
            style: TextStyle(
              fontSize: 30,
              color: Colors.white, // Add color for better visibility
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
