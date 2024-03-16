import 'package:google_maps_flutter/google_maps_flutter.dart';

// 7D:1D:F3:DB:63:9F:42:4E:DE:3E:64:05:80:4F:7E:4B:D3:DC:78:96

enum DayOfWeekType {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get titleName {
    switch (this) {
      case DayOfWeekType.monday:
        return 'Monday';
      case DayOfWeekType.tuesday:
        return 'Tuesday';
      case DayOfWeekType.wednesday:
        return 'Wednesday';
      case DayOfWeekType.thursday:
        return 'Thursday';
      case DayOfWeekType.friday:
        return 'Friday';
      case DayOfWeekType.saturday:
        return 'Saturday';
      case DayOfWeekType.sunday:
        return 'Sunday';
    }
  }
}

enum RideType {
  roadRide,
  gravelRide,
  mtbRide,
  bikeEvent;

  String get titleName {
    switch (this) {
      case RideType.roadRide:
        return 'Road Ride';
      case RideType.gravelRide:
        return 'Gravel Ride';
      case RideType.mtbRide:
        return 'MTB Ride';
      case RideType.bikeEvent:
        return 'Bike Event';
    }
  }
}

class Ride {
  final int? id;
  final String? title;
  final String? desc;
  final String? snippet;
  final DateTime? startTime;
  final String? dow;
  final String? contact;
  final String? phone;
  final String? startPointDesc;
  final LatLng? latlng;
  final bool? verified;
  final String? verifiedBy;
  final String? createdBy;
  final RideType? rideType;
  final int? rideDistance;

  const Ride({
    this.id,
    this.title,
    this.desc,
    this.snippet,
    this.startTime,
    this.dow,
    this.contact,
    this.phone,
    this.startPointDesc,
    this.latlng,
    this.verified,
    this.verifiedBy,
    this.createdBy,
    this.rideType,
    this.rideDistance,
  });

  Ride copyWith({
    int? id,
    String? title,
    String? desc,
    String? snippet,
    DateTime? startTime,
    String? dow,
    String? contact,
    String? phone,
    String? startpointdesc,
    LatLng? latLng,
    bool? verified,
    String? verifiedBy,
    String? createdBy,
    RideType? rideType,
    int? rideDistance,
  }) {
    return Ride(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      snippet: snippet ?? this.snippet,
      startTime: startTime ?? this.startTime,
      contact: contact ?? this.contact,
      phone: phone ?? this.phone,
      startPointDesc: startPointDesc ?? startPointDesc,
      latlng: latlng ?? latlng,
      verified: verified ?? verified,
      verifiedBy: verifiedBy ?? verifiedBy,
      createdBy: createdBy ?? createdBy,
      rideType: rideType ?? rideType,
      rideDistance: rideDistance ?? rideDistance,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "id": id,
      "title": title,
      "desc": desc,
      "snippet": snippet,
      "startTime": startTime,
      "dow": dow,
      "contactName": contact,
      "contactPhone": phone,
      "startpointdesc": startPointDesc,
      "latlng": latlng,
      "verified": verified,
      "verifiedBy": verifiedBy,
      "createdBy": createdBy,
      "rideType": rideType,
      "rideDistance": rideDistance,
    };
  }

  factory Ride.fromJson(Map<String, dynamic> map) {
    return Ride(
      id: map["id"] as int,
      title: map["title"] as String,
      desc: map["desc"] as String,
      snippet: map["snippet"] as String,
      startTime: map["startTime"] as DateTime,
      dow: map["dow"] as String,
      contact: map["contactName"] as String,
      phone: map["contactPhone"] as String,
      startPointDesc: map["startPointDesc"] as String,
      latlng: map["latlng"] as LatLng,
      verified: map["verified"] as bool,
      verifiedBy: map["verifiedBy"] as String,
      createdBy: map["createdBy"] as String,
      rideType: map["rideType"] as RideType,
      rideDistance: map["rideDistance"] as int,
    );
  }
}
