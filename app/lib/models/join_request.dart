import 'user.dart';
import 'ride.dart';

class JoinRequest {
  final String id;
  final String rideId;
  final String requesterId;
  final String status;
  final DateTime createdAt;
  final User? requester;
  final Ride? ride;

  JoinRequest({
    required this.id,
    required this.rideId,
    required this.requesterId,
    required this.status,
    required this.createdAt,
    this.requester,
    this.ride,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['_id'] ?? json['id'],
      rideId: json['rideId'] is Map ? json['rideId']['_id'] : json['rideId'],
      requesterId: json['requesterId'] is Map
          ? json['requesterId']['_id']
          : json['requesterId'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      requester: json['requester'] != null
          ? User.fromJson(json['requester'])
          : null,
      ride: json['rideId'] is Map ? Ride.fromJson(json['rideId']) : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
