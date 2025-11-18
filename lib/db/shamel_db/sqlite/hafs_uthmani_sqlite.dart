import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../utils/logger.dart';
import 'model/extra/verse.dart';
import 'model/tajweed.dart';
import 'shamel_sqlite.dart';
import 'sql_constants.dart';

class SQLHafsUthmani {
  static const String databaseName = 'db/hafsuthmani.db';
  static const String databaseLatestVersion = '0.063';

  static const int _maxLoopingError = 5;
  static int _loopingErrors = 0;

  static Future<bool> init(bool isFirstRun) async {
    if (isFirstRun) _loopingErrors = 0;
    if (_loopingErrors > _maxLoopingError) return false;

    final dbDirectory = await getDatabasesPath();
    final dbPath = p.join(dbDirectory, databaseName);
    final dbExists = await databaseExists(dbPath);

    if (!dbExists) {
      IO.printFullText('SQLite :: creating a new copy from bundled asset');
      try {
        await Directory(p.dirname(dbPath)).create(recursive: true);
      } catch (err) {
        IO.printFullText('SQLite :: failed to create directory $err');
      }

      final byteData = await rootBundle.load('assets/$databaseName');
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      await File(dbPath).writeAsBytes(bytes, flush: true);
      _loopingErrors++;
      return init(false);
    }

    IO.printFullText('SQLite :: opening existing database');
    final version = await _getVersion(dbPath);
    IO.printFullText('SQLite :: version $version');

    final currentVersion = double.tryParse(version) ?? 0.0;
    final expectedVersion = double.tryParse(databaseLatestVersion) ?? 0.0;
    if (currentVersion != expectedVersion) {
      IO.printFullText(
        'SQLite :: expected version $databaseLatestVersion, deleting old copy',
      );
      await deleteDatabase(dbPath);
      _loopingErrors++;
      return init(false);
    }

    return true;
  }

  static Future<String> _getVersion(String path) async {
    try {
      final db = await openDatabase(path, readOnly: true);
      final rows = await db.rawQuery('SELECT version FROM version');
      if (rows.isNotEmpty) {
        return rows.first[SQL_IO.COLUMN_version]?.toString() ?? '0';
      }
    } catch (_) {
      IO.printFullText('SQLite :: failed to read version table');
    }
    return '0';
  }

  static Future<List<List<TajweedModel>>> getTajweedPage(
    String tableIndexName,
    int pageIndex,
  ) async {
    final dbDirectory = await getDatabasesPath();
    final dbPath = p.join(dbDirectory, databaseName);
    final dbExists = await databaseExists(dbPath);
    if (!dbExists) return [];

    final List<VerseModel> verses = await SQLHelper.getVerses(
      tableIndexName,
      pageIndex,
    );
    if (verses.isEmpty) return [];

    final whereQuery = verses
        .map(
          (verse) =>
              '( t.surahIndex = ${verse.surahIndex} AND t.ayahIndex = ${verse.ayahIndex} )',
        )
        .join(' OR ');

    final selectStatement =
        '''
SELECT
  t.id,
  t.lineId,
  t.tokenInLineIndex,
  t.surahIndex,
  t.ayahIndex,
  t.tokenIndex,
  t.content AS token,
  r.startIndex,
  r.endIndex,
  r.startIndexInToken,
  r.endIndexInToken,
  r.character,
  r.isRelatedWithNextToken,
  r.isRelatedWithPreviousToken,
  c.id AS colorId,
  c.name,
  c.color,
  l.type,
  l.content AS verse
FROM tokens t
INNER JOIN rules r ON r.tokenId = t.id
INNER JOIN colors c ON c.id = r.colorId
INNER JOIN lines l ON l.id = t.lineId
WHERE $whereQuery
ORDER BY t.id, c.id, r.startIndex ASC
''';

    try {
      final db = await openDatabase(dbPath, readOnly: true);
      final rows = await db.rawQuery(selectStatement);
      return _groupRules(rows);
    } catch (err) {
      IO.printFullText('SQLite :: error while fetching tajweed page $err');
      return [];
    }
  }

  static Future<List<List<TajweedModel>>> getTajweedVerse(
    String tableIndexName,
    int surahIndex,
    int ayahIndex,
  ) async {
    IO.printFullText(
      'SQLite :: getTajweedVerse($tableIndexName, $surahIndex, $ayahIndex)',
    );
    final dbDirectory = await getDatabasesPath();
    final dbPath = p.join(dbDirectory, databaseName);
    final dbExists = await databaseExists(dbPath);
    if (!dbExists) return [];

    const selectStatement = '''
SELECT
  t.id,
  t.lineId,
  t.tokenInLineIndex,
  t.surahIndex,
  t.ayahIndex,
  t.tokenIndex,
  t.content AS token,
  r.startIndex,
  r.endIndex,
  r.startIndexInToken,
  r.endIndexInToken,
  r.character,
  r.isRelatedWithNextToken,
  r.isRelatedWithPreviousToken,
  c.id AS colorId,
  c.name,
  c.color,
  l.type,
  l.content AS verse
FROM tokens t
INNER JOIN rules r ON r.tokenId = t.id
INNER JOIN colors c ON c.id = r.colorId
INNER JOIN lines l ON l.id = t.lineId
WHERE t.surahIndex = ? AND t.ayahIndex = ?
ORDER BY t.id, c.id, r.startIndex ASC
''';

    try {
      final db = await openDatabase(dbPath, readOnly: true);
      final rows = await db.rawQuery(selectStatement, [surahIndex, ayahIndex]);
      return _groupRules(rows);
    } catch (err) {
      IO.printFullText('SQLite :: error while fetching tajweed verse $err');
      return [];
    }
  }

  static List<List<TajweedModel>> _groupRules(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return [];

    final List<List<TajweedModel>> grouped = [];
    List<TajweedModel> currentTokenModels = [];
    int? currentTokenId;

    for (final row in rows) {
      final model = TajweedModel.fromJson(row);
      if (model.colorId == SQL_IO.Goneh_Rule_v6_ID &&
          model.startIndexInToken == 0) {
        model.colorId = SQL_IO.EdgamMutaseel_Rule_v6_ID;
      }

      if (currentTokenId != null && model.tokenId != currentTokenId) {
        grouped.add(
          removeErrorRule(List<TajweedModel>.from(currentTokenModels)),
        );
        currentTokenModels = [];
      }

      currentTokenModels.add(model);
      currentTokenId = model.tokenId;
    }

    if (currentTokenModels.isNotEmpty) {
      grouped.add(removeErrorRule(currentTokenModels));
    }

    return grouped;
  }

  static Future<bool> hasTajweedVerse(
    String tableIndexName,
    int surahIndex,
    int ayahIndex,
  ) async {
    IO.printFullText(
      'SQLite :: hasTajweedVerse($tableIndexName, $surahIndex, $ayahIndex)',
    );
    final dbDirectory = await getDatabasesPath();
    final dbPath = p.join(dbDirectory, databaseName);
    final dbExists = await databaseExists(dbPath);
    if (!dbExists) return false;

    const query = '''
SELECT COUNT(*) AS count
FROM tokens t
INNER JOIN rules r ON r.tokenId = t.id
INNER JOIN colors c ON c.id = r.colorId
INNER JOIN lines l ON l.id = t.lineId
WHERE t.surahIndex = ? AND t.ayahIndex = ?
''';

    try {
      final db = await openDatabase(dbPath, readOnly: true);
      final rows = await db.rawQuery(query, [surahIndex, ayahIndex]);
      if (rows.isEmpty) return false;
      final count =
          int.tryParse(rows.first[SQL_IO.COLUMN_count]?.toString() ?? '0') ?? 0;
      return count > 0;
    } catch (err) {
      IO.printFullText('SQLite :: error while checking tajweed count $err');
      return false;
    }
  }

  static List<TajweedModel> removeErrorRule(List<TajweedModel> models) {
    if (models.isEmpty) return models;

    final filtered = <TajweedModel>[];
    for (final model in models) {
      final hasConflict = models.any(
        (other) =>
            model != other &&
            model.tokenId == other.tokenId &&
            model.startIndexInLine == other.startIndexInLine &&
            model.endIndexInLine == other.endIndexInLine &&
            (model.colorId ?? 0) < (other.colorId ?? 0),
      );
      if (!hasConflict) {
        filtered.add(model);
      }
    }

    filtered.sort((a, b) {
      final startComparison =
          (a.startIndexInLine ?? 0) - (b.startIndexInLine ?? 0);
      if (startComparison != 0) return startComparison;
      return (b.endIndexInLine ?? 0) - (a.endIndexInLine ?? 0);
    });

    return filtered;
  }

  static Future<List<Map<String, Object?>>?> getSurahListNames({
    required String pageNumber,
  }) async {
    try {
      final dbDirectory = await getDatabasesPath();
      final dbPath = p.join(dbDirectory, databaseName);
      final dbExists = await databaseExists(dbPath);
      if (!dbExists) return [{}];

      final db = await openDatabase(dbPath, readOnly: true);
      final data = await db.query('lines', where: 'pageIndex = $pageNumber');
      return data;
    } catch (err) {
      IO.printFullText('SQLite :: failed to fetch surah list $err');
      return null;
    }
  }
}
