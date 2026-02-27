import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/scan_provider.dart';

/// Écran principal de scan — choix caméra/galerie, puis analyse
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _hasNavigatedToResults = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scan = context.read<ScanProvider>();
      // Reset if entering from a previous completed/errored scan
      if (scan.state == ScanState.results || scan.state == ScanState.error) {
        scan.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = context.watch<ScanProvider>();

    // Auto-navigate to results when ready (once only)
    if (scanProvider.state == ScanState.results && !_hasNavigatedToResults) {
      _hasNavigatedToResults = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push('/scan/results');
      });
    }

    // Reset navigation flag when scan resets to idle
    if (scanProvider.state == ScanState.idle) {
      _hasNavigatedToResults = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner une étagère'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: switch (scanProvider.state) {
        ScanState.idle => _IdleView(
            onPickImage: (bytes) => scanProvider.analyzePhoto(bytes),
          ),
        ScanState.scanning => const _ScanningView(),
        ScanState.enriching => const _EnrichingView(),
        ScanState.results => const Center(child: CircularProgressIndicator()),
        ScanState.error => _ErrorView(
            message: scanProvider.errorMessage ?? 'Erreur inconnue',
            onRetry: () => scanProvider.reset(),
          ),
      },
    );
  }
}

/// Vue initiale — choisir une source d'image
class _IdleView extends StatelessWidget {
  final void Function(Uint8List bytes) onPickImage;

  const _IdleView({required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_camera_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'Photographie ton étagère',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Prends en photo une étagère de livres et BiblioShare identifiera chaque livre automatiquement.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Guide de cadrage
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conseils pour un bon scan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _tip(context, Icons.light_mode, 'Bonne luminosité, pas de reflets'),
                  _tip(context, Icons.crop_free, 'Cadre bien toute l\'étagère'),
                  _tip(context, Icons.center_focus_strong, 'Image nette, pas floue'),
                  _tip(context, Icons.straighten, 'De face, pas en angle'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Boutons d'action
            ElevatedButton.icon(
              onPressed: () => _pickFromCamera(context),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Prendre une photo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickFromGallery(context),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choisir depuis la galerie'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tip(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      onPickImage(bytes);
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      onPickImage(bytes);
    }
  }
}

/// Vue pendant l'analyse par Claude Vision
class _ScanningView extends StatelessWidget {
  const _ScanningView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analyse de l\'étagère en cours...',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'L\'IA identifie chaque livre sur ta photo. Cela peut prendre quelques secondes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
    );
  }
}

/// Vue pendant l'enrichissement Google Books
class _EnrichingView extends StatelessWidget {
  const _EnrichingView();

  @override
  Widget build(BuildContext context) {
    final scanProvider = context.watch<ScanProvider>();
    final total = scanProvider.detectedBooks.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$total livres détectés !',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Recherche des couvertures et métadonnées...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Vue erreur
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text(
              'Oups, quelque chose a échoué',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
