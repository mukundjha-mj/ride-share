import '../config/api_config.dart';
import '../models/ride.dart';
import '../models/join_request.dart';
import '../models/chat_message.dart';
import 'api_service.dart';

class RideService {
  final ApiService _api = ApiService();

  // Get all open rides (feed)
  Future<List<Ride>> getRides() async {
    final response = await _api.get(ApiConfig.rides);
    if (response.success && response.data != null) {
      final List rides = response.data['rides'];
      return rides.map((r) => Ride.fromJson(r)).toList();
    }
    return [];
  }

  // Get my posted rides
  Future<List<Ride>> getMyRides() async {
    final response = await _api.get(ApiConfig.myRides);
    if (response.success && response.data != null) {
      final List rides = response.data['rides'];
      return rides.map((r) => Ride.fromJson(r)).toList();
    }
    return [];
  }

  // Get single ride
  Future<RideDetail?> getRide(String rideId) async {
    final response = await _api.get('${ApiConfig.rides}/$rideId');
    if (response.success && response.data != null) {
      return RideDetail(
        ride: Ride.fromJson(response.data['ride']),
        myRequest: response.data['myRequest'] != null
            ? JoinRequest.fromJson(response.data['myRequest'])
            : null,
        isOwner: response.data['isOwner'] ?? false,
      );
    }
    return null;
  }

  // Create a ride
  Future<Ride?> createRide({
    required String from,
    required String to,
    required DateTime timeStart,
    required DateTime timeEnd,
    int seats = 1,
  }) async {
    final response = await _api.post(ApiConfig.rides, {
      'from': from,
      'to': to,
      'timeStart': timeStart.toIso8601String(),
      'timeEnd': timeEnd.toIso8601String(),
      'seats': seats,
    });
    if (response.success && response.data != null) {
      return Ride.fromJson(response.data['ride']);
    }
    return null;
  }

  // Cancel a ride
  Future<bool> cancelRide(String rideId) async {
    final response = await _api.delete('${ApiConfig.rides}/$rideId');
    return response.success;
  }

  // Request to join a ride
  Future<JoinRequest?> joinRide(String rideId) async {
    final response = await _api.post(ApiConfig.joinRide(rideId), {});
    if (response.success && response.data != null) {
      return JoinRequest.fromJson(response.data['joinRequest']);
    }
    return null;
  }

  // Get all requests for a ride (owner only)
  Future<List<JoinRequest>> getRideRequests(String rideId) async {
    final response = await _api.get(ApiConfig.rideRequests(rideId));
    if (response.success && response.data != null) {
      final List requests = response.data['requests'];
      return requests.map((r) => JoinRequest.fromJson(r)).toList();
    }
    return [];
  }

  // Accept a request
  Future<bool> acceptRequest(String joinId) async {
    final response = await _api.post(ApiConfig.acceptRequest(joinId), {});
    return response.success;
  }

  // Get my join requests
  Future<List<JoinRequest>> getMyRequests() async {
    final response = await _api.get(ApiConfig.myRequests);
    if (response.success && response.data != null) {
      final List requests = response.data['requests'];
      return requests.map((r) => JoinRequest.fromJson(r)).toList();
    }
    return [];
  }

  // Get chat messages
  Future<ChatData?> getChatMessages(String joinId) async {
    final response = await _api.get(ApiConfig.chatMessages(joinId));
    if (response.success && response.data != null) {
      final List messages = response.data['messages'];
      return ChatData(
        messages: messages.map((m) => ChatMessage.fromJson(m)).toList(),
        joinRequest: JoinRequest.fromJson(response.data['joinRequest']),
        isOwner: response.data['isOwner'] ?? false,
        canSendMessage: response.data['canSendMessage'] ?? false,
      );
    }
    return null;
  }

  // Send a message
  Future<ChatMessage?> sendMessage(String joinId, String message) async {
    final response = await _api.post(ApiConfig.chatMessages(joinId), {
      'message': message,
    });
    if (response.success && response.data != null) {
      return ChatMessage.fromJson(response.data['chatMessage']);
    }
    return null;
  }
}

class RideDetail {
  final Ride ride;
  final JoinRequest? myRequest;
  final bool isOwner;

  RideDetail({required this.ride, this.myRequest, required this.isOwner});
}

class ChatData {
  final List<ChatMessage> messages;
  final JoinRequest joinRequest;
  final bool isOwner;
  final bool canSendMessage;

  ChatData({
    required this.messages,
    required this.joinRequest,
    required this.isOwner,
    required this.canSendMessage,
  });
}
