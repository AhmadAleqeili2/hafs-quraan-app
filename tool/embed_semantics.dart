import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Merges semantic explanations from the SQLite database into the
/// corresponding `assets/metadata/Quran/pages_colored/<page>.json` files.
///
/// Run with:
///   dart run tool/embed_semantics.dart
///
/// The script requires read/write access to the assets directory and a local
/// copy of the SQLite database (`assets/db/shamel.db`).
Future<void> main() async {
  final projectRoot = Directory.current.path;
  final pagesDir = p.join(projectRoot, 'assets', 'metadata', 'Quran', 'pages');
  final pagesColoredDir = p.join(
    projectRoot,
    'assets',
    'metadata',
    'Quran',
    'pages_colored',
  );
  final dbPath = p.join(projectRoot, 'assets', 'db', 'shamel.db');

  final dbFile = File(dbPath);
  if (!dbFile.existsSync()) {
    stderr.writeln('Database not found at $dbPath');
    exit(1);
  }

  final sqlite = sqlite3.open(dbPath);
  try {
    final pageFiles =
        Directory(pagesDir)
            .listSync()
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.json'))
            .toList()
          ..sort((a, b) {
            final aName = p.basenameWithoutExtension(a.path);
            final bName = p.basenameWithoutExtension(b.path);
            final aIndex = int.tryParse(aName);
            final bIndex = int.tryParse(bName);
            if (aIndex == null || bIndex == null) {
              return aName.compareTo(bName);
            }
            return aIndex.compareTo(bIndex);
          });

    for (final file in pageFiles) {
      final fileName = p.basenameWithoutExtension(file.path);
      final pageNumber = int.tryParse(fileName);
      if (pageNumber == null) {
        continue;
      }
      final semanticRows = sqlite.select(
        '''
        SELECT
          s.tokens,
          s.content,
          s.tokenFromIndex,
          s.tokenToIndex,
          v.surahIndex,
          v.ayahIndex
        FROM semantics s
        INNER JOIN verses v ON v.id = s.verseId
        INNER JOIN index_madinah i
          ON i.surahIndex = v.surahIndex
         AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex
        WHERE i.pageIndex = ?
        ORDER BY v.surahIndex, v.ayahIndex, s.tokenFromIndex
        ''',
        [pageNumber],
      );

      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final row in semanticRows) {
        final surah = row['surahIndex']?.toString() ?? '';
        final ayah = row['ayahIndex']?.toString() ?? '';
        if (surah.isEmpty || ayah.isEmpty) continue;

        final key = '$surah:$ayah';
        grouped.putIfAbsent(key, () => []).add({
          'tokens': (row['tokens'] ?? '').toString(),
          'content': (row['content'] ?? '').toString(),
          'tokenFromIndex': _asInt(row['tokenFromIndex']),
          'tokenToIndex': _asInt(row['tokenToIndex']),
          'surahIndex': _asInt(row['surahIndex']),
          'ayahIndex': _asInt(row['ayahIndex']),
        });
      }

      for (final targetDir in [pagesDir, pagesColoredDir]) {
        final pageFile = File(p.join(targetDir, '$pageNumber.json'));
        if (!pageFile.existsSync()) {
          continue;
        }

        final jsonData = json.decode(await pageFile.readAsString());
        if (jsonData is! Map<String, dynamic>) {
          stderr.writeln('Unexpected JSON structure in ${pageFile.path}');
          continue;
        }

        final lines =
            (jsonData['lines'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final line in lines) {
          final surah = (line['surahIndexFirst'] as num?)?.toInt();
          final ayah = (line['ayahIndexFirst'] as num?)?.toInt();
          if (surah == null || ayah == null) continue;

          final key = '$surah:$ayah';
          final matches = grouped[key];
          if (matches == null || matches.isEmpty) {
            line.remove('semantic');
            continue;
          }
          line['semantic'] = matches;
        }

        await pageFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(jsonData),
        );
      }

      stdout.writeln('Updated page $pageNumber');
    }
  } finally {
    sqlite.dispose();
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
