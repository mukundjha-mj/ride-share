import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/ride_service.dart';
import '../services/socket_service.dart';

class UnreadProvider with ChangeNotifier {
  final RideService _rideService = RideService();
  int _totalUnreadCount = 0;
  final SocketService _socketService = SocketService();

  int get totalUnreadCount => _totalUnreadCount;
  bool get hasUnread => _totalUnreadCount > 0;

  void startPolling() {
    // Initial load
    fetchUnreadCount();

    // Listen for events that affect unread count
    _socketService.on('new_message', (_) => fetchUnreadCount());
    _socketService.on('new_join_request', (_) => fetchUnreadCount());
    _socketService.on('request_accepted', (_) => fetchUnreadCount());
    _socketService.on('request_rejected', (_) => fetchUnreadCount());
    _socketService.on('ride_filled', (_) => fetchUnreadCount());
  }

  void stopPolling() {
    // No-op
  }

  Future<void> fetchUnreadCount() async {
    try {
      int total = 0;

      // Get unread from my requests (where I'm the requester)
      final myRequests = await _rideService.getMyRequests();
      for (final request in myRequests) {
        total += request.unreadCount;
      }

      // Get unread from my rides' requests (where I'm the owner)
      final myRides = await _rideService.getMyRides();
      for (final ride in myRides) {
        final requests = await _rideService.getRideRequests(ride.id);
        for (final request in requests) {
          total += request.unreadCount;
        }
      }

      if (_totalUnreadCount != total) {
        _totalUnreadCount = total;
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - don't break the app
    }
  }

  void clearUnread() {
    _totalUnreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
