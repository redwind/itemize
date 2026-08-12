import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/providers/settings_provider.dart';

void main() {
  group('region to currency', () {
    test('maps the eurozone countries this app is sold into', () {
      for (final region in [
        'DE',
        'FR',
        'AT',
        'BE',
        'NL',
        'ES',
        'IT',
        'IE',
        'FI',
        'PT',
        'GR',
        'LU',
        'SK',
        'SI',
        'EE',
        'LV',
        'LT',
        'CY',
        'MT',
      ]) {
        expect(currencyForRegion(region), 'EUR', reason: region);
      }
    });

    test('maps the non-euro markets individually', () {
      expect(currencyForRegion('GB'), 'GBP');
      expect(currencyForRegion('CH'), 'CHF');
      expect(currencyForRegion('LI'), 'CHF');
      expect(currencyForRegion('US'), 'USD');
      expect(currencyForRegion('CA'), 'CAD');
      expect(currencyForRegion('AU'), 'AUD');
      expect(currencyForRegion('NZ'), 'NZD');
      expect(currencyForRegion('VN'), 'VND');
    });

    test('is case-insensitive, since locale casing is not guaranteed', () {
      expect(currencyForRegion('de'), 'EUR');
      expect(currencyForRegion('gb'), 'GBP');
    });

    test('falls back to USD for anything unmapped', () {
      expect(currencyForRegion('JP'), 'USD');
      expect(currencyForRegion('BR'), 'USD');
      expect(currencyForRegion(null), 'USD');
      expect(currencyForRegion(''), 'USD');
    });
  });

  group('parsing the region out of a platform locale name', () {
    test('handles the Linux-style locale with an encoding suffix', () {
      expect(regionFromLocaleName('de_DE.UTF-8'), 'DE');
    });

    test('handles a hyphenated locale', () {
      expect(regionFromLocaleName('de-DE'), 'DE');
    });

    test('returns null when the OS reports no region at all', () {
      expect(regionFromLocaleName('de'), isNull);
    });

    test('returns null for an empty string', () {
      expect(regionFromLocaleName(''), isNull);
    });

    test('returns null for junk that has no separator', () {
      expect(regionFromLocaleName('klingon'), isNull);
    });
  });

  group('the default currency for a whole locale name', () {
    test('a German phone defaults to EUR even if the app runs in English', () {
      expect(currencyForLocaleName('de_DE.UTF-8'), 'EUR');
    });

    test('a bare language with no region falls back to USD', () {
      expect(currencyForLocaleName('de'), 'USD');
    });

    test('a Vietnamese locale defaults to VND', () {
      expect(currencyForLocaleName('vi_VN.UTF-8'), 'VND');
    });
  });

  test('every currency the mapping can produce is offered by the picker', () {
    final producible = <String>{
      currencyForRegion(null),
      'EUR',
      'GBP',
      'CHF',
      'USD',
      'CAD',
      'AUD',
      'NZD',
      'VND',
    };
    for (final code in producible) {
      expect(kSupportedCurrencies, contains(code), reason: code);
    }
  });
}
