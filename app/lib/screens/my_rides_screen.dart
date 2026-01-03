import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../config/theme.dart';
import '../widgets/ride_card.dart';
import 'ride_requests_screen.dart';

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.myRides.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.myRides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 80,
                  color: AppTheme.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  'No rides posted yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to post your first ride',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadMyRides(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.myRides.length,
            itemBuilder: (context, index) {
              final ride = provider.myRides[index];
              return RideCard(
                ride: ride,
                showJoinButton: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RideRequestsScreen(ride: ride),
                    ),
                  ).then((_) => provider.loadMyRides());
                },
              );
            },
          ),
        );
      },
    );
  }
}
