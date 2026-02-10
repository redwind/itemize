import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itemize/core/utils/pdf_service.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/providers/settings_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends ConsumerWidget {
  final List<Asset> assets;

  const PdfPreviewScreen({super.key, required this.assets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Preview')),
      body: PdfPreview(
        build:
            (format) => PDFService().generateAssetsReport(
              assets,
              ref.watch(settingsProvider).currencySymbol,
            ),
        allowSharing: true,
        allowPrinting: true,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: 'itemize_report.pdf',
      ),
    );
  }
}
