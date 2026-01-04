import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/ride.dart';
import '../models/join_request.dart';
import '../services/ride_service.dart';
import '../services/socket_service.dart';

class RideProvider with ChangeNotifier {
  final RideService _rideService = RideService();
  final SocketService _socketService = SocketService();
  Timer? _expirationTimer;

  List<Ride> _rides = [];
  List<Ride> _myRides = [];
  List<JoinRequest> _myRequests = [];

  bool _isFeedLoading = false;
  bool _isMyRidesLoading = false;
  // Keep generic error or split it? For now, generic.
  String _error = '';

  List<Ride> get rides => _rides;
  List<Ride> get myRides => _myRides;
  List<JoinRequest> get myRequests => _myRequests;

  bool get isFeedLoading => _isFeedLoading;
  bool get isMyRidesLoading => _isMyRidesLoading;

  // Backward compatibility if needed, or migration
  bool get isLoading => _isFeedLoading || _isMyRidesLoading;
  String get error => _error;

  // Load ride feed
  Future<void> loadRides() async {
    _isFeedLoading = true;
    _error = '';
    notifyListeners();

    print('📥 Fetching rides from API...');
    try {
      _rides = await _rideService.getRides();
      print('✅ Loaded ${_rides.length} rides from API');
      // Force filter for invalid dates just in case
      final now = DateTime.now();
      _rides.removeWhere((r) => r.timeEnd.isBefore(now));
    } catch (e) {
      print('❌ Error loading rides: $e');
      _error = 'Failed to load rides';
    }

    _isFeedLoading = false;
    notifyListeners();
  }

  // Load my posted rides
  Future<void> loadMyRides() async {
    _isMyRidesLoading = true;
    notifyListeners();

    _myRides = await _rideService.getMyRides();

    _isMyRidesLoading = false;
    notifyListeners();
  }

  // Load my join requests
  Future<void> loadMyRequests() async {
    _myRequests = await _rideService.getMyRequests();
    notifyListeners();
  }

  void startRealTimeUpdates({String? currentUserId}) {
    print('🔄 Starting real-time ride updates... User: $currentUserId');
    print('🔌 Socket Connected Status: ${_socketService.isConnected}');

    if (!_socketService.isConnected) {
      print('⚠️ Socket is NOT connected. Attempting to connect now...');
      _socketService.connect();
    }

    // Listen for new rides
    _socketService.on('new_ride', (data) {
      print('🆕 RAW NEW RIDE EVENT: $data');
      if (data != null) {
        try {
          final newRide = Ride.fromJson(data);
          print('🎁 Parsed new ride: ${newRide.id}, Owner: ${newRide.ownerId}');

          // Filter out my own rides to prevent flicker
          if (currentUserId != null && newRide.ownerId == currentUserId) {
            print('👻 Ignoring my own ride from socket: ${newRide.id}');
            return;
          }

          if (currentUserId == null) {
            print(
              '⚠️ currentUserId is null in listener, safety check passed but might be unexpected.',
            );
          }

          // Basic check: is not expired?
          if (!newRide.isExpired) {
            print('🆕 New ride received via socket: ${newRide.id}');
            // Check if already exists to avoid dupes
            final exists = _rides.any((r) => r.id == newRide.id);
            if (!exists) {
              // Add to TOP of list
              _rides.insert(0, newRide);
              // Sort by timeStart
              _rides.sort((a, b) => a.timeStart.compareTo(b.timeStart));
              notifyListeners();
            }
          } else {
            print('⚠️ Received EXPIRED ride from socket: ${newRide.id}');
          }
        } catch (e) {
          print('Error parsing new ride: $e');
        }
      }
    });

    // Listen for cancelled rides
    _socketService.on('ride_cancelled', (data) {
      print('🗑️ RAW CANCEL EVENT: $data');
      if (data != null && data['rideId'] != null) {
        final String rideId = data['rideId'];
        print('❌ MATCHING Ride cancelled event: $rideId');

        final initialLength = _rides.length;
        _rides.removeWhere((r) {
          final match = r.id == rideId;
          if (match) print('Found ride to remove: ${r.id}');
          return match;
        });

        if (_rides.length != initialLength) {
          print(
            '✅ Removed ride from list. Old size: $initialLength, New size: ${_rides.length}',
          );
          notifyListeners();
        } else {
          print(
            '⚠️ Ride ID $rideId not found in local list of ${_rides.length} rides.',
          );
          _rides.forEach((r) => print(' - Available: ${r.id}'));
        }
      }
    });

    // Start auto-expiration timer (runs every 30 seconds)
    _expirationTimer?.cancel();
    _expirationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final now = DateTime.now();
      int removedCount = 0;
      _rides.removeWhere((ride) {
        if (ride.timeEnd.isBefore(now)) {
          removedCount++;
          return true;
        }
        return false;
      });
      if (removedCount > 0) {
        print('🧹 Auto-removed $removedCount expired rides from feed');
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    // note: socket service assumes global lifecycle, so we don't turn off listeners
    // unless we want to stop updates. For now, we leave them or could remove them.
    super.dispose();
  }

  // Create a ride
  Future<Ride?> createRide({
    required String from,
    required String to,
    required DateTime timeStart,
    required DateTime timeEnd,
    int seats = 1,
  }) async {
    _isMyRidesLoading = true;
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

    _isMyRidesLoading = false;
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
