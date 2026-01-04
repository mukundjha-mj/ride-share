// API Configuration
class ApiConfig {
  // LOCAL TESTING - Uncomment production URLs before deploying
  // Use 192.168.1.5 for physical device testing (LAN IP)
  static const String baseUrl = 'http://192.168.1.5:5000';
  static const String websocketUrl = 'http://192.168.1.5:3001';

  // Production URLs (uncomment before building APK)
  // static const String baseUrl = 'https://ride-share-prod.vercel.app';
  // static const String websocketUrl = 'https://rideshare-websocket.onrender.com';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/profile';

  // Ride endpoints
  static const String rides = '/rides';
  static const String myRides = '/rides/my';

  // Join endpoints
  static String joinRide(String rideId) => '/rides/$rideId/join';
  static String rideRequests(String rideId) => '/rides/$rideId/requests';
  static String acceptRequest(String joinId) => '/join/$joinId/accept';
  static String myRequests = '/join/my';

  // Chat endpoints
  static String chatMessages(String joinId) => '/join/$joinId/messages';
}
