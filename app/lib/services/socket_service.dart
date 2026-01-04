import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import '../models/chat_message.dart';
import 'api_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  final ApiService _api = ApiService();

  // Callbacks
  Function(ChatMessage)? onNewMessage;
  Function(dynamic)? onNewJoinRequest;
  Function(dynamic)? onRequestAccepted;
  Function(dynamic)? onRequestRejected;
  Function(dynamic)? onRideFilled;
  Function(ChatMessage)? onMessageEdited;
  Function(String)? onMessageDeleted;
  Function(String, DateTime)? onMessagesRead;

  bool get isConnected => _isConnected;

  // Pending listeners queue
  final List<Map<String, dynamic>> _pendingListeners = [];

  /// Listen to an event
  void on(String event, Function(dynamic) handler) {
    if (_socket != null) {
      _socket!.on(event, handler);
    } else {
      print('⏳ Socket not ready, queuing listener for: $event');
      _pendingListeners.add({'event': event, 'handler': handler});
    }
  }

  /// Connect to Socket.IO server
  Future<void> connect() async {
    if (_socket != null && _isConnected) return;

    final token = await _api.getToken();
    if (token == null) return;

    _socket = IO.io(
      ApiConfig.websocketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    // Register queued listeners
    if (_pendingListeners.isNotEmpty) {
      print('🚀 Registering ${_pendingListeners.length} queued listeners');
      for (final listener in _pendingListeners) {
        _socket!.on(listener['event'], listener['handler']);
      }
      _pendingListeners.clear();
    }

    _socket!.onConnect((_) {
      _isConnected = true;
      print('🔌 Socket connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('🔌 Socket disconnected');
    });

    _socket!.onConnectError((error) {
      print('🔌 Socket connection error: $error');
    });

    // Listen for new messages
    _socket!.on('new_message', (data) {
      print('📨 New message received');
      final message = ChatMessage.fromJson(data);
      onNewMessage?.call(message);
    });

    // Listen for new join requests (for ride owners)
    _socket!.on('new_join_request', (data) {
      print('🙋 New join request');
      onNewJoinRequest?.call(data);
    });

    // Listen for request accepted
    _socket!.on('request_accepted', (data) {
      print('✅ Request accepted');
      onRequestAccepted?.call(data);
    });

    // Listen for request rejected
    _socket!.on('request_rejected', (data) {
      print('❌ Request rejected');
      onRequestRejected?.call(data);
    });

    // Listen for ride filled
    _socket!.on('ride_filled', (data) {
      print('🚗 Ride filled');
      onRideFilled?.call(data);
    });

    // Listen for message edited
    _socket!.on('message_edited', (data) {
      print('📝 Message edited');
      final message = ChatMessage.fromJson(data);
      onMessageEdited?.call(message);
    });

    // Listen for message deleted
    _socket!.on('message_deleted', (data) {
      print('🗑️ Message deleted');
      onMessageDeleted?.call(data['messageId']);
    });

    // Listen for messages read
    _socket!.on('messages_read', (data) {
      print('👀 Messages read');
      onMessagesRead?.call(data['userId'], DateTime.parse(data['lastRead']));
    });

    _socket!.connect();
  }

  /// Disconnect from socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Join a chat room to receive messages
  void joinChat(String joinRequestId) {
    _socket?.emit('join_chat', joinRequestId);
  }

  /// Leave a chat room
  void leaveChat(String joinRequestId) {
    _socket?.emit('leave_chat', joinRequestId);
  }

  /// Join a ride room (for owners to get new request notifications)
  void joinRide(String rideId) {
    _socket?.emit('join_ride', rideId);
  }

  /// Clear all callbacks
  void clearCallbacks() {
    onNewMessage = null;
    onNewJoinRequest = null;
    onRequestAccepted = null;
    onRequestRejected = null;
    onRideFilled = null;
  }
}
