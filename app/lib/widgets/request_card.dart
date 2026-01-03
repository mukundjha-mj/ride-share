import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/join_request.dart';
import '../config/theme.dart';

class RequestCard extends StatelessWidget {
  final JoinRequest request;
  final VoidCallback? onTap;

  const RequestCard({super.key, required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat.jm();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status and date
              Row(
                children: [
                  _buildStatusChip(request.status),
                  const Spacer(),
                  Text(
                    dateFormat.format(request.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
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
                        const Icon(
                          Icons.trip_origin,
                          color: AppTheme.successColor,
                          size: 14,
                        ),
                        Container(
                          width: 2,
                          height: 16,
                          color: AppTheme.textHint,
                        ),
                        const Icon(
                          Icons.location_on,
                          color: AppTheme.errorColor,
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
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            request.ride!.to,
                            style: Theme.of(context).textTheme.bodyMedium,
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
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${dateFormat.format(request.ride!.timeStart)} • ${timeFormat.format(request.ride!.timeStart)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppTheme.textHint),
                  ],
                ),
              ] else
                Row(
                  children: [
                    Text(
                      'Ride details unavailable',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppTheme.textHint),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
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
        label = 'Confirmed';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = AppTheme.textHint;
        label = 'Closed';
        icon = Icons.remove_circle_outline;
        break;
      default:
        color = AppTheme.textHint;
        label = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
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
