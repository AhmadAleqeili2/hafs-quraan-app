import '../../sql_constants.dart';

class SearchModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? verseId;
  int? tokensCount;
  String? surahDisplayName;
  String? verseHafs;
  String? verseUthmani;

  String? verseDynamicType;
  String? verseDeep;
  String? verseTasmee;
  String? verseGoogle;
  String? verseCleanup;
  String? searchText;
  String? part1;
  String? part2;
  String? part3;

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

  Future<void> toSplit() async {
    part1 = '';
    part2 = '';
    part3 = '';

    if (verseCleanup == null || searchText == null) return;
    String mainString = verseCleanup!.trim();
    String searchString = searchText!.trim();

    int index = mainString.indexOf(searchString);
    if (index != -1) {
      part1 = mainString.substring(0, index).trim();
      part2 = mainString.substring(index, index + searchString.length).trim();
      part3 = mainString.substring(index + searchString.length).trim();
    } else {
      // print("Search string not found in the main string.");
    }

    List<String> verseCleanupTokens = verseCleanup!.trim() == '' ? <String>[] : verseCleanup!.trim().split(' ');
    List<String> verseHafsTokens = verseHafs!.trim() == '' ? <String>[] : verseHafs!.trim().split(' ');
    if (verseHafsTokens.isNotEmpty) {
      verseHafsTokens.removeAt(verseHafsTokens.length - 1); // TODO remove verse icon
    }
    List<String> verseUthmaniTokens = verseUthmani!.trim() == '' ? <String>[] : verseUthmani!.trim().split(' ');
    List<String> part1Tokens = part1!.trim() == '' ? <String>[] : part1!.trim().split(' ');
    List<String> part2Tokens = part2!.trim() == '' ? <String>[] : part2!.trim().split(' ');
    List<String> part3Tokens = part3!.trim() == '' ? <String>[] : part3!.trim().split(' ');
    // print("-------");
    // print("verseCleanup :: $verseCleanup");
    // print("verseCleanupTokens :: ${verseCleanupTokens.length}");
    // print("verseHafsTokens :: ${verseHafsTokens.length}");
    // print("verseUthmaniTokens :: ${verseUthmaniTokens.length}");
    // print("part1Tokens :: ${part1Tokens.length}");
    // print("part2Tokens :: ${part2Tokens.length}");
    // print("part3Tokens :: ${part3Tokens.length}");
    // print("Part 1: $part1");
    // print("Part 2: $part2");
    // print("Part 3: $part3");

    if (verseHafsTokens.length != verseCleanupTokens.length || verseUthmaniTokens.length != verseCleanupTokens.length) {
      // TODO Error data
      part1 = '';
      part2 = verseHafs!;
      part3 = '';
      // print('verseCleanup $verseCleanup');
      // print('verseHafs $verseHafs');
      // print('verseUthmani $verseUthmani');
      return;
    }

    int cIndex = 0;
    String tmpPart1 = '';
    String tmpPart2 = '';
    String tmpPart3 = '';

    if (part1Tokens.isNotEmpty) {
      // print(' part1Tokens.isNotEmpty');
      for (int nIndex = 0; nIndex < part1Tokens.length; nIndex++) {
        String xToken = part1Tokens[nIndex].trim();
        // print(' ??? $nIndex $xToken');
        if (cIndex < verseCleanupTokens.length && xToken == verseCleanupTokens[cIndex].trim()) {
          // print('xToken $xToken == ${verseCleanupTokens[cIndex].trim()}');
          tmpPart1 += ' ${verseHafsTokens[cIndex].trim()}';
          // tmpPart1 += ' ${verseUthmaniTokens[cIndex].trim()}';
          cIndex++;
        } else {
          // print('xToken $xToken != ${verseCleanupTokens[cIndex].trim()}');
        }
      }
    }
    // print(' ***');

    if (part2Tokens.isNotEmpty) {
      // print(' part2Tokens.isNotEmpty');
      for (int nIndex = 0; nIndex < part2Tokens.length; nIndex++) {
        String xToken = part2Tokens[nIndex].trim();
        // print(' ??? $nIndex $xToken');
        if (cIndex < verseCleanupTokens.length && verseCleanupTokens[cIndex].trim().contains(xToken)) {
          // print('xToken $xToken == ${verseCleanupTokens[cIndex].trim()}');
          tmpPart2 += ' ${verseHafsTokens[cIndex].trim()}';
          // tmpPart2 += ' ${verseUthmaniTokens[cIndex].trim()}';
          // if (verseCleanupTokens[cIndex].trim() != (xToken) && part3Tokens.isNotEmpty) {
          //   print('part3Tokens.removeAt(0);');
          //   part3Tokens.removeAt(0);
          // }
          cIndex++;
        } else {
          // print('xToken $xToken != ${verseCleanupTokens[cIndex].trim()}');
          tmpPart2 += ' ${verseHafsTokens[cIndex].trim()}';
          // tmpPart2 += ' ${verseUthmaniTokens[cIndex].trim()}';
          // if (verseCleanupTokens[cIndex].trim() != (xToken) && part3Tokens.isNotEmpty) {
          //   print('part3Tokens.removeAt(0);');
          //   part3Tokens.removeAt(0);
          // }
          cIndex++;
        }
      }
    }
    // print(' ***');

    if (part3Tokens.isNotEmpty) {
      //print(' part3Tokens.isNotEmpty');
      for (int nIndex = 0; nIndex < part3Tokens.length; nIndex++) {
        String xToken = part3Tokens[nIndex].trim();
        // print(' ??? $nIndex $xToken');
        if (cIndex < verseCleanupTokens.length && xToken == verseCleanupTokens[cIndex].trim()) {
          // print('xToken $xToken == ${verseCleanupTokens[cIndex].trim()}');
          tmpPart3 += ' ${verseHafsTokens[cIndex].trim()}';
          // tmpPart3 += ' ${verseUthmaniTokens[cIndex].trim()}';
          cIndex++;
        } else {
          // print('xToken $xToken != ${verseCleanupTokens[cIndex].trim()}');
        }
      }
    }

    // TODO Short
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

  SearchModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    verseId = nJSON[SQL_IO.COLUMN_verseId];
    tokensCount = nJSON[SQL_IO.COLUMN_tokensCount];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
    surahDisplayName = nJSON[SQL_IO.COLUMN_displayName];
    verseDeep = nJSON[SQL_IO.COLUMN_verseDeep];
    verseTasmee = nJSON[SQL_IO.COLUMN_verseTasmee];
    verseGoogle = nJSON[SQL_IO.COLUMN_verseGoogle];
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
        SQL_IO.COLUMN_verseDeep: verseDeep,
        SQL_IO.COLUMN_verseTasmee: verseTasmee,
        SQL_IO.COLUMN_verseGoogle: verseGoogle,
      };

  @override
  String toString() {
    return 'SearchModel{'
        'pageIndex: $pageIndex,'
        ' surahIndex: $surahIndex,'
        ' ayahIndex: $ayahIndex,'
        ' verseId: $verseId,'
        ' tokensCount: $tokensCount,'
        ' surahDisplayName: $surahDisplayName,'
        //' verseHafs: $verseHafs,'
        //' verseUthmani: $verseUthmani,'
        //' verseDynamicType: $verseDynamicType,'
        ' verseCleanup: $verseCleanup,'
        ' part1: $part1,'
        ' part2: $part2,'
        ' part3: $part3,'
        '}';
  }
}
