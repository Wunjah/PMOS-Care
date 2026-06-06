import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported Languages Enum
enum AppLanguage { en, fr }

/// Localized translations map for PMOS Care (Cameroon Context)
final Map<AppLanguage, Map<String, String>> _localizedValues = {
  AppLanguage.en: {
    'app_name': 'PMOS Care',
    'login_title': 'PMOS Care Login',
    'phone_hint': 'Phone Number (E.164)',
    'send_otp': 'Send Verification Code',
    'otp_title': 'Verify SMS Code',
    'verify': 'Verify and Enter',
    'nav_home': 'Home',
    'nav_calendar': 'Calendar',
    'nav_diet': 'Diet & GI',
    'nav_coach': 'AI Coach',
    'nav_reports': 'Medical',
    'offline_banner': 'Offline Mode - Data will sync when online',
    'ai_coach_offline': 'AI Coach requires internet connection to converse.',
    'swap_suggestion': 'Replace with plantain fufu or double the vegetable ratio to manage glycemic load.',
  },
  AppLanguage.fr: {
    'app_name': 'PMOS Care',
    'login_title': 'Connexion PMOS Care',
    'phone_hint': 'Numéro de téléphone (E.164)',
    'send_otp': 'Envoyer le code de vérification',
    'otp_title': 'Vérifier le code SMS',
    'verify': 'Vérifier et Entrer',
    'nav_home': 'Accueil',
    'nav_calendar': 'Calendrier',
    'nav_diet': 'Régime & IG',
    'nav_coach': 'Coach IA',
    'nav_reports': 'Médical',
    'offline_banner': 'Mode hors ligne - Les données seront synchronisées en ligne',
    'ai_coach_offline': 'Le coach IA nécessite une connexion Internet pour converser.',
    'swap_suggestion': 'Remplacer par du fufu de banane ou doubler le ratio de légumes pour gérer la charge glycémique.',
  },
};

/// Language controller provider using Riverpod
class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.en);

  void setLanguage(AppLanguage language) {
    state = language;
  }

  void toggleLanguage() {
    state = state == AppLanguage.en ? AppLanguage.fr : AppLanguage.en;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

/// Extension on BuildContext to translate strings easily in UI widgets
extension LocalizationExtension on BuildContext {
  String translate(String key) {
    final container = ProviderScope.containerOf(this, listen: false);
    final currentLanguage = container.read(languageProvider);
    return _localizedValues[currentLanguage]?[key] ?? key;
  }
}
