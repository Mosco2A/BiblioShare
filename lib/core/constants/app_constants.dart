/// Constantes globales BiblioShare
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'BiblioShare';
  static const String appVersion = '1.0.0';

  // Supabase — à remplacer par les vraies valeurs
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

  // AdMob — Test IDs (remplacer en production)
  static const String admobAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String admobIosAppId =
      'ca-app-pub-3940256099942544~1458002511';

  // Banner Ad Unit IDs (test)
  static const String bannerAdAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String bannerAdIos = 'ca-app-pub-3940256099942544/2934735716';

  // Interstitial Ad Unit IDs (test)
  static const String interstitialAdAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String interstitialAdIos =
      'ca-app-pub-3940256099942544/4411468910';

  // Onboarding
  static const int onboardingPageCount = 4;
  static const int otpLength = 6;

  // Bio
  static const int maxBioLength = 280;

  // Default settings
  static const int defaultLoanDays = 30;
  static const int defaultMaxLoansPerFriend = 3;
  static const int defaultReminderFrequencyDays = 3;

  // Use test ads in debug mode
  static const bool showTestAds = true;
}
