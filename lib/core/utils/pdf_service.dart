import 'package:flutter/services.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFService {
  Future<Uint8List> generateAssetsReport(
    List<Asset> assets,
    String currencySymbol,
  ) async {
    final doc = pw.Document();

    // Load font if needed (printing package uses default usually)
    // final font = await PdfGoogleFonts.interRegular();

    double totalValue = assets.fold(0, (sum, item) => sum + item.price);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Itemize Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Date: ${DateTime.now().toIso8601String().split('T')[0]}',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Assets: ${assets.length}',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.Text(
                    'Total Value: $currencySymbol${totalValue.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Name', 'Category', 'Price', 'Purchase Date'],
              data:
                  assets.map((asset) {
                    return [
                      asset.name,
                      asset.category,
                      '$currencySymbol${asset.price.toStringAsFixed(2)}',
                      asset.purchaseDate.toIso8601String().split('T')[0],
                    ];
                  }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),
            if (assets.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 20),
                child: pw.Text(
                  "Notes: Does not include photo attachments in this summary.",
                ),
              ),
          ];
        },
      ),
    );

    return await doc.save();
  }

  Future<void> printOrShareReport(
    List<Asset> assets,
    String currencySymbol,
  ) async {
    final pdfBytes = await generateAssetsReport(assets, currencySymbol);
    await Printing.sharePdf(bytes: pdfBytes, filename: 'itemize_report.pdf');
  }
}
