import 'dart:async';
import 'package:flutter/cupertino.dart' as cupertino;

import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

//import 'package:location/location.dart' as loc;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymap/constants/constants.dart';
import 'package:mymap/models/auto_complete_result.dart';
import 'package:mymap/models/ride_data.dart';
import 'package:mymap/pages/add_new_ride_page.dart';
import 'package:mymap/pages/app_drawer.dart';
import 'package:mymap/pages/profile_page.dart';
import 'package:mymap/providers/providers.dart';
import 'package:mymap/services/firestore.dart';
import 'package:mymap/services/map_services.dart';
import 'package:mymap/utils/extensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/gestures.dart';
import 'package:mymap/widgets/display_dlg_text.dart';
import 'package:mymap/widgets/display_text.dart';
import 'package:mymap/widgets/my_textfield.dart';

class MapScreen extends ConsumerStatefulWidget {
  //const MapScreen({super.key});
  const MapScreen({Key? key}) : super(key: key);

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends ConsumerState<MapScreen> {
  //Position of initial map and camera is Boulder, CO

  // static const _initialCameraPosition =
  //     CameraPosition(target: LatLng(40.017555, -105.258336), zoom: 10.5);
  CameraPosition _startPosition =
      const CameraPosition(target: LatLng(40.017555, -105.258336), zoom: 10.5);

  //loc.Location location = loc.Location();
  final LatLng _initialCameraPosition = const LatLng(0.0, 0.0);
  //LatLng _initialCameraPosition = LatLng(0.0, 0.0);
/////40.187503, -105.152711
  ///
  ///

  final List<Ride> ridesData = [];

  Set<Marker> _markers = <Marker>{};
  final Set<Marker> _saveMarkers = <Marker>{};

  //Debounce to throttle async calls during location search
  Timer? _debounce;

  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDT = DateTime.now();

  //Toggling UI as we need;
  bool searchToggle = false;
  bool showDetailsToggle = false;

  LatLng? tappedPoint;
  int rideIndex = 0;
  String rideID = '';

/////////////
  String? rideTitle;
  String? rideDesc;
  DayOfWeekType? rideDow;
  TimeOfDay? rideStartTime;
  String? rideStartPointDesc;
  String? rideContact;
  String? ridePhone;
  bool? rideVerified = false;
  String? rideVerifiedBy;
  String? rideSnippet;
  RideType? rideType;
  int? rideDistance;
  LatLng? rideLatlng;

  List<Uint8List> pinImages = [];
  List<String> assetImages = [
    'assets/mapicons/birds.png',
    'assets/mapicons/bars.png',
    'assets/mapicons/coffee-n-tea.png',
    'assets/mapicons/food.png',
  ];

  BitmapDescriptor? markerGravel;

/////////////////
  ///
  ///
  final Completer<GoogleMapController> mapController = Completer();
  final LatLng _initialPosition = const LatLng(0.0, 0.0); // Default position

  final _searchController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController snippetController = TextEditingController();
  TextEditingController dowController = TextEditingController();
  TextEditingController startPointController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();
  TextEditingController distanceController = TextEditingController();

  void _onMapCreated(GoogleMapController controller) {
    mapController.complete(controller);
    //print("On Map Created");
    _setMarker();
  }

  final user = FirebaseAuth.instance.currentUser!;
  final CollectionReference ridesDataFS =
      FirebaseFirestore.instance.collection('rides');

  // sign user out method
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  // go to Profile Page
  void goToProfilePage() {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    //_selectedDT = _selectedDT.copyWith(hour: 5, minute: 0);
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext builder) => SizedBox(
          height: 216,
          child: CupertinoDatePicker(
            backgroundColor: context.colorScheme.surfaceVariant,
            initialDateTime: _selectedDT,
            mode: CupertinoDatePickerMode.time,
            onDateTimeChanged: (DateTime newTime) {
              setState(() {
                _selectedDT = newTime;
                _selectedTime = TimeOfDay.fromDateTime(_selectedDT);
              });
            },
          ),
        ),
      );
    } else {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      ).then((value) {
        if (value != null) {
          setState(() {
            _selectedDT = DateTime(_selectedDT.year, _selectedDT.month,
                _selectedDT.day, value.hour, value.minute);
            _selectedTime = TimeOfDay.fromDateTime(_selectedDT);
          });
        }
        return;
      });
      return;
    }
  }

  void _createMarkers() async {
    // Define custom marker icons from assets
    markerGravel = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2.0),
      'assets/mapicons/birds.png',
    );
  }
  // // declared method to get Images
  // Future<Uint8List> getImage(String path, int width) async {
  //   ByteData data = await rootBundle.load(path);
  //   ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
  //       targetHeight: width);
  //   ui.FrameInfo fi = await codec.getNextFrame();
  //   return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
  //       .buffer
  //       .asUint8List();
  // }

  @override
  void initState() {
    super.initState();
    //_createMarkers;
    //_loadPinImages();
    _determinePosition();
    _getRideData();

    //setState(() {});
  }

  @override
  void dispose() {
    //mapController.dispose();
    _searchController.dispose();
    titleController.dispose();
    descController.dispose();
    snippetController.dispose();
    dowController.dispose();
    startPointController.dispose();
    contactController.dispose();
    phoneController.dispose();
    startTimeController.dispose();
    distanceController.dispose();
    super.dispose();
  }

  // _loadPinImages() async {
  //   for (var assetImage in assetImages) {
  //     pinImages.add(await getImage(assetImage, 10));
  //   }
  // }

  _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    //print("Permissions granted for location");

    Position pos = await Geolocator.getCurrentPosition().then((myPos) {
      //print("pos determined");
      _startPosition = CameraPosition(
          target: LatLng(
            myPos.latitude,
            myPos.longitude,
          ),
          zoom: 11);
      gotoSearchedPlace(myPos.latitude, myPos.longitude);
      setState(() {});
      return myPos;
    });

    //return await Geolocator.getCurrentPosition();
  }

  Future<BitmapDescriptor> _getCustomMarker(image) async {
    ByteData data = await rootBundle.load(image);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: 40);
    ui.FrameInfo fi = await codec.getNextFrame();
    Uint8List? bytes =
        (await fi.image.toByteData(format: ui.ImageByteFormat.png))
            ?.buffer
            .asUint8List();
    return BitmapDescriptor.fromBytes(bytes!);
  }

  void _getRideData() async {
    _saveMarkers.clear();

    BitmapDescriptor markerIcon;

    // BitmapDescriptor markerGravel =
    //     await _getCustomMarker('assets/mapicons/bikeRising.png');

    BitmapDescriptor markerGravel = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 1.0),
        'assets/mapicons/bikeRising.png');
    BitmapDescriptor markerRoad = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 1.0),
        'assets/mapicons/roadRide.png');
    BitmapDescriptor markerMTB = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 1.0),
        'assets/mapicons/greenBike.png');
    BitmapDescriptor markerEvent = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 1.0),
        'assets/mapicons/blueRide.png');

    ridesDataFS.get().then(
      (querySnapshot) {
        for (var doc in querySnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          //print("DocID: ${doc.id}");
          //print('Ride Title: ${data["title"]}');

          RideType type = RideType.values[data['rideType']];
          //RideType type = RideType.values.data['rideType'];
          switch (type) {
            case RideType.gravelRide:
              markerIcon = markerGravel;
              break;
            case RideType.roadRide:
              markerIcon = markerRoad;

              break;
            case RideType.mtbRide:
              markerIcon = markerMTB;

              break;
            case RideType.bikeEvent:
              markerIcon = markerEvent;

              break;
          }

          GeoPoint pos = data["latlng"];
          LatLng latlng = LatLng(pos.latitude, pos.longitude);
          final Marker marker = Marker(
            markerId: MarkerId(doc.id),
            position: latlng,
            infoWindow: InfoWindow(
              onTap: () async {
                rideID = doc.id;

                //showDetailsToggle = !showDetailsToggle;
                await getRideDetails();
                showDetails();
                setState(() {});
              },
              title: data["title"],
              snippet: data["snippet"],
            ),
            onTap: () {},
            icon: markerIcon,

            //icon: BitmapDescriptor.defaultMarker,
          );
          _saveMarkers.add(marker);
        }
        setState(() {});
      },
    );
  }

////////////////////////////////////
  void addRidesToFirestore() {
    final FireStoreService fs = FireStoreService();
    _fillRideData();
    for (Ride ride in ridesData) {
      fs.addRide(ride);
    }
  }

  void _fillRideData() {
    ridesData.add(
      Ride(
        id: 1,
        title: "Golden Gate Bridge Ride",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Enjoy a scenic ride across the iconic Golden Gate Bridge with breathtaking views of San Francisco.",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.monday,
        latlng: const LatLng(37.8199, -122.4783),
        verified: true,
        verifiedBy: "mQOrVKoRv7NxRuFXFLzJznBIiYl1",
        createdBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        rideType: RideType.roadRide,
        rideDistance: 20,
      ),
    );
    ridesData.add(
      Ride(
        id: 2,
        title: "Central Park Loop",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Take a leisurely ride through the heart of Manhattan in the beautiful Central Park.",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.monday,
        latlng: const LatLng(40.785091, -73.968285),
        verified: false,
        verifiedBy: "",
        createdBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        rideType: RideType.roadRide,
        rideDistance: 20,
      ),
    );
    ridesData.add(
      Ride(
        id: 3,
        title: "Lakefront Trail",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Ride along the picturesque Lake Michigan and enjoy the stunning Chicago skyline.",
        snippet: "Best bike ride ever",
        startPointDesc: "Lakeshore drive near the pier.",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.monday,
        latlng: const LatLng(41.8833, -87.6197),
        verified: false,
        verifiedBy: "",
        createdBy: "mQOrVKoRv7NxRuFXFLzJznBIiYl1",
        rideType: RideType.roadRide,
        rideDistance: 20,
      ),
    );
    ridesData.add(
      Ride(
        id: 4,
        title: "Boston Harborwalk",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Cycle along the historic Boston Harbor and explore the city's waterfront.",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.monday,
        latlng: const LatLng(42.3601, -71.0589),
        verified: true,
        verifiedBy: "mQOrVKoRv7NxRuFXFLzJznBIiYl1",
        createdBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        rideType: RideType.roadRide,
      ),
    );
    ridesData.add(
      Ride(
        id: 5,
        title: "Los Angeles River Bike Path",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Follow the Los Angeles River through parks, neighborhoods, and urban landscapes.",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.monday,
        latlng: const LatLng(34.0522, -118.2437),
        verified: true,
        verifiedBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        createdBy: "mQOrVKoRv7NxRuFXFLzJznBIiYl1",
        rideType: RideType.roadRide,
        rideDistance: 20,
      ),
    );
    ridesData.add(
      Ride(
        id: 6,
        title: "Portland Eastbank Esplanade",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Enjoy a scenic ride along the Willamette River with views of downtown Portland.",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.monday,
        latlng: const LatLng(45.5175, -122.6651),
        verified: true,
        verifiedBy: "mQOrVKoRv7NxRuFXFLzJznBIiYl1",
        createdBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        rideType: RideType.roadRide,
        rideDistance: 20,
      ),
    );
    ridesData.add(
      Ride(
        id: 7,
        title: "Minneapolis Chain of Lakes",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Explore the interconnected lakes of Minneapolis on this beautiful bike path.",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.monday,
        latlng: const LatLng(44.9497, -93.3133),
        verified: true,
        verifiedBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        createdBy: "mQOrVKoRv7NxRuFXFLzJznBIiYl1",
        rideType: RideType.roadRide,
        rideDistance: 20,
      ),
    );
    ridesData.add(
      Ride(
        id: 8,
        title: "Austin Hike and Bike Trail",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Cycle along the scenic Lady Bird Lake in downtown Austin, Texas.",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.friday,
        latlng: const LatLng(30.2649, -97.7479),
        verified: false,
        verifiedBy: "",
        createdBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        rideType: RideType.gravelRide,
        rideDistance: 20,
      ),
    );
    ridesData.add(
      Ride(
        id: 9,
        title: "Seattle Burke-Gilman Trail",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Ride through parks, neighborhoods, and along scenic waterways on this popular Seattle trail.",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.monday,
        latlng: const LatLng(47.6607, -122.2886),
        verified: true,
        verifiedBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        createdBy: "mQOrVKoRv7NxRuFXFLzJznBIiYl1",
        rideType: RideType.gravelRide,
        rideDistance: 20,
      ),
    );
    ridesData.add(
      Ride(
        id: 10,
        title: "Denver Cherry Creek Trail",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Cycle along the Cherry Creek and enjoy the beautiful scenery of Denver.",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.tuesday,
        latlng: const LatLng(39.7392, -104.9903),
        verified: true,
        verifiedBy: "mQOrVKoRv7NxRuFXFLzJznBIiYl1",
        createdBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        rideType: RideType.gravelRide,
        rideDistance: 20,
      ),
    );
    ridesData.add(
      Ride(
        id: 11,
        title: "Cenna Cycle",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Gravel Ride, Leaves from the shop. This is a friendly ride with an occasional few spicy spots.",
        snippet: "Best bike ride ever",
        startPointDesc: "Start at the shop",
        contact: "Cenna Da Man!",
        phone: "555 123-4567",
        dow: DayOfWeekType.wednesday,
        latlng: const LatLng(40.135667689123494, -105.10335022137203),
        verified: true,
        verifiedBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        createdBy: "mQOrVKoRv7NxRuFXFLzJznBIiYl1",
        rideType: RideType.gravelRide,
        rideDistance: 20,
      ),
    );
    ridesData.add(
      Ride(
        id: 12,
        title: "Gravel Donkey Ride",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Leaves every Thursday evening from the Eagle parking lot at 5:00pm",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.thursday,
        latlng: const LatLng(40.0805057836106, -105.23549907690392),
        verified: true,
        verifiedBy: "mQOrVKoRv7NxRuFXFLzJznBIiYl1",
        createdBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        rideType: RideType.gravelRide,
        rideDistance: 20,
      ),
    );
    ridesData.add(
      Ride(
        id: 13,
        title: "Full Cycle",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc:
            "Road Rides leaving Tuesday and Thursday evening from the shop at 5:30pm",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.monday,
        latlng: const LatLng(40.017555, -105.258336),
        verified: false,
        verifiedBy: "",
        createdBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        rideType: RideType.gravelRide,
        rideDistance: 20,
      ),
    );

    ridesData.add(
      Ride(
        id: 14,
        title: "Tony's Awesome Ride",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc: "This ride leaves from my house whenever the FUCK I want!",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Ranger Adams",
        phone: "616 956-5434",
        dow: DayOfWeekType.sunday,
        latlng: const LatLng(42.405876, -85.277250),
        verified: true,
        verifiedBy: "mQOrVKoRv7NxRuFXFLzJznBIiYl1",
        createdBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        rideType: RideType.gravelRide,
        rideDistance: 20,
      ),
    );

    ridesData.add(
      Ride(
        id: 15,
        title: "Tucson Shootout",
        startTime: DateTime.parse("2024-03-15 14:44:00.000"),
        desc: "Probably the most famous ride in the country.",
        snippet: "Best bike ride ever",
        startPointDesc: "Just under the bridge",
        contact: "Jeff Miller",
        phone: "555 123-4567",
        dow: DayOfWeekType.saturday,
        latlng: const LatLng(32.231719, -110.959289),
        verified: false,
        verifiedBy: "",
        createdBy: "tDWKQAecW5Msw5yXPQK4h5n7MXR2",
        rideType: RideType.roadRide,
        rideDistance: 20,
      ),
    );

    // for (Ride ride in ridesData) {
    //   final Marker marker = Marker(
    //       markerId: MarkerId('marker_${ride.id.toString()}'),
    //       position: ride.latlng!,
    //       infoWindow: InfoWindow(
    //         onTap: () {
    //           rideIndex = ride.id!.toInt();
    //           print("Tapped on InfoWindo");
    //           showDetailsToggle = !showDetailsToggle;
    //           setState(() {});
    //         },
    //         title: ride.title,
    //         snippet: ride.desc,
    //       ),
    //       onTap: () {},
    //       icon: BitmapDescriptor.defaultMarker);
    //   _saveMarkers.add(marker);
    // }
  }

  // void addNewRide(LatLng point) {
  //   Navigator.of(context)
  //       .push(MaterialPageRoute(builder: (context) => const AddNewRide()));
  // }

  // Future<void> _selectTime(BuildContext context) async {
  //   final TimeOfDay? picked = await showTimePicker(
  //     context: context,
  //     initialTime: _selectedTime,
  //   );
  //   if (picked != null && picked != _selectedTime) {
  //     setState(() {
  //       _selectedTime = picked;
  //     });
  //   }
  // }

  void newRideDialog(LatLng latlng, bool isEdit) {
    RideType tmpRideType = RideType.roadRide;
    DayOfWeekType tmpDOW = DayOfWeekType.monday;
    // rideDow = tmpDOW;
    // rideType = tmpRideType;
    // rideStartTime = _selectedTime;
    //_selectedTime = rideStartTime!;
    // Init Fields for screen
    if (isEdit) {
      titleController.text = rideTitle!;
      descController.text = rideDesc!;
      snippetController.text = rideSnippet!;
      startPointController.text = rideStartPointDesc!;
      contactController.text = rideContact!;
      phoneController.text = ridePhone!;
      distanceController.text = rideDistance.toString();
      tmpRideType = rideType!;
      tmpDOW = rideDow!;
      _selectedTime = rideStartTime!;
    } else {
      rideDistance = 0;
      // rideDow = tmpDOW;
      // rideType = tmpRideType;
      // rideStartTime = _selectedTime;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colorScheme.onTertiary,
        title: isEdit
            ? const Text("Edit Ride Details")
            : const Text("Add a new Ride"),
        scrollable: true,
        content: StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Column(
              children: [
                MyTextField(
                    controller: titleController,
                    hintText: "Ride Title",
                    obscureText: false),
                MyTextField(
                    controller: descController,
                    hintText: "Ride Description",
                    obscureText: false),
                MyTextField(
                    controller: snippetController,
                    hintText: "Info Window Snippet",
                    obscureText: false),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                  child: DropdownButtonFormField(
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: context.colorScheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: context.colorScheme.outline),
                      ),
                      fillColor: context.colorScheme.onInverseSurface,
                      filled: true,
                      // hintText: "Day of Week",
                      // hintStyle:
                      //     TextStyle(color: context.colorScheme.outlineVariant),
                    ),
                    dropdownColor: context.colorScheme.onInverseSurface,
                    padding: EdgeInsets.zero,
                    value: tmpDOW,
                    onSaved: (newDay) {
                      setState(() {
                        tmpDOW = newDay!;
                        rideDow = tmpDOW;
                      });
                    },
                    onChanged: (newDay) {
                      setState(() {
                        tmpDOW = newDay!;
                        rideDow = tmpDOW;
                      });
                    },
                    items: DayOfWeekType.values.map((DayOfWeekType type) {
                      return DropdownMenuItem(
                          // value: type, child: Text(type.toString()));
                          value: type,
                          child: Text(type.titleName));
                    }).toList(),
                  ),
                ),
                /////// Time
                ///
                Padding(
                  padding:
                      const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: context.colorScheme.outlineVariant),

                      color: context.colorScheme.onInverseSurface,
                      //borderRadius: BorderRadius.circular(8),
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        await _selectTime(context).then((value) {
                          setState(() {
                            rideStartTime = _selectedTime;
                          });
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              '${_selectedTime.hourOfPeriod}:${_selectedTime.minute.toString().padLeft(2, '0')} ${_selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                              //style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 10.0),
                            child: Icon(
                                IconData(0xe662, fontFamily: 'MaterialIcons')),
                          )
                        ],
                      ),
                    ),
                  ),
                ),

                ///
                /////////
                Padding(
                  padding:
                      const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                  child: DropdownButtonFormField(
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: context.colorScheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: context.colorScheme.outline),
                      ),
                      fillColor: context.colorScheme.onInverseSurface,
                      filled: true,
                    ),
                    dropdownColor: context.colorScheme.onInverseSurface,
                    value: tmpRideType,
                    onSaved: (newRideType) {
                      setState(() {
                        tmpRideType = newRideType!;
                        rideType = tmpRideType;
                      });
                    },
                    onChanged: (newRideType) {
                      setState(() {
                        tmpRideType = newRideType!;
                        rideType = tmpRideType;
                      });
                    },
                    items: RideType.values.map((RideType type) {
                      return DropdownMenuItem(
                          // value: type, child: Text(type.toString()));
                          value: type,
                          child: Text(type.titleName));
                    }).toList(),
                  ),
                ),
                MyTextField(
                    controller: distanceController,
                    hintText: "Distance",
                    obscureText: false),
                // MyTextField(
                //     controller: startTimeController,
                //     hintText: "Start Time",
                //     obscureText: false),
                MyTextField(
                    controller: startPointController,
                    hintText: "Starting Point Description",
                    obscureText: false),
                MyTextField(
                    controller: contactController,
                    hintText: "Contact Name",
                    obscureText: false),
                MyTextField(
                    controller: phoneController,
                    hintText: "Contact Phone",
                    obscureText: false),
              ],
            );
          },
        ),
        actions: [
          _cancelNewRideButton(),
          _saveNewRideButton(latlng, isEdit),
        ],
      ),
    );
  }

  Widget _cancelNewRideButton() {
    return MaterialButton(
      onPressed: () {
        Navigator.pop(context);
        //clear controllers
        titleController.clear();
        descController.clear();
        snippetController.clear();
        dowController.clear();
        startPointController.clear();
        contactController.clear();
        phoneController.clear();
        startTimeController.clear();
        distanceController.clear();
      },
      child: const Text('Cancel'),
    );
  }

  Widget _saveNewRideButton(LatLng latLng, bool isEdit) {
    return MaterialButton(
      onPressed: () async {
        final FireStoreService fs = FireStoreService();
        final ride = Ride(
          title: titleController.text.trim(),
          desc: descController.text.trim(),
          snippet: snippetController.text.trim(),
          dow: rideDow,
          startTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day, rideStartTime!.hour, rideStartTime!.minute),
          startPointDesc: startPointController.text.trim(),
          contact: contactController.text.trim(),
          phone: phoneController.text.trim(),
          latlng: latLng,
          verified: false,
          verifiedBy: rideVerifiedBy,
          createdBy: user.uid,
          rideType: rideType,
          rideDistance: int.tryParse(distanceController.text.trim()),
        );
        if (isEdit) {
          await fs.updateRide(rideID, ride).then(
            (value) {
              _getRideData();
            },
          );
        } else {
          await fs.addRide(ride).then(
            (value) {
              _getRideData();
            },
          );
        }

        Navigator.pop(context);
        //clear controllers
        titleController.clear();
        descController.clear();
        snippetController.clear();
        dowController.clear();
        startPointController.clear();
        contactController.clear();
        phoneController.clear();
      },
      child: const Text('Save'),
    );
  }

  void _setMarker() async {
    final GoogleMapController controller = await mapController.future;
    LatLngBounds bounds = await controller.getVisibleRegion();

    final Set<Marker> newMarkers = Set<Marker>.from(_saveMarkers.where(
      (marker) => bounds.contains(marker.position),
    ));
    setState(() {
      //print("Set Markers");
      _markers = newMarkers;
    });
  }

  Future getRideDetails() async {
    await ridesDataFS.doc(rideID).get().then((ride) {
      // you can access the values by

      GeoPoint pos = ride["latlng"];
      LatLng latlng = LatLng(pos.latitude, pos.longitude);
      rideLatlng = latlng;
      rideTitle = ride['title'];
      rideDesc = ride['desc'];
      rideSnippet = ride['snippet'];
      rideDistance = ride['distance'];
      rideDow = DayOfWeekType.values[ride['dow']];
      rideStartPointDesc = ride['startPointDesc'];
      rideContact = ride['contactName'];
      ridePhone = ride['contactPhone'];
      rideVerified = ride['verified'];
      rideVerifiedBy = ride["verifiedBy"];
      DateTime myDateTime = (ride['startTime']).toDate();
      rideStartTime = TimeOfDay.fromDateTime(myDateTime);
      rideType = RideType.values[ride['rideType']];
    });
  }

  Widget showSearch() {
    //Providers
    final allSearchResults = ref.watch(placeResultsProvider);
    final searchFlag = ref.watch(searchToggleProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15.0, 40.0, 15.0, 5.0),
      child: Column(children: [
        Container(
          height: 50.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            //color: Colors.white,
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
              _debounce = Timer(const Duration(milliseconds: 700), () async {
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
    );
  }

  void showDetails() {
    //getRideDetails();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$rideTitle"),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 25.0,
              width: 100.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: rideVerified!
                    ? Colors.green.withOpacity(0.7)
                    : Colors.orange,
              ),
              child: rideVerified!
                  ? const Padding(
                      padding: EdgeInsets.only(left: 20.0, top: 3.0),
                      child: Text("Verified"),
                    )
                  : const Padding(
                      padding: EdgeInsets.only(left: 10, top: 3.0),
                      child: Text("UnVerified"),
                    ),
            ),
            const Gap(5),

            DisplayDlgText(topic: "Ride Type", text: rideType!.titleName),
            DisplayDlgText(topic: "Distance", text: rideDistance.toString()),
            DisplayDlgText(topic: "Start Point", text: rideStartPointDesc!),
            DisplayDlgText(topic: "Day of Week", text: rideDow!.titleName),
            //'${rideStartTime.hourOfPeriod}:${rideStartTime.minute.toString().padLeft(2, '0')} ${rideStartTime.period == DayPeriod.am ? 'AM' : 'PM'}',
            DisplayDlgText(
                topic: "Start Time",
                text:
                    '${rideStartTime!.hourOfPeriod}:${rideStartTime!.minute.toString().padLeft(2, '0')} ${rideStartTime!.period == DayPeriod.am ? 'AM' : 'PM'}'),
            DisplayDlgText(topic: "Contact", text: "$rideContact"),
            const Divider(
              height: 5.0,
              thickness: 5.0,
            ),
            Text("$rideDesc"),

            // Text("$rideStarttime"),
            // Text("$rideContact"),
          ],
        ),
        actions: [
          //_deleteRideButton(),
          _cancelDetailsButton(),
          _editDetailsButton(),
        ],
      ),
    );
  }

  Widget _editDetailsButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        newRideDialog(rideLatlng!, true);
      },
      child: const Text("Edit"),
    );
  }

  Widget _cancelDetailsButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Text("Close"),
    );
  }

  Widget _deleteRideButton() {
    return TextButton(
      style: TextButton.styleFrom(
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: const Text('Delete'),
      onPressed: () async {
        final FireStoreService fs = FireStoreService();
        print("RideID: $rideID");
        await fs.deleteRide(rideID).then((value) {
          _getRideData();
        });
        //_getRideData();
        setState(() {});
        Navigator.pop(context);
      },
    );
  }

  Widget placeMap() {
    return GoogleMap(
      mapType: MapType.normal,
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
      initialCameraPosition: _startPosition,
      markers: Set<Marker>.of(_saveMarkers),
      onCameraMove: (CameraPosition position) {
        // _updateMarkersPosition();
        // _checkLatLngInViewableArea();
        _setMarker();
      },
      onLongPress: (point) {
        rideLatlng = point;
        newRideDialog(point, false);
      },
      onTap: (point) {
        setState(() {
          gotoSearchedPlace(point.latitude, point.longitude);
        });
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
          title: const Text(appTitle),

          //backgroundColor: const Color(0xFFE2DFFF),
          backgroundColor: context.colorScheme.onTertiary),
      drawer: AppDrawer(
        onProfileTap: goToProfilePage,
        onSignOut: signUserOut,
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
                searchToggle ? showSearch() : Container(),
                //showDetailsToggle ? showDetails1() : Container(),
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
                                              //color: Colors.white,
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
          // Padding(
          //   padding: const EdgeInsets.only(left: 20.0),
          //   child: FloatingActionButton(
          //     onPressed: () {
          //       addRidesToFirestore();
          //     },
          //     child: const Icon(Icons.add),
          //   ),
          // ),
        ],
      ),
    );
  }

  Future<void> gotoSearchedPlace(double lat, double lng) async {
    final GoogleMapController controller = await mapController.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 10.5)));
    showDetailsToggle = false;
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
