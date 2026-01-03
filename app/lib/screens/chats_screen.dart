import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../config/theme.dart';
import '../services/ride_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);

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
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadChats,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
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
                            style: theme.textTheme.titleMedium,
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

  ChatItem({
    required this.joinRequestId,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.isOwner,
    required this.createdAt,
  });
}
