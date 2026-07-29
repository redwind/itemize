import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/l10n/app_localizations.dart';
import 'package:itemize/l10n/domain_labels.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fr = lookupAppLocalizations(const Locale('fr'));
  final de = lookupAppLocalizations(const Locale('de'));

  // Both languages borrow this one unchanged, so equality to the English key
  // is a real translation, not evidence that roomLabel fell through.
  const loanwords = {'Garage'};

  group('every kAssetRoom translates in every shipped language', () {
    for (final room in kAssetRooms) {
      test(room, () {
        final frText = fr.roomLabel(room);
        final deText = de.roomLabel(room);

        expect(frText, isNotEmpty, reason: '$room (fr)');
        expect(deText, isNotEmpty, reason: '$room (de)');

        if (loanwords.contains(room)) return;

        // A fallback to the raw key reads as "translated" by isNotEmpty
        // alone, so distinctness from the English string -- the key itself --
        // is what actually proves the fr/de getter was reached.
        expect(frText, isNot(equals(room)), reason: '$room: fr matches the raw key');
        expect(deText, isNot(equals(room)), reason: '$room: de matches the raw key');
      });
    }
  });

  group('a room the app does not know', () {
    test('falls through to itself rather than vanishing', () {
      // What a pre-update backup or a hand-edited row could carry.
      const unknown = 'Attic';
      expect(en.roomLabel(unknown), unknown);
      expect(fr.roomLabel(unknown), unknown);
      expect(de.roomLabel(unknown), unknown);
    });
  });

  group('ordering that other code relies on', () {
    test('Other is still last', () {
      expect(kAssetRooms.last, 'Other');
    });

    test('the default first entry is unchanged', () {
      expect(kAssetRooms.first, 'Living Room');
    });
  });
}
