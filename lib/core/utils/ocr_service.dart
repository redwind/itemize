import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:intl/intl.dart';
import 'package:itemize/core/utils/nameplate_parser.dart';

class OCRService {
  final _textRecognizer = TextRecognizer();
  final _barcodeScanner = BarcodeScanner();

  Future<String?> scanBarcode(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final barcodes = await _barcodeScanner.processImage(inputImage);

    if (barcodes.isNotEmpty) {
      // Return the first barcode value
      return barcodes.first.rawValue;
    }
    return null;
  }

  /// Reads the maker, model and serial off a photographed rating plate.
  ///
  /// Runs entirely on the device against the recognizer already bundled for
  /// receipts, so it costs nothing per scan and needs no network. See
  /// [NameplateParser] for why this replaced an online barcode lookup.
  Future<NameplateInfo> scanNameplate(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return NameplateParser.parse(recognizedText.text);
  }

  Future<Map<String, dynamic>> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final text = recognizedText.text;

    return _parseReceiptText(text);
  }

  void close() {
    _textRecognizer.close();
    _barcodeScanner.close();
  }

  Map<String, dynamic> _parseReceiptText(String text) {
    DateTime? date;
    double? price;
    String? possibleName;

    // Date Regex (MM/DD/YYYY or DD/MM/YYYY)
    final dateRegex = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      date = parseReceiptDate(dateMatch.group(0));
    }

    // Price Regex (Find largest price generally)
    // Matches $10.99, 10.99 €, etc.
    final priceRegex = RegExp(
      r'[\$€£¥]?\s?\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?',
    );
    final prices =
        priceRegex.allMatches(text).map((m) {
          String clean = m.group(0)!.replaceAll(RegExp(r'[^\d.,]'), '');
          // Handle comma decimals vs dot decimals usually tricky, assume dot or last separator is decimal
          if (clean.contains(',')) {
            clean = clean.replaceAll(',', '.'); // Naive replacement
          }
          return double.tryParse(clean) ?? 0.0;
        }).toList();

    if (prices.isNotEmpty) {
      // Heuristic: Total is usually the largest number
      prices.sort();
      price = prices.last;
    }

    // Name Heuristic: First line that isn't date/price/header?
    // Very naive, just take the first line that has reasonable length
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.trim().length > 3 && !line.contains(RegExp(r'\d'))) {
        // Skip lines with numbers logic?
        possibleName = line.trim();
        break;
      }
    }
    possibleName ??= lines.isNotEmpty ? lines.first : "Unknown Item";

    return {'date': date, 'price': price, 'name': possibleName};
  }

  /// Turns the date lifted off a receipt into a real one, or null.
  ///
  /// `03/04/2024` is March or April depending on where the till stood, and the
  /// receipt does not say. Where one number exceeds 12 the order is settled by
  /// arithmetic; otherwise it follows the locale the app is running in, which
  /// is the best guess available. A date in the future, or older than twenty
  /// years, is treated as a misread and dropped: a wrong purchase date quietly
  /// overwriting a right one is worse than leaving the owner to type it.
  ///
  /// [today] and [locale] exist so this can be tested; both default to the
  /// running app.
  static DateTime? parseReceiptDate(
    String? raw, {
    DateTime? today,
    String? locale,
  }) {
    if (raw == null) return null;
    final parts = raw.split(RegExp(r'[/-]'));
    if (parts.length != 3) return null;

    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    var year = int.tryParse(parts[2]);
    if (first == null || second == null || year == null) return null;
    if (year < 100) year += 2000;

    final bool dayFirst;
    if (first > 12) {
      dayFirst = true;
    } else if (second > 12) {
      dayFirst = false;
    } else {
      dayFirst = !_isMonthFirstLocale(locale ?? Intl.getCurrentLocale());
    }

    final day = dayFirst ? first : second;
    final month = dayFirst ? second : first;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    final parsed = DateTime(year, month, day);
    // DateTime rolls 31 February over into March; reject rather than record the
    // wrong day.
    if (parsed.month != month || parsed.day != day) return null;

    final now = today ?? DateTime.now();
    if (parsed.isAfter(now)) return null;
    if (parsed.isBefore(DateTime(now.year - 20))) return null;
    return parsed;
  }

  /// Whether [locale] writes 3/4 as March the 4th.
  ///
  /// Read off the locale string rather than out of `DateFormat`'s pattern:
  /// that lookup throws unless the locale database has been initialised for
  /// the locale in question, and a receipt scan must not fail over the date
  /// being ambiguous. Month-first is near enough a US convention -- everywhere
  /// else writes the day first, or writes the year first and so never reaches
  /// this branch.
  static bool _isMonthFirstLocale(String locale) {
    final normalized = locale.replaceAll('-', '_');
    if (normalized == 'en') return true; // intl's bare 'en' follows en_US
    return normalized == 'en_US';
  }
}
