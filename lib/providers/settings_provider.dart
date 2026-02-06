import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple model for settings
class AppSettings {
  final bool isBiometricEnabled;
  final String currencyCode;
  final String languageCode;

  AppSettings({
    this.isBiometricEnabled = false,
    this.currencyCode = 'USD',
    this.languageCode = 'en',
  });

  AppSettings copyWith({
    bool? isBiometricEnabled,
    String? currencyCode,
    String? languageCode,
  }) {
    return AppSettings(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      currencyCode: currencyCode ?? this.currencyCode,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      isBiometricEnabled: prefs.getBool('isBiometricEnabled') ?? false,
      currencyCode: prefs.getString('currencyCode') ?? 'USD',
      languageCode: prefs.getString('languageCode') ?? 'en',
    );
  }

  Future<void> toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBiometricEnabled', value);
    state = state.copyWith(isBiometricEnabled: value);
  }

  Future<void> setCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currencyCode', code);
    state = state.copyWith(currencyCode: code);
  }

  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);
    state = state.copyWith(languageCode: code);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});
