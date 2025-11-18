part of tajweed_viewer;

class QuranPageFrame extends StatelessWidget {
  const QuranPageFrame({
    super.key,
    required this.child,
    required this.u,
    this.outerRadius,
    this.heightFactor,
  });

  final Widget child;
  final double u;
  final double? outerRadius;
  final double? heightFactor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF9F6EF);
    final gold = isDark ? const Color(0xFFE2C375) : const Color(0xFFC39A3C);
    final goldLight = isDark
        ? const Color(0xFFF3E3B0)
        : const Color(0xFFE7D19A);
    final double verticalScale =
        heightFactor == null ? 1.0 : heightFactor!.clamp(0.6, 1.3);

    final double framePaddingH = 2.2 * u;
    final double framePaddingV = 2.4 * u * verticalScale;
    final double edgeHeight = 2.4 * u * verticalScale;
    final double contentRadius = outerRadius ?? (1.6 * u);

    Widget buildEdge({required bool top}) {
      return Container(
        alignment: Alignment.center,
        height: edgeHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? Alignment.topCenter : Alignment.bottomCenter,
            end: top ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [
              gold.withOpacity(0.85),
              goldLight.withOpacity(0.95),
              gold.withOpacity(0.45),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.12),
              blurRadius: 1.6 * u,
              offset: Offset(0, top ? 0.6 * u : -0.6 * u),
            ),
          ],
        ),
      );
    }

    final content = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bg.withOpacity(isDark ? 0.92 : 0.98),
            (isDark ? const Color(0xFF141922) : const Color(0xFFF1E7D3))
                .withOpacity(0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(contentRadius),
        border: Border(
          top: BorderSide(color: goldLight.withOpacity(0.4), width: 0.1 * u),
          bottom: BorderSide(color: goldLight.withOpacity(0.4), width: 0.1 * u),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.12),
            blurRadius: 2.1 * u,
            offset: Offset(0, 1.2 * u),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: framePaddingH,
          vertical: framePaddingV,
        ),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.015 * verticalScale,
            ),
            child,
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.015 * verticalScale,
            ),
          ],
        ),
      ),
    );

    final frame = Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 1.2 * u * verticalScale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildEdge(top: true),
          SizedBox(height: 0.8 * u * verticalScale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.4 * u),
            child: content,
          ),
          SizedBox(height: 0.8 * u * verticalScale),
          buildEdge(top: false),
        ],
      ),
    );
    return frame;
  }
}
