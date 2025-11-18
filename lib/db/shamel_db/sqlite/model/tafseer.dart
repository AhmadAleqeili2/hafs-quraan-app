import '../sql_constants.dart';

class TafseerModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? verseId;
  String? verseHafs;
  String? verseUthmani;
  List<TafseerLanguageModel>? data;

  TafseerModel();

  void setData(List<TafseerLanguageModel> data) {
    this.data = data;
  }

  void addData(TafseerLanguageModel cModel) {
    if (data == null || data!.isEmpty) data = <TafseerLanguageModel>[];
    data!.add(cModel);
  }

  TafseerModel.fromJson(Map nJSON) {
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
    return 'TafseerModel{'
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

class TafseerLanguageModel {
  String? tafsserCode;
  String? tafsserText;

  TafseerLanguageModel(String this.tafsserCode, String this.tafsserText);

  @override
  String toString() {
    return 'TafseerLanguageModel{'
        'tafsserCode: $tafsserCode'
        //', tafsserText: $tafsserText'
        '}';
  }
}
