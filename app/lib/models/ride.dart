import 'user.dart';

class Ride {
  final String id;
  final String ownerId;
  final String from;
  final String to;
  final DateTime timeStart;
  final DateTime timeEnd;
  final int seats;
  final String status;
  final DateTime createdAt;
  final User? owner;
  final int? pendingRequestCount;

  Ride({
    required this.id,
    required this.ownerId,
    required this.from,
    required this.to,
    required this.timeStart,
    required this.timeEnd,
    required this.seats,
    required this.status,
    required this.createdAt,
    this.owner,
    this.pendingRequestCount,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['_id'] ?? json['id'],
      ownerId: json['ownerId'] is Map
          ? json['ownerId']['_id']
          : json['ownerId'],
      from: json['from'],
      to: json['to'],
      timeStart: DateTime.parse(json['timeStart']),
      timeEnd: DateTime.parse(json['timeEnd']),
      seats: json['seats'] ?? 1,
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,
      pendingRequestCount: json['pendingRequestCount'],
    );
  }

  bool get isOpen => status == 'open';
  bool get isFilled => status == 'filled';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => DateTime.now().isAfter(timeEnd);
}
