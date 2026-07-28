import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/core/utils/image_storage.dart';
import 'package:itemize/core/utils/reminders.dart';
import 'package:itemize/data/repositories/asset_repository.dart';
import 'package:itemize/l10n/app_localizations.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:itemize/ui/assets/asset_detail_screen.dart';
import 'package:itemize/ui/common/main_screen.dart';
import 'package:itemize/ui/common/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itemize/ui/common/biometric_guard.dart';

/// Lets a tapped reminder open the item it is about, from outside the tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize other services (ML Kit, etc if needed lazily)

  // Item pictures are addressed relative to Documents and shown from
  // synchronous widgets, so resolve that directory before the first build.
  await ImageStorage.init();
  // Dates and grouped numbers read the ambient locale, which nothing sets by
  // itself. Without this the interface would turn French while every date on it
  // stayed English -- and the receipt-date parser would go on assuming the
  // wrong day-month order.
  await initializeDateFormatting();

  await Reminders.instance.init(onTapAsset: _openAsset);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ItemizeApp(),
    ),
  );
}

/// Opens the item a tapped reminder refers to.
///
/// Read straight from the repository rather than from the list provider: the
/// tap can arrive before the first build, when no provider has loaded yet.
Future<void> _openAsset(String assetId) async {
  try {
    final asset = await AssetRepository().getAsset(assetId);
    await navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: asset)),
    );
  } catch (_) {
    // Deleted between the reminder being scheduled and tapped. Landing on the
    // app's home screen is the right outcome, and is what already happened.
  }
}

class ItemizeApp extends ConsumerWidget {
  const ItemizeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final language = resolveLanguage(settings.languageCode);
    // Set here as well as on MaterialApp, because the formatters in
    // AppSettings, the PDF report and the OCR date parser all read
    // Intl.defaultLocale rather than anything from the widget tree.
    Intl.defaultLocale = language;

    return MaterialApp(
      title: 'Itemize',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: Locale(language),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // English only, deliberately -- see kSupportedLanguages. The delegates
      // and the generated l10n classes stay, so widening this later is a
      // translation job rather than a rebuild.
      supportedLocales: kSupportedLanguages.map(Locale.new).toList(),
      home: const BiometricGuard(child: OnboardingGate(child: MainScreen())),
    );
  }
}
