import 'arabic_text.dart';
import 'search_text.dart';

class ArabicSpecialToken {
  static Future<String> fromVerseGoogleToSurahName(String text) async {
    final normalised = ArabicText(text).toCharactersWithoutDiacritics();
    return SearchText(normalised).toCleanup();
  }
}
