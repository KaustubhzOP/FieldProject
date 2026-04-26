import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'config/app_theme.dart';
import 'config/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/route_provider.dart';
import 'providers/collection_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for Web explicitly
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

  runApp(const AdminWebPortalApp());
}

class AdminWebPortalApp extends StatelessWidget {
  const AdminWebPortalApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => CollectionProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'BMC Admin Dashboard',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light, // Enforce light theme for municipal platform
            home: const WebSplashScreen(),
          );
        },
      ),
    );
  }
}

class WebSplashScreen extends StatefulWidget {
  const WebSplashScreen({super.key});

  @override
  State<WebSplashScreen> createState() => _WebSplashScreenState();
}

class _WebSplashScreenState extends State<WebSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 1));
    
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();
    
    if (!mounted) return;
    
    if (authProvider.isLoggedIn) {
      if (authProvider.userRole == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminHome()),
        );
      } else {
        // Log out non-admin users trying to access the portal
        await authProvider.logout();
        _showError('Access Denied: This portal is for Administrators only.');
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _showError(String msg) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person_rounded, size: 80, color: AppColors.warning),
                const SizedBox(height: 20),
                Text(msg, style: const TextStyle(fontSize: 18, color: AppColors.textHeader, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => AdminWebPortalApp.navigatorKey.currentState?.pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen())
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.card,
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings_rounded, size: 100, color: AppColors.primary),
            SizedBox(height: 24),
            Text('BMC ADMIN PORTAL', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textHeader, letterSpacing: 2)),
            SizedBox(height: 48),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
