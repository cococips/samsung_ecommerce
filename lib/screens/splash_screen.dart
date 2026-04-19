import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _entranceController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleEntrance;
  late Animation<double> _fadeEntrance;

  @override
  void initState() {
    super.initState();

    // 1. Controller untuk Animasi Masuk (Fade In + Scale Up halus)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleEntrance = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutExpo)
    );
    _fadeEntrance = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut)
    );

    // 2. Controller Orbit (Dipercepat putarannya agar dinamis)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), 
    )..repeat();

    // 3. Controller Denyut Logo (Smooth pulse)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    // Mulai animasi pop-up pertama kali aplikasi dibuka
    _entranceController.forward();

    // --- DURASI DIPERCEPAT: Pindah halaman dalam 3 Detik ---
    Timer(const Duration(milliseconds: 3000), () async {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim, secondAnim) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
          transitionsBuilder: (context, anim, secondAnim, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 800), // Transisi hilang yang sangat halus
        ),
      );
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background dengan gradasi perak sangat halus khas UI Premium
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Colors.white, Colors.grey[50]!, Colors.grey[200]!],
            radius: 1.5,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeEntrance,
          child: ScaleTransition(
            scale: _scaleEntrance,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // --- LAYER 1: MULTI-ORBIT ANIMATION (PREMIUM GLOW) ---
                RotationTransition(
                  turns: _rotationController,
                  child: _buildPremiumRing(320, Colors.blue[900]!.withValues(alpha: 0.04), 1.5),
                ),
                RotationTransition(
                  turns: ReverseAnimation(_rotationController),
                  child: _buildPremiumRing(260, Colors.blue[600]!.withValues(alpha: 0.08), 2.0),
                ),
                RotationTransition(
                  turns: _rotationController,
                  child: _buildPremiumRing(200, Colors.black.withValues(alpha: 0.03), 1.0),
                ),
                
                // --- LAYER 2: LOGO BERDENYUT DENGAN CAHAYA (GLOW) ---
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue[100]!.withValues(alpha: 0.5), // Cahaya berpendar di belakang logo
                          blurRadius: 40,
                          spreadRadius: 10,
                        )
                      ]
                    ),
                    child: Image.asset('assets/smsnglogo.png', width: 180),
                  ),
                ),

                // --- LAYER 3: FOOTER GALAXY AI & PROGRESS BAR ---
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Teks gaya Galaxy Unpacked dengan Ikon Bintang AI
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 14, color: Colors.blue[900]),
                            const SizedBox(width: 8),
                            Text(
                              "POWERED BY GALAXY AI",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 6.0,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        // Loading Bar Tipis Futuristik (Edge-to-Edge feel)
                        SizedBox(
                          width: 140,
                          height: 2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[900]!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper untuk membuat lingkaran orbit dengan Satelit Bercahaya
  Widget _buildPremiumRing(double size, Color color, double width) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: width),
      ),
      child: Stack(
        children: [
          // Satelit Bercahaya (Glow Effect)
          Positioned(
            top: size / 6,
            right: size / 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color.withAlpha(200), // Warna solid
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color, blurRadius: 10, spreadRadius: 2) // Efek bersinar (Glow)
                ]
              ),
            ),
          ),
        ],
      ),
    );
  }
}