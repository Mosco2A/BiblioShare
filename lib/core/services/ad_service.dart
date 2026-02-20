import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/app_constants.dart';

/// Service AdMob — adapté du pattern RideTogether
class AdService {
  AdService._();

  static InterstitialAd? _interstitialAd;
  static String? _loadingInterstitialAdUnitId;

  /// Initialise le SDK Mobile Ads
  static Future<void> initialize() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    _updateRequestConfiguration();
    requestConsent();
  }

  /// Met à jour la config de requête
  static void _updateRequestConfiguration() {
    if (kIsWeb) return;
    final requestConfiguration = RequestConfiguration();
    MobileAds.instance.updateRequestConfiguration(requestConfiguration);
  }

  // ── GDPR Consent ──

  /// Demande le consentement GDPR (UMP)
  static void requestConsent() {
    if (kIsWeb) return;
    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(params, () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        _loadConsentForm();
      }
    }, (error) {});
  }

  static void _loadConsentForm() {
    ConsentForm.loadConsentForm((consentForm) async {
      final status = await ConsentInformation.instance.getConsentStatus();
      if (status == ConsentStatus.required) {
        consentForm.show((error) {
          _loadConsentForm();
        });
      }
    }, (error) {});
  }

  // ── Interstitial ──

  /// Précharge un interstitial
  static void loadInterstitial() {
    if (kIsWeb) return;

    String adUnitId;
    if (Platform.isIOS) {
      adUnitId = AppConstants.showTestAds
          ? 'ca-app-pub-3940256099942544/4411468910'
          : AppConstants.interstitialAdIos;
    } else if (Platform.isAndroid) {
      adUnitId = AppConstants.showTestAds
          ? 'ca-app-pub-3940256099942544/1033173712'
          : AppConstants.interstitialAdAndroid;
    } else {
      return;
    }

    if (adUnitId == _loadingInterstitialAdUnitId) return;
    if (adUnitId == _interstitialAd?.adUnitId) return;

    _loadingInterstitialAdUnitId = adUnitId;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          if (adUnitId == _loadingInterstitialAdUnitId) {
            _interstitialAd = ad;
            _loadingInterstitialAdUnitId = null;
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Interstitial ad failed to load: $error');
          _loadingInterstitialAdUnitId = null;
        },
      ),
    );
  }

  /// Affiche l'interstitial préchargé
  static Future<bool> showInterstitial() async {
    if (_interstitialAd == null) {
      // L'ad attend l'utilisateur, pas l'inverse
      return true;
    }

    final completer = Completer<bool>();
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _interstitialAd = null;
        completer.complete(true);
        // Précharger le prochain
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('Interstitial failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        completer.complete(false);
        loadInterstitial();
      },
    );
    _interstitialAd!.show();
    return completer.future;
  }

  // ── Banner ──

  /// Crée un widget banner ad
  static Widget banner({double? width, double? height}) {
    return AdBanner(
      showTestAd: AppConstants.showTestAds,
      width: width,
      height: height,
    );
  }
}

/// Widget banner ad réutilisable
class AdBanner extends StatefulWidget {
  const AdBanner({
    super.key,
    required this.showTestAd,
    this.width,
    this.height,
  });

  final bool showTestAd;
  final double? width;
  final double? height;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  AdWidget? _adWidget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createBanner();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _createBanner() async {
    if (kIsWeb) return;

    final AdSize? size = widget.width != null && widget.height != null
        ? AdSize(
            height: widget.height!.toInt(),
            width: widget.width!.toInt(),
          )
        : await AdSize.getAnchoredAdaptiveBannerAdSize(
            Orientation.portrait,
            MediaQuery.sizeOf(context).width.truncate(),
          );

    if (size == null) return;

    final isAndroid = !kIsWeb && Platform.isAndroid;
    final banner = BannerAd(
      size: size,
      request: const AdRequest(),
      adUnitId: widget.showTestAd
          ? isAndroid
              ? 'ca-app-pub-3940256099942544/6300978111'
              : 'ca-app-pub-3940256099942544/2934735716'
          : isAndroid
              ? AppConstants.bannerAdAndroid
              : AppConstants.bannerAdIos,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _bannerAd = ad as BannerAd);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
    await banner.load();

    _adWidget = AdWidget(ad: banner);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd != null && _adWidget != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: _adWidget,
      );
    }
    return const SizedBox.shrink();
  }
}
