import '../sql_constants.dart';

class SubstantiveModel {
  int? pageIndex;
  int? surahIndex;
  int? verseIdFrom;
  int? verseIdTo;
  int? verseFromIndex;
  int? verseToIndex;
  int? color;
  String? detail;
  String? verseHafs;
  String? verseUthmani;
  String? displayName;

  SubstantiveModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    verseIdFrom = nJSON[SQL_IO.COLUMN_verseIdFrom];
    verseIdTo = nJSON[SQL_IO.COLUMN_verseIdTo];
    verseFromIndex = nJSON[SQL_IO.COLUMN_verseFromIndex];
    verseToIndex = nJSON[SQL_IO.COLUMN_verseToIndex];
    color = nJSON[SQL_IO.COLUMN_color];
    detail = nJSON[SQL_IO.COLUMN_detail];
    verseHafs = nJSON[SQL_IO.COLUMN_verseHafs];
    verseUthmani = nJSON[SQL_IO.COLUMN_verseUthmani];
    displayName = nJSON[SQL_IO.COLUMN_displayName];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_verseIdFrom: verseIdFrom,
        SQL_IO.COLUMN_verseIdTo: verseIdTo,
        SQL_IO.COLUMN_verseFromIndex: verseFromIndex,
        SQL_IO.COLUMN_verseToIndex: verseToIndex,
        SQL_IO.COLUMN_color: color,
        SQL_IO.COLUMN_detail: detail,
        SQL_IO.COLUMN_verseHafs: verseHafs,
        SQL_IO.COLUMN_verseUthmani: verseUthmani,
        SQL_IO.COLUMN_displayName: displayName,
      };

  @override
  String toString() {
    return 'SubstantiveModel{'
        ' pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', verseIdFrom: $verseIdFrom'
        ', verseIdTo: $verseIdTo'
        ', verseFromIndex: $verseFromIndex'
        ', verseToIndex: $verseToIndex'
        ', color: $color'
        ', detail: $detail'
        // ', verseHafs: $verseHafs'
        // ', verseUthmani: $verseUthmani'
        ', displayName: $displayName'
        '}';
  }
}
