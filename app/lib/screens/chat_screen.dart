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

  @override
  void initState() {
    super.initState();
    _isOwner = widget.isOwner;
    _setupSocket();
    _loadMessages();
  }

  void _setupSocket() {
    _socketService.onNewMessage = (message) {
      if (message.joinRequestId == widget.joinRequestId) {
        setState(() => _messages.add(message));
        _scrollToBottom();
      }
    };
    _socketService.connect().then((_) {
      _socketService.joinChat(widget.joinRequestId);
    });
  }

  @override
  void dispose() {
    _socketService.leaveChat(widget.joinRequestId);
    _socketService.onNewMessage = null;
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

    final sent = await _rideService.sendMessage(widget.joinRequestId, message);

    if (sent == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
    setState(() => _isSending = false);
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
          backgroundColor: AppTheme.secondaryColor,
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
              child: Icon(Icons.wifi, color: AppTheme.secondaryColor, size: 18),
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
                  : Icon(Icons.check_circle, color: AppTheme.secondaryColor),
              label: Text(
                'Accept',
                style: TextStyle(color: AppTheme.secondaryColor),
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
                      return _buildMessageBubble(message, isMe, theme);
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
      color = AppTheme.secondaryColor;
      text = '🎉 Ride Confirmed!';
      icon = Icons.check_circle;
    } else if (_joinRequest!.isRejected) {
      color = const Color(0xFF6B7280);
      text = 'This ride has been filled';
      icon = Icons.info_outline;
    } else {
      color = AppTheme.warningColor;
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

  Widget _buildMessageBubble(ChatMessage message, bool isMe, ThemeData theme) {
    // System message
    if (message.isSystemMessage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          message.message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.chatSystemText,
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      );
    }

    // Chat colors per design spec
    // Outgoing: Teal background, white text
    // Incoming: White background, charcoal text (adapts in dark mode)
    final isDark = theme.brightness == Brightness.dark;

    final bubbleColor = isMe
        ? AppTheme.chatOutgoing
        : (isDark ? AppTheme.chatIncomingDark : AppTheme.chatIncomingLight);
    final textColor = isMe
        ? AppTheme.chatOutgoingText
        : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
              : Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Text(
          message.message,
          style: TextStyle(color: textColor, fontSize: 15),
        ),
      ),
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
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
