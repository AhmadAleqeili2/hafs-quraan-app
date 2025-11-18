import '../../sql_constants.dart';

class HizbModel {
  int? id;
  int? hizb;
  dynamic? hizbDetails;

  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? juzaaIndex;

  int? verseId;

  String? verseHafs;
  String? verseUthmani;
  String? displayName;

  HizbModel.fromJson(Map nJSON) {
    id = nJSON[SQL_IO.COLUMN_id];
    hizb = nJSON[SQL_IO.COLUMN_hizb];
    hizbDetails = nJSON[SQL_IO.COLUMN_hizbDetails];
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    juzaaIndex = nJSON[SQL_IO.COLUMN_juzaaIndex];
    verseId = nJSON[SQL_IO.COLUMN_verseId];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
    displayName = nJSON[SQL_IO.COLUMN_displayName];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_id: id,
        SQL_IO.COLUMN_hizb: hizb,
        SQL_IO.COLUMN_hizbDetails: hizbDetails,
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_juzaaIndex: juzaaIndex,
        SQL_IO.COLUMN_verseId: verseId,
        SQL_IO.COLUMN_verseHafs: verseHafs,
        SQL_IO.COLUMN_verseUthmani: verseUthmani,
        SQL_IO.COLUMN_displayName: displayName,
      };

  @override
  String toString() {
    return 'HizbModel{'
        ' id: $id,'
        ' hizb: $hizb,'
        ' hizbDetails: $hizbDetails,'
        ' pageIndex: $pageIndex,'
        ' surahIndex: $surahIndex,'
        ' ayahIndex: $ayahIndex,'
        ' juzaaIndex: $juzaaIndex,'
        ' verseId: $verseId,'
        ' verseHafs: $verseHafs,'
        ' verseUthmani: $verseUthmani,'
        ' displayName: $displayName'
        '}';
  }
}
