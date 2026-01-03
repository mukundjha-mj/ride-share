import 'package:flutter/foundation.dart';
import '../models/ride.dart';
import '../models/join_request.dart';
import '../services/ride_service.dart';

class RideProvider with ChangeNotifier {
  final RideService _rideService = RideService();

  List<Ride> _rides = [];
  List<Ride> _myRides = [];
  List<JoinRequest> _myRequests = [];
  bool _isLoading = false;
  String _error = '';

  List<Ride> get rides => _rides;
  List<Ride> get myRides => _myRides;
  List<JoinRequest> get myRequests => _myRequests;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Load ride feed
  Future<void> loadRides() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    _rides = await _rideService.getRides();

    _isLoading = false;
    notifyListeners();
  }

  // Load my posted rides
  Future<void> loadMyRides() async {
    _isLoading = true;
    notifyListeners();

    _myRides = await _rideService.getMyRides();

    _isLoading = false;
    notifyListeners();
  }

  // Load my join requests
  Future<void> loadMyRequests() async {
    _myRequests = await _rideService.getMyRequests();
    notifyListeners();
  }

  // Create a ride
  Future<Ride?> createRide({
    required String from,
    required String to,
    required DateTime timeStart,
    required DateTime timeEnd,
    int seats = 1,
  }) async {
    _isLoading = true;
    notifyListeners();

    final ride = await _rideService.createRide(
      from: from,
      to: to,
      timeStart: timeStart,
      timeEnd: timeEnd,
      seats: seats,
    );

    if (ride != null) {
      _myRides.insert(0, ride);
    }

    _isLoading = false;
    notifyListeners();
    return ride;
  }

  // Cancel a ride
  Future<bool> cancelRide(String rideId) async {
    final success = await _rideService.cancelRide(rideId);
    if (success) {
      _myRides.removeWhere((r) => r.id == rideId);
      notifyListeners();
    }
    return success;
  }

  // Join a ride
  Future<JoinRequest?> joinRide(String rideId) async {
    final request = await _rideService.joinRide(rideId);
    if (request != null) {
      // Remove from feed since user has requested
      _rides.removeWhere((r) => r.id == rideId);
      _myRequests.insert(0, request);
      notifyListeners();
    }
    return request;
  }

  // Accept a request
  Future<bool> acceptRequest(String joinId) async {
    final success = await _rideService.acceptRequest(joinId);
    if (success) {
      await loadMyRides();
    }
    return success;
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([loadRides(), loadMyRides(), loadMyRequests()]);
  }

  // Clear data (on logout)
  void clear() {
    _rides = [];
    _myRides = [];
    _myRequests = [];
    notifyListeners();
  }
}
