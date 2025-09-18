import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymap/models/auto_complete_result.dart';

import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class MapServices {
  final String key = 'AIzaSyB6ZNEIx7WZO3Vzl1kphBmwaNDpjpkifOU';
  final String types = '(regions)';

  Future<List<AutoCompleteResult>> searchPlaces(String searchInput) async {
    // URL encode the search input to handle spaces and special characters
    final String encodedInput = Uri.encodeComponent(searchInput);
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedInput&key=$key';

    print('🔍 Original input: "$searchInput"');
    print('🔍 Encoded input: "$encodedInput"');
    print('🔍 Full URL: $url');

    try {
      var response = await http.get(Uri.parse(url));

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode != 200) {
        print('❌ HTTP Error: ${response.statusCode}');
        return [];
      }

      var json = convert.jsonDecode(response.body);

      if (json['status'] != 'OK') {
        print('❌ API Error: ${json['status']} - ${json['error_message'] ?? 'No error message'}');
        // Handle specific error cases
        if (json['status'] == 'REQUEST_DENIED') {
          print('🔑 Check your API key and enable Places API');
        } else if (json['status'] == 'OVER_QUERY_LIMIT') {
          print('💰 API quota exceeded');
        }
        return [];
      }

      var results = json['predictions'] as List;
      print('✅ Found ${results.length} results');

      return results.map((e) => AutoCompleteResult.fromJson(e)).toList();
    } catch (e) {
      print('💥 Exception in searchPlaces: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getPlace(String? input) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$input&key=$key';

    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);

    var results = json['result'] as Map<String, dynamic>;

    return results;
  }

  // Future<Map<String, dynamic>> getDirections(
  //     String origin, String destination) async {
  //   final String url =
  //       'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$key';

  //   var response = await http.get(Uri.parse(url));

  //   var json = convert.jsonDecode(response.body);

  //   var results = {
  //     'bounds_ne': json['routes'][0]['bounds']['northeast'],
  //     'bounds_sw': json['routes'][0]['bounds']['southwest'],
  //     'start_location': json['routes'][0]['legs'][0]['start_location'],
  //     'end_location': json['routes'][0]['legs'][0]['end_location'],
  //     'polyline': json['routes'][0]['overview_polyline']['points'],
  //     'polyline_decoded': PolylinePoints()
  //         .decodePolyline(json['routes'][0]['overview_polyline']['points'])
  //   };

  //   return results;
  // }

  Future<dynamic> getPlaceDetails(LatLng coords, int radius) async {
    var lat = coords.latitude;
    var lng = coords.longitude;

    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?&location=$lat,$lng&radius=$radius&key=$key';

    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);

    return json;
  }

  Future<dynamic> getMorePlaceDetails(String token) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?&pagetoken=$token&key=$key';

    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);

    return json;
  }
}
