import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymap/models/ride_data.dart';

class MapMarkerService {
  static final MapMarkerService _instance = MapMarkerService._internal();
  factory MapMarkerService() => _instance;
  MapMarkerService._internal();

  // Cache for marker icons to avoid reloading
  final Map<RideType, BitmapDescriptor> _markerCache = {};
  bool _markersInitialized = false;

  // Asset paths for different ride types
  static const Map<RideType, String> _markerAssets = {
    RideType.gravelRide: 'assets/mapicons/bikeRising.png',
    RideType.roadRide: 'assets/mapicons/roadRide.png',
    RideType.mtbRide: 'assets/mapicons/greenBike.png',
    RideType.bikeEvent: 'assets/mapicons/blueRide.png',
  };

  /// Initialize marker icons (call once at app startup)
  Future<void> initializeMarkers() async {
    if (_markersInitialized) return;

    try {
      final futures = _markerAssets.entries.map((entry) async {
        final descriptor = await BitmapDescriptor.asset(
          const ImageConfiguration(devicePixelRatio: 1.0),
          entry.value,
        );
        _markerCache[entry.key] = descriptor;
      });

      await Future.wait(futures);
      _markersInitialized = true;
    } catch (e) {
      throw MarkerServiceException('Failed to initialize markers: $e');
    }
  }

  /// Get marker icon for a specific ride type
  BitmapDescriptor? getMarkerIcon(RideType rideType) {
    if (!_markersInitialized) {
      throw MarkerServiceException(
        'Markers not initialized. Call initializeMarkers() first.'
      );
    }
    return _markerCache[rideType];
  }

  /// Create a single marker from ride data
  Marker? createMarker(Ride ride, String markerId, {VoidCallback? onTap}) {
    try {
      // Validate required data
      if (ride.latlng == null) {
        return null;
      }

      final rideType = ride.rideType ?? RideType.roadRide;
      final markerIcon = getMarkerIcon(rideType);
      
      if (markerIcon == null) {
        throw MarkerServiceException('No marker icon found for ride type: $rideType');
      }

      return Marker(
        markerId: MarkerId(markerId),
        position: ride.latlng!,
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: ride.title ?? 'Untitled Ride',
          snippet: _buildEnhancedSnippet(ride),
          onTap: onTap,
        ),
      );
    } catch (e) {
      throw MarkerServiceException('Failed to create marker: $e');
    }
  }

  /// Create multiple markers from a list of rides
  Future<Set<Marker>> createMarkersFromRides(
    List<Ride> rides, {
    Function(String rideId)? onMarkerTap,
  }) async {
    if (!_markersInitialized) {
      await initializeMarkers();
    }

    final markers = <Marker>{};
    
    for (int i = 0; i < rides.length; i++) {
      final ride = rides[i];
      final markerId = ride.id?.toString() ?? 'marker_$i';
      
      final marker = createMarker(
        ride,
        markerId,
        onTap: onMarkerTap != null ? () => onMarkerTap(markerId) : null,
      );
      
      if (marker != null) {
        markers.add(marker);
      }
    }

    return markers;
  }

  /// Filter markers that are visible in the current map bounds
  Set<Marker> filterMarkersInBounds(
    Set<Marker> allMarkers, 
    LatLngBounds bounds
  ) {
    return allMarkers.where((marker) => bounds.contains(marker.position)).toSet();
  }

  /// Create custom marker from network image (for user avatars, etc.)
  Future<BitmapDescriptor> createMarkerFromUrl(
    String imageUrl, {
    int size = 100,
  }) async {
    try {
      final bytes = await _getBytesFromUrl(imageUrl, size);
      return BitmapDescriptor.bytes(bytes);
    } catch (e) {
      throw MarkerServiceException('Failed to create marker from URL: $e');
    }
  }

  /// Create custom marker from asset with specific size
  Future<BitmapDescriptor> createMarkerFromAsset(
    String assetPath, {
    int size = 100,
  }) async {
    try {
      final bytes = await _getBytesFromAsset(assetPath, size);
      return BitmapDescriptor.bytes(bytes);
    } catch (e) {
      throw MarkerServiceException('Failed to create marker from asset: $e');
    }
  }

  /// Update marker icon for a specific ride type
  Future<void> updateMarkerIcon(RideType rideType, String assetPath) async {
    try {
      final descriptor = await BitmapDescriptor.asset(
        const ImageConfiguration(devicePixelRatio: 1.0),
        assetPath,
      );
      _markerCache[rideType] = descriptor;
    } catch (e) {
      throw MarkerServiceException('Failed to update marker icon: $e');
    }
  }

  /// Clear marker cache (useful for memory management)
  void clearCache() {
    _markerCache.clear();
    _markersInitialized = false;
  }

  /// Get statistics about cached markers
  Map<String, dynamic> getCacheStats() {
    return {
      'initialized': _markersInitialized,
      'cached_markers': _markerCache.length,
      'cache_size_kb': _estimateCacheSize(),
    };
  }

  // Helper method to get bytes from network image
  Future<Uint8List> _getBytesFromUrl(String url, int size) async {
    // This would typically use http package to fetch image
    // For now, throwing not implemented
    throw UnimplementedError('Network image loading not implemented');
  }

  // Helper method to get bytes from asset
  Future<Uint8List> _getBytesFromAsset(String assetPath, int size) async {
    final data = await rootBundle.load(assetPath);
    // Would typically resize image here using image processing package
    return data.buffer.asUint8List();
  }

  // Estimate cache size in KB (rough approximation)
  int _estimateCacheSize() {
    // Each marker is approximately 10-50KB depending on image size
    return _markerCache.length * 30; // Rough estimate of 30KB per marker
  }

  /// Build enhanced snippet with quality indicators for InfoWindow
  String _buildEnhancedSnippet(Ride ride) {
    final parts = <String>[];

    // Add original snippet if available
    if (ride.snippet?.isNotEmpty == true) {
      parts.add(ride.snippet!);
    }

    // Add difficulty if available
    if (ride.difficulty != null) {
      parts.add('${ride.difficulty!.titleName} difficulty');
    }

    // Add rating info if available
    if (ride.averageRating != null && ride.averageRating! > 0) {
      final stars = '★' * ride.averageRating!.round();
      final emptyStars = '☆' * (5 - ride.averageRating!.round());
      parts.add('$stars$emptyStars (${ride.totalRatings ?? 0})');
    }

    // Add verification info if available
    final verificationCount = ride.verificationCount ?? 0;
    if (verificationCount > 0) {
      parts.add('✓ Verified by $verificationCount user${verificationCount == 1 ? '' : 's'}');
    }

    // Add distance if available
    if (ride.rideDistance != null && ride.rideDistance! > 0) {
      parts.add('${ride.rideDistance} miles');
    }

    return parts.join(' • ');
  }

  /// Check if markers are initialized
  bool get isInitialized => _markersInitialized;

  /// Get available ride types
  static List<RideType> get availableRideTypes => _markerAssets.keys.toList();

  /// Get asset path for ride type
  static String? getAssetPath(RideType rideType) => _markerAssets[rideType];
}

/// Custom exception for marker service operations
class MarkerServiceException implements Exception {
  final String message;
  MarkerServiceException(this.message);

  @override
  String toString() => 'MarkerServiceException: $message';
}

/// Configuration for marker appearance
class MarkerConfig {
  final double size;
  final double alpha;
  final bool showInfoWindow;
  final Duration animationDuration;

  const MarkerConfig({
    this.size = 1.0,
    this.alpha = 1.0,
    this.showInfoWindow = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  MarkerConfig copyWith({
    double? size,
    double? alpha,
    bool? showInfoWindow,
    Duration? animationDuration,
  }) {
    return MarkerConfig(
      size: size ?? this.size,
      alpha: alpha ?? this.alpha,
      showInfoWindow: showInfoWindow ?? this.showInfoWindow,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }
}