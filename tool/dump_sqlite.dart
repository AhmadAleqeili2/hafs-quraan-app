import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Exports the contents of one or more SQLite databases into Excel files.
///
/// Usage:
///   dart run tool/dump_sqlite.dart [path/to/database.db] [...]
///
/// If no path is supplied the script defaults to `assets/db/shamel.db`.
/// Multiple paths can be passed to export more than one database in a single run.
Future<void> main(List<String> arguments) async {
  final dbPaths = arguments.isEmpty ? ['assets/db/shamel.db'] : arguments;
  final outputDir = Directory(p.join('build', 'db_exports'));
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  for (final dbPath in dbPaths) {
    final resolvedPath = _resolvePath(dbPath);
    final file = File(resolvedPath);

    if (!file.existsSync()) {
      stderr.writeln('Database file not found: $dbPath');
      continue;
    }

    stdout.writeln('Processing database: ${file.path}');
    final db = sqlite3.open(file.path);
    try {
      final tables = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;",
      );

      if (tables.isEmpty) {
        stdout.writeln('  No user tables found.');
        continue;
      }

      final excel = Excel.createExcel();
      // remove default sheet created by the package
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.delete(defaultSheet);
      }

      for (final table in tables) {
        final tableName = table['name'] as String;
        final sheetName = _sanitizeSheetName(tableName);
        final sheet = excel[sheetName];

        final rows = db.select('SELECT * FROM "$tableName"');
        if (rows.isEmpty) {
          sheet.appendRow([TextCellValue('<empty>')]);
          continue;
        }

        final columns = rows.columnNames;
        sheet.appendRow(columns.map((name) => TextCellValue(name)).toList());

        for (final row in rows) {
          final values = columns
              .map((column) => _stringifyValue(row[column]))
              .map((value) => TextCellValue(value))
              .toList();
          sheet.appendRow(values);
        }
      }

      final bytes = excel.encode();
      if (bytes == null) {
        stdout.writeln('  Failed to encode Excel workbook.');
        continue;
      }

      final outputFile = File(
        p.join(outputDir.path, '${_fileFriendlyName(file.path)}.xlsx'),
      );
      outputFile
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes, flush: true);
      stdout.writeln('  Exported to ${outputFile.path}');
    } finally {
      db.dispose();
    }

    stdout.writeln('Done.\n');
  }
}

String _resolvePath(String path) {
  if (p.isAbsolute(path)) {
    return p.normalize(path);
  }
  final cwd = Directory.current.path;
  return p.normalize(p.join(cwd, path));
}

String _stringifyValue(Object? value) {
  if (value == null) return 'NULL';
  if (value is List<int>) {
    return 'BLOB(${value.length} bytes)';
  }
  return value.toString();
}

String _sanitizeSheetName(String name) {
  const invalidChars = r'[]:*?\/';
  var cleaned = name;
  for (final char in invalidChars.split('')) {
    cleaned = cleaned.replaceAll(char, '_');
  }
  if (cleaned.length > 31) {
    cleaned = cleaned.substring(0, 31);
  }
  return cleaned.isEmpty ? 'Sheet' : cleaned;
}

String _fileFriendlyName(String path) {
  final base = p.basenameWithoutExtension(path);
  return base.replaceAll(RegExp(r'[^\w\-]+'), '_');
}
