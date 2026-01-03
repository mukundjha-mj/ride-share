import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/ride_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const RideShareApp());
}

class RideShareApp extends StatelessWidget {
  const RideShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
      ],
      child: MaterialApp(
        title: 'RideShare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
