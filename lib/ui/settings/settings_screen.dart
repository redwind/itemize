import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/core/utils/auth_service.dart';
import 'package:itemize/core/utils/pdf_service.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader('Data Management'),
          ListTile(
            leading: const Icon(
              Icons.picture_as_pdf,
              color: AppTheme.primaryBlue,
            ),
            title: const Text('Export Report to PDF'),
            subtitle: const Text('Generate insurance report'),
            onTap: () async {
              try {
                // Check biometric if enabled
                if (settings.isBiometricEnabled) {
                  final authenticated = await AuthService().authenticate(
                    reason: 'Authenticate to Export Data',
                  );
                  if (!authenticated) return;
                }

                final assetsValue = ref.read(assetListProvider);
                assetsValue.when(
                  data: (data) async {
                    if (data.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No assets to export")),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Generating PDF...")),
                    );
                    await PDFService().printOrShareReport(data);
                  },
                  error:
                      (e, s) => ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e"))),
                  loading:
                      () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please wait, data loading..."),
                        ),
                      ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Export Failed: $e")));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup, color: Colors.orange),
            title: const Text('Backup Data'),
            subtitle: const Text('Local backup (Coming Soon)'),
            onTap: () {},
          ),

          const Divider(),
          _buildSectionHeader('Preferences'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(settings.languageCode.toUpperCase()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Cycle language for demo (en -> vi -> fr -> de -> en)
              final langs = ['en', 'vi', 'fr', 'de'];
              final currentIndex = langs.indexOf(settings.languageCode);
              final nextIndex = (currentIndex + 1) % langs.length;
              settingsNotifier.setLanguage(langs[nextIndex]);
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
            subtitle: Text(settings.currencyCode),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Cycle currency for demo
              final currencies = ['USD', 'EUR', 'GBP', 'VND'];
              final currentIndex = currencies.indexOf(settings.currencyCode);
              final nextIndex = (currentIndex + 1) % currencies.length;
              settingsNotifier.setCurrency(currencies[nextIndex]);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint, color: Colors.purple),
            title: const Text('Biometric Lock'),
            subtitle: const Text(
              'Require FaceID/TouchID for sensitive actions',
            ),
            value: settings.isBiometricEnabled,
            onChanged: (val) async {
              if (val) {
                // Verify before enabling
                final success = await AuthService().authenticate();
                if (success) {
                  settingsNotifier.toggleBiometric(true);
                }
              } else {
                settingsNotifier.toggleBiometric(false);
              }
            },
          ),

          const Divider(),
          _buildSectionHeader('About'),
          const ListTile(title: Text('Version'), trailing: Text('1.0.0')),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
