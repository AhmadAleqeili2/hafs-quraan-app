import '../sql_constants.dart';

class TajweedModel {
  int? tokenId;
  int? lineId;
  int? tokenInLineIndex;
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? tokenIndex;
  String? token;
  String? character;

  int? startIndexInLine;
  int? endIndexInLine;

  int? startIndexInToken;
  int? endIndexInToken;

  int? colorId;
  String? colorEnName;
  String? colorArName;
  String? colorHEX;

  int? verseType;
  String? verse;

  bool? isRelatedWithNextToken;
  bool? isRelatedWithPreviousToken;

  TajweedModel.fromJson(Map nJSON) {
    tokenId = nJSON[SQL_IO.COLUMN_id];
    lineId = nJSON[SQL_IO.COLUMN_lineId];
    tokenInLineIndex = nJSON[SQL_IO.COLUMN_tokenInLineIndex];
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    tokenIndex = nJSON[SQL_IO.COLUMN_tokenIndex];
    token = nJSON[SQL_IO.COLUMN_token];
    character = nJSON[SQL_IO.COLUMN_character];
    startIndexInLine = nJSON[SQL_IO.COLUMN_startIndex];
    endIndexInLine = nJSON[SQL_IO.COLUMN_endIndex];
    startIndexInToken = nJSON[SQL_IO.COLUMN_startIndexInToken];
    endIndexInToken = nJSON[SQL_IO.COLUMN_endIndexInToken];
    colorId = nJSON[SQL_IO.COLUMN_colorId];
    colorEnName = nJSON[SQL_IO.COLUMN_name];
    colorArName = nJSON[SQL_IO.COLUMN_name];
    colorHEX = nJSON[SQL_IO.COLUMN_color];
    verseType = nJSON[SQL_IO.COLUMN_type];
    verse = nJSON[SQL_IO.COLUMN_verse];
    isRelatedWithNextToken = nJSON[SQL_IO.COLUMN_isRelatedWithNextToken] == 0 ? false : true;
    isRelatedWithPreviousToken = nJSON[SQL_IO.COLUMN_isRelatedWithPreviousToken] == 0 ? false : true;
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_id: tokenId,
        SQL_IO.COLUMN_lineId: lineId,
        SQL_IO.COLUMN_tokenInLineIndex: tokenInLineIndex,
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_tokenIndex: tokenIndex,
        SQL_IO.COLUMN_token: token,
        SQL_IO.COLUMN_character: character,
        SQL_IO.COLUMN_startIndex: startIndexInLine,
        SQL_IO.COLUMN_endIndex: endIndexInLine,
        SQL_IO.COLUMN_startIndexInToken: startIndexInToken,
        SQL_IO.COLUMN_endIndexInToken: endIndexInToken,
        SQL_IO.COLUMN_colorId: colorId,
        SQL_IO.COLUMN_name: colorEnName,
        SQL_IO.COLUMN_name: colorArName,
        SQL_IO.COLUMN_color: colorHEX,
        SQL_IO.COLUMN_type: verseType,
        SQL_IO.COLUMN_verse: verse,
        SQL_IO.COLUMN_isRelatedWithNextToken: isRelatedWithNextToken,
        SQL_IO.COLUMN_isRelatedWithPreviousToken: isRelatedWithPreviousToken,
      };

  @override
  String toString() {
    return 'TajweedInfoModel{'
        //'tokenId: $tokenId'
        //', lineId: $lineId'
        //', tokenInLineIndex: $tokenInLineIndex'
        ', pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', ayahIndex: $ayahIndex'
        ', tokenIndex: $tokenIndex'
        ', token: $token'
        ', character: $character'
        //', startIndexInLine: $startIndexInLine'
        //', endIndexInLine: $endIndexInLine'
        ', startIndexInToken: $startIndexInToken'
        ', endIndexInToken: $endIndexInToken'
        ', colorId: $colorId'
        ', colorEnName: $colorEnName'
        //', colorArName: $colorArName'
        ', colorHEX: $colorHEX'
        //', verseType: $verseType'
        //', verse: $verse'
        //', isRelatedWithNextToken: $isRelatedWithNextToken'
        //', isRelatedWithPreviousToken: $isRelatedWithPreviousToken'
        '}';
  }
}
