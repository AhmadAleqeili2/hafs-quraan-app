import '../../sql_constants.dart';

class JuzaaModel {
  int? pageIndex;
  int? surahIndex;
  int? juzaaIndex;

  JuzaaModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    juzaaIndex = nJSON[SQL_IO.COLUMN_juzaaIndex];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_juzaaIndex: juzaaIndex,
      };

  @override
  String toString() {
    return 'JuzaaModel{'
        'pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', juzaaIndex: $juzaaIndex'
        '}';
  }
}
