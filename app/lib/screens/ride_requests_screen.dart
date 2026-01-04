import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pendingCount = _requests.where((r) => r.isPending).length;
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat.jm();

    return Scaffold(
      appBar: AppBar(title: const Text('Join Requests')),
      body: Column(
        children: [
          // Ride info - Simple minimalist card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route with dots
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppTheme.successColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 28,
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ride.from,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              widget.ride.to,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(widget.ride.status, colorScheme),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Date, time, pending count
                  Row(
                    children: [
                      Text(
                        '${dateFormat.format(widget.ride.timeStart)} • ${timeFormat.format(widget.ride.timeStart)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      if (pendingCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$pendingCount pending',
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Requests list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 56,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No requests yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Wait for people to request to join',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRequests,
                    color: AppTheme.primaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) => _buildRequestItem(
                        _requests[index],
                        theme,
                        colorScheme,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, ColorScheme colorScheme) {
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = AppTheme.successColor;
        label = 'Open';
        break;
      case 'filled':
        color = colorScheme.primary;
        label = 'Filled';
        break;
      case 'cancelled':
        color = AppTheme.errorColor;
        label = 'Closed';
        break;
      default:
        color = colorScheme.outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRequestItem(
    JoinRequest request,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Text(
                  (request.requester?.name ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requester?.name ?? 'Unknown',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildRequestStatus(request.status, colorScheme),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestStatus(String status, ColorScheme colorScheme) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = AppTheme.warningColor;
        label = 'Pending';
        break;
      case 'accepted':
        color = AppTheme.successColor;
        label = 'Accepted';
        break;
      default:
        color = colorScheme.outline;
        label = 'Closed';
    }

    return Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
    );
  }
}
