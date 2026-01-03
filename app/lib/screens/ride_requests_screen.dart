import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../models/join_request.dart';
import '../services/ride_service.dart';
import '../config/theme.dart';
import 'chat_screen.dart';

class RideRequestsScreen extends StatefulWidget {
  final Ride ride;

  const RideRequestsScreen({super.key, required this.ride});

  @override
  State<RideRequestsScreen> createState() => _RideRequestsScreenState();
}

class _RideRequestsScreenState extends State<RideRequestsScreen> {
  final RideService _rideService = RideService();
  List<JoinRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    _requests = await _rideService.getRideRequests(widget.ride.id);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _requests.where((r) => r.isPending).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Join Requests')),
      body: Column(
        children: [
          // Ride info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.trip_origin,
                      color: AppTheme.successColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.ride.from,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(left: 7),
                  height: 20,
                  width: 2,
                  color: AppTheme.textHint,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.errorColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.ride.to,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatusChip(widget.ride.status),
                    const SizedBox(width: 8),
                    if (pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$pendingCount pending',
                          style: const TextStyle(
                            color: AppTheme.warningColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Requests list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No requests yet',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Wait for people to request to join',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRequests,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        return _buildRequestItem(request);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = AppTheme.successColor;
        label = 'Open';
        break;
      case 'filled':
        color = AppTheme.primaryColor;
        label = 'Filled';
        break;
      case 'cancelled':
        color = AppTheme.errorColor;
        label = 'Cancelled';
        break;
      default:
        color = AppTheme.textHint;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRequestItem(JoinRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ChatScreen(joinRequestId: request.id, isOwner: true),
            ),
          ).then((_) => _loadRequests());
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                child: Text(
                  (request.requester?.name ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requester?.name ?? 'Unknown User',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    _buildRequestStatusChip(request.status),
                  ],
                ),
              ),
              // Arrow
              const Icon(Icons.chevron_right, color: AppTheme.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        color = AppTheme.warningColor;
        label = 'Pending';
        icon = Icons.schedule;
        break;
      case 'accepted':
        color = AppTheme.successColor;
        label = 'Accepted';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = AppTheme.textHint;
        label = 'Closed';
        icon = Icons.close;
        break;
      default:
        color = AppTheme.textHint;
        label = status;
        icon = Icons.help;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
