// tool/bake_char_colors_flutter.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';        // لتوفير dart:ui لأن حزمة tajweed تعتمد Flutter
import 'package:characters/characters.dart';
import 'tajweed.dart';
import 'tajweed_token.dart';

const String kPagesSrcDir = 'assets/metadata/Quran/pages';
const String kPagesOutDir = 'assets/metadata/Quran/pages_colored';
const String kManifestSrc = 'assets/metadata/Quran/pages/pages_manifest.json';

/// ألوان القواعد (فاتح/داكن) طبقًا لـ enum الذي أرسلته:
/// مخزنة كنص HEX "AARRGGBB"
const Map<String, Map<String, String>> kRuleColors = {
  'LAFZATULLAH': {'cL': '#FF4CAF50', 'cD': '#FF81C784'},
  'izhar': {'cL': '#FF06B0B6', 'cD': '#FF6FF0F5'},
  'ikhfaa': {'cL': '#FFB71C1C', 'cD': '#FFFA4444'},
  'idghamWithGhunna': {'cL': '#FFF06292', 'cD': '#FFF06292'},
  'iqlab': {'cL': '#FF2196F3', 'cD': '#FF2196F3'},
  'qalqala': {'cL': '#FF7B8F0A', 'cD': '#FFD6F046'},
  'idghamWithoutGhunna': {'cL': '#FF9E9E9E', 'cD': '#FF9E9E9E'},
  'ghunna': {'cL': '#FFFF9800', 'cD': '#FFFF9800'},
  'prolonging': {'cL': '#FF8E64D6', 'cD': '#FFBFA5EC'},
  'alefTafreeq': {'cL': '#FF9E9E9E', 'cD': '#FF9E9E9E'},
  'hamzatulWasli': {'cL': '#FF9E9E9E', 'cD': '#FF9E9E9E'},
  'none': {'cL': '#00000000', 'cD': '#00000000'}, // شفّاف = يرث لاحقًا
};

String _ruleKey(TajweedToken t) {
  final raw = t.rule.toString(); // e.g. TajweedRule.ikhfaa
  final i = raw.indexOf('.');
  return i >= 0 ? raw.substring(i + 1) : raw;
}

Map<String, String> _colorPairFor(TajweedToken t) {
  final key = _ruleKey(t);
  return kRuleColors[key] ??
      kRuleColors.entries.firstWhere(
        (e) => e.key.toLowerCase() == key.toLowerCase(),
        orElse: () => const MapEntry('none', {'cL': '#00000000', 'cD': '#00000000'}),
      ).value;
}

Future<void> _bake() async {
  // تأكد مجلد الإخراج موجود
  final outDir = Directory(kPagesOutDir);
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  // اقرأ المانيفست
  final manifestMap = json.decode(await File(kManifestSrc).readAsString())
      as Map<String, dynamic>;
  final pages = (manifestMap['page_count'] as num).toInt();

  for (int page = 1; page <= pages; page++) {
    final inPath = '$kPagesSrcDir/$page.json';
    final inFile = File(inPath);
    if (!inFile.existsSync()) {
      // تخطَّ الصفحات غير الموجودة
      continue;
    }

    final src = json.decode(await inFile.readAsString()) as Map<String, dynamic>;
    final lines = (src['lines'] as List).cast<Map<String, dynamic>>();

    final outLines = <Map<String, dynamic>>[];

    for (final line in lines) {
      final text = (line['text'] ?? '').toString();
      final surahIdx = (line['surahIndexFirst'] as num).toInt();
      final ayahIdx  = (line['ayahIndexFirst']  as num).toInt();
      final isBasmala = line['isBasmala'] == true;
      final isTitle   = line['isTitle'] == true;

      // العناوين: لا تلوين، نخزن كتلة واحدة بدون لون (أو شفافة)
      if (isTitle) {
        outLines.add({
          'sortKey': (line['sortKey'] as num).toInt(),
          'text': text,
          'surahIndexFirst': surahIdx,
          'ayahIndexFirst': ayahIdx,
          'isBasmala': isBasmala,
          'isTitle': isTitle,
          'chars': [
            {'t': text, 'cL': '#00000000', 'cD': '#00000000'},
          ],
        });
        continue;
      }

      // لو سطر عادي، نلوّنه عبر التجزئة ثم تقسيم إلى عناقيد مُشكّلة
      final tokens = Tajweed.tokenize(text, surahIdx, ayahIdx);
      final chars = <Map<String, String>>[];

      for (final tok in tokens) {
        final colors = _colorPairFor(tok);
        for (final cluster in tok.text.characters) {
          chars.add({
            't': cluster,
            'cL': colors['cL']!,
            'cD': colors['cD']!,
          });
        }
      }

      outLines.add({
        'sortKey': (line['sortKey'] as num).toInt(),
        'text': text,
        'surahIndexFirst': surahIdx,
        'ayahIndexFirst': ayahIdx,
        'isBasmala': isBasmala,
        'isTitle': isTitle,
        'chars': chars,
      });
    }

    final outPath = '$kPagesOutDir/$page.json';
    await File(outPath).writeAsString(json.encode({
      'pageIndex': page,
      'lines': outLines,
    }), flush: true);
    // print('Wrote $outPath');
  }

  // اكتب مانيفست جديد للمجلد الملوّن
  await File('$kPagesOutDir/pages_manifest.json').writeAsString(json.encode({
    'page_count': pages,
  }), flush: true);

  // انتهى
  // print('Done baking to $kPagesOutDir');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bake();
  // خروج نظيف
  exit(0);
}
