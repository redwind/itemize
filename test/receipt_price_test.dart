import 'package:flutter_test/flutter_test.dart';
import 'package:itemize/core/utils/ocr_service.dart';

/// The total lifted off a photographed till roll.
///
/// The old cleanup swapped every comma for a full stop, so a German receipt's
/// "1.234,56" became "1.234.56", parsed as null, and was counted as 0. The
/// heuristic then picked the largest of what remained, which meant the price
/// field was filled in from some other line on the receipt entirely.
double? priceIn(String text, {String locale = 'en'}) =>
    OCRService.parseReceiptText(text, locale: locale)['price'] as double?;

void main() {
  group('reading the total off a receipt', () {
    test('an English receipt', () {
      expect(priceIn('MediaMarkt\nTV\nTotal \$1,234.56\n'), 1234.56);
    });

    test('a German receipt', () {
      expect(
        priceIn('MediaMarkt\nFernseher\nSumme 1.234,56 EUR\n', locale: 'de'),
        1234.56,
      );
    });

    test('a French receipt', () {
      expect(priceIn('Darty\nTéléviseur\nTotal 1 234,56 €\n', locale: 'fr'),
          1234.56);
    });

    test('the largest line wins, and the grouped total is the largest', () {
      // The failure this guards: 1.234,56 used to parse as nothing, leaving
      // 89,99 the biggest surviving number and the price the app filled in.
      const receipt = '''
Saturn
Waschmaschine     1.234,56
Lieferung            89,99
Summe             1.324,55
''';
      expect(priceIn(receipt, locale: 'de'), 1324.55);
    });

    test('a small amount is read exactly, not rounded to nothing', () {
      expect(priceIn('Bon\nTotal 49,99 EUR', locale: 'de'), 49.99);
    });

    test('a receipt with no numbers at all yields no price', () {
      expect(priceIn('Thank you for shopping with us'), isNull);
    });
  });
}
