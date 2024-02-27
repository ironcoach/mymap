import 'package:google_maps_flutter/google_maps_flutter.dart';

// 7D:1D:F3:DB:63:9F:42:4E:DE:3E:64:05:80:4F:7E:4B:D3:DC:78:96

class Ride {
  final int? id;
  final String? title;
  final String? desc;
  final String? snippet;
  final String? starttime;
  final String? dow;
  final String? contact;
  final String? phone;
  final String? startpointdesc;
  final LatLng? latlng;

  const Ride({
    this.id,
    this.title,
    this.desc,
    this.snippet,
    this.starttime,
    this.dow,
    this.contact,
    this.phone,
    this.startpointdesc,
    this.latlng,
  });

  Ride copyWith({
    int? id,
    String? title,
    String? desc,
    String? snippet,
    String? starttime,
    String? dow,
    String? contact,
    String? phone,
    String? startpointdesc,
    LatLng? latLng,
  }) {
    return Ride(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      snippet: snippet ?? this.snippet,
      starttime: starttime ?? this.starttime,
      contact: contact ?? this.contact,
      phone: phone ?? this.phone,
      startpointdesc: startpointdesc ?? this.startpointdesc,
      latlng: latlng ?? latlng,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "id": id,
      "title": title,
      "desc": desc,
      "snippet": snippet,
      "starttime": starttime,
      "dow": dow,
      "contact": contact,
      "phone": phone,
      "startpointdesc": startpointdesc,
      "latlng": latlng,
    };
  }

  factory Ride.fromJson(Map<String, dynamic> map) {
    return Ride(
      id: map["id"] as int,
      title: map["title"] as String,
      desc: map["desc"] as String,
      snippet: map["snippet"] as String,
      starttime: map["starttime"] as String,
      dow: map["dow"] as String,
      contact: map["contact"] as String,
      phone: map["phone"] as String,
      startpointdesc: map["startpointdesc"] as String,
      latlng: map["latlng"] as LatLng,
    );
  }
}
