import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/services/ad_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/library/providers/library_provider.dart';
import 'features/library/providers/review_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/scan/providers/scan_provider.dart';
import 'features/social/providers/social_provider.dart';
import 'features/social/providers/loan_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialiser Firebase en priorité (nécessaire pour l'auth)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Initialiser Supabase (nécessaire pour le profil)
  try {
    await SupabaseService.initialize()
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  // Lancer l'app IMMÉDIATEMENT — AdMob s'initialise en arrière-plan
  runApp(const BiblioShareApp());

  // AdMob en arrière-plan (non bloquant)
  _initAdMobInBackground();
}

/// Initialise AdMob sans bloquer le rendu de l'app
Future<void> _initAdMobInBackground() async {
  try {
    await AdService.initialize()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('AdMob init error (background): $e');
  }
}

class BiblioShareApp extends StatefulWidget {
  const BiblioShareApp({super.key});

  @override
  State<BiblioShareApp> createState() => _BiblioShareAppState();
}

class _BiblioShareAppState extends State<BiblioShareApp> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
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
        routerConfig: AppRouter.router(_authProvider),
      ),
    );
  }
}
