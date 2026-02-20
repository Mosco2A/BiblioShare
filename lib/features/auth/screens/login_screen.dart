import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/social_sign_in_button.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _fullPhoneNumber = '';
  bool _isLoading = false;

  Future<void> _signInWithPhone() async {
    if (_fullPhoneNumber.isEmpty) {
      context.showSnackBar('Veuillez saisir votre numéro', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    await AuthService.signInWithPhone(
      phoneNumber: _fullPhoneNumber,
      onCodeSent: (verificationId, resendToken) {
        setState(() => _isLoading = false);
        context.push('/otp', extra: {
          'verificationId': verificationId,
          'phoneNumber': _fullPhoneNumber,
          'resendToken': resendToken,
        });
      },
      onError: (errorMessage) {
        setState(() => _isLoading = false);
        context.showSnackBar(errorMessage, isError: true);
      },
      onAutoVerification: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            setState(() => _isLoading = false);
            await AdService.showInterstitial();
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            context.showSnackBar('Erreur de vérification automatique',
                isError: true);
          }
        }
      },
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.signInWithGoogle();
      if (result != null && mounted) {
        await AdService.showInterstitial();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erreur Google Sign-In', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithApple();
      if (mounted) {
        await AdService.showInterstitial();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erreur Apple Sign-In', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Connexion en cours...',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),

                // Logo / Title
                Icon(
                  Icons.menu_book_rounded,
                  size: 72,
                  color: AppColors.primary,
                ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),

                const SizedBox(height: 16),

                Text(
                  'BiblioShare',
                  style: context.textTheme.headlineLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 8),

                Text(
                  'Ta bibliothèque. Tes amis. Tes livres.',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 48),

                // Phone input
                IntlPhoneField(
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    counterText: '',
                  ),
                  initialCountryCode: 'FR',
                  onChanged: (phone) {
                    _fullPhoneNumber = phone.completeNumber;
                  },
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Phone sign-in button
                ElevatedButton.icon(
                  onPressed: _signInWithPhone,
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('Recevoir un code SMS'),
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou continuer avec',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ).animate().fadeIn(delay: 800.ms),

                const SizedBox(height: 24),

                // Google Sign-In
                SocialSignInButton(
                  label: 'Google',
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  onPressed: _signInWithGoogle,
                ).animate().fadeIn(delay: 900.ms),

                // Apple Sign-In (iOS only)
                if (!kIsWeb && Platform.isIOS) ...[
                  const SizedBox(height: 12),
                  SocialSignInButton(
                    label: 'Apple',
                    icon: const Icon(Icons.apple, size: 24),
                    onPressed: _signInWithApple,
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ).animate().fadeIn(delay: 1000.ms),
                ],

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
