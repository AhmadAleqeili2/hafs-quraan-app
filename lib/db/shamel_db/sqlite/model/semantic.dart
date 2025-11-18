import '../sql_constants.dart';

class SemanticModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? verseId;
  int? tokenFromIndex;
  int? tokenToIndex;
  String? tokens;
  String? content;
  String? verseHafs;
  String? verseUthmani;

  SemanticModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    verseId = nJSON[SQL_IO.COLUMN_verseId];
    tokenFromIndex = nJSON[SQL_IO.COLUMN_tokenFromIndex];
    tokenToIndex = nJSON[SQL_IO.COLUMN_tokenToIndex];
    tokens = nJSON[SQL_IO.COLUMN_tokens];
    content = nJSON[SQL_IO.COLUMN_content];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_verseId: verseId,
        SQL_IO.COLUMN_tokenFromIndex: tokenFromIndex,
        SQL_IO.COLUMN_tokenToIndex: tokenToIndex,
        SQL_IO.COLUMN_tokens: tokens,
        SQL_IO.COLUMN_content: content,
        SQL_IO.COLUMN_verseHafs: verseHafs,
        SQL_IO.COLUMN_verseUthmani: verseUthmani,
      };

  @override
  String toString() {
    return 'SemanticModel{'
        ' pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', ayahIndex: $ayahIndex'
        ', verseId: $verseId'
        ', tokenFromIndex: $tokenFromIndex'
        ', tokenToIndex: $tokenToIndex'
        ', tokens: $tokens'
        ', content: $content'
        ', verseHafs: $verseHafs'
        ', verseUthmani: $verseUthmani'
        '}';
  }
}
