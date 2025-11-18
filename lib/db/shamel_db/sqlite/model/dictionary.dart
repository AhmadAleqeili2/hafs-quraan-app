import '../sql_constants.dart';

class DictionaryModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? tokenIndex;
  int? verseId;
  String? verseHafs;
  String? verseUthmani;
  String? arabEng;
  String? translation;
  String? redWord;
  String? shortAyah;

  DictionaryModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    tokenIndex = nJSON[SQL_IO.COLUMN_tokenIndex];
    verseId = nJSON[SQL_IO.COLUMN_verseId];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
    arabEng = nJSON[SQL_IO.COLUMN_arabEng];
    translation = nJSON[SQL_IO.COLUMN_translation];
    redWord = nJSON[SQL_IO.COLUMN_redWord];
    shortAyah = nJSON[SQL_IO.COLUMN_shortAyah];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_tokenIndex: tokenIndex,
        SQL_IO.COLUMN_verseId: verseId,
        SQL_IO.COLUMN_verseHafs: verseHafs,
        SQL_IO.COLUMN_verseUthmani: verseUthmani,
        SQL_IO.COLUMN_arabEng: arabEng,
        SQL_IO.COLUMN_translation: translation,
        SQL_IO.COLUMN_redWord: redWord,
        SQL_IO.COLUMN_shortAyah: shortAyah,
      };

  @override
  String toString() {
    return 'DictionaryModel{'
        'pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', ayahIndex: $ayahIndex'
        ', tokenIndex: $tokenIndex'
        ', verseId: $verseId'
        ', verseHafs: $verseHafs'
        ', verseUthmani: $verseUthmani'
        ', arabEng: $arabEng'
        ', translation: $translation'
        ', redWord: $redWord'
        ', shortAyah: $shortAyah'
        '}';
  }
}
