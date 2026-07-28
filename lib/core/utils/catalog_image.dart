import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:itemize/core/catalog/asset_catalog.dart';
import 'package:itemize/core/utils/image_storage.dart';

/// Paints a catalog item to a real image file.
///
/// Everywhere an asset's picture is shown it is read with `FileImage`, so a
/// catalog pick has to end up on disk like a camera or gallery pick does --
/// that keeps the display code from having to know where a picture came from.
class CatalogImage {
  static const double _canvasSize = 900;

  static Future<String> render(CatalogItem item) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, _canvasSize, _canvasSize),
    );

    final tint = catalogTints[item.category] ?? catalogTints['Other']!;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _canvasSize, _canvasSize),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(0, _canvasSize),
          tint,
        ),
    );

    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(item.icon.codePoint),
        style: TextStyle(
          fontFamily: item.icon.fontFamily,
          package: item.icon.fontPackage,
          fontSize: _canvasSize * 0.46,
          color: const Color(0xFF1C1C1E).withAlpha(210),
        ),
      ),
    )..layout();

    painter.paint(
      canvas,
      Offset(
        (_canvasSize - painter.width) / 2,
        (_canvasSize - painter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _canvasSize.toInt(),
      _canvasSize.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();

    if (bytes == null) {
      throw StateError('Could not encode catalog image for ${item.label}');
    }

    return ImageStorage.saveBytes(bytes.buffer.asUint8List());
  }
}
