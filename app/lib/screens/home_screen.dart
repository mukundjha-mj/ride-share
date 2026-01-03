import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../config/theme.dart';
import '../widgets/ride_card.dart';
import 'create_ride_screen.dart';
import 'my_rides_screen.dart';
import 'my_requests_screen.dart';
import 'chats_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load data when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideProvider>().refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _RideFeed(),
          MyRidesScreen(),
          ChatsScreen(),
          MyRequestsScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRideScreen()),
                ).then((_) {
                  context.read<RideProvider>().loadMyRides();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Post Ride'),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Browse'),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car),
              label: 'My Rides',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chats',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.send), label: 'Requests'),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Available Rides';
      case 1:
        return 'My Rides';
      case 2:
        return 'Chats';
      case 3:
        return 'My Requests';
      default:
        return 'RideShare';
    }
  }
}

class _RideFeed extends StatelessWidget {
  const _RideFeed();

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.rides.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.rides.isEmpty) {
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
                  'No rides available',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later or post your own ride',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadRides(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadRides(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.rides.length,
            itemBuilder: (context, index) {
              return RideCard(
                ride: provider.rides[index],
                showJoinButton: true,
              );
            },
          ),
        );
      },
    );
  }
}
