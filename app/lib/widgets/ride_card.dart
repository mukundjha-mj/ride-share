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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat.jm();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        ride.owner!.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ride.owner!.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    _buildStatusChip(ride.status),
                  ],
                ),

              const SizedBox(height: 16),

              // Route visualization
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(
                        Icons.circle,
                        color: AppTheme.secondaryColor,
                        size: 12,
                      ),
                      Container(
                        width: 2,
                        height: 28,
                        color: colorScheme.outline.withOpacity(0.3),
                      ),
                      Icon(
                        Icons.location_on,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ride.from, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 18),
                        Text(ride.to, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(color: colorScheme.outline.withOpacity(0.2), height: 1),
              const SizedBox(height: 12),

              // Time and seats info
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${dateFormat.format(ride.timeStart)} • ${timeFormat.format(ride.timeStart)} - ${timeFormat.format(ride.timeEnd)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 4),
                  Text('${ride.seats}', style: theme.textTheme.bodySmall),
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
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
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
        color = AppTheme.secondaryColor;
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
        color = const Color(0xFF6B7280);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
          backgroundColor: AppTheme.secondaryColor,
          duration: Duration(seconds: 1),
        ),
      );

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
