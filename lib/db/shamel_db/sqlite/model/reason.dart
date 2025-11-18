import '../sql_constants.dart';

class ReasonModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? verseId;
  String? verseHafs;
  String? verseUthmani;
  String? reason;
  String? shortAyah;
  String? displayName;

  ReasonModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    verseId = nJSON[SQL_IO.COLUMN_verseId];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
    reason = nJSON[SQL_IO.COLUMN_reason];
    shortAyah = nJSON[SQL_IO.COLUMN_shortAyah];
    displayName = nJSON[SQL_IO.COLUMN_displayName];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_verseId: verseId,
        SQL_IO.COLUMN_verseHafs: verseHafs,
        SQL_IO.COLUMN_verseUthmani: verseUthmani,
        SQL_IO.COLUMN_reason: reason,
        SQL_IO.COLUMN_shortAyah: shortAyah,
        SQL_IO.COLUMN_displayName: displayName,
      };

  @override
  String toString() {
    return 'ReasonModel{'
        ' pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', ayahIndex: $ayahIndex'
        ', verseId: $verseId'
        // ', verseHafs: $verseHafs'
        // ', verseUthmani: $verseUthmani'
        //', reason: $reason'
        ', shortAyah: $shortAyah'
        ', displayName: $displayName'
        '}';
  }
}
