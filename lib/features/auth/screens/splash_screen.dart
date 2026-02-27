import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

/// Ecran de chargement au lancement de l'app
/// Timeout de sécurité : si l'auth ne résout pas en 4s, force unauthenticated
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSafetyTimeout();
  }

  void _startSafetyTimeout() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.status == AuthStatus.initial) {
        // Auth n'a pas résolu → forcer vers login
        debugPrint('Splash timeout: auth still initial, forcing unauthenticated');
        auth.forceUnauthenticated();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.surfaceWarm,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo SVG
              SvgPicture.asset(
                'assets/images/logo.svg',
                width: 160,
                height: 160,
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8), delay: 200.ms),
              const SizedBox(height: 16),
              Text(
                'BiblioShare',
                style: GoogleFonts.merriweather(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
              const SizedBox(height: 8),
              Text(
                'PARTAGEZ VOS LECTURES',
                style: GoogleFonts.merriweather(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondary,
                  letterSpacing: 4,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
              const SizedBox(height: 48),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppColors.primaryLight,
                  strokeWidth: 3,
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
