import 'package:google_maps_flutter/google_maps_flutter.dart';

class Ride {
  final int? id;
  final String? title;
  final String? desc;
  final String? snippet;
  final LatLng? latlng;

  const Ride({
    this.id,
    this.title,
    this.desc,
    this.snippet,
    this.latlng,
  });

  Ride copyWith({
    int? id,
    String? title,
    String? desc,
    String? snippet,
    LatLng? latLng,
  }) {
    return Ride(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      snippet: snippet ?? this.snippet,
      latlng: latlng ?? latlng,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "id": id,
      "title": title,
      "desc": desc,
      "snippet": snippet,
      "latlng": latlng,
    };
  }

  factory Ride.fromJson(Map<String, dynamic> map) {
    return Ride(
      id: map["id"] as int,
      title: map["title"] as String,
      desc: map["desc"] as String,
      snippet: map["snippet"] as String,
      latlng: map["latlng"] as LatLng,
    );
  }
}
