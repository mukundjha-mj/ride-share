import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../config/theme.dart';
import '../services/ride_service.dart';
import '../services/socket_service.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final RideService _rideService = RideService();
  List<ChatItem> _chats = [];
  bool _isLoading = true;
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _loadChats();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for events that should refresh the chat list
    _socketService.on('new_message', (_) => _loadChats(showLoading: false));
    _socketService.on(
      'new_join_request',
      (_) => _loadChats(showLoading: false),
    );
    _socketService.on(
      'request_accepted',
      (_) => _loadChats(showLoading: false),
    );
    _socketService.on(
      'request_rejected',
      (_) => _loadChats(showLoading: false),
    );
    _socketService.on('ride_filled', (_) => _loadChats(showLoading: false));
  }

  @override
  void dispose() {
    // Note: We don't remove socket listeners here as they might be shared,
    // but typically we should if proper cleanup is needed.
    // For now, simple re-fetch is fine.
    super.dispose();
  }

  Future<void> _loadChats({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);

    final chats = <ChatItem>[];

    // Get my requests (where I'm the requester)
    final myRequests = await _rideService.getMyRequests();
    for (final request in myRequests) {
      chats.add(
        ChatItem(
          joinRequestId: request.id,
          name: request.ride?.owner?.name ?? 'Unknown',
          subtitle: '${request.ride?.from ?? ''} → ${request.ride?.to ?? ''}',
          status: request.status,
          isOwner: false,
          createdAt: request.createdAt,
          unreadCount: request.unreadCount,
        ),
      );
    }

    // Get my rides and their requests (where I'm the owner)
    final provider = context.read<RideProvider>();
    await provider.loadMyRides();

    for (final ride in provider.myRides) {
      final requests = await _rideService.getRideRequests(ride.id);
      for (final request in requests) {
        chats.add(
          ChatItem(
            joinRequestId: request.id,
            name: request.requester?.name ?? 'Unknown',
            subtitle: '${ride.from} → ${ride.to}',
            status: request.status,
            isOwner: true,
            createdAt: request.createdAt,
            unreadCount: request.unreadCount,
          ),
        );
      }
    }

    chats.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _chats = chats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text('No conversations yet', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Join a ride or wait for requests',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return _buildChatTile(chat, theme, colorScheme);
        },
      ),
    );
  }

  Widget _buildChatTile(
    ChatItem chat,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                joinRequestId: chat.joinRequestId,
                isOwner: chat.isOwner,
              ),
            ),
          ).then((_) => _loadChats());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with unread indicator
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        (chat.isOwner
                                ? AppTheme.primaryColor
                                : AppTheme.secondaryColor)
                            .withOpacity(0.1),
                    child: Text(
                      chat.name[0].toUpperCase(),
                      style: TextStyle(
                        color: chat.isOwner
                            ? AppTheme.primaryColor
                            : AppTheme.secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Red dot for unread messages
                  if (chat.hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            chat.unreadCount > 9 ? '9+' : '${chat.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: chat.hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        _buildStatusChip(chat.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(chat.subtitle, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      chat.isOwner ? 'Your ride' : 'Requested to join',
                      style: TextStyle(
                        fontSize: 11,
                        color: chat.isOwner
                            ? AppTheme.primaryColor
                            : AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = AppTheme.warningColor;
        label = 'Active';
        break;
      case 'accepted':
        color = AppTheme.secondaryColor;
        label = 'Confirmed';
        break;
      case 'rejected':
        color = const Color(0xFF6B7280);
        label = 'Closed';
        break;
      default:
        color = const Color(0xFF6B7280);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class ChatItem {
  final String joinRequestId;
  final String name;
  final String subtitle;
  final String status;
  final bool isOwner;
  final DateTime createdAt;
  final int unreadCount;

  ChatItem({
    required this.joinRequestId,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.isOwner,
    required this.createdAt,
    this.unreadCount = 0,
  });

  bool get hasUnread => unreadCount > 0;
}
