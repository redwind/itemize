import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/core/utils/ocr_service.dart';

void main() {
  final today = DateTime(2026, 7, 27);

  DateTime? parse(String? raw, {String locale = 'en_US'}) =>
      OCRService.parseReceiptDate(raw, today: today, locale: locale);

  group('unambiguous dates', () {
    test('a number above 12 settles the order regardless of locale', () {
      expect(parse('25/12/2024'), DateTime(2024, 12, 25));
      expect(parse('25/12/2024', locale: 'en_US'), DateTime(2024, 12, 25));
      expect(parse('12/25/2024', locale: 'en_GB'), DateTime(2024, 12, 25));
    });

    test('dashes read the same as slashes', () {
      expect(parse('25-12-2024'), DateTime(2024, 12, 25));
    });

    test('two-digit years are read as this century', () {
      expect(parse('25/12/24'), DateTime(2024, 12, 25));
    });
  });

  group('ambiguous dates fall back to the locale', () {
    test('US reads month first', () {
      expect(parse('03/04/2024', locale: 'en_US'), DateTime(2024, 3, 4));
    });

    test('UK reads day first', () {
      expect(parse('03/04/2024', locale: 'en_GB'), DateTime(2024, 4, 3));
    });

    test('Vietnamese reads day first', () {
      expect(parse('03/04/2024', locale: 'vi'), DateTime(2024, 4, 3));
    });

    test('German reads day first', () {
      expect(parse('03/04/2024', locale: 'de'), DateTime(2024, 4, 3));
    });
  });

  group('misreads are dropped rather than recorded', () {
    test('a future date', () {
      expect(parse('01/01/2027'), isNull);
    });

    test('a date older than the twenty-year window', () {
      expect(parse('01/01/2000'), isNull);
    });

    test('a day that does not exist in that month', () {
      // 31 February would otherwise roll over into March.
      expect(parse('31/02/2024'), isNull);
    });

    test('an impossible month', () {
      expect(parse('13/13/2024'), isNull);
    });

    test('a day of zero', () {
      expect(parse('00/01/2024'), isNull);
    });

    test('junk, or nothing at all', () {
      expect(parse(null), isNull);
      expect(parse('not a date'), isNull);
      expect(parse('12/2024'), isNull);
      expect(parse('a/b/c'), isNull);
    });
  });

  test('today itself is accepted', () {
    expect(parse('27/07/2026'), today);
  });
}
