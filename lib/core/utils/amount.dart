import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Reads a sum of money the way the person typing it meant it.
///
/// The number pad a French or German phone puts up has a comma where an
/// English one has a full stop, and [double.tryParse] accepts only the full
/// stop. So `1299,99` parsed as null, every call site folded that null into
/// zero, and the price field's only validation was that something had been
/// typed -- which it had. The washing machine was stored as costing nothing,
/// silently, and the dashboard total, the depreciation estimate, the
/// under-insured warning and the insurance report all quietly agreed with it.
///
/// Returns null when the text is not a number at all, so a caller can say so
/// rather than write a zero into the one figure the whole app is about.
double? parseAmount(String raw, {String locale = 'en'}) {
  // Currency symbols, spaces, and the non-breaking and narrow no-break spaces
  // French grouping uses, all thrown away before anything is decided.
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.,\-]'), '');
  if (cleaned.isEmpty) return null;

  final negative = cleaned.startsWith('-');
  final digits = cleaned.replaceAll('-', '');
  if (digits.isEmpty) return null;

  final separator = _decimalSeparatorIn(digits, locale);

  final String normalised;
  if (separator == null) {
    // Every separator present is grouping: 1.234.567, or 1,234,567.
    normalised = digits.replaceAll(RegExp(r'[.,]'), '');
  } else {
    final grouping = separator == '.' ? ',' : '.';
    normalised = digits.replaceAll(grouping, '').replaceAll(separator, '.');
  }

  final value = double.tryParse(normalised);
  if (value == null) return null;
  return negative ? -value : value;
}

/// Which separator in [digits] is the decimal point, or null when they are all
/// grouping marks.
String? _decimalSeparatorIn(String digits, String locale) {
  final lastDot = digits.lastIndexOf('.');
  final lastComma = digits.lastIndexOf(',');

  // Both kinds present, so the rightmost is the decimal point and the other is
  // grouping. True of 1.234,56 and of 1,234.56 alike, whatever the locale.
  if (lastDot >= 0 && lastComma >= 0) {
    return lastDot > lastComma ? '.' : ',';
  }

  if (lastDot < 0 && lastComma < 0) return null;

  final separator = lastDot >= 0 ? '.' : ',';
  final position = lastDot >= 0 ? lastDot : lastComma;

  // More than one of them and they cannot be decimal points: 1.234.567.
  if (separator.allMatches(digits).length > 1) return null;

  final trailing = digits.length - position - 1;

  // Exactly three digits after a single separator is the ambiguous case, and
  // the only one where the locale has to decide: 1,234 is one thousand to an
  // English reader and one-and-a-bit to a German one. Anything else is not
  // grouping -- no thousands separator is ever followed by two digits.
  if (trailing == 3) {
    return separator == _localeDecimalSeparator(locale) ? separator : null;
  }

  return separator;
}

/// What a decimal point looks like in [locale], falling back to a full stop.
String _localeDecimalSeparator(String locale) {
  try {
    return NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
  } catch (e) {
    // An unknown locale is a reason to guess, not to refuse the number.
    if (kDebugMode) print('No decimal separator for "$locale": $e');
    return '.';
  }
}
