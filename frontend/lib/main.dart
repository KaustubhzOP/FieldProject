import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/route_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/resident/resident_home.dart';
import 'screens/driver/driver_home.dart';
import 'screens/admin/admin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBvKTIUtyFGF5V7C0CpPrqjq5MfVAitniY",
        authDomain: "smart-waste-collection-6a2f0.firebaseapp.com",
        projectId: "smart-waste-collection-6a2f0",
        storageBucket: "smart-waste-collection-6a2f0.firebasestorage.app",
        messagingSenderId: "25095083900",
        appId: "1:25095083900:web:c874f440860a14fcad36f9",
        measurementId: "G-594ZW9DMQR",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  runApp(const SmartWasteApp());
}

class SmartWasteApp extends StatelessWidget {
  const SmartWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Smart Waste Collection',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();
    
    if (!mounted) return;
    
    if (authProvider.isLoggedIn) {
      _navigateToHome(authProvider.userRole!);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateToHome(String role) {
    Widget homeScreen;
    
    switch (role) {
      case 'resident':
        homeScreen = const ResidentHome();
        break;
      case 'driver':
        homeScreen = const DriverHome();
        break;
      case 'admin':
        homeScreen = const AdminHome();
        break;
      default:
        homeScreen = const LoginScreen();
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => homeScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.recycling,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'Smart Waste Collection',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'BMC Waste Management System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
