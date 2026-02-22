import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/core/utils/auth_service.dart';
// import 'package:itemize/core/utils/pdf_service.dart';
import 'package:itemize/providers/asset_provider.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:itemize/providers/pro_provider.dart';
import 'package:itemize/ui/settings/paywall_screen.dart';
import 'package:itemize/ui/settings/pdf_preview_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final proState = ref.watch(proProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTab)),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          const SizedBox(height: 20),

          if (!proState.isPro)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.purple.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.purple.shade100),
              ),
              child: ListTile(
                leading: const Icon(Icons.diamond, color: Colors.purple),
                title: const Text(
                  "Upgrade to Pro",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                subtitle: const Text(
                  "Unlock unlimited items, biometrics, and more.",
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.purple,
                ),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    ),
              ),
            ),

          ListTile(
            leading: const Icon(
              Icons.picture_as_pdf,
              color: AppTheme.primaryBlue,
            ),
            title: Text(l10n.exportPdf),
            subtitle: Text(l10n.exportPdfSubtitle),
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
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfPreviewScreen(assets: data),
                        ),
                      );
                    }
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
            title: Text(l10n.backupData),
            subtitle: Text(l10n.backupDataSubtitle),
            onTap: () {},
          ),

          const Divider(),
          _buildSectionHeader(l10n.preferences),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_getLanguageName(settings.languageCode)),
            trailing: DropdownButton<String>(
              value: settings.languageCode,
              underline: const SizedBox(), // Hide default underline
              icon: const Icon(Icons.arrow_drop_down),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  settingsNotifier.setLanguage(newValue);
                }
              },
              items:
                  ['en', 'vi', 'fr', 'de'].map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(_getLanguageName(value)),
                    );
                  }).toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: Text(l10n.currency),
            subtitle: Text(
              '${settings.currencyCode} (${settings.currencySymbol})',
            ),
            trailing: DropdownButton<String>(
              value: settings.currencyCode,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  settingsNotifier.setCurrency(newValue);
                }
              },
              items:
                  ['USD', 'EUR', 'GBP', 'VND'].map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
          ),
          SwitchListTile(
            secondary: Icon(
              Icons.fingerprint,
              color: proState.isPro ? Colors.purple : Colors.grey,
            ),
            title: Text(l10n.biometricLock),
            subtitle: Text(
              proState.isPro
                  ? l10n.biometricLockSubtitle
                  : "Available in Pro Version",
            ),
            value: settings.isBiometricEnabled,
            onChanged: (val) async {
              if (!proState.isPro) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
                return;
              }
              try {
                if (val) {
                  // Verify before enabling
                  final success = await AuthService().authenticate();
                  if (success) {
                    settingsNotifier.toggleBiometric(true);
                  }
                } else {
                  // Verify before disabling (security best practice)
                  // If device security is gone (NotAvailable), we should allow disabling locally.
                  try {
                    final success = await AuthService().authenticate(
                      reason: 'Authenticate to disable Lock',
                    );
                    if (success) {
                      settingsNotifier.toggleBiometric(false);
                    }
                  } on PlatformException catch (e) {
                    if (e.code == 'NotAvailable') {
                      // Security removed from device, force disable in app
                      settingsNotifier.toggleBiometric(false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Device security disabled. Biometric lock turned off.",
                            ),
                          ),
                        );
                      }
                    } else {
                      rethrow; // Re-throw other errors to outer catch
                    }
                  }
                }
              } on PlatformException catch (e) {
                if (context.mounted) {
                  String message = "Authentication failed.";
                  if (e.code == 'NotAvailable') {
                    message =
                        "Biometrics/Security not set up. Please enable a Lock Screen (PIN/Pattern).";
                  } else if (e.code == 'LockedOut') {
                    message = "Too many attempts. Try again later.";
                  } else if (e.code == 'PermanentlyLockedOut') {
                    message =
                        "Biometrics disabled. Use PIN/Pattern or re-enroll.";
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              }
            },
          ),

          const Divider(),
          _buildSectionHeader(l10n.about),
          ListTile(title: Text(l10n.version), trailing: const Text('1.0.0')),

          if (proState.isPro && kDebugMode) ...[
            const Divider(),
            _buildSectionHeader("Debug (Dev Only)"),
            ListTile(
              title: const Text(
                "Cancel Pro Subscription",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await ref.read(proProvider.notifier).debugCancelPro();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Pro status wiped. Redirecting to store...",
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'vi':
        return 'Tiếng Việt';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return code.toUpperCase();
    }
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
