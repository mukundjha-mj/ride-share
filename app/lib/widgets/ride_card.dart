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
  final bool showDeleteButton;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const RideCard({
    super.key,
    required this.ride,
    this.showJoinButton = false,
    this.showDeleteButton = false,
    this.onTap,
    this.onDelete,
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
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route - Simple FROM → TO
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route dots
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
                          height: 32,
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
                  // Locations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.from,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          ride.to,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  _buildStatusChip(ride.status, colorScheme),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom info - Date, Time, Seats, Owner
              Row(
                children: [
                  // Owner avatar
                  if (ride.owner != null) ...[
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        ride.owner!.name[0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ride.owner!.name.split(' ')[0],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Divider dot
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colorScheme.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Date & Time
                  Text(
                    '${dateFormat.format(ride.timeStart)} • ${timeFormat.format(ride.timeStart)}',
                    style: theme.textTheme.bodySmall,
                  ),

                  const Spacer(),

                  // Seats
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.seats}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Pending requests notification
              if (ride.pendingRequestCount != null &&
                  ride.pendingRequestCount! > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_active,
                        size: 14,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${ride.pendingRequestCount} pending',
                        style: TextStyle(
                          color: AppTheme.warningColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Join button
              if (showJoinButton && ride.isOpen) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleJoin(context),
                    child: const Text('Request to Join'),
                  ),
                ),
              ],

              // Delete button (Owner only)
              if (showDeleteButton && !ride.isCancelled) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete Ride'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(color: AppTheme.errorColor),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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

  Future<void> _handleJoin(BuildContext context) async {
    final provider = context.read<RideProvider>();
    final request = await provider.joinRide(ride.id);

    if (request != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request sent!'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 1),
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
