import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod/riverpod.dart' show Ref; 
import '../../services/iraqi_localization_service.dart';

part 'locale_provider.g.dart';

const String _localePreferenceKey = 'app_locale';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    _loadSavedLocale();
    return const Locale('ar', 'IQ'); // Default to Arabic (Iraq)
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localePreferenceKey);

      if (savedLocale != null) {
        final locale = _parseLocale(savedLocale);
        state = locale;
        // Update Iraqi localization service
        IraqiLocalizationService.setLanguage(locale.languageCode);
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localePreferenceKey, '${locale.languageCode}_${locale.countryCode ?? ''}');
      state = locale;
      
      // Update Iraqi localization service
      IraqiLocalizationService.setLanguage(locale.languageCode);
      
      debugPrint('Locale changed to: ${locale.languageCode}_${locale.countryCode}');
    } catch (e) {
      debugPrint('Error saving locale preference: $e');
    }
  }

  void toggleLocale() {
    final newLocale = state.languageCode == 'ar'
        ? const Locale('en', 'US')
        : const Locale('ar', 'IQ');
    setLocale(newLocale);
  }
  
  void setArabic() => setLocale(const Locale('ar', 'IQ'));
  void setEnglish() => setLocale(const Locale('en', 'US'));
  void setKurdish() => setLocale(const Locale('ku', 'IQ'));

  Locale _parseLocale(String localeString) {
    final parts = localeString.split('_');
    final languageCode = parts[0];
    // countryCode is parsed but not used in current logic
    
    // Map to Iraqi-specific locales
    switch (languageCode) {
      case 'ar':
        return const Locale('ar', 'IQ');
      case 'ku':
        return const Locale('ku', 'IQ');
      case 'en':
      default:
        return const Locale('en', 'US');
    }
  }
}

// Helper provider for getting localized strings using Iraqi localization service
@riverpod
String iraqi(Ref ref, String key) {
  // Watch locale changes to trigger rebuilds
  ref.watch(localeNotifierProvider);
  return IraqiLocalizationService.translate(key);
}

// Provider for getting current text direction
@riverpod
TextDirection textDirection(Ref ref) {
  final locale = ref.watch(localeNotifierProvider);
  return locale.languageCode == 'ar' || locale.languageCode == 'ku' 
      ? TextDirection.rtl 
      : TextDirection.ltr;
}

// Provider for checking if current language is RTL
@riverpod
bool isRTL(Ref ref) {
  final locale = ref.watch(localeNotifierProvider);
  return locale.languageCode == 'ar' || locale.languageCode == 'ku';
}

// Provider for getting supported locales
@riverpod
List<Locale> supportedLocales(Ref ref) {
  return const [
    Locale('ar', 'IQ'), // Arabic (Iraq)
    Locale('ku', 'IQ'), // Kurdish (Iraq)
    Locale('en', 'US'), // English (US)
  ];
}

// Provider for getting language name in current locale
@riverpod
String languageName(Ref ref, String languageCode) {
  ref.watch(localeNotifierProvider); // Watch for locale changes
  
  switch (languageCode) {
    case 'ar':
      return IraqiLocalizationService.translate('arabic_language') != 'arabic_language' 
          ? IraqiLocalizationService.translate('arabic_language')
          : 'العربية';
    case 'ku':
      return IraqiLocalizationService.translate('kurdish_language') != 'kurdish_language'
          ? IraqiLocalizationService.translate('kurdish_language')
          : 'کوردی';
    case 'en':
      return IraqiLocalizationService.translate('english_language') != 'english_language'
          ? IraqiLocalizationService.translate('english_language')
          : 'English';
    default:
      return languageCode;
  }
}
