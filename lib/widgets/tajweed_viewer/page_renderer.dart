part of '../../secreens/tajweed_viewer.dart';

/// ملاحظة: تأكد أن ملف الـ library (الذي يحتوي `library ...;`) فيه:
/// import 'dart:async'; // لا يمكن عمل import داخل ملفات part.

double? _pageFiveLineHeightReference;

const String _kAyatDataPath = 'assets/metadata/Quran/ayat_data.json';
Future<Map<String, _AyahData>>? _ayahDataFuture;

class _AyahData {
  final int surahNo;
  final int ayahNo;
  final String ayahText;
  final List<_AyahTafsir> tafseer;
  final List<_AyahTranslation> translations;
  final List<String> reasons;

  const _AyahData({
    required this.surahNo,
    required this.ayahNo,
    required this.ayahText,
    required this.tafseer,
    required this.translations,
    required this.reasons,
  });

  factory _AyahData.fromMap(Map<String, dynamic> map) {
    final text = (map['ayah_text'] ?? '').toString().trim();
    return _AyahData(
      surahNo: _parseInt(map['surah_no']),
      ayahNo: _parseInt(map['ayah_no']),
      ayahText: text,
      tafseer: _AyahTafsir.parseList(map['tafseer']),
      translations: _AyahTranslation.parseList(map['translations']),
      reasons: _parseReasons(map['reasons']),
    );
  }

  static List<String> _parseReasons(Object? raw) {
    final result = <String>[];
    if (raw is Iterable) {
      for (final entry in raw) {
        final candidate = entry is Map<String, dynamic>
            ? (entry['reason'] ?? entry['text'] ?? entry['description'] ?? '')
                  .toString()
            : entry?.toString() ?? '';
        final trimmed = candidate.trim();
        if (trimmed.isNotEmpty) {
          result.add(trimmed);
        }
      }
    }
    return result;
  }
}

class _AyahTafsir {
  final String code;
  final String name;
  final String text;

  const _AyahTafsir({
    required this.code,
    required this.name,
    required this.text,
  });

  static List<_AyahTafsir> parseList(Object? raw) {
    final result = <_AyahTafsir>[];
    if (raw is Iterable) {
      for (final entry in raw) {
        if (entry is Map<String, dynamic>) {
          final text = (entry['text'] ?? '').toString().trim();
          if (text.isEmpty) continue;
          final name = (entry['name'] ?? '').toString().trim();
          final code = (entry['code'] ?? '').toString().trim();
          result.add(
            _AyahTafsir(
              code: code,
              name: name.isEmpty ? code : name,
              text: text,
            ),
          );
        }
      }
    }
    return result;
  }
}

class _AyahTranslation {
  final String langCode;
  final String langName;
  final String translatedText;

  const _AyahTranslation({
    required this.langCode,
    required this.langName,
    required this.translatedText,
  });

  static List<_AyahTranslation> parseList(Object? raw) {
    final result = <_AyahTranslation>[];
    if (raw is Iterable) {
      for (final entry in raw) {
        if (entry is Map<String, dynamic>) {
          final text = (entry['translated_text'] ?? entry['text'] ?? '')
              .toString()
              .trim();
          if (text.isEmpty) continue;
          final name = (entry['lang_name'] ?? entry['name'] ?? '')
              .toString()
              .trim();
          final code = (entry['lang_code'] ?? entry['code'] ?? '')
              .toString()
              .trim();
          result.add(
            _AyahTranslation(
              langCode: code.isEmpty ? name : code,
              langName: name.isEmpty ? code : name,
              translatedText: text,
            ),
          );
        }
      }
    }
    return result;
  }
}

Future<Map<String, _AyahData>> _loadAyahData() {
  if (_ayahDataFuture != null) {
    return _ayahDataFuture!;
  }
  _ayahDataFuture = _fetchAyahData();
  return _ayahDataFuture!;
}

Future<Map<String, _AyahData>> _fetchAyahData() async {
  try {
    final raw = await rootBundle.loadString(_kAyatDataPath);
    final decoded = json.decode(raw);
    if (decoded is! Iterable) {
      return {};
    }
    final result = <String, _AyahData>{};
    for (final entry in decoded) {
      if (entry is Map<String, dynamic>) {
        final data = _AyahData.fromMap(entry);
        if (data.surahNo > 0 && data.ayahNo > 0 && data.ayahText.isNotEmpty) {
          result['${data.surahNo}:${data.ayahNo}'] = data;
        }
      }
    }
    return result;
  } catch (_) {
    return {};
  }
}

Color _withOpacity(Color base, double opacity) {
  final normalized = opacity.clamp(0.0, 1.0);
  final alpha = math.max(0, math.min(255, (normalized * 255).round()));
  return base.withAlpha(alpha);
}

class TajweedPageView extends StatelessWidget {
  const TajweedPageView({
    super.key,
    required this.lines,
    required this.pageIndex,
    required this.unit,
    required this.constraints,
    required this.surahNames,
    this.partName,
    this.showFrame = true,
    this.allowInnerScroll = true,
    this.onPageFiveLineHeightReady,
  });

  final List<RenderedLine> lines;
  final int pageIndex;
  final double unit;
  final BoxConstraints constraints;
  final Map<int, String> surahNames;
  final String? partName;
  final bool showFrame;
  final bool allowInnerScroll;
  final ValueChanged<double>? onPageFiveLineHeightReady;

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).colorScheme.onSurface;

    final double frameOuterMargin = showFrame ? 0.5 * unit : 0.0;
    final double frameInnerMargin = showFrame ? 2.0 * unit : 0.0;
    final double framePaddingH = showFrame ? 4.2 * unit : 0.0;
    final hPad = 2.0 * unit;
    final double frameWidthDeduction =
        2 * (frameOuterMargin + frameInnerMargin + framePaddingH + hPad);
    final double limitWidth = math.max(
      0.0,
      constraints.maxWidth - frameWidthDeduction,
    );
    final double scrollWidth = math.max(0.0, constraints.maxWidth - (2 * hPad));
    final double contentMaxWidth = showFrame
        ? limitWidth
        : math.max(0.0, math.min(scrollWidth, limitWidth));
    final availableJustificationWidth = contentMaxWidth > 0
        ? contentMaxWidth
        : constraints.maxWidth - (showFrame ? 0.0 : 2 * hPad);

    final contentLines = lines.where((line) => !line.isTitle).toList();

    final filteredLines = <RenderedLine>[];
    final processedCharsPerLine = <List<ColoredChar>>[];
    final processedTexts = <String>[];
    for (final line in contentLines) {
      final trimmedChars = _trimTrailingSpaces(line.chars);
      final joined = _joinText(trimmedChars);
      if (_isAllWhitespace(joined)) {
        continue;
      }
      filteredLines.add(line);
      processedCharsPerLine.add(trimmedChars);
      processedTexts.add(joined);
    }

    final double cacheWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : MediaQuery.of(context).size.width;
    final double cacheHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : MediaQuery.of(context).size.height;
    final String cacheSizeKey = LayoutMeasurementCache.instance.sizeKey(
      cacheWidth,
      cacheHeight,
    );
    final PageLayoutMetrics? cachedPageMetrics = LayoutMeasurementCache.instance
        .pageLayoutFor(pageIndex, cacheSizeKey);
    final bool hasCachedMetrics =
        cachedPageMetrics != null &&
        cachedPageMetrics.lines.length == filteredLines.length;
    final List<_LineLayout> cachedLayouts =
        hasCachedMetrics && cachedPageMetrics != null
        ? cachedPageMetrics.lines
              .map((metrics) => _LineLayout.fromMetrics(metrics))
              .toList()
        : <_LineLayout>[];

    // --- semanticHighlights مع دعم التطابق التقريبي (أخضر) ---
    final semanticHighlights = <int, List<_HighlightRange>>{};
    for (int i = 0; i < filteredLines.length; i++) {
      final spans = filteredLines[i].semanticSpans;
      if (spans.isEmpty) continue;

      final text = processedTexts[i];
      final chars = processedCharsPerLine[i];

      final ranges = _buildHighlightsWithApproxMatches(
        text: text,
        chars: chars,
        spans: spans,
        similarityThreshold: 0.5, // 50%
      );

      if (ranges.isNotEmpty) {
        semanticHighlights[i] = ranges;
      }
    }
    // -----------------------------------------------------------

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double baseScriptFont = ResponsiveTypography.mushafScript(unit);
    final double introScale = pageIndex <= 2 ? 1.05 : 0.92;
    const double swipeDisplayScale = 1.0;
    const double scrollDisplayScale =
        0.88; // Scroll mode stays slightly smaller—keep this exact value.
    final double displayScale = showFrame
        ? swipeDisplayScale
        : scrollDisplayScale;
    final double widthFactor =
        MediaQuery.of(context).size.width * (pageIndex > 2 ? 0.003 : 0.0036);
    final double minFontSize = 10.0 * widthFactor;
    final double maxFontSize = 19.0 * widthFactor;
    double scriptFontSize;
    if (hasCachedMetrics && cachedPageMetrics != null) {
      scriptFontSize = cachedPageMetrics.scriptFontSize;
    } else {
      scriptFontSize = baseScriptFont * introScale * displayScale;
      scriptFontSize = scriptFontSize.clamp(18.0, 34.0) * widthFactor;
    }
    final String? currentSurahName = filteredLines.isNotEmpty
        ? _lookupSurahName(filteredLines.last.surahIndexFirst, surahNames)
        : null;

    if (filteredLines.isEmpty) {
      final background = isDark
          ? const Color(0xFF0B0E12)
          : const Color(0xFFF1ECE0);
      return Container(
        color: background,
        child: Center(
          child: Text(
            'Page $pageIndex is empty',
            style: TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: ResponsiveTypography.body(unit),
              color: defaultColor,
            ),
          ),
        ),
      );
    }

    Color scriptTextColor = isDark ? Colors.white70 : const Color(0xFF5A4B2E);
    TextStyle styleFor(RenderedLine line, double size) => TextStyle(
      fontFamily: 'UthmanicHafs',
      fontSize: size,
      fontWeight: line.isBasmala ? FontWeight.w600 : FontWeight.w800,
      height: 1.9,
      color: scriptTextColor,
    );

    if (!hasCachedMetrics) {
      final double measurementFontSize = scriptFontSize;
      double longestLineWidthAtBase = 0.0;
      for (int i = 0; i < filteredLines.length; i++) {
        final style = styleFor(filteredLines[i], measurementFontSize);
        final width = _measureWithWordSpacing(processedTexts[i], style, 0.0);
        if (width > longestLineWidthAtBase) {
          longestLineWidthAtBase = width;
        }
      }

      final double targetLineWidth = availableJustificationWidth > 0
          ? availableJustificationWidth
          : constraints.maxWidth;

      if (longestLineWidthAtBase > 0 &&
          targetLineWidth > 0 &&
          longestLineWidthAtBase != targetLineWidth) {
        final double rawScale = targetLineWidth / longestLineWidthAtBase;
        if (rawScale.isFinite && rawScale > 0) {
          final double candidateSize = measurementFontSize * rawScale;
          scriptFontSize = candidateSize.clamp(minFontSize, maxFontSize);
        }
      }
    }

    TextStyle baseStyleFor(RenderedLine line) => styleFor(line, scriptFontSize);

    bool isException(int index, RenderedLine line, String text) {
      final bool isFirstContentLineOnFirstPage = (pageIndex == 1 && index == 0);
      final int wordCount = _countWords(text);
      if (_isLastAyahOfSurah(line)) return true;
      return line.isBasmala ||
          isFirstContentLineOnFirstPage ||
          (wordCount <= 3);
    }

    bool shouldReduceSpacing(int index) => pageIndex == 1 && index == 1;

    const double firstPageSecondLineSpacingScale = 0.75;

    final intrinsicWidths = hasCachedMetrics ? <double>[] : <double>[];
    if (!hasCachedMetrics) {
      for (int i = 0; i < filteredLines.length; i++) {
        final style = baseStyleFor(filteredLines[i]);
        final width = _measureWithWordSpacing(processedTexts[i], style, 0.0);
        intrinsicWidths.add(width);
      }
    }

    double maxIntrinsicNonException = 0.0;
    for (int i = 0; i < filteredLines.length; i++) {
      if (isException(i, filteredLines[i], processedTexts[i])) {
        continue;
      }
      final double width = hasCachedMetrics
          ? cachedLayouts[i].intrinsicWidth
          : intrinsicWidths[i];
      maxIntrinsicNonException = math.max(maxIntrinsicNonException, width);
    }
    final bool noJustifiableLines = maxIntrinsicNonException == 0.0;
    final bool allowSymbolSpacing = pageIndex > 2;

    final displayChildren = <Widget>[];
    int headerCount = 0;
    int? lastSurahIndex;

    final double standardVPad = 0.4 * unit;
    final double vPad = _normalizeLineSpacing(
      rawVPad: standardVPad,
      scriptFontSize: scriptFontSize,
      pageIndex: pageIndex,
      onLineHeightRegistered: onPageFiveLineHeightReady,
    );
    final double baseTextHeight = scriptFontSize * 2.0;

    final double desiredWidthForJustified = noJustifiableLines
        ? 0.0
        : math.min(maxIntrinsicNonException, availableJustificationWidth);

    final List<_LineLayout> measuredLayouts = <_LineLayout>[];
    for (int i = 0; i < filteredLines.length; i++) {
      final line = filteredLines[i];
      final text = processedTexts[i];
      final _LineLayout? cachedLayout = hasCachedMetrics
          ? cachedLayouts[i]
          : null;
      final bool isLastAyah = _isLastAyahOfSurah(line);
      final bool except = isException(i, line, text) || isLastAyah;

      double lineFontSize;
      double width0;
      double targetWidthForThisLine;
      double perGap = 0.0;
      List<_ExtraSpaceInsertion> targetedExtraSpaces = const [];

      if (cachedLayout != null) {
        lineFontSize = cachedLayout.lineFontSize;
        width0 = cachedLayout.intrinsicWidth;
        targetWidthForThisLine = cachedLayout.targetWidth;
        perGap = cachedLayout.perGap;
        targetedExtraSpaces = cachedLayout.extraSpaces;
      } else {
        final double baseWidthAtBaseFont = intrinsicWidths[i];
        lineFontSize = _lineFontSizeForScrollMode(
          baseFontSize: scriptFontSize,
          measuredWidthAtBaseFont: baseWidthAtBaseFont,
          targetWidth: availableJustificationWidth,
          minFontSize: minFontSize,
          maxFontSize: maxFontSize,
          enable: !showFrame,
        );
        final TextStyle measurementStyle = styleFor(line, lineFontSize);
        width0 = _measureWithWordSpacing(text, measurementStyle, 0.0);
        targetWidthForThisLine = width0;

        if (!except && !noJustifiableLines && desiredWidthForJustified > 0.0) {
          targetWidthForThisLine = desiredWidthForThisLine(
            desiredWidthForJustified,
            width0,
          );

          if (shouldReduceSpacing(i)) {
            targetWidthForThisLine =
                width0 +
                (targetWidthForThisLine - width0) *
                    firstPageSecondLineSpacingScale;
          }

          final double widthShortage = targetWidthForThisLine - width0;
          if (widthShortage > 0.05) {
            if (allowSymbolSpacing) {
              final preferredSlots = _preferredSpacePositions(text);
              if (preferredSlots.isNotEmpty) {
                targetedExtraSpaces = _buildExtraSpaceInsertions(
                  positions: preferredSlots,
                  extraWidth: widthShortage,
                  textLength: text.length,
                );
              }
            }

            if (targetedExtraSpaces.isEmpty) {
              final gaps = _countGapsInText(text);
              if (gaps > 0) {
                perGap = _solvePerGap(
                  text: text,
                  baseStyle: measurementStyle,
                  targetWidth: targetWidthForThisLine,
                  gaps: gaps,
                );

                for (int iter = 0; iter < 4; iter++) {
                  final currentWidth = _measureWithWordSpacing(
                    text,
                    measurementStyle,
                    perGap,
                  );
                  final error = targetWidthForThisLine - currentWidth;
                  if (error.abs() <= 0.2) break;
                  perGap = math.max(0.0, perGap + (error / gaps));
                }
              }
            }
          }
        }
      }

      final _LineLayout layout =
          cachedLayout ??
          _LineLayout(
            lineFontSize: lineFontSize,
            perGap: perGap,
            targetWidth: targetWidthForThisLine,
            intrinsicWidth: width0,
            extraSpaces: targetedExtraSpaces,
          );
      if (!hasCachedMetrics) {
        measuredLayouts.add(layout);
      }

      final int surahIndex = line.surahIndexFirst;
      final bool newSurahStart =
          line.ayahIndexFirst == 1 && surahIndex != lastSurahIndex;
      if (newSurahStart) {
        final headerTitle = _lookupSurahName(surahIndex, surahNames);
        if (headerTitle != null && headerTitle.isNotEmpty) {
          headerCount++;
          final bool isIntroPage = pageIndex <= 2;
          final double scaledUnit = isIntroPage ? unit * 1.12 : unit * 0.92;
          displayChildren.add(
            SurahHeaderFrame(
              title: headerTitle,
              u: scaledUnit,
              fullWidth: pageIndex > 2 || !showFrame,
            ),
          );
          displayChildren.add(
            SizedBox(height: isIntroPage ? 2.4 * unit : 1.6 * unit),
          );
        }
      }

      final TextStyle style0 = styleFor(line, layout.lineFontSize);
      final TextStyle styleWithSpacing = layout.perGap == 0.0
          ? style0
          : style0.merge(TextStyle(wordSpacing: layout.perGap));
      final spans = _buildInteractiveSpans(
        context,
        processedCharsPerLine[i],
        isDark: isDark,
        baseStyle: styleWithSpacing,
        highlights: semanticHighlights[i] ?? const [],
        extraSpaces: layout.extraSpaces,
        ayahMarkerGlyph: line.ayahMarkerGlyph,
        ayahMarkerNumber: line.ayahMarkerAyaNo,
        surahNumber: line.surahIndexFirst,
        lineText: line.text,
      );

      displayChildren.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: showFrame ? hPad : 0,
            vertical: vPad,
          ),
          child: SizedBox(
            width: double.infinity,
            child: SizedBox(
              width: showFrame ? layout.targetWidth : double.infinity,
              child: Align(
                alignment: Alignment.center,
                child: Text.rich(
                  TextSpan(style: styleWithSpacing, children: spans),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  strutStyle: StrutStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: layout.lineFontSize,
                    height: 1.9,
                    forceStrutHeight: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      lastSurahIndex = surahIndex;
    }

    if (!hasCachedMetrics && measuredLayouts.isNotEmpty) {
      LayoutMeasurementCache.instance.storePageLayout(
        pageIndex: pageIndex,
        sizeKey: cacheSizeKey,
        width: cacheWidth,
        height: cacheHeight,
        metrics: PageLayoutMetrics(
          lineHeight: baseTextHeight + (vPad * 2),
          scriptFontSize: scriptFontSize,
          vPad: vPad,
          lines: measuredLayouts.map((layout) => layout.toMetrics()).toList(),
        ),
      );
    }

    if (displayChildren.isNotEmpty) {
      displayChildren.add(SizedBox(height: 10.0 * unit));
    }

    final perLineTotal = baseTextHeight + (vPad * 2);
    const double headerEstimatedUnitHeight = 6.0;
    final double headerHeightEstimate =
        headerCount * (headerEstimatedUnitHeight * unit);
    final double contentHeight =
        (filteredLines.length * perLineTotal) + headerHeightEstimate;
    final double scrollableHeight = math.max(
      0.0,
      constraints.maxHeight - (6.5 * unit),
    );

    final bool needsScroll =
        allowInnerScroll && contentHeight > constraints.maxHeight;
    final normalizedPartName = partName?.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (!showFrame) {
      const double scrollPageNumberScale =
          1.3; // Preserve scroll mode footer sizing; do not shrink.
      final Color pageNumberColor = isDark
          ? Colors.white70
          : const Color(0xFF5A4B2E);
      displayChildren.add(
        Padding(
          padding: EdgeInsets.only(top: vPad),
          child: Text(
            '$pageIndex',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'UthmanicHafs',
              letterSpacing: 1.2,
              fontSize:
                  ResponsiveTypography.pageBadge(unit) * scrollPageNumberScale,
              color: _withOpacity(pageNumberColor, isDark ? 0.85 : 0.75),
            ),
          ),
        ),
      );
    }

    if (!showFrame) {
      final padding = EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: vPad * 1.4,
      );
      if (!allowInnerScroll) {
        return Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: displayChildren,
          ),
        );
      }
      if (needsScroll) {
        return ListView(
          padding: padding,
          physics: const BouncingScrollPhysics(),
          children: displayChildren,
        );
      }
      return SingleChildScrollView(
        padding: padding,
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: displayChildren,
        ),
      );
    }

    final frameContent = needsScroll
        ? SizedBox(
            height: scrollableHeight,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: displayChildren,
            ),
          )
        : Column(mainAxisSize: MainAxisSize.min, children: displayChildren);

    final bool isIntroFramedPage = showFrame && pageIndex <= 2;
    final double? introFrameHeightFactor = isIntroFramedPage ? 0.5 : null;

    final framedContent = SingleChildScrollView(
      child: QuranPageFrame(
        u: unit,
        outerRadius: (pageIndex <= 2) ? 90 : null,
        heightFactor: introFrameHeightFactor,
        child: SizedBox(
          height: isIntroFramedPage
              ? MediaQuery.of(context).size.height * 0.6
              : MediaQuery.of(context).size.height * 0.75,
          child: SingleChildScrollView(
            child: Stack(
              alignment: Alignment.center,
              children: [
                frameContent,
                Positioned(
                  bottom: 0,
                  child: Text(
                    '$pageIndex',
                    style: TextStyle(
                      fontFamily: 'UthmanicHafs',
                      fontSize: ResponsiveTypography.pageBadge(unit),
                      color: isDark ? Colors.white70 : const Color(0xFF5A4B2E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final double labelTopOffset = 2 * unit;
    final double horizontalInset = 2 * unit;

    return Container(
      color: isDark ? const Color(0xFF0B0E12) : const Color(0xFFF1ECE0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: 3.4 * unit),
              child: Center(child: framedContent),
            ),
          ),
          if (currentSurahName != null && currentSurahName.isNotEmpty) ...[
            Positioned(
              top: labelTopOffset,
              left: horizontalInset,
              child: _FrameCornerLabel(
                text: currentSurahName,
                u: unit,
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
          if (normalizedPartName != null && normalizedPartName.isNotEmpty)
            Positioned(
              top: labelTopOffset,
              right: horizontalInset,
              child: _FrameCornerLabel(
                text: normalizedPartName,
                u: unit,
                alignment: Alignment.centerRight,
              ),
            ),
        ],
      ),
    );
  }
}

String _joinText(List<ColoredChar> chars) => chars.map((c) => c.t).join();

Color? _parseHexOrNullInherit(String hex) {
  try {
    if (hex.startsWith('#') && hex.length == 9) {
      final value = int.parse(hex.substring(1), radix: 16);
      final alpha = (value >> 24) & 0xFF;
      if (alpha == 0) return null;
      return Color(value);
    }
  } catch (_) {}
  return null;
}

double _measureWithWordSpacing(
  String text,
  TextStyle base,
  double wordSpacing,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: base.merge(TextStyle(wordSpacing: wordSpacing)),
    ),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
    maxLines: 1,
  )..layout(minWidth: 0, maxWidth: double.infinity);
  return painter.width;
}

int _countWords(String value) {
  final normalized = value.replaceAll('\u00A0', ' ').trim();
  if (normalized.isEmpty) {
    return 0;
  }
  return normalized.split(RegExp(r'\s+')).length;
}

int _countGapsInText(String value) {
  int gaps = 0;
  for (int i = 0; i < value.length; i++) {
    final ch = value[i];
    if (ch == ' ' || ch == '\u00A0') {
      gaps++;
    }
  }
  return gaps;
}

final RegExp _stopMarkRegex = RegExp(
  '[\u06D6\u06D7\u06D8\u06D9\u06DA\u06DB\u06DC]',
);
final RegExp _ayahMarkerRegex = RegExp('\u06DD[0-9\u0660-\u0669]+');

List<int> _preferredSpacePositions(String text) {
  final stopSlots = _slotsAfterStopMarkWords(text);
  if (stopSlots.isNotEmpty) {
    return stopSlots;
  }
  return _slotsAfterAyahMarkers(text);
}

List<int> _slotsAfterStopMarkWords(String text) {
  final words = _extractWordsWithIndices(text);
  if (words.isEmpty) return const [];

  final positions = <int>[];
  for (final word in words) {
    if (_stopMarkRegex.hasMatch(word.text)) {
      positions.add(word.end);
    }
  }
  return positions;
}

List<int> _slotsAfterAyahMarkers(String text) {
  final matches = _ayahMarkerRegex.allMatches(text);
  if (matches.isEmpty) return const [];

  final positions = <int>[];
  for (final match in matches) {
    positions.add(match.end);
  }
  return positions;
}

List<_ExtraSpaceInsertion> _buildExtraSpaceInsertions({
  required List<int> positions,
  required double extraWidth,
  required int textLength,
}) {
  if (positions.isEmpty || extraWidth <= 0 || textLength < 0) {
    return const [];
  }

  final seen = <int>{};
  final normalized = <int>[];
  for (final raw in positions) {
    int clamped = raw;
    if (clamped < 0) {
      clamped = 0;
    } else if (clamped > textLength) {
      clamped = textLength;
    }
    if (seen.add(clamped)) {
      normalized.add(clamped);
    }
  }

  if (normalized.isEmpty) {
    return const [];
  }

  final double perSlot = extraWidth / normalized.length;
  if (!perSlot.isFinite || perSlot <= 0) {
    return const [];
  }

  return normalized
      .map((pos) => _ExtraSpaceInsertion(position: pos, width: perSlot))
      .toList(growable: false);
}

/// يبني الـ spans التفاعلية مع دعم الألوان ومسافات التمدد المخصصة:
/// - أحمر: تطابق مؤكد (الـ span الأصلي)
/// - أخضر: تطابق تقريبي (>= 50%)
List<InlineSpan> _buildInteractiveSpans(
  BuildContext context,
  List<ColoredChar> processedChars, {
  required bool isDark,
  required TextStyle baseStyle,
  List<_HighlightRange> highlights = const [],
  List<_ExtraSpaceInsertion> extraSpaces = const [],
  int? ayahMarkerGlyph,
  int? ayahMarkerNumber,
  int? surahNumber,
  required String lineText,
}) {
  var segments = _createSegments(processedChars, isDark);
  if (ayahMarkerGlyph != null && ayahMarkerNumber != null) {
    final markers = _buildAyahMarkerRanges(
      processedChars,
      glyph: ayahMarkerGlyph,
      ayahNumber: ayahMarkerNumber,
    );
    for (final marker in markers) {
      segments = _applyAyahMarkerToSegments(segments, marker);
    }
  }
  if (highlights.isNotEmpty) {
    final sorted = [...highlights]..sort((a, b) => a.start.compareTo(b.start));
    for (final highlight in sorted) {
      segments = _applyHighlightToSegments(segments, highlight);
    }
  }

  InlineSpan? buildTextSpan(_TextSegment segment, String value) {
    if (value.isEmpty) return null;
    if (segment.isAyahMarker) {
      final int number = segment.ayahNumber ?? ayahMarkerNumber ?? 0;
      final int surah = surahNumber ?? 0;
      return TextSpan(
        text: value,
        style: baseStyle.copyWith(color: isDark ? Colors.white70 : const Color(0xFF5A4B2E),),
        recognizer: TapGestureRecognizer()
          ..onTapDown = (details) {
            if (number > 0) {
              _removeAyahPopup();
              _showAyahPopup(
                context,
                details.globalPosition,
                number,
                surah,
                lineText,
              );
            }
          },
      );
    }
    if (segment.semantic != null) {
      final Color color = segment.isApprox ? Colors.green : Colors.green;
      segment.isApprox ? Colors.green : Colors.green;
      return TextSpan(
        text: value,
        style: baseStyle.copyWith(
          color: color,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTapDown = (details) => _showSemanticBubble(
            context,
            details.globalPosition,
            segment.semantic!,
          ),
      );
    }
    return TextSpan(
      text: value,
      style: segment.color == null ? null : TextStyle(color: isDark ? Colors.white70 : const Color(0xFF5A4B2E),),
    );
  }

  InlineSpan buildSpaceSpan(double width) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: SizedBox(width: width),
  );

  final filteredSpaces =
      extraSpaces
          .where((entry) => entry.width > 0 && entry.position >= 0)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
  int spaceIndex = 0;

  final spans = <InlineSpan>[];
  for (final segment in segments) {
    if (segment.text.isEmpty) continue;

    int segmentCursor = segment.start;
    int textOffset = 0;

    while (segmentCursor < segment.end) {
      final insertion = spaceIndex < filteredSpaces.length
          ? filteredSpaces[spaceIndex]
          : null;

      if (insertion == null || insertion.position > segment.end) {
        final int remaining = segment.end - segmentCursor;
        if (remaining > 0) {
          final int endOffset = math.min(
            segment.text.length,
            textOffset + remaining,
          );
          if (endOffset > textOffset) {
            final span = buildTextSpan(
              segment,
              segment.text.substring(textOffset, endOffset),
            );
            if (span != null) {
              spans.add(span);
            }
            textOffset = endOffset;
          }
          segmentCursor = segment.end;
        }
        break;
      }

      if (insertion.position < segmentCursor) {
        spaceIndex++;
        continue;
      }

      final int fragmentLength = insertion.position - segmentCursor;
      if (fragmentLength > 0) {
        final int endOffset = math.min(
          segment.text.length,
          textOffset + fragmentLength,
        );
        if (endOffset > textOffset) {
          final span = buildTextSpan(
            segment,
            segment.text.substring(textOffset, endOffset),
          );
          if (span != null) {
            spans.add(span);
          }
          final int consumed = endOffset - textOffset;
          textOffset = endOffset;
          segmentCursor += consumed;
        }
      }

      spans.add(buildSpaceSpan(insertion.width));
      spaceIndex++;
    }

    if (textOffset < segment.text.length) {
      final span = buildTextSpan(segment, segment.text.substring(textOffset));
      if (span != null) {
        spans.add(span);
      }
    }
  }

  while (spaceIndex < filteredSpaces.length) {
    spans.add(buildSpaceSpan(filteredSpaces[spaceIndex].width));
    spaceIndex++;
  }

  if (spans.isEmpty) {
    spans.add(const TextSpan(text: ''));
  }
  return spans;
}

List<_TextSegment> _createSegments(
  List<ColoredChar> processedChars,
  bool isDark,
) {
  final segments = <_TextSegment>[];
  final buffer = StringBuffer();
  Color? activeColor;
  int startOffset = 0;
  int offset = 0;

  void flush() {
    if (buffer.isEmpty) return;
    segments.add(
      _TextSegment(
        text: buffer.toString(),
        start: startOffset,
        end: offset,
        color: activeColor,
      ),
    );
    buffer.clear();
  }

  for (final char in processedChars) {
    final candidate = _parseHexOrNullInherit(isDark ? char.cD : char.cL);
    final sameColor =
        (activeColor == null && candidate == null) ||
        (activeColor != null && candidate != null && activeColor == candidate);
    if (!sameColor) {
      flush();
      activeColor = candidate;
      startOffset = offset;
    }
    if (buffer.isEmpty) {
      startOffset = offset;
    }
    buffer.write(char.t);
    offset += char.t.length;
  }
  flush();

  return segments;
}

List<_TextSegment> _applyHighlightToSegments(
  List<_TextSegment> segments,
  _HighlightRange highlight,
) {
  if (highlight.start >= highlight.end) {
    return segments;
  }

  final result = <_TextSegment>[];
  for (final segment in segments) {
    if (segment.end <= highlight.start || segment.start >= highlight.end) {
      result.add(segment);
      continue;
    }

    if (highlight.start > segment.start) {
      final left = segment.slice(segment.start, highlight.start);
      if (!left.isEmpty) result.add(left);
    }

    final overlapStart = math.max(highlight.start, segment.start);
    final overlapEnd = math.min(highlight.end, segment.end);
    final middle = segment.slice(
      overlapStart,
      overlapEnd,
      semantic: highlight.entry,
      isApprox: highlight.isApprox,
    );
    if (!middle.isEmpty) result.add(middle);

    if (highlight.end < segment.end) {
      final right = segment.slice(highlight.end, segment.end);
      if (!right.isEmpty) result.add(right);
    }
  }

  return result;
}

List<_AyahMarker> _buildAyahMarkerRanges(
  List<ColoredChar> processedChars, {
  required int glyph,
  required int ayahNumber,
}) {
  final markers = <_AyahMarker>[];
  int cursor = 0;
  for (final char in processedChars) {
    final runes = char.t.runes;
    if (runes.isEmpty) {
      continue;
    }
    final rune = runes.first;
    final int length = char.t.length;
    if (rune == glyph) {
      markers.add(
        _AyahMarker(start: cursor, end: cursor + length, ayaNumber: ayahNumber),
      );
    }
    cursor += length;
  }
  return markers;
}

List<_TextSegment> _applyAyahMarkerToSegments(
  List<_TextSegment> segments,
  _AyahMarker marker,
) {
  if (marker.start >= marker.end) {
    return segments;
  }

  final result = <_TextSegment>[];
  for (final segment in segments) {
    if (segment.end <= marker.start || segment.start >= marker.end) {
      result.add(segment);
      continue;
    }

    if (marker.start > segment.start) {
      final before = segment.slice(segment.start, marker.start);
      if (!before.isEmpty) result.add(before);
    }

    final middle = segment.slice(
      marker.start,
      marker.end,
      isAyahMarker: true,
      ayahNumber: marker.ayaNumber,
    );
    if (!middle.isEmpty) result.add(middle);

    if (marker.end < segment.end) {
      final after = segment.slice(marker.end, segment.end);
      if (!after.isEmpty) result.add(after);
    }
  }

  return result;
}

// ====== Popup Bubble (Overlay) بدلاً من Dialog ======

OverlayEntry? _semanticBubble; // فقاعة واحدة نشطة فقط
void _removeSemanticBubble() {
  _semanticBubble?.remove();
  _semanticBubble = null;
}

Future<void> _showSemanticBubble(
  BuildContext context,
  Offset globalPosition,
  SemanticSpan entry,
) async {
  _removeSemanticBubble();

  final overlay = Overlay.of(context);

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final Size screen = MediaQuery.of(context).size;
  final EdgeInsets viewPadding = MediaQuery.of(context).padding;

  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
  if (overlayBox == null) return;
  final Offset pos = overlayBox.globalToLocal(globalPosition);

  final double bubbleMaxWidth = screen.width * 0.82;
  final double horizontalMargin = 8.0;
  final double verticalOffsetAbove = 56.0;
  final double verticalOffsetBelow = 12.0;

  double left = pos.dx - (bubbleMaxWidth / 2);
  double top = pos.dy - verticalOffsetAbove;
  final double minTop = viewPadding.top + 8.0;

  if (top < minTop) {
    top = pos.dy + verticalOffsetBelow;
  }

  left = left.clamp(
    horizontalMargin,
    screen.width - bubbleMaxWidth - horizontalMargin,
  );

  final Color bubbleBg = isDark
      ? _withOpacity(const Color(0xFF121620), 0.95)
      : _withOpacity(const Color(0xFFFFFEFD), 0.98);
  final Color textColor = isDark
      ? const Color(0xFFF5F6FA)
      : const Color(0xFF2C2A27);

  final String phrase = entry.tokens.trim();
  final String meaning = entry.content.trim();
  final String displayText =
      (phrase.isEmpty ? meaning : '$phrase\n$meaning').trim().isEmpty
      ? 'لا يوجد تفسير متاح.'
      : (phrase.isEmpty ? meaning : '$phrase\n$meaning');

  _semanticBubble = OverlayEntry(
    builder: (context) {
      return Stack(
        children: [
          // نقر خارج الفقاعة لإغلاقها
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeSemanticBubble,
            ),
          ),
          // الفقاعة
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _removeSemanticBubble,
                child: Container(
                  constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    borderRadius: BorderRadius.circular(14.0),
                    boxShadow: [
                      BoxShadow(
                        color: _withOpacity(Colors.black, isDark ? 0.35 : 0.15),
                        blurRadius: 14.0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A3240)
                          : const Color(0xFFE6DFCF),
                      width: 1.0,
                    ),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'UthmanicHafs',
                      fontSize: 16.0,
                      height: 1.5,
                      color: Colors.white,
                    ).copyWith(color: textColor),
                    textAlign: TextAlign.right,
                    child: Text(displayText, textDirection: TextDirection.rtl),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(_semanticBubble!);

  // إغلاق تلقائي بعد 3 ثوانٍ
  Timer(const Duration(seconds: 3), _removeSemanticBubble);
}

OverlayEntry? _ayahPopupEntry;
void _removeAyahPopup() {
  _ayahPopupEntry?.remove();
  _ayahPopupEntry = null;
}

Future<void> _showAyahPopup(
  BuildContext context,
  Offset globalPosition,
  int ayahNumber,
  int surahNumber,
  String ayahText,
) async {
  _removeAyahPopup();
  _removeSemanticBubble();

  final overlay = Overlay.of(context);
  if (overlay == null) return;

  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final Size screen = MediaQuery.of(context).size;
  final EdgeInsets viewPadding = MediaQuery.of(context).padding;
  final double bubbleMaxWidth = screen.width * 0.72;
  const double horizontalMargin = 12.0;
  const double verticalOffsetAbove = 56.0;
  const double verticalOffsetBelow = 12.0;

  final ayahDataMap = await _loadAyahData();
  final key = '$surahNumber:$ayahNumber';
  final ayahEntry = ayahDataMap[key];
  final displayAyahText = ayahEntry?.ayahText.trim().isNotEmpty == true
      ? ayahEntry!.ayahText
      : ayahText;

  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
  if (overlayBox == null) return;
  final Offset pos = overlayBox.globalToLocal(globalPosition);

  double left = pos.dx - (bubbleMaxWidth / 2);
  double top = pos.dy - verticalOffsetAbove;
  final double minTop = viewPadding.top + 8.0;
  if (top < minTop) {
    top = pos.dy + verticalOffsetBelow;
  }

  left = left.clamp(
    horizontalMargin,
    screen.width - bubbleMaxWidth - horizontalMargin,
  );

  final Color bubbleBg = isDark
      ? _withOpacity(const Color(0xFF121620), 0.95)
      : const Color(0xFFFBF8F0);
  final Color textColor = isDark
      ? const Color(0xFFF5F6FA)
      : const Color(0xFF2C2A27);

  _ayahPopupEntry = OverlayEntry(
    builder: (_) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeAyahPopup,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: bubbleBg,
                  borderRadius: BorderRadius.circular(14.0),
                  boxShadow: [
                    BoxShadow(
                      color: _withOpacity(Colors.black, isDark ? 0.35 : 0.15),
                      blurRadius: 14.0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A3240)
                        : const Color(0xFFE6DFCF),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (ayahNumber > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          'الآية ${_formatArabicNumber(ayahNumber)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                    Text(
                      displayAyahText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _ayahPopupOptions
                          .map(
                            (option) => _buildAyahPopupButton(
                              option,
                              textColor: textColor,
                              iconColor: isDark ? Colors.white : Colors.black87,
                              backgroundColor: isDark
                                  ? Colors.white12
                                  : Colors.black12,
                              onTap: () {
                                _removeAyahPopup();
                                _navigateToAyahDetail(
                                  context,
                                  ayahNumber,
                                  surahNumber,
                                  displayAyahText,
                                  option.mode,
                                  ayahEntry,
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(_ayahPopupEntry!);
}
// ====== /Popup Bubble ======

String _formatArabicNumber(int value) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  if (value == 0) {
    return digits[0];
  }
  final buffer = StringBuffer();
  int number = value.abs();
  while (number > 0) {
    buffer.write(digits[number % 10]);
    number ~/= 10;
  }
  final reversed = buffer.toString().split('').reversed.join();
  return value < 0 ? '-$reversed' : reversed;
}

enum _AyahPopupMode { copy, tafsir, translations, detail }

class _AyahPopupOption {
  final String label;
  final IconData icon;
  final _AyahPopupMode mode;

  const _AyahPopupOption({
    required this.label,
    required this.icon,
    required this.mode,
  });
}

const List<_AyahPopupOption> _ayahPopupOptions = [
  _AyahPopupOption(label: 'نسخ', icon: Icons.copy, mode: _AyahPopupMode.copy),
  _AyahPopupOption(
    label: 'التفسير',
    icon: Icons.menu_book,
    mode: _AyahPopupMode.tafsir,
  ),
  _AyahPopupOption(
    label: 'الترجمات',
    icon: Icons.translate,
    mode: _AyahPopupMode.translations,
  ),
  _AyahPopupOption(
    label: 'سبب النزول',
    icon: Icons.info,
    mode: _AyahPopupMode.detail,
  ),
];

Widget _buildAyahPopupButton(
  _AyahPopupOption option, {
  required Color textColor,
  required Color iconColor,
  required Color backgroundColor,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(8.0),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(option.icon, color: iconColor, size: 18.0),
            const SizedBox(height: 4.0),
            Text(
              option.label,
              style: TextStyle(
                color: textColor,
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _navigateToAyahDetail(
  BuildContext context,
  int ayahNumber,
  int surahNumber,
  String ayahText,
  _AyahPopupMode mode,
  _AyahData? ayahEntry,
) {
  switch (mode) {
    case _AyahPopupMode.copy:
      Clipboard.setData(ClipboardData(text: ayahText));
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'تم نسخ الآية ${_formatArabicNumber(ayahNumber)}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      break;
    case _AyahPopupMode.tafsir:
      _showAyahTafsirSheet(
        context,
        ayahEntry?.tafseer ?? const <_AyahTafsir>[],
        ayahText,
        surahNumber,
        ayahNumber,
      );
      break;
    case _AyahPopupMode.translations:
      _showAyahTranslationSheet(
        context,
        ayahEntry?.translations ?? const <_AyahTranslation>[],
        ayahText,
        surahNumber,
        ayahNumber,
      );
      break;
    case _AyahPopupMode.detail:
      _showAyahDetailDialog(
        context,
        surahNumber,
        ayahNumber,
        ayahText,
        ayahEntry,
      );
      break;
  }
}

void _showAyahTafsirSheet(
  BuildContext context,
  List<_AyahTafsir> tafseer,
  String ayahText,
  int surahNumber,
  int ayahNumber,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18.0)),
    ),
    builder: (sheetContext) {
      final maxHeight = MediaQuery.of(sheetContext).size.height * 0.75;
      final hasTafsir = tafseer.isNotEmpty;
      int selectedIndex = 0;
      return StatefulBuilder(
        builder: (stateContext, setState) {
          final int safeIndex = hasTafsir
              ? math.min(selectedIndex, tafseer.length - 1)
              : 0;
          final _AyahTafsir? selectedTafsir = hasTafsir
              ? tafseer[safeIndex]
              : null;
          return Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 12.0,
              left: 16.0,
              right: 16.0,
              top: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    height: 4.0,
                    width: 40.0,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'سورة $surahNumber - الآية ${_formatArabicNumber(ayahNumber)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 10.0),
                Text(
                  ayahText,
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 21.0,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12.0),
                if (hasTafsir) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'اختر التفسير:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          sheetContext,
                        ).textTheme.bodyLarge?.color,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  DropdownButton<int>(
                    value: safeIndex,
                    isExpanded: true,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedIndex = value);
                    },
                    items: tafseer
                        .asMap()
                        .entries
                        .map(
                          (entry) => DropdownMenuItem<int>(
                            value: entry.key,
                            child: Text(
                              entry.value.name.isNotEmpty
                                  ? entry.value.name
                                  : entry.value.code,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ] else ...[
                  const Text(
                    'لا توجد تفاسير إضافية متوفرة.',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ],
                const SizedBox(height: 6.0),
                Expanded(
                  child: SingleChildScrollView(
                    child: selectedTafsir != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                selectedTafsir.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                selectedTafsir.text,
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          )
                        : const Text(
                            'لا يوجد تفسير متاح لهذه الآية حالياً.',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showAyahDetailDialog(
  BuildContext context,
  int surahNumber,
  int ayahNumber,
  String ayahText,
  _AyahData? ayahEntry,
) {
  final reasons = ayahEntry?.reasons ?? const <String>[];
  final String? reasonText = reasons.isNotEmpty ? reasons.first.trim() : null;
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          'السورة $surahNumber - الآية ${_formatArabicNumber(ayahNumber)}',
          textDirection: TextDirection.rtl,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ayahText,
                style: const TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 22.0,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12.0),
              const Text(
                'أسباب النزول',
                style: TextStyle(fontWeight: FontWeight.w700),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 6.0),
              Text(
                reasonText ?? 'لا يوجد سبب نزول موثَّق لهذه الآية.',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      );
    },
  );
}

class _AyahMarker {
  final int start;
  final int end;
  final int ayaNumber;

  const _AyahMarker({
    required this.start,
    required this.end,
    required this.ayaNumber,
  });
}

void _showAyahTranslationSheet(
  BuildContext context,
  List<_AyahTranslation> translations,
  String ayahText,
  int surahNumber,
  int ayahNumber,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18.0)),
    ),
    builder: (sheetContext) {
      final maxHeight = MediaQuery.of(sheetContext).size.height * 0.75;
      final bool hasTranslations = translations.isNotEmpty;
      final int englishIndex = translations.indexWhere(
        (entry) => entry.langCode.toLowerCase() == 'en',
      );
      int selectedIndex = hasTranslations
          ? (englishIndex >= 0 ? englishIndex : 0)
          : 0;
      return StatefulBuilder(
        builder: (stateContext, setState) {
          final _AyahTranslation? selectedTranslation = hasTranslations
              ? translations[selectedIndex]
              : null;
          return Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 12.0,
              left: 16.0,
              right: 16.0,
              top: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    height: 4.0,
                    width: 40.0,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'سورة $surahNumber - الآية ${_formatArabicNumber(ayahNumber)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 10.0),
                Text(
                  ayahText,
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 21.0,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12.0),
                if (hasTranslations) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'اختر الترجمة:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          sheetContext,
                        ).textTheme.bodyLarge?.color,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  DropdownButton<int>(
                    value: selectedIndex,
                    isExpanded: true,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedIndex = value);
                    },
                    items: translations
                        .asMap()
                        .entries
                        .map(
                          (entry) => DropdownMenuItem<int>(
                            value: entry.key,
                            child: Text(
                              entry.value.langName.isNotEmpty
                                  ? entry.value.langName
                                  : entry.value.langCode,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ] else ...[
                  const Text(
                    'لا توجد ترجمات متاحة حالياً.',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ],
                const SizedBox(height: 6.0),
                Expanded(
                  child: SingleChildScrollView(
                    child: selectedTranslation != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                selectedTranslation.langName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                selectedTranslation.translatedText,
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          )
                        : const Text(
                            'لا يوجد ترجمة متاحة لهذه الآية حالياً.',
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _HighlightRange {
  final int start;
  final int end;
  final SemanticSpan entry;

  /// true = تطابق تقريبي (يُلوَّن أخضر), false = تطابق أصلي (أحمر)
  final bool isApprox;

  _HighlightRange({
    required this.start,
    required this.end,
    required this.entry,
    this.isApprox = false,
  });
}

class _ExtraSpaceInsertion {
  final int position;
  final double width;

  const _ExtraSpaceInsertion({required this.position, required this.width});
}

class _TextSegment {
  final String text;
  final int start;
  final int end;
  final Color? color;
  final SemanticSpan? semantic;
  final bool isApprox;
  final bool isAyahMarker;
  final int? ayahNumber;

  const _TextSegment({
    required this.text,
    required this.start,
    required this.end,
    required this.color,
    this.semantic,
    this.isApprox = false,
    this.isAyahMarker = false,
    this.ayahNumber,
  });

  bool get isEmpty => text.isEmpty;

  _TextSegment slice(
    int sliceStart,
    int sliceEnd, {
    SemanticSpan? semantic,
    bool? isApprox,
    bool? isAyahMarker,
    int? ayahNumber,
  }) {
    final localStart = math.max(0, sliceStart - start);
    final localEnd = math.min(text.length, sliceEnd - start);
    if (localStart >= localEnd) {
      return _TextSegment(
        text: '',
        start: sliceStart,
        end: sliceStart,
        color: color,
        semantic: semantic ?? this.semantic,
        isApprox: isApprox ?? this.isApprox,
        isAyahMarker: isAyahMarker ?? this.isAyahMarker,
        ayahNumber: ayahNumber ?? this.ayahNumber,
      );
    }

    return _TextSegment(
      text: text.substring(localStart, localEnd),
      start: sliceStart,
      end: sliceEnd,
      color: color,
      semantic: semantic ?? this.semantic,
      isApprox: isApprox ?? this.isApprox,
      isAyahMarker: isAyahMarker ?? this.isAyahMarker,
      ayahNumber: ayahNumber ?? this.ayahNumber,
    );
  }
}

bool _isAllWhitespace(String text) {
  if (text.isEmpty) {
    return true;
  }
  final normalized = text.replaceAll('\u00A0', ' ').trim();
  return normalized.isEmpty;
}

List<ColoredChar> _trimTrailingSpaces(List<ColoredChar> chars) {
  var end = chars.length;
  while (end > 0 && _isWhitespaceChar(chars[end - 1].t)) {
    end--;
  }
  return chars.sublist(0, end);
}

bool _isWhitespaceChar(String value) => value == ' ' || value == '\u00A0';

double _solvePerGap({
  required String text,
  required TextStyle baseStyle,
  required double targetWidth,
  required int gaps,
}) {
  if (gaps <= 0) {
    return 0.0;
  }

  final w0 = _measureWithWordSpacing(text, baseStyle, 0);
  double per = math.max(0.0, (targetWidth - w0) / gaps);

  for (int i = 0; i < 6; i++) {
    final width = _measureWithWordSpacing(text, baseStyle, per);
    final error = width - targetWidth;
    if (error.abs() <= 0.25) {
      break;
    }
    per -= error / gaps;
    if (per < 0) {
      per = 0;
      break;
    }
  }
  return per;
}

double desiredWidthForThisLine(double desired, double intrinsic) =>
    math.max(desired, intrinsic);

double _normalizeLineSpacing({
  required double rawVPad,
  required double scriptFontSize,
  required int pageIndex,
  ValueChanged<double>? onLineHeightRegistered,
}) {
  final double lineHeight = scriptFontSize * 2.0 + (rawVPad * 2);
  if (pageIndex == 5) {
    final bool shouldNotify = _pageFiveLineHeightReference == null;
    _pageFiveLineHeightReference = lineHeight;
    if (shouldNotify) {
      onLineHeightRegistered?.call(lineHeight);
    }
    return rawVPad;
  }
  final reference = _pageFiveLineHeightReference;
  if (reference == null || lineHeight >= reference) {
    return rawVPad;
  }
  final double extraVPad = (reference - lineHeight) / 2.0;
  return rawVPad + extraVPad;
}

double _lineFontSizeForScrollMode({
  required double baseFontSize,
  required double measuredWidthAtBaseFont,
  required double targetWidth,
  required double minFontSize,
  required double maxFontSize,
  required bool enable,
}) {
  final double constrainedBase = baseFontSize.clamp(minFontSize, maxFontSize);
  if (!enable || measuredWidthAtBaseFont <= 0 || targetWidth <= 0) {
    return constrainedBase;
  }
  final double scale = targetWidth / measuredWidthAtBaseFont;
  if (scale <= 1.0) {
    return constrainedBase;
  }
  return (constrainedBase * scale).clamp(minFontSize, maxFontSize);
}

class _LineLayout {
  _LineLayout({
    required this.lineFontSize,
    required this.perGap,
    required this.targetWidth,
    required this.intrinsicWidth,
    required this.extraSpaces,
  });

  final double lineFontSize;
  final double perGap;
  final double targetWidth;
  final double intrinsicWidth;
  final List<_ExtraSpaceInsertion> extraSpaces;

  factory _LineLayout.fromMetrics(LineLayoutMetrics metrics) => _LineLayout(
    lineFontSize: metrics.lineFontSize,
    perGap: metrics.perGap,
    targetWidth: metrics.targetWidth,
    intrinsicWidth: metrics.intrinsicWidth,
    extraSpaces: metrics.extraSpaces
        .map(
          (item) =>
              _ExtraSpaceInsertion(position: item.position, width: item.width),
        )
        .toList(),
  );

  LineLayoutMetrics toMetrics() => LineLayoutMetrics(
    lineFontSize: lineFontSize,
    perGap: perGap,
    targetWidth: targetWidth,
    intrinsicWidth: intrinsicWidth,
    extraSpaces: extraSpaces
        .map(
          (space) =>
              ExtraSpaceRecord(position: space.position, width: space.width),
        )
        .toList(),
  );
}

bool _isLastAyahOfSurah(RenderedLine line) {
  final total = kSurahAyahCounts[line.surahIndexFirst];
  if (total == null) return false;
  return line.ayahIndexFirst >= total;
}

String? _lookupSurahName(int? index, Map<int, String> lookup) {
  if (index == null || index <= 0) {
    return null;
  }
  final mapped = lookup[index];
  if (mapped != null && mapped.isNotEmpty) {
    return mapped;
  }
  if (index <= kFallbackSurahNames.length) {
    return kFallbackSurahNames[index - 1];
  }
  return 'سورة $index';
}

class _FrameCornerLabel extends StatelessWidget {
  const _FrameCornerLabel({
    required this.text,
    required this.u,
    required this.alignment,
  });

  final String text;
  final double u;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final baseColor = isDark
        ? const Color.fromARGB(230, 20, 24, 32)
        : const Color.fromARGB(230, 247, 240, 223);
    final Color labelTextColor = isDark
        ? colorScheme.onSurface
        : colorScheme.onSecondaryContainer;

    return Align(
      alignment: alignment,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC39A3C)),
          color: baseColor,
          borderRadius: BorderRadius.circular(1 * u),
        ),
        child: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  text,
                  textDirection: TextDirection.rtl,
                  textAlign: alignment == Alignment.centerRight
                      ? TextAlign.right
                      : TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',

                    fontSize: ResponsiveTypography.body(u) / 1.3,
                    color: labelTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// يمثل كلمة في السطر مع حدودها في الـ string
class _WordInfo {
  final String text;
  final int start;
  final int end;

  _WordInfo({required this.text, required this.start, required this.end});
}

/// استخراج الكلمات من السطر مع start/end لكل كلمة
List<_WordInfo> _extractWordsWithIndices(String text) {
  final words = <_WordInfo>[];
  final buffer = StringBuffer();
  int? startIndex;

  for (int i = 0; i < text.length; i++) {
    final ch = text[i];
    final isSpace = ch == ' ' || ch == '\u00A0';

    if (isSpace) {
      if (buffer.isNotEmpty && startIndex != null) {
        final wordText = buffer.toString();
        words.add(_WordInfo(text: wordText, start: startIndex, end: i));
        buffer.clear();
        startIndex = null;
      }
    } else {
      if (buffer.isEmpty) {
        startIndex = i;
      }
      buffer.write(ch);
    }
  }

  if (buffer.isNotEmpty && startIndex != null) {
    words.add(
      _WordInfo(text: buffer.toString(), start: startIndex, end: text.length),
    );
  }

  return words;
}

/// إيجاد الكلمة التي تتقاطع مع span معين (start/end)
int? _findWordIndexOverlappingSpan(
  List<_WordInfo> words,
  int spanStart,
  int spanEnd,
) {
  for (int i = 0; i < words.length; i++) {
    final w = words[i];
    final bool noOverlap = w.end <= spanStart || w.start >= spanEnd;
    if (!noOverlap) {
      return i;
    }
  }
  return null;
}

/// تطبيع الكلمة للمقارنة (إزالة المسافات بين الحروف، التطويل، التشكيل)
String _normalizeWordForCompare(String input) {
  // إزالة كل المسافات (حتى "ا ل ل ه" تصبح "الله")
  var s = input.replaceAll(RegExp(r'\s+'), '');

  // إزالة التطويل
  s = s.replaceAll('\u0640', '');

  // إزالة التشكيل والحركات
  s = s.replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670]'), '');

  return s;
}

bool _shouldSkipApproxColoring(String normalizedCandidate) {
  if (normalizedCandidate.isEmpty) return false;
  return _isDivineWord(normalizedCandidate);
}

bool _isDivineWord(String normalized) {
  if (normalized.isEmpty) return false;
  final canonical = normalized
      .replaceAll('\u0671', '\u0627') // ألف وصل → ألف عادية
      .replaceAll('\u0622', '\u0627')
      .replaceAll('\u0623', '\u0627')
      .replaceAll('\u0625', '\u0627');

  for (final marker in _kDivineWordMarkers) {
    if (canonical.contains(marker)) {
      return true;
    }
  }
  return false;
}

const List<String> _kDivineWordMarkers = ['الله', 'لله'];

/// تشابه تقريبي بسيط باستخدام Levenshtein ratio
double _similarityRatio(String a, String b) {
  if (a == b) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;

  final dist = _levenshteinDistance(a, b);
  final maxLen = math.max(a.length, b.length);
  return 1.0 - (dist / maxLen);
}

int _levenshteinDistance(String s, String t) {
  final m = s.length;
  final n = t.length;

  if (m == 0) return n;
  if (n == 0) return m;

  final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));

  for (int i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (int j = 0; j <= n; j++) {
    dp[0][j] = j;
  }

  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      final cost = s[i - 1] == t[j - 1] ? 0 : 1;
      dp[i][j] = math.min(
        math.min(
          dp[i - 1][j] + 1, // حذف
          dp[i][j - 1] + 1, // إضافة
        ),
        dp[i - 1][j - 1] + cost, // استبدال
      );
    }
  }

  return dp[m][n];
}

/// يبني قائمة الهايلايت مع دعم:
/// - تلوين الكلمة الأصلية (مثلاً رقم 5) بالأحمر
/// - تلوين الكلمات السابقة [4..1] بالأخضر إذا التشابه >= threshold
List<_HighlightRange> _buildHighlightsWithApproxMatches({
  required String text,
  required List<ColoredChar> chars,
  required List<SemanticSpan> spans,
  double similarityThreshold = 0.5,
}) {
  final result = <_HighlightRange>[];

  if (spans.isEmpty) return result;

  final words = _extractWordsWithIndices(text);
  if (words.isEmpty) {
    // fallback: نعيد الهايلايت الأصلي فقط
    for (final span in spans) {
      result.add(
        _HighlightRange(
          start: span.start,
          end: span.start + span.length,
          entry: span,
          isApprox: false,
        ),
      );
    }
    return result;
  }

  for (final span in spans) {
    final int spanStart = span.start;
    final int spanEnd = span.start + span.length;

    // الكلمة/المقطع المكتشف (مثلاً رقم 5) → أحمر
    result.add(
      _HighlightRange(
        start: spanStart,
        end: spanEnd,
        entry: span,
        isApprox: false,
      ),
    );

    final String tokens = span.tokens.trim();
    if (tokens.isEmpty) continue;

    final phraseWords = tokens.split(RegExp(r'\s+'));
    if (phraseWords.length <= 1) {
      // عبارة من كلمة واحدة فقط: لا يوجد 4..1
      continue;
    }

    final baseWordIndex = _findWordIndexOverlappingSpan(
      words,
      spanStart,
      spanEnd,
    );
    if (baseWordIndex == null) continue;

    final int lastIdxInPhrase = phraseWords.length - 1;

    // نبدأ من الكلمة السابقة (lastIdxInPhrase-1) ونرجع للخلف:
    int currentWordIndexInText = baseWordIndex - 1;

    for (
      int j = lastIdxInPhrase - 1;
      j >= 0 && currentWordIndexInText >= 0;
      j--, currentWordIndexInText--
    ) {
      final expected = phraseWords[j];
      final candidate = words[currentWordIndexInText];

      final normExpected = _normalizeWordForCompare(expected);
      final normCandidate = _normalizeWordForCompare(candidate.text);

      if (normExpected.isEmpty || normCandidate.isEmpty) {
        break;
      }

      final sim = _similarityRatio(normExpected, normCandidate);
      if (sim >= similarityThreshold) {
        if (!_shouldSkipApproxColoring(normCandidate)) {
          // تطابق تقريبي ناجح → نلوّن هذه الكلمة بالأخضر
          result.add(
            _HighlightRange(
              start: candidate.start,
              end: candidate.end,
              entry: span,
              isApprox: true,
            ),
          );
        }
      } else {
        // أول فشل → نوقف الرجوع (لا نفحص 3..1)
        break;
      }
    }
  }

  return result;
}
