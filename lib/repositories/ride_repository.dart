import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymap/models/ride_data.dart';

class RideRepository {
  static final RideRepository _instance = RideRepository._internal();
  factory RideRepository() => _instance;
  RideRepository._internal();

  final CollectionReference _ridesCollection =
      FirebaseFirestore.instance.collection('rides');

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Get all rides from Firestore
  Future<List<Ride>> getAllRides() async {
    try {
      final querySnapshot = await _ridesCollection.get();
      return querySnapshot.docs.map((doc) {
        return _mapDocumentToRide(doc);
      }).toList();
    } catch (e) {
      throw RideRepositoryException('Failed to fetch rides: $e');
    }
  }

  /// Get rides near a specific location
  Future<List<Ride>> getRidesNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
  }) async {
    try {
      // Note: For production, you'd want to use GeoFirestore for efficient geo queries
      // For now, we'll fetch all and filter client-side
      final allRides = await getAllRides();

      return allRides.where((ride) {
        if (ride.latlng == null) return false;

        final distance = _calculateDistance(
          latitude,
          longitude,
          ride.latlng!.latitude,
          ride.latlng!.longitude,
        );

        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw RideRepositoryException('Failed to fetch rides near location: $e');
    }
  }

  /// Get rides within a viewport (map bounds) - FORCE SERVER READ
  Future<List<Ride>> getRidesInViewport({
    required double northLat,
    required double southLat,
    required double eastLng,
    required double westLng,
  }) async {
    try {
      debugPrint('=== getRidesInViewport (FORCED SERVER READ) ===');
      debugPrint('Bounds: N:$northLat, S:$southLat, E:$eastLng, W:$westLng');

      // FORCE SERVER READ to avoid cached failed writes
      final querySnapshot = await _ridesCollection
          .where('latitude', isGreaterThanOrEqualTo: southLat)
          .where('latitude', isLessThanOrEqualTo: northLat)
          .get(const GetOptions(source: Source.server)); // FORCE SERVER

      debugPrint(
          'Server query returned ${querySnapshot.docs.length} documents');

      // Debug: Check document metadata
      for (var doc in querySnapshot.docs.take(3)) {
        debugPrint(
            'Doc ${doc.id}: fromCache=${doc.metadata.isFromCache}, pendingWrites=${doc.metadata.hasPendingWrites}');
      }

      // Filter by longitude client-side
      final ridesInViewport = querySnapshot.docs
          .map((doc) => _mapDocumentToRide(doc))
          .where((ride) {
        final lng = ride.longitude ?? ride.latlng?.longitude;
        if (lng == null) return false;

        if (westLng <= eastLng) {
          return lng >= westLng && lng <= eastLng;
        } else {
          return lng >= westLng || lng <= eastLng;
        }
      }).toList();

      debugPrint(
          'After longitude filtering: ${ridesInViewport.length} rides in viewport');
      return ridesInViewport;
    } catch (e) {
      debugPrint('Error in getRidesInViewport: $e');
      throw RideRepositoryException('Failed to fetch rides in viewport: $e');
    }
  }

  /// Add a new ride
  Future<String> addRide(Ride ride) async {
    try {
      debugPrint('Repository: Starting addRide for ride: ${ride.title}');

      // Check if user is authenticated
      if (currentUserId == null) {
        throw RideRepositoryException('User must be logged in to create rides');
      }

      final rideData = _mapRideToFirestore(ride);
      rideData['createdBy'] = currentUserId;
      rideData['createdAt'] = FieldValue.serverTimestamp();

      debugPrint('Repository: About to write to Firestore...');
      debugPrint('Repository: User ID: $currentUserId');
      debugPrint('Repository: Ride data keys: ${rideData.keys.toList()}');

      // REMOVE THE TIMEOUT - Let Firestore handle its own timeouts
      final docRef = await _ridesCollection.add(rideData);

      debugPrint(
          'Repository: ✅ SUCCESS - Document created with ID: ${docRef.id}');

      // Verify the document was actually written
      final verification = await docRef.get();
      if (!verification.exists) {
        throw RideRepositoryException('Document was not found after creation');
      }

      debugPrint('Repository: ✅ VERIFIED - Document exists in Firestore');
      return docRef.id;
    } catch (e) {
      debugPrint('Repository: ❌ FAILED to add ride: $e');
      debugPrint('Repository: Error type: ${e.runtimeType}');

      // Don't mask any errors - let them bubble up
      if (e is RideRepositoryException) {
        rethrow;
      }
      throw RideRepositoryException('Failed to add ride: $e');
    }
  }

  /// Update an existing ride
  Future<void> updateRide(String rideId, Ride ride) async {
    try {
      if (currentUserId == null) {
        throw RideRepositoryException('User must be logged in to update rides');
      }

      final rideData = _mapRideToFirestore(ride);
      rideData['updatedAt'] = FieldValue.serverTimestamp();
      rideData['updatedBy'] = currentUserId;

      await _ridesCollection.doc(rideId).update(rideData);
    } catch (e) {
      throw RideRepositoryException('Failed to update ride: $e');
    }
  }

  /// Delete a ride
  Future<void> deleteRide(String rideId) async {
    try {
      if (currentUserId == null) {
        throw RideRepositoryException('User must be logged in to delete rides');
      }

      // Check if user owns the ride or is admin
      final rideDoc = await _ridesCollection.doc(rideId).get();
      if (!rideDoc.exists) {
        throw RideRepositoryException('Ride not found');
      }

      final rideData = rideDoc.data() as Map<String, dynamic>;
      if (rideData['createdBy'] != currentUserId) {
        throw RideRepositoryException('You can only delete your own rides');
      }

      await _ridesCollection.doc(rideId).delete();
    } catch (e) {
      throw RideRepositoryException('Failed to delete ride: $e');
    }
  }

  /// Get a single ride by ID
  Future<Ride?> getRideById(String rideId) async {
    try {
      final doc = await _ridesCollection.doc(rideId).get();
      if (!doc.exists) return null;

      return _mapDocumentToRide(doc);
    } catch (e) {
      throw RideRepositoryException('Failed to fetch ride: $e');
    }
  }

  /// Add multiple rides (for sample data)
  Future<String?> addMultipleRides(List<Ride> rides) async {
    try {
      if (currentUserId == null) {
        throw RideRepositoryException('User must be logged in');
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final ride in rides) {
        final docRef = _ridesCollection.doc();
        final rideData = _mapRideToFirestore(ride);
        rideData['createdBy'] = currentUserId;
        rideData['createdAt'] = FieldValue.serverTimestamp();

        batch.set(docRef, rideData);
      }

      await batch.commit();
      return null; // Success
    } catch (e) {
      return 'Failed to add rides: $e';
    }
  }

  /// Get user's rides
  Future<List<Ride>> getUserRides() async {
    try {
      if (currentUserId == null) return [];

      final querySnapshot = await _ridesCollection
          .where('createdBy', isEqualTo: currentUserId)
          .get();

      return querySnapshot.docs.map((doc) {
        return _mapDocumentToRide(doc);
      }).toList();
    } catch (e) {
      throw RideRepositoryException('Failed to fetch user rides: $e');
    }
  }

  /// Rate a ride (1-5 stars)
  Future<void> rateRide(String rideId, int rating) async {
    try {
      if (currentUserId == null) {
        throw RideRepositoryException('User must be logged in to rate rides');
      }

      if (rating < 1 || rating > 5) {
        throw RideRepositoryException('Rating must be between 1 and 5');
      }

      await _ridesCollection.doc(rideId).update({
        'userRatings.$currentUserId': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recalculate average rating
      await _recalculateRideRating(rideId);
    } catch (e) {
      throw RideRepositoryException('Failed to rate ride: $e');
    }
  }

  /// Remove a user's rating from a ride
  Future<void> removeUserRating(String rideId) async {
    try {
      if (currentUserId == null) {
        throw RideRepositoryException(
            'User must be logged in to remove ratings');
      }

      await _ridesCollection.doc(rideId).update({
        'userRatings.$currentUserId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recalculate average rating
      await _recalculateRideRating(rideId);
    } catch (e) {
      throw RideRepositoryException('Failed to remove rating: $e');
    }
  }

  /// Verify a ride
  Future<void> verifyRide(String rideId) async {
    try {
      if (currentUserId == null) {
        throw RideRepositoryException('User must be logged in to verify rides');
      }

      await _ridesCollection.doc(rideId).update({
        'verifiedByUsers': FieldValue.arrayUnion([currentUserId]),
        'verificationCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw RideRepositoryException('Failed to verify ride: $e');
    }
  }

  /// Remove verification from a ride
  Future<void> removeVerification(String rideId) async {
    try {
      if (currentUserId == null) {
        throw RideRepositoryException(
            'User must be logged in to remove verification');
      }

      await _ridesCollection.doc(rideId).update({
        'verifiedByUsers': FieldValue.arrayRemove([currentUserId]),
        'verificationCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw RideRepositoryException('Failed to remove verification: $e');
    }
  }

  /// Private method to recalculate ride rating
  Future<void> _recalculateRideRating(String rideId) async {
    final doc = await _ridesCollection.doc(rideId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final userRatings = data['userRatings'] as Map<String, dynamic>? ?? {};

    if (userRatings.isEmpty) {
      await _ridesCollection.doc(rideId).update({
        'averageRating': null,
        'totalRatings': 0,
      });
      return;
    }

    final ratings = userRatings.values.map((v) => (v as num).toInt()).toList();
    final totalRatings = ratings.length;
    final averageRating = ratings.reduce((a, b) => a + b) / totalRatings;

    await _ridesCollection.doc(rideId).update({
      'averageRating': averageRating,
      'totalRatings': totalRatings,
    });
  }

  // Helper method to convert Firestore document to Ride model
  Ride _mapDocumentToRide(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    GeoPoint? geoPoint = data['latlng'];
    DateTime? startTime = data['startTime']?.toDate();

    return Ride(
      id: doc.id, // Use Firestore document ID instead of stored ID
      title: data['title'],
      desc: data['desc'],
      snippet: data['snippet'],
      dow: data['dow'] != null ? DayOfWeekType.values[data['dow']] : null,
      startTime: startTime,
      startPointDesc: data['startPointDesc'],
      contact: data['contactName'],
      phone: data['contactPhone'],
      latlng: geoPoint != null
          ? LatLng(geoPoint.latitude, geoPoint.longitude)
          : null,
      verified: data['verified'] ?? false,
      verifiedBy: data['verifiedBy'],
      createdBy: data['createdBy'],
      rideType: data['rideType'] != null
          ? RideType.values[data['rideType']]
          : RideType.roadRide,
      rideDistance: data['distance'],
      // Separate latitude and longitude fields
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      // New fields
      verifiedByUsers: data['verifiedByUsers'] != null
          ? List<String>.from(data['verifiedByUsers'])
          : [],
      verificationCount: data['verificationCount'] ?? 0,
      averageRating: data['averageRating']?.toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      userRatings: data['userRatings'] != null
          ? Map<String, int>.from(data['userRatings'])
          : {},
      routeUrl: data['routeUrl'],
      difficulty: data['difficulty'] != null
          ? RideDifficulty.values[data['difficulty']]
          : null,
    );
  }

  // Helper method to convert Ride model to Firestore data
  Map<String, dynamic> _mapRideToFirestore(Ride ride) {
    // If latitude and longitude are provided, use them; otherwise extract from latlng
    double? latitude = ride.latitude ?? ride.latlng?.latitude;
    double? longitude = ride.longitude ?? ride.latlng?.longitude;

    return {
      'id': ride.id,
      'title': ride.title,
      'desc': ride.desc,
      'snippet': ride.snippet,
      'dow': ride.dow?.index,
      'startTime': ride.startTime,
      'startPointDesc': ride.startPointDesc,
      'contactName': ride.contact,
      'contactPhone': ride.phone,
      'latlng': ride.latlng != null
          ? GeoPoint(ride.latlng!.latitude, ride.latlng!.longitude)
          : null,
      'verified': ride.verified ?? false,
      'verifiedBy': ride.verifiedBy,
      'rideType': ride.rideType?.index,
      'distance': ride.rideDistance,
      // Separate latitude and longitude fields for efficient querying
      'latitude': latitude,
      'longitude': longitude,
      // New fields
      'verifiedByUsers': ride.verifiedByUsers ?? [],
      'verificationCount': ride.verificationCount ?? 0,
      'averageRating': ride.averageRating,
      'totalRatings': ride.totalRatings ?? 0,
      'userRatings': ride.userRatings ?? {},
      'routeUrl': ride.routeUrl,
      'difficulty': ride.difficulty?.index,
    };
  }

  // Helper method to calculate distance between two points (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

class RideRepositoryException implements Exception {
  final String message;
  RideRepositoryException(this.message);

  @override
  String toString() => 'RideRepositoryException: $message';
}
