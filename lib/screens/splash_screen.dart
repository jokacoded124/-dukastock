import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller,
            curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller,
            curve: const Interval(0.3, 0.8, curve: Curves.easeIn)));
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
        CurvedAnimation(parent: _controller,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOut)));
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2500), _checkAuth);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final role = doc.data()?['role'] ?? 'retailer';
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => DashboardScreen(role: role)));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGreen,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 64),
                ),
              ),
              const SizedBox(height: 28),
              Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Column(
                    children: [
                      const Text('DukaStock',
                          style: TextStyle(fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: Colors.white, letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text('B2B Marketplace',
                          style: TextStyle(fontSize: 16,
                              color: Colors.white.withOpacity(0.8))),
                      const SizedBox(height: 6),
                      Text('Connecting Wholesalers & Retailers in Kenya',
                          style: TextStyle(fontSize: 12,
                              color: Colors.white.withOpacity(0.6)),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 64),
              Opacity(
                opacity: _fadeAnimation.value,
                child: SizedBox(width: 32, height: 32,
                    child: CircularProgressIndicator(
                        color: Colors.white.withOpacity(0.8), strokeWidth: 2.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
