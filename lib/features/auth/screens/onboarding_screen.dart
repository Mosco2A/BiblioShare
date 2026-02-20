import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedLocale = 'fr';

  final _pages = const [
    _OnboardingPageData(
      icon: Icons.menu_book_rounded,
      title: 'Bienvenue sur BiblioShare',
      subtitle: 'Ta bibliothèque. Tes amis. Tes livres.',
    ),
    _OnboardingPageData(
      icon: Icons.language,
      title: 'Choisis ta langue',
      subtitle: 'Tu pourras la changer dans les paramètres.',
      isLanguagePage: true,
    ),
    _OnboardingPageData(
      icon: Icons.camera_alt_outlined,
      title: 'Scanne ta première étagère',
      subtitle:
          'Prends en photo ton étagère et on s\'occupe du reste !',
    ),
    _OnboardingPageData(
      icon: Icons.people_outline,
      title: 'Invite tes amis lecteurs !',
      subtitle:
          'Partage ta bibliothèque, emprunte leurs livres, recommande tes coups de coeur.',
    ),
  ];

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      // Interstitial entre les écrans
      if (_currentPage == 1) {
        await AdService.showInterstitial();
        AdService.loadInterstitial();
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipToEnd() {
    _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skipToEnd,
                child: Text(
                  'Passer',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page);
                },
              ),
            ),

            // Dots indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          isActive ? AppColors.primary : AppColors.textHint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Action button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: ElevatedButton(
                onPressed: _nextPage,
                child: Text(
                  _currentPage == _pages.length - 1
                      ? 'Commencer !'
                      : 'Suivant',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            page.icon,
            size: 96,
            color: AppColors.primary,
          ).animate().fadeIn(duration: 500.ms).scale(delay: 200.ms),

          const SizedBox(height: 32),

          Text(
            page.title,
            style: context.textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 16),

          Text(
            page.subtitle,
            style: context.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms),

          if (page.isLanguagePage) ...[
            const SizedBox(height: 32),
            _buildLanguageSelector(),
          ],

          if (page.icon == Icons.camera_alt_outlined) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Module 3 — Scanner
                context.showSnackBar('Le scanner sera disponible bientôt !');
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scanner maintenant'),
            ),
          ],

          if (page.icon == Icons.people_outline) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Module 6 — Invitations
                context.showSnackBar('Les invitations seront disponibles bientôt !');
              },
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Inviter par SMS'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Module 6 — Invitations
                context.showSnackBar('Les invitations seront disponibles bientôt !');
              },
              icon: const Icon(Icons.email_outlined),
              label: const Text('Inviter par email'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    const languages = [
      ('fr', 'Francais', '\u{1F1EB}\u{1F1F7}'),
      ('en', 'English', '\u{1F1EC}\u{1F1E7}'),
      ('es', 'Espanol', '\u{1F1EA}\u{1F1F8}'),
      ('de', 'Deutsch', '\u{1F1E9}\u{1F1EA}'),
      ('it', 'Italiano', '\u{1F1EE}\u{1F1F9}'),
      ('pt', 'Portugues', '\u{1F1F5}\u{1F1F9}'),
    ];

    return Column(
      children: languages.map((lang) {
        final isSelected = _selectedLocale == lang.$1;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            tileColor: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : null,
            leading: Text(lang.$3, style: const TextStyle(fontSize: 24)),
            title: Text(lang.$2),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () => setState(() => _selectedLocale = lang.$1),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 600.ms);
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLanguagePage;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLanguagePage = false,
  });
}
