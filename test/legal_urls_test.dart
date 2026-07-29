import 'package:flutter_test/flutter_test.dart';
import 'package:itemize/core/legal.dart';

/// Apple will not review a build without a reachable privacy policy URL, and
/// this is the one check that catches "forgot to publish docs/ and fill in
/// legal.dart" before a reviewer does. It is expected to fail on a fresh
/// checkout -- that is the point, not a bug in the test.
void main() {
  group('legal URLs must be pointed at the published pages before shipping', () {
    test('kPrivacyPolicyUrl and kTermsOfUseUrl are configured', () {
      expect(
        legalUrlsConfigured,
        isTrue,
        reason:
            'kPrivacyPolicyUrl and/or kTermsOfUseUrl in lib/core/legal.dart '
            'are still the .invalid placeholder. Publish the docs/ folder '
            '(GitHub Pages serves it directly -- Settings > Pages > Deploy '
            'from a branch > /docs) and put the two live addresses '
            '(https://<you>.github.io/<repo>/privacy.html and '
            '.../terms.html, or wherever they end up) into lib/core/legal.dart. '
            'Apple will not review a build with no reachable privacy policy URL.',
      );
    });
  });

  group('isLegalUrlConfigured', () {
    test('rejects the unset .invalid placeholder', () {
      expect(isLegalUrlConfigured('https://example.invalid/set-me'), isFalse);
    });

    test('rejects a URL with no scheme', () {
      expect(isLegalUrlConfigured('example.com/privacy'), isFalse);
    });

    test('accepts a real, configured URL', () {
      // Proves the guard itself works, not just that today's placeholder
      // fails it -- a check that only ever sees one input is not proven.
      expect(
        isLegalUrlConfigured('https://example.github.io/itemize/privacy.html'),
        isTrue,
      );
    });
  });
}
