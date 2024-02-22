import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymap/models/auto_complete_result.dart';
import 'package:mymap/models/ride_data.dart';
import 'package:mymap/providers/providers.dart';
import 'package:mymap/services/map_services.dart';
import 'package:mymap/widgets/common_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/gestures.dart';

class MapScreen extends ConsumerStatefulWidget {
  //const MapScreen({super.key});
  const MapScreen({Key? key}) : super(key: key);

  @override
  MapScreenState createState() => MapScreenState();
  // State<MapScreen> createState() => _MapScreenState();
}

class MapScreenState extends ConsumerState<MapScreen> {
  //Position of initial map and camera is Boulder, CO
  // static const _initialCameraPosition =
  //     CameraPosition(target: LatLng(40.017555, -105.258336), zoom: 10.5);

  // static const _initialCameraPosition = CameraPosition(
  //     target: LatLng(37.42796133580664, -122.085749655962), zoom: 10.5);

  static const _initialCameraPosition =
      CameraPosition(target: LatLng(40.017555, -105.258336), zoom: 10.5);
  final List<Ride> ridesData = [];
  //final Set<Marker> _markers = <Marker>{};
  Set<Marker> _markers = <Marker>{};
  final Set<Marker> _saveMarkers = <Marker>{};

  LatLngBounds? _currentBounds;

  // history.add(HistoryDetail(
  //   name: exName, round: historyRounds, reps: reps, duration: strTime));

  final LatLng _fullCycle = const LatLng(40.017555, -105.258336);
  final LatLng _univCycle = const LatLng(40.01721559800597, -105.2839693419586);
  final LatLng _cennaCycle =
      const LatLng(40.135667689123494, -105.10335022137203);
  final LatLng _gdRide = const LatLng(40.0805057836106, -105.23549907690392);

  //Debounce to throttle async calls during search
  Timer? _debounce;

  //Toggling UI as we need;
  bool searchToggle = false;
  LatLng? tappedPoint;

  //late GoogleMapController mapController;
  final Completer<GoogleMapController> mapController = Completer();

  final _searchController = TextEditingController();

  void _onMapCreated(GoogleMapController controller) {
    mapController.complete(controller);
    _setMarker();
    //_updateMarkers(controller);
  }

  void _updateMarkersPosition() async {
    final GoogleMapController controller = await mapController.future;
    final LatLngBounds visibleBounds = await controller.getVisibleRegion();
    setState(() {
      _currentBounds = visibleBounds;
    });
    final Set<Marker> newMarkers = Set<Marker>.from(_markers.where(
      (marker) => visibleBounds.contains(marker.position),
    ));
    setState(() {
      _markers = newMarkers;
    });
  }

  void _updateMarkers(GoogleMapController controller) {
    final Set<Marker> newMarkers = <Marker>{};
    // Add your markers here
    newMarkers.add(
      const Marker(
        markerId: MarkerId('marker1'),
        position: LatLng(37.4219999, -122.0840575),
        infoWindow: InfoWindow(title: 'Marker 1'),
      ),
    );
    newMarkers.add(
      const Marker(
        markerId: MarkerId('marker2'),
        position: LatLng(37.42796133580664, -122.085749655962),
        infoWindow: InfoWindow(title: 'Marker 2'),
      ),
    );
    setState(() {
      _markers = newMarkers;
      _updateMarkersPosition();
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fillRideData();
    //_setMarker();
  }

  @override
  void dispose() {
    //mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fillRideData() {
    ridesData.add(
      const Ride(
        id: 1,
        title: "Cenna Cycle",
        desc:
            "Wedneday Gravel Ride, Leaves from the shop and starts at 5:30pm.",
        latlng: LatLng(40.135667689123494, -105.10335022137203),
      ),
    );
    ridesData.add(
      const Ride(
        id: 2,
        title: "Gravel Donkey Ride",
        desc:
            "Leaves every Thursday evening from the Eagle parking lot at 5:00pm",
        latlng: LatLng(40.0805057836106, -105.23549907690392),
      ),
    );
    ridesData.add(
      const Ride(
        id: 3,
        title: "Full Cycle",
        desc:
            "Road Rides leaving Tuesday and Thursday evening from the shop at 5:30pm",
        latlng: LatLng(40.017555, -105.258336),
      ),
    );

    ridesData.add(
      const Ride(
        id: 3,
        title: "Tony's Awesome Ride",
        desc: "This ride leaves from my house whenever the FUCK I want!",
        latlng: LatLng(42.405876, -85.277250),
      ),
    );

    ridesData.add(
      const Ride(
        id: 3,
        title: "Tucson Shootout",
        desc: "Probably the most famous ride in the country.",
        latlng: LatLng(32.231719, -110.959289),
      ),
    );

    for (Ride ride in ridesData) {
      final Marker marker = Marker(
          markerId: MarkerId('marker_${ride.id.toString()}'),
          position: ride.latlng!,
          infoWindow: InfoWindow(
            title: ride.title,
            snippet: ride.desc,
          ),
          onTap: () {
            print("Tapped on InfoWindo");
          },
          icon: BitmapDescriptor.defaultMarker);
      _saveMarkers.add(marker);
    }
  }

  void _setMarker() async {
    final GoogleMapController controller = await mapController.future;
    LatLngBounds bounds = await controller.getVisibleRegion();

    // for (Ride ride in ridesData) {
    //   isInBounds = bounds.contains(ride.latlng!);

    //   if (isInBounds) {
    //     print("It's in the box ${ride.title}");
    //     final Marker marker = Marker(
    //         markerId: MarkerId('marker_${ride.id.toString()}'),
    //         position: ride.latlng!,
    //         infoWindow: InfoWindow(
    //           title: ride.title,
    //           snippet: ride.desc,
    //         ),
    //         onTap: () {},
    //         icon: BitmapDescriptor.defaultMarker);
    //     _markers.add(marker);
    //   } else {
    //     print("************* Not in the box ${ride.title}  *************");
    //   }
    // }
    final Set<Marker> newMarkers = Set<Marker>.from(_saveMarkers.where(
      (marker) => bounds.contains(marker.position),
    ));
    setState(() {
      _markers = newMarkers;
    });
  }

// Future<void> _goToTheLake() async {
//   final GoogleMapController controller = await _controller.future;
//   controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
//  }

  void _moveToAddress() async {
    String address = _searchController.text;
    try {
      List<Location> locations = await locationFromAddress(address);
      print("Made it here");
      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng latLng = LatLng(location.latitude, location.longitude);
        GoogleMapController newController = await mapController.future;
        //newController.animateCamera(CameraUpdate.newCameraPosition(latLng));
        newController.animateCamera(CameraUpdate.newLatLng(latLng));
        setState(() {});
      } else {
        _showErrorDialog('Address not found');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _checkLatLngInViewableArea() async {
    final GoogleMapController controller = await mapController.future;
    LatLngBounds bounds = await controller.getVisibleRegion();
    LatLng cennaCycle = const LatLng(40.135667689123494, -105.10335022137203);

    bool isInBounds = bounds.contains(cennaCycle);
    if (isInBounds) {
      print("It's in the box");
    } else {
      print("Not in the box");
    }
  }

  Widget PlaceMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      myLocationButtonEnabled: false,
      scrollGesturesEnabled: true,
      zoomControlsEnabled: true,
      tiltGesturesEnabled: false,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(
          () => EagerGestureRecognizer(),
        ),
      },
      initialCameraPosition: _initialCameraPosition,
      //markers: _markers,
      markers: Set<Marker>.of(_markers),
      onCameraMove: (CameraPosition position) {
        // _updateMarkersPosition();
        // _checkLatLngInViewableArea();
        _setMarker();
      },
      onTap: (point) {
        tappedPoint = point;
        gotoSearchedPlace(point.latitude, point.longitude);
      },
      //
      // {
      //   Marker(
      //     markerId: const MarkerId('Univ Cycle'),
      //     position: _univCycle,
      //     infoWindow: const InfoWindow(
      //       title: "University Bikes",
      //       snippet: "Tuesday Screamer Ride",
      //     ),
      //   ),
      //   Marker(
      //     markerId: const MarkerId('Full Cycle'),
      //     position: _fullCycle,
      //     infoWindow: const InfoWindow(
      //       title: "Full Cycle",
      //       snippet: "The ride starts here!",
      //     ),
      //   ),
      //   Marker(
      //     markerId: const MarkerId('Cenna Cycle'),
      //     position: _cennaCycle,
      //     infoWindow: const InfoWindow(
      //       title: "Cenna's Custom Cycle",
      //       snippet: "Only goodness from here",
      //     ),
      //   ),
      //   Marker(
      //     markerId: const MarkerId('Gravel Donkey'),
      //     position: _gdRide,
      //     infoWindow: const InfoWindow(
      //       title: "Gravel Donkey Ride",
      //       snippet: "Hang onto your hat, it's gonna get spicy!",
      //     ),
      //   ),
      //   // Marker
      // },
    );
  }

  void _getMapCenter() async {
    final GoogleMapController controller = await mapController.future;
    LatLng center = await controller.getLatLng(ScreenCoordinate(
      x: MediaQuery.of(context).size.width ~/ 2,
      y: MediaQuery.of(context).size.height ~/ 2,
    ));
    print('Map center: $center');
  }
  // Widget DrawSearch() {
  //   return Row(
  //     children: [
  //       TextField(
  //         controller: _searchController,
  //         onTapOutside: (event) {
  //           FocusManager.instance.primaryFocus?.unfocus();
  //         },
  //         decoration: const InputDecoration(
  //           hintText: 'search',
  //           //suffixIcon: suffixIcon,
  //         ),
  //         onChanged: (value) {},
  //       ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    //Providers
    final allSearchResults = ref.watch(placeResultsProvider);
    final searchFlag = ref.watch(searchToggleProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('The Ride Finder'),
        // actions: [
        //   TextButton(
        //     onPressed: () {},
        //     style: TextButton.styleFrom(foregroundColor: Colors.black),
        //     child: const Text('Filter'),
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: screenHeight,
                  width: screenWidth,
                  child: PlaceMap(),
                ),
                searchToggle
                    ? Padding(
                        padding:
                            const EdgeInsets.fromLTRB(15.0, 40.0, 15.0, 5.0),
                        child: Column(children: [
                          Container(
                            height: 50.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.white,
                            ),
                            child: TextFormField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 15.0),
                                  border: InputBorder.none,
                                  hintText: 'Search',
                                  suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          searchToggle = false;

                                          _searchController.text = '';
                                          //_markers = {};
                                          if (searchFlag.searchToggle) {
                                            searchFlag.toggleSearch();
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.close))),
                              onChanged: (value) {
                                if (_debounce?.isActive ?? false) {
                                  _debounce?.cancel();
                                }
                                _debounce =
                                    Timer(const Duration(milliseconds: 700),
                                        () async {
                                  if (value.length > 2) {
                                    if (!searchFlag.searchToggle) {
                                      searchFlag.toggleSearch();
                                      //_markers = {};
                                    }

                                    List<AutoCompleteResult> searchResults =
                                        await MapServices().searchPlaces(value);

                                    allSearchResults.setResults(searchResults);
                                  } else {
                                    List<AutoCompleteResult> emptyList = [];
                                    allSearchResults.setResults(emptyList);
                                  }
                                });
                              },
                            ),
                          )
                        ]),
                      )
                    : Container(),
                searchFlag.searchToggle
                    ? allSearchResults.allReturnedResults.isNotEmpty
                        ? Positioned(
                            top: 100.0,
                            left: 15.0,
                            child: Container(
                              height: 200.0,
                              width: screenWidth - 30.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.white.withOpacity(0.7),
                              ),
                              child: ListView(
                                children: [
                                  ...allSearchResults.allReturnedResults
                                      .map((e) => buildListItem(e, searchFlag))
                                ],
                              ),
                            ))
                        : Positioned(
                            top: 100.0,
                            left: 15.0,
                            child: Container(
                              height: 200.0,
                              width: screenWidth - 30.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.white.withOpacity(0.7),
                              ),
                              child: Center(
                                child: Column(children: [
                                  const Text('No results to show',
                                      style: TextStyle(
                                          fontFamily: 'WorkSans',
                                          fontWeight: FontWeight.w400)),
                                  const SizedBox(height: 5.0),
                                  SizedBox(
                                    width: 125.0,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        searchFlag.toggleSearch();
                                      },
                                      child: const Center(
                                        child: Text(
                                          'Close this',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'WorkSans',
                                              fontWeight: FontWeight.w300),
                                        ),
                                      ),
                                    ),
                                  )
                                ]),
                              ),
                            ))
                    : Container(),
              ],
            ),

            //SizedBox(height: 20),
            //PlaceMap(),
            const Gap(10),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: TextField(
            //     controller: _searchController,
            //     decoration: InputDecoration(
            //       labelText: 'Search Location',
            //       suffixIcon: IconButton(
            //           icon: const Icon(Icons.search),
            //           onPressed: () {
            //             _moveToAddress();
            //           }),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  //_setMarker();
                  searchToggle = true;
                });
              },
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> gotoSearchedPlace(double lat, double lng) async {
    final GoogleMapController controller = await mapController.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 12)));

    _setMarker();
  }

  Widget buildListItem(AutoCompleteResult placeItem, searchFlag) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: GestureDetector(
        onTapDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onTap: () async {
          var place = await MapServices().getPlace(placeItem.placeId);
          gotoSearchedPlace(place['geometry']['location']['lat'],
              place['geometry']['location']['lng']);
          searchFlag.toggleSearch();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.green, size: 25.0),
            const SizedBox(width: 4.0),
            SizedBox(
              height: 40.0,
              width: MediaQuery.of(context).size.width - 75.0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(placeItem.description ?? ''),
              ),
            )
          ],
        ),
      ),
    );
  }
}
