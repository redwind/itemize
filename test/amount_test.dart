import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/core/utils/amount.dart';

/// What the price field does with what people actually type.
///
/// The app is sold into France and Germany, where the number pad offers a
/// comma. [double.tryParse] rejects a comma, and every call site turned that
/// rejection into a zero, so the first item a German owner ever recorded was
/// stored as free.
void main() {
  group('a comma is a decimal point where people type one', () {
    test('the digits a German or French keyboard produces', () {
      expect(parseAmount('1299,99', locale: 'de'), 1299.99);
      expect(parseAmount('49,99', locale: 'fr'), 49.99);
      expect(parseAmount('0,5', locale: 'de'), 0.5);
    });

    test('a comma decimal is read even by an English speaker', () {
      // Two digits after a separator is never grouping, in any locale, so
      // there is nothing to be ambiguous about.
      expect(parseAmount('1299,99', locale: 'en'), 1299.99);
    });

    test('and never becomes a silent zero', () {
      for (final input in ['1299,99', '1.234,56', '49,99']) {
        expect(parseAmount(input, locale: 'de'), isNot(0));
      }
    });
  });

  group('grouped thousands', () {
    test('German and French grouping', () {
      expect(parseAmount('1.234,56', locale: 'de'), 1234.56);
      expect(parseAmount('1 234,56', locale: 'fr'), 1234.56);
      // The narrow no-break space French formatting actually emits.
      expect(parseAmount('1 234,56', locale: 'fr'), 1234.56);
      expect(parseAmount('1.234.567', locale: 'de'), 1234567);
    });

    test('English grouping', () {
      expect(parseAmount('1,234.56', locale: 'en'), 1234.56);
      expect(parseAmount('1,234,567', locale: 'en'), 1234567);
    });

    test('the ambiguous three-digit case follows the locale', () {
      // "1,234" is a thousand in English and one-and-a-bit in German.
      expect(parseAmount('1,234', locale: 'en'), 1234);
      expect(parseAmount('1,234', locale: 'de'), 1.234);
      // And the mirror image.
      expect(parseAmount('1.234', locale: 'en'), 1.234);
      expect(parseAmount('1.234', locale: 'de'), 1234);
    });
  });

  group('what surrounds the number is ignored', () {
    test('currency symbols and spacing', () {
      expect(parseAmount('€ 1.299,00', locale: 'de'), 1299);
      expect(parseAmount(r'$1,299.00', locale: 'en'), 1299);
      expect(parseAmount('  49,99 €', locale: 'fr'), 49.99);
      expect(parseAmount('1299,99 CHF', locale: 'de'), 1299.99);
    });

    test('a negative stays negative', () {
      expect(parseAmount('-49,99', locale: 'de'), -49.99);
    });
  });

  group('what is not a number says so, rather than saying zero', () {
    test('empty and junk', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount('   '), isNull);
      expect(parseAmount('abc'), isNull);
      expect(parseAmount('€'), isNull);
      expect(parseAmount('-'), isNull);
    });

    test('a real zero is still a zero', () {
      expect(parseAmount('0'), 0);
      expect(parseAmount('0,00', locale: 'de'), 0);
    });
  });

  test('plain input is unchanged by any of this', () {
    expect(parseAmount('1299.99', locale: 'en'), 1299.99);
    expect(parseAmount('1299', locale: 'de'), 1299);
    expect(parseAmount('1299.99', locale: 'de'), 1299.99);
  });

  test('an unknown locale still parses rather than refusing', () {
    expect(parseAmount('49,99', locale: 'zz-ZZ'), 49.99);
    expect(parseAmount('1299.99', locale: 'zz-ZZ'), 1299.99);
  });
}
