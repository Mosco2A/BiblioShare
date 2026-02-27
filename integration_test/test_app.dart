import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:biblioshare/core/router/app_router.dart';
import 'package:biblioshare/core/services/supabase_service.dart';
import 'package:biblioshare/core/theme/app_theme.dart';
import 'package:biblioshare/features/auth/providers/auth_provider.dart';
import 'package:biblioshare/features/library/providers/library_provider.dart';
import 'package:biblioshare/features/library/providers/review_provider.dart';
import 'package:biblioshare/features/profile/providers/profile_provider.dart';
import 'package:biblioshare/features/scan/providers/scan_provider.dart';
import 'package:biblioshare/features/social/providers/loan_provider.dart';
import 'package:biblioshare/features/social/providers/social_provider.dart';
import 'package:biblioshare/firebase_options.dart';

/// Entry point de test qui initialise l'app puis force l'état authentifié
/// pour pouvoir tester tous les écrans sans passer par Firebase Auth.
Future<AuthProvider> initTestApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  try {
    await SupabaseService.initialize().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  final authProvider = AuthProvider();

  // Forcer l'état authentifié avec un userId de test
  // Cela déclenche le chargement des seed data (fallback Supabase)
  authProvider.forceAuthenticatedForTest('test-user-acceptance');

  runApp(_TestBiblioShareApp(authProvider: authProvider));

  return authProvider;
}

class _TestBiblioShareApp extends StatelessWidget {
  final AuthProvider authProvider;

  const _TestBiblioShareApp({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
      ],
      child: MaterialApp.router(
        title: 'BiblioShare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router(authProvider),
      ),
    );
  }
}
