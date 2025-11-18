import '../sql_constants.dart';

class TranslateModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? verseId;
  String? verseHafs;
  String? verseUthmani;
  List<TranslateLanguageModel>? data;

  TranslateModel();

  void setData(List<TranslateLanguageModel> data) {
    this.data = data;
  }

  void addData(TranslateLanguageModel cModel) {
    if (data == null || data!.isEmpty) data = <TranslateLanguageModel>[];
    data!.add(cModel);
  }

  TranslateModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    verseId = nJSON[SQL_IO.COLUMN_verseId];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_verseId: verseId,
        SQL_IO.COLUMN_verseHafs: verseHafs,
        SQL_IO.COLUMN_verseUthmani: verseUthmani,
      };

  @override
  String toString() {
    return 'TranslateModel{'
        ' pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', ayahIndex: $ayahIndex'
        ', verseId: $verseId'
        // ', verseHafs: $verseHafs'
        // ', verseUthmani: $verseUthmani'
        ', data: $data'
        '}';
  }
}

class TranslateLanguageModel {
  String? languageCode;
  String? translateText;

  TranslateLanguageModel(String this.languageCode, String this.translateText);

  @override
  String toString() {
    return 'TranslateLanguageModel{'
        'languageCode: $languageCode'
        ', translateText: $translateText'
        '}';
  }
}
