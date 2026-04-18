import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(const Duration(milliseconds: 3400), () {
      if (!mounted) {
        return;
      }
      final UserRole? role = AuthService.instance.currentSession?.user.role;
      final Widget destination = role == null
          ? const LoginScreen()
          : role == UserRole.admin
          ? const AdminDashboardScreen()
          : const HomeScreen();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => destination,
          transitionsBuilder: (_, Animation<double> anim, _, Widget child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        child: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _controller,
              curve: Curves.elasticOut,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const AnimatedBrandLogo(size: 220, showText: true),
                const SizedBox(height: 18),
                Text(
                  'Learn smarter with one modern coaching platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
