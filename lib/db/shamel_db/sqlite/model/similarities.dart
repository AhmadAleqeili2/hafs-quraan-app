import '../sql_constants.dart';

class SimilarityModel {
  int? tokensId;
  int? tokensLength;
  int? count;
  String? tokensArabic;
  String? tokensUthmani;
  String? tokensHafs;

  SimilarityModel.fromJson(Map nJSON) {
    tokensId = nJSON[SQL_IO.COLUMN_tokensId];
    tokensLength = nJSON[SQL_IO.COLUMN_tokensLength];
    count = nJSON[SQL_IO.COLUMN_count];
    tokensArabic = nJSON[SQL_IO.COLUMN_tokensArabic];
    tokensUthmani = nJSON[SQL_IO.COLUMN_tokensUthmani];
    tokensHafs = nJSON[SQL_IO.COLUMN_tokensHafs];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_tokensId: tokensId,
        SQL_IO.COLUMN_tokensLength: tokensLength,
        SQL_IO.COLUMN_count: count,
        SQL_IO.COLUMN_tokensArabic: tokensArabic,
        SQL_IO.COLUMN_tokensUthmani: tokensUthmani,
        SQL_IO.COLUMN_tokensHafs: tokensHafs,
      };

  @override
  String toString() {
    return 'SimilarityModel{'
        'tokensId: $tokensId, '
        'tokensLength: $tokensLength, '
        'count: $count, '
        'tokensArabic: $tokensArabic, '
        'tokensUthmani: $tokensUthmani, '
        'tokensHafs: $tokensHafs'
        '}';
  }
}

class SimilarityInfoModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;

  int? verseId;
  int? tokensId;
  int? tokenStartIndex;
  int? tokenEndIndex;
  int? tokensLength;
  int? count;

  String? tokensArabic;
  String? tokensUthmani;
  String? tokensHafs;

  String? verseHafs;
  String? verseUthmani;
  String? displayName;
  int? verseTokensCount;

  String? part1;
  String? part2;
  String? part3;

  static String getTokenHafs(String verseHafs, int tokenFromIndex, int tokenToIndex) {
    tokenFromIndex -= 1;
    tokenToIndex -= 1;
    if (verseHafs == null) return verseHafs;
    verseHafs = verseHafs.trim();
    List<String> tokens = verseHafs.split(' ');
    if (tokens.isNotEmpty /*&& tokens.length == verseTokensCount!*/) {
      tokens.removeAt(tokens.length - 1); // TODO remove verse icon
    }
    String tokensHafs = '';
    for (int cIndex = tokenFromIndex; cIndex <= tokenToIndex; cIndex++) {
      tokensHafs += '${tokens[cIndex]} ';
    }
    return tokensHafs.trim();
  }

  Future<void> toSplit() async {
    print("-------");
    print("verseUthmani : $verseUthmani");
    print("tokenStartIndex : $tokenStartIndex");
    print("tokenEndIndex : $tokenEndIndex");
    print("verseTokensCount : $verseTokensCount");

    String tmpPart1 = (tokenStartIndex! > 1) ? getTokenHafs(verseHafs!, 1, tokenStartIndex! - 1) : '';
    String tmpPart2 = getTokenHafs(verseHafs!, tokenStartIndex!, tokenEndIndex!);
    String tmpPart3 =
        (verseTokensCount! > tokenEndIndex!) ? getTokenHafs(verseHafs!, tokenEndIndex! + 1, verseTokensCount!) : '';

    print("tmpPart1 1: $tmpPart1");
    print("tmpPart2 2: $tmpPart2");
    print("tmpPart3 3: $tmpPart3");
    print("-------");

    // // TODO Short
    if (tmpPart1!.trim() != '') {
      List<String> tmpPart1Tokens = tmpPart1!.trim() == '' ? <String>[] : tmpPart1!.trim().split(' ');
      if (tmpPart1Tokens.length > 3) {
        tmpPart1 =
            '... ${tmpPart1Tokens[tmpPart1Tokens!.length - 3].trim()} ${tmpPart1Tokens[tmpPart1Tokens!.length - 2].trim()} ${tmpPart1Tokens[tmpPart1Tokens!.length - 1].trim()}';
      }
    }

    if (tmpPart3!.trim() != '') {
      List<String> tmpPart3Tokens = tmpPart3!.trim() == '' ? <String>[] : tmpPart3!.trim().split(' ');
      if (tmpPart3Tokens.length > 5) {
        tmpPart3 =
            '${tmpPart3Tokens[0].trim()} ${tmpPart3Tokens[1].trim()} ${tmpPart3Tokens[2].trim()} ${tmpPart3Tokens[3].trim()} ${tmpPart3Tokens[4].trim()} ...';
      }
    }

    part1 = '${tmpPart1.trim()} ';
    part2 = tmpPart2.trim();
    part3 = ' ${tmpPart3.trim()}';
    // print("Part 1: $part1");
    // print("Part 2: $part2");
    // print("Part 3: $part3");
    // print("-------");

    return;
  }

  SimilarityInfoModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    verseId = nJSON[SQL_IO.COLUMN_verseId];
    tokensId = nJSON[SQL_IO.COLUMN_tokensId];
    tokenStartIndex = nJSON[SQL_IO.COLUMN_tokenStartIndex];
    tokenEndIndex = nJSON[SQL_IO.COLUMN_tokenEndIndex];
    tokensLength = nJSON[SQL_IO.COLUMN_tokensLength];
    count = nJSON[SQL_IO.COLUMN_count];
    tokensArabic = nJSON[SQL_IO.COLUMN_tokensArabic];
    tokensUthmani = nJSON[SQL_IO.COLUMN_tokensUthmani];
    tokensHafs = nJSON[SQL_IO.COLUMN_tokensHafs];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
    verseTokensCount = nJSON[SQL_IO.COLUMN_tokensCount];
    displayName = nJSON[SQL_IO.COLUMN_displayName];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_verseId: verseId,
        SQL_IO.COLUMN_tokensId: tokensId,
        SQL_IO.COLUMN_tokenStartIndex: tokenStartIndex,
        SQL_IO.COLUMN_tokenEndIndex: tokenEndIndex,
        SQL_IO.COLUMN_tokensLength: tokensLength,
        SQL_IO.COLUMN_count: count,
        SQL_IO.COLUMN_tokensArabic: tokensArabic,
        SQL_IO.COLUMN_tokensUthmani: tokensUthmani,
        SQL_IO.COLUMN_tokensHafs: tokensHafs,
        SQL_IO.COLUMN_verseHafs: verseHafs,
        SQL_IO.COLUMN_verseUthmani: verseUthmani,
        SQL_IO.COLUMN_tokensCount: verseTokensCount,
        SQL_IO.COLUMN_displayName: displayName,
      };

  @override
  String toString() {
    return 'SimilarityInfoModel{'
        'pageIndex: $pageIndex, '
        'surahIndex: $surahIndex, '
        'ayahIndex: $ayahIndex, '
        'verseId: $verseId, '
        'tokensId: $tokensId, '
        'tokenStartIndex: $tokenStartIndex, '
        'tokenEndIndex: $tokenEndIndex, '
        'tokensLength: $tokensLength, '
        'count: $count, '
        'tokensArabic: $tokensArabic, '
        'tokensUthmani: $tokensUthmani, '
        'tokensHafs: $tokensHafs, '
        'verseHafs: $verseHafs, '
        'verseUthmani: $verseUthmani, '
        'verseTokensCount: $verseTokensCount, '
        'displayName: $displayName'
        '}';
  }
}

class SimilarityColorModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? verseTokensCount;
  String? tokensArabic;
  int? tokenStartIndex;
  int? tokenEndIndex;

  SimilarityColorModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    verseTokensCount = nJSON[SQL_IO.COLUMN_tokensCount];
    tokenStartIndex = nJSON[SQL_IO.COLUMN_tokenStartIndex];
    tokenEndIndex = nJSON[SQL_IO.COLUMN_tokenEndIndex];
    tokensArabic = nJSON[SQL_IO.COLUMN_tokensArabic];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_tokensCount: verseTokensCount,
        SQL_IO.COLUMN_tokenStartIndex: tokenStartIndex,
        SQL_IO.COLUMN_tokenEndIndex: tokenEndIndex,
        SQL_IO.COLUMN_tokensArabic: tokensArabic,
      };

  @override
  String toString() {
    return 'SimilarityColorModel{'
        'pageIndex: $pageIndex, '
        'surahIndex: $surahIndex, '
        'ayahIndex: $ayahIndex, '
        'tokenStartIndex: $tokenStartIndex, '
        'tokenEndIndex: $tokenEndIndex, '
        'tokensArabic: $tokensArabic, '
        'verseTokensCount: $verseTokensCount, '
        '}';
  }
}
