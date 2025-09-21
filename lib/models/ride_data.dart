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

enum RideDifficulty {
  easy,
  moderate,
  difficult,
  expert;

  String get titleName {
    switch (this) {
      case RideDifficulty.easy:
        return 'Easy';
      case RideDifficulty.moderate:
        return 'Moderate';
      case RideDifficulty.difficult:
        return 'Difficult';
      case RideDifficulty.expert:
        return 'Expert';
    }
  }

  String get description {
    switch (this) {
      case RideDifficulty.easy:
        return 'Suitable for beginners, flat terrain, short distance';
      case RideDifficulty.moderate:
        return 'Some hills, moderate distance, basic fitness required';
      case RideDifficulty.difficult:
        return 'Challenging terrain, longer distance, good fitness required';
      case RideDifficulty.expert:
        return 'Very challenging, steep climbs, high fitness level required';
    }
  }
}

class Ride {
  final String? id;
  final String? title;
  final String? desc;
  final String? snippet;
  final DateTime? startTime;
  final DayOfWeekType? dow;
  final String? contact;
  final String? phone;
  final String? startPointDesc;
  final LatLng? latlng;
  final bool? verified;
  final String? verifiedBy;
  final String? createdBy;
  final RideType? rideType;
  final int? rideDistance;

  // Separate latitude and longitude fields for efficient Firestore queries
  final double? latitude;
  final double? longitude;

  // New verification system
  final List<String>? verifiedByUsers;
  final int? verificationCount;

  // Rating system
  final double? averageRating;
  final int? totalRatings;
  final Map<String, int>? userRatings; // userId -> rating (1-5)

  // External route link
  final String? routeUrl;

  // Difficulty rating
  final RideDifficulty? difficulty;

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
    this.latitude,
    this.longitude,
    this.verifiedByUsers,
    this.verificationCount,
    this.averageRating,
    this.totalRatings,
    this.userRatings,
    this.routeUrl,
    this.difficulty,
  });

  Ride copyWith({
    String? id,
    String? title,
    String? desc,
    String? snippet,
    DateTime? startTime,
    DayOfWeekType? dow,
    String? contact,
    String? phone,
    String? startPointDesc,
    LatLng? latlng,
    bool? verified,
    String? verifiedBy,
    String? createdBy,
    RideType? rideType,
    int? rideDistance,
    double? latitude,
    double? longitude,
    List<String>? verifiedByUsers,
    int? verificationCount,
    double? averageRating,
    int? totalRatings,
    Map<String, int>? userRatings,
    String? routeUrl,
    RideDifficulty? difficulty,
  }) {
    return Ride(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      snippet: snippet ?? this.snippet,
      startTime: startTime ?? this.startTime,
      dow: dow ?? this.dow,
      contact: contact ?? this.contact,
      phone: phone ?? this.phone,
      startPointDesc: startPointDesc ?? this.startPointDesc,
      latlng: latlng ?? this.latlng,
      verified: verified ?? this.verified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      createdBy: createdBy ?? this.createdBy,
      rideType: rideType ?? this.rideType,
      rideDistance: rideDistance ?? this.rideDistance,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      verifiedByUsers: verifiedByUsers ?? this.verifiedByUsers,
      verificationCount: verificationCount ?? this.verificationCount,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      userRatings: userRatings ?? this.userRatings,
      routeUrl: routeUrl ?? this.routeUrl,
      difficulty: difficulty ?? this.difficulty,
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
      "latitude": latitude,
      "longitude": longitude,
      "verifiedByUsers": verifiedByUsers,
      "verificationCount": verificationCount,
      "averageRating": averageRating,
      "totalRatings": totalRatings,
      "userRatings": userRatings,
      "routeUrl": routeUrl,
      "difficulty": difficulty,
    };
  }

  factory Ride.fromJson(Map<String, dynamic> map) {
    return Ride(
      id: map["id"] as String?,
      title: map["title"] as String?,
      desc: map["desc"] as String?,
      snippet: map["snippet"] as String?,
      startTime: map["startTime"] as DateTime?,
      dow: map["dow"] != null ? DayOfWeekType.values[map["dow"]] : null,
      contact: map["contactName"] as String?,
      phone: map["contactPhone"] as String?,
      startPointDesc: map["startPointDesc"] as String?,
      latlng: map["latlng"] as LatLng?,
      verified: map["verified"] as bool?,
      verifiedBy: map["verifiedBy"] as String?,
      createdBy: map["createdBy"] as String?,
      rideType: map["rideType"] != null ? RideType.values[map["rideType"]] : null,
      rideDistance: map["rideDistance"] as int?,
      latitude: map["latitude"] as double?,
      longitude: map["longitude"] as double?,
      verifiedByUsers: map["verifiedByUsers"] != null
          ? List<String>.from(map["verifiedByUsers"])
          : null,
      verificationCount: map["verificationCount"] as int?,
      averageRating: map["averageRating"] as double?,
      totalRatings: map["totalRatings"] as int?,
      userRatings: map["userRatings"] != null
          ? Map<String, int>.from(map["userRatings"])
          : null,
      routeUrl: map["routeUrl"] as String?,
      difficulty: map["difficulty"] != null
          ? RideDifficulty.values[map["difficulty"]]
          : null,
    );
  }

  // Convenience methods for new features

  /// Check if a user has verified this ride
  bool isVerifiedByUser(String userId) {
    return verifiedByUsers?.contains(userId) ?? false;
  }

  /// Check if a user has rated this ride
  bool isRatedByUser(String userId) {
    return userRatings?.containsKey(userId) ?? false;
  }

  /// Get the rating given by a specific user
  int? getUserRating(String userId) {
    return userRatings?[userId];
  }

  /// Get a formatted verification count string
  String get verificationDisplayText {
    final count = verificationCount ?? 0;
    if (count == 0) return 'Not verified';
    if (count == 1) return 'Verified by 1 user';
    return 'Verified by $count users';
  }

  /// Get a formatted rating display string
  String get ratingDisplayText {
    if (averageRating == null || totalRatings == null || totalRatings == 0) {
      return 'No ratings';
    }
    return '${averageRating!.toStringAsFixed(1)} (${totalRatings!} rating${totalRatings! == 1 ? '' : 's'})';
  }

  /// Check if ride has external route link
  bool get hasExternalRoute {
    return routeUrl?.isNotEmpty ?? false;
  }
}
