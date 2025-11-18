import 'verse.dart';

class WirdVerseModel {
  int? number;

  VerseModel? fromVerseModel;
  VerseModel? toVerseModel;

  bool? isReading;

  WirdVerseModel({
    required this.number,
    required this.fromVerseModel,
    required this.toVerseModel,
    required this.isReading,
  });

  factory WirdVerseModel.fromJson(Map<String, dynamic> json) {
    return WirdVerseModel(
      number: json['number'],
      fromVerseModel: VerseModel.fromJson(json['fromVerseModel']),
      toVerseModel: VerseModel.fromJson(json['toVerseModel']),
      isReading: json['isReading'],
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'fromVerseModel': fromVerseModel,
        'toVerseModel': toVerseModel,
        'isReading': isReading,
      };

  @override
  String toString() {
    return 'WirdVerseModel{number: $number, fromVerseModel: $fromVerseModel, toVerseModel: $toVerseModel, isReading: $isReading}';
  }
}
