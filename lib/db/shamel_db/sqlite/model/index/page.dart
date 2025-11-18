import '../../sql_constants.dart';

class PageModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahFromIndex;
  int? ayahToIndex;
  int? juzaaIndex;

  // ← جديد: مُنشئ عادي
  PageModel({
    this.pageIndex,
    this.surahIndex,
    this.ayahFromIndex,
    this.ayahToIndex,
    this.juzaaIndex,
  });

  PageModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahFromIndex = nJSON[SQL_IO.COLUMN_ayahFromIndex];
    ayahToIndex = nJSON[SQL_IO.COLUMN_ayahToIndex];
    juzaaIndex = nJSON[SQL_IO.COLUMN_juzaaIndex];
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahFromIndex: ayahFromIndex,
        SQL_IO.COLUMN_ayahToIndex: ayahToIndex,
        SQL_IO.COLUMN_juzaaIndex: juzaaIndex,
      };

  factory PageModel.fromPage(int pageIndex) => PageModel(pageIndex: pageIndex);

  @override
  bool operator ==(Object other) => identical(this, other) || other is PageModel && pageIndex != null && other.pageIndex == pageIndex;

  @override
  int get hashCode => (pageIndex ?? -1).hashCode;

  @override
  String toString() {
    return 'PageModel{'
        'pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', ayahFromIndex: $ayahFromIndex'
        ', ayahToIndex: $ayahToIndex'
        ', juzaaIndex: $juzaaIndex'
        '}';
  }
}
