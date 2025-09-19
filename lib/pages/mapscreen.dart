import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymap/constants/constants.dart';
import 'package:mymap/models/auto_complete_result.dart';
import 'package:mymap/models/ride_data.dart';
import 'package:mymap/pages/app_drawer.dart';
import 'package:mymap/pages/profile_page.dart';
import 'package:mymap/providers/providers.dart';
import 'package:mymap/services/firestore.dart';
import 'package:mymap/services/map_services.dart';
import 'package:mymap/services/sample_ride_service.dart';
import 'package:mymap/services/location_service.dart';
import 'package:mymap/services/migration_service.dart';
import 'package:mymap/repositories/ride_repository.dart';
import 'package:mymap/widgets/dialogs/responsive_ride_dialog.dart';
import 'package:mymap/widgets/dialogs/ride_info_dialog.dart';
import 'package:mymap/widgets/search/map_search_widget.dart';
import 'package:mymap/utils/extensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/gestures.dart';
import 'package:mymap/widgets/display_dlg_text.dart';
import 'package:mymap/widgets/my_textfield.dart';

class MapScreen extends ConsumerStatefulWidget {
  //const MapScreen({super.key});
  const MapScreen({Key? key}) : super(key: key);

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends ConsumerState<MapScreen> {
  //Position of initial map and camera is Boulder, CO

  CameraPosition _startPosition =
      const CameraPosition(target: _defaultPosition, zoom: _defaultZoom);

  static const LatLng _defaultPosition = LatLng(40.017555, -105.258336);
  static const double _defaultZoom = 10.5;
  static const int _searchDebounceMs = 700;

  ///
  ///

  final Set<Marker> _saveMarkers = <Marker>{};

  // Cached marker icons to avoid reloading
  Map<RideType, BitmapDescriptor>? _cachedMarkers;

  // Store ride data for quick access without additional Firestore calls
  final Map<String, Map<String, dynamic>> _ridesData = {};

  //Debounce to throttle async calls during location search
  Timer? _debounce;

  //Debounce to throttle viewport loading during camera movement
  Timer? _viewportLoadTimer;

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

/////////////////
  ///
  ///
  final Completer<GoogleMapController> mapController = Completer();

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
    _setMarker();

    // Debug: Check if map is ready
    debugPrint('Google Map created and ready');

    // Note: Sample rides already exist in database

    // Delay viewport loading until map is fully initialized
    Future.delayed(const Duration(milliseconds: 1000), () {
      _loadRidesInViewport();
    });
  }

  /// Handle camera movement - cancel any pending viewport load
  void _onCameraMove(CameraPosition position) {
    // Cancel any pending viewport load timer
    _viewportLoadTimer?.cancel();
  }

  /// Handle camera idle - trigger debounced viewport loading
  void _onCameraIdle() {
    // Cancel any existing timer
    _viewportLoadTimer?.cancel();

    // Start new timer with debounce
    _viewportLoadTimer = Timer(const Duration(milliseconds: 800), () {
      _loadRidesInViewport();
    });
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
            backgroundColor: context.colorScheme.surfaceContainerHighest,
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
      await showTimePicker(
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

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _runDatabaseMigration();
    // Note: Ride loading now handled by viewport loading in _onMapCreated()

    //setState(() {});
  }

  /// Runs the database migration to convert GeoPoint to separate lat/lng fields
  Future<void> _runDatabaseMigration() async {
    try {
      debugPrint('Starting database migration...');

      // First, let's inspect what's actually in the database
      await _inspectDatabaseDocument();

      // Force update to see if fields actually get written
      final result =
          await MigrationService.migrateGeoPointToLatLng(forceUpdate: true);

      debugPrint('Migration completed: ${result.summary}');

      if (result.wasSuccessful) {
        debugPrint('Migration successful! Verifying...');
        final verified = await MigrationService.verifyMigration();
        if (verified) {
          debugPrint('Migration verification passed ✅');
        } else {
          debugPrint('Migration verification failed ❌');
        }
      } else {
        debugPrint('Migration had errors: ${result.errors}');
      }

      // Inspect again after migration
      await _inspectDatabaseDocument();
    } catch (e) {
      debugPrint('Migration failed: $e');
    }
  }

  /// Inspects the first document to see what fields exist
  Future<void> _inspectDatabaseDocument() async {
    try {
      debugPrint('=== DOCUMENT INSPECTION (limit 1 from rides collection) ===');
      final querySnapshot =
          await FirebaseFirestore.instance.collection('rides').limit(1).get();
      debugPrint(
          'Inspection query returned ${querySnapshot.docs.length} documents');
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        debugPrint('Document ID: ${doc.id}');
        debugPrint('All fields in document:');
        data.forEach((key, value) {
          debugPrint('  $key: $value (${value.runtimeType})');
        });
        debugPrint('=== END INSPECTION ===');
      }
    } catch (e) {
      debugPrint('Failed to inspect document: $e');
    }
  }

  @override
  void dispose() {
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

  Future<void> _determinePosition() async {
    final locationService = LocationService();
    final result = await locationService.getCurrentLocation();

    if (!mounted) return;

    _startPosition = locationService.getCameraPosition(result);
    gotoSearchedPlace(result.position.latitude, result.position.longitude);

    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
    }

    setState(() {});
  }

  Future<void> _oldDeterminePosition() async {
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

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );

      if (mounted) {
        _startPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 11.0,
        );
        gotoSearchedPlace(position.latitude, position.longitude);
        setState(() {});
      }
    } catch (e) {
      // Fallback to default position if location fails
      if (mounted) {
        setState(() {
          _startPosition = const CameraPosition(
            target: _defaultPosition,
            zoom: _defaultZoom,
          );
        });
      }
    }

    //return await Geolocator.getCurrentPosition();
  }

  Future<void> _getRideData() async {
    debugPrint('=== _getRideData started ===');
    try {
      debugPrint('Clearing existing markers and cached data...');
      _saveMarkers.clear();
      _ridesData.clear(); // Clear cached data for fresh reload

      debugPrint('Loading marker icons...');
      // Load marker icons only if not cached
      _cachedMarkers ??= {
        RideType.gravelRide: await BitmapDescriptor.asset(
            const ImageConfiguration(devicePixelRatio: 1.0),
            'assets/mapicons/bikeRising.png'),
        RideType.roadRide: await BitmapDescriptor.asset(
            const ImageConfiguration(devicePixelRatio: 1.0),
            'assets/mapicons/roadRide.png'),
        RideType.mtbRide: await BitmapDescriptor.asset(
            const ImageConfiguration(devicePixelRatio: 1.0),
            'assets/mapicons/greenBike.png'),
        RideType.bikeEvent: await BitmapDescriptor.asset(
            const ImageConfiguration(devicePixelRatio: 1.0),
            'assets/mapicons/blueRide.png'),
      };
      debugPrint('Marker icons loaded/cached');

      debugPrint('Fetching rides from Firestore...');
      final querySnapshot = await ridesDataFS.get();
      debugPrint('Loaded ${querySnapshot.docs.length} rides from Firestore');

      debugPrint('Processing rides and creating markers...');
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Caching disabled to avoid data inconsistency issues
        // _ridesData[doc.id] = data;

        final rideTypeIndex = data['rideType'] as int? ?? 0;
        if (rideTypeIndex >= RideType.values.length) continue;

        final type = RideType.values[rideTypeIndex];
        final markerIcon = _cachedMarkers![type]!;

        final pos = data["latlng"] as GeoPoint?;
        if (pos == null) continue;

        final latlng = LatLng(pos.latitude, pos.longitude);
        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: latlng,
          infoWindow: InfoWindow(
            onTap: () {
              rideID = doc.id;
              setRideDetailsFromCache(doc.id);
              if (mounted) {
                showDetails();
                setState(() {});
              }
            },
            title: data["title"] as String? ?? 'Untitled Ride',
            snippet: data["snippet"] as String? ?? '',
          ),
          onTap: () {},
          icon: markerIcon,
        );
        _saveMarkers.add(marker);
      }

      debugPrint('Created ${_saveMarkers.length} markers');

      debugPrint('Calling setState to update UI...');
      if (mounted) {
        setState(() {});
      }
      debugPrint('setState completed');

      debugPrint('=== _getRideData completed successfully ===');
    } catch (e) {
      debugPrint('=== ERROR in _getRideData ===');
      debugPrint('Error details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rides: $e')),
        );
      }
    }
  }

  /// Load rides within the current map viewport
  Future<void> _loadRidesInViewport() async {
    debugPrint('=== _loadRidesInViewport started ===');

    final GoogleMapController controller = await mapController.future;
    if (controller == null) {
      debugPrint('Map controller not ready, skipping viewport load');
      return;
    }

    try {
      // Get current map bounds
      final LatLngBounds bounds = await controller.getVisibleRegion();

      debugPrint(
          'Viewport bounds: NE(${bounds.northeast.latitude}, ${bounds.northeast.longitude}), SW(${bounds.southwest.latitude}, ${bounds.southwest.longitude})');

      // Check for invalid bounds (map not ready yet)
      if (bounds.northeast.latitude <= -90 ||
          bounds.southwest.latitude <= -90 ||
          bounds.northeast.longitude <= -180 ||
          bounds.southwest.longitude <= -180) {
        debugPrint(
            'Invalid viewport bounds detected - map not ready yet, skipping load');
        return;
      }

      // Clear existing markers and cached data
      _saveMarkers.clear();
      _ridesData.clear();

      // Load marker icons only if not cached
      _cachedMarkers ??= {
        RideType.gravelRide: await BitmapDescriptor.asset(
            const ImageConfiguration(devicePixelRatio: 1.0),
            'assets/mapicons/bikeRising.png'),
        RideType.roadRide: await BitmapDescriptor.asset(
            const ImageConfiguration(devicePixelRatio: 1.0),
            'assets/mapicons/roadRide.png'),
        RideType.mtbRide: await BitmapDescriptor.asset(
            const ImageConfiguration(devicePixelRatio: 1.0),
            'assets/mapicons/greenBike.png'),
        RideType.bikeEvent: await BitmapDescriptor.asset(
            const ImageConfiguration(devicePixelRatio: 1.0),
            'assets/mapicons/blueRide.png'),
      };

      // Get rides in viewport using repository
      final repository = RideRepository();
      final rides = await repository.getRidesInViewport(
        northLat: bounds.northeast.latitude,
        southLat: bounds.southwest.latitude,
        eastLng: bounds.northeast.longitude,
        westLng: bounds.southwest.longitude,
      );

      debugPrint('Found ${rides.length} rides in viewport');

      // Debug: If no rides in viewport, check total rides in database
      if (rides.isEmpty) {
        debugPrint(
            '=== DEBUG: No rides in viewport, checking total rides in database ===');
        try {
          final querySnapshot =
              await FirebaseFirestore.instance.collection('rides').get();
          debugPrint('Total rides in database: ${querySnapshot.docs.length}');

          if (querySnapshot.docs.isNotEmpty) {
            debugPrint('Sample ride locations and data structure:');
            for (var doc in querySnapshot.docs.take(3)) {
              final data = doc.data();
              debugPrint('  - Doc ID: ${doc.id}');
              debugPrint('  - Title: ${data['title']}');
              debugPrint(
                  '  - latlng field type: ${data['latlng'].runtimeType}');
              debugPrint('  - latlng value: ${data['latlng']}');

              final latlng = data['latlng'] as GeoPoint?;
              if (latlng != null) {
                debugPrint(
                    '  - Parsed: ${latlng.latitude}, ${latlng.longitude}');
              } else {
                debugPrint('  - Failed to parse as GeoPoint');
              }
              debugPrint('---');
            }
          }
        } catch (e) {
          debugPrint('Error checking total rides: $e');
        }
        debugPrint('=== END DEBUG ===');
      }

      // Create markers for rides in viewport
      for (var ride in rides) {
        if (ride.latlng == null) continue;

        // Store ride data for quick access (convert back to map format)
        final data = {
          'id': ride.id,
          'title': ride.title,
          'desc': ride.desc,
          'snippet': ride.snippet,
          'dow': ride.dow?.index,
          'startTime': ride.startTime,
          'startPointDesc': ride.startPointDesc,
          'contactName': ride.contact,
          'contactPhone': ride.phone,
          'latlng': GeoPoint(ride.latlng!.latitude, ride.latlng!.longitude),
          'verified': ride.verified,
          'verifiedBy': ride.verifiedBy,
          'rideType': ride.rideType?.index,
          'distance': ride.rideDistance,
          'createdBy': ride.createdBy,
          'verifiedByUsers': ride.verifiedByUsers,
          'verificationCount': ride.verificationCount,
          'averageRating': ride.averageRating,
          'totalRatings': ride.totalRatings,
          'userRatings': ride.userRatings,
          'rideWithGpsUrl': ride.rideWithGpsUrl,
          'stravaUrl': ride.stravaUrl,
          'difficulty': ride.difficulty?.index,
        };

        // Caching disabled to avoid data inconsistency issues
        final docId = ride.id ?? 'unknown_${rides.indexOf(ride)}';
        // _ridesData[docId] = data;

        final type = ride.rideType ?? RideType.roadRide;
        final markerIcon = _cachedMarkers![type]!;

        final marker = Marker(
          markerId: MarkerId(docId),
          position: ride.latlng!,
          infoWindow: InfoWindow(
            onTap: () {
              rideID = docId;
              // setRideDetailsFromCache(docId); // No longer using cache
              if (mounted) {
                showDetails();
                setState(() {});
              }
            },
            title: ride.title ?? 'Untitled Ride',
            snippet: ride.snippet ?? '',
          ),
          onTap: () {},
          icon: markerIcon,
        );
        _saveMarkers.add(marker);
      }

      debugPrint('Created ${_saveMarkers.length} markers for viewport');

      // Update UI
      if (mounted) {
        setState(() {});
      }

      debugPrint('=== _loadRidesInViewport completed successfully ===');
    } catch (e) {
      debugPrint('=== ERROR in _loadRidesInViewport ===');
      debugPrint('Error details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rides in viewport: $e')),
        );
      }
    }
  }

// Sample data method removed - using existing database with 42 rides

  void newRideDialog(LatLng latlng, bool isEdit) {
    showDialog(
      context: context,
      barrierDismissible:
          true, // Allow barrier dismissal but handle unsaved changes
      builder: (context) => ResponsiveRideDialog(
        location: latlng,
        isEdit: isEdit,
        existingRide: isEdit ? _getCurrentRideFromData() : null,
        onSave: _handleRideSave,
        onCancel: () {
          debugPrint('Dialog cancelled by user');
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editRideDialog(Ride existingRide) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ResponsiveRideDialog(
        location: existingRide.latlng!,
        isEdit: true,
        existingRide: existingRide,
        onSave: _handleRideSave,
        onCancel: () {
          debugPrint('Edit dialog cancelled by user');
          Navigator.pop(context);
        },
      ),
    );
  }

  Ride? _getCurrentRideFromData() {
    // Create ride from current form data for editing
    return Ride(
      title: rideTitle,
      desc: rideDesc,
      snippet: rideSnippet,
      dow: rideDow,
      startTime: rideStartTime != null
          ? DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day, rideStartTime!.hour, rideStartTime!.minute)
          : null,
      startPointDesc: rideStartPointDesc,
      contact: rideContact,
      phone: ridePhone,
      latlng: rideLatlng,
      verified: rideVerified,
      verifiedBy: rideVerifiedBy,
      rideType: rideType,
      rideDistance: rideDistance,
    );
  }

  Future<void> _handleRideSave(Ride ride, bool isEdit) async {
    debugPrint('=== _handleRideSave called ===');
    debugPrint('Ride title: ${ride.title}');
    debugPrint('Is edit: $isEdit');
    debugPrint('User auth status: ${FirebaseAuth.instance.currentUser?.uid}');

    final repository = RideRepository();
    try {
      debugPrint('About to save ride to repository...');

      if (isEdit) {
        debugPrint('Updating existing ride...');
        await repository.updateRide(rideID, ride);
        debugPrint('Ride updated successfully');
      } else {
        debugPrint('Adding new ride...');
        final rideId = await repository.addRide(ride);
        debugPrint('Ride created with ID: $rideId');
      }

      debugPrint('Repository operation completed successfully');

      if (!mounted) {
        debugPrint('Widget not mounted, skipping UI updates');
        return;
      }

      debugPrint('About to refresh map data...');

      // Refresh the map data (dialog closes itself)
      _loadRidesInViewport();

      debugPrint('Map data refresh initiated');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit
              ? 'Ride updated successfully!'
              : 'Ride created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint('Success message shown, _handleRideSave completing');
    } catch (e) {
      debugPrint('=== ERROR in _handleRideSave ===');
      debugPrint('Error details: $e');
      debugPrint('Error type: ${e.runtimeType}');

      if (!mounted) return;

      // Check if this is a timeout error (which means operation likely succeeded)
      if (e.toString().contains('timed out') ||
          e.toString().contains('TimeoutException')) {
        debugPrint('Treating timeout as soft success - refreshing data');

        // Refresh map data since operation likely succeeded
        _loadRidesInViewport();

        // Show optimistic success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Ride updated (please verify)'
                : 'Ride created (please verify)'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Show actual error message for real failures
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save ride: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _oldNewRideDialog(LatLng latlng, bool isEdit) {
    RideType tmpRideType = RideType.roadRide;
    DayOfWeekType tmpDOW = DayOfWeekType.monday;
    // rideDow = tmpDOW;
    // rideType = tmpRideType;
    // rideStartTime = _selectedTime;
    //_selectedTime = rideStartTime!;
    // Init Fields for screen
    if (isEdit) {
      titleController.text = rideTitle ?? '';
      descController.text = rideDesc ?? '';
      snippetController.text = rideSnippet ?? '';
      startPointController.text = rideStartPointDesc ?? '';
      contactController.text = rideContact ?? '';
      phoneController.text = ridePhone ?? '';
      distanceController.text = rideDistance?.toString() ?? '0';
      tmpRideType = rideType ?? RideType.roadRide;
      tmpDOW = rideDow ?? DayOfWeekType.monday;
      _selectedTime = rideStartTime ?? TimeOfDay.now();
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
                    initialValue: tmpDOW,
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
                    initialValue: tmpRideType,
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
          await fs.updateRide(rideID, ride);
        } else {
          await fs.addRide(ride);
        }

        if (!mounted) return;

        _loadRidesInViewport();
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
      // TODO: Implement visible marker filtering if needed
    });
  }

  // Fast method using cached data instead of Firestore call
  Ride? _createRideFromCache(String docId) {
    debugPrint('=== _createRideFromCache called with docId: $docId ===');
    debugPrint('_ridesData cache contains ${_ridesData.length} entries');
    debugPrint('Cache keys: ${_ridesData.keys.toList()}');
    final data = _ridesData[docId];
    if (data == null) {
      debugPrint('No data found in cache for docId: $docId');
      return null;
    }

    try {
      GeoPoint pos = data["latlng"];
      LatLng latlng = LatLng(pos.latitude, pos.longitude);

      return Ride(
        id: null, // Using docId as rideId parameter instead
        title: data['title'],
        desc: data['desc'],
        snippet: data['snippet'],
        dow: data['dow'] != null ? DayOfWeekType.values[data['dow']] : null,
        startTime: data['startTime'] is DateTime
            ? data['startTime']
            : data['startTime']?.toDate(),
        startPointDesc: data['startPointDesc'],
        contact: data['contactName'],
        phone: data['contactPhone'],
        latlng: latlng,
        verified: data['verified'] ?? false,
        verifiedBy: data['verifiedBy'],
        createdBy: data['createdBy'],
        rideType: data['rideType'] != null
            ? RideType.values[data['rideType']]
            : RideType.roadRide,
        rideDistance: data['distance'],
        verifiedByUsers: data['verifiedByUsers'] != null
            ? List<String>.from(data['verifiedByUsers'])
            : [],
        verificationCount: data['verificationCount'] ?? 0,
        averageRating: data['averageRating']?.toDouble(),
        totalRatings: data['totalRatings'] ?? 0,
        userRatings: data['userRatings'] != null
            ? Map<String, int>.from(data['userRatings'])
            : {},
        rideWithGpsUrl: data['rideWithGpsUrl'],
        stravaUrl: data['stravaUrl'],
        difficulty: data['difficulty'] != null
            ? RideDifficulty.values[data['difficulty']]
            : null,
      );
    } catch (e) {
      debugPrint('Error creating Ride from cached data: $e');
      return null;
    }
  }

  void setRideDetailsFromCache(String docId) {
    final data = _ridesData[docId];
    if (data == null) {
      debugPrint(
          'No cached data found for ride $docId, falling back to Firestore');
      getRideDetails();
      return;
    }

    try {
      GeoPoint pos = data["latlng"];
      LatLng latlng = LatLng(pos.latitude, pos.longitude);
      rideLatlng = latlng;
      rideTitle = data['title'];
      rideDesc = data['desc'];
      rideSnippet = data['snippet'];
      rideDistance = data['distance'];
      rideDow = DayOfWeekType.values[data['dow']];
      rideStartPointDesc = data['startPointDesc'];
      rideContact = data['contactName'];
      ridePhone = data['contactPhone'];
      rideVerified = data['verified'];
      rideVerifiedBy = data["verifiedBy"];
      DateTime myDateTime = (data['startTime']).toDate();
      rideStartTime = TimeOfDay.fromDateTime(myDateTime);
      rideType = RideType.values[data['rideType']];
    } catch (e) {
      debugPrint(
          'Error loading cached ride data: $e, falling back to Firestore');
      getRideDetails();
    }
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
                          ref
                              .read(searchToggleProvider.notifier)
                              .toggleSearch();
                        }
                      });
                    },
                    icon: const Icon(Icons.close))),
            onChanged: (value) {
              if (_debounce?.isActive ?? false) {
                _debounce?.cancel();
              }
              _debounce = Timer(const Duration(milliseconds: _searchDebounceMs),
                  () async {
                if (value.length > 2) {
                  if (!searchFlag.searchToggle) {
                    ref.read(searchToggleProvider.notifier).toggleSearch();
                  }

                  List<AutoCompleteResult> searchResults =
                      await MapServices().searchPlaces(value);

                  ref
                      .read(placeResultsProvider.notifier)
                      .setResults(searchResults);
                } else {
                  List<AutoCompleteResult> emptyList = [];
                  ref.read(placeResultsProvider.notifier).setResults(emptyList);
                }
              });
            },
          ),
        )
      ]),
    );
  }

  void showDetails() async {
    debugPrint('=== showDetails called for rideID: $rideID ===');

    try {
      // Fetch the ride directly from Firestore instead of using cache
      final repository = RideRepository();
      final ride = await repository.getRideById(rideID);

      if (ride == null) {
        debugPrint('Ride not found in Firestore for ID: $rideID');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride not found')),
          );
        }
        return;
      }

      debugPrint(
          'Successfully fetched ride from Firestore, checking permissions...');
      final canEdit = _canUserEditRide(ride);
      debugPrint('User can edit: $canEdit');

      if (!mounted) return;

      debugPrint('Opening RideInfoDialog...');
      showDialog(
        context: context,
        builder: (context) => RideInfoDialog(
          ride: ride,
          rideId: rideID,
          onEdit: () {
            debugPrint('Edit button pressed');
            // Close the dialog and open the edit dialog
            _editRideDialog(ride);
          },
          onDelete: canEdit
              ? () {
                  debugPrint('Delete button pressed');
                  // Handle ride deletion
                  _deleteRide(rideID);
                }
              : null,
        ),
      );
    } catch (e) {
      debugPrint('Error fetching ride details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ride details: $e')),
        );
      }
    }
  }

  bool _canUserEditRide(Ride ride) {
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('=== _canUserEditRide check ===');
    debugPrint('Current user: ${currentUser?.uid}');
    debugPrint('Ride created by: ${ride.createdBy}');

    if (currentUser == null) {
      debugPrint('No current user - cannot edit');
      return false;
    }

    // Allow editing if user created the ride
    final canEdit = ride.createdBy == currentUser.uid;
    debugPrint('Can edit: $canEdit');
    return canEdit;
  }

  Future<void> _deleteRide(String rideId) async {
    debugPrint('=== _deleteRide called for rideId: $rideId ===');

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting ride...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Retry logic for Firestore connectivity issues
    int maxRetries = 3;
    int retryDelay = 1; // seconds

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('Delete attempt $attempt of $maxRetries');
        final repository = RideRepository();
        debugPrint('Calling repository.deleteRide...');
        await repository.deleteRide(rideId);
        debugPrint('Repository.deleteRide completed successfully');

        // Refresh the map data
        debugPrint('Refreshing map data...');
        await _loadRidesInViewport();
        debugPrint('Map data refresh completed');

        if (mounted) {
          debugPrint('Showing success message');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return; // Success - exit the retry loop
      } catch (e) {
        debugPrint('Delete attempt $attempt failed: $e');

        // Check if it's a connectivity issue that we should retry
        bool shouldRetry = e.toString().contains('unavailable') ||
            e.toString().contains('timeout') ||
            e.toString().contains('network');

        if (shouldRetry && attempt < maxRetries) {
          debugPrint('Retrying in $retryDelay seconds...');
          await Future.delayed(Duration(seconds: retryDelay));
          retryDelay *= 2; // Exponential backoff
        } else {
          // Final failure or non-retryable error
          debugPrint('Final error in _deleteRide: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(shouldRetry
                    ? 'Failed to delete ride after $maxRetries attempts. Please check your connection and try again.'
                    : 'Failed to delete ride: ${e.toString().replaceAll('RideRepositoryException: Failed to delete ride: ', '')}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          break;
        }
      }
    }
  }

  Widget _editDetailsButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        // Note: This function may need current ride data for proper editing
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

  Widget placeMap() {
    return GoogleMap(
      mapType: MapType.normal,
      onMapCreated: _onMapCreated,
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      zoomControlsEnabled: false,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: false,
      trafficEnabled: false,
      buildingsEnabled: true,
      indoorViewEnabled: true,
      liteModeEnabled: false, // Ensure full map mode
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(
          () => EagerGestureRecognizer(),
        ),
      },
      initialCameraPosition: _startPosition,
      markers: _saveMarkers,
      onLongPress: (point) {
        rideLatlng = point;
        newRideDialog(point, false);
      },
      onTap: (point) {
        debugPrint('Map tapped at: ${point.latitude}, ${point.longitude}');
        // Don't center the map on tap - let users drag to navigate naturally
        // Only update the current position for reference
        setState(() {
          // Just update the state without moving the camera
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    //Providers - removed unused provider watchers since MapSearchWidget handles its own state

    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 50.0, centerTitle: false, title: const Text(appTitle)),
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
                MapSearchWidget(
                  isVisible: searchToggle,
                  onLocationSelected: (lat, lng) {
                    gotoSearchedPlace(lat, lng);
                    setState(() {
                      searchToggle = false;
                    });
                  },
                  onClose: () {
                    setState(() {
                      searchToggle = false;
                    });
                  },
                ),
                //showDetailsToggle ? showDetails1() : Container(),
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
              icon: const Icon(
                Icons.search,
                size: 24,
              ),
              label: const Text('Search'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
        CameraPosition(target: LatLng(lat, lng), zoom: _defaultZoom)));
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
          ref.read(searchToggleProvider.notifier).toggleSearch();
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
