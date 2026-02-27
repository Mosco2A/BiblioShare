/// Modèle utilisateur BiblioShare (synchronisé avec Supabase `users`)
class UserModel {
  final String id;
  final String displayName;
  final String username;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? bio;
  final String? location;
  final List<String> preferredGenres;
  final String? externalLink;
  final String locale;
  final String timezone;
  final List<String> authProviders;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.email,
    this.phone,
    this.photoUrl,
    this.bio,
    this.location,
    this.preferredGenres = const [],
    this.externalLink,
    this.locale = 'fr',
    this.timezone = 'Europe/Paris',
    this.authProviders = const [],
    this.onboardingCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'Utilisateur',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      preferredGenres: (json['preferred_genres'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      externalLink: json['external_link'] as String?,
      locale: json['locale'] as String? ?? 'fr',
      timezone: json['timezone'] as String? ?? 'Europe/Paris',
      authProviders:
          (json['auth_providers'] as List<dynamic>?)?.cast<String>() ?? [],
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'username': username,
      'email': email,
      'phone': phone,
      'photo_url': photoUrl,
      'bio': bio,
      'location': location,
      'preferred_genres': preferredGenres,
      'external_link': externalLink,
      'locale': locale,
      'timezone': timezone,
      'auth_providers': authProviders,
      'onboarding_completed': onboardingCompleted,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? photoUrl,
    String? bio,
    String? location,
    List<String>? preferredGenres,
    String? externalLink,
    String? locale,
    String? timezone,
    List<String>? authProviders,
    bool? onboardingCompleted,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      preferredGenres: preferredGenres ?? this.preferredGenres,
      externalLink: externalLink ?? this.externalLink,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      authProviders: authProviders ?? this.authProviders,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
