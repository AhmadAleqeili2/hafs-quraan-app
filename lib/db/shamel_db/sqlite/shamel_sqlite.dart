import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../utils/arabic_special_token.dart';
import '../utils/arabic_text.dart';
import '../utils/language_util.dart';
import '../utils/logger.dart';
import '../utils/search_text.dart';
import 'model/dictionary.dart';
import 'model/extra/khatma.dart';
import 'model/extra/token.dart';
import 'model/extra/verse.dart';
import 'model/grammar.dart';
import 'model/index/hizb.dart';
import 'model/index/juzaa.dart';
import 'model/index/page.dart';
import 'model/index/search.dart';
import 'model/index/surah.dart';
import 'model/location.dart';
import 'model/maqraa/surah.dart';
import 'model/reason.dart';
import 'model/semantic.dart';
import 'model/similarities.dart';
import 'model/substantive.dart';
import 'model/tafseer.dart';
import 'model/translate.dart';
import 'sql_constants.dart';

class SQLHelper {
  static const String DATABASE_NAME = 'db/shamel.db';
  static const String DATABASE_LATEST_VERSION = '7.05';

  static int loopingError = 0;
  static const int maxLoopingError = 5;

  static Future<bool> init(bool isFirstUp) async {
    if (isFirstUp) loopingError = 0;
    if (loopingError > maxLoopingError) return false;
    //IO.printFullText('SQlite :: loopingError ${loopingError}');

    var dbDirectory = await getDatabasesPath();
    //IO.printFullText('SQlite :: dbDirectory ${dbDirectory}');

    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    //IO.printFullText('SQlite :: dbPath ${dbPath}');

    var dbExists = await databaseExists(dbPath);
    //IO.printFullText('SQlite :: dbExists ${dbExists}');

    if (!dbExists) {
      IO.printFullText('SQlite :: Creating new copy from asset');

      try {
        await Directory(p.dirname(dbPath)).create(recursive: true);
        IO.printFullText('SQlite :: Directory created');
      } catch (err) {
        IO.printFullText('SQlite :: err ${err}');
      }

      // Copy from asset
      //ByteData? data = await rootBundle.load('assets/db/shamel.db');
      ByteData data = await rootBundle.load('assets/$DATABASE_NAME');
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      // Copy DataBase
      var nFile = await File(dbPath).writeAsBytes(bytes, flush: true);
      IO.printFullText('SQlite :: nFile ${nFile.path}');
      loopingError++;
      return init(false);
    } else {
      IO.printFullText('SQlite :: Opening existing database');

      String nVersion = await getVersion(dbPath);
      IO.printFullText('SQlite :: Version ${nVersion}');

      double nVersionNum = double.parse(nVersion) ?? 0.0;
      double nLatestVersionNum = double.parse(DATABASE_LATEST_VERSION) ?? 0.0;

      if (nVersionNum != nLatestVersionNum) {
        IO.printFullText(
          'SQlite :: DATABASE_LATEST_VERSION ${DATABASE_LATEST_VERSION}',
        );
        await deleteDatabase(dbPath);
        loopingError++;
        return init(false);
      }

      return true;
    }
  }

  static Future<String> getVersion(String path) async {
    String nVersion = '0';
    try {
      Database db = await openDatabase(path, readOnly: true);
      List<Map<String, Object?>> rows = await db.rawQuery(
        'SELECT version FROM version',
        [],
      );
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row['version'] ?? '0'}');
          nVersion = row[SQL_IO.COLUMN_version].toString() ?? '0';
          break;
        }
      }
    } catch (err) {}
    return nVersion;
  }

  static Future<List<TafseerModel>> getTafseerPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<TafseerModel> models = <TafseerModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery += ' , t.verseId, t.tafsserCode, t.tafsserText';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN tafseer t ON t.verseId = v.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY v.id ASC ;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      TafseerModel? tmpModel;
      int tmpSurahIndex = 0;
      int tmpAyahIndex = 0;
      if (rows.isNotEmpty) {
        for (var row in rows) {
          int nSurahIndex = int.parse(row[SQL_IO.COLUMN_surahIndex].toString());
          int nAyahIndex = int.parse(row[SQL_IO.COLUMN_ayahIndex].toString());

          //IO.printFullText('SQlite :: ');
          //IO.printFullText('SQlite :: tmpSurahIndex ${tmpSurahIndex}');
          //IO.printFullText('SQlite :: tmpAyahIndex ${tmpAyahIndex}');
          //IO.printFullText('SQlite :: nSurahIndex ${nSurahIndex}');
          //IO.printFullText('SQlite :: nAyahIndex ${nAyahIndex}');

          if (tmpSurahIndex != nSurahIndex || tmpAyahIndex != nAyahIndex) {
            if (tmpModel != null) {
              //IO.printFullText('SQlite :: ADD tmpModel ${tmpModel.toString()}');
              models.add(tmpModel);
              tmpModel = null;
            }
          }

          tmpModel ??= TafseerModel.fromJson(row);

          TafseerLanguageModel nTafseerLanguageModel = TafseerLanguageModel(
            row[SQL_IO.COLUMN_tafsserCode].toString(),
            row[SQL_IO.COLUMN_tafsserText].toString(),
          );
          //IO.printFullText('SQlite :: nTafseerLanguageModel ${nTafseerLanguageModel.toString()}');
          tmpModel.addData(nTafseerLanguageModel);

          tmpSurahIndex = nSurahIndex;
          tmpAyahIndex = nAyahIndex;

          // TODO
          //IO.printFullText('SQlite :: row ${row}');
          //TafseerModel nModel = TafseerModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          //models.add(nModel);
        }

        if (tmpModel != null) {
          //IO.printFullText('SQlite :: ADD tmpModel ${tmpModel.toString()}');
          models.add(tmpModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<TafseerModel>> getTafseerVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<TafseerModel> models = <TafseerModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery += ' , t.verseId, t.tafsserCode, t.tafsserText';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN tafseer t ON t.verseId = v.id';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      TafseerModel? tmpModel;
      int tmpSurahIndex = 0;
      int tmpAyahIndex = 0;
      if (rows.isNotEmpty) {
        for (var row in rows) {
          int nSurahIndex = int.parse(row[SQL_IO.COLUMN_surahIndex].toString());
          int nAyahIndex = int.parse(row[SQL_IO.COLUMN_ayahIndex].toString());

          // IO.printFullText('SQlite :: ');
          // IO.printFullText('SQlite :: tmpSurahIndex ${tmpSurahIndex}');
          // IO.printFullText('SQlite :: tmpAyahIndex ${tmpAyahIndex}');
          // IO.printFullText('SQlite :: nSurahIndex ${nSurahIndex}');
          // IO.printFullText('SQlite :: nAyahIndex ${nAyahIndex}');

          if (tmpSurahIndex != nSurahIndex || tmpAyahIndex != nAyahIndex) {
            if (tmpModel != null) {
              // IO.printFullText('SQlite :: ADD tmpModel ${tmpModel.toString()}');
              models.add(tmpModel);
              tmpModel = null;
            }
          }

          tmpModel ??= TafseerModel.fromJson(row);

          TafseerLanguageModel nTafseerLanguageModel = TafseerLanguageModel(
            row[SQL_IO.COLUMN_tafsserCode].toString(),
            row[SQL_IO.COLUMN_tafsserText].toString(),
          );
          //IO.printFullText('SQlite :: nTafseerLanguageModel ${nTafseerLanguageModel.toString()}');
          tmpModel.addData(nTafseerLanguageModel);

          tmpSurahIndex = nSurahIndex;
          tmpAyahIndex = nAyahIndex;

          // TODO
          //IO.printFullText('SQlite :: row ${row}');
          //TafseerModel nModel = TafseerModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          //models.add(nModel);
        }

        if (tmpModel != null) {
          // IO.printFullText('SQlite :: ADD tmpModel ${tmpModel.toString()}');
          models.add(tmpModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<TranslateModel>> getTranslatePage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<TranslateModel> models = <TranslateModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery += ' , t.verseId, t.languageCode, t.translateText';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN translateVerses t ON t.verseId = v.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      TranslateModel? tmpModel;
      int tmpSurahIndex = 0;
      int tmpAyahIndex = 0;
      if (rows.isNotEmpty) {
        for (var row in rows) {
          int nSurahIndex = int.parse(row[SQL_IO.COLUMN_surahIndex].toString());
          int nAyahIndex = int.parse(row[SQL_IO.COLUMN_ayahIndex].toString());

          //IO.printFullText('SQlite :: ');
          //IO.printFullText('SQlite :: tmpSurahIndex ${tmpSurahIndex}');
          //IO.printFullText('SQlite :: tmpAyahIndex ${tmpAyahIndex}');
          //IO.printFullText('SQlite :: nSurahIndex ${nSurahIndex}');
          //IO.printFullText('SQlite :: nAyahIndex ${nAyahIndex}');

          if (tmpSurahIndex != nSurahIndex || tmpAyahIndex != nAyahIndex) {
            if (tmpModel != null) {
              // IO.printFullText('SQlite :: ADD tmpModel ${tmpModel.toString()}');
              models.add(tmpModel);
              tmpModel = null;
            }
          }

          tmpModel ??= TranslateModel.fromJson(row);

          TranslateLanguageModel nTranslateLanguageModel =
              TranslateLanguageModel(
                row[SQL_IO.COLUMN_languageCode].toString(),
                row[SQL_IO.COLUMN_translateText].toString(),
              );
          //IO.printFullText('SQlite :: nTranslateLanguageModel ${nTranslateLanguageModel.toString()}');
          tmpModel.addData(nTranslateLanguageModel);

          tmpSurahIndex = nSurahIndex;
          tmpAyahIndex = nAyahIndex;

          // TODO
          //IO.printFullText('SQlite :: row ${row}');
          //TranslateModel nModel = TranslateModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          //models.add(nModel);
        }

        if (tmpModel != null) {
          // IO.printFullText('SQlite :: ADD tmpModel ${tmpModel.toString()}');
          models.add(tmpModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<VerseModel>> getLastVerseInPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<VerseModel> models = <VerseModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex, v.tokensCount';
    cQuery += ' , q.verseId, q.verseHafs, q.verseUthmani';
    cQuery += ' , s.displayName';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY q.id DESC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          VerseModel nModel = VerseModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
          break;
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err $err');
    }

    return models;
  }

  static Future<List<TranslateModel>> getTranslateVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<TranslateModel> models = <TranslateModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery += ' , t.verseId, t.languageCode, t.translateText';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN translateVerses t ON t.verseId = v.id';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      TranslateModel? tmpModel;
      int tmpSurahIndex = 0;
      int tmpAyahIndex = 0;
      if (rows.isNotEmpty) {
        for (var row in rows) {
          int nSurahIndex = int.parse(row[SQL_IO.COLUMN_surahIndex].toString());
          int nAyahIndex = int.parse(row[SQL_IO.COLUMN_ayahIndex].toString());

          //IO.printFullText('SQlite :: ');
          //IO.printFullText('SQlite :: tmpSurahIndex ${tmpSurahIndex}');
          //IO.printFullText('SQlite :: tmpAyahIndex ${tmpAyahIndex}');
          //IO.printFullText('SQlite :: nSurahIndex ${nSurahIndex}');
          //IO.printFullText('SQlite :: nAyahIndex ${nAyahIndex}');

          if (tmpSurahIndex != nSurahIndex || tmpAyahIndex != nAyahIndex) {
            if (tmpModel != null) {
              // IO.printFullText('SQlite :: ADD tmpModel ${tmpModel.toString()}');
              models.add(tmpModel);
              tmpModel = null;
            }
          }

          tmpModel ??= TranslateModel.fromJson(row);

          TranslateLanguageModel nTranslateLanguageModel =
              TranslateLanguageModel(
                row[SQL_IO.COLUMN_languageCode].toString(),
                row[SQL_IO.COLUMN_translateText].toString(),
              );
          //IO.printFullText('SQlite :: nTranslateLanguageModel ${nTranslateLanguageModel.toString()}');
          tmpModel.addData(nTranslateLanguageModel);

          tmpSurahIndex = nSurahIndex;
          tmpAyahIndex = nAyahIndex;

          // TODO
          //IO.printFullText('SQlite :: row ${row}');
          //TranslateModel nModel = TranslateModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          //models.add(nModel);
        }

        if (tmpModel != null) {
          // IO.printFullText('SQlite :: ADD tmpModel ${tmpModel.toString()}');
          models.add(tmpModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<SemanticModel>> getSemanticPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<SemanticModel> models = <SemanticModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery +=
        ' , s.verseId, s.tokenFromIndex, s.tokenToIndex, s.tokens, s.content';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN semantics s ON s.verseId = v.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SemanticModel nModel = SemanticModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          nModel.verseHafs = await getTokenHafs(
            nModel.verseHafs!,
            nModel.tokenFromIndex!,
            nModel.tokenToIndex!,
          );
          nModel.verseUthmani = await getTokenHafs(
            nModel.verseUthmani!,
            nModel.tokenFromIndex!,
            nModel.tokenToIndex!,
          );
          models.add(nModel);
        }
      }
    } catch (err) {}

    return models;
  }

  static Future<List<SemanticModel>> getSemanticVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<SemanticModel> models = <SemanticModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery +=
        ' , s.verseId, s.tokenFromIndex, s.tokenToIndex, s.tokens, s.content';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN semantics s ON s.verseId = v.id';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SemanticModel nModel = SemanticModel.fromJson(row);
          nModel.verseHafs = await getTokenHafs(
            nModel.verseHafs!,
            nModel.tokenFromIndex!,
            nModel.tokenToIndex!,
          );
          nModel.verseUthmani = await getTokenHafs(
            nModel.verseUthmani!,
            nModel.tokenFromIndex!,
            nModel.tokenToIndex!,
          );
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<SemanticModel>> getSemanticToken(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
    int cTokenIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<SemanticModel> models = <SemanticModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery +=
        ' , s.verseId, s.tokenFromIndex, s.tokenToIndex, s.tokens, s.content';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery +=
        ' INNER JOIN semantics s ON s.verseId = v.id AND ? BETWEEN s.tokenFromIndex AND s.tokenToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [
        cTokenIndex,
        cSurahIndex,
        cAyahIndex,
      ]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SemanticModel nModel = SemanticModel.fromJson(row);
          nModel.verseHafs = await getTokenHafs(
            nModel.verseHafs!,
            nModel.tokenFromIndex!,
            nModel.tokenToIndex!,
          );
          nModel.verseUthmani = await getTokenHafs(
            nModel.verseUthmani!,
            nModel.tokenFromIndex!,
            nModel.tokenToIndex!,
          );
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<bool> hasSemanticVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    if (!dbExists) return false;

    String cQuery = 'SELECT';
    cQuery += ' COUNT(*) as count';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN semantics s ON s.verseId = v.id';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          try {
            int count = int.parse(row[SQL_IO.COLUMN_count].toString());
            return count > 0;
          } catch (err) {
            return false;
          }
        }
      }
    } catch (err) {}

    return false;
  }

  static Future<bool> hasSemanticToken(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
    int cTokenIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    if (!dbExists) return false;

    String cQuery = 'SELECT';
    cQuery += ' COUNT(*) as count';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery +=
        ' INNER JOIN semantics s ON s.verseId = v.id AND ? BETWEEN s.tokenFromIndex AND s.tokenToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [
        cTokenIndex,
        cSurahIndex,
        cAyahIndex,
      ]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          try {
            int count = int.parse(row[SQL_IO.COLUMN_count].toString());
            return count > 0;
          } catch (err) {
            return false;
          }
        }
      }
    } catch (err) {}

    return false;
  }

  static Future<List<SubstantiveModel>> getSubstantivePage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<SubstantiveModel> models = <SubstantiveModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT DISTINCT';
    cQuery += ' s.verseIdFrom, s.verseIdTo, s.color, s.detail';
    cQuery += ' , i.pageIndex';
    cQuery += ' , v.surahIndex';
    cQuery +=
        ' , (select group_concat(q.verseHafs,\' \') from quran q WHERE q.verseId BETWEEN s.verseIdFrom AND s.verseIdTo) verseHafs';
    cQuery +=
        ' , (select group_concat(q.verseUthmani,\' \') from quran q WHERE q.verseId BETWEEN s.verseIdFrom AND s.verseIdTo) verseUthmani';
    cQuery +=
        ' , (select vv.ayahIndex from verses vv WHERE vv.id = s.verseIdFrom) verseFromIndex';
    cQuery +=
        ' , (select vv.ayahIndex from verses vv WHERE vv.id = s.verseIdTo) verseToIndex';
    cQuery += ' , ss.displayName';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery +=
        ' INNER JOIN substantive s ON v.id BETWEEN s.verseIdFrom AND s.verseIdTo';
    cQuery += ' INNER JOIN surah ss ON ss.surahIndex = v.surahIndex';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY s.id ASC';

    //IO.printFullText(cQuery);

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SubstantiveModel nModel = SubstantiveModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<SubstantiveModel>> getSubstantiveVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<SubstantiveModel> models = <SubstantiveModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT DISTINCT';
    cQuery += ' s.verseIdFrom, s.verseIdTo, s.color, s.detail';
    cQuery += ' , i.pageIndex';
    cQuery += ' , v.surahIndex';
    cQuery +=
        ' , (select group_concat(q.verseHafs,\' \') from quran q WHERE q.verseId BETWEEN s.verseIdFrom AND s.verseIdTo) verseHafs';
    cQuery +=
        ' , (select group_concat(q.verseUthmani,\' \') from quran q WHERE q.verseId BETWEEN s.verseIdFrom AND s.verseIdTo) verseUthmani';
    cQuery +=
        ' , (select vv.ayahIndex from verses vv WHERE vv.id = s.verseIdFrom) verseFromIndex';
    cQuery +=
        ' , (select vv.ayahIndex from verses vv WHERE vv.id = s.verseIdTo) verseToIndex';
    cQuery += ' , ss.displayName';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery +=
        ' INNER JOIN substantive s ON v.id BETWEEN s.verseIdFrom AND s.verseIdTo';
    cQuery += ' INNER JOIN surah ss ON ss.surahIndex = v.surahIndex';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SubstantiveModel nModel = SubstantiveModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {}

    return models;
  }

  static Future<List<SimilarityModel>> getSimilaritiesPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<SimilarityModel> models = <SimilarityModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' tokens_info.tokensId, tokens.tokensLength, tokens.count';
    cQuery += ' , tokens.tokensArabic, tokens.tokensUthmani, tokens.tokensHafs';
    // -- i.pageIndex
    // -- , v.surahIndex, v.ayahIndex
    // -- , tokens.tokensLength, tokens.count, tokens.tokensArabic
    // -- , tokens_info.verseId, tokens_info.tokensId, tokens_info.tokenStartIndex, tokens_info.tokenEndIndex, tokens_info.tokensLength
    // -- , tokens.tokensUthmani, tokens.tokensHafs
    // -- , q.verseHafs, q.verseUthmani
    // -- , ss.displayName
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery +=
        ' INNER JOIN similarities_tokens_info tokens_info ON tokens_info.verseId = v.id';
    cQuery +=
        ' INNER JOIN similarities_tokens tokens ON tokens_info.tokensId = tokens.id';
    //cQuery += ' INNER JOIN surah ss ON ss.surahIndex = v.surahIndex';
    cQuery += ' WHERE i.pageIndex = ?';
    //cQuery += ' ORDER BY v.id ASC;';
    cQuery += ' ORDER BY v.id ASC, tokens_info.tokenStartIndex ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SimilarityModel nModel = SimilarityModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          //nModel.verseHafs = await getTokenHafs(nModel.verseHafs!, nModel.tokenFromIndex!, nModel.tokenToIndex!);
          //nModel.verseUthmani = await getTokenHafs(nModel.verseUthmani!, nModel.tokenFromIndex!, nModel.tokenToIndex!);
          models.add(nModel);
        }
      }
    } catch (err) {}

    return models;
  }

  static Future<List<SimilarityModel>> getSimilaritiesVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<SimilarityModel> models = <SimilarityModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' tokens_info.tokensId, tokens.tokensLength, tokens.count';
    cQuery += ' , tokens.tokensArabic, tokens.tokensUthmani, tokens.tokensHafs';
    // -- i.pageIndex
    // -- , v.surahIndex, v.ayahIndex
    // -- , tokens.tokensLength, tokens.count, tokens.tokensArabic
    // -- , tokens_info.verseId, tokens_info.tokensId, tokens_info.tokenStartIndex, tokens_info.tokenEndIndex, tokens_info.tokensLength
    // -- , tokens.tokensUthmani, tokens.tokensHafs
    // -- , q.verseHafs, q.verseUthmani
    // -- , ss.displayName
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery +=
        ' INNER JOIN similarities_tokens_info tokens_info ON tokens_info.verseId = v.id';
    cQuery +=
        ' INNER JOIN similarities_tokens tokens ON tokens_info.tokensId = tokens.id';
    //cQuery += ' INNER JOIN surah ss ON ss.surahIndex = v.surahIndex';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    // cQuery += ' ORDER BY v.id ASC;';
    cQuery += ' ORDER BY v.id ASC, tokens_info.tokenStartIndex ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SimilarityModel nModel = SimilarityModel.fromJson(row);
          //nModel.verseHafs = await getTokenHafs(nModel.verseHafs!, nModel.tokenFromIndex!, nModel.tokenToIndex!);
          //nModel.verseUthmani = await getTokenHafs(nModel.verseUthmani!, nModel.tokenFromIndex!, nModel.tokenToIndex!);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<bool> hasSimilaritiesVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    if (!dbExists) return false;

    String cQuery = 'SELECT';
    cQuery += ' COUNT(*) as count';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery +=
        ' INNER JOIN similarities_tokens_info tokens_info ON tokens_info.verseId = v.id';
    cQuery +=
        ' INNER JOIN similarities_tokens tokens ON tokens_info.tokensId = tokens.id';
    //cQuery += ' INNER JOIN surah ss ON ss.surahIndex = v.surahIndex';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    // cQuery += ' ORDER BY v.id ASC;';
    cQuery += ' ORDER BY v.id ASC, tokens_info.tokenStartIndex ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          try {
            int count = int.parse(row[SQL_IO.COLUMN_count].toString());
            return count > 0;
          } catch (err) {
            return false;
          }
        }
      }
    } catch (err) {}

    return false;
  }

  static Future<List<SimilarityModel>> getSimilaritiesToken(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
    int cTokenIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<SimilarityModel> models = <SimilarityModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' tokens_info.tokensId, tokens.tokensLength, tokens.count';
    cQuery += ' , tokens.tokensArabic, tokens.tokensUthmani, tokens.tokensHafs';
    // -- i.pageIndex
    // -- , v.surahIndex, v.ayahIndex
    // -- , tokens.tokensLength, tokens.count, tokens.tokensArabic
    // -- , tokens_info.verseId, tokens_info.tokensId, tokens_info.tokenStartIndex, tokens_info.tokenEndIndex, tokens_info.tokensLength
    // -- , tokens.tokensUthmani, tokens.tokensHafs
    // -- , q.verseHafs, q.verseUthmani
    // -- , ss.displayName
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery +=
        ' INNER JOIN similarities_tokens_info tokens_info ON tokens_info.verseId = v.id AND ? BETWEEN tokens_info.tokenStartIndex AND tokens_info.tokenEndIndex';
    cQuery +=
        ' INNER JOIN similarities_tokens tokens ON tokens_info.tokensId = tokens.id';
    cQuery += ' INNER JOIN surah ss ON ss.surahIndex = v.surahIndex';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    // cQuery += ' ORDER BY v.id ASC;';
    cQuery += ' ORDER BY v.id ASC, tokens_info.tokenStartIndex ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [
        cTokenIndex,
        cSurahIndex,
        cAyahIndex,
      ]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SimilarityModel nModel = SimilarityModel.fromJson(row);
          //nModel.verseHafs = await getTokenHafs(nModel.verseHafs!, nModel.tokenFromIndex!, nModel.tokenToIndex!);
          //nModel.verseUthmani = await getTokenHafs(nModel.verseUthmani!, nModel.tokenFromIndex!, nModel.tokenToIndex!);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<SimilarityInfoModel>> getSimilarityTokensInfo(
    String cTableIndexName,
    int cTokensId,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<SimilarityInfoModel> models = <SimilarityInfoModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex,v.tokensCount';
    cQuery += ' , tokens_info.verseId, tokens_info.tokensId';
    cQuery += ' , tokens_info.tokenStartIndex, tokens_info.tokenEndIndex';
    cQuery +=
        ' , tokens.tokensLength, tokens.count, tokens.tokensArabic, tokens.tokensUthmani, tokens.tokensHafs';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' , ss.displayName';
    cQuery += ' FROM similarities_tokens_info tokens_info';
    cQuery += ' INNER JOIN verses v ON  v.id = tokens_info.verseId';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN surah ss ON ss.surahIndex = v.surahIndex';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery +=
        ' INNER JOIN similarities_tokens tokens ON tokens_info.tokensId = tokens.id';
    cQuery += ' WHERE tokens_info.tokensId = ?';
    cQuery += ' ORDER BY v.id ASC;';

    // IO.printFullText('SQlite :: cQuery $cQuery');

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cTokensId]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SimilarityInfoModel nModel = SimilarityInfoModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          //nModel.verseHafs = await getTokenHafs(nModel.verseHafs!, nModel.tokenFromIndex!, nModel.tokenToIndex!);
          //nModel.verseUthmani = await getTokenHafs(nModel.verseUthmani!, nModel.tokenFromIndex!, nModel.tokenToIndex!);
          models.add(nModel);
        }
      }
    } catch (err) {}

    return models;
  }

  static Future<List<SimilarityColorModel>> getSimilaritiesColorPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<SimilarityColorModel> models = <SimilarityColorModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT DISTINCT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex,v.tokensCount';
    cQuery += ' , tokens.tokensArabic';
    cQuery += ' , tokens_info.tokenStartIndex, tokens_info.tokenEndIndex';

    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery +=
        ' INNER JOIN similarities_tokens_info tokens_info ON tokens_info.verseId = v.id';
    cQuery +=
        ' INNER JOIN similarities_tokens tokens ON tokens_info.tokensId = tokens.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    // IO.printFullText('SQlite :: cQuery $cQuery');

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SimilarityColorModel nModel = SimilarityColorModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          //nModel.verseHafs = await getTokenHafs(nModel.verseHafs!, nModel.tokenFromIndex!, nModel.tokenToIndex!);
          //nModel.verseUthmani = await getTokenHafs(nModel.verseUthmani!, nModel.tokenFromIndex!, nModel.tokenToIndex!);
          models.add(nModel);
        }
      }
    } catch (err) {}

    return models;
  }

  static Future<List<ReasonModel>> getReasonPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<ReasonModel> models = <ReasonModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery += ' , r.verseId, r.reason, r.shortAyah';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' , s.displayName';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN reasons r ON r.verseId = v.id';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      String? tmpReason;
      String? tmpShortAyah;
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          ReasonModel nModel = ReasonModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          if (nModel.reason != tmpReason && nModel.shortAyah != tmpShortAyah) {
            tmpReason = nModel.reason;
            tmpShortAyah = nModel.shortAyah;
            models.add(nModel);
          }
        }
      }
    } catch (err) {}

    return models;
  }

  static Future<List<ReasonModel>> getReasonVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<ReasonModel> models = <ReasonModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery += ' , r.verseId, r.reason, r.shortAyah';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' , s.displayName';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN reasons r ON r.verseId = v.id';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      //String? tmpReason;
      //String? tmpShortAyah;
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          ReasonModel nModel = ReasonModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          //if (nModel.reason != tmpReason && nModel.shortAyah != tmpShortAyah) {
          //tmpReason = nModel.reason;
          //tmpShortAyah = nModel.shortAyah;
          models.add(nModel);
          //}
        }
      }
    } catch (err) {}

    return models;
  }

  static Future<bool> hasReasonPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    if (!dbExists) return false;

    String cQuery = 'SELECT';
    cQuery += ' COUNT(*) as count';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN reasons r ON r.verseId = v.id';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          try {
            int count = int.parse(row[SQL_IO.COLUMN_count].toString());
            return count > 0;
          } catch (err) {
            return false;
          }
        }
      }
    } catch (err) {}

    return false;
  }

  static Future<bool> hasReasonVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    if (!dbExists) return false;

    String cQuery = 'SELECT';
    cQuery += ' COUNT(*) as count';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN reasons r ON r.verseId = v.id';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          try {
            int count = int.parse(row[SQL_IO.COLUMN_count].toString());
            return count > 0;
          } catch (err) {
            return false;
          }
        }
      }
    } catch (err) {}

    return false;
  }

  static Future<List<DictionaryModel>> getDictionaryPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<DictionaryModel> models = <DictionaryModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery +=
        ' , d.verseId, d.tokenIndex, d.arabEng, d.translation, d.RedWord, d.shortAyah';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN dictionaries d ON d.verseId = v.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          DictionaryModel nModel = DictionaryModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {}

    return models;
  }

  static Future<List<DictionaryModel>> getDictionaryVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<DictionaryModel> models = <DictionaryModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery +=
        ' , d.verseId, d.tokenIndex, d.arabEng, d.translation, d.RedWord, d.shortAyah';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN dictionaries d ON d.verseId = v.id';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          DictionaryModel nModel = DictionaryModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<DictionaryModel>> getDictionaryPage_(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<DictionaryModel> models = <DictionaryModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery +=
        ' , g.verseId, g.tokenIndex, g.arabEng, g.translation, g.image, g.arGrammar, g.enGrammar';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN grammar_tokens g ON g.verseId = v.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      int tmpSurahIndex = 0;
      int tmpAyahIndex = 0;
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          DictionaryModel nModel = DictionaryModel.fromJson(row);
          nModel.redWord = await getToken(
            nModel.verseHafs!,
            nModel.tokenIndex!,
          );
          //nModel.shortAyah = nModel.verseHafs;
          nModel.shortAyah = nModel.verseUthmani;
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');

          if (nModel.surahIndex == tmpSurahIndex &&
              nModel.ayahIndex == tmpAyahIndex) {
            nModel.shortAyah = '';
          }
          tmpSurahIndex = nModel.surahIndex!;
          tmpAyahIndex = nModel.ayahIndex!;

          models.add(nModel);
        }
      }
    } catch (err) {}

    return models;
  }

  static Future<List<DictionaryModel>> getDictionaryVerse_(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<DictionaryModel> models = <DictionaryModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery +=
        ' , g.verseId, g.tokenIndex, g.arabEng, g.translation, g.image, g.arGrammar, g.enGrammar';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN grammar_tokens g ON g.verseId = v.id';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      int tmpSurahIndex = 0;
      int tmpAyahIndex = 0;
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          DictionaryModel nModel = DictionaryModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          nModel.redWord = await getToken(
            nModel.verseHafs!,
            nModel.tokenIndex!,
          );
          //nModel.shortAyah = nModel.verseHafs;
          nModel.shortAyah = nModel.verseUthmani;

          if (nModel.surahIndex == tmpSurahIndex &&
              nModel.ayahIndex == tmpAyahIndex) {
            nModel.shortAyah = '';
          }
          tmpSurahIndex = nModel.surahIndex!;
          tmpAyahIndex = nModel.ayahIndex!;

          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<DictionaryModel>> getDictionaryToken_(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
    int cTokenIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<DictionaryModel> models = <DictionaryModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery +=
        ' , g.verseId, g.tokenIndex, g.arabEng, g.translation, g.image, g.arGrammar, g.enGrammar';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery +=
        ' INNER JOIN grammar_tokens g ON g.verseId = v.id AND g.tokenIndex = ?';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [
        cTokenIndex,
        cSurahIndex,
        cAyahIndex,
      ]);
      int tmpSurahIndex = 0;
      int tmpAyahIndex = 0;
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          DictionaryModel nModel = DictionaryModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          nModel.redWord = await getToken(
            nModel.verseHafs!,
            nModel.tokenIndex!,
          );
          //nModel.shortAyah = nModel.verseHafs;
          nModel.shortAyah = nModel.verseUthmani;

          if (nModel.surahIndex == tmpSurahIndex &&
              nModel.ayahIndex == tmpAyahIndex) {
            nModel.shortAyah = '';
          }
          tmpSurahIndex = nModel.surahIndex!;
          tmpAyahIndex = nModel.ayahIndex!;

          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  /////

  static Future<List<GrammarTokenModel>> getGrammarTokensPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<GrammarTokenModel> models = <GrammarTokenModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery +=
        ' , g.verseId, g.tokenIndex, g.arabEng, g.translation, g.image, g.arGrammar, g.enGrammar';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN grammar_tokens g ON g.verseId = v.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          GrammarTokenModel nModel = GrammarTokenModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {}

    return models;
  }

  static Future<List<GrammarTokenModel>> getGrammarTokensVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<GrammarTokenModel> models = <GrammarTokenModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery +=
        ' , g.verseId, g.tokenIndex, g.arabEng, g.translation, g.image, g.arGrammar, g.enGrammar';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN grammar_tokens g ON g.verseId = v.id';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          GrammarTokenModel nModel = GrammarTokenModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<GrammarGraphModel>> getGrammarGraphsPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<GrammarGraphModel> models = <GrammarGraphModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery +=
        ' , g.verseId, g.startTokenIndex, g.endTokenIndex, g.verseGrammar, g.image';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN grammar_graphs g ON g.verseId = v.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          GrammarGraphModel nModel = GrammarGraphModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {}

    return models;
  }

  static Future<List<GrammarGraphModel>> getGrammarGraphsVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<GrammarGraphModel> models = <GrammarGraphModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery +=
        ' , g.verseId, g.startTokenIndex, g.endTokenIndex, g.verseGrammar, g.image';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN grammar_graphs g ON g.verseId = v.id';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY v.id ASC;';

    //IO.printFullText('SQlite :: cQuery ${cQuery}');

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          GrammarGraphModel nModel = GrammarGraphModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  /////

  static Future<List<GrammarModel>> getGrammarInfoPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    List<GrammarGraphModel> cGraphModels = await getGrammarGraphsPage(
      cTableIndexName,
      cPageIndex,
    );
    List<GrammarTokenModel> cTokenModels = await getGrammarTokensPage(
      cTableIndexName,
      cPageIndex,
    );
    return getGrammarInfoModels(cGraphModels, cTokenModels);
  }

  static Future<List<GrammarModel>> getGrammarInfoVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    List<GrammarGraphModel> cGraphModels = await getGrammarGraphsVerse(
      cTableIndexName,
      cSurahIndex,
      cAyahIndex,
    );
    List<GrammarTokenModel> cTokenModels = await getGrammarTokensVerse(
      cTableIndexName,
      cSurahIndex,
      cAyahIndex,
    );
    return getGrammarInfoModels(cGraphModels, cTokenModels);
  }

  static Future<List<GrammarModel>> getGrammarInfoModels(
    List<GrammarGraphModel> cGraphModels,
    List<GrammarTokenModel> cTokenModels,
  ) async {
    List<GrammarModel> cModels = <GrammarModel>[];
    if (cGraphModels != null &&
        cGraphModels.isNotEmpty &&
        cTokenModels != null &&
        cTokenModels.isNotEmpty) {
      for (
        int cGraphIndex = 0;
        cGraphIndex < cGraphModels.length;
        cGraphIndex++
      ) {
        GrammarGraphModel cGraphModel = cGraphModels[cGraphIndex];
        if ((cGraphModel.verseGrammar != null &&
                cGraphModel.verseGrammar!.trim() != '') ||
            (cGraphModel.image != null && cGraphModel.image!.trim() != '')) {
          GrammarModel cGrammarInfoModel = GrammarModel();
          cGrammarInfoModel.graphModel = cGraphModel;
          cModels.add(cGrammarInfoModel);
          //Log.e('@Grammar', 'Add Graph :: ' + cGraphModel.toString());
        }
        List<GrammarModel> cTmpModels = await getGrammarTokensModels(
          cGraphModel,
          cTokenModels,
        );
        if (cTmpModels != null && cTmpModels.isNotEmpty)
          cModels.addAll(cTmpModels);
      }
    } else
      return cModels;
    return cModels;
  }

  static Future<List<GrammarModel>> getGrammarTokensModels(
    GrammarGraphModel cGraphModel,
    List<GrammarTokenModel> cTokenModels,
  ) async {
    List<GrammarModel> cModels = <GrammarModel>[];
    if (cGraphModel == null) return cModels;
    if (cTokenModels == null || cTokenModels.isEmpty) return cModels;

    for (
      int cTokenIndex = 0;
      cTokenIndex < cTokenModels.length;
      cTokenIndex++
    ) {
      GrammarTokenModel cTokenModel = cTokenModels[cTokenIndex];
      if (cGraphModel.verseId == cTokenModel.verseId) {
        if (cGraphModel.startTokenIndex == 0 &&
            cGraphModel.endTokenIndex == 0) {
          GrammarModel cGrammarInfoModel = GrammarModel();
          cGrammarInfoModel.tokenModel = cTokenModel;
          cModels.add(cGrammarInfoModel);
          //Log.e('@Grammar', 'Add Token :: ' + cTokenModel.toString());
        } else if (cGraphModel.startTokenIndex! <= cTokenModel.tokenIndex! &&
            cGraphModel.endTokenIndex! >= cTokenModel.tokenIndex!) {
          GrammarModel cGrammarInfoModel = GrammarModel();
          cGrammarInfoModel.tokenModel = cTokenModel;
          cModels.add(cGrammarInfoModel);
          //Log.e('@Grammar', 'Add Token :: ' + cTokenModel.toString());
        }
      }
    }
    return cModels;
  }

  /////
  /*
  static Future<List<XXXXXX>> getXXXX(String cTableIndexName, int cPageIndex) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<XXXXXX> models = <XXXXXX>[];
    if (!dbExists) return models;

    String cQuery = XXXX;

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          XXXXXX nModel = XXXXXX.fromJson(row);
          IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {}

    return models;
  }
 */

  // *******

  static Future<List<SearchModel>> getSearchData(
    final String cTableIndexName,
    String cText,
    final int cNumberOfTable,
  ) async {
    IO.printFullText('SQlite :: -- getSearchData ${cText}');
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    //IO.printFullText('SQlite :: dbDirectory  ${dbDirectory}');
    //IO.printFullText('SQlite :: dbPath  ${dbPath}');
    //IO.printFullText('SQlite :: dbExists  ${dbExists}');
    List<SearchModel> models = <SearchModel>[];
    if (!dbExists) return models;
    if (cText.trim() == '') return models;

    List<SearchModel> modelsFirstVerseInSurah = await getSearchSurah(
      cTableIndexName,
      cText,
    );
    List<SearchModel> modelsVerse = await getSearchVerse(
      cTableIndexName,
      cText,
      cNumberOfTable,
    );
    if (null != modelsFirstVerseInSurah && modelsFirstVerseInSurah.isNotEmpty) {
      models.addAll(modelsFirstVerseInSurah);
    }
    if (null != modelsVerse && modelsVerse.isNotEmpty) {
      models.addAll(modelsVerse);
    }
    return models;
  }

  static Future<List<SearchModel>> getSearchVerse(
    final String cTableIndexName,
    String cText,
    final int cNumberOfTable,
  ) async {
    bool isStartWithSpace = cText.startsWith(' ');
    bool isEndWithSpace = cText.endsWith(' ');
    cText = SearchText(
      ArabicText(cText).toCharactersWithoutDiacritics(),
    ).toCleanup();
    cText = '${isStartWithSpace ? ' ' : ''}$cText${isEndWithSpace ? ' ' : ''}';
    IO.printFullText('SQlite :: -- getSearchVerse ${cText}');
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    //IO.printFullText('SQlite :: dbDirectory  ${dbDirectory}');
    //IO.printFullText('SQlite :: dbPath  ${dbPath}');
    //IO.printFullText('SQlite :: dbExists  ${dbExists}');
    List<SearchModel> models = <SearchModel>[];
    if (!dbExists) return models;
    if (cText.trim() == '') return models;

    String cColumnName = '';
    if (cNumberOfTable == 0) {
      cColumnName = 'verseDeep';
    } else if (cNumberOfTable == 1) {
      cColumnName = 'verseGoogle';
    } else if (cNumberOfTable == 2) {
      cColumnName = 'verseTasmee';
    } else {
      cColumnName = 'verseDeep';
    }

    String WhereQuery = '';
    if ((!cText.startsWith(' ')) && (!cText.endsWith(' '))) {
      WhereQuery = ' q.$cColumnName LIKE \'%${cText.trim()}%\'';
    } else if (cText.startsWith(' ') && cText.endsWith(' ')) {
      WhereQuery = ' q.$cColumnName LIKE \'% ${cText.trim()} %\'';
      //WhereQuery += ' OR q.$cColumnName LIKE \'%${cText.trim()} %\'';
      //WhereQuery += ' OR q.$cColumnName LIKE \'% ${cText.trim()}%\'';
    } else if (cText.startsWith(' ') && (!cText.endsWith(' '))) {
      WhereQuery = ' q.$cColumnName LIKE \'% ${cText.trim()}%\'';
      //WhereQuery += ' OR q.$cColumnName LIKE \'%${cText.trim()}%\'';
    } else if ((!cText.startsWith(' ')) && cText.endsWith(' ')) {
      WhereQuery = ' q.$cColumnName LIKE \'%${cText.trim()} %\'';
      //WhereQuery += ' OR q.$cColumnName LIKE \'%${cText.trim()}%\'';
    }

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex, v.tokensCount';
    cQuery +=
        ' , q.verseId, q.verseHafs, q.verseUthmani, q.verseDeep, q.verseTasmee, q.verseGoogle';
    cQuery += ' , s.displayName';
    cQuery += ' FROM quran q';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN verses v ON v.id = q.verseId';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' WHERE $WhereQuery';
    cQuery += ' ORDER BY q.verseId ASC;';

    //IO.printFullText('SQlite :: cQuery ${cQuery}');

    /*
    -- find number of tokens in the verse
    Select
  q.id, q.verseHafs, q.verseUthmani
    -- q.verseUthmani, q.verseDeep
    -- q.verseUthmani, q.verseTasmee
    -- q.verseUthmani, q.verseGoogle
  , v.surahIndex, v.ayahIndex
    from quran q
	INNER JOIN verses v ON v.id = q.verseId
    Where

     ((length(q.verseHafs)-length(replace(q.verseHafs,' ',''))+1)-1) != (length(q.verseUthmani)-length(replace(q.verseUthmani,' ',''))+1)
     -- (length(q.verseUthmani)-length(replace(q.verseUthmani,' ',''))+1) != (length(q.verseDeep)-length(replace(q.verseDeep,' ',''))+1)
    -- (length(q.verseUthmani)-length(replace(q.verseUthmani,' ',''))+1) != (length(q.verseTasmee)-length(replace(q.verseTasmee,' ',''))+1)
    -- (length(q.verseUthmani)-length(replace(q.verseUthmani,' ',''))+1) != (length(q.verseGoogle)-length(replace(q.verseGoogle,' ',''))+1)


    */

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, []);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SearchModel nModel = SearchModel.fromJson(row);

          nModel.searchText = cText;
          nModel.verseDynamicType = cColumnName;
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          if (cNumberOfTable == 1) {
            nModel.verseCleanup = SearchText(
              ArabicText(nModel.verseGoogle!).toCharactersWithoutDiacritics(),
            ).toCleanup();
          } else if (cNumberOfTable == 2) {
            nModel.verseCleanup = SearchText(
              ArabicText(nModel.verseTasmee!).toCharactersWithoutDiacritics(),
            ).toCleanup();
          } else {
            nModel.verseCleanup = SearchText(
              ArabicText(nModel.verseDeep!).toCharactersWithoutDiacritics(),
            ).toCleanup();
          }

          // await nModel.toSplit(cText);

          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<SearchModel>> getSearchSurah(
    final String cTableIndexName,
    String cText,
  ) async {
    if (cText == null) return <SearchModel>[];
    cText = cText.trim();
    var token = cText.split(' ');
    if (token == null || token.length > 2) return <SearchModel>[];
    IO.printFullText('SQlite :: -- getSearchSurah ${cText}');
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    //IO.printFullText('SQlite :: dbDirectory  ${dbDirectory}');
    //IO.printFullText('SQlite :: dbPath  ${dbPath}');
    //IO.printFullText('SQlite :: dbExists  ${dbExists}');
    List<SearchModel> models = <SearchModel>[];
    if (!dbExists) return models;
    if (cText.trim() == '') return models;

    String WhereQuery =
        's.name LIKE \'%${await ArabicSpecialToken.fromVerseGoogleToSurahName(cText)}%\'';

    String cQuery = 'SELECT';
    cQuery += ' s.displayName';
    cQuery += ' , i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex, v.tokensCount';
    cQuery +=
        ' , q.verseId, q.verseHafs, q.verseUthmani, q.verseDeep, q.verseTasmee, q.verseGoogle';
    cQuery += ' FROM surah s';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = s.surahIndex AND v.ayahIndex = 1';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' WHERE $WhereQuery';
    cQuery += ' ORDER BY q.verseId ASC;';

    //IO.printFullText('SQlite :: cQuery ${cQuery}');

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, []);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SearchModel nModel = SearchModel.fromJson(row);

          nModel.searchText = null;
          nModel.verseCleanup = null;
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');

          // await nModel.toSplit(cText);

          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<SearchModel>> getSearchPage(
    final String cTableIndexName,
    String cText,
    final int cNumberOfTable,
  ) async {
    cText = SearchText(
      ArabicText(cText).toCharactersWithoutDiacritics(),
    ).toCleanup();
    cText = cText.trim();
    cText = ' $cText ';
    IO.printFullText('SQlite :: -- getSearchVerse ${cText}');
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    //IO.printFullText('SQlite :: dbDirectory  ${dbDirectory}');
    //IO.printFullText('SQlite :: dbPath  ${dbPath}');
    //IO.printFullText('SQlite :: dbExists  ${dbExists}');
    List<SearchModel> models = <SearchModel>[];
    if (!dbExists) return models;
    if (cText.trim() == '') return models;

    String WhereQuery = 'WHERE verseGoogle Like \'%$cText%\'';
    String HavingQuery = 'HAVING verseGoogle Like \'%$cText%\'';

    String cQuery = 'SELECT';
    cQuery += ' pageIndex , verseGoogle';
    // TODO Start subQuery
    cQuery += ' FROM ( SELECT';
    cQuery += ' i.pageIndex';
    //cQuery += ' , GROUP_CONCAT(q.verseGoogle,\' \') as verseGoogle';
    cQuery +=
        ' , (\' \' || GROUP_CONCAT(q.verseGoogle,\' \') || \' \') as verseGoogle';

    cQuery += ' FROM quran q';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN verses v ON v.id = q.verseId';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' GROUP BY i.pageIndex';
    cQuery += ' ORDER BY i.pageIndex ASC';
    cQuery += ' ) AS subquery';
    // TODO End subQuery
    cQuery += ' $WhereQuery';
    //cQuery += ' $HavingQuery'; // TODO also work without HAVING

    /*
    SELECT
    pageIndex , verseGoogle
    FROM ( SELECT
        i.pageIndex as pageIndex
        , GROUP_CONCAT(q.verseGoogle,' ') as verseGoogle
        FROM quran q
        INNER JOIN index_madinah i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex
        INNER JOIN verses v ON v.id = q.verseId
        INNER JOIN surah s ON s.surahIndex = v.surahIndex
        GROUP BY i.pageIndex
        ORDER BY i.pageIndex ASC
    ) AS subquery
    WHERE verseGoogle LIKE '%والتين والزيتون وطور%';
*/

    IO.printFullText('SQlite :: cQuery ${cQuery}');

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, []);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SearchModel nModel = SearchModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  // *******
  static Future<List<VerseModel>> getVerses(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    //IO.printFullText('SQlite :: -- getVerses');
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    //IO.printFullText('SQlite :: dbDirectory  ${dbDirectory}');
    //IO.printFullText('SQlite :: dbPath  ${dbPath}');
    //IO.printFullText('SQlite :: dbExists  ${dbExists}');
    List<VerseModel> models = <VerseModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex, v.tokensCount';
    cQuery += ' , q.verseId, q.verseHafs, q.verseUthmani';
    cQuery += ' , s.displayName';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY q.verseId ASC;';

    //IO.printFullText('SQlite :: cQuery ${cQuery}');

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          VerseModel nModel = VerseModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<VerseModel>> getVerse(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<VerseModel> models = <VerseModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex, v.tokensCount';
    cQuery += ' , q.verseId, q.verseHafs, q.verseUthmani';
    cQuery += ' , s.displayName';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ?';
    cQuery += ' ORDER BY q.verseId ASC';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          VerseModel nModel = VerseModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<int> getVersesCount(
    String cTableIndexName,
    int cSurahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    if (!dbExists) return 0;

    String cQuery = 'SELECT';
    cQuery += ' COUNT(*) as count';
    cQuery += ' FROM verses v';
    cQuery += ' WHERE v.surahIndex = ? ;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          try {
            int count = int.parse(row[SQL_IO.COLUMN_count].toString());
            return count;
          } catch (err) {}
        }
      }
    } catch (err) {}

    return 0;
  }

  static Future<int> getTokensCount(
    String cTableIndexName,
    int cSurahIndex,
    int cAyahIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    if (!dbExists) return 0;

    String cQuery = 'SELECT';
    cQuery += ' tokensCount';
    cQuery += ' FROM verses v';
    cQuery += ' WHERE v.surahIndex = ? AND v.ayahIndex = ? ;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cSurahIndex, cAyahIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          try {
            int count = int.parse(row[SQL_IO.COLUMN_tokensCount].toString());
            return count;
          } catch (err) {}
        }
      }
    } catch (err) {}

    return 0;
  }

  static Future<List<VerseModel>> getFirstVerseInPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<VerseModel> models = <VerseModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex, v.tokensCount';
    cQuery += ' , q.verseId, q.verseHafs, q.verseUthmani';
    cQuery += ' , s.displayName';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY q.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          VerseModel nModel = VerseModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
          break;
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<String> getFirstTokenInPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    List<VerseModel> nVerses = await getFirstVerseInPage(
      cTableIndexName!,
      cPageIndex,
    );
    if (null != nVerses && nVerses.length! > 0) {
      String nVerseHafs = nVerses[0].verseHafs!;
      String nFirstToken = await getTokenHafs(nVerseHafs, 1, 1);
      return nFirstToken;
    } else {
      return '';
    }
  }

  static Future<List<KhatmaVerseModel>> getVerseById(
    String cTableIndexName,
    int cVerseId,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<KhatmaVerseModel> models = <KhatmaVerseModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex, v.tokensCount';
    cQuery += ' , q.verseId, q.verseHafs, q.verseUthmani';
    cQuery += ' , s.displayName';
    cQuery += ' , j.juzaa as juzaaIndex';
    cQuery += ' , h.hizb';
    cQuery += ' FROM verses v';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON i.surahIndex = v.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery +=
        ' INNER JOIN juzaa j ON v.id BETWEEN j.startVerseId AND j.endVerseId';
    cQuery +=
        ' INNER JOIN hizb h ON v.id BETWEEN h.startVerseId AND h.endVerseId';
    cQuery += ' WHERE v.id = ?';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cVerseId]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          KhatmaVerseModel nModel = KhatmaVerseModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<VerseModel>> getVersesIncludeTranslateAndTafseer(
    String cTableIndexName,
    int cPageIndex,
    String translateLanguageCode,
  ) async {
    String tafseerLanguageCode = LanguageUtil.isRTLLocat(translateLanguageCode)
        ? 'ar-mu'
        : 'en';
    translateLanguageCode = LanguageUtil.getActualLocal(translateLanguageCode);
    translateLanguageCode =
        LanguageUtil.isSupportedTranslateLanguageCode(translateLanguageCode)
        ? translateLanguageCode
        : 'en';

    //IO.printFullText('SQlite :: -- getVerses');
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    //IO.printFullText('SQlite :: dbDirectory  ${dbDirectory}');
    //IO.printFullText('SQlite :: dbPath  ${dbPath}');
    //IO.printFullText('SQlite :: dbExists  ${dbExists}');
    List<VerseModel> models = <VerseModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex, j.juzaa AS juzaaIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex, v.tokensCount';
    cQuery += ' , q.verseId, q.verseHafs, q.verseUthmani';
    cQuery += ' , s.displayName';
    cQuery +=
        ' , (SELECT t.translateText FROM translateVerses t WHERE t.verseId = v.id AND t.languageCode == ?) as translateText';
    cQuery +=
        ', (SELECT tt.tafsserText FROM tafseer tt WHERE tt.verseId = v.id AND tt.tafsserCode == ?) as tafsserText';

    cQuery +=
        ' , (SELECT GROUP_CONCAT(ii.surahIndex, \'_\') FROM index_madinah ii WHERE ii.pageIndex = i.pageIndex) AS concatenatedSurahIndex';

    cQuery += '''
  , CASE
WHEN (i.pageIndex || '_' || v.surahIndex || '_' || v.ayahIndex)  = 	(
SELECT ii.pageIndex || '_' || ii.surahIndex || '_' || ii.ayahFromIndex FROM  index_madinah ii WHERE
ii.pageIndex = i.pageIndex
AND i.surahIndex = v.surahIndex
AND i.ayahFromIndex = v.ayahIndex
LIMIT 1) 	THEN true
ELSE false
END AS isFirstVerse
  ''';
    cQuery += '''
 , CASE
WHEN (i.pageIndex || '_' || v.surahIndex || '_' || v.ayahIndex)  =	(
SELECT ii.pageIndex || '_' || ii.surahIndex || '_' || ii.ayahToIndex FROM  index_madinah ii WHERE
ii.pageIndex = i.pageIndex 
AND i.surahIndex = v.surahIndex 
AND i.ayahToIndex = v.ayahIndex
ORDER BY ii.surahIndex DESC LIMIT 1
) 	THEN true
ELSE false
END AS isLastVerse
  ''';

    cQuery += '''
 , CASE
WHEN v.ayahIndex = 1
AND i.surahIndex = v.surahIndex
AND i.ayahFromIndex = v.ayahIndex
AND v.surahIndex = i.surahIndex
AND v.ayahIndex = i.ayahFromIndex
THEN true
ELSE false
END AS isFirstSurah
  ''';

    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery +=
        ' INNER JOIN juzaa j ON v.id BETWEEN j.startVerseId AND j.endVerseId';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY q.verseId ASC;';

    //IO.printFullText('SQlite :: cQuery ${cQuery}');

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [
        translateLanguageCode,
        tafseerLanguageCode,
        cPageIndex,
      ]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          VerseModel nModel = VerseModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          nModel.translateCode = translateLanguageCode;
          nModel.tafseerCode = tafseerLanguageCode;
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  // ******
  static Future<List<TokenModel>> getTokens(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    //IO.printFullText('SQlite :: -- getVerses');
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    //IO.printFullText('SQlite :: dbDirectory  ${dbDirectory}');
    //IO.printFullText('SQlite :: dbPath  ${dbPath}');
    //IO.printFullText('SQlite :: dbExists  ${dbExists}');
    List<TokenModel> models = <TokenModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex, v.tokensCount';
    cQuery += ' , q.verseId, q.verseHafs, q.verseUthmani, q.verseGoogle';
    cQuery += ' , s.displayName';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY q.verseId ASC;';

    //IO.printFullText('SQlite :: cQuery ${cQuery}');

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          VerseModel nVerseModel = VerseModel.fromJson(row);
          Map<String, dynamic> verseMap = nVerseModel.toJson();
          List<String> tokens = nVerseModel.verseGoogle!.split(' ');
          for (int tokenIndex = 0; tokenIndex < tokens.length; tokenIndex++) {
            String tokenUthmani = nVerseModel.verseUthmani!.split(
              ' ',
            )[tokenIndex];
            String tokenHafs = nVerseModel.verseHafs!.split(' ')[tokenIndex];
            String tokenGoogle = nVerseModel.verseGoogle!.split(
              ' ',
            )[tokenIndex];
            tokenGoogle = SearchText(
              ArabicText(tokenGoogle).toCharactersWithoutDiacritics(),
            ).toCleanup();
            Map<String, dynamic> nTokenMap = verseMap;
            nTokenMap.addAll({
              SQL_IO.COLUMN_tokenIndex: tokenIndex + 1,
              SQL_IO.COLUMN_tokenUthmani: tokenUthmani,
              SQL_IO.COLUMN_tokenHafs: tokenHafs,
              SQL_IO.COLUMN_tokenGoogle: tokenGoogle,
            });
            TokenModel nTokenModel = TokenModel.fromJson(nTokenMap);
            //IO.printFullText('SQlite :: nModel ${nTokenModel.toString()}');
            models.add(nTokenModel);

            //   if (tokenIndex == tokens.length - 1) {
            //     String icontoken = nVerseModel.verseHafs!.split(' ')[tokenIndex + 1];
            //     Map<String, dynamic> nIconTokenMap = verseMap;
            //     nIconTokenMap.addAll(
            //       {
            //         SQL_IO.COLUMN_tokenIndex: 0,
            //         SQL_IO.COLUMN_tokenUthmani: icontoken,
            //         SQL_IO.COLUMN_tokenHafs: icontoken,
            //         SQL_IO.COLUMN_tokenGoogle: icontoken,
            //       },
            //     );
            //     TokenModel nIconTokenModel = TokenModel.fromJson(nIconTokenMap);
            //     //IO.printFullText('SQlite :: nModel ${nIconTokenModel.toString()}');
            //     models.add(nIconTokenModel);
            //   }
          }
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  // ******
  static Future<List<String>> getUniqueTokensPage(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    //IO.printFullText('SQlite :: -- getVerses');
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    //IO.printFullText('SQlite :: dbDirectory  ${dbDirectory}');
    //IO.printFullText('SQlite :: dbPath  ${dbPath}');
    //IO.printFullText('SQlite :: dbExists  ${dbExists}');
    List<String> tokens = <String>[];
    if (!dbExists) return tokens;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex, v.tokensCount';
    cQuery += ' , q.verseId, q.verseHafs, q.verseUthmani, q.verseGoogle';
    cQuery += ' , s.displayName';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' ORDER BY q.verseId ASC;';

    //IO.printFullText('SQlite :: cQuery ${cQuery}');

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          VerseModel nVerseModel = VerseModel.fromJson(row);
          String verseGoogle = nVerseModel.verseGoogle!;
          verseGoogle = SearchText(
            ArabicText(verseGoogle).toCharactersWithoutDiacritics(),
          ).toCleanup();
          tokens.addAll(verseGoogle.split(' '));
        }
        tokens = tokens.toSet().toList();
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return tokens;
  }

  // ******
  static Future<List<String>> getUniqueTokensAll(String cTableIndexName) async {
    //IO.printFullText('SQlite :: -- getVerses');
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    //IO.printFullText('SQlite :: dbDirectory  ${dbDirectory}');
    //IO.printFullText('SQlite :: dbPath  ${dbPath}');
    //IO.printFullText('SQlite :: dbExists  ${dbExists}');
    List<String> tokens = <String>[];
    if (!dbExists) return tokens;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex, v.tokensCount';
    cQuery += ' , q.verseId, q.verseHafs, q.verseUthmani, q.verseGoogle';
    cQuery += ' , s.displayName';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' ORDER BY q.verseId ASC;';

    //IO.printFullText('SQlite :: cQuery ${cQuery}');

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, []);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          VerseModel nVerseModel = VerseModel.fromJson(row);
          String verseGoogle = nVerseModel.verseGoogle!;
          verseGoogle = SearchText(
            ArabicText(verseGoogle).toCharactersWithoutDiacritics(),
          ).toCleanup();
          tokens.addAll(verseGoogle.split(' '));
        }
        tokens = tokens.toSet().toList();
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return tokens;
  }

  // ******
  static Future<List<PageModel>> getPagesInfo(String cTableIndexName) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<PageModel> models = <PageModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery +=
        ' i.pageIndex, i.surahIndex, i.ayahFromIndex, i.ayahToIndex , j.juzaa as juzaaIndex';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON i.surahIndex == v.surahIndex AND i.ayahFromIndex == v.ayahIndex';
    cQuery +=
        ' INNER JOIN juzaa j ON v.id BETWEEN j.startVerseId AND j.endVerseId';
    cQuery += ' GROUP BY i.pageIndex';
    cQuery += ' ORDER BY i.pageIndex ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, []);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          PageModel nModel = PageModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<PageModel>> getPageInfo(
    String cTableIndexName,
    int cPageIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<PageModel> models = <PageModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery +=
        ' i.pageIndex, i.surahIndex, i.ayahFromIndex, i.ayahToIndex , j.juzaa as juzaaIndex';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON i.surahIndex == v.surahIndex AND i.ayahFromIndex == v.ayahIndex';
    cQuery +=
        ' INNER JOIN juzaa j ON v.id BETWEEN j.startVerseId AND j.endVerseId';
    cQuery += ' WHERE i.pageIndex = ?';
    cQuery += ' GROUP BY i.surahIndex';
    cQuery += ' ORDER BY i.surahIndex ASC';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [cPageIndex]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          PageModel nModel = PageModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<SurahModel>> getSurahInfo(String cTableIndexName) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<SurahModel> models = <SurahModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery +=
        ' i.pageIndex , s.surahIndex , s.type , s.name , s.displayName, j.juzaa as juzaaIndex';
    cQuery += ' FROM surah s';
    cQuery +=
        ' INNER JOIN verses v ON s.surahIndex == v.surahIndex AND v.ayahIndex == 1';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON s.surahIndex == i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery +=
        ' INNER JOIN juzaa j ON v.id BETWEEN j.startVerseId AND j.endVerseId';
    cQuery += ' ORDER BY s.surahIndex ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, []);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          SurahModel nModel = SurahModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<Chapters>> getChapterInfo(String cTableIndexName) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    print(dbExists);
    List<Chapters> models = <Chapters>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery +=
        ' i.pageIndex as pageIndexStart, s.surahIndex , s.type , s.name , s.displayName, j.juzaa as juzaaIndex';
    cQuery +=
        ' ,(SELECT COUNT(*) as versCount FROM verses vv WHERE vv.surahIndex = s.surahIndex) as versCount';
    cQuery +=
        ' ,(SELECT ii.pageIndex FROM index_madinah ii WHERE (SELECT COUNT(*) as versCount FROM verses vv WHERE vv.surahIndex = s.surahIndex) = ii.ayahToIndex AND s.surahIndex = ii.surahIndex) as pageIndexEnd';
    cQuery += ' FROM surah s';
    cQuery +=
        ' INNER JOIN verses v ON s.surahIndex == v.surahIndex AND v.ayahIndex == 1';
    cQuery +=
        ' INNER JOIN index_madinah i ON s.surahIndex == i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery +=
        ' INNER JOIN juzaa j ON v.id BETWEEN j.startVerseId AND j.endVerseId';
    cQuery += ' ORDER BY s.surahIndex ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, []);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          Chapters chapters = Chapters.fromJson(row);
          //SurahModel nModel = SurahModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(chapters);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<bool> getIfSajdahToShowDialog(
    String cTableIndexName,
    int pageNumber,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    if (!dbExists) return false;

    String cQuery = 'SELECT';
    cQuery += '  i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery += ' , sa.id , sa.verseId';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' , s.displayName';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN sajdah sa ON sa.verseId = v.id';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' WHERE i.pageIndex = $pageNumber';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, []);
      if (rows.isNotEmpty) {
        return true;
      }
      return false;
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
      return false;
    }
  }

  static Future<Map<String, String>?> getIfHizbToShowDialog(
    String cTableIndexName,
    int pageNumber,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<Map<dynamic, dynamic>> models = [];
    if (!dbExists) return null;

    String cQuery = 'SELECT';
    cQuery += '  i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery += ' , h.hizb, h.hizbDetails, h.startVerseId, h.endVerseId';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' , s.displayName';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN hizb h ON h.startVerseId = v.id';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' WHERE i.pageIndex = $pageNumber';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, []);
      if (rows.isNotEmpty) {
        return {
          "HizbDetails": rows.first['hizbDetails'].toString(),
          "HizbNumber": rows.first['hizb'].toString(),
        };
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }
    return null;
  }

  static Future<String?> getIfJuzzaToShowDialog(
    String cTableIndexName,
    int pageNumber,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<Map<dynamic, dynamic>> models = [];
    if (!dbExists) return null;

    String cQuery = 'SELECT';
    cQuery += '  i.pageIndex';
    cQuery += ' , v.surahIndex, v.ayahIndex';
    cQuery += '  , j.juzaa, j.startVerseId, j.endVerseId';
    cQuery += ' , q.verseHafs, q.verseUthmani';
    cQuery += ' , s.displayName';
    cQuery += ' FROM $cTableIndexName i';
    cQuery +=
        ' INNER JOIN verses v ON v.surahIndex = i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN juzaa j ON j.startVerseId = v.id';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' WHERE i.pageIndex = $pageNumber';
    cQuery += ' ORDER BY v.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, []);
      if (rows.isNotEmpty) {
        return rows.first['juzaa'].toString();
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }
    return null;
  }

  static Future<List<JuzaaModel>> getJuzaaInfo(String cTableIndexName) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<JuzaaModel> models = <JuzaaModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' i.pageIndex , i.surahIndex, j.juzaa as juzaaIndex';
    cQuery += ' FROM  juzaa j';
    cQuery += ' INNER JOIN verses v ON j.startVerseId == v.id';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON v.surahIndex == i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery += ' ORDER BY j.juzaa ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, []);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          JuzaaModel nModel = JuzaaModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  static Future<List<HizbModel>> getHizbInfo(String cTableIndexName) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<HizbModel> models = <HizbModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery += ' h.id, h.hizb , h.hizbDetails';
    cQuery += ' , i.pageIndex';
    cQuery += ' , v.surahIndex , v.ayahIndex';
    cQuery += ' , j.juzaa as juzaaIndex';
    cQuery += ' , q.verseId, q.verseHafs, q.verseUthmani';
    cQuery += ' , s.displayName';
    cQuery += ' FROM  hizb h';
    cQuery += ' INNER JOIN verses v ON h.startVerseId == v.id';
    cQuery +=
        ' INNER JOIN $cTableIndexName i ON v.surahIndex == i.surahIndex AND v.ayahIndex BETWEEN i.ayahFromIndex AND i.ayahToIndex';
    cQuery +=
        ' INNER JOIN juzaa j ON v.id BETWEEN j.startVerseId AND j.endVerseId';
    cQuery += ' INNER JOIN quran q ON q.verseId = v.id';
    cQuery += ' INNER JOIN surah s ON s.surahIndex = v.surahIndex';
    cQuery += ' ORDER BY h.hizb ASC';

    //IO.printFullText(cQuery);

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, []);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          //IO.printFullText('SQlite :: row ${row}');
          HizbModel nModel = HizbModel.fromJson(row);
          //IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  // ******

  static Future<String> getTokenHafs(
    String verseHafs,
    int tokenFromIndex,
    int tokenToIndex,
  ) async {
    if (verseHafs == null) return verseHafs;
    verseHafs = verseHafs.trim();
    List<String> tokens = verseHafs.split(' ');
    String tokensHafs = '';
    for (
      int cIndex = (tokenFromIndex - 1);
      cIndex <= (tokenToIndex - 1);
      cIndex++
    ) {
      tokensHafs += '${tokens[cIndex]} ';
    }
    return tokensHafs.trim();
  }

  static Future<String> getToken(String verseHafs, int tokenIndex) async {
    if (verseHafs == null) return verseHafs;
    try {
      return verseHafs.split(' ')[tokenIndex - 1];
    } catch (err) {}
    return '';
  }

  static Future<List<LocationModel>> getLocationOrImage(
    int cSurahIndex,
    int cAyahIndex,
    int cTokenIndex,
  ) async {
    var dbDirectory = await getDatabasesPath();
    var dbPath = p.join(dbDirectory, DATABASE_NAME);
    var dbExists = await databaseExists(dbPath);
    List<LocationModel> models = <LocationModel>[];
    if (!dbExists) return models;

    String cQuery = 'SELECT';
    cQuery +=
        ' l.pageIndex, l.surahIndex, l.ayahIndex, l.tokenIndex, l.image, l.location';
    cQuery += ' FROM locations l';
    cQuery +=
        ' WHERE l.surahIndex = ? AND l.ayahIndex = ? AND l.tokenIndex = ?';
    cQuery += ' ORDER BY l.id ASC;';

    try {
      Database db = await openDatabase(dbPath, readOnly: true);
      List<Map> rows = await db.rawQuery(cQuery, [
        cSurahIndex,
        cAyahIndex,
        cTokenIndex,
      ]);
      if (rows.isNotEmpty) {
        for (var row in rows) {
          IO.printFullText('SQlite :: row ${row}');
          LocationModel nModel = LocationModel.fromJson(row);
          IO.printFullText('SQlite :: nModel ${nModel.toString()}');
          models.add(nModel);
        }
      }
    } catch (err) {
      IO.printFullText('SQlite :: err ${err}');
    }

    return models;
  }

  // ******
}
