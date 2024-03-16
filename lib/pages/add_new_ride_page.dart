import 'package:flutter/material.dart';
import 'package:mymap/constants/constants.dart';

class AddNewRide extends StatelessWidget {
  const AddNewRide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50.0,
        centerTitle: false,
        title: const Text(appTitle),
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            Text("Start of Add a Ride"),
          ],
        ),
      ),
    );
  }
}
