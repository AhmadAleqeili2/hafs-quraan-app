class ArabicText {
  ArabicText(this._text);

  final String _text;

  /// Removes tashkeel and additional combining marks so we can match tokens.
  String toCharactersWithoutDiacritics() {
    final diacritics = RegExp(
      r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
      unicode: true,
    );
    return _text.replaceAll(diacritics, '');
  }
}
