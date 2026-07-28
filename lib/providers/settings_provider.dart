import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple model for settings
class AppSettings {
  final bool isBiometricEnabled;

  /// On by default: an expiry date recorded and never mentioned again is the
  /// state this app was already in, and it helped nobody.
  final bool warrantyRemindersEnabled;

  /// Nudges when a scheduled job falls due.
  ///
  /// Kept separate from the warranty switch because they are different
  /// appetites: plenty of people want to be told a filter is due and not to be
  /// reminded about paperwork, and the reverse.
  final bool maintenanceRemindersEnabled;

  /// The contents limit on the owner's policy, or 0 when they have not said.
  ///
  /// Kept so the app can point out that what they own has grown past what they
  /// are covered for — the discovery that otherwise waits until a claim is
  /// already being settled.
  final double coverageLimit;

  /// When a backup was last taken, or null if never.
  ///
  /// Kept so the app can say something. A backup nobody remembers to make
  /// protects only the disciplined, and the people most at risk of losing an
  /// inventory are the ones who set it up once and stopped thinking about it.
  final DateTime? lastBackupAt;

  /// Whether the owner has been walked through their first room.
  final bool hasOnboarded;

  final String currencyCode;

  /// The interface language.
  ///
  /// Pinned to English for now — see [kSupportedLanguages]. The field and its
  /// setter are kept rather than ripped out because the l10n plumbing is
  /// staying: adding a language back is a matter of translating and widening
  /// that list, not of rebuilding this.
  final String languageCode;

  AppSettings({
    this.isBiometricEnabled = false,
    this.warrantyRemindersEnabled = true,
    this.maintenanceRemindersEnabled = true,
    this.coverageLimit = 0,
    this.lastBackupAt,
    this.hasOnboarded = false,
    this.currencyCode = 'USD',
    this.languageCode = 'en',
  });

  /// How long since the last backup, or null when there has never been one.
  int? get daysSinceBackup =>
      lastBackupAt == null
          ? null
          : DateTime.now().difference(lastBackupAt!).inDays;

  bool get hasCoverageLimit => coverageLimit > 0;

  AppSettings copyWith({
    bool? isBiometricEnabled,
    bool? warrantyRemindersEnabled,
    bool? maintenanceRemindersEnabled,
    double? coverageLimit,
    DateTime? lastBackupAt,
    bool? hasOnboarded,
    String? currencyCode,
    String? languageCode,
  }) {
    return AppSettings(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      warrantyRemindersEnabled:
          warrantyRemindersEnabled ?? this.warrantyRemindersEnabled,
      maintenanceRemindersEnabled:
          maintenanceRemindersEnabled ?? this.maintenanceRemindersEnabled,
      coverageLimit: coverageLimit ?? this.coverageLimit,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      hasOnboarded: hasOnboarded ?? this.hasOnboarded,
      currencyCode: currencyCode ?? this.currencyCode,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  String get currencySymbol {
    switch (currencyCode) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'VND':
        return '₫';
      case 'USD':
      default:
        return '\$';
    }
  }

  // Dong is never quoted with a fractional part.
  int get _decimalDigits => currencyCode == 'VND' ? 0 : 2;

  /// Grouped, locale-aware amount — "$21,411.00" rather than "$21411.00",
  /// and "21 411,00 €" once the app is in French.
  String formatAmount(double amount) => NumberFormat.currency(
    locale: languageCode,
    symbol: currencySymbol,
    decimalDigits: _decimalDigits,
  ).format(amount);

  /// Same, without the fractional part, for tight spots like chart legends.
  String formatAmountCompact(double amount) => NumberFormat.currency(
    locale: languageCode,
    symbol: currencySymbol,
    decimalDigits: 0,
  ).format(amount);
}

/// Languages the app actually ships in.
///
/// It was offering four. Three of them covered 23 of the app's 100-odd strings,
/// so choosing French produced a mostly-English screen — which reads as broken
/// rather than as unfinished, and reads worst to exactly the paying overseas
/// customer it was there to attract. English alone is the honest state until
/// another language is genuinely translated.
const List<String> kSupportedLanguages = ['en', 'fr', 'de'];

/// What each language calls itself, for the picker.
///
/// In the language itself, never translated: somebody hunting for their own
/// language is scanning for the word they recognise, and "Allemand" is no help
/// to a German speaker who has landed in a French interface by accident.
const Map<String, String> kLanguageNames = {
  'en': 'English',
  'fr': 'Français',
  'de': 'Deutsch',
};

/// The stored preference, or English when it names a language no longer shipped.
String resolveLanguage(String? stored) =>
    kSupportedLanguages.contains(stored) ? stored! : 'en';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences prefs;

  SettingsNotifier(this.prefs)
    : super(
        AppSettings(
          isBiometricEnabled: prefs.getBool('isBiometricEnabled') ?? false,
          warrantyRemindersEnabled:
              prefs.getBool('warrantyRemindersEnabled') ?? true,
          maintenanceRemindersEnabled:
              prefs.getBool('maintenanceRemindersEnabled') ?? true,
          coverageLimit: prefs.getDouble('coverageLimit') ?? 0,
          lastBackupAt: DateTime.tryParse(prefs.getString('lastBackupAt') ?? ''),
          hasOnboarded: prefs.getBool('hasOnboarded') ?? false,
          currencyCode: prefs.getString('currencyCode') ?? 'USD',
          // Sanitised on read: anyone carrying 'vi', 'fr' or 'de' from an
          // earlier build lands on English rather than on a half-translated
          // screen.
          languageCode: resolveLanguage(prefs.getString('languageCode')),
        ),
      );

  Future<void> toggleBiometric(bool value) async {
    await prefs.setBool('isBiometricEnabled', value);
    state = state.copyWith(isBiometricEnabled: value);
  }

  Future<void> toggleWarrantyReminders(bool value) async {
    await prefs.setBool('warrantyRemindersEnabled', value);
    state = state.copyWith(warrantyRemindersEnabled: value);
  }

  Future<void> toggleMaintenanceReminders(bool value) async {
    await prefs.setBool('maintenanceRemindersEnabled', value);
    state = state.copyWith(maintenanceRemindersEnabled: value);
  }

  /// Records the policy limit, or clears it when [amount] is zero or less.
  Future<void> setCoverageLimit(double amount) async {
    final value = amount > 0 ? amount : 0.0;
    await prefs.setDouble('coverageLimit', value);
    state = state.copyWith(coverageLimit: value);
  }

  Future<void> recordBackup() async {
    final now = DateTime.now();
    await prefs.setString('lastBackupAt', now.toIso8601String());
    state = state.copyWith(lastBackupAt: now);
  }

  Future<void> completeOnboarding() async {
    await prefs.setBool('hasOnboarded', true);
    state = state.copyWith(hasOnboarded: true);
  }

  Future<void> setCurrency(String code) async {
    await prefs.setString('currencyCode', code);
    state = state.copyWith(currencyCode: code);
  }

  Future<void> setLanguage(String code) async {
    final resolved = resolveLanguage(code);
    await prefs.setString('languageCode', resolved);
    state = state.copyWith(languageCode: resolved);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
