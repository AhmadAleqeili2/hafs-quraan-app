part of tajweed_viewer;

class ResponsiveTypography {
  const ResponsiveTypography._();

  static double _scale(double unit) {
    final normalized = unit <= 0 ? 4.0 : unit;
    return (normalized / 4.0).clamp(0.8, 1.1);
  }

  static double mushafScript(double unit) {
    final size = kBaseFontSize * _scale(unit);
    return size.clamp(10.0, 30.0);
  }

  static double surahTitle(double unit) {
    final size = mushafScript(unit) * 1.35;
    return size.clamp(24.0, 44.0);
  }

  static double pageBadge(double unit) {
    final size = mushafScript(unit) * 0.7;
    return size.clamp(12.0, 22.0);
  }

  static double body(double unit) {
    final size = mushafScript(unit) * 0.9;
    return size.clamp(16.0, 26.0);
  }
}
