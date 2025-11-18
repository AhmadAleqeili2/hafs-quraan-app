part of tajweed_viewer;

class ColoredChar {
  final String t;
  final String cL;
  final String cD;

  ColoredChar({required this.t, required this.cL, required this.cD});

  factory ColoredChar.fromMap(Map<String, dynamic> map) => ColoredChar(
    t: (map['t'] ?? '').toString(),
    cL: (map['cL'] ?? '#00000000').toString(),
    cD: (map['cD'] ?? '#00000000').toString(),
  );
}

class RenderedLine {
  final int sortKey;
  final String text;
  final int surahIndexFirst;
  final int ayahIndexFirst;
  final bool isBasmala;
  final bool isTitle;
  final List<ColoredChar> chars;
  final List<SemanticSpan> semanticSpans;
  final String? surahName;
  final int? ayahMarkerGlyph;
  final int? ayahMarkerAyaNo;

  RenderedLine({
    required this.sortKey,
    required this.text,
    required this.surahIndexFirst,
    required this.ayahIndexFirst,
    required this.isBasmala,
    required this.isTitle,
    required this.chars,
    required this.semanticSpans,
    this.surahName,
    this.ayahMarkerGlyph,
    this.ayahMarkerAyaNo,
  });

  factory RenderedLine.fromMap(Map<String, dynamic> map) => RenderedLine(
    sortKey: (map['sortKey'] as num).toInt(),
    text: (map['text'] ?? '').toString(),
    surahIndexFirst: (map['surahIndexFirst'] as num).toInt(),
    ayahIndexFirst: (map['ayahIndexFirst'] as num).toInt(),
    isBasmala: map['isBasmala'] == true,
    isTitle: map['isTitle'] == true,
    chars: ((map['chars'] as List?) ?? const [])
        .map((entry) => ColoredChar.fromMap(entry as Map<String, dynamic>))
        .toList(),
    semanticSpans:
        ((map['semanticSpans'] ?? map['semantic_spans']) as List?)
            ?.map(
              (entry) => SemanticSpan.fromJson(entry as Map<String, dynamic>),
            )
            .toList() ??
        const [],
    surahName: (map['surah_name_ar'] ??
            map['surah_name'] ??
            map['surahName'])?.toString(),
    ayahMarkerGlyph:
        (map['ayahMarkerGlyph'] as num?)?.toInt() ??
            (map['ayah_marker_glyph'] as num?)?.toInt(),
    ayahMarkerAyaNo:
        (map['ayahMarkerAyaNo'] as num?)?.toInt() ??
            (map['ayah_marker_aya_no'] as num?)?.toInt(),
  );
}

class SemanticSpan {
  final int start;
  final int length;
  final String tokens;
  final String content;

  const SemanticSpan({
    required this.start,
    required this.length,
    required this.tokens,
    required this.content,
  });

  factory SemanticSpan.fromJson(Map<String, dynamic> json) => SemanticSpan(
    start: (json['start'] as num?)?.toInt() ?? 0,
    length: (json['length'] as num?)?.toInt() ?? 0,
    tokens: (json['tokens'] ?? '').toString(),
    content: (json['content'] ?? '').toString(),
  );
}

class TajweedPageData {
  final int pageIndex;
  final List<RenderedLine> lines;

  const TajweedPageData({required this.pageIndex, required this.lines});
}

class QuranPart {
  final String name;
  final int startPage;
  final int endPage;

  QuranPart({
    required this.name,
    required this.startPage,
    required this.endPage,
  });

  factory QuranPart.fromMap(Map<String, dynamic> map) => QuranPart(
    name: (map['part_name'] ?? '').toString(),
    startPage: (map['start_page'] as num).toInt(),
    endPage: (map['end_page'] as num).toInt(),
  );
}

const List<String> kFallbackSurahNames = [
  'الفاتحة',
  'البقرة',
  'آل عمران',
  'النساء',
  'المائدة',
  'الأنعام',
  'الأعراف',
  'الأنفال',
  'التوبة',
  'يونس',
  'هود',
  'يوسف',
  'الرعد',
  'إبراهيم',
  'الحجر',
  'النحل',
  'الإسراء',
  'الكهف',
  'مريم',
  'طه',
  'الأنبياء',
  'الحج',
  'المؤمنون',
  'النور',
  'الفرقان',
  'الشعراء',
  'النمل',
  'القصص',
  'العنكبوت',
  'الروم',
  'لقمان',
  'السجدة',
  'الأحزاب',
  'سبأ',
  'فاطر',
  'يس',
  'الصافات',
  'ص',
  'الزمر',
  'غافر',
  'فصلت',
  'الشورى',
  'الزخرف',
  'الدخان',
  'الجاثية',
  'الأحقاف',
  'محمد',
  'الفتح',
  'الحجرات',
  'ق',
  'الذاريات',
  'الطور',
  'النجم',
  'القمر',
  'الرحمن',
  'الواقعة',
  'الحديد',
  'المجادلة',
  'الحشر',
  'الممتحنة',
  'الصف',
  'الجمعة',
  'المنافقون',
  'التغابن',
  'الطلاق',
  'التحريم',
  'الملك',
  'القلم',
  'الحاقة',
  'المعارج',
  'نوح',
  'الجن',
  'المزمل',
  'المدثر',
  'القيامة',
  'الإنسان',
  'المرسلات',
  'النبأ',
  'النازعات',
  'عبس',
  'التكوير',
  'الانفطار',
  'المطففين',
  'الانشقاق',
  'البروج',
  'الطارق',
  'الأعلى',
  'الغاشية',
  'الفجر',
  'البلد',
  'الشمس',
  'الليل',
  'الضحى',
  'الشرح',
  'التين',
  'العلق',
  'القدر',
  'البينة',
  'الزلزلة',
  'العاديات',
  'القارعة',
  'التكاثر',
  'العصر',
  'الهمزة',
  'الفيل',
  'قريش',
  'الماعون',
  'الكوثر',
  'الكافرون',
  'النصر',
  'المسد',
  'الإخلاص',
  'الفلق',
  'الناس',
];

const Map<int, int> kSurahAyahCounts = {
  1: 7,
  2: 286,
  3: 200,
  4: 176,
  5: 120,
  6: 165,
  7: 206,
  8: 75,
  9: 129,
  10: 109,
  11: 123,
  12: 111,
  13: 43,
  14: 52,
  15: 99,
  16: 128,
  17: 111,
  18: 110,
  19: 98,
  20: 135,
  21: 112,
  22: 78,
  23: 118,
  24: 64,
  25: 77,
  26: 227,
  27: 93,
  28: 88,
  29: 69,
  30: 60,
  31: 34,
  32: 30,
  33: 73,
  34: 54,
  35: 45,
  36: 83,
  37: 182,
  38: 88,
  39: 75,
  40: 85,
  41: 54,
  42: 53,
  43: 89,
  44: 59,
  45: 37,
  46: 35,
  47: 38,
  48: 29,
  49: 18,
  50: 45,
  51: 60,
  52: 49,
  53: 62,
  54: 55,
  55: 78,
  56: 96,
  57: 29,
  58: 22,
  59: 24,
  60: 13,
  61: 14,
  62: 11,
  63: 11,
  64: 18,
  65: 12,
  66: 12,
  67: 30,
  68: 52,
  69: 52,
  70: 44,
  71: 28,
  72: 28,
  73: 20,
  74: 56,
  75: 40,
  76: 31,
  77: 50,
  78: 40,
  79: 46,
  80: 42,
  81: 29,
  82: 19,
  83: 36,
  84: 25,
  85: 22,
  86: 17,
  87: 19,
  88: 26,
  89: 30,
  90: 20,
  91: 15,
  92: 21,
  93: 11,
  94: 8,
  95: 8,
  96: 19,
  97: 5,
  98: 8,
  99: 8,
  100: 11,
  101: 11,
  102: 8,
  103: 3,
  104: 9,
  105: 5,
  106: 4,
  107: 7,
  108: 3,
  109: 6,
  110: 3,
  111: 5,
  112: 4,
  113: 5,
  114: 6,
};
