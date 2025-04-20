// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'screens/trends_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ApneaAidApp());
}

class ApneaAidApp extends StatefulWidget {
  const ApneaAidApp({Key? key}) : super(key: key);

  @override
  State<ApneaAidApp> createState() => _ApneaAidAppState();
}

class _ApneaAidAppState extends State<ApneaAidApp> {
  final AuthService _authService = AuthService();
  bool _isInitialized = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Check authentication state
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Allow time for the auth service to initialize
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isInitialized = true;
      _isLoggedIn = _authService.isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apnea-Aid',
      theme: AppTheme.theme,
      // Show splash screen until we determine auth state
      home: !_isInitialized
          ? const SplashScreen()
          : _isLoggedIn 
              ? const HomeScreen() 
              : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/history': (context) => const HistoryScreen(),
        '/trends': (context) => const TrendsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// Simple splash screen to show while checking auth state
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.nightlight_round,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'APNEA-AID',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }
}
