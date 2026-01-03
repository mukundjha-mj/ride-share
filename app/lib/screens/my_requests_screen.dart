import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../config/theme.dart';
import '../widgets/request_card.dart';
import 'chat_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, provider, child) {
        if (provider.myRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_outlined, size: 80, color: AppTheme.textHint),
                const SizedBox(height: 16),
                Text(
                  'No requests sent',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse rides and request to join',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadMyRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.myRequests.length,
            itemBuilder: (context, index) {
              final request = provider.myRequests[index];
              return RequestCard(
                request: request,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(joinRequestId: request.id),
                    ),
                  ).then((_) => provider.loadMyRequests());
                },
              );
            },
          ),
        );
      },
    );
  }
}
