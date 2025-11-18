import 'dart:ui';

import 'model/extra/verse.dart';
import 'shamel_sqlite.dart';

class SQL_IO {
  // TODO TABLEs
  static const String TABLE_INDEX_NAME_RASHED = 'index_rashed';
  static const String TABLE_INDEX_NAME_MADINAH = 'index_madinah';
  static const String TABLE_INDEX_NAME_TEXT = 'index_uthmanic_hafs';
  static const String TABLE_INDEX_NAME_NsTaliQ = 'index_nstaliq';

  static const int MAX_PAGE_INDEX_MADINAH = 604;
  static const int MIN_PAGE_INDEX_MADINAH = 1;

  static const int MAX_PAGE_INDEX_NsTaliQ = 611;
  static const int MIN_PAGE_INDEX_NsTaliQ = 2;

  // TODO COLUMNs
  static const String COLUMN_ = '';

  static const String COLUMN_version = 'version';
  static const String COLUMN_count = 'count';

  static const String COLUMN_pageIndex = 'pageIndex';
  static const String COLUMN_surahIndex = 'surahIndex';
  static const String COLUMN_ayahIndex = 'ayahIndex';
  static const String COLUMN_tokenIndex = 'tokenIndex';
  static const String COLUMN_verseId = 'verseId';

  static const String COLUMN_tokens = 'tokens';
  static const String COLUMN_content = 'content';

  static const String COLUMN_verseHafs = 'verseHafs';
  static const String COLUMN_verseUthmani = 'verseUthmani';
  static const String COLUMN_verseDeep = 'verseDeep';
  static const String COLUMN_verseTasmee = 'verseTasmee';
  static const String COLUMN_verseGoogle = 'verseGoogle';

  static const String COLUMN_isFirstVerse = 'isFirstVerse';
  static const String COLUMN_isLastVerse = 'isLastVerse';
  static const String COLUMN_isFirstSurah = 'isFirstSurah';
  static const String COLUMN_concatenatedSurahIndex = 'concatenatedSurahIndex';

  static const String COLUMN_tokenHafs = 'tokenHafs';
  static const String COLUMN_tokenUthmani = 'tokenUthmani';
  static const String COLUMN_tokenGoogle = 'tokenGoogle';

  static const String COLUMN_tafsserCode = 'tafsserCode';
  static const String COLUMN_tafsserText = 'tafsserText';

  static const String COLUMN_languageCode = 'languageCode';
  static const String COLUMN_translateText = 'translateText';

  static const String COLUMN_verseIdFrom = 'verseIdFrom';
  static const String COLUMN_verseIdTo = 'verseIdTo';
  static const String COLUMN_verseFromIndex = 'verseFromIndex';
  static const String COLUMN_verseToIndex = 'verseToIndex';
  static const String COLUMN_tokenFromIndex = 'tokenFromIndex';
  static const String COLUMN_tokenToIndex = 'tokenToIndex';

  static const String COLUMN_color = 'color';
  static const String COLUMN_detail = 'detail';
  static const String COLUMN_displayName = 'displayName';
  static const String COLUMN_reason = 'reason';
  static const String COLUMN_shortAyah = 'shortAyah';

  static const String COLUMN_arabEng = 'arabEng';
  static const String COLUMN_translation = 'translation';
  static const String COLUMN_redWord = 'RedWord';
  static const String COLUMN_image = 'image';
  static const String COLUMN_location = 'location';
  static const String COLUMN_arGrammar = 'arGrammar';
  static const String COLUMN_enGrammar = 'enGrammar';

  static const String COLUMN_verseGrammar = 'verseGrammar';
  static const String COLUMN_startTokenIndex = 'startTokenIndex';
  static const String COLUMN_endTokenIndex = 'endTokenIndex';

  static const String COLUMN_ayahFromIndex = 'ayahFromIndex';
  static const String COLUMN_ayahToIndex = 'ayahToIndex';
  static const String COLUMN_juzaaIndex = 'juzaaIndex';
  static const String COLUMN_hizb = 'hizb';
  static const String COLUMN_hizbDetails = 'hizbDetails';
  static const String COLUMN_type = 'type';
  static const String COLUMN_name = 'name';

  static const String COLUMN_id = 'id';
  static const String COLUMN_lineId = 'lineId';
  static const String COLUMN_tokenInLineIndex = 'tokenInLineIndex';

  //static const String COLUMN_surahIndex = 'surahIndex';
  //static const String COLUMN_ayahIndex = 'ayahIndex';
  //static const String COLUMN_tokenIndex = 'tokenIndex';
  static const String COLUMN_token = 'token';
  static const String COLUMN_startIndex = 'startIndex';
  static const String COLUMN_endIndex = 'endIndex';
  static const String COLUMN_startIndexInToken = 'startIndexInToken';
  static const String COLUMN_endIndexInToken = 'endIndexInToken';
  static const String COLUMN_character = 'character';
  static const String COLUMN_colorId = 'colorId';

  //static const String COLUMN_name = 'name';
  //static const String COLUMN_color = 'color';
  //static const String COLUMN_type = 'type';
  static const String COLUMN_verse = 'verse';
  static const String COLUMN_isRelatedWithNextToken = 'isRelatedWithNextToken';
  static const String COLUMN_isRelatedWithPreviousToken = 'isRelatedWithPreviousToken';

  static const String COLUMN_tokensCount = 'tokensCount';

  static const String COLUMN_tokensId = 'tokensId';
  static const String COLUMN_tokensLength = 'tokensLength';

  //static const String COLUMN_count = 'count';
  static const String COLUMN_tokensArabic = 'tokensArabic';
  static const String COLUMN_tokensUthmani = 'tokensUthmani';
  static const String COLUMN_tokensHafs = 'tokensHafs';
  static const String COLUMN_tokenStartIndex = 'tokenStartIndex';
  static const String COLUMN_tokenEndIndex = 'tokenEndIndex';

  static const int Tafkheem_Rule_v6_ID = 1;
  static const int TafkheemWasl_Rule_v6_ID = 2;
  static const int Qalqlah_Rule_v6_ID = 3;
  static const int EkfahGoneh_Rule_v6_ID = 4;
  static const int EkfahGonehWasl_Rule_v6_ID = 5;
  static const int Goneh_Rule_v6_ID = 6;
  static const int GonehWasl_Rule_v6_ID = 7;
  static const int Eqlab_Rule_v6_ID = 8;
  static const int EqlabWasl_Rule_v6_ID = 9;
  static const int Edgam_Rule_v6_ID = 10;
  static const int EdgamWasl_Rule_v6_ID = 11;
  static const int EdgamMutaseel_Rule_v6_ID = 12;
  static const int Madd_TTabehee_2_Rule_v6_ID = 13;
  static const int Madd_TTabehee_2_Wasl_Rule_v6_ID = 14;
  static const int Madd_Jwaaz_2_4_6_ArdSukon_Rule_v6_ID = 15;
  static const int Madd_Jwaaz_2_4_6_ArdSukon_Wasl_Rule_v6_ID = 16;
  static const int Madd_Wajeeb_4_5_Mutaseel_Rule_v6_ID = 17;
  static const int Madd_Wajeeb_4_5_Monfseel_Rule_v6_ID = 18;
  static const int Madd_Wajeeb_4_5_Monfseel_Wasl_Rule_v6_ID = 19;
  static const int Madd_Wajeeb_4_5_6_Mutaseel_ArdSukon_Rule_v6_ID = 20;
  static const int Madd_Lazem_6_Rule_v6_ID = 21;
  static const int NotPronouncedStopped_Rule_v6_ID = 22;
  static const int NotPronouncedMutaseel_Rule_v6_ID = 23;
  static const int NotPronouncedNever_Rule_v6_ID = 24;
  static const int RED_Rule_v6_ID = 25;

  static const String Tafkheem_Rule_v6_Name = 'Tafkheem';
  static const String TafkheemWasl_Rule_v6_Name = 'TafkheemWasl';
  static const String Qalqlah_Rule_v6_Name = 'Qalqlah';
  static const String EkfahGoneh_Rule_v6_Name = 'EkfahGoneh';
  static const String EkfahGonehWasl_Rule_v6_Name = 'EkfahGonehWasl';
  static const String Goneh_Rule_v6_Name = 'Goneh';
  static const String GonehWasl_Rule_v6_Name = 'GonehWasl';
  static const String Eqlab_Rule_v6_Name = 'Eqlab';
  static const String EqlabWasl_Rule_v6_Name = 'EqlabWasl';
  static const String Edgam_Rule_v6_Name = 'Edgam';
  static const String EdgamWasl_Rule_v6_Name = 'EdgamWasl';
  static const String EdgamMutaseel_Rule_v6_Name = 'EdgamMutaseel';
  static const String Madd_TTabehee_2_Rule_v6_Name = 'Madd_TTabehee_2';
  static const String Madd_TTabehee_2_Wasl_Rule_v6_Name = 'Madd_TTabehee_2_Wasl';
  static const String Madd_Jwaaz_2_4_6_ArdSukon_Rule_v6_Name = 'Madd_Jwaaz_2_4_6_ArdSukon';
  static const String Madd_Jwaaz_2_4_6_ArdSukon_Wasl_Rule_v6_Name = 'Madd_Jwaaz_2_4_6_ArdSukon_Wasl';
  static const String Madd_Wajeeb_4_5_Mutaseel_Rule_v6_Name = 'Madd_Wajeeb_4_5_Mutaseel';
  static const String Madd_Wajeeb_4_5_Monfseel_Rule_v6_Name = 'Madd_Wajeeb_4_5_Monfseel';
  static const String Madd_Wajeeb_4_5_Monfseel_Wasl_Rule_v6_Name = 'Madd_Wajeeb_4_5_Monfseel_Wasl';
  static const String Madd_Wajeeb_4_5_6_Mutaseel_ArdSukon_Rule_v6_Name = 'Madd_Wajeeb_4_5_6_Mutaseel_ArdSukon';
  static const String Madd_Lazem_6_Rule_v6_Name = 'Madd_Lazem_6';
  static const String NotPronouncedStopped_Rule_v6_Name = 'NotPronouncedStopped';
  static const String NotPronouncedMutaseel_Rule_v6_Name = 'NotPronouncedMutaseel';
  static const String NotPronouncedNever_Rule_v6_Name = 'NotPronouncedNever';
  static const String RED_Rule_v6_Name = 'RED';

  static const Color Tafkheem_Color_v6 = Color(0xFF22AA22);
  static const Color TafkheemWasl_Color_v6 = Color(0xFF22AA22);
  static const Color Qalqlah_Color_v6 = Color(0xFFF69813);
  static const Color EkfahGoneh_Color_v6 = Color(0xFFFF0000);
  static const Color EkfahGonehWasl_Color_v6 = Color(0xFFFF0000);
  static const Color Goneh_Color_v6 = Color(0xFFFF0000);
  static const Color GonehWasl_Color_v6 = Color(0xFFFF0000);
  static const Color Eqlab_Color_v6 = Color(0xFFFF0000);
  static const Color EqlabWasl_Color_v6 = Color(0xFFFF0000);
  static const Color Edgam_Color_v6 = Color(0xFFFF33CC);
  static const Color EdgamWasl_Color_v6 = Color(0xFFFF33CC);
  static const Color EdgamMutaseel_Color_v6 = Color(0xFFFF0000);
  static const Color Madd_TTabehee_2_Color_v6 = Color(0xFF000000);
  static const Color Madd_TTabehee_2_Wasl_Color_v6 = Color(0xFF000000);
  static const Color Madd_Jwaaz_2_4_6_ArdSukon_Color_v6 = Color(0xFF000000);
  static const Color Madd_Jwaaz_2_4_6_ArdSukon_Wasl_Color_v6 = Color(0xFF000000);
  static const Color Madd_Wajeeb_4_5_Mutaseel_Color_v6 = Color(0xFF2444FF);
  static const Color Madd_Wajeeb_4_5_Monfseel_Color_v6 = Color(0xFF2444FF);
  static const Color Madd_Wajeeb_4_5_Monfseel_Wasl_Color_v6 = Color(0xFF2444FF);
  static const Color Madd_Wajeeb_4_5_6_Mutaseel_ArdSukon_Color_v6 = Color(0xFF2444FF);
  static const Color Madd_Lazem_6_Color_v6 = Color(0xFFBD5E00);
  static const Color NotPronouncedStopped_Color_v6 = Color(0xFF000000);
  static const Color NotPronouncedMutaseel_Color_v6 = Color(0xFF000000);
  static const Color NotPronouncedNever_Color_v6 = Color(0xFF000000);
  static const Color RED_Color_v6 = Color(0xFFFF0000);
  static const Color BLACK_Color_v6 = Color(0xff000000);
}

class SQL_Options {
  String? tableIndexType;

  int? pageIndex;

  int? surahIndex;
  int? ayahIndex;
  int? tokenIndex;

  int MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_MADINAH;
  int MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_MADINAH;

  String location_url = '';
  String image_item = '';

  SQL_Options() {
    pageIndex = 0;
    surahIndex = 0;
    ayahIndex = 0;
    tokenIndex = 0;
  }

  void setPageInfo(String tableIndexType, int pageIndex) {
    this.tableIndexType = tableIndexType;
    this.pageIndex = pageIndex;
    surahIndex = 0;
    ayahIndex = 0;
    tokenIndex = 0;

    if (tableIndexType == SQL_IO.TABLE_INDEX_NAME_NsTaliQ) {
      MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_NsTaliQ;
      MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_NsTaliQ;
    } else {
      MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_MADINAH;
      MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_MADINAH;
    }
  }

  void setAyahInfo(String tableIndexType, int surahIndex, int ayahIndex) {
    this.tableIndexType = tableIndexType;
    pageIndex = 0;
    this.surahIndex = surahIndex;
    this.ayahIndex = ayahIndex;
    tokenIndex = 0;

    if (tableIndexType == SQL_IO.TABLE_INDEX_NAME_NsTaliQ) {
      MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_NsTaliQ;
      MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_NsTaliQ;
    } else {
      MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_MADINAH;
      MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_MADINAH;
    }
  }

  void setTokenInfo(String tableIndexType, int surahIndex, int ayahIndex, int tokenIndex) {
    this.tableIndexType = tableIndexType;
    pageIndex = 0;
    this.surahIndex = surahIndex;
    this.ayahIndex = ayahIndex;
    this.tokenIndex = tokenIndex;

    if (tableIndexType == SQL_IO.TABLE_INDEX_NAME_NsTaliQ) {
      MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_NsTaliQ;
      MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_NsTaliQ;
    } else {
      MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_MADINAH;
      MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_MADINAH;
    }
  }

  void setAllInfo(String tableIndexType, int surahIndex, int ayahIndex, {int pageIndex = 0, int tokenIndex = 0}) {
    this.tableIndexType = tableIndexType;
    this.pageIndex = pageIndex;
    this.surahIndex = surahIndex;
    this.ayahIndex = ayahIndex;
    this.tokenIndex = tokenIndex;

    if (tableIndexType == SQL_IO.TABLE_INDEX_NAME_NsTaliQ) {
      MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_NsTaliQ;
      MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_NsTaliQ;
    } else {
      MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_MADINAH;
      MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_MADINAH;
    }
  }

  @override
  String toString() {
    return 'SQL_Options{'
        'tableIndexType: $tableIndexType'
        ', pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', ayahIndex: $ayahIndex'
        ', tokenIndex: $tokenIndex'
        '}';
  }

  Future<void> nextItem() async {
    //print('nextItem >> ${toString()}');
    if (pageIndex! >= MIN_PAGE_INDEX && pageIndex! < MAX_PAGE_INDEX) {
      // next page
      pageIndex = pageIndex! + 1;
      //print('nextItem page >> ${toString()}');
      return;
    } else if (surahIndex != 0 && surahIndex! >= 1 && surahIndex! <= 114 && ayahIndex! > 0) {
      // next verse
      int nTokensCount = await SQLHelper.getTokensCount(tableIndexType!, surahIndex!, ayahIndex!);
      int nVersesCount = await SQLHelper.getVersesCount(tableIndexType!, surahIndex!);
      //print('nextItem nTokensCount >> ${nTokensCount}');
      //print('nextItem nVersesCount >> ${nVersesCount}');

      if (tokenIndex! > 0 && tokenIndex! < nTokensCount) {
        tokenIndex = tokenIndex! + 1;
        //print('nextItem Token >> ${toString()}');
        return;
      } else if (ayahIndex! + 1 <= nVersesCount && nVersesCount > 0) {
        ayahIndex = ayahIndex! + 1;
        if (tokenIndex! > 0) {
          tokenIndex = 1;
        } else {
          tokenIndex = 0;
        }
        //print('nextItem Verse >> ${toString()}');
        return;
      } else if (ayahIndex! == nVersesCount && nVersesCount > 0 && surahIndex! < 114) {
        surahIndex = surahIndex! + 1;
        ayahIndex = 1;
        if (tokenIndex! > 0) {
          tokenIndex = 1;
        } else {
          tokenIndex = 0;
        }
        //print('nextItem Surah >> ${toString()}');
        return;
      }
    }
    return;
  }

  Future<void> previousItem() async {
    //print('previousItem >> ${toString()}');
    if (pageIndex != 0 && pageIndex! > MIN_PAGE_INDEX) {
      // previous page
      pageIndex = pageIndex! - 1;
      //print('previousItem page >> ${toString()}');
      return;
    } else if (surahIndex != 0 && surahIndex! >= 1 && surahIndex! <= 114 && ayahIndex! > 0) {
      // previous verse
      if (tokenIndex! > 1) {
        tokenIndex = tokenIndex! - 1;
        //print('previousItem token >> ${toString()}');
        return;
      } else if (ayahIndex! > 1) {
        ayahIndex = ayahIndex! - 1;
        if (tokenIndex! > 0) {
          int nTokensCount = await SQLHelper.getTokensCount(tableIndexType!, surahIndex!, ayahIndex!);
          tokenIndex = nTokensCount;
        } else {
          tokenIndex = 0;
        }
        //print('previousItem verse >> ${toString()}');
        return;
      } else if (ayahIndex == 1 && surahIndex! > 1) {
        int nVersesCount = await SQLHelper.getVersesCount(tableIndexType!, (surahIndex! - 1));
        if (nVersesCount > 0) {
          surahIndex = surahIndex! - 1;
          ayahIndex = nVersesCount;
          if (tokenIndex! > 0) {
            int nTokensCount = await SQLHelper.getTokensCount(tableIndexType!, surahIndex!, ayahIndex!);
            tokenIndex = nTokensCount;
          } else {
            tokenIndex = 0;
          }
          //print('previousItem Surah >> ${toString()}');
          return;
        }
      }
    }
    return;
  }

  // *****
  Future<void> setPagePlayerInfo(String tableIndexType, int pageIndex) async {
    this.tableIndexType = tableIndexType;
    this.pageIndex = 0;
    surahIndex = 0;
    ayahIndex = 0;
    tokenIndex = 0;

    if (tableIndexType == SQL_IO.TABLE_INDEX_NAME_NsTaliQ) {
      MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_NsTaliQ;
      MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_NsTaliQ;
    } else {
      MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_MADINAH;
      MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_MADINAH;
    }

    List<VerseModel> nVerses = await SQLHelper.getFirstVerseInPage(tableIndexType!, pageIndex!);
    if (null != nVerses && nVerses.length! > 0) {
      this.pageIndex = nVerses[0].pageIndex;
      surahIndex = nVerses[0].surahIndex;
      ayahIndex = nVerses[0].ayahIndex;
      tokenIndex = 1;
      return;
    }
  }

  Future<void> setAyahPlayerInfo(String tableIndexType, int surahIndex, int ayahIndex) async {
    this.tableIndexType = tableIndexType;
    pageIndex = 0;
    this.surahIndex = 0;
    this.ayahIndex = 0;
    tokenIndex = 0;

    if (tableIndexType == SQL_IO.TABLE_INDEX_NAME_NsTaliQ) {
      MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_NsTaliQ;
      MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_NsTaliQ;
    } else {
      MAX_PAGE_INDEX = SQL_IO.MAX_PAGE_INDEX_MADINAH;
      MIN_PAGE_INDEX = SQL_IO.MIN_PAGE_INDEX_MADINAH;
    }

    List<VerseModel> nVerses = await SQLHelper.getVerse(tableIndexType!, surahIndex!, ayahIndex!);
    if (null != nVerses && nVerses.length! > 0) {
      pageIndex = nVerses[0].pageIndex;
      this.surahIndex = nVerses[0].surahIndex;
      this.ayahIndex = nVerses[0].ayahIndex;
      tokenIndex = 1;
      return;
    }
  }

  Future<void> nextAyahPlayer() async {
    print('nextAyahPlayer >> ${toString()}');
    if (surahIndex != 0 && surahIndex! >= 1 && surahIndex! <= 114 && ayahIndex! > 0) {
      // next verse
      int nVersesCount = await SQLHelper.getVersesCount(tableIndexType!, surahIndex!);
      if (ayahIndex! + 1 <= nVersesCount && nVersesCount > 0) {
        List<VerseModel> nVerses = await SQLHelper.getVerse(tableIndexType!, surahIndex!, ayahIndex! + 1);
        if (null != nVerses && nVerses.length! > 0) {
          print('nextAyahPlayer Verse >> ${toString()}');
          pageIndex = nVerses[0].pageIndex;
          surahIndex = nVerses[0].surahIndex;
          ayahIndex = nVerses[0].ayahIndex;
          tokenIndex = 1;
          return;
        }
      } else if (ayahIndex! == nVersesCount && nVersesCount > 0 && surahIndex! < 114) {
        List<VerseModel> nVerses = await SQLHelper.getVerse(tableIndexType!, surahIndex! + 1, 1);
        if (null != nVerses && nVerses.length! > 0) {
          print('nextAyahPlayer Verse >> ${toString()}');
          pageIndex = nVerses[0].pageIndex;
          surahIndex = nVerses[0].surahIndex;
          ayahIndex = nVerses[0].ayahIndex;
          tokenIndex = 1;
          return;
        }
      }
    }
    return;
  }

  Future<void> previousAyahPlayer() async {
    print('previousAyahPlayer >> ${toString()}');
    if (surahIndex != 0 && surahIndex! >= 1 && surahIndex! <= 114 && ayahIndex! > 0) {
      // previous verse
      if (ayahIndex! > 1) {
        List<VerseModel> nVerses = await SQLHelper.getVerse(tableIndexType!, surahIndex!, ayahIndex! - 1);
        if (null != nVerses && nVerses.length! > 0) {
          print('previousAyahPlayer Verse >> ${toString()}');
          pageIndex = nVerses[0].pageIndex;
          surahIndex = nVerses[0].surahIndex;
          ayahIndex = nVerses[0].ayahIndex;
          tokenIndex = 1;
          return;
        }
      } else if (ayahIndex == 1 && surahIndex! > 1) {
        int nVersesCount = await SQLHelper.getVersesCount(tableIndexType!, (surahIndex! - 1));
        if (nVersesCount > 0) {
          List<VerseModel> nVerses = await SQLHelper.getVerse(tableIndexType!, surahIndex! - 1, nVersesCount);
          if (null != nVerses && nVerses.length! > 0) {
            print('previousAyahPlayer Verse >> ${toString()}');
            pageIndex = nVerses[0].pageIndex;
            surahIndex = nVerses[0].surahIndex;
            ayahIndex = nVerses[0].ayahIndex;
            tokenIndex = 1;
            return;
          }
        }
      }
    }
    return;
  }

  Future<void> nextPagePlayer() async {
    print('nextPagePlayer >> ${toString()}');
    if (pageIndex! >= MIN_PAGE_INDEX && pageIndex! < MAX_PAGE_INDEX) {
      List<VerseModel> nVerses = await SQLHelper.getFirstVerseInPage(tableIndexType!, pageIndex! + 1);
      if (null != nVerses && nVerses.length! > 0) {
        print('nextPagePlayer page >> ${toString()}');
        pageIndex = nVerses[0].pageIndex;
        surahIndex = nVerses[0].surahIndex;
        ayahIndex = nVerses[0].ayahIndex;
        tokenIndex = 1;
        return;
      }
    }
    return;
  }

  Future<void> previousPagePlayer() async {
    print('previousPagePlayer >> ${toString()}');
    if (pageIndex != 0 && pageIndex! > MIN_PAGE_INDEX) {
      List<VerseModel> nVerses = await SQLHelper.getFirstVerseInPage(tableIndexType!, pageIndex! - 1);
      if (null != nVerses && nVerses.length! > 0) {
        print('previousPagePlayer page >> ${toString()}');
        pageIndex = nVerses[0].pageIndex;
        surahIndex = nVerses[0].surahIndex;
        ayahIndex = nVerses[0].ayahIndex;
        tokenIndex = 1;
        return;
      }
    }
    return;
  }
}
