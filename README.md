# Inventa

A premium, privacy-first home inventory app. Everything you own, what it is
worth today, when the warranty runs out, and what is due for servicing — kept
on your device and nowhere else.

Built with Flutter. English, German and French.

## Running it

```sh
flutter pub get
flutter run
```

Localized strings live in `lib/l10n/*.arb`; after editing them run:

```sh
flutter gen-l10n
```

## A note on names

The app shipped its first builds as *Itemize* and was renamed to *Inventa*.
Two identifiers deliberately kept the old spelling, because changing them
would strand data that already exists on people's phones:

- the application id / bundle id, `com.itemize.itemize` — it cannot be changed
  after publication without becoming a different app in either store;
- the local database file, `itemize.db`.

Backup archives are written as `.inventa` with an `inventa-backup` tag, but
older `itemize-backup` archives are still accepted on import, and always will
be.
