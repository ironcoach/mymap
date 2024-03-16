import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymap/models/ride_data.dart';

class FireStoreService {
  // Get Collection of Rides
  final CollectionReference ridesData =
      FirebaseFirestore.instance.collection('rides');

  // Create a ride
  Future<void> addRide(Ride ride) {
    //GeoPoint geoPoint = GeoPoint(ride.latlng!.latitude,ride.latlng!.longitude);
    return ridesData.add({
      'contactName': ride.contact,
      'contactPhone': ride.phone,
      'desc': ride.desc,
      'dow': ride.dow,
      'startTime': ride.startTime,
      'latlng': GeoPoint(ride.latlng!.latitude, ride.latlng!.longitude),
      'snippet': ride.snippet,
      'startPointDesc': ride.startPointDesc,
      'title': ride.title,
      'createOn': Timestamp.now(),
      'verified': ride.verified,
      'verifiedBy': ride.verifiedBy,
      'createdBy': ride.createdBy,
      'rideType': ride.rideType!.index,
    });
  }

  // Read a ride
  Stream<QuerySnapshot> getRidesStream() {
    final ridesStream =
        ridesData.orderBy('createdOn', descending: true).snapshots();

    return ridesStream;
  }

  // Update a ride
  Future<void> updateRide(String docID, Ride ride) {
    //GeoPoint geoPoint = GeoPoint(ride.latlng!.latitude,ride.latlng!.longitude);
    return ridesData.doc(docID).update({
      'contactName': ride.contact,
    });
  }

  //Delete a ride
  Future<void> deleteRide(String docID) {
    //GeoPoint geoPoint = GeoPoint(ride.latlng!.latitude,ride.latlng!.longitude);
    return ridesData.doc(docID).delete();
  }
}
