import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/join_request.dart';

class RequestCard extends StatelessWidget {
  final JoinRequest request;
  final VoidCallback? onTap;

  const RequestCard({super.key, required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d');
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
              // Status and date
              Row(
                children: [
                  _buildStatusChip(request.status, colorScheme),
                  const Spacer(),
                  Text(
                    dateFormat.format(request.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Ride info
              if (request.ride != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(
                          Icons.circle,
                          color: colorScheme.outline,
                          size: 10,
                        ),
                        Container(
                          width: 2,
                          height: 16,
                          color: colorScheme.outline.withOpacity(0.3),
                        ),
                        Icon(
                          Icons.location_on,
                          color: colorScheme.primary,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.ride!.from,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            request.ride!.to,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Time info
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${dateFormat.format(request.ride!.timeStart)} • ${timeFormat.format(request.ride!.timeStart)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: colorScheme.outline),
                  ],
                ),
              ] else
                Row(
                  children: [
                    Text(
                      'Ride details unavailable',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: colorScheme.outline),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, ColorScheme colorScheme) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        color = const Color(0xFFF59E0B); // Amber
        label = 'Pending';
        icon = Icons.schedule;
        break;
      case 'accepted':
        color = const Color(0xFF22C55E); // Green
        label = 'Confirmed';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = colorScheme.outline;
        label = 'Closed';
        icon = Icons.remove_circle_outline;
        break;
      default:
        color = colorScheme.outline;
        label = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
