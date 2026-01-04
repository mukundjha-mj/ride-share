import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/join_request.dart';
import '../services/ride_service.dart';
import '../services/socket_service.dart';
import '../providers/auth_provider.dart';
import '../providers/ride_provider.dart';
import '../config/theme.dart';

class ChatScreen extends StatefulWidget {
  final String joinRequestId;
  final bool isOwner;

  const ChatScreen({
    super.key,
    required this.joinRequestId,
    this.isOwner = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final RideService _rideService = RideService();
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  JoinRequest? _joinRequest;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isAccepting = false;
  bool _canSendMessage = false;
  bool _isOwner = false;

  // Polling timer for real-time updates
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _isOwner = widget.isOwner;
    _setupSocket();
    _loadMessages();
    _startPolling();
  }

  void _startPolling() {
    // Poll every 3 seconds for new messages
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollNewMessages();
    });
  }

  Future<void> _pollNewMessages() async {
    if (_isLoading) return;

    final data = await _rideService.getChatMessages(widget.joinRequestId);
    if (data != null && mounted) {
      // Check if there are new messages
      if (data.messages.length > _messages.length) {
        final newMessages = data.messages.sublist(_messages.length);
        setState(() {
          for (var msg in newMessages) {
            if (!_messages.any((m) => m.id == msg.id)) {
              _messages.add(msg);
            }
          }
          _joinRequest = data.joinRequest;
          _canSendMessage = data.canSendMessage;
        });
        _scrollToBottom();
      } else if (data.joinRequest.status != _joinRequest?.status) {
        // Also update status if changed
        setState(() {
          _joinRequest = data.joinRequest;
          _canSendMessage = data.canSendMessage;
        });
      }
    }
  }

  void _setupSocket() {
    _socketService.onNewMessage = (message) {
      if (message.joinRequestId == widget.joinRequestId) {
        final isDuplicate = _messages.any((m) => m.id == message.id);
        if (!isDuplicate) {
          setState(() => _messages.add(message));
          _scrollToBottom();
          // Mark as read immediately since we are viewing the chat
          _rideService.markAsRead(widget.joinRequestId);
        }
      }
    };

    _socketService.onMessageEdited = (message) {
      if (message.joinRequestId == widget.joinRequestId) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = message;
          }
        });
      }
    };

    _socketService.onMessageDeleted = (messageId) {
      setState(() {
        _messages.removeWhere((m) => m.id == messageId);
      });
    };

    _socketService.onMessagesRead = (userId, lastRead) {
      print('👀 ChatScreen received read: $userId at $lastRead');
      if (_joinRequest == null) {
        print('⚠️ _joinRequest is null');
        return;
      }

      print('Requester ID: ${_joinRequest!.requester?.id}');

      // Update the correct timestamp based on who read it
      setState(() {
        if (userId == _joinRequest!.requesterId) {
          print('Updating lastReadRequester');
          _joinRequest = _joinRequest!.copyWith(lastReadRequester: lastRead);
        } else {
          print('Updating lastReadOwner');
          // Owner (or other) read it
          _joinRequest = _joinRequest!.copyWith(lastReadOwner: lastRead);
        }
      });
    };

    _socketService.connect().then((_) {
      _socketService.joinChat(widget.joinRequestId);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _socketService.leaveChat(widget.joinRequestId);
    _socketService.onNewMessage = null;
    _socketService.onMessageEdited = null;
    _socketService.onMessageDeleted = null;
    _socketService.onMessagesRead = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);

    final data = await _rideService.getChatMessages(widget.joinRequestId);

    if (data != null && mounted) {
      setState(() {
        _messages = data.messages;
        _joinRequest = data.joinRequest;
        _canSendMessage = data.canSendMessage;
        _isOwner = widget.isOwner || data.isOwner;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final sentMessage = await _rideService.sendMessage(
      widget.joinRequestId,
      message,
    );

    if (sentMessage != null && mounted) {
      setState(() {
        _messages.add(sentMessage);
        _isSending = false;
      });
      _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      setState(() => _isSending = false);
    }
  }

  Future<void> _acceptRequest() async {
    if (_joinRequest == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Request'),
        content: const Text(
          'This will confirm the ride with this person and close all other pending requests. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isAccepting = true);
    final success = await context.read<RideProvider>().acceptRequest(
      widget.joinRequestId,
    );

    if (success && mounted) {
      await _loadMessages(showLoading: false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride confirmed! 🎉'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    }
    setState(() => _isAccepting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_joinRequest?.requester?.name ?? 'Chat'),
        actions: [
          if (_socketService.isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.wifi, color: const Color(0xFF22C55E), size: 18),
            ),
          if (_isOwner && _joinRequest?.isPending == true)
            TextButton.icon(
              onPressed: _isAccepting ? null : _acceptRequest,
              icon: _isAccepting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.check_circle, color: const Color(0xFF22C55E)),
              label: Text(
                'Accept',
                style: TextStyle(color: const Color(0xFF22C55E)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_joinRequest != null) _buildStatusBanner(colorScheme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet.\nStart the conversation!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == currentUserId;

                      // Check if this is my last message (for "Seen" indicator)
                      bool isMyLastMessage = false;
                      if (isMe) {
                        isMyLastMessage = !_messages
                            .skip(index + 1)
                            .any(
                              (m) =>
                                  m.senderId == currentUserId &&
                                  !m.isSystemMessage,
                            );
                      }

                      return _buildMessageBubble(
                        message,
                        isMe,
                        theme,
                        colorScheme,
                        isMyLastMessage: isMyLastMessage,
                      );
                    },
                  ),
          ),
          if (_canSendMessage) _buildInputField(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(ColorScheme colorScheme) {
    Color color;
    String text;
    IconData icon;

    if (_joinRequest!.isAccepted) {
      color = const Color(0xFF22C55E);
      text = '🎉 Ride Confirmed!';
      icon = Icons.check_circle;
    } else if (_joinRequest!.isRejected) {
      color = colorScheme.outline;
      text = 'This ride has been filled';
      icon = Icons.info_outline;
    } else {
      color = const Color(0xFFF59E0B);
      text = _isOwner
          ? 'Tap Accept to confirm this rider'
          : 'Waiting for response...';
      icon = Icons.schedule;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isMe,
    ThemeData theme,
    ColorScheme colorScheme, {
    bool isMyLastMessage = false,
  }) {
    if (message.isSystemMessage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          message.message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.outline,
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      );
    }

    final isDark = theme.brightness == Brightness.dark;

    final bubbleColor = isMe
        ? colorScheme.primary
        : (isDark ? AppTheme.chatIncomingDark : AppTheme.chatIncomingLight);
    final textColor = isMe ? colorScheme.onPrimary : colorScheme.onSurface;

    // Check if message is seen by other person
    bool isSeen = false;
    if (isMe && isMyLastMessage && _joinRequest != null) {
      final otherLastRead = _isOwner
          ? _joinRequest!.lastReadRequester
          : _joinRequest!.lastReadOwner;
      if (otherLastRead != null) {
        isSeen = otherLastRead.isAfter(message.createdAt);
      }
    }

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: isMe ? () => _showMessageOptions(message) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? null
                    : Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(color: textColor, fontSize: 15),
                  ),
                  if (message.isEdited)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '(edited)',
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? textColor.withOpacity(0.7)
                              : theme.textTheme.bodySmall?.color,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Seen indicator for last sent message
        if (isMe && isMyLastMessage && isSeen)
          Padding(
            padding: const EdgeInsets.only(right: 4, top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.done_all, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Seen',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInputField(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Icon(Icons.send, color: colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                title: const Text(
                  'Unsend Message',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(ChatMessage message) {
    final controller = TextEditingController(text: message.message);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Message',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new message',
            border: OutlineInputBorder(),
          ),
          minLines: 1,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty || newText == message.message) {
                Navigator.pop(context);
                return;
              }

              Navigator.pop(context); // Close dialog

              final updatedMessage = await _rideService.editMessage(
                widget.joinRequestId,
                message.id,
                newText,
              );

              if (updatedMessage != null && mounted) {
                setState(() {
                  final index = _messages.indexWhere((m) => m.id == message.id);
                  if (index != -1) {
                    _messages[index] = updatedMessage;
                  }
                });
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to edit message'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    // Confirm delete
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Unsend Message',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: const Text('Are you sure you want to unsend this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unsend'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _rideService.deleteMessage(
      widget.joinRequestId,
      message.id,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to unsend message'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
