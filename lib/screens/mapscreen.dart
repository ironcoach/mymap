import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymap/models/auto_complete_result.dart';
import 'package:mymap/models/ride_data.dart';
import 'package:mymap/providers/providers.dart';
import 'package:mymap/services/map_services.dart';
import 'package:mymap/utils/extensions.dart';
import 'package:mymap/widgets/common_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/gestures.dart';

class MapScreen extends ConsumerStatefulWidget {
  //const MapScreen({super.key});
  const MapScreen({Key? key}) : super(key: key);

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends ConsumerState<MapScreen> {
  //Position of initial map and camera is Boulder, CO

  static const _initialCameraPosition =
      CameraPosition(target: LatLng(40.017555, -105.258336), zoom: 10.5);

  final List<Ride> ridesData = [];

  Set<Marker> _markers = <Marker>{};
  final Set<Marker> _saveMarkers = <Marker>{};

  //LatLngBounds? _currentBounds;

  // history.add(HistoryDetail(
  //   name: exName, round: historyRounds, reps: reps, duration: strTime));

  // final LatLng _fullCycle = const LatLng(40.017555, -105.258336);
  // final LatLng _univCycle = const LatLng(40.01721559800597, -105.2839693419586);
  // final LatLng _cennaCycle =
  //     const LatLng(40.135667689123494, -105.10335022137203);
  // final LatLng _gdRide = const LatLng(40.0805057836106, -105.23549907690392);

  //Debounce to throttle async calls during search
  Timer? _debounce;

  //Toggling UI as we need;
  bool searchToggle = false;
  bool showDetailsToggle = false;

  LatLng? tappedPoint;
  int rideIndex = 0;

  final Completer<GoogleMapController> mapController = Completer();

  final _searchController = TextEditingController();

  void _onMapCreated(GoogleMapController controller) {
    mapController.complete(controller);
    _setMarker();
  }

  final user = FirebaseAuth.instance.currentUser!;

  // sign user out method
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  // void _updateMarkersPosition() async {
  //   final GoogleMapController controller = await mapController.future;
  //   final LatLngBounds visibleBounds = await controller.getVisibleRegion();
  //   setState(() {
  //     _currentBounds = visibleBounds;
  //   });
  //   final Set<Marker> newMarkers = Set<Marker>.from(_markers.where(
  //     (marker) => visibleBounds.contains(marker.position),
  //   ));
  //   setState(() {
  //     _markers = newMarkers;
  //   });
  // }

  // void _updateMarkers(GoogleMapController controller) {
  //   final Set<Marker> newMarkers = <Marker>{};
  //   // Add your markers here
  //   newMarkers.add(
  //     const Marker(
  //       markerId: MarkerId('marker1'),
  //       position: LatLng(37.4219999, -122.0840575),
  //       infoWindow: InfoWindow(title: 'Marker 1'),
  //     ),
  //   );
  //   newMarkers.add(
  //     const Marker(
  //       markerId: MarkerId('marker2'),
  //       position: LatLng(37.42796133580664, -122.085749655962),
  //       infoWindow: InfoWindow(title: 'Marker 2'),
  //     ),
  //   );
  //   setState(() {
  //     _markers = newMarkers;
  //     _updateMarkersPosition();
  //   });
  // }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fillRideData();
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
        title: "Golden Gate Bridge Ride",
        starttime: "3:00 AM",
        desc:
            "Enjoy a scenic ride across the iconic Golden Gate Bridge with breathtaking views of San Francisco.",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(37.8199, -122.4783),
      ),
    );
    ridesData.add(
      const Ride(
        id: 2,
        title: "Central Park Loop",
        starttime: "9:30 AM",
        desc:
            "Take a leisurely ride through the heart of Manhattan in the beautiful Central Park.",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(40.785091, -73.968285),
      ),
    );
    ridesData.add(
      const Ride(
        id: 3,
        title: "Lakefront Trail",
        starttime: "10:00 AM",
        desc:
            "Ride along the picturesque Lake Michigan and enjoy the stunning Chicago skyline.",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(41.8833, -87.6197),
      ),
    );
    ridesData.add(
      const Ride(
        id: 4,
        title: "Boston Harborwalk",
        starttime: "9:00 AM",
        desc:
            "Cycle along the historic Boston Harbor and explore the city's waterfront.",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(42.3601, -71.0589),
      ),
    );
    ridesData.add(
      const Ride(
        id: 5,
        title: "Los Angeles River Bike Path",
        starttime: "8:30 AM",
        desc:
            "Follow the Los Angeles River through parks, neighborhoods, and urban landscapes.",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(34.0522, -118.2437),
      ),
    );
    ridesData.add(
      const Ride(
        id: 6,
        title: "Portland Eastbank Esplanade",
        starttime: "10:30 AM",
        desc:
            "Enjoy a scenic ride along the Willamette River with views of downtown Portland.",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(45.5175, -122.6651),
      ),
    );
    ridesData.add(
      const Ride(
        id: 7,
        title: "Minneapolis Chain of Lakes",
        starttime: "9:30 AM",
        desc:
            "Explore the interconnected lakes of Minneapolis on this beautiful bike path.",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(44.9497, -93.3133),
      ),
    );
    ridesData.add(
      const Ride(
        id: 8,
        title: "Austin Hike and Bike Trail",
        starttime: "8:00 AM",
        desc:
            "Cycle along the scenic Lady Bird Lake in downtown Austin, Texas.",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(30.2649, -97.7479),
      ),
    );
    ridesData.add(
      const Ride(
        id: 9,
        title: "Seattle Burke-Gilman Trail",
        starttime: "10:00 AM",
        desc:
            "Ride through parks, neighborhoods, and along scenic waterways on this popular Seattle trail.",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(47.6607, -122.2886),
      ),
    );
    ridesData.add(
      const Ride(
        id: 10,
        title: "Denver Cherry Creek Trail",
        starttime: "9:00 AM",
        desc:
            "Cycle along the Cherry Creek and enjoy the beautiful scenery of Denver.",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(39.7392, -104.9903),
      ),
    );
    ridesData.add(
      const Ride(
        id: 11,
        title: "Cenna Cycle",
        starttime: "5:30 PM",
        desc:
            "Gravel Ride, Leaves from the shop. This is a friendly ride with an occasional few spicy spots.",
        startpointdesc: "Start at the shop",
        contact: "Cenna Da Man!",
        phone: "555 123-4567",
        dow: "Wednesday",
        latlng: LatLng(40.135667689123494, -105.10335022137203),
      ),
    );
    ridesData.add(
      const Ride(
        id: 12,
        title: "Gravel Donkey Ride",
        starttime: "10:30 AM",
        desc:
            "Leaves every Thursday evening from the Eagle parking lot at 5:00pm",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(40.0805057836106, -105.23549907690392),
      ),
    );
    ridesData.add(
      const Ride(
        id: 13,
        title: "Full Cycle",
        starttime: "10:30 AM",
        desc:
            "Road Rides leaving Tuesday and Thursday evening from the shop at 5:30pm",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(40.017555, -105.258336),
      ),
    );

    ridesData.add(
      const Ride(
        id: 14,
        title: "Tony's Awesome Ride",
        starttime: "Whenever I want",
        desc: "This ride leaves from my house whenever the FUCK I want!",
        startpointdesc: "Just under the bridge",
        contact: "Ranger Adams",
        phone: "616 956-5434",
        dow: "Random",
        latlng: LatLng(42.405876, -85.277250),
      ),
    );

    ridesData.add(
      const Ride(
        id: 15,
        title: "Tucson Shootout",
        starttime: "10:30 AM",
        desc: "Probably the most famous ride in the country.",
        startpointdesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: "Monday",
        latlng: LatLng(32.231719, -110.959289),
      ),
    );

    for (Ride ride in ridesData) {
      final Marker marker = Marker(
          markerId: MarkerId('marker_${ride.id.toString()}'),
          position: ride.latlng!,
          infoWindow: InfoWindow(
            onTap: () {
              rideIndex = ride.id!.toInt();
              print("Tapped on InfoWindo");
              showDetailsToggle = !showDetailsToggle;
              setState(() {});
            },
            title: ride.title,
            snippet: ride.desc,
          ),
          onTap: () {},
          icon: BitmapDescriptor.defaultMarker);
      _saveMarkers.add(marker);
    }
  }

  void _setMarker() async {
    final GoogleMapController controller = await mapController.future;
    LatLngBounds bounds = await controller.getVisibleRegion();

    final Set<Marker> newMarkers = Set<Marker>.from(_saveMarkers.where(
      (marker) => bounds.contains(marker.position),
    ));
    setState(() {
      _markers = newMarkers;
    });
  }

  // void _moveToAddress() async {
  //   String address = _searchController.text;
  //   try {
  //     List<Location> locations = await locationFromAddress(address);
  //     print("Made it here");
  //     if (locations.isNotEmpty) {
  //       Location location = locations.first;
  //       LatLng latLng = LatLng(location.latitude, location.longitude);
  //       GoogleMapController newController = await mapController.future;
  //       //newController.animateCamera(CameraUpdate.newCameraPosition(latLng));
  //       newController.animateCamera(CameraUpdate.newLatLng(latLng));
  //       setState(() {});
  //     } else {
  //       _showErrorDialog('Address not found');
  //     }
  //   } catch (e) {
  //     _showErrorDialog('Error: $e');
  //   }
  // }

  // void _showErrorDialog(String message) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text('Error'),
  //         content: Text(message),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('OK'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // void _checkLatLngInViewableArea() async {
  //   final GoogleMapController controller = await mapController.future;
  //   LatLngBounds bounds = await controller.getVisibleRegion();
  //   LatLng cennaCycle = const LatLng(40.135667689123494, -105.10335022137203);

  //   bool isInBounds = bounds.contains(cennaCycle);
  //   if (isInBounds) {
  //     print("It's in the box");
  //   } else {
  //     print("Not in the box");
  //   }
  // }

  Widget showDetails() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      top: 100.0,
      left: 15.0,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: screenHeight * .40,
              width: screenWidth * .75,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(4, 8),
                    ),
                  ]),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 15.0),
                        child: Text(
                          'Details ',
                          style: TextStyle(
                              fontFamily: 'WorkSans',
                              fontSize: 22.0,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Gap(70),
                      IconButton(
                        iconSize: 30,
                        icon: const Icon(
                          Icons.close,
                        ),
                        onPressed: () {
                          showDetailsToggle = !showDetailsToggle;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const Divider(
                    indent: 10.0,
                    endIndent: 10.0,
                    height: 5.0,
                    thickness: 5.0,
                  ),
                  const Gap(5),
                  Text(
                    "${ridesData[rideIndex - 1].title}",
                    style: context.textTheme.headlineSmall,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${ridesData[rideIndex - 1].desc}"),
                  ),
                  Text("${ridesData[rideIndex - 1].dow}"),
                  Text("${ridesData[rideIndex - 1].starttime}"),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${ridesData[rideIndex - 1].contact}"),
                  ),
                  Text("${ridesData[rideIndex - 1].phone}"),
                ],
              ),
            ),
            // const Text('Hello'),
            // const Text('GoodBye'),
          ],
        ),
      ),
    );
  }

  Widget placeMap() {
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    //Providers
    final allSearchResults = ref.watch(placeResultsProvider);
    final searchFlag = ref.watch(searchToggleProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50.0,
        centerTitle: false,
        title: const Text('The Ride Finder'),
        actions: [
          IconButton(
            onPressed: signUserOut,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: screenHeight,
                  width: screenWidth,
                  child: placeMap(),
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
                showDetailsToggle ? showDetails() : Container(),
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
            const Gap(10),
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
        CameraPosition(target: LatLng(lat, lng), zoom: 10.5)));

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
