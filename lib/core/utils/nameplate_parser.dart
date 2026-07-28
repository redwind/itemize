import 'package:flutter/foundation.dart';

/// What could be read off a product's label.
///
/// Any field may be null: a label that does not say is better represented as
/// silence than as a guess the owner then has to notice and undo.
@immutable
class NameplateInfo {
  final String? brand;
  final String? model;
  final String? serialNumber;

  const NameplateInfo({this.brand, this.model, this.serialNumber});

  bool get isEmpty => brand == null && model == null && serialNumber == null;

  int get fieldCount =>
      (brand == null ? 0 : 1) +
      (model == null ? 0 : 1) +
      (serialNumber == null ? 0 : 1);
}

/// Reads the rating plate stuck to the back of almost everything people own.
///
/// This replaced an online barcode lookup, and does more than it did. A barcode
/// identifies a *product* — something the owner is looking straight at and could
/// type in seconds. The plate carries the *serial number*, which is unique to
/// their particular unit, is long enough to mistype, and is the field an insurer
/// asks for by name. No database anywhere can supply it.
///
/// Everything here runs on the device against text the bundled recognizer has
/// already produced. It costs nothing per scan and works with the phone in
/// aeroplane mode, which the online lookup could claim neither of.
class NameplateParser {
  const NameplateParser._();

  /// Label spellings seen on real plates, longest first so that `serial no`
  /// wins over the bare `sn` hiding inside it.
  static const List<String> _serialKeys = [
    'serial number',
    'serial no',
    'serial nr',
    'ser no',
    'serial',
    'so may',
    's/n',
    'sn',
    'p/n',
  ];

  static const List<String> _modelKeys = [
    'model number',
    'model no',
    'model nr',
    'model name',
    'modell',
    'model',
    'm/n',
    'mod',
    'type no',
    'type',
  ];

  /// Words that appear on plates and are never the manufacturer.
  static const Set<String> _notBrands = {
    'made in china',
    'made in japan',
    'made in korea',
    'made in vietnam',
    'caution',
    'warning',
    'danger',
    'specifications',
    'rating',
    'input',
    'output',
    'voltage',
    'power',
  };

  static NameplateInfo parse(String rawText) {
    final lines =
        rawText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    return NameplateInfo(
      serialNumber: _valueFor(lines, _serialKeys, _looksLikeSerial),
      model: _valueFor(lines, _modelKeys, _looksLikeModel),
      brand: _brandFrom(lines),
    );
  }

  /// Finds the value belonging to one of [keys].
  ///
  /// Plates put the value after the label on the same line, and just as often
  /// on the line below when the print is stacked, so both are tried. The value
  /// still has to pass [accept]: a label followed by nothing useful should
  /// leave the field empty rather than capture whatever came next.
  static String? _valueFor(
    List<String> lines,
    List<String> keys,
    bool Function(String) accept,
  ) {
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();

      for (final key in keys) {
        final at = lower.indexOf(key);
        if (at == -1) continue;
        // Only a label when it starts the line or follows punctuation --
        // otherwise `type` matches the middle of an unrelated sentence.
        if (at > 0 && RegExp(r'[a-z0-9]').hasMatch(lower[at - 1])) continue;

        final sameLine = _clean(lines[i].substring(at + key.length));
        if (accept(sameLine)) return sameLine;

        // Stacked label: the value is on the next line, but only if that line
        // is not itself another label.
        if (sameLine.isEmpty && i + 1 < lines.length) {
          final below = _clean(lines[i + 1]);
          if (!_isLabelLine(lines[i + 1]) && accept(below)) return below;
        }
      }
    }
    return null;
  }

  /// Strips the punctuation a label leaves behind: `: `, `- `, `. `, `#`.
  static String _clean(String value) =>
      value.replaceAll(RegExp(r'^[\s:.\-#=]+'), '').trim();

  static bool _isLabelLine(String line) {
    final lower = line.toLowerCase();
    return [
      ..._serialKeys,
      ..._modelKeys,
    ].any((key) => lower.startsWith(key));
  }

  /// A serial is long, and carries at least one digit.
  ///
  /// The digit requirement is what keeps a stray word following the label from
  /// being recorded as somebody's serial number.
  static bool _looksLikeSerial(String value) {
    if (value.length < 4 || value.length > 32) return false;
    if (!RegExp(r'\d').hasMatch(value)) return false;
    return RegExp(r'^[A-Za-z0-9][A-Za-z0-9\-/ ]*$').hasMatch(value);
  }

  /// A model may be all letters -- `KIVIK`, `CLASSIC` -- so digits are not
  /// required, but it is still short and free of spaces-heavy prose.
  static bool _looksLikeModel(String value) {
    if (value.length < 2 || value.length > 32) return false;
    if (value.split(RegExp(r'\s+')).length > 4) return false;
    return RegExp(r'^[A-Za-z0-9][A-Za-z0-9\-/. ]*$').hasMatch(value);
  }

  /// The manufacturer, guessed from the top of the plate.
  ///
  /// Brands are printed large and first, so the recognizer generally puts them
  /// in the opening lines. Only the first few are considered, and anything that
  /// reads as a labelled field or as boilerplate is skipped. Returns null
  /// rather than reaching further down, because by then it is guessing.
  static String? _brandFrom(List<String> lines) {
    for (final line in lines.take(4)) {
      final lower = line.toLowerCase();
      if (_isLabelLine(line)) continue;
      if (_notBrands.any(lower.contains)) continue;
      if (line.contains(':')) continue;

      final words = line.split(RegExp(r'\s+'));
      if (words.length > 3) continue;
      if (line.length < 2 || line.length > 24) continue;
      // Mostly letters: a line of numbers is a rating, not a maker.
      final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
      if (letters < line.length * 0.6) continue;

      return line;
    }
    return null;
  }
}
