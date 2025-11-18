import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

Future<void> main() async {
  final root = Directory.current.path;
  final quranPath = p.join(root, 'assets', 'metadata', 'Quran', 'quraan.json');
  final tokensByPage = await _loadQuranTokens(quranPath);

  final dirs = [
    p.join(root, 'assets', 'metadata', 'Quran', 'pages'),
    p.join(root, 'assets', 'metadata', 'Quran', 'pages_colored'),
  ];

  for (final dirPath in dirs) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      stderr.writeln('Directory not found: $dirPath');
      continue;
    }

    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.json'))
            .toList()
          ..sort((a, b) {
            final aIndex = int.tryParse(p.basenameWithoutExtension(a.path));
            final bIndex = int.tryParse(p.basenameWithoutExtension(b.path));
            if (aIndex == null || bIndex == null) {
              return a.path.compareTo(b.path);
            }
            return aIndex.compareTo(bIndex);
          });

    for (final file in files) {
      final content = await file.readAsString();
      final jsonData = json.decode(content);
      if (jsonData is! Map<String, dynamic>) {
        stderr.writeln('Unexpected JSON in ${file.path}');
        continue;
      }

      final pageIndex = (jsonData['pageIndex'] as num?)?.toInt();
      final pageTokens = pageIndex != null
          ? (tokensByPage[pageIndex] ?? const <int, List<_LineToken>>{})
          : const <int, List<_LineToken>>{};

      final lines =
          (jsonData['lines'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      bool modified = false;

      for (final line in lines) {
        final semanticEntries =
            (line['semantic'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
        if (semanticEntries.isEmpty) {
          if (line.containsKey('semanticSpans')) {
            line.remove('semanticSpans');
            modified = true;
          }
          continue;
        }

        final glyphs = _extractGlyphs(line);
        final trimmedGlyphs = _trimTrailingSpaces(glyphs);
        final joined = trimmedGlyphs.join();
        var lineText = joined.isNotEmpty
            ? joined
            : (line['text'] ?? '').toString();
        lineText = lineText.replaceAll('\r', '').replaceAll('\n', '');
        if (lineText.trim().isEmpty) {
          if (line.containsKey('semanticSpans')) {
            line.remove('semanticSpans');
            modified = true;
          }
          continue;
        }

        final collapsed = _CollapsedText.build(lineText);
        if (collapsed.text.isEmpty) {
          if (line.containsKey('semanticSpans')) {
            line.remove('semanticSpans');
            modified = true;
          }
          continue;
        }

        final sortKey = (line['sortKey'] as num?)?.toInt();
        final lineIndex = sortKey != null ? sortKey ~/ 1000 : null;
        final lineTokens = lineIndex != null
            ? (pageTokens[lineIndex] ?? const <_LineToken>[])
            : const <_LineToken>[];
        final tokenRanges = _buildTokenRanges(lineTokens, collapsed);
        final verseTokenMap = _groupTokensByVerse(tokenRanges);

        final usedRanges = <_Range>[];
        final spans = <Map<String, dynamic>>[];
        for (final entry in semanticEntries) {
          final span = _resolveSpanForEntry(
            entry: entry,
            verseTokens: verseTokenMap,
            lineCollapsed: collapsed,
            usedRanges: usedRanges,
            lineMeta: line,
          );
          if (span == null) continue;
          usedRanges.add(span);
          spans.add({
            'start': span.start,
            'length': span.length,
            'tokens': (entry['tokens'] ?? '').toString(),
            'content': (entry['content'] ?? '').toString(),
          });
        }

        if (spans.isEmpty) {
          if (line.containsKey('semanticSpans')) {
            line.remove('semanticSpans');
            modified = true;
          }
        } else {
          line['semanticSpans'] = spans;
          modified = true;
        }
      }

      if (modified) {
        final formatted = const JsonEncoder.withIndent('  ').convert(jsonData);
        await file.writeAsString(formatted);
        stdout.writeln('Updated semantic spans for ${file.path}');
      }
    }
  }
}

Future<Map<int, Map<int, List<_LineToken>>>> _loadQuranTokens(
  String path,
) async {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('quraan.json not found at $path');
    exit(1);
  }

  final raw = await file.readAsString();
  final decoded = json.decode(raw);
  if (decoded is! List) {
    stderr.writeln('Unexpected quraan.json structure');
    exit(1);
  }

  final result = <int, Map<int, List<_LineToken>>>{};
  for (final entry in decoded) {
    if (entry is! Map<String, dynamic>) continue;
    final token = _LineToken.fromJson(entry);
    final pageMap = result.putIfAbsent(
      token.pageIndex,
      () => <int, List<_LineToken>>{},
    );
    final lineList = pageMap.putIfAbsent(token.lineIndex, () => <_LineToken>[]);
    lineList.add(token);
  }

  for (final pageMap in result.values) {
    for (final lineList in pageMap.values) {
      lineList.sort((a, b) {
        final cmpTokenInLine = a.tokenInLineIndex.compareTo(b.tokenInLineIndex);
        if (cmpTokenInLine != 0) return cmpTokenInLine;
        final cmpSurah = a.surahIndex.compareTo(b.surahIndex);
        if (cmpSurah != 0) return cmpSurah;
        final cmpAyah = a.ayahIndex.compareTo(b.ayahIndex);
        if (cmpAyah != 0) return cmpAyah;
        return a.tokenIndex.compareTo(b.tokenIndex);
      });
    }
  }

  return result;
}

List<String> _extractGlyphs(Map<String, dynamic> line) {
  final charsRaw =
      (line['chars'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  if (charsRaw.isNotEmpty) {
    return charsRaw.map((entry) => (entry['t'] ?? '').toString()).toList();
  }
  final fallback = (line['text'] ?? '').toString();
  if (fallback.isEmpty) {
    return const [];
  }
  return fallback.split('');
}

List<_TokenRange> _buildTokenRanges(
  List<_LineToken> tokens,
  _CollapsedText collapsed,
) {
  if (tokens.isEmpty || collapsed.text.isEmpty) {
    return const [];
  }

  final ranges = <_TokenRange>[];
  var searchStart = 0;
  for (final token in tokens) {
    final normalizedToken = _collapseString(token.content);
    if (normalizedToken.isEmpty) continue;

    var index = collapsed.text.indexOf(normalizedToken, searchStart);
    if (index == -1) {
      index = collapsed.text.indexOf(normalizedToken);
    }
    if (index == -1) {
      stderr.writeln(
        'Unable to locate token "${token.content}" on page '
        '${token.pageIndex} line ${token.lineIndex}',
      );
      continue;
    }

    final startOriginal = collapsed.mapping[index];
    final endOriginal =
        collapsed.mapping[index + normalizedToken.length - 1] + 1;
    ranges.add(
      _TokenRange(
        surahIndex: token.surahIndex,
        ayahIndex: token.ayahIndex,
        tokenIndex: token.tokenIndex,
        start: startOriginal,
        end: endOriginal,
      ),
    );
    searchStart = index + normalizedToken.length;
  }
  return ranges;
}

Map<_VerseKey, Map<int, _TokenRange>> _groupTokensByVerse(
  List<_TokenRange> tokens,
) {
  if (tokens.isEmpty) return const {};
  final map = <_VerseKey, Map<int, _TokenRange>>{};
  for (final token in tokens) {
    final key = _VerseKey(token.surahIndex, token.ayahIndex);
    final verseTokens = map.putIfAbsent(key, () => <int, _TokenRange>{});
    verseTokens[token.tokenIndex] = token;
  }
  return map;
}

_Range? _resolveSpanForEntry({
  required Map<String, dynamic> entry,
  required Map<_VerseKey, Map<int, _TokenRange>> verseTokens,
  required _CollapsedText lineCollapsed,
  required List<_Range> usedRanges,
  required Map<String, dynamic> lineMeta,
}) {
  final surah =
      _asInt(entry['surahIndex']) ??
      (lineMeta['surahIndexFirst'] as num?)?.toInt();
  final ayah =
      _asInt(entry['ayahIndex']) ??
      (lineMeta['ayahIndexFirst'] as num?)?.toInt();
  final tokenFrom = _asInt(entry['tokenFromIndex']);
  final tokenTo = _asInt(entry['tokenToIndex']);

  if (surah != null && ayah != null && tokenFrom != null && tokenTo != null) {
    final verseMap = verseTokens[_VerseKey(surah, ayah)];
    if (verseMap != null && verseMap.isNotEmpty) {
      final collected = <_TokenRange>[];
      for (int idx = tokenFrom; idx <= tokenTo; idx++) {
        final tokenRange = verseMap[idx];
        if (tokenRange != null) {
          collected.add(tokenRange);
        }
      }
      if (collected.isNotEmpty) {
        var start = collected.first.start;
        var end = collected.first.end;
        for (final token in collected.skip(1)) {
          if (token.start < start) start = token.start;
          if (token.end > end) end = token.end;
        }
        final candidate = _Range(start, end);
        final overlaps = usedRanges.any(
          (range) =>
              !(candidate.end <= range.start || candidate.start >= range.end),
        );
        if (!overlaps) return candidate;
      }
    }
  }

  final normalizedPhrase = _collapseString((entry['tokens'] ?? '').toString());
  if (normalizedPhrase.isEmpty) {
    return null;
  }

  var searchStart = 0;
  while (true) {
    final index = lineCollapsed.text.indexOf(normalizedPhrase, searchStart);
    if (index == -1) {
      return null;
    }
    final startOriginal = lineCollapsed.mapping[index];
    final endOriginal =
        lineCollapsed.mapping[index + normalizedPhrase.length - 1] + 1;
    final candidate = _Range(startOriginal, endOriginal);
    final overlaps = usedRanges.any(
      (range) =>
          !(candidate.end <= range.start || candidate.start >= range.end),
    );
    if (!overlaps) {
      return candidate;
    }
    searchStart = index + 1;
  }
}

List<String> _trimTrailingSpaces(List<String> chars) {
  var end = chars.length;
  while (end > 0 && _isWhitespace(chars[end - 1])) {
    end--;
  }
  return chars.sublist(0, end);
}

bool _isWhitespace(String value) {
  if (value.isEmpty) return false;
  if (value == ' ' || value == '\u00A0') return true;
  return value.trim().isEmpty;
}

String _collapseString(String input) {
  if (input.isEmpty) return '';
  final buffer = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    final char = input[i];
    if (_isWhitespace(char)) continue;
    buffer.write(char);
  }
  return buffer.toString();
}

class _LineToken {
  final int pageIndex;
  final int lineIndex;
  final int surahIndex;
  final int ayahIndex;
  final int tokenIndex;
  final int tokenInLineIndex;
  final String content;

  const _LineToken({
    required this.pageIndex,
    required this.lineIndex,
    required this.surahIndex,
    required this.ayahIndex,
    required this.tokenIndex,
    required this.tokenInLineIndex,
    required this.content,
  });

  factory _LineToken.fromJson(Map<String, dynamic> json) => _LineToken(
    pageIndex: _asInt(json['pageIndex']) ?? 0,
    lineIndex: _asInt(json['lineIndex']) ?? 0,
    surahIndex: _asInt(json['surahIndex']) ?? 0,
    ayahIndex: _asInt(json['ayahIndex']) ?? 0,
    tokenIndex: _asInt(json['tokenIndex']) ?? 0,
    tokenInLineIndex: _asInt(json['tokenInLineIndex']) ?? 0,
    content: (json['content'] ?? '').toString(),
  );
}

class _TokenRange {
  final int surahIndex;
  final int ayahIndex;
  final int tokenIndex;
  final int start;
  final int end;

  const _TokenRange({
    required this.surahIndex,
    required this.ayahIndex,
    required this.tokenIndex,
    required this.start,
    required this.end,
  });
}

class _Range {
  final int start;
  final int end;

  const _Range(this.start, this.end);

  int get length => end - start;
}

class _CollapsedText {
  final String text;
  final List<int> mapping;

  const _CollapsedText(this.text, this.mapping);

  factory _CollapsedText.build(String input) {
    final mapping = <int>[];
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (_isWhitespace(char)) {
        continue;
      }
      buffer.write(char);
      mapping.add(i);
    }
    return _CollapsedText(buffer.toString(), mapping);
  }
}

class _VerseKey {
  final int surah;
  final int ayah;

  const _VerseKey(this.surah, this.ayah);

  @override
  bool operator ==(Object other) =>
      other is _VerseKey && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
