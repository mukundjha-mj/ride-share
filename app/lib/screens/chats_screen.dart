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

    // Sort by most recent
    chats.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _chats = chats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: AppTheme.textHint),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Join a ride or wait for requests',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadChats,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return _buildChatTile(chat);
        },
      ),
    );
  }

  Widget _buildChatTile(ChatItem chat) {
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: chat.isOwner
                    ? AppTheme.primaryColor.withValues(alpha: 0.2)
                    : AppTheme.secondaryColor.withValues(alpha: 0.2),
                child: Text(
                  chat.name[0].toUpperCase(),
                  style: TextStyle(
                    color: chat.isOwner
                        ? AppTheme.primaryColor
                        : AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        _buildStatusChip(chat.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
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
              const Icon(Icons.chevron_right, color: AppTheme.textHint),
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
        color = AppTheme.successColor;
        label = 'Confirmed';
        break;
      case 'rejected':
        color = AppTheme.textHint;
        label = 'Closed';
        break;
      default:
        color = AppTheme.textHint;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
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
