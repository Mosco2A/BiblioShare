/// Modèle paramètres utilisateur (synchronisé avec Supabase `user_settings`)
class UserSettingsModel {
  final String userId;

  // Notifications
  final bool notifPush;
  final bool notifEmail;
  final bool notifSms;
  final bool notifLoans;
  final bool notifReminders;
  final bool notifRecos;
  final bool notifSocial;
  final bool notifStreak;
  final bool notifWeeklySummary;
  final int reminderFrequencyDays;

  // Confidentialité
  final String defaultLibraryVisibility;
  final String defaultReviewVisibility;
  final String profileVisibility;
  final String findByPhone;
  final String findByEmail;

  // Bibliothèque
  final int defaultLoanDays;
  final int maxLoansPerFriend;
  final bool autoReminders;
  final String reminderTone;

  // App
  final String theme;
  final String libraryDisplay;
  final List<String> searchLanguages;

  const UserSettingsModel({
    required this.userId,
    this.notifPush = true,
    this.notifEmail = true,
    this.notifSms = false,
    this.notifLoans = true,
    this.notifReminders = true,
    this.notifRecos = true,
    this.notifSocial = true,
    this.notifStreak = true,
    this.notifWeeklySummary = true,
    this.reminderFrequencyDays = 3,
    this.defaultLibraryVisibility = 'friends',
    this.defaultReviewVisibility = 'friends',
    this.profileVisibility = 'public',
    this.findByPhone = 'everyone',
    this.findByEmail = 'everyone',
    this.defaultLoanDays = 30,
    this.maxLoansPerFriend = 3,
    this.autoReminders = true,
    this.reminderTone = 'friendly',
    this.theme = 'system',
    this.libraryDisplay = 'grid',
    this.searchLanguages = const ['fr', 'en'],
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      userId: json['user_id'] as String,
      notifPush: json['notif_push'] as bool? ?? true,
      notifEmail: json['notif_email'] as bool? ?? true,
      notifSms: json['notif_sms'] as bool? ?? false,
      notifLoans: json['notif_loans'] as bool? ?? true,
      notifReminders: json['notif_reminders'] as bool? ?? true,
      notifRecos: json['notif_recos'] as bool? ?? true,
      notifSocial: json['notif_social'] as bool? ?? true,
      notifStreak: json['notif_streak'] as bool? ?? true,
      notifWeeklySummary: json['notif_weekly_summary'] as bool? ?? true,
      reminderFrequencyDays: json['reminder_frequency_days'] as int? ?? 3,
      defaultLibraryVisibility:
          json['default_library_visibility'] as String? ?? 'friends',
      defaultReviewVisibility:
          json['default_review_visibility'] as String? ?? 'friends',
      profileVisibility: json['profile_visibility'] as String? ?? 'public',
      findByPhone: json['find_by_phone'] as String? ?? 'everyone',
      findByEmail: json['find_by_email'] as String? ?? 'everyone',
      defaultLoanDays: json['default_loan_days'] as int? ?? 30,
      maxLoansPerFriend: json['max_loans_per_friend'] as int? ?? 3,
      autoReminders: json['auto_reminders'] as bool? ?? true,
      reminderTone: json['reminder_tone'] as String? ?? 'friendly',
      theme: json['theme'] as String? ?? 'system',
      libraryDisplay: json['library_display'] as String? ?? 'grid',
      searchLanguages:
          (json['search_languages'] as List<dynamic>?)?.cast<String>() ??
              const ['fr', 'en'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'notif_push': notifPush,
      'notif_email': notifEmail,
      'notif_sms': notifSms,
      'notif_loans': notifLoans,
      'notif_reminders': notifReminders,
      'notif_recos': notifRecos,
      'notif_social': notifSocial,
      'notif_streak': notifStreak,
      'notif_weekly_summary': notifWeeklySummary,
      'reminder_frequency_days': reminderFrequencyDays,
      'default_library_visibility': defaultLibraryVisibility,
      'default_review_visibility': defaultReviewVisibility,
      'profile_visibility': profileVisibility,
      'find_by_phone': findByPhone,
      'find_by_email': findByEmail,
      'default_loan_days': defaultLoanDays,
      'max_loans_per_friend': maxLoansPerFriend,
      'auto_reminders': autoReminders,
      'reminder_tone': reminderTone,
      'theme': theme,
      'library_display': libraryDisplay,
      'search_languages': searchLanguages,
    };
  }

  UserSettingsModel copyWith({
    bool? notifPush,
    bool? notifEmail,
    bool? notifSms,
    bool? notifLoans,
    bool? notifReminders,
    bool? notifRecos,
    bool? notifSocial,
    bool? notifStreak,
    bool? notifWeeklySummary,
    int? reminderFrequencyDays,
    String? defaultLibraryVisibility,
    String? defaultReviewVisibility,
    String? profileVisibility,
    String? findByPhone,
    String? findByEmail,
    int? defaultLoanDays,
    int? maxLoansPerFriend,
    bool? autoReminders,
    String? reminderTone,
    String? theme,
    String? libraryDisplay,
    List<String>? searchLanguages,
  }) {
    return UserSettingsModel(
      userId: userId,
      notifPush: notifPush ?? this.notifPush,
      notifEmail: notifEmail ?? this.notifEmail,
      notifSms: notifSms ?? this.notifSms,
      notifLoans: notifLoans ?? this.notifLoans,
      notifReminders: notifReminders ?? this.notifReminders,
      notifRecos: notifRecos ?? this.notifRecos,
      notifSocial: notifSocial ?? this.notifSocial,
      notifStreak: notifStreak ?? this.notifStreak,
      notifWeeklySummary: notifWeeklySummary ?? this.notifWeeklySummary,
      reminderFrequencyDays:
          reminderFrequencyDays ?? this.reminderFrequencyDays,
      defaultLibraryVisibility:
          defaultLibraryVisibility ?? this.defaultLibraryVisibility,
      defaultReviewVisibility:
          defaultReviewVisibility ?? this.defaultReviewVisibility,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      findByPhone: findByPhone ?? this.findByPhone,
      findByEmail: findByEmail ?? this.findByEmail,
      defaultLoanDays: defaultLoanDays ?? this.defaultLoanDays,
      maxLoansPerFriend: maxLoansPerFriend ?? this.maxLoansPerFriend,
      autoReminders: autoReminders ?? this.autoReminders,
      reminderTone: reminderTone ?? this.reminderTone,
      theme: theme ?? this.theme,
      libraryDisplay: libraryDisplay ?? this.libraryDisplay,
      searchLanguages: searchLanguages ?? this.searchLanguages,
    );
  }
}
