part of tajweed_viewer;

class SurahHeaderFrame extends StatelessWidget {
  const SurahHeaderFrame({
    super.key,
    required this.title,
    required this.u,
    this.fullWidth = false,
  });

  final String title;
  final double u;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? const Color(0xFFE2C375) : const Color(0xFFC39A3C);
    final goldDeep = isDark ? const Color(0xFFB08A34) : const Color(0xFF9F7A2E);

    final double outerHorizontal = fullWidth ? 1.2 * u : 2.4 * u;
    final double outerVertical = fullWidth ? 0.5 * u : 0.8 * u;
    final double radius = fullWidth ? 1.6 * u : 2.8 * u;
    final double textFont = fullWidth
        ? (ResponsiveTypography.body(u) * 1.18)
        : (ResponsiveTypography.body(u) * 1.32);

    final gradient = LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [
        isDark ? const Color(0xFF1E2431) : const Color(0xFFF7EFD7),
        isDark ? const Color(0xFF181E29) : const Color(0xFFF2E1BE),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: outerHorizontal,
        vertical: outerVertical,
      ),
      child: Container(
        width: fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: gold.withOpacity(0.85), width: 0.12 * u),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.12),
              blurRadius: 1.2 * u,
              offset: Offset(0, 0.5 * u),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      gold.withOpacity(0.0),
                      gold.withOpacity(0.22),
                      gold.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: fullWidth ? 1.8 * u : 2.6 * u,
                vertical: fullWidth ? 0.9 * u : 1.1 * u,
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontSize: textFont,
                  color: isDark ? Colors.white : goldDeep,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.white.withOpacity(0.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
