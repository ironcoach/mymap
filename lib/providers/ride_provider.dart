import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mymap/models/ride_data.dart';
import 'package:mymap/repositories/ride_repository.dart';

// Repository provider
final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepository();
});

// Rides state provider using the same pattern as your existing providers
final ridesProvider = NotifierProvider<RidesNotifier, RidesState>(RidesNotifier.new);

class RidesState {
  final List<Ride> rides;
  final bool isLoading;
  final String? error;

  const RidesState({
    this.rides = const [],
    this.isLoading = false,
    this.error,
  });

  RidesState copyWith({
    List<Ride>? rides,
    bool? isLoading,
    String? error,
  }) {
    return RidesState(
      rides: rides ?? this.rides,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RidesNotifier extends Notifier<RidesState> {
  late final RideRepository _repository;

  @override
  RidesState build() {
    _repository = ref.read(rideRepositoryProvider);
    loadRides(); // Auto-load on initialization
    return const RidesState(isLoading: true);
  }

  Future<void> loadRides() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final rides = await _repository.getAllRides();
      state = state.copyWith(rides: rides, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> addRide(Ride ride) async {
    try {
      await _repository.addRide(ride);
      await loadRides(); // Refresh the list
    } catch (error) {
      state = state.copyWith(error: error.toString());
      rethrow;
    }
  }

  Future<void> updateRide(String rideId, Ride ride) async {
    try {
      await _repository.updateRide(rideId, ride);
      await loadRides(); // Refresh the list
    } catch (error) {
      state = state.copyWith(error: error.toString());
      rethrow;
    }
  }

  Future<void> deleteRide(String rideId) async {
    try {
      await _repository.deleteRide(rideId);
      await loadRides(); // Refresh the list
    } catch (error) {
      state = state.copyWith(error: error.toString());
      rethrow;
    }
  }

  /// Rate a ride (1-5 stars)
  Future<void> rateRide(String rideId, int rating) async {
    try {
      await _repository.rateRide(rideId, rating);
      await loadRides(); // Refresh to get updated ratings
    } catch (error) {
      state = state.copyWith(error: error.toString());
      rethrow;
    }
  }

  /// Verify a ride
  Future<void> verifyRide(String rideId) async {
    try {
      await _repository.verifyRide(rideId);
      await loadRides(); // Refresh to get updated verification count
    } catch (error) {
      state = state.copyWith(error: error.toString());
      rethrow;
    }
  }

  /// Remove verification from a ride
  Future<void> removeVerification(String rideId) async {
    try {
      await _repository.removeVerification(rideId);
      await loadRides(); // Refresh to get updated verification count
    } catch (error) {
      state = state.copyWith(error: error.toString());
      rethrow;
    }
  }
}