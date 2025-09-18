import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mymap/models/ride_data.dart';

class FireStoreService {
  // Get Collection of Rides
  final CollectionReference ridesData =
      FirebaseFirestore.instance.collection('rides');

  // Custom exception for Firestore operations
  static const String _genericErrorMessage = 'An error occurred. Please try again.';

  // Create a ride
  Future<String?> addRide(Ride ride) async {
    try {
      if (ride.latlng == null || ride.dow == null || ride.rideType == null) {
        return 'Invalid ride data provided';
      }
      
      await ridesData.add({
        'contactName': ride.contact ?? '',
        'contactPhone': ride.phone ?? '',
        'desc': ride.desc ?? '',
        'dow': ride.dow!.index,
        'startTime': ride.startTime ?? DateTime.now(),
        'distance': ride.rideDistance ?? 0,
        'latlng': GeoPoint(ride.latlng!.latitude, ride.latlng!.longitude),
        'snippet': ride.snippet ?? '',
        'startPointDesc': ride.startPointDesc ?? '',
        'title': ride.title ?? '',
        'createOn': Timestamp.now(),
        'verified': ride.verified ?? false,
        'verifiedBy': ride.verifiedBy ?? '',
        'createdBy': ride.createdBy ?? '',
        'rideType': ride.rideType!.index,
      });
      return null; // Success
    } on FirebaseException catch (e) {
      debugPrint('Firebase error adding ride: ${e.message}');
      return e.message ?? _genericErrorMessage;
    } catch (e) {
      debugPrint('Error adding ride: $e');
      return _genericErrorMessage;
    }
  }

  // Read rides
  Stream<QuerySnapshot> getRidesStream() {
    try {
      return ridesData.orderBy('createOn', descending: true).snapshots();
    } catch (e) {
      debugPrint('Error getting rides stream: $e');
      // Return empty stream on error
      return const Stream.empty();
    }
  }

  // Get all rides with error handling
  Future<(List<QueryDocumentSnapshot>?, String?)> getAllRides() async {
    try {
      final querySnapshot = await ridesData.get();
      return (querySnapshot.docs, null);
    } on FirebaseException catch (e) {
      debugPrint('Firebase error getting rides: ${e.message}');
      return (null, e.message ?? _genericErrorMessage);
    } catch (e) {
      debugPrint('Error getting rides: $e');
      return (null, _genericErrorMessage);
    }
  }

  // Get single ride with error handling
  Future<(DocumentSnapshot?, String?)> getRide(String docID) async {
    try {
      final doc = await ridesData.doc(docID).get();
      return (doc, null);
    } on FirebaseException catch (e) {
      debugPrint('Firebase error getting ride: ${e.message}');
      return (null, e.message ?? _genericErrorMessage);
    } catch (e) {
      debugPrint('Error getting ride: $e');
      return (null, _genericErrorMessage);
    }
  }

  // Update a ride
  Future<String?> updateRide(String docID, Ride ride) async {
    try {
      if (docID.isEmpty || ride.latlng == null || ride.dow == null || ride.rideType == null) {
        return 'Invalid ride data provided';
      }
      
      await ridesData.doc(docID).update({
        'contactName': ride.contact ?? '',
        'contactPhone': ride.phone ?? '',
        'desc': ride.desc ?? '',
        'dow': ride.dow!.index,
        'startTime': ride.startTime ?? DateTime.now(),
        'distance': ride.rideDistance ?? 0,
        'latlng': GeoPoint(ride.latlng!.latitude, ride.latlng!.longitude),
        'snippet': ride.snippet ?? '',
        'startPointDesc': ride.startPointDesc ?? '',
        'title': ride.title ?? '',
        'updateOn': Timestamp.now(),
        'verified': ride.verified ?? false,
        'verifiedBy': ride.verifiedBy ?? '',
        'createdBy': ride.createdBy ?? '',
        'rideType': ride.rideType!.index,
      });
      return null; // Success
    } on FirebaseException catch (e) {
      debugPrint('Firebase error updating ride: ${e.message}');
      return e.message ?? _genericErrorMessage;
    } catch (e) {
      debugPrint('Error updating ride: $e');
      return _genericErrorMessage;
    }
  }

  //Delete a ride
  Future<String?> deleteRide(String docID) async {
    try {
      if (docID.isEmpty) {
        return 'Invalid document ID provided';
      }
      
      await ridesData.doc(docID).delete();
      return null; // Success
    } on FirebaseException catch (e) {
      debugPrint('Firebase error deleting ride: ${e.message}');
      return e.message ?? _genericErrorMessage;
    } catch (e) {
      debugPrint('Error deleting ride: $e');
      return _genericErrorMessage;
    }
  }

  // Batch add multiple rides (for seeding sample data)
  Future<String?> addMultipleRides(List<Ride> rides) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final ride in rides) {
        if (ride.latlng == null || ride.dow == null || ride.rideType == null) {
          continue; // Skip invalid rides
        }
        
        final docRef = ridesData.doc();
        batch.set(docRef, {
          'contactName': ride.contact ?? '',
          'contactPhone': ride.phone ?? '',
          'desc': ride.desc ?? '',
          'dow': ride.dow!.index,
          'startTime': ride.startTime ?? DateTime.now(),
          'distance': ride.rideDistance ?? 0,
          'latlng': GeoPoint(ride.latlng!.latitude, ride.latlng!.longitude),
          'snippet': ride.snippet ?? '',
          'startPointDesc': ride.startPointDesc ?? '',
          'title': ride.title ?? '',
          'createOn': Timestamp.now(),
          'verified': ride.verified ?? false,
          'verifiedBy': ride.verifiedBy ?? '',
          'createdBy': ride.createdBy ?? '',
          'rideType': ride.rideType!.index,
        });
      }
      
      await batch.commit();
      return null; // Success
    } on FirebaseException catch (e) {
      debugPrint('Firebase error adding multiple rides: ${e.message}');
      return e.message ?? _genericErrorMessage;
    } catch (e) {
      debugPrint('Error adding multiple rides: $e');
      return _genericErrorMessage;
    }
  }
}
