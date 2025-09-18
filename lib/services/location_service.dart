import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const LatLng _defaultPosition = LatLng(40.017555, -105.258336); // Boulder, CO
  static const double _defaultZoom = 10.5;

  /// Get current location with comprehensive error handling
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error(
          'Location services are disabled. Please enable location services in your device settings.',
          fallbackPosition: _defaultPosition,
        );
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      // Handle denied permissions
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.error(
            'Location permissions are denied. Please enable location access in your device settings.',
            fallbackPosition: _defaultPosition,
          );
        }
      }

      // Handle permanently denied permissions
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error(
          'Location permissions are permanently denied. Please enable location access in your device settings.',
          fallbackPosition: _defaultPosition,
        );
      }

      // Get current position with timeout and accuracy settings
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Only update if moved 10 meters
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw LocationServiceTimeoutException('Location request timed out');
        },
      );

      return LocationResult.success(
        LatLng(position.latitude, position.longitude),
        accuracy: position.accuracy,
      );

    } on LocationServiceTimeoutException catch (e) {
      return LocationResult.error(
        'Location request timed out. Using default location.',
        fallbackPosition: _defaultPosition,
        originalError: e,
      );
    } catch (e) {
      return LocationResult.error(
        'Failed to get location: ${e.toString()}',
        fallbackPosition: _defaultPosition,
        originalError: e,
      );
    }
  }

  /// Get camera position from location result
  CameraPosition getCameraPosition(LocationResult result, {double? zoom}) {
    return CameraPosition(
      target: result.position,
      zoom: zoom ?? _defaultZoom,
    );
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Request location permissions
  Future<LocationPermissionResult> requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      
      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationPermissionResult.granted();
          
        case LocationPermission.denied:
          return LocationPermissionResult.denied(
            'Location access denied. Some features may not work properly.'
          );
          
        case LocationPermission.deniedForever:
          return LocationPermissionResult.permanentlyDenied(
            'Location access permanently denied. Please enable it in device settings.'
          );
          
        case LocationPermission.unableToDetermine:
          return LocationPermissionResult.error(
            'Unable to determine location permission status.'
          );
      }
    } catch (e) {
      return LocationPermissionResult.error(
        'Failed to request location permission: ${e.toString()}'
      );
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    ) / 1000; // Convert meters to kilometers
  }

  /// Check if location services are available
  Future<bool> isLocationServiceAvailable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Get default position for fallback
  static LatLng get defaultPosition => _defaultPosition;
  static double get defaultZoom => _defaultZoom;
}

/// Result wrapper for location operations
class LocationResult {
  final LatLng position;
  final bool isSuccess;
  final String? errorMessage;
  final double? accuracy;
  final Object? originalError;

  const LocationResult._({
    required this.position,
    required this.isSuccess,
    this.errorMessage,
    this.accuracy,
    this.originalError,
  });

  factory LocationResult.success(LatLng position, {double? accuracy}) {
    return LocationResult._(
      position: position,
      isSuccess: true,
      accuracy: accuracy,
    );
  }

  factory LocationResult.error(
    String message, {
    required LatLng fallbackPosition,
    Object? originalError,
  }) {
    return LocationResult._(
      position: fallbackPosition,
      isSuccess: false,
      errorMessage: message,
      originalError: originalError,
    );
  }

  bool get hasError => !isSuccess;
  bool get isAccurate => accuracy != null && accuracy! < 100; // Within 100 meters
}

/// Result wrapper for permission operations
class LocationPermissionResult {
  final bool isGranted;
  final String? message;
  final LocationPermissionStatus status;

  const LocationPermissionResult._({
    required this.isGranted,
    required this.status,
    this.message,
  });

  factory LocationPermissionResult.granted() {
    return const LocationPermissionResult._(
      isGranted: true,
      status: LocationPermissionStatus.granted,
    );
  }

  factory LocationPermissionResult.denied(String message) {
    return LocationPermissionResult._(
      isGranted: false,
      status: LocationPermissionStatus.denied,
      message: message,
    );
  }

  factory LocationPermissionResult.permanentlyDenied(String message) {
    return LocationPermissionResult._(
      isGranted: false,
      status: LocationPermissionStatus.permanentlyDenied,
      message: message,
    );
  }

  factory LocationPermissionResult.error(String message) {
    return LocationPermissionResult._(
      isGranted: false,
      status: LocationPermissionStatus.error,
      message: message,
    );
  }
}

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  error,
}

/// Custom exception for location service timeouts
class LocationServiceTimeoutException implements Exception {
  final String message;
  LocationServiceTimeoutException(this.message);

  @override
  String toString() => 'LocationServiceTimeoutException: $message';
}