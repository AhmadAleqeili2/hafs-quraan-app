class LanguageUtil {
  static const Set<String> _rtlLanguagePrefixes = {'ar', 'ur', 'fa'};
  static const Set<String> _supportedTranslateLanguages = {
    'ar',
    'en',
    'fr',
    'ur',
    'tr',
    'id',
    'ms',
    'fa',
    'bn',
  };

  static bool isRTLLocat(String languageCode) {
    final code = getActualLocal(languageCode);
    return _rtlLanguagePrefixes.any((prefix) => code.startsWith(prefix));
  }

  static String getActualLocal(String languageCode) {
    if (languageCode.isEmpty) {
      return 'en';
    }
    final normalised = languageCode.replaceAll('_', '-').toLowerCase();
    final segments = normalised.split('-');
    return segments.first;
  }

  static bool isSupportedTranslateLanguageCode(String languageCode) {
    final code = getActualLocal(languageCode);
    return _supportedTranslateLanguages.any((prefix) => code.startsWith(prefix));
  }
}
