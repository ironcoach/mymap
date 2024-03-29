import 'package:flutter/material.dart';

class WebBody extends StatelessWidget {
  const WebBody({super.key});

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
                    'assets/images/SuzyBike1Crop.jpg',
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
                  color: Colors.green[300],
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text('Find your Ride'),
                        Text('Login'),
                      ],
                    ),
                  ),
                )),
                const Positioned(
                  top: 100,
                  left: 100,
                  child: Center(
                    child: Text(
                      'Your App Content',
                      style: TextStyle(color: Colors.white),
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

  Widget backgroudImage(String imageFile) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.black, Colors.black12],
        begin: Alignment.bottomCenter,
        end: Alignment.center,
      ).createShader(bounds),
      blendMode: BlendMode.darken,
      child: Container(
        // height: 300,
        // width: 300,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imageFile),

            /// change this to your  image directory
            fit: BoxFit.cover,
            colorFilter:
                const ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
        ),
      ),
    );
  }
}
