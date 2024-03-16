// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:location/location.dart';
// //import 'package:intl/intl.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class TestPage extends StatefulWidget {
//   const TestPage({super.key});

//   @override
//   _TestPageState createState() => _TestPageState();
// }

// class _TestPageState extends State<TestPage> {
//   LocationData _currentPosition = LocationData();

//   late GoogleMapController mapController;
//   late Marker marker;
//   Location location = Location();

//   late GoogleMapController _controller;
//   LatLng _initialcameraposition = const LatLng(0.5937, 0.9629);

//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     getLoc();
//   }

//   void _onMapCreated(GoogleMapController cntlr) {
//     _controller = _controller;
//     location.onLocationChanged.listen((l) {
//       _controller.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(target: LatLng(l.latitude!, l.longitude!), zoom: 15),
//         ),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           image: DecorationImage(
//               image: AssetImage('assets/images/bg.jpg'), fit: BoxFit.cover),
//         ),
//         height: MediaQuery.of(context).size.height,
//         width: MediaQuery.of(context).size.width,
//         child: SafeArea(
//           child: Container(
//             color: Colors.blueGrey.withOpacity(.8),
//             child: Center(
//               child: Column(
//                 children: [
//                   SizedBox(
//                     height: MediaQuery.of(context).size.height / 2.5,
//                     width: MediaQuery.of(context).size.width,
//                     child: GoogleMap(
//                       initialCameraPosition: CameraPosition(
//                           target: _initialcameraposition, zoom: 15),
//                       mapType: MapType.normal,
//                       onMapCreated: _onMapCreated,
//                       myLocationEnabled: true,
//                     ),
//                   ),
//                   const SizedBox(
//                     height: 3,
//                   ),
//                   Text(
//                     "Latitude: ${_currentPosition.latitude}, Longitude: ${_currentPosition.longitude}",
//                     style: const TextStyle(
//                         fontSize: 22,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   getLoc() async {
//     bool serviceEnabled;
//     PermissionStatus permissionGranted;

//     serviceEnabled = await location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await location.requestService();
//       if (!serviceEnabled) {
//         return;
//       }
//     }

//     permissionGranted = await location.hasPermission();
//     if (permissionGranted == PermissionStatus.denied) {
//       permissionGranted = await location.requestPermission();
//       if (permissionGranted != PermissionStatus.granted) {
//         return;
//       }
//     }

//     _currentPosition = await location.getLocation();
//     _initialcameraposition =
//         LatLng(_currentPosition.latitude!, _currentPosition.longitude!);
//     location.onLocationChanged.listen((LocationData currentLocation) {
//       print("${currentLocation.longitude} : ${currentLocation.longitude}");
//       setState(() {
//         _currentPosition = currentLocation;
//         _initialcameraposition =
//             LatLng(_currentPosition.latitude!, _currentPosition.longitude!);
//       });
//     });
//   }
// }
