import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart'
    hide ClusterManager, Cluster;
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:http/http.dart' as http;
import 'package:mymap/constants/constants.dart';
import 'package:mymap/models/auto_complete_result.dart';
import 'package:mymap/models/ride_data.dart';
import 'package:mymap/models/cluster_marker.dart';
import 'package:mymap/pages/app_drawer.dart';
import 'package:mymap/pages/profile_page.dart';
import 'package:mymap/providers/providers.dart';
import 'package:mymap/services/firestore.dart';
import 'package:mymap/services/map_services.dart';
import 'package:mymap/services/sample_ride_service.dart';
import 'package:mymap/services/location_service.dart';
import 'package:mymap/services/migration_service.dart';
import 'package:mymap/services/cluster_icon_service.dart';
import 'package:mymap/repositories/ride_repository.dart';
import 'package:mymap/widgets/dialogs/responsive_ride_dialog.dart';
import 'package:mymap/widgets/dialogs/ride_info_dialog.dart';
import 'package:mymap/widgets/search/map_search_widget.dart';
import 'package:mymap/utils/extensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/gestures.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends ConsumerState<MapScreen> {
  // Map configuration
  CameraPosition _startPosition =
      const CameraPosition(target: _defaultPosition, zoom: _defaultZoom);

  static const LatLng _defaultPosition = LatLng(40.017555, -105.258336);
  static const double _defaultZoom = 10.5;

  // Clustering variables
  late ClusterManager<ClusterRideMarker> _clusterManager;
  Set<Marker> _markers = <Marker>{};
  List<ClusterRideMarker> _clusterItems = [];

  // Icon caching
  final Map<RideType, BitmapDescriptor> _rideTypeIcons = {};
  bool _iconsLoaded = false;

  // Timers for debouncing
  Timer? _debounce;
  Timer? _viewportLoadTimer;

  // UI state
  final TimeOfDay _selectedTime = TimeOfDay.now();
  final DateTime _selectedDT = DateTime.now();
  bool searchToggle = false;
  bool showDetailsToggle = false;

  // Debug state
  bool _isLoadingRides = false;
  int _totalRidesLoaded = 0;
  String _lastLoadError = '';
  bool _useSimpleMarkers = false; // Custom clustering implementation
  final bool _useCustomClustering =
      true; // Bypass broken google_maps_cluster_manager_2

  // Ride data state
  LatLng? tappedPoint;
  String rideID = '';
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

  // Controllers
  final Completer<GoogleMapController> mapController = Completer();
  final _searchController = TextEditingController();
  final List<TextEditingController> _formControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _clusterItems = [];

    _checkFirestoreConnectivity();
    _determinePosition();
    // _runDatabaseMigration();
  }

  void _initializeControllers() {
    final controllers = [
      TextEditingController(), // title
      TextEditingController(), // desc
      TextEditingController(), // snippet
      TextEditingController(), // dow
      TextEditingController(), // startPoint
      TextEditingController(), // contact
      TextEditingController(), // phone
      TextEditingController(), // startTime
      TextEditingController(), // distance
    ];
    _formControllers.addAll(controllers);
  }

  void _onMapCreated(GoogleMapController controller) {
    debugPrint('🚀 === _onMapCreated() STARTED ===');
    mapController.complete(controller);

    debugPrint('🚀 Initializing cluster manager...');
    _initializeClusterManager();

    debugPrint('🚀 Loading ride type icons...');
    _loadRideTypeIcons();

    debugPrint('🚀 Google Map created and ready');
    debugPrint('🚀 Current cluster items: ${_clusterItems.length}');
    debugPrint('🚀 Current markers: ${_markers.length}');

    // Wait longer for map to be fully ready, then set initial camera position
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mounted) {
        debugPrint('🚀 Setting initial camera position for cluster manager');
        try {
          final bounds = await controller.getVisibleRegion();
          final initialPosition = CameraPosition(
            target: LatLng(
              (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
              (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
            ),
            zoom: await controller.getZoomLevel(),
          );
          debugPrint(
              '🚀 Initial camera position: ${initialPosition.target} (zoom: ${initialPosition.zoom})');
          _clusterManager.onCameraMove(initialPosition);
        } catch (e) {
          debugPrint('⚠️ Could not set initial camera position: $e');
        }
      }
    });

    // Delay viewport loading until map is fully initialized
    Future.delayed(const Duration(milliseconds: 1500), () {
      debugPrint('🚀 Delayed viewport loading triggered');
      _loadRidesInViewport();
    });
    debugPrint('🚀 === _onMapCreated() COMPLETED ===');
  }

  Future<void> _loadRideTypeIcons() async {
    try {
      debugPrint('Loading ride type icons...');

      final iconPaths = {
        RideType.gravelRide: 'assets/mapicons/bikeRising.png',
        RideType.roadRide: 'assets/mapicons/roadRide.png',
        RideType.mtbRide: 'assets/mapicons/greenBike.png',
        RideType.bikeEvent: 'assets/mapicons/blueRide.png',
      };

      for (final entry in iconPaths.entries) {
        try {
          _rideTypeIcons[entry.key] = await BitmapDescriptor.asset(
            const ImageConfiguration(devicePixelRatio: 1.0),
            entry.value,
          );
        } catch (e) {
          debugPrint('Failed to load icon for ${entry.key}: $e');
          // Use default marker as fallback
          _rideTypeIcons[entry.key] = BitmapDescriptor.defaultMarker;
        }
      }

      _iconsLoaded = true;
      debugPrint('✅ Ride type icons loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading ride type icons: $e');
      _iconsLoaded = false;
    }
  }

  void _initializeClusterManager() {
    debugPrint('🎯 === _initializeClusterManager() STARTED ===');
    debugPrint('🎯 Initializing with ${_clusterItems.length} cluster items');

    _clusterManager = ClusterManager<ClusterRideMarker>(
      _clusterItems,
      _updateMarkers,
      markerBuilder: _buildClusterMarker,
      // AGGRESSIVE FIX 1: Force individual markers at current zoom
      levels: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      extraPercent: 0.0, // No extra bounds
      stopClusteringZoom: 11.0, // Stop clustering at zoom 11 (current is 10.5)
    );

    debugPrint('🎯 Cluster manager initialized with aggressive settings');
    debugPrint(
        '🎯 stopClusteringZoom: 11.0 (current zoom ~10.5 should show individual markers)');
    debugPrint('🎯 === _initializeClusterManager() COMPLETED ===');
  }

  void _updateMarkers(Set<Marker> markers) {
    debugPrint('🗺️ === _updateMarkers() CALLED ===');
    debugPrint('🗺️ Received ${markers.length} markers from cluster manager');
    debugPrint('🗺️ Current _markers count before update: ${_markers.length}');

    if (mounted) {
      setState(() {
        _markers = markers;
      });
      debugPrint(
          '🗺️ ✅ State updated: _markers now has ${_markers.length} markers');

      // Debug first few markers
      final markersToShow = markers.take(3);
      for (final marker in markersToShow) {
        debugPrint(
            '🗺️ Marker: ${marker.markerId.value} at ${marker.position}');
      }
    } else {
      debugPrint('🗺️ ❌ Widget not mounted, skipping marker update');
    }
    debugPrint('🗺️ === _updateMarkers() COMPLETED ===');
  }

  Future<Marker> _buildClusterMarker(Cluster<ClusterRideMarker> cluster) async {
    debugPrint(
        '🏗️ Building marker for cluster: ${cluster.getId()} (${cluster.count} items)');
    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      onTap: () => _handleMarkerTap(cluster),
      icon: await _getClusterIcon(cluster),
      infoWindow: cluster.isMultiple
          ? InfoWindow(
              title: '${cluster.count} Rides',
              snippet: 'Tap to view details or zoom in',
            )
          : InfoWindow(
              title: cluster.items.first.title,
              snippet: cluster.items.first.snippet,
            ),
    );
  }

  Future<BitmapDescriptor> _getClusterIcon(
      Cluster<ClusterRideMarker> cluster) async {
    debugPrint(
        '🎨 Getting icon for cluster: ${cluster.getId()} (multiple: ${cluster.isMultiple})');
    if (cluster.isMultiple) {
      // For clusters, use the cluster icon service
      return await ClusterIconService.getCachedClusterIcon(cluster.count);
    } else {
      // For individual markers, use ride type specific icons
      final item = cluster.items.first;
      if (_iconsLoaded && _rideTypeIcons.containsKey(item.rideType)) {
        debugPrint('🎨 Using custom icon for ${item.rideType}');
        return _rideTypeIcons[item.rideType]!;
      } else {
        debugPrint('🎨 Using default marker icon');
        return BitmapDescriptor.defaultMarker;
      }
    }
  }

  void _handleMarkerTap(Cluster<ClusterRideMarker> cluster) {
    debugPrint(
        '👆 Marker tapped: ${cluster.getId()} (multiple: ${cluster.isMultiple})');
    if (cluster.isMultiple) {
      if (cluster.count <= 10) {
        _showClusterDetailsDialog(cluster);
      } else {
        _zoomToCluster(cluster);
      }
    } else {
      // Single marker, show ride details
      final item = cluster.items.first;
      rideID = item.id;
      showDetails();
    }
  }

  void _showClusterDetailsDialog(Cluster<ClusterRideMarker> cluster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.group,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text('${cluster.count} Rides in this area'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.separated(
            itemCount: cluster.items.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = cluster.items.elementAt(index);
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getRideTypeIconData(item.rideType),
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                subtitle: item.snippet.isNotEmpty
                    ? Text(
                        item.snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  Navigator.pop(context);
                  rideID = item.id;
                  showDetails();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _zoomToCluster(cluster);
            },
            icon: const Icon(Icons.zoom_in, size: 18),
            label: const Text('Zoom In'),
          ),
        ],
      ),
    );
  }

  Future<void> _zoomToCluster(Cluster<ClusterRideMarker> cluster) async {
    final GoogleMapController controller = await mapController.future;

    try {
      final bounds = _getBoundsFromItems(cluster.items);
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    } catch (e) {
      // Fallback: zoom to cluster center
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: cluster.location,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  LatLngBounds _getBoundsFromItems(Iterable<ClusterRideMarker> items) {
    if (items.isEmpty) {
      return LatLngBounds(
        southwest: _defaultPosition,
        northeast: _defaultPosition,
      );
    }

    double minLat = items.first.location.latitude;
    double maxLat = items.first.location.latitude;
    double minLng = items.first.location.longitude;
    double maxLng = items.first.location.longitude;

    for (final item in items) {
      minLat =
          minLat < item.location.latitude ? minLat : item.location.latitude;
      maxLat =
          maxLat > item.location.latitude ? maxLat : item.location.latitude;
      minLng =
          minLng < item.location.longitude ? minLng : item.location.longitude;
      maxLng =
          maxLng > item.location.longitude ? maxLng : item.location.longitude;
    }

    const double padding = 0.001;

    return LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  IconData _getRideTypeIconData(RideType type) {
    switch (type) {
      case RideType.roadRide:
        return Icons.directions_bike;
      case RideType.gravelRide:
        return Icons.terrain;
      case RideType.mtbRide:
        return Icons.forest;
      case RideType.bikeEvent:
        return Icons.event;
    }
  }

  void _onCameraMove(CameraPosition position) {
    debugPrint(
        '📹 Camera moving to: ${position.target} (zoom: ${position.zoom})');
    _viewportLoadTimer?.cancel();
    debugPrint('📹 Calling _clusterManager.onCameraMove()');
    _clusterManager.onCameraMove(position);
  }

  void _onCameraIdle() {
    debugPrint('📹 === Camera idle - triggering updates ===');
    debugPrint('📹 Calling _clusterManager.updateMap()');
    _clusterManager.updateMap();

    _viewportLoadTimer?.cancel();
    _viewportLoadTimer = Timer(const Duration(milliseconds: 800), () {
      debugPrint('📹 Viewport load timer triggered after camera idle');
      _loadRidesInViewport();
    });
  }

  // User and authentication
  final user = FirebaseAuth.instance.currentUser!;

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  void goToProfilePage() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  Future<void> _checkFirestoreConnectivity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final testDoc = await FirebaseFirestore.instance
            .collection('rides')
            .limit(1)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 10));
        debugPrint(
            '✅ Firestore connectivity: OK (${testDoc.docs.length} docs)');
      }
    } catch (e) {
      debugPrint('❌ Firestore connectivity test failed: $e');
    }
  }

  Future<void> _runDatabaseMigration() async {
    try {
      final result = await MigrationService.migrateGeoPointToLatLng();
      debugPrint('Migration result: ${result.summary}');
    } catch (e) {
      debugPrint('Migration failed: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _formControllers) {
      controller.dispose();
    }
    _debounce?.cancel();
    _viewportLoadTimer?.cancel();
    ClusterIconService.clearCache();
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

  Future<void> _loadRidesInViewport() async {
    debugPrint('🚀 === _loadRidesInViewport() STARTED ===');

    if (mounted) {
      setState(() {
        _isLoadingRides = true;
        _lastLoadError = '';
      });
    }

    final GoogleMapController controller = await mapController.future;

    try {
      final bounds = await controller.getVisibleRegion();
      debugPrint(
          '📍 Map bounds: NE(${bounds.northeast.latitude}, ${bounds.northeast.longitude}) SW(${bounds.southwest.latitude}, ${bounds.southwest.longitude})');

      if (bounds.northeast.latitude <= -90 ||
          bounds.southwest.latitude <= -90) {
        debugPrint('❌ Invalid bounds detected, skipping viewport load');
        if (mounted) {
          setState(() {
            _isLoadingRides = false;
            _lastLoadError = 'Invalid map bounds';
          });
        }
        return;
      }

      debugPrint(
          '📊 Current cluster items before load: ${_clusterItems.length}');
      debugPrint('📊 Current markers before load: ${_markers.length}');

      final repository = RideRepository();
      final rides = await repository.getRidesInViewport(
        northLat: bounds.northeast.latitude,
        southLat: bounds.southwest.latitude,
        eastLng: bounds.northeast.longitude,
        westLng: bounds.southwest.longitude,
      );

      debugPrint('📈 Repository returned ${rides.length} rides');

      // Debug each ride's data
      for (int i = 0; i < rides.length && i < 3; i++) {
        final ride = rides[i];
        debugPrint(
            '🚴 Ride $i: ${ride.title} at ${ride.latlng} (lat: ${ride.latitude}, lng: ${ride.longitude})');
      }

      if (_useSimpleMarkers) {
        // Debug mode: Use simple markers instead of clustering
        debugPrint('🔧 DEBUG MODE: Using simple markers instead of clustering');
        final simpleMarkers = _createSimpleMarkers(rides);

        if (mounted) {
          setState(() {
            _markers = simpleMarkers;
            _totalRidesLoaded = rides.length;
            _isLoadingRides = false;
          });
          debugPrint(
              '✅ State updated with ${simpleMarkers.length} simple markers');
        }
      } else if (_useCustomClustering) {
        // NUCLEAR OPTION: Custom clustering implementation
        debugPrint('🚀 NUCLEAR OPTION: Using custom clustering implementation');
        final customMarkers = await _createCustomClusteredMarkers(rides);

        if (mounted) {
          setState(() {
            _markers = customMarkers;
            _totalRidesLoaded = rides.length;
            _isLoadingRides = false;
          });
          debugPrint(
              '✅ State updated with ${customMarkers.length} custom clustered markers');
        }
      } else {
        // Normal mode: Use clustering
        final newClusterItems = ClusterRideMarker.fromRides(rides);
        debugPrint(
            '🎯 ClusterRideMarker.fromRides() created ${newClusterItems.length} cluster items');

        if (mounted) {
          // AGGRESSIVE FIX 2: Set camera position BEFORE adding items
          debugPrint('🔧 === AGGRESSIVE FIX: CAMERA FIRST, THEN ITEMS ===');

          _setCurrentCameraPositionThenAddItems(newClusterItems, rides.length);
        } else {
          debugPrint('❌ Widget not mounted, skipping state update');
        }
      }

      debugPrint('📊 Final cluster items count: ${_clusterItems.length}');
      debugPrint('📊 Final markers count: ${_markers.length}');
      debugPrint('✅ === _loadRidesInViewport() COMPLETED ===');
    } catch (e) {
      debugPrint('❌ Error loading rides: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: ${StackTrace.current}');

      if (mounted) {
        setState(() {
          _isLoadingRides = false;
          _lastLoadError = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load rides: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void newRideDialog(LatLng latlng, bool isEdit) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ResponsiveRideDialog(
        location: latlng,
        isEdit: isEdit,
        existingRide: isEdit ? _getCurrentRideFromData() : null,
        onSave: _handleRideSave,
        onCancel: () => Navigator.pop(context),
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
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Ride? _getCurrentRideFromData() {
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
    final repository = RideRepository();
    try {
      if (isEdit) {
        await repository.updateRide(rideID, ride);
      } else {
        await repository.addRide(ride);
      }

      if (!mounted) return;

      _loadRidesInViewport();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Ride updated!' : 'Ride created!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save ride: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showDetails() async {
    try {
      final repository = RideRepository();
      final ride = await repository.getRideById(rideID);

      if (ride == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride not found')),
          );
        }
        return;
      }

      final canEdit = _canUserEditRide(ride);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => RideInfoDialog(
          ride: ride,
          rideId: rideID,
          onEdit: canEdit ? () => _editRideDialog(ride) : null,
          onDelete: canEdit ? () => _deleteRide(rideID) : null,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ride details: $e')),
        );
      }
    }
  }

  bool _canUserEditRide(Ride ride) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && ride.createdBy == currentUser.uid;
  }

  Future<void> _deleteRide(String rideId) async {
    try {
      final repository = RideRepository();
      await repository.deleteRide(rideId);
      await _loadRidesInViewport();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete ride: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      liteModeEnabled: false,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(
          () => EagerGestureRecognizer(),
        ),
      },
      initialCameraPosition: _startPosition,
      markers: _markers,
      onLongPress: (point) {
        rideLatlng = point;
        newRideDialog(point, false);
      },
      onTap: (point) {
        setState(() {
          // Update state without moving camera
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50.0,
        centerTitle: false,
        title: const Text(appTitle),
      ),
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
              icon: const Icon(Icons.search, size: 24),
              label: const Text('Search'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> gotoSearchedPlace(double lat, double lng) async {
    final GoogleMapController controller = await mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: _defaultZoom),
      ),
    );
    showDetailsToggle = false;
  }

  /// AGGRESSIVE FIX 2: Set camera position BEFORE adding items
  Future<void> _setCurrentCameraPositionThenAddItems(
      List<ClusterRideMarker> newClusterItems, int totalRides) async {
    try {
      debugPrint('🔧 === _setCurrentCameraPositionThenAddItems() STARTED ===');
      final GoogleMapController controller = await mapController.future;
      final bounds = await controller.getVisibleRegion();
      final currentPosition = CameraPosition(
        target: LatLng(
          (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
          (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
        ),
        zoom: await controller.getZoomLevel(),
      );

      debugPrint(
          '🔧 Step 1: Current camera position: ${currentPosition.target} (zoom: ${currentPosition.zoom})');
      debugPrint('🔧 Step 2: Setting camera position on cluster manager FIRST');
      _clusterManager.onCameraMove(currentPosition);

      // Wait for camera position to register
      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint(
          '🔧 Step 3: RECREATING cluster manager with items (instead of setItems)');
      setState(() {
        _clusterItems = newClusterItems;
        _totalRidesLoaded = totalRides;
        _isLoadingRides = false;

        // AGGRESSIVE FIX 3: Recreate cluster manager with items
        debugPrint(
            '🔧 Creating NEW cluster manager with ${_clusterItems.length} items');
        _clusterManager = ClusterManager<ClusterRideMarker>(
          _clusterItems, // Pass items directly to constructor
          _updateMarkers,
          markerBuilder: _buildClusterMarker,
          levels: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          extraPercent: 0.0,
          stopClusteringZoom: 11.0,
        );
      });

      debugPrint('🔧 Step 4: Setting camera position on NEW cluster manager');
      _clusterManager.onCameraMove(currentPosition);

      await Future.delayed(const Duration(milliseconds: 100));

      debugPrint('🔧 Step 5: Forcing NEW cluster manager update');
      _clusterManager.updateMap();

      // AGGRESSIVE FIX 4: Try different zoom configurations
      debugPrint(
          '🔧 AGGRESSIVE FIX 4: Testing multiple cluster configurations');

      final configurations = [
        {'stopZoom': 0.0, 'desc': 'Force individual markers (stopZoom=0)'},
        {'stopZoom': 20.0, 'desc': 'Force clustering (stopZoom=20)'},
        {'stopZoom': 11.0, 'desc': 'Normal config (stopZoom=11)'},
      ];

      for (int configIndex = 0;
          configIndex < configurations.length;
          configIndex++) {
        final config = configurations[configIndex];
        debugPrint('🔧 Testing config ${configIndex + 1}: ${config['desc']}');

        setState(() {
          _clusterManager = ClusterManager<ClusterRideMarker>(
            _clusterItems,
            _updateMarkers,
            markerBuilder: _buildClusterMarker,
            levels: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
            extraPercent: 0.0,
            stopClusteringZoom: config['stopZoom'] as double,
          );
        });

        _clusterManager.onCameraMove(currentPosition);
        await Future.delayed(const Duration(milliseconds: 300));
        _clusterManager.updateMap();
        await Future.delayed(const Duration(milliseconds: 300));

        debugPrint(
            '🔧 Config ${configIndex + 1} tested, current markers: ${_markers.length}');

        // If this config works, break early
        if (_markers.isNotEmpty) {
          debugPrint(
              '🎉 SUCCESS! Config ${configIndex + 1} produced ${_markers.length} markers!');
          break;
        }
      }

      // Final update attempts
      for (int i = 1; i <= 3; i++) {
        await Future.delayed(Duration(milliseconds: 200 * i));
        if (mounted) {
          debugPrint('🔧 Final update attempt $i');
          _clusterManager.updateMap();
        }
      }

      debugPrint(
          '🔧 === _setCurrentCameraPositionThenAddItems() COMPLETED ===');
    } catch (e) {
      debugPrint('❌ Error in _setCurrentCameraPositionThenAddItems: $e');
    }
  }

  /// Get current camera position and update cluster manager with proper sequence
  Future<void> _getCurrentCameraAndUpdate() async {
    try {
      debugPrint('🔄 === _getCurrentCameraAndUpdate() STARTED ===');
      final GoogleMapController controller = await mapController.future;
      final bounds = await controller.getVisibleRegion();
      final currentPosition = CameraPosition(
        target: LatLng(
          (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
          (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
        ),
        zoom: await controller.getZoomLevel(),
      );

      debugPrint(
          '🔄 Current camera position: ${currentPosition.target} (zoom: ${currentPosition.zoom})');

      // Critical: Set camera position FIRST, then update
      debugPrint('🔄 Step 1: Setting camera position');
      _clusterManager.onCameraMove(currentPosition);

      // Small delay to let camera position register
      await Future.delayed(const Duration(milliseconds: 50));

      debugPrint('🔄 Step 2: Triggering initial cluster update');
      _clusterManager.updateMap();

      // Multiple update attempts with increasing delays
      for (int i = 1; i <= 3; i++) {
        await Future.delayed(Duration(milliseconds: 100 * i));
        if (mounted) {
          debugPrint('🔄 Step ${i + 2}: Update attempt $i');
          _clusterManager.updateMap();
        }
      }

      debugPrint('🔄 === _getCurrentCameraAndUpdate() COMPLETED ===');
    } catch (e) {
      debugPrint('❌ Error in _getCurrentCameraAndUpdate: $e');
    }
  }

  /// NUCLEAR OPTION: Custom clustering implementation that actually works
  Future<Set<Marker>> _createCustomClusteredMarkers(List<Ride> rides) async {
    debugPrint('🚀 === _createCustomClusteredMarkers() STARTED ===');
    debugPrint('🚀 Processing ${rides.length} rides for custom clustering');

    final markers = <Marker>{};
    final GoogleMapController controller = await mapController.future;
    final currentZoom = await controller.getZoomLevel();

    debugPrint('🚀 Current zoom level: $currentZoom');

    // Custom clustering logic based on zoom level
    if (currentZoom >= 12.0) {
      // High zoom: Show individual markers
      debugPrint(
          '🚀 High zoom ($currentZoom >= 12.0): Creating individual markers');
      for (final ride in rides) {
        if (ride.latlng != null && ride.id != null) {
          final marker = Marker(
            markerId: MarkerId('custom_${ride.id}'),
            position: ride.latlng!,
            infoWindow: InfoWindow(
              title: ride.title ?? 'Untitled Ride',
              snippet: ride.snippet ?? '',
            ),
            icon: _iconsLoaded && _rideTypeIcons.containsKey(ride.rideType)
                ? _rideTypeIcons[ride.rideType]!
                : BitmapDescriptor.defaultMarker,
            onTap: () {
              rideID = ride.id!;
              showDetails();
            },
          );
          markers.add(marker);
          debugPrint(
              '🚀 Created individual marker: ${ride.title} at ${ride.latlng}');
        }
      }
    } else {
      // Low zoom: Create clusters
      debugPrint('🚀 Low zoom ($currentZoom < 12.0): Creating clusters');
      final clusters = _createCustomClusters(rides, currentZoom);

      for (final cluster in clusters) {
        final marker = await _createCustomClusterMarker(cluster);
        markers.add(marker);
      }
    }

    debugPrint('🚀 Created ${markers.length} custom clustered markers');
    debugPrint('🚀 === _createCustomClusteredMarkers() COMPLETED ===');
    return markers;
  }

  /// Create custom clusters based on distance
  List<CustomCluster> _createCustomClusters(List<Ride> rides, double zoom) {
    debugPrint('🚀 Creating custom clusters for zoom level: $zoom');

    final clusters = <CustomCluster>[];
    final processedRides = <Ride>{};

    // Distance threshold based on zoom (higher zoom = smaller threshold)
    final distanceThreshold = _getDistanceThreshold(zoom);
    debugPrint('🚀 Using distance threshold: ${distanceThreshold}km');

    for (final ride in rides) {
      if (processedRides.contains(ride) || ride.latlng == null) continue;

      final cluster = CustomCluster(rides: [ride]);
      processedRides.add(ride);

      // Find nearby rides to cluster
      for (final otherRide in rides) {
        if (processedRides.contains(otherRide) || otherRide.latlng == null)
          continue;

        final distance = _calculateDistance(
          ride.latlng!.latitude,
          ride.latlng!.longitude,
          otherRide.latlng!.latitude,
          otherRide.latlng!.longitude,
        );

        if (distance <= distanceThreshold) {
          cluster.rides.add(otherRide);
          processedRides.add(otherRide);
        }
      }

      clusters.add(cluster);
      debugPrint(
          '🚀 Created cluster with ${cluster.rides.length} rides at ${cluster.center}');
    }

    debugPrint('🚀 Total clusters created: ${clusters.length}');
    return clusters;
  }

  /// Get distance threshold based on zoom level
  double _getDistanceThreshold(double zoom) {
    // More aggressive clustering at lower zoom levels
    if (zoom <= 8) return 50.0; // 50km
    if (zoom <= 10) return 20.0; // 20km
    if (zoom <= 11) return 10.0; // 10km
    return 5.0; // 5km
  }

  /// Create marker for custom cluster
  Future<Marker> _createCustomClusterMarker(CustomCluster cluster) async {
    final center = cluster.center;

    if (cluster.rides.length == 1) {
      // Single marker
      final ride = cluster.rides.first;
      debugPrint('🚀 Creating single marker for: ${ride.title}');
      return Marker(
        markerId: MarkerId('custom_single_${ride.id}'),
        position: ride.latlng!,
        infoWindow: InfoWindow(
          title: ride.title ?? 'Untitled Ride',
          snippet: ride.snippet ?? '',
        ),
        icon: _iconsLoaded && _rideTypeIcons.containsKey(ride.rideType)
            ? _rideTypeIcons[ride.rideType]!
            : BitmapDescriptor.defaultMarker,
        onTap: () {
          rideID = ride.id!;
          showDetails();
        },
      );
    } else {
      // Cluster marker
      debugPrint(
          '🚀 Creating cluster marker for ${cluster.rides.length} rides');
      return Marker(
        markerId:
            MarkerId('custom_cluster_${center.latitude}_${center.longitude}'),
        position: center,
        infoWindow: InfoWindow(
          title: '${cluster.rides.length} Rides',
          snippet: 'Tap to view details',
        ),
        icon:
            await ClusterIconService.getCachedClusterIcon(cluster.rides.length),
        onTap: () => _showCustomClusterDialog(cluster),
      );
    }
  }

  /// Show dialog for custom cluster
  void _showCustomClusterDialog(CustomCluster cluster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${cluster.rides.length} Rides in this area'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: cluster.rides.length,
            itemBuilder: (context, index) {
              final ride = cluster.rides[index];
              return ListTile(
                title: Text(ride.title ?? 'Untitled Ride'),
                subtitle: Text(ride.snippet ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  rideID = ride.id!;
                  showDetails();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Calculate distance between two points (reused existing method)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    double dLat = (lat2 - lat1) * (3.14159 / 180);
    double dLon = (lon2 - lon1) * (3.14159 / 180);
    double a = (dLat / 2).abs() * (dLat / 2).abs() +
        (lat1 * 3.14159 / 180).abs() *
            (lat2 * 3.14159 / 180).abs() *
            (dLon / 2).abs() *
            (dLon / 2).abs();
    double c = 2 * (a.abs().clamp(0.0, 1.0));
    return earthRadius * c;
  }

  /// Create simple markers directly without clustering (for debugging)
  Set<Marker> _createSimpleMarkers(List<Ride> rides) {
    debugPrint('🔧 === _createSimpleMarkers() STARTED ===');
    debugPrint('🔧 Creating simple markers for ${rides.length} rides');

    final markers = <Marker>{};

    for (int i = 0; i < rides.length; i++) {
      final ride = rides[i];
      if (ride.latlng != null && ride.id != null) {
        final marker = Marker(
          markerId: MarkerId('simple_${ride.id}'),
          position: ride.latlng!,
          infoWindow: InfoWindow(
            title: ride.title ?? 'Untitled Ride',
            snippet: ride.snippet ?? '',
          ),
          icon: _iconsLoaded && _rideTypeIcons.containsKey(ride.rideType)
              ? _rideTypeIcons[ride.rideType]!
              : BitmapDescriptor.defaultMarker,
          onTap: () {
            rideID = ride.id!;
            showDetails();
          },
        );
        markers.add(marker);
        debugPrint(
            '🔧 Created simple marker $i: ${ride.title} at ${ride.latlng}');
      } else {
        debugPrint('🔧 Skipped ride $i: ${ride.title} (missing latlng or id)');
      }
    }

    debugPrint('🔧 Created ${markers.length} simple markers');
    debugPrint('🔧 === _createSimpleMarkers() COMPLETED ===');
    return markers;
  }
}

/// Custom cluster class for grouping nearby markers
class CustomCluster {
  final List<Ride> rides;
  final int size;

  CustomCluster({
    required this.rides,
  }) : size = rides.length;

  bool get isCluster => rides.length > 1;

  /// Calculate the center position of the cluster
  LatLng get center {
    if (rides.isEmpty) return const LatLng(0, 0);

    double totalLat = 0;
    double totalLng = 0;
    int count = 0;

    for (final ride in rides) {
      if (ride.latlng != null) {
        totalLat += ride.latlng!.latitude;
        totalLng += ride.latlng!.longitude;
        count++;
      }
    }

    if (count == 0) return const LatLng(0, 0);

    return LatLng(totalLat / count, totalLng / count);
  }
}
