part of tajweed_viewer;

const String _kQuranLinesPath = 'assets/metadata/Quran/quraan_lines.json';
const String _kSemanticsPath = 'assets/metadata/Quran/semantics.json';
const String _kDefaultCharColor = '#FF000000';

Future<Map<int, List<_SemanticMeaning>>>? _semanticsFuture;

class TajweedDataService {
  const TajweedDataService();

  static Future<_QuranLineIndex>? _lineIndexFuture;

  Future<_QuranLineIndex> _loadLineIndex() {
    if (_lineIndexFuture != null) {
      return _lineIndexFuture!;
    }
    _lineIndexFuture = _initLineIndex();
    return _lineIndexFuture!;
  }

  Future<_QuranLineIndex> _initLineIndex() async {
    final raw = await rootBundle.loadString(_kQuranLinesPath);
    final data = json.decode(raw) as List<dynamic>;
    final grouped = <int, List<_QuranLineEntry>>{};
    for (final entry in data) {
      final line = _QuranLineEntry.fromMap(entry as Map<String, dynamic>);
      if (line.page <= 0) {
        continue;
      }
      grouped.putIfAbsent(line.page, () => []).add(line);
    }
    final pages = <int, List<_QuranLineEntry>>{};
    for (final group in grouped.entries) {
      final sorted = List<_QuranLineEntry>.from(group.value);
      sorted.sort((a, b) => a.lineIndex.compareTo(b.lineIndex));
      pages[group.key] = List<_QuranLineEntry>.unmodifiable(sorted);
    }
    return _QuranLineIndex(pages: pages);
  }

  Future<int> loadPageCount() async {
    final index = await _loadLineIndex();
    return index.pageCount;
  }

  Future<List<QuranPart>> loadParts() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/metadata/Quran/parts.json',
      );
      final data = json.decode(raw) as List<dynamic>;
      return data
          .map((entry) => QuranPart.fromMap(entry as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<Map<int, String>> loadSurahNames() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/metadata/Quran/surah_index.json',
      );
      final data = json.decode(raw) as List<dynamic>;
      final resolved = <int, String>{};
      for (final entry in data) {
        final map = entry as Map<String, dynamic>;
        final number = (map['number'] as num?)?.toInt();
        final name = (map['name'] ?? '').toString();
        if (number == null || number <= 0 || name.isEmpty) {
          continue;
        }
        resolved[number] = name;
      }
      return resolved;
    } catch (_) {
      return const {};
    }
  }

  Future<TajweedPageData> loadPage(int page) async {
    final index = await _loadLineIndex();
    final entries = index.pages[page];
    if (entries == null || entries.isEmpty) {
      return TajweedPageData(pageIndex: page, lines: const []);
    }
    final semanticsForPage = await _loadSemanticsForPage(page);
    final lines = entries
        .map((entry) {
          final trimmedName = entry.suraNameAr.trim();
          return RenderedLine(
            sortKey: entry.lineIndex,
            text: entry.ayaText,
            surahIndexFirst: entry.suraNo,
            ayahIndexFirst: entry.ayaNo,
            isBasmala: false,
            isTitle: false,
            chars: _buildColoredChars(entry.ayaText),
            semanticSpans: _buildLineSemantics(
              lineIndex: entry.lineIndex,
              text: entry.ayaText,
              meanings: semanticsForPage,
            ),
            surahName: trimmedName.isNotEmpty ? trimmedName : null,
          );
        })
        .toList(growable: false);
    return TajweedPageData(
      pageIndex: page,
      lines: List<RenderedLine>.unmodifiable(lines),
    );
  }
}

List<ColoredChar> _buildColoredChars(String text) {
  final chars = <ColoredChar>[];
  for (final rune in text.runes) {
    chars.add(
      ColoredChar(
        t: String.fromCharCode(rune),
        cL: _kDefaultCharColor,
        cD: _kDefaultCharColor,
      ),
    );
  }
  return chars;
}

class _QuranLineIndex {
  _QuranLineIndex({required Map<int, List<_QuranLineEntry>> pages})
    : pages = Map.unmodifiable(pages),
      pageCount = pages.keys.isEmpty
          ? 0
          : pages.keys.reduce(
              (value, element) => value > element ? value : element,
            );

  final Map<int, List<_QuranLineEntry>> pages;
  final int pageCount;
}

class _QuranLineEntry {
  _QuranLineEntry({
    required this.page,
    required this.lineIndex,
    required this.suraNo,
    required this.ayaNo,
    required this.ayaText,
    required this.suraNameAr,
  });

  final int page;
  final int lineIndex;
  final int suraNo;
  final int ayaNo;
  final String ayaText;
  final String suraNameAr;

  factory _QuranLineEntry.fromMap(Map<String, dynamic> map) {
    return _QuranLineEntry(
      page: _parseInt(map['page']),
      lineIndex: _parseInt(map['lineIndex']),
      suraNo: _parseInt(map['sura_no']),
      ayaNo: _parseInt(map['aya_no']),
      ayaText: (map['aya_text'] ?? '').toString(),
      suraNameAr: (map['sura_name_ar'] ?? '').toString(),
    );
  }
}

int _parseInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

Future<Map<int, List<_SemanticMeaning>>> _loadSemanticIndex() {
  if (_semanticsFuture != null) {
    return _semanticsFuture!;
  }
  _semanticsFuture = _initSemanticsIndex();
  return _semanticsFuture!;
}

Future<Map<int, List<_SemanticMeaning>>> _initSemanticsIndex() async {
  try {
    final raw = await rootBundle.loadString(_kSemanticsPath);
    final data = json.decode(raw) as List<dynamic>;
    final map = <int, List<_SemanticMeaning>>{};
    for (final entry in data) {
      final meaning = _SemanticMeaning.fromMap(entry as Map<String, dynamic>);
      for (final word in meaning.words) {
        if (word.page <= 0) continue;
        map.putIfAbsent(word.page, () => []).add(meaning);
      }
    }
    return map;
  } catch (_) {
    return const {};
  }
}

Future<List<_SemanticMeaning>> _loadSemanticsForPage(int page) async {
  final index = await _loadSemanticIndex();
  return index[page] ?? const [];
}

List<SemanticSpan> _buildLineSemantics({
  required int lineIndex,
  required String text,
  required List<_SemanticMeaning> meanings,
}) {
  if (meanings.isEmpty) return const [];
  final boundaries = _tokenBoundaries(text);
  if (boundaries.isEmpty) return const [];

  final spans = <SemanticSpan>[];
  for (final meaning in meanings) {
    final tokenIndices =
        meaning.words
            .where((word) => word.lineIndex == lineIndex && word.tokenNo > 0)
            .map((word) => word.tokenNo - 1)
            .where((token) => token >= 0 && token < boundaries.length)
            .toSet()
            .toList()
          ..sort();
    if (tokenIndices.isEmpty) continue;
    final startBoundary = boundaries[tokenIndices.first];
    final endBoundary = boundaries[tokenIndices.last];
    final start = startBoundary.start;
    final end = endBoundary.start + endBoundary.length;
    final length = end - start;
    if (length <= 0) continue;
    spans.add(
      SemanticSpan(
        start: start,
        length: length,
        tokens: meaning.sentence,
        content: meaning.meaning,
      ),
    );
  }
  return spans;
}

List<_TokenBoundary> _tokenBoundaries(String text) {
  final matches = RegExp(r'\S+').allMatches(text);
  return matches
      .map(
        (match) =>
            _TokenBoundary(start: match.start, length: match.end - match.start),
      )
      .toList();
}

class _TokenBoundary {
  _TokenBoundary({required this.start, required this.length});

  final int start;
  final int length;
}

class _SemanticMeaning {
  _SemanticMeaning({
    required this.sentence,
    required this.meaning,
    required this.words,
  });

  final String sentence;
  final String meaning;
  final List<_SemanticWord> words;

  factory _SemanticMeaning.fromMap(Map<String, dynamic> map) {
    final words = ((map['words_includ'] ?? []) as List<dynamic>)
        .map((entry) => _SemanticWord.fromMap(entry as Map<String, dynamic>))
        .toList();
    return _SemanticMeaning(
      sentence: (map['sentence'] ?? '').toString(),
      meaning: (map['meaning'] ?? '').toString(),
      words: words,
    );
  }
}

class _SemanticWord {
  _SemanticWord({
    required this.page,
    required this.lineIndex,
    required this.tokenNo,
  });

  final int page;
  final int lineIndex;
  final int tokenNo;

  factory _SemanticWord.fromMap(Map<String, dynamic> map) {
    return _SemanticWord(
      page: _parseInt(map['page']),
      lineIndex: _parseInt(map['lineIndex']),
      tokenNo: _parseInt(map['token_no']),
    );
  }
}
