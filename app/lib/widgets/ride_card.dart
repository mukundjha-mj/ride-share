import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/ride.dart';
import '../providers/ride_provider.dart';
import '../config/theme.dart';
import '../screens/chat_screen.dart';

class RideCard extends StatelessWidget {
  final Ride ride;
  final bool showJoinButton;
  final VoidCallback? onTap;

  const RideCard({
    super.key,
    required this.ride,
    this.showJoinButton = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat.jm();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner info
              if (ride.owner != null)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.2,
                      ),
                      child: Text(
                        ride.owner!.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ride.owner!.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _buildStatusChip(ride.status),
                  ],
                ),

              const SizedBox(height: 16),

              // Route
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.trip_origin,
                        color: AppTheme.successColor,
                        size: 16,
                      ),
                      Container(width: 2, height: 24, color: AppTheme.textHint),
                      const Icon(
                        Icons.location_on,
                        color: AppTheme.errorColor,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.from,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ride.to,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Time and seats info
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${dateFormat.format(ride.timeStart)} • ${timeFormat.format(ride.timeStart)} - ${timeFormat.format(ride.timeEnd)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.seats}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              // Pending count for owner
              if (ride.pendingRequestCount != null &&
                  ride.pendingRequestCount! > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        size: 14,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${ride.pendingRequestCount} pending request${ride.pendingRequestCount! > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppTheme.warningColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Join button
              if (showJoinButton && ride.isOpen) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleJoin(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Request to Join'),
                  ),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Future<void> _handleJoin(BuildContext context) async {
    final provider = context.read<RideProvider>();
    final request = await provider.joinRide(ride.id);

    if (request != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent! Opening chat...'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 1),
        ),
      );

      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(joinRequestId: request.id),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send request'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
