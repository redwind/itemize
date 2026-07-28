import 'package:flutter_test/flutter_test.dart';
import 'package:itemize/providers/settings_provider.dart';

void main() {
  group('resolving a stored language', () {
    test('keeps every language the app ships in', () {
      for (final code in kSupportedLanguages) {
        expect(resolveLanguage(code), code);
      }
      expect(kSupportedLanguages, containsAll(['en', 'fr', 'de']));
    });

    test('falls back for a language dropped since the preference was saved', () {
      // Vietnamese was offered by an earlier build and is no longer shipped.
      expect(resolveLanguage('vi'), 'en');
    });

    test('falls back for nonsense and for nothing at all', () {
      expect(resolveLanguage(null), 'en');
      expect(resolveLanguage(''), 'en');
      expect(resolveLanguage('klingon'), 'en');
    });

    test('every shipped language has a name to show in the picker', () {
      for (final code in kSupportedLanguages) {
        expect(kLanguageNames[code], isNotNull, reason: code);
        expect(kLanguageNames[code], isNotEmpty);
      }
    });

    test('the picker names each language in that language', () {
      // Scanning for your own language means looking for the word you
      // recognise, so these are deliberately not translated.
      expect(kLanguageNames['fr'], 'Français');
      expect(kLanguageNames['de'], 'Deutsch');
    });
  });

  group('amounts follow the language', () {
    test('French groups with spaces and puts the symbol last', () {
      final fr = AppSettings(languageCode: 'fr', currencyCode: 'EUR');
      final formatted = fr.formatAmount(21411);
      expect(formatted, contains('€'));
      expect(formatted.trim().endsWith('€'), isTrue, reason: formatted);
    });

    test('English groups with commas and puts the symbol first', () {
      final en = AppSettings(languageCode: 'en', currencyCode: 'USD');
      expect(en.formatAmount(21411), startsWith(r'$'));
      expect(en.formatAmount(21411), contains(','));
    });

    test('German uses its own separators', () {
      final de = AppSettings(languageCode: 'de', currencyCode: 'EUR');
      final formatted = de.formatAmount(21411.5);
      expect(formatted, contains('€'));
      expect(formatted, contains(','), reason: 'decimal comma: $formatted');
    });
  });
}
