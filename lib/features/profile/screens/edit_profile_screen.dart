import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _linkController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile ??
        context.read<AuthProvider>().userProfile;

    _nameController =
        TextEditingController(text: profile?.displayName ?? '');
    _usernameController =
        TextEditingController(text: profile?.username ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _locationController =
        TextEditingController(text: profile?.location ?? '');
    _linkController =
        TextEditingController(text: profile?.externalLink ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      await context.read<ProfileProvider>().updateProfile(userId, {
        'display_name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        'location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'external_link': _linkController.text.trim().isEmpty
            ? null
            : _linkController.text.trim(),
      });

      if (mounted) {
        context.showSnackBar('Profil mis à jour !');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erreur lors de la sauvegarde', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer',
                    style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        iconSize: 16,
                        icon: const Icon(Icons.camera_alt,
                            color: Colors.white),
                        onPressed: () {
                          // TODO: Pick image
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom d\'affichage',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requis' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email),
                helperText: 'Unique, visible par les autres',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requis';
                if (v.contains(' ')) return 'Pas d\'espaces';
                if (v.length < 3) return 'Minimum 3 caractères';
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: 'Bio',
                prefixIcon: const Icon(Icons.edit_note),
                counterText:
                    '${_bioController.text.length}/${AppConstants.maxBioLength}',
              ),
              maxLines: 3,
              maxLength: AppConstants.maxBioLength,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Localisation (optionnel)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Lien externe (optionnel)',
                prefixIcon: Icon(Icons.link),
                hintText: 'Goodreads, Babelio, blog...',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }
}
