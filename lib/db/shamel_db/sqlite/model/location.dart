import '../sql_constants.dart';

class LocationModel {
  int? pageIndex;
  int? surahIndex;
  int? ayahIndex;
  int? tokenIndex;
  String? image;
  String? location;

  LocationModel.fromJson(Map nJSON) {
    pageIndex = nJSON[SQL_IO.COLUMN_pageIndex];
    surahIndex = nJSON[SQL_IO.COLUMN_surahIndex];
    ayahIndex = nJSON[SQL_IO.COLUMN_ayahIndex];
    tokenIndex = nJSON[SQL_IO.COLUMN_tokenIndex];
    image = nJSON[SQL_IO.COLUMN_image].toString();
    location = nJSON[SQL_IO.COLUMN_location].toString();
  }

  Map<String, dynamic> toJson() => {
        SQL_IO.COLUMN_pageIndex: pageIndex,
        SQL_IO.COLUMN_surahIndex: surahIndex,
        SQL_IO.COLUMN_ayahIndex: ayahIndex,
        SQL_IO.COLUMN_tokenIndex: tokenIndex,
        SQL_IO.COLUMN_image: image,
        SQL_IO.COLUMN_location: location,
      };

  @override
  String toString() {
    return 'LocationModel{'
        'pageIndex: $pageIndex'
        ', surahIndex: $surahIndex'
        ', ayahIndex: $ayahIndex'
        ', tokenIndex: $tokenIndex'
        ', image: $image'
        ', location: $location'
        '}';
  }
}
