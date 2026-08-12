import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventa/core/utils/pdf_service.dart';
import 'package:inventa/data/models/asset.dart';
import 'package:inventa/data/models/service_record.dart';
import 'package:inventa/providers/asset_provider.dart';
import 'package:inventa/providers/settings_provider.dart';
import 'package:inventa/providers/pro_provider.dart';
import 'package:inventa/ui/settings/paywall_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:inventa/l10n/app_localizations.dart';

class PdfPreviewScreen extends ConsumerWidget {
  final List<Asset> assets;

  /// True for the paywall's "see a sample" preview rather than a real export.
  ///
  /// Forces the Pro layout regardless of [proProvider], so a free visitor sees
  /// the document Pro produces rather than the one they already have. Sharing
  /// and printing are switched off for the same reason a shop demo doesn't let
  /// you walk out with the till receipt: nothing here should be a way to get
  /// the Pro document without paying for it.
  final bool sample;

  const PdfPreviewScreen({
    super.key,
    required this.assets,
    this.sample = false,
  });

  /// Groups the whole history by item, in one read.
  ///
  /// PdfPreview rebuilds on every page-format change, so fetching per item on
  /// each build would mean hundreds of queries each time somebody switches from
  /// A4 to Letter.
  Future<Map<String, List<ServiceRecord>>> _history(WidgetRef ref) async {
    final records = await ref.read(assetRepositoryProvider).allServiceRecords();
    final byAsset = <String, List<ServiceRecord>>{};
    for (final record in records) {
      byAsset.putIfAbsent(record.assetId, () => []).add(record);
    }
    return byAsset;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = sample || ref.watch(proProvider).isPro;
    // Resolved before the builder rather than inside it: PdfPreview calls that
    // builder asynchronously, by which time reading a BuildContext is unsafe.
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _PreviewBar(sample: sample),
      body: Column(
        children: [
          if (sample) const _SampleBanner(),
          if (!isPro) _UpgradeBanner(itemCount: assets.length),
          Expanded(
            child: PdfPreview(
              build:
                  (format) async => PDFService().generateAssetsReport(
                    assets,
                    ref.read(settingsProvider).formatAmount,
                    l10n: l10n,
                    isPro: isPro,
                    serviceHistory: isPro ? await _history(ref) : const {},
                  ),
              allowSharing: !sample,
              allowPrinting: !sample,
              initialPageFormat: PdfPageFormat.a4,
              pdfFileName: 'inventa_report.pdf',
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewBar extends StatelessWidget implements PreferredSizeWidget {
  final bool sample;

  const _PreviewBar({required this.sample});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      title: Text(sample ? l10n.sampleReportTitle : l10n.reportPreview),
    );
  }
}

/// Says, on the document itself, that it is not the one the viewer just paid
/// for -- because sharing being greyed out only reads as a bug otherwise.
class _SampleBanner extends StatelessWidget {
  const _SampleBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        border: Border(bottom: BorderSide(color: Colors.purple.shade100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Colors.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.sampleReportNote,
              style: const TextStyle(fontSize: 13, color: Colors.purple),
            ),
          ),
        ],
      ),
    );
  }
}

/// Says what the paid document adds, on the screen where it matters.
///
/// This is the one moment a free user meets the ceiling, and until now the only
/// mention of it was a paragraph on the last page of the generated PDF —
/// reachable by producing the document, waiting for it to render and reading to
/// the end. Nobody was going to find it there.
///
/// Written as a comparison rather than a pitch: what is in their hands against
/// what an insurer asks for. The difference is the argument.
class _UpgradeBanner extends StatelessWidget {
  final int itemCount;

  const _UpgradeBanner({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        border: Border(bottom: BorderSide(color: Colors.purple.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, size: 18, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.summaryReportBanner,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.summaryReportBannerBody(itemCount),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaywallScreen(),
                      ),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l10n.seeWhatProAdds),
              ),
              const SizedBox(width: 12),
              // The free report is still worth having, and saying so keeps this
              // from reading as a locked door.
              Expanded(
                child: Text(
                  l10n.canStillShare,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
