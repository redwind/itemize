import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:itemize/core/utils/depreciation.dart';
import 'package:itemize/core/utils/image_storage.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/service_record.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Longest edge, in pixels, that a photo is shrunk to for the report.
///
/// Stored photos are up to 2048px, which at a hundred items would produce a
/// document too large to email — and an adjuster reads this on a screen or on
/// A4, where 900 is already more than the page can show.
const int _kReportImageMaxEdge = 900;

/// Photos per item beyond the cover.
///
/// Enough to show the item, a serial plate and one detail. Past that the page
/// stops being evidence and starts being an album.
const int _kExtraPhotosPerItem = 2;

class PDFService {
  /// Builds the report.
  ///
  /// The Pro document is the one the paywall has always described: every item
  /// on its own row with photographs, serial number, receipt and an estimated
  /// current value, grouped by room and signed at the end. The free document is
  /// the summary table alone — useful, and visibly not the same thing.
  Future<Uint8List> generateAssetsReport(
    List<Asset> assets,
    String Function(double) formatAmount, {
    bool isPro = false,
    Map<String, List<ServiceRecord>> serviceHistory = const {},
  }) async {
    final generatedAt = DateTime.now();
    final summary = Depreciation.summarize(assets, asOf: generatedAt);

    final images =
        isPro ? await _loadImages(assets) : const <String, Uint8List>{};

    final doc = pw.Document(theme: await _theme());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => _footer(context, isPro, generatedAt),
        build:
            (context) => [
              ..._coverBlock(
                assets: assets,
                summary: summary,
                formatAmount: formatAmount,
                generatedAt: generatedAt,
                isPro: isPro,
              ),
              pw.SizedBox(height: 24),
              ..._roomTables(assets, formatAmount, isPro: isPro),
              if (isPro) ...[
                pw.SizedBox(height: 24),
                ..._itemDetails(assets, formatAmount, images, serviceHistory),
                pw.SizedBox(height: 24),
                ..._declarationBlock(generatedAt),
              ] else ...[
                pw.SizedBox(height: 24),
                _upgradeNotice(),
              ],
            ],
      ),
    );

    return doc.save();
  }

  // --- Fonts ---------------------------------------------------------------

  /// Cached across reports: the preview rebuilds on every page-format change,
  /// and re-parsing two TTFs each time is wasted work.
  static pw.ThemeData? _cachedTheme;

  /// A theme backed by an embedded Unicode font.
  ///
  /// PDF's built-in Helvetica is Latin-1 only, so without this every Vietnamese
  /// item name comes out blank and so does the `₫` the app offers as a
  /// currency. The failure is silent in the document itself, which is what
  /// makes it worth the 336 KB.
  ///
  /// If the fonts cannot be loaded the report is still produced on the built-in
  /// font: a Latin-only report beats no report, and an English-language
  /// inventory is unaffected.
  static Future<pw.ThemeData?> _theme() async {
    if (_cachedTheme != null) return _cachedTheme;
    try {
      final regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
      );
      final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
      );
      return _cachedTheme = pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        italic: regular,
        boldItalic: bold,
      );
    } catch (e) {
      if (kDebugMode) print('Report fonts unavailable, falling back: $e');
      return null;
    }
  }

  // --- Cover ---------------------------------------------------------------

  List<pw.Widget> _coverBlock({
    required List<Asset> assets,
    required DepreciationSummary summary,
    required String Function(double) formatAmount,
    required DateTime generatedAt,
    required bool isPro,
  }) {
    final rooms = assets.map((a) => a.room).toSet().length;
    final withSerial =
        assets.where((a) => (a.serialNumber ?? '').isNotEmpty).length;
    final withReceipt =
        assets.where((a) => (a.receiptPath ?? '').isNotEmpty).length;

    return [
      pw.Header(
        level: 0,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              isPro ? 'Home Inventory Report' : 'Itemize Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(DateFormat.yMMMMd().format(generatedAt)),
          ],
        ),
      ),
      pw.SizedBox(height: 16),
      _summaryTable([
        ['Items recorded', '${assets.length}'],
        ['Rooms covered', '$rooms'],
        ['Total purchase price', formatAmount(summary.totalPaid)],
        if (isPro) ...[
          ['Estimated value today', formatAmount(summary.totalCurrent)],
          ['Estimated depreciation', formatAmount(summary.totalLoss)],
          ['Items with a serial number', '$withSerial of ${assets.length}'],
          ['Items with a receipt attached', '$withReceipt of ${assets.length}'],
        ],
      ]),
      if (isPro) ...[
        pw.SizedBox(height: 12),
        pw.Text(
          'Estimated values are straight-line figures based on conventional '
          'useful life by category. They are provided to help you check your '
          'cover and are not a valuation; your insurer may apply a different '
          'schedule.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    ];
  }

  pw.Widget _summaryTable(List<List<String>> rows) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
      ),
      child: pw.Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration:
                  i.isEven
                      ? const pw.BoxDecoration(color: PdfColors.grey100)
                      : null,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(rows[i][0], style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(
                    rows[i][1],
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Room tables ---------------------------------------------------------

  List<pw.Widget> _roomTables(
    List<Asset> assets,
    String Function(double) formatAmount, {
    required bool isPro,
  }) {
    if (assets.isEmpty) {
      return [pw.Text('No items recorded.')];
    }

    final byRoom = <String, List<Asset>>{};
    for (final asset in assets) {
      byRoom.putIfAbsent(asset.room, () => []).add(asset);
    }
    final rooms = byRoom.keys.toList()..sort();

    return [
      for (final room in rooms) ...[
        pw.Header(level: 1, text: room),
        pw.TableHelper.fromTextArray(
          headers: [
            'Item',
            'Category',
            'Serial / Model',
            'Purchased',
            'Paid',
            if (isPro) 'Est. today',
          ],
          data: [
            for (final asset in byRoom[room]!)
              [
                asset.name,
                asset.category,
                [
                  asset.serialNumber,
                  asset.model,
                ].where((v) => v != null && v.isNotEmpty).join(' / '),
                DateFormat.yMd().format(asset.purchaseDate),
                formatAmount(asset.price),
                if (isPro) formatAmount(Depreciation.currentValue(asset)),
              ],
          ],
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
            5: pw.Alignment.centerRight,
          },
        ),
        pw.SizedBox(height: 6),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '$room subtotal: '
            '${formatAmount(byRoom[room]!.fold<double>(0, (s, a) => s + a.price))}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 16),
      ],
    ];
  }

  // --- Per-item detail -----------------------------------------------------

  List<pw.Widget> _itemDetails(
    List<Asset> assets,
    String Function(double) formatAmount,
    Map<String, Uint8List> images,
    Map<String, List<ServiceRecord>> serviceHistory,
  ) {
    if (assets.isEmpty) return [];

    return [
      pw.Header(level: 1, text: 'Item detail'),
      for (final asset in assets)
        _itemBlock(
          asset,
          formatAmount,
          images,
          serviceHistory[asset.id] ?? const [],
        ),
    ];
  }

  pw.Widget _itemBlock(
    Asset asset,
    String Function(double) formatAmount,
    Map<String, Uint8List> images,
    List<ServiceRecord> history,
  ) {
    final photos =
        asset.photoPaths
            .take(1 + _kExtraPhotosPerItem)
            .map((p) => images[p])
            .whereType<Uint8List>()
            .toList();
    final receipt = images[asset.receiptPath];

    final facts = <List<String>>[
      ['Room', asset.room],
      ['Category', asset.category],
      if ((asset.brand ?? '').isNotEmpty) ['Brand', asset.brand!],
      if ((asset.model ?? '').isNotEmpty) ['Model', asset.model!],
      if ((asset.serialNumber ?? '').isNotEmpty)
        ['Serial number', asset.serialNumber!],
      if ((asset.barcode ?? '').isNotEmpty) ['Barcode', asset.barcode!],
      ['Purchased', DateFormat.yMMMd().format(asset.purchaseDate)],
      ['Purchase price', formatAmount(asset.price)],
      ['Estimated value today', formatAmount(Depreciation.currentValue(asset))],
      if (asset.warrantyExpiry != null)
        ['Warranty until', DateFormat.yMMMd().format(asset.warrantyExpiry!)],
    ];

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            asset.name,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (photos.isNotEmpty) ...[
                pw.Column(
                  children: [
                    for (final photo in photos)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        width: 130,
                        height: 100,
                        child: pw.Image(
                          pw.MemoryImage(photo),
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(width: 12),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (final fact in facts)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(
                              width: 110,
                              child: pw.Text(
                                fact[0],
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                fact[1],
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if ((asset.notes ?? '').isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        asset.notes!,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (history.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _serviceHistoryBlock(history, formatAmount),
          ],
          if (receipt != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Receipt',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              height: 150,
              alignment: pw.Alignment.centerLeft,
              child: pw.Image(pw.MemoryImage(receipt), fit: pw.BoxFit.contain),
            ),
          ],
        ],
      ),
    );
  }

  /// What has been done to the item, and what it cost.
  ///
  /// Carried into the report because it argues two things at once: it shows the
  /// item was looked after, which is what a manufacturer asks when a warranty
  /// claim turns on whether the servicing was kept up, and it evidences money
  /// spent on an item whose replacement is being claimed for.
  pw.Widget _serviceHistoryBlock(
    List<ServiceRecord> history,
    String Function(double) formatAmount,
  ) {
    final total = history.fold<double>(0, (sum, r) => sum + r.cost);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Service history',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 3),
        for (final record in history)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 1),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 60,
                  child: pw.Text(
                    DateFormat.yMd().format(record.date),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    [
                      record.kind.label,
                      if ((record.description ?? '').isNotEmpty)
                        record.description!,
                      if ((record.provider ?? '').isNotEmpty) record.provider!,
                    ].join(' — '),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Text(
                  record.cost > 0 ? formatAmount(record.cost) : '—',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Spent on this item to date: ${formatAmount(total)}',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  // --- Closing blocks ------------------------------------------------------

  List<pw.Widget> _declarationBlock(DateTime generatedAt) {
    return [
      pw.Header(level: 1, text: 'Declaration'),
      pw.Text(
        'I confirm that the items listed in this report were owned by me on '
        '${DateFormat.yMMMMd().format(generatedAt)}, and that the details and '
        'photographs given are accurate to the best of my knowledge.',
        style: const pw.TextStyle(fontSize: 10),
      ),
      pw.SizedBox(height: 32),
      pw.Row(
        children: [
          pw.Expanded(child: _signatureLine('Signature')),
          pw.SizedBox(width: 32),
          pw.Expanded(child: _signatureLine('Date')),
        ],
      ),
    ];
  }

  pw.Widget _signatureLine(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700)),
          ),
          height: 1,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _upgradeNotice() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'This is the summary report.',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Itemize Pro adds a page for every item with its photographs, '
            'serial number, receipt, service history and estimated current '
            'value, plus a signed declaration — the form an insurer asks for '
            'when you claim.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context, bool isPro, DateTime generatedAt) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        isPro
            ? 'Itemize · ${DateFormat.yMd().format(generatedAt)} · '
                'Page ${context.pageNumber} of ${context.pagesCount}'
            : 'Generated by Itemize Free · '
                'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
      ),
    );
  }

  // --- Images --------------------------------------------------------------

  /// Reads and shrinks every photo the report will show.
  ///
  /// Paths are resolved to absolute ones here, on the main isolate, because
  /// [ImageStorage] holds the documents directory in static state that a
  /// spawned isolate would not inherit. The decoding itself is handed off, as
  /// a hundred JPEGs would otherwise freeze the UI while the preview builds.
  Future<Map<String, Uint8List>> _loadImages(List<Asset> assets) async {
    final wanted = <String, String>{};

    void want(String? stored) {
      if (stored == null || stored.isEmpty || wanted.containsKey(stored)) {
        return;
      }
      final file = ImageStorage.resolve(stored);
      if (file != null && file.existsSync()) wanted[stored] = file.path;
    }

    for (final asset in assets) {
      for (final photo in asset.photoPaths.take(1 + _kExtraPhotosPerItem)) {
        want(photo);
      }
      want(asset.receiptPath);
    }

    if (wanted.isEmpty) return const {};

    try {
      return await compute(_downscaleAll, wanted);
    } catch (e) {
      // A report without pictures still beats no report, and the caller has no
      // better answer to give than the one it already shows.
      if (kDebugMode) print('Preparing report images failed: $e');
      return const {};
    }
  }
}

/// Runs in a background isolate: {storedPath: absolutePath} in, JPEG bytes out.
///
/// An image that will not decode is skipped rather than failing the batch; one
/// unreadable photo should not cost the owner the whole report.
Map<String, Uint8List> _downscaleAll(Map<String, String> paths) {
  final out = <String, Uint8List>{};

  paths.forEach((stored, absolute) {
    try {
      final decoded = img.decodeImage(File(absolute).readAsBytesSync());
      if (decoded == null) return;

      final longestEdge =
          decoded.width > decoded.height ? decoded.width : decoded.height;
      final resized =
          longestEdge <= _kReportImageMaxEdge
              ? decoded
              : img.copyResize(
                decoded,
                width:
                    decoded.width >= decoded.height
                        ? _kReportImageMaxEdge
                        : null,
                height:
                    decoded.height > decoded.width
                        ? _kReportImageMaxEdge
                        : null,
                maintainAspect: true,
              );

      out[stored] = img.encodeJpg(resized, quality: 80);
    } catch (_) {
      // Skipped, as above.
    }
  });

  return out;
}
