import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/scan/screens/scan_screen.dart';
import '../../features/scan/screens/scan_results_screen.dart';

/// Noms des routes
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String scan = '/scan';
  static const String scanResults = '/scan/results';
}

/// Configuration du routeur GoRouter avec auth redirect
class AppRouter {
  AppRouter._();

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: authProvider,
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final status = authProvider.status;
        final currentPath = state.matchedLocation;

        // Pendant l'initialisation, rester sur le splash
        if (status == AuthStatus.initial) {
          return currentPath == AppRoutes.splash ? null : AppRoutes.splash;
        }

        // Non connecté → rediriger vers login
        if (status == AuthStatus.unauthenticated) {
          // Autoriser l'accès au login et OTP
          if (currentPath == AppRoutes.login ||
              currentPath == AppRoutes.otp) {
            return null;
          }
          return AppRoutes.login;
        }

        // Connecté mais onboarding pas terminé → forcer onboarding
        if (status == AuthStatus.onboarding) {
          if (currentPath == AppRoutes.onboarding) return null;
          return AppRoutes.onboarding;
        }

        // Connecté et onboarding terminé → ne pas rester sur login/splash/onboarding
        if (status == AuthStatus.authenticated) {
          if (currentPath == AppRoutes.splash ||
              currentPath == AppRoutes.login ||
              currentPath == AppRoutes.otp ||
              currentPath == AppRoutes.onboarding) {
            return AppRoutes.home;
          }
          return null;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.otp,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return OtpVerificationScreen(
              verificationId: extra['verificationId'] as String,
              phoneNumber: extra['phoneNumber'] as String,
              resendToken: extra['resendToken'] as int?,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Paramètres — bientôt disponible')),
          ),
        ),
        GoRoute(
          path: AppRoutes.scan,
          builder: (context, state) => const ScanScreen(),
        ),
        GoRoute(
          path: AppRoutes.scanResults,
          builder: (context, state) => const ScanResultsScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page introuvable : ${state.error}'),
        ),
      ),
    );
  }
}
