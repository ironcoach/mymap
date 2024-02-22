import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(const ChatApp());

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChatMapScreen(),
    );
  }
}

class ChatMapScreen extends StatefulWidget {
  const ChatMapScreen({super.key});

  @override
  _ChatMapScreenState createState() => _ChatMapScreenState();
}

class _ChatMapScreenState extends State<ChatMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = <Marker>{};
  LatLngBounds? _currentBounds;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps with Dynamic Markers'),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          _updateMarkers(controller);
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(37.42796133580664, -122.085749655962),
          zoom: 12,
        ),
        markers: _markers,
        onCameraMove: (CameraPosition position) {
          _updateMarkersPosition();
        },
      ),
    );
  }

  void _updateMarkers(GoogleMapController controller) {
    final Set<Marker> newMarkers = <Marker>{};
    // Add your markers here
    newMarkers.add(
      const Marker(
        markerId: MarkerId('marker1'),
        position: LatLng(37.4219999, -122.0840575),
        infoWindow: InfoWindow(title: 'Marker 1'),
      ),
    );
    newMarkers.add(
      const Marker(
        markerId: MarkerId('marker2'),
        position: LatLng(37.42796133580664, -122.085749655962),
        infoWindow: InfoWindow(title: 'Marker 2'),
      ),
    );
    setState(() {
      _markers = newMarkers;
      _updateMarkersPosition();
    });
  }

  void _updateMarkersPosition() async {
    final GoogleMapController controller = await _controller.future;
    final LatLngBounds visibleBounds = await controller.getVisibleRegion();
    setState(() {
      _currentBounds = visibleBounds;
    });
    final Set<Marker> newMarkers = Set<Marker>.from(_markers.where(
      (marker) => visibleBounds.contains(marker.position),
    ));
    setState(() {
      _markers = newMarkers;
    });
  }
}
