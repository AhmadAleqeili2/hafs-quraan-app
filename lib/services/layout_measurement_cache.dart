part of tajweed_viewer;

class LayoutMeasurementCache {
  LayoutMeasurementCache._();

  static final LayoutMeasurementCache instance = LayoutMeasurementCache._();

  final Map<String, _SizeCacheEntry> _entries = {};
  bool _initialized = false;
  bool _persistScheduled = false;
  File? _file;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    final cacheFile = File(
      path.join(dir.path, 'tajweed_layout_measurements.json'),
    );
    _file = cacheFile;
    if (await cacheFile.exists()) {
      try {
        final content = await cacheFile.readAsString();
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _entries[key] = _SizeCacheEntry.fromJson(
            value as Map<String, dynamic>,
          );
        });
      } catch (_) {
        // ignore parse errors and start fresh
      }
    }
    _initialized = true;
  }

  String sizeKey(double width, double height) =>
      '${width.toStringAsFixed(2)}x${height.toStringAsFixed(2)}';

  PageLayoutMetrics? pageLayoutFor(int pageIndex, String sizeKey) =>
      _entries[sizeKey]?.pages[pageIndex];

  void storePageLayout({
    required int pageIndex,
    required String sizeKey,
    required double width,
    required double height,
    required PageLayoutMetrics metrics,
  }) {
    final entry = _entries.putIfAbsent(
      sizeKey,
      () => _SizeCacheEntry(width: width, height: height),
    );
    if (entry.pages.containsKey(pageIndex)) return;
    entry.pages[pageIndex] = metrics;
    _schedulePersist();
  }

  void _schedulePersist() {
    if (_persistScheduled) return;
    _persistScheduled = true;
    scheduleMicrotask(() async {
      _persistScheduled = false;
      await _persistToFile();
    });
  }

  Future<void> _persistToFile() async {
    if (!_initialized) {
      await ensureInitialized();
    }
    final file = _file;
    if (file == null) return;
    final data = <String, dynamic>{};
    for (final entry in _entries.entries) {
      data[entry.key] = entry.value.toJson();
    }
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }
}

class _SizeCacheEntry {
  _SizeCacheEntry({
    required this.width,
    required this.height,
    Map<int, PageLayoutMetrics>? pages,
  }) : pages = pages ?? {};

  final double width;
  final double height;
  final Map<int, PageLayoutMetrics> pages;

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'pages': {
      for (final entry in pages.entries)
        entry.key.toString(): entry.value.toJson(),
    },
  };

  factory _SizeCacheEntry.fromJson(Map<String, dynamic> json) {
    final width = (json['width'] as num?)?.toDouble() ?? 0.0;
    final height = (json['height'] as num?)?.toDouble() ?? 0.0;
    final pagesJson = json['pages'] as Map<String, dynamic>? ?? {};
    final pages = <int, PageLayoutMetrics>{};
    pagesJson.forEach((key, value) {
      final pageIndex = int.tryParse(key);
      if (pageIndex != null) {
        pages[pageIndex] = PageLayoutMetrics.fromJson(
          value as Map<String, dynamic>,
        );
      }
    });
    return _SizeCacheEntry(width: width, height: height, pages: pages);
  }
}

class PageLayoutMetrics {
  PageLayoutMetrics({
    required this.lineHeight,
    required this.scriptFontSize,
    required this.vPad,
    required this.lines,
  });

  final double lineHeight;
  final double scriptFontSize;
  final double vPad;
  final List<LineLayoutMetrics> lines;

  Map<String, dynamic> toJson() => {
    'lineHeight': lineHeight,
    'scriptFontSize': scriptFontSize,
    'vPad': vPad,
    'lines': lines.map((line) => line.toJson()).toList(),
  };

  factory PageLayoutMetrics.fromJson(Map<String, dynamic> json) {
    final linesList =
        (json['lines'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>()
            .map((entry) => LineLayoutMetrics.fromJson(entry))
            .toList() ??
        [];
    return PageLayoutMetrics(
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 0.0,
      scriptFontSize: (json['scriptFontSize'] as num?)?.toDouble() ?? 0.0,
      vPad: (json['vPad'] as num?)?.toDouble() ?? 0.0,
      lines: linesList,
    );
  }
}

class LineLayoutMetrics {
  LineLayoutMetrics({
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
  final List<ExtraSpaceRecord> extraSpaces;

  Map<String, dynamic> toJson() => {
    'lineFontSize': lineFontSize,
    'perGap': perGap,
    'targetWidth': targetWidth,
    'intrinsicWidth': intrinsicWidth,
    'extraSpaces': extraSpaces.map((space) => space.toJson()).toList(),
  };

  factory LineLayoutMetrics.fromJson(Map<String, dynamic> json) {
    final extraSpacesList =
        (json['extraSpaces'] as List<dynamic>?)
            ?.map(
              (entry) =>
                  ExtraSpaceRecord.fromJson(entry as Map<String, dynamic>),
            )
            .toList() ??
        [];
    return LineLayoutMetrics(
      lineFontSize: (json['lineFontSize'] as num?)?.toDouble() ?? 0.0,
      perGap: (json['perGap'] as num?)?.toDouble() ?? 0.0,
      targetWidth: (json['targetWidth'] as num?)?.toDouble() ?? 0.0,
      intrinsicWidth: (json['intrinsicWidth'] as num?)?.toDouble() ?? 0.0,
      extraSpaces: extraSpacesList,
    );
  }
}

class ExtraSpaceRecord {
  ExtraSpaceRecord({required this.position, required this.width});

  final int position;
  final double width;

  Map<String, dynamic> toJson() => {'position': position, 'width': width};

  factory ExtraSpaceRecord.fromJson(Map<String, dynamic> json) {
    return ExtraSpaceRecord(
      position: (json['position'] as int?) ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
