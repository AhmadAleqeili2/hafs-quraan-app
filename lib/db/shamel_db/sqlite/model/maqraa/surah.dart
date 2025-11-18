class Surah {
  List<Chapters>? chapters;

  Surah({this.chapters});

  Surah.fromJson(Map<String, dynamic> json) {
    if (json['chapters'] != null) {
      chapters = <Chapters>[];
      json['chapters'].forEach((v) {
        chapters!.add(Chapters.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (chapters != null) {
      data['chapters'] = chapters!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Chapters {
  int? surahIndex;
  int? pageIndexStart;
  int? type;
  String? name;
  String? displayName;
  int? juzaaIndex;
  int? versCount;
  int? pageIndexEnd;

  Chapters(
      {this.surahIndex,
      this.pageIndexStart,
      this.type,
      this.name,
      this.displayName,
      this.juzaaIndex,
      this.versCount,
      this.pageIndexEnd});

  Chapters.fromJson(Map<dynamic, dynamic> json) {
    surahIndex = json['surahIndex'];
    pageIndexStart = json['pageIndexStart'];
    type = json['type'];
    name = json['name'];
    displayName = json['displayName'];
    juzaaIndex = json['juzaaIndex'];
    versCount = json['versCount'];
    pageIndexEnd = json['pageIndexEnd'];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = <dynamic, dynamic>{};
    data['surahIndex'] = surahIndex;
    data['pageIndexStart'] = pageIndexStart;
    data['type'] = type;
    data['name'] = name;
    data['displayName'] = displayName;
    data['juzaaIndex'] = juzaaIndex;
    data['versCount'] = versCount;
    data['pageIndexEnd'] = pageIndexEnd;
    return data;
  }
}
