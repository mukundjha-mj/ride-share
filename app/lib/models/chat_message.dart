class ChatMessage {
  final String id;
  final String joinRequestId;
  final String senderId;
  final String message;
  final bool isSystemMessage;
  final DateTime createdAt;
  final bool isEdited;

  ChatMessage({
    required this.id,
    required this.joinRequestId,
    required this.senderId,
    required this.message,
    required this.isSystemMessage,
    required this.createdAt,
    this.isEdited = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'],
      joinRequestId: json['joinRequestId'],
      senderId: json['senderId'],
      message: json['message'],
      isSystemMessage: json['isSystemMessage'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      isEdited: json['isEdited'] ?? false,
    );
  }
}
