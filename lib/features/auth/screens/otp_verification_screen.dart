import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../services/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });

  final String verificationId;
  final String phoneNumber;
  final int? resendToken;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late String _verificationId;
  int? _resendToken;
  bool _isLoading = false;
  bool _canResend = false;
  int _resendCountdown = 60;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _controllers =
        List.generate(AppConstants.otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(AppConstants.otpLength, (_) => FocusNode());
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown--);
      if (_resendCountdown <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length != AppConstants.otpLength) {
      context.showSnackBar('Veuillez saisir le code complet', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.verifyOtp(
        verificationId: _verificationId,
        smsCode: code,
      );
      if (mounted) {
        await AdService.showInterstitial();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        context.showSnackBar(
          e.code == 'invalid-verification-code'
              ? 'Code incorrect. Vérifiez et réessayez.'
              : 'Erreur de vérification',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erreur de vérification', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);
    await AuthService.signInWithPhone(
      phoneNumber: widget.phoneNumber,
      resendToken: _resendToken,
      onCodeSent: (newVerificationId, newResendToken) {
        setState(() {
          _verificationId = newVerificationId;
          _resendToken = newResendToken;
          _isLoading = false;
        });
        _startResendTimer();
        context.showSnackBar('Code renvoyé !');
      },
      onError: (errorMessage) {
        setState(() => _isLoading = false);
        context.showSnackBar(errorMessage, isError: true);
      },
      onAutoVerification: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Vérification...',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              Icon(
                Icons.message_outlined,
                size: 64,
                color: AppColors.primary,
              ).animate().fadeIn().scale(),

              const SizedBox(height: 24),

              Text(
                'Code de vérification',
                style: context.textTheme.headlineSmall,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                'Entrez le code envoyé au\n${widget.phoneNumber}',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 40),

              // OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(AppConstants.otpLength, (i) {
                  return Container(
                    width: 48,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: context.textTheme.headlineSmall,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (value) {
                        if (value.isNotEmpty &&
                            i < AppConstants.otpLength - 1) {
                          _focusNodes[i + 1].requestFocus();
                        }
                        if (value.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                        // Auto-submit quand complet
                        if (_otpCode.length == AppConstants.otpLength) {
                          _verifyOtp();
                        }
                      },
                    ),
                  );
                }),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _verifyOtp,
                child: const Text('Vérifier'),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 24),

              TextButton(
                onPressed: _canResend ? _resendCode : null,
                child: Text(
                  _canResend
                      ? 'Renvoyer le code'
                      : 'Renvoyer dans ${_resendCountdown}s',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
