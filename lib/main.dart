import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:itemize/ui/common/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itemize/ui/common/biometric_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize other services (ML Kit, etc if needed lazily)

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ItemizeApp(),
    ),
  );
}

class ItemizeApp extends ConsumerWidget {
  const ItemizeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Itemize',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: Locale(settings.languageCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
        Locale('fr'),
        Locale('de'),
      ],
      home: const BiometricGuard(child: MainScreen()),
    );
  }
}
