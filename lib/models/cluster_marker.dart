import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:mymap/models/ride_data.dart';

/// A cluster item implementation for ride markers
class ClusterRideMarker with ClusterItem {
  final String id;
  @override
  final LatLng location;
  final String title;
  final String snippet;
  final RideType rideType;

  ClusterRideMarker({
    required this.id,
    required this.location,
    required this.title,
    required this.snippet,
    required this.rideType,
  });


  @override
  String toString() {
    return 'ClusterRideMarker{id: $id, title: $title, location: $location, type: $rideType}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClusterRideMarker && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Create a ClusterRideMarker from a Ride object
  factory ClusterRideMarker.fromRide(Ride ride, {required String id}) {
    return ClusterRideMarker(
      id: id,
      location: ride.latlng!,
      title: ride.title ?? 'Untitled Ride',
      snippet: ride.snippet ?? '',
      rideType: ride.rideType ?? RideType.roadRide,
    );
  }

  /// Create multiple ClusterRideMarker objects from a list of rides
  static List<ClusterRideMarker> fromRides(List<Ride> rides) {
    debugPrint('🎯 === ClusterRideMarker.fromRides() STARTED ===');
    debugPrint('🎯 Input: ${rides.length} rides to process');

    final validRides = <Ride>[];
    final invalidRides = <String>[];

    // Check each ride for required data
    for (int i = 0; i < rides.length; i++) {
      final ride = rides[i];
      if (ride.latlng != null && ride.id != null) {
        validRides.add(ride);
        debugPrint('🎯 ✅ Ride $i: Valid - ${ride.title} (${ride.id}) at ${ride.latlng}');
      } else {
        final reason = ride.latlng == null ? 'no latlng' : 'no id';
        invalidRides.add('Ride $i: ${ride.title} - $reason');
        debugPrint('🎯 ❌ Ride $i: Invalid - ${ride.title} ($reason)');
      }
    }

    debugPrint('🎯 Valid rides: ${validRides.length}/${rides.length}');
    if (invalidRides.isNotEmpty) {
      debugPrint('🎯 Invalid rides: ${invalidRides.join(', ')}');
    }

    final clusterMarkers = validRides
        .map((ride) {
          final marker = ClusterRideMarker.fromRide(ride, id: ride.id!);
          debugPrint('🎯 Created marker: ${marker.id} - ${marker.title} at ${marker.location}');
          return marker;
        })
        .toList();

    debugPrint('🎯 Output: ${clusterMarkers.length} cluster markers created');
    debugPrint('🎯 === ClusterRideMarker.fromRides() COMPLETED ===');
    return clusterMarkers;
  }
}