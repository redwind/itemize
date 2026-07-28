import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itemize/l10n/app_localizations.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:itemize/core/utils/auth_service.dart';
import 'package:itemize/core/utils/backup_service.dart';
import 'package:itemize/core/utils/reminders.dart';
import 'package:share_plus/share_plus.dart';
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
                  "Insurance reports and backups. Everything else is free.",
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
            subtitle: Text(
              proState.isPro
                  ? 'Full report: photos, serials, receipts, signed'
                  : l10n.exportPdfSubtitle,
            ),
            onTap: () => _exportReport(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.backup, color: Colors.orange),
            title: Text(l10n.backupData),
            subtitle: Text(
              switch (settings.daysSinceBackup) {
                null => 'Never backed up — save everything to one file',
                0 => 'Last backed up today',
                1 => 'Last backed up yesterday',
                final days => 'Last backed up $days days ago',
              },
            ),
            trailing: proState.isPro ? null : const _ProChip(),
            onTap: () => _backUp(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore, color: Colors.orange),
            title: const Text('Restore from a Backup'),
            subtitle: const Text('Adds the items in a backup file to this app'),
            trailing: proState.isPro ? null : const _ProChip(),
            onTap: () => _restore(context, ref),
          ),

          const Divider(),
          _buildSectionHeader(l10n.preferences),
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
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: Colors.indigo),
            title: const Text('Contents Cover Limit'),
            subtitle: Text(
              settings.hasCoverageLimit
                  ? settings.formatAmount(settings.coverageLimit)
                  : 'Not set — tell us and we will warn you if you outgrow it',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editCoverageLimit(context, ref),
          ),

          SwitchListTile(
            secondary: const Icon(
              Icons.notifications_active,
              color: Colors.teal,
            ),
            title: const Text('Warranty Reminders'),
            subtitle: const Text('Told 30, 7 and 1 days before one runs out'),
            value: settings.warrantyRemindersEnabled,
            onChanged: (val) async {
              if (val) {
                // Asked for here rather than at first launch, where it would
                // land before there is anything to be reminded about.
                final granted =
                    await Reminders.instance.requestPermission();
                if (!granted) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Notifications are turned off for Itemize. Enable them in your device settings.",
                        ),
                      ),
                    );
                  }
                  return;
                }
              }
              await settingsNotifier.toggleWarrantyReminders(val);
              // Reloading rebuilds the schedule: the sync runs off every
              // reload, so this is what applies the switch that was just moved.
              await ref.read(assetListProvider.notifier).loadAssets();
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.build_circle_outlined, color: Colors.teal),
            title: const Text('Maintenance Reminders'),
            subtitle: const Text('Told a week before a scheduled job is due'),
            value: settings.maintenanceRemindersEnabled,
            onChanged: (val) async {
              if (val) {
                final granted = await Reminders.instance.requestPermission();
                if (!granted) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Notifications are turned off for Itemize. Enable them in your device settings.",
                        ),
                      ),
                    );
                  }
                  return;
                }
              }
              await settingsNotifier.toggleMaintenanceReminders(val);
              await ref.read(assetListProvider.notifier).loadAssets();
            },
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

  Future<void> _editCoverageLimit(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);

    final entered = await showDialog<String>(
      context: context,
      builder:
          (ctx) => _CoverageLimitDialog(
            initialValue:
                settings.hasCoverageLimit
                    ? settings.coverageLimit.toString()
                    : '',
            currencySymbol: settings.currencySymbol,
          ),
    );

    if (entered == null) return;
    await ref
        .read(settingsProvider.notifier)
        .setCoverageLimit(double.tryParse(entered.trim()) ?? 0);
  }

  /// Opens the report preview.
  ///
  /// Free users get here too, and get the summary report — the paywall is the
  /// difference between the two documents, not a locked door in front of both.
  /// Read from the repository rather than the list provider so an active search
  /// on the Assets tab cannot quietly narrow what the report covers.
  Future<void> _exportReport(BuildContext context, WidgetRef ref) async {
    if (ref.read(settingsProvider).isBiometricEnabled) {
      try {
        final ok = await AuthService().authenticate(
          reason: 'Authenticate to export your inventory',
        );
        if (!ok) return;
      } catch (_) {
        return;
      }
    }

    final assets = await ref.read(assetRepositoryProvider).getAllAssets();
    if (!context.mounted) return;

    if (assets.isEmpty) {
      _snack(context, 'There is nothing to report on yet.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfPreviewScreen(assets: assets)),
    );
  }

  /// Writes the whole inventory to a file and hands it to the share sheet.
  ///
  /// Sharing rather than saving on the user's behalf: the app has nowhere of
  /// its own to put this, and a backup sitting in the app's own sandbox would
  /// vanish with exactly the app it is meant to survive.
  Future<void> _backUp(BuildContext context, WidgetRef ref) async {
    if (!await _allowed(context, ref, 'Authenticate to back up your data')) {
      return;
    }

    final repository = ref.read(assetRepositoryProvider);
    final assets = await repository.getAllAssets();
    if (!context.mounted) return;

    if (assets.isEmpty) {
      _snack(context, 'There is nothing to back up yet.');
      return;
    }

    _showBusy(context, 'Preparing backup…');
    try {
      final file = await BackupService().export(
        assets,
        schedules: await repository.allSchedules(),
        serviceRecords: await repository.allServiceRecords(),
      );
      if (!context.mounted) return;
      Navigator.pop(context); // busy

      await ref.read(settingsProvider.notifier).recordBackup();
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Itemize backup',
        text:
            'Itemize backup — ${assets.length} items. '
            'Keep this file somewhere you can find it again.',
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // busy
      _snack(context, 'Backup failed: $e');
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    if (!await _allowed(context, ref, 'Authenticate to restore a backup')) {
      return;
    }

    final picked = await FilePicker.pickFiles(
      // Not filtered to the extension: iOS will not offer a custom type it does
      // not know, which leaves the user staring at a file picker that greys out
      // the very file they are looking for.
      type: FileType.any,
      allowMultiple: false,
    );
    final path = picked?.files.single.path;
    if (path == null || !context.mounted) return;

    _showBusy(context, 'Restoring…');
    final repository = ref.read(assetRepositoryProvider);
    try {
      final result = await BackupService().import(
        path,
        findExisting: repository.findAsset,
        addAsset: repository.addAsset,
        updateAsset: repository.updateAsset,
        saveSchedule: repository.saveSchedule,
        // Straight to storage rather than through logService: the archived
        // schedules already carry their own last-done dates, and replaying the
        // history over them would only rewrite what is already correct.
        saveServiceRecord: repository.saveServiceRecordRaw,
      );
      await ref.read(assetListProvider.notifier).loadAssets();
      if (!context.mounted) return;
      Navigator.pop(context); // busy

      showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Restore complete'),
              content: Text(
                '${result.added} item${result.added == 1 ? '' : 's'} added, '
                '${result.updated} updated, '
                '${result.photosRestored} photo'
                '${result.photosRestored == 1 ? '' : 's'} restored.\n\n'
                'Nothing already on this device was removed.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } on BackupFormatException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // busy
      _snack(context, e.message);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // busy
      _snack(context, 'Restore failed: $e');
    }
  }

  /// Pro check and biometric prompt, in that order.
  Future<bool> _allowed(
    BuildContext context,
    WidgetRef ref,
    String reason,
  ) async {
    if (!ref.read(proProvider).isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return false;
    }

    if (ref.read(settingsProvider).isBiometricEnabled) {
      try {
        if (!await AuthService().authenticate(reason: reason)) return false;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  void _showBusy(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 20),
                  Expanded(child: Text(message)),
                ],
              ),
            ),
          ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

/// Asks for the policy's contents limit.
///
/// Stateful so the text controller dies with the dialog. Disposing it right
/// after `showDialog` returns is too early: that future completes the moment
/// pop is called, while the dialog is still animating out and its field is
/// still reading the controller as it loses focus.
class _CoverageLimitDialog extends StatefulWidget {
  const _CoverageLimitDialog({
    required this.initialValue,
    required this.currencySymbol,
  });

  final String initialValue;
  final String currencySymbol;

  @override
  State<_CoverageLimitDialog> createState() => _CoverageLimitDialogState();
}

class _CoverageLimitDialogState extends State<_CoverageLimitDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contents Cover Limit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The most your policy pays out for belongings. Find it on '
            'your schedule under contents.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: widget.currencySymbol,
              hintText: 'Leave empty to remove',
            ),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Marks a row as something Pro unlocks, without disabling it.
///
/// The row still opens the paywall when tapped: a greyed-out control tells
/// someone they cannot have it, where this tells them what it costs.
class _ProChip extends StatelessWidget {
  const _ProChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: Colors.purple,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
