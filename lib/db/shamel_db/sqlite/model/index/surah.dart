import '../../sql_constants.dart';

class SurahModel {
  int? pageIndex;
  int? surahIndex;
  int? juzaaIndex;
  int? type;
  String? name;
  String? displayName;

  SurahModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    juzaaIndex = nJSON[SQL_IO.COLUMN_juzaaIndex];
    type = nJSON[SQL_IO.COLUMN_type];
    name = nJSON[SQL_IO.COLUMN_name];
    displayName = nJSON[SQL_IO.COLUMN_displayName];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_juzaaIndex: juzaaIndex,
        SQL_IO.COLUMN_type: type,
        SQL_IO.COLUMN_name: name,
        SQL_IO.COLUMN_displayName: displayName,
      };

  @override
  String toString() {
    return 'SurahModel{'
        'pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', juzaaIndex: $juzaaIndex'
        ', type: $type'
        ', name: $name'
        ', displayName: $displayName'
        '}';
  }
}
