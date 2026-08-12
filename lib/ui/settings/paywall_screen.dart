import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventa/core/utils/free_tier.dart';
import 'package:inventa/data/models/asset.dart';
import 'package:inventa/providers/asset_provider.dart';
import 'package:inventa/providers/pro_provider.dart';
import 'package:inventa/l10n/app_localizations.dart';
import 'package:inventa/ui/settings/pdf_preview_screen.dart';

/// How many items the sample report shows.
///
/// Enough to fill a room table and give the per-item detail pages something
/// to say; a 200-item inventory rendered in full would be slow to build and
/// would not sell the idea any harder than three items do.
const int kSampleReportItemCap = 3;

/// Items to build the sample report from: the owner's own, when there are
/// any, because a report about the sofa the owner is looking at is far more
/// persuasive than one about a sofa that is not theirs, and it costs nothing
/// extra to build from data already on the device.
List<Asset> sampleReportAssets(List<Asset> owned, AppLocalizations l10n) {
  if (owned.isNotEmpty) return owned.take(kSampleReportItemCap).toList();
  return buildDemoSampleAssets(l10n);
}

/// Plausible stand-in items for a paywall visitor with nothing recorded yet.
///
/// Named from the same item-name catalog the app already translates, so the
/// sample reads correctly in whatever language the paywall is shown in.
/// Dated so the two columns the sample exists to sell -- the depreciation
/// estimate and the warranty date -- both actually have something in them;
/// an empty-columned sample would argue against buying, not for it.
List<Asset> buildDemoSampleAssets(AppLocalizations l10n) {
  final now = DateTime.now();
  return [
    Asset(
      id: 'sample-sofa',
      name: l10n.itemSofa,
      price: 1200,
      currency: 'USD',
      room: kAssetRooms.first,
      category: 'Furniture',
      purchaseDate: now.subtract(const Duration(days: 365 * 3)),
      warrantyExpiry: now.subtract(const Duration(days: 365)),
    ),
    Asset(
      id: 'sample-television',
      name: l10n.itemTelevision,
      price: 899,
      currency: 'USD',
      room: kAssetRooms.first,
      category: 'Electronics',
      purchaseDate: now.subtract(const Duration(days: 365 * 2)),
      warrantyExpiry: now.add(const Duration(days: 180)),
    ),
    Asset(
      id: 'sample-washing-machine',
      name: l10n.itemWashingMachine,
      price: 650,
      currency: 'USD',
      room: 'Basement',
      category: 'Appliances',
      purchaseDate: now.subtract(const Duration(days: 365 * 4)),
      warrantyExpiry: now.subtract(const Duration(days: 400)),
    ),
  ];
}

/// Where a [ProOutcome] becomes user-facing text. Kept beside the one screen
/// that shows purchase outcomes today, not on [ProState] itself, so the
/// notifier never goes stale when the language changes underneath it.
extension ProOutcomeText on ProOutcome {
  String localize(AppLocalizations l10n) {
    switch (this) {
      case ProOutcome.storeUnavailable:
        return l10n.storeUnavailable;
      case ProOutcome.purchasePending:
        return l10n.purchasePending;
      case ProOutcome.purchaseCancelled:
        return l10n.purchaseCancelled;
      case ProOutcome.purchaseFailed:
        return l10n.purchaseFailed;
      case ProOutcome.purchaseAlreadyOwnedUnlinked:
        return l10n.purchaseAlreadyOwnedUnlinked;
      case ProOutcome.purchaseSucceeded:
        return l10n.welcomeToPro;
      case ProOutcome.restoredToPro:
        return l10n.restoredToPro;
      case ProOutcome.restoredNothingFound:
        return l10n.restoredNothingFound;
      case ProOutcome.restoreFailed:
        return l10n.restorePurchasesFailed;
    }
  }
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    // If the store failed to start earlier -- a moment without signal on first
    // launch is enough -- try again now, quietly, before the user is shown a
    // dead buy button. Returns immediately when the store is already up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proProvider.notifier).retryStoreConnection();
    });
  }

  /// Opens the real Pro report, built from what's already on the device.
  ///
  /// Reads whatever [allAssetsProvider] already holds rather than its
  /// `.future`: the paywall is reached from a tab that has always already
  /// watched it, so the value is normally there, and `.future` is not safe to
  /// read imperatively here -- this provider's own `ref.watch` on
  /// [assetListProvider] means it can still be mid-rebuild the first time
  /// anything touches it, and a `.future` captured in that window is
  /// abandoned by the rebuild and never completes. An inventory that has not
  /// loaded yet reads the same as an empty one and falls back to the demo
  /// items, which beats a button that silently does nothing.
  void _showSampleReport() {
    final l10n = AppLocalizations.of(context)!;
    final owned = ref.read(allAssetsProvider).valueOrNull ?? const <Asset>[];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewScreen(
              assets: sampleReportAssets(owned, l10n),
              sample: true,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proState = ref.watch(proProvider);
    final proNotifier = ref.read(proProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    // Listen for state changes
    ref.listen(proProvider, (previous, next) {
      if (next.errorOutcome != null &&
          (next.errorOutcome != previous?.errorOutcome ||
              next.errorDetail != previous?.errorDetail)) {
        // The raw exception only ever rides alongside the outcome when
        // toggleDetailedErrors is on, so it is safe to always append here.
        final message =
            next.errorDetail == null
                ? next.errorOutcome!.localize(l10n)
                : '${next.errorOutcome!.localize(l10n)}: ${next.errorDetail}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      if (next.successOutcome != null &&
          next.successOutcome != previous?.successOutcome) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successOutcome!.localize(l10n))),
        );
      }

      if (next.isPro && !(previous?.isPro ?? false)) {
        if (next.successOutcome == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.welcomeToPro)));
        }
        Navigator.pop(context);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.upgradeToPro)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.diamond, size: 80, color: Colors.purple),
                const SizedBox(height: 24),
                GestureDetector(
                  // Debug builds only. In release a long press on the headline
                  // swapped every friendly purchase error for a raw exception
                  // dump, on the one screen where a confused customer is most
                  // likely to be pressing things.
                  onLongPress:
                      kDebugMode
                          ? () {
                            proNotifier.toggleDetailedErrors();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Toggled detailed error logs"),
                              ),
                            );
                          }
                          : null,
                  child: Text(
                    l10n.unlockFullPotential,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.paywallLead,
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                _buildBenefitItem(
                  Icons.all_inclusive,
                  l10n.paywallUnlimited,
                  l10n.paywallUnlimitedBody(kFreeItemLimit),
                ),
                _buildBenefitItem(
                  Icons.description,
                  l10n.paywallReport,
                  l10n.paywallReportBody,
                ),
                _buildBenefitItem(
                  Icons.save_alt,
                  l10n.paywallBackup,
                  l10n.paywallBackupBody,
                ),
                _buildBenefitItem(
                  Icons.fingerprint,
                  l10n.paywallBiometric,
                  l10n.paywallBiometricBody,
                ),

                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _showSampleReport,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l10n.paywallSeeSample),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(color: Colors.purple),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                const SizedBox(height: 32),

                if (!proState.isStoreAvailable && !proState.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Text(
                          l10n.storeUnavailable,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                        // The way back. Without it the only cure for a failed
                        // start was force-quitting the app.
                        TextButton.icon(
                          onPressed: () => proNotifier.retryStoreConnection(),
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.retryStore),
                        ),
                      ],
                    ),
                  ),

                ElevatedButton(
                  onPressed:
                      proState.isLoading || !proState.isStoreAvailable
                          ? null
                          : () => proNotifier.purchasePro(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    // Priced by the store, so the figure is right in every
                    // currency and stays right if the price ever changes.
                    proState.priceString == null
                        ? l10n.upgrade
                        : l10n.upgradeFor(proState.priceString!),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      proState.isLoading || !proState.isStoreAvailable
                          ? null
                          : () => proNotifier.restorePurchases(),
                  child: Text(l10n.restorePurchases),
                ),
                const SizedBox(height: 20),
                if (proState.proPackage != null)
                  Text(
                    proState.isSubscription
                        ? l10n.subscriptionFinePrint
                        : l10n.oneTimeFinePrint,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),

          if (proState.isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.purple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
