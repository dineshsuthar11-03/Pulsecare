import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pulsecare/core/theme/app_theme.dart';
import 'package:pulsecare/core/constants/app_strings.dart';
import 'package:pulsecare/features/home/home_screen.dart';
import 'package:pulsecare/features/auth/role_selection_screen.dart';
import 'package:pulsecare/features/doctor/doctor_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase configuration
  // In production web builds, .env assets may not be available,
  // so we fall back to baked-in public Supabase credentials.
  const fallbackSupabaseUrl = 'https://rpyccvaakjhpsumgqarf.supabase.co';
  const fallbackSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJweWNjdmFha2pocHN1bWdxYXJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4MjkyNDcsImV4cCI6MjA4NjQwNTI0N30.Pogb_nMKgv0WIbyHEb0V8LU8iNW9slwanKCTt_aNVwM';

  final supabaseUrl = fallbackSupabaseUrl;
  final supabaseAnonKey = fallbackSupabaseAnonKey;

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }

  runApp(const Pulsecare());
}

class Pulsecare extends StatelessWidget {
  const Pulsecare({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.session;
          if (session != null) {
            // In a real app, we need to fetch the user role from Supabase first
            // to decide which dashboard to show.
            // For now, we'll fetch it on the fly or improved via a specific AuthProvider.
            // But since this is inside build(), async operations are tricky.
            // A better approach is to have a specialized 'AuthWrapper' widget.
            return const AuthWrapper();
          }

          return const RoleSelectionScreen();
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    _determineTargetScreen();
  }

  Future<void> _determineTargetScreen() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // 1. Try metadata first (fastest, avoids DB query)
        String? role = user.userMetadata?['role'] as String?;

        // 2. If metadata is missing, query the 'users' table
        if (role == null) {
          final response = await Supabase.instance.client
              .from('users')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();
          role = response?['role'] as String?;
        }

        if (role == 'doctor') {
          _targetScreen = const DoctorDashboardScreen();
        } else if (role == 'admin') {
          _targetScreen = const HomeScreen(); // Placeholder for admin dashboard
        } else {
          _targetScreen = const HomeScreen();
        }
      }
    } catch (e) {
      debugPrint('Error determining role: $e');
      _targetScreen = const HomeScreen(); // Fallback to patient home
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _targetScreen ?? const RoleSelectionScreen();
  }
}
