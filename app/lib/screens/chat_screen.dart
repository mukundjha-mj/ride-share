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
    // Set up real-time message listener
    _socketService.onNewMessage = (message) {
      if (message.joinRequestId == widget.joinRequestId) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    };

    // Connect and join chat room
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
    if (showLoading) {
      setState(() => _isLoading = true);
    }

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

    // Message will arrive via socket, no need to reload
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
        backgroundColor: AppTheme.cardColor,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
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
          backgroundColor: AppTheme.successColor,
        ),
      );
    }

    setState(() => _isAccepting = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_joinRequest?.requester?.name ?? 'Chat'),
        actions: [
          // Real-time indicator
          if (_socketService.isConnected)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.wifi, color: AppTheme.successColor, size: 18),
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
                  : const Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                    ),
              label: const Text(
                'Accept',
                style: TextStyle(color: AppTheme.successColor),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_joinRequest != null) _buildStatusBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet.\nStart the conversation!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == currentUserId;
                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),
          if (_canSendMessage) _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color color;
    String text;
    IconData icon;

    if (_joinRequest!.isAccepted) {
      color = AppTheme.successColor;
      text = '🎉 Ride Confirmed!';
      icon = Icons.check_circle;
    } else if (_joinRequest!.isRejected) {
      color = AppTheme.textHint;
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
      color: color.withValues(alpha: 0.1),
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

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    if (message.isSystemMessage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Text(
          message.message,
          style: TextStyle(color: isMe ? Colors.white : AppTheme.textPrimary),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
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
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
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
