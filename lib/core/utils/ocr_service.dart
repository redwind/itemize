import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

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
    String? date;
    double? price;
    String? possibleName;

    // Date Regex (MM/DD/YYYY or DD/MM/YYYY)
    final dateRegex = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      date = dateMatch.group(0);
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
}
