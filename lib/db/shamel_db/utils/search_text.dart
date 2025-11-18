class SearchText {
  SearchText(this._text);

  final String _text;

  /// Normalises spacing and strips characters that would break LIKE queries.
  String toCleanup() {
    final cleaned = _text
        .replaceAll(RegExp(r'[^\u0600-\u06FF0-9A-Za-z\s]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }
}
