import '../sql_constants.dart';

class GrammarModel {
  GrammarGraphModel? graphModel;
  GrammarTokenModel? tokenModel;

  GrammarModel();

  //GrammarModel(GrammarGraphModel this.graphModel, GrammarTokenModel this.tokenModel);

  @override
  String toString() {
    return 'GrammarModel{graphModel: $graphModel, tokenModel: $tokenModel}';
  }
}

class GrammarGraphModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? startTokenIndex;
  int? endTokenIndex;
  int? verseId;
  String? verseHafs;
  String? verseUthmani;
  String? verseGrammar;
  String? image;

  GrammarGraphModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    startTokenIndex = nJSON[SQL_IO.COLUMN_startTokenIndex];
    endTokenIndex = nJSON[SQL_IO.COLUMN_endTokenIndex];
    verseId = nJSON[SQL_IO.COLUMN_verseId];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
    verseGrammar = nJSON[SQL_IO.COLUMN_verseGrammar];
    image = nJSON[SQL_IO.COLUMN_image];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_startTokenIndex: startTokenIndex,
        SQL_IO.COLUMN_endTokenIndex: endTokenIndex,
        SQL_IO.COLUMN_verseId: verseId,
        SQL_IO.COLUMN_verseHafs: verseHafs,
        SQL_IO.COLUMN_verseUthmani: verseUthmani,
        SQL_IO.COLUMN_verseGrammar: verseGrammar,
        SQL_IO.COLUMN_image: image,
      };

  @override
  String toString() {
    return 'GrammarGraphModel{'
        'pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', ayahIndex: $ayahIndex'
        ', startTokenIndex: $startTokenIndex'
        ', endTokenIndex: $endTokenIndex'
        ', verseId: $verseId'
        //', verseHafs: $verseHafs'
        //', verseUthmani: $verseUthmani'
        ', verseGrammar: $verseGrammar'
        ', image: $image'
        '}';
  }
}

class GrammarTokenModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? tokenIndex;
  int? verseId;
  String? verseHafs;
  String? verseUthmani;
  String? arabEng;
  String? translation;
  String? image;
  String? arGrammar;
  String? enGrammar;

  bool? isMp3Playing;

  GrammarTokenModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    tokenIndex = nJSON[SQL_IO.COLUMN_tokenIndex];
    verseId = nJSON[SQL_IO.COLUMN_verseId];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
    arabEng = nJSON[SQL_IO.COLUMN_arabEng];
    translation = nJSON[SQL_IO.COLUMN_translation];
    image = nJSON[SQL_IO.COLUMN_image];
    arGrammar = nJSON[SQL_IO.COLUMN_arGrammar];
    enGrammar = nJSON[SQL_IO.COLUMN_enGrammar];
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
        SQL_IO.COLUMN_image: image,
        SQL_IO.COLUMN_arGrammar: arGrammar,
        SQL_IO.COLUMN_enGrammar: enGrammar,
      };

  @override
  String toString() {
    return 'GrammarTokenModel{'
        'pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', ayahIndex: $ayahIndex'
        ', tokenIndex: $tokenIndex'
        ', verseId: $verseId'
        //', verseHafs: $verseHafs'
        //', verseUthmani: $verseUthmani'
        ', arabEng: $arabEng'
        ', translation: $translation'
        ', image: $image'
        ', arGrammar: $arGrammar'
        ', enGrammar: $enGrammar'
        ', isMp3Playing: $isMp3Playing'
        '}';
  }
}
