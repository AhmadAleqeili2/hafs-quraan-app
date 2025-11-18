import '../../sql_constants.dart';

class VerseModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? juzaaIndex;
  int? verseId;
  int? tokensCount;
  String? surahDisplayName;
  String? verseHafs;
  String? verseUthmani;
  String? verseGoogle;
  bool? isFirstVerse;
  bool? isLastVerse;
  bool? isFirstSurah;
  String? concatenatedSurahIndex;

  // TODO Memorize
  int colorVerse = 0;
  bool isHintFirstToken = false;
  bool isSelectedVerse = false;
  bool isHiddenVerse = false;
  List<int> hiddenTokensIndex = <int>[];
  List<int> coloredTokensIndex = <int>[];

  // TODO for quran text
  String? translateText;
  String translateCode = '';
  String? tafseerText;
  String tafseerCode = '';

  VerseModel();

  VerseModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    juzaaIndex = nJSON[SQL_IO.COLUMN_juzaaIndex];
    verseId = nJSON[SQL_IO.COLUMN_verseId];
    tokensCount = nJSON[SQL_IO.COLUMN_tokensCount];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
    verseGoogle = nJSON[SQL_IO.COLUMN_verseGoogle];
    isFirstVerse = nJSON[SQL_IO.COLUMN_isFirstVerse] == 1 ? true : false;
    isLastVerse = nJSON[SQL_IO.COLUMN_isLastVerse] == 1 ? true : false;
    isFirstSurah = nJSON[SQL_IO.COLUMN_isFirstSurah] == 1 ? true : false;
    concatenatedSurahIndex = nJSON[SQL_IO.COLUMN_concatenatedSurahIndex];
    surahDisplayName = nJSON[SQL_IO.COLUMN_displayName];
    translateText = nJSON[SQL_IO.COLUMN_translateText];
    tafseerText = nJSON[SQL_IO.COLUMN_tafsserText];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_juzaaIndex: juzaaIndex,
        SQL_IO.COLUMN_verseId: verseId,
        SQL_IO.COLUMN_tokensCount: tokensCount,
        SQL_IO.COLUMN_verseHafs: verseHafs,
        SQL_IO.COLUMN_verseUthmani: verseUthmani,
        SQL_IO.COLUMN_verseGoogle: verseGoogle,
        SQL_IO.COLUMN_isFirstVerse: isFirstVerse != null && isFirstVerse! ? 1 : 0,
        SQL_IO.COLUMN_isLastVerse: isLastVerse != null && isLastVerse! ? 1 : 0,
        SQL_IO.COLUMN_isFirstSurah: isFirstSurah != null && isFirstSurah! ? 1 : 0,
        SQL_IO.COLUMN_concatenatedSurahIndex: concatenatedSurahIndex,
        SQL_IO.COLUMN_displayName: surahDisplayName,
        SQL_IO.COLUMN_translateText: translateText,
        SQL_IO.COLUMN_tafsserText: tafseerText,
      };

  @override
  String toString() {
    return 'VerseModel{'
        'pageIndex: $pageIndex,'
        ' surahIndex: $surahIndex,'
        ' ayahIndex: $ayahIndex,'
        ' juzaaIndex: $juzaaIndex,'
        // ' concatenatedSurahIndex: $concatenatedSurahIndex,'
        ' verseId: $verseId,'
        ' tokensCount: $tokensCount,'
        ' surahDisplayName: $surahDisplayName,'
        ' isFirstVerse: $isFirstVerse,'
        ' isLastVerse: $isLastVerse,'
        ' isFirstSurah: $isFirstSurah,'
        //' verseHafs: $verseHafs,'
        //' verseUthmani: $verseUthmani,'
        // ' verseDynamicType: $verseDynamicType,'
        // ' translateText: translateText,'
        // ' tafseerText: tafseerText,'
        '}';
  }
}
