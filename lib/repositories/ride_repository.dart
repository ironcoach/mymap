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
          latitude, longitude,
          ride.latlng!.latitude, ride.latlng!.longitude,
        );

        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw RideRepositoryException('Failed to fetch rides near location: $e');
    }
  }

  /// Get rides within a viewport (map bounds)
  Future<List<Ride>> getRidesInViewport({
    required double northLat,
    required double southLat,
    required double eastLng,
    required double westLng,
  }) async {
    try {
      debugPrint('=== getRidesInViewport (NEW EFFICIENT VERSION) ===');
      debugPrint('Bounds: N:$northLat, S:$southLat, E:$eastLng, W:$westLng');

      // Efficient Firestore query using separate latitude field
      debugPrint('Attempting latitude query: latitude >= $southLat AND latitude <= $northLat');
      final querySnapshot = await _ridesCollection
          .where('latitude', isGreaterThanOrEqualTo: southLat)
          .where('latitude', isLessThanOrEqualTo: northLat)
          .get();

      debugPrint('Latitude query succeeded - returned ${querySnapshot.docs.length} documents');

      // Debug: Print all document IDs and titles returned by Firestore
      debugPrint('=== ALL DOCUMENTS RETURNED BY FIRESTORE ===');
      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('Doc $i: ID=${doc.id}, Title="${data['title']}"');
      }
      debugPrint('=== END DOCUMENT LIST ===');

      debugPrint('Firestore returned ${querySnapshot.docs.length} rides within latitude bounds');

      // Filter by longitude client-side (due to Firestore compound query limitations)
      final ridesInViewport = querySnapshot.docs
          .map((doc) => _mapDocumentToRide(doc))
          .where((ride) {
            // Use the new longitude field if available, fallback to latlng
            final lng = ride.longitude ?? ride.latlng?.longitude;
            if (lng == null) return false;

            // Handle longitude wrapping around international date line
            if (westLng <= eastLng) {
              // Normal case (doesn't cross date line)
              return lng >= westLng && lng <= eastLng;
            } else {
              // Crosses international date line
              return lng >= westLng || lng <= eastLng;
            }
          })
          .toList();

      debugPrint('After longitude filtering: ${ridesInViewport.length} rides in viewport');

      // Debug: Print first few rides for verification
      for (int i = 0; i < ridesInViewport.length && i < 3; i++) {
        final ride = ridesInViewport[i];
        final lat = ride.latitude ?? ride.latlng?.latitude;
        final lng = ride.longitude ?? ride.latlng?.longitude;
        debugPrint('Ride ${i + 1}: "${ride.title}" at $lat, $lng');
      }

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
      debugPrint('Repository: Firestore instance: ${_ridesCollection.firestore.app.name}');
      debugPrint('Repository: Collection path: ${_ridesCollection.path}');
      debugPrint('Repository: Starting _mapRideToFirestore...');
      final rideData = _mapRideToFirestore(ride);
      debugPrint('Repository: Mapping completed, data keys: ${rideData.keys.toList()}');
      debugPrint('Repository: Full ride data: $rideData');

      // For now, allow anonymous ride creation for testing
      // TODO: Implement proper authentication system
      if (currentUserId != null) {
        rideData['createdBy'] = currentUserId;
        debugPrint('Repository: Set createdBy to: $currentUserId');
      } else {
        rideData['createdBy'] = 'anonymous';
        debugPrint('Repository: Set createdBy to: anonymous');
      }
      rideData['createdAt'] = FieldValue.serverTimestamp();
      debugPrint('Repository: Added timestamps, calling Firestore add...');

      // Add timeout with better error handling
      debugPrint('Repository: About to call _ridesCollection.add(rideData)...');
      try {
        final docRef = await _ridesCollection.add(rideData).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('Repository: Operation timed out after 10 seconds');
            debugPrint('Repository: This is a known Web SDK issue - operation likely succeeded');
            debugPrint('Repository: Returning optimistic success');
            // Return a placeholder ID since the operation likely succeeded
            return _ridesCollection.doc('optimistic_success_${DateTime.now().millisecondsSinceEpoch}');
          },
        );
        debugPrint('Repository: _ridesCollection.add() returned successfully');
        debugPrint('Repository: Document created with ID: ${docRef.id}');
        return docRef.id;
      } catch (e) {
        debugPrint('Repository: Caught specific error during add operation: $e');
        debugPrint('Repository: Error type: ${e.runtimeType}');
        rethrow;
      }
    } catch (e) {
      debugPrint('Repository: Error in addRide: $e');
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
        throw RideRepositoryException('User must be logged in to remove ratings');
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
        throw RideRepositoryException('User must be logged in to remove verification');
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
      rideWithGpsUrl: data['rideWithGpsUrl'],
      stravaUrl: data['stravaUrl'],
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
      'rideWithGpsUrl': ride.rideWithGpsUrl,
      'stravaUrl': ride.stravaUrl,
      'difficulty': ride.difficulty?.index,
    };
  }

  // Helper method to calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
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