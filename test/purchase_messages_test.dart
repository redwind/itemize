import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/l10n/app_localizations.dart';
import 'package:inventa/providers/pro_provider.dart';
import 'package:inventa/ui/settings/paywall_screen.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fr = lookupAppLocalizations(const Locale('fr'));
  final de = lookupAppLocalizations(const Locale('de'));

  // ProOutcome carries no English of its own -- ProOutcomeText.localize is
  // the only place that turns one into a string. If a value is ever added to
  // the enum without a case there, or a case is wired to the wrong key, this
  // is what catches it: the paywall would otherwise show a French or German
  // customer, at the moment they just paid, a blank or an English sentence.
  group('every ProOutcome translates in every shipped language', () {
    for (final outcome in ProOutcome.values) {
      test(outcome.name, () {
        final enText = outcome.localize(en);
        final frText = outcome.localize(fr);
        final deText = outcome.localize(de);

        expect(enText, isNotEmpty, reason: '${outcome.name} (en)');
        expect(frText, isNotEmpty, reason: '${outcome.name} (fr)');
        expect(deText, isNotEmpty, reason: '${outcome.name} (de)');

        // A fallback to the English getter reads as "translated" by the
        // isNotEmpty check above, so distinctness is what actually proves
        // the fr/de key was reached.
        expect(
          frText,
          isNot(equals(enText)),
          reason: '${outcome.name}: fr text equals en text',
        );
        expect(
          deText,
          isNot(equals(enText)),
          reason: '${outcome.name}: de text equals en text',
        );
      });
    }
  });
}
