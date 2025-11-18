import 'dart:ui';

import '../../../utils/diff_util.dart';
import '../../../utils/cache_helper.dart';
import '../../sql_constants.dart';

class TokenModel {
  int? pageIndex;

  int? surahIndex;
  int? ayahIndex;
  int? tokenIndex;

  int? verseId;
  int? verseTokensCount;
  String? verseHafs;
  String? verseUthmani;
  String? verseGoogle;

  String? tokenHafs;
  String? tokenUthmani;
  String? tokenGoogle;

  bool isSelectedToken = false;
  bool isHiddenToken = false;
  bool isDiff = false;
  Color color = CacheHelper.isDarkTheme() ? DiffUtil.TokenWhite_Color : DiffUtil.TokenBlack_Color;
  String type = '';

  TokenModel();

  TokenModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    tokenIndex = nJSON[SQL_IO.COLUMN_tokenIndex];
    verseId = nJSON[SQL_IO.COLUMN_verseId];
    verseTokensCount = nJSON[SQL_IO.COLUMN_tokensCount];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
    verseGoogle = nJSON[SQL_IO.COLUMN_verseGoogle];
    tokenHafs = nJSON[SQL_IO.COLUMN_tokenHafs];
    tokenUthmani = nJSON[SQL_IO.COLUMN_tokenUthmani];
    tokenGoogle = nJSON[SQL_IO.COLUMN_tokenGoogle];

    // TODO Log
    //isSelectedToken = nJSON[SQL_IO.COLUMN_isSelectedToken] ?? false;
    //isHiddenToken = nJSON[SQL_IO.COLUMN_isHiddenToken] ?? false;
    //isDiff = nJSON[SQL_IO.COLUMN_isDiff] ?? false;
    type = nJSON[SQL_IO.COLUMN_type] ?? '';
    if (type == DiffUtil.TokenError_Type) {
      color = DiffUtil.TokenRed_Color;
      //color = CacheHelper.isDarkTheme() ? DiffUtil.TokenWhite_Color : DiffUtil.TokenBlack_Color;
    } else if (type == DiffUtil.TokenCorrect_Type) {
      color = DiffUtil.TokenGreen_Color;
    } else if (type == DiffUtil.TokenContian_Type) {
      color = DiffUtil.TokenOrange_Color;
    } else if (type == DiffUtil.TokenHelp_Type) {
      color = CacheHelper.isDarkTheme() ? DiffUtil.TokenWhite_Color : DiffUtil.TokenBlack_Color;
    } else {
      color = CacheHelper.isDarkTheme() ? DiffUtil.TokenWhite_Color : DiffUtil.TokenBlack_Color;
    }
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_tokenIndex: tokenIndex,
        SQL_IO.COLUMN_verseId: verseId,
        SQL_IO.COLUMN_tokensCount: verseTokensCount,
        SQL_IO.COLUMN_verseHafs: verseHafs,
        SQL_IO.COLUMN_verseUthmani: verseUthmani,
        SQL_IO.COLUMN_verseGoogle: verseGoogle,
        SQL_IO.COLUMN_tokenHafs: tokenHafs,
        SQL_IO.COLUMN_tokenUthmani: tokenUthmani,
        SQL_IO.COLUMN_tokenGoogle: tokenGoogle,
        SQL_IO.COLUMN_type: type,
      };

  @override
  String toString() {
    return 'TokenModel{'
        'pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', ayahIndex: $ayahIndex'
        ', tokenIndex: $tokenIndex'
        //', verseId: $verseId'
        //', verseTokensCount: $verseTokensCount'
        //', verseHafs: $verseHafs'
        //', verseUthmani: $verseUthmani'
        //', verseGoogle: $verseGoogle'
        //', tokenHafs: $tokenHafs'
        //', tokenUthmani: $tokenUthmani'
        //', tokenGoogle: $tokenGoogle'
        //', isSelectedToken: $isSelectedToken'
        //', isHiddenToken: $isHiddenToken'
        ', isDiff: $isDiff'
        //', type: type'
        //', color: $color'
        '}';
  }
}
