import 'package:flutter_test/flutter_test.dart';
import 'package:itemize/providers/settings_provider.dart';

void main() {
  group('resolving a stored language', () {
    test('keeps a language the app actually ships in', () {
      expect(resolveLanguage('en'), 'en');
    });

    test('falls back for a language dropped since the preference was saved', () {
      // Somebody upgrading from a build that offered four languages.
      for (final dropped in ['vi', 'fr', 'de']) {
        expect(resolveLanguage(dropped), 'en', reason: dropped);
      }
    });

    test('falls back for nonsense and for nothing at all', () {
      expect(resolveLanguage(null), 'en');
      expect(resolveLanguage(''), 'en');
      expect(resolveLanguage('klingon'), 'en');
    });

    test('every shipped language resolves to itself', () {
      for (final code in kSupportedLanguages) {
        expect(resolveLanguage(code), code);
      }
    });
  });
}
