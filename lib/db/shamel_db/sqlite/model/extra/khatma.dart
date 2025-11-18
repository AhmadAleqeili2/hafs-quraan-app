import '../../sql_constants.dart';

class KhatmaVerseModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? verseId;
  int? tokensCount;
  String? surahDisplayName;
  String? verseHafs;
  String? verseUthmani;
  int? juzaaIndex;
  int? hizbIndex;

  int colorVerse = 0;
  bool isSelectedVerse = false;
  bool isHiddenVerse = false;
  List<int> hiddenTokensIndex = <int>[];
  List<int> coloredTokensIndex = <int>[];

  KhatmaVerseModel();

  KhatmaVerseModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    verseId = nJSON[SQL_IO.COLUMN_verseId];
    tokensCount = nJSON[SQL_IO.COLUMN_tokensCount];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
    surahDisplayName = nJSON[SQL_IO.COLUMN_displayName];
    juzaaIndex = nJSON[SQL_IO.COLUMN_juzaaIndex];
    hizbIndex = nJSON[SQL_IO.COLUMN_hizb];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_verseId: verseId,
        SQL_IO.COLUMN_tokensCount: tokensCount,
        SQL_IO.COLUMN_verseHafs: verseHafs,
        SQL_IO.COLUMN_verseUthmani: verseUthmani,
        SQL_IO.COLUMN_displayName: surahDisplayName,
        SQL_IO.COLUMN_juzaaIndex: juzaaIndex,
        SQL_IO.COLUMN_hizb: hizbIndex,
      };

  String getShortVerseHafs() {
    if (null == verseHafs) return '';
    List<String> tokens = verseHafs!.trim().split(' ');
    if (tokens.isNotEmpty /*&& tokens.length == verseTokensCount!*/) {
      tokens.removeAt(tokens.length - 1); // TODO remove verse icon
    }
    int tokenFromIndex = 0;
    int tokenToIndex = tokens.length - 1;
    bool isLong = false;
    if (tokenToIndex > 12) {
      isLong = true;
      tokenToIndex = 12;
    }
    String tokensHafs = '';
    for (int cIndex = tokenFromIndex; cIndex <= tokenToIndex; cIndex++) {
      tokensHafs += '${tokens[cIndex]} ';
    }
    if (isLong) tokensHafs += ' ...';
    return tokensHafs.trim();
  }

  @override
  String toString() {
    return 'KhatmaVerseModel{'
        'pageIndex: $pageIndex,'
        ' surahIndex: $surahIndex,'
        ' ayahIndex: $ayahIndex,'
        ' verseId: $verseId,'
        ' tokensCount: $tokensCount,'
        ' surahDisplayName: $surahDisplayName,'
        //' verseHafs: $verseHafs,'
        //' verseUthmani: $verseUthmani,'
        //' verseDynamicType: $verseDynamicType,'
        '}';
  }
}
