import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/unread_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rideProvider = context.read<RideProvider>();
      final authProvider = context.read<AuthProvider>();

      rideProvider.refreshAll();
      rideProvider.startRealTimeUpdates(currentUserId: authProvider.user?.id);

      // Start polling for unread messages
      context.read<UnreadProvider>().startPolling();
    });
  }

  @override
  void dispose() {
    // Note: Provider handles its own disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final unreadProvider = context.watch<UnreadProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            themeProvider.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: () => themeProvider.toggleTheme(),
          tooltip: 'Toggle theme',
        ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Refresh unread when switching to chats
          if (index == 2) {
            unreadProvider.fetchUnreadCount();
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Browse',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: 'My Rides',
          ),
          BottomNavigationBarItem(
            icon: _buildChatIcon(unreadProvider, false),
            activeIcon: _buildChatIcon(unreadProvider, true),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.send_outlined),
            activeIcon: Icon(Icons.send),
            label: 'Requests',
          ),
        ],
      ),
    );
  }

  Widget _buildChatIcon(UnreadProvider unreadProvider, bool isActive) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(isActive ? Icons.chat_bubble : Icons.chat_bubble_outline),
        if (unreadProvider.hasUnread)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadProvider.totalUnreadCount > 9
                    ? '9+'
                    : '${unreadProvider.totalUnreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<RideProvider>(
      builder: (context, provider, child) {
        // Use specific feed loading state to avoid flicker from background updates
        if (provider.isFeedLoading && provider.rides.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.rides.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text('No rides available', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later or post your own ride',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadRides(),
          color: AppTheme.primaryColor,
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
