import 'package:flutter/widgets.dart';

import 'package:itemize/core/utils/image_storage.dart';

/// An item photo decoded no larger than the box it is shown in.
///
/// Stored photos run up to 2048px wide (see [ImageStorage]), while every
/// call site here shows one at 48-220 logical px. Decoding at source
/// resolution for every row of a 200-item list is roughly 12-16MB of bitmap
/// per tile -- decode jank on every newly visible row, and a real OOM risk
/// on a mid-range Android phone. [ResizeImage] decodes straight to the pixel
/// size actually needed, so the cache only ever holds what is on screen.
///
/// Use the widget itself in place of `Image.file`, or [provider] in place of
/// a bare `FileImage` inside a [DecorationImage] -- `DecorationImage` needs
/// an [ImageProvider], not a widget, so there is no way to share one build
/// method across both shapes.
class AssetThumbnail extends StatelessWidget {
  const AssetThumbnail({
    super.key,
    required this.path,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  /// The value stored on the model, resolved through [ImageStorage.resolve]
  /// the same way every other screen already does.
  final String? path;

  /// The display box, in logical pixels.
  final double width;
  final double height;

  final BoxFit fit;

  /// Shown when [path] does not resolve to a file. Left null by default
  /// rather than defaulting to some icon, since every call site already has
  /// its own empty state and a second, different one here would just fight
  /// it.
  final Widget? placeholder;

  /// The resized [ImageProvider] for [path], or null if it does not resolve.
  /// For the call sites that need the image inside a [DecorationImage]
  /// rather than as a child widget.
  ///
  /// [width]/[height] are logical pixels -- they get multiplied by the
  /// device pixel ratio here rather than left to the caller, which is what
  /// keeps a 3x screen from getting a soft, under-decoded tile.
  ///
  /// [fit] decides how many axes are handed to [ResizeImage]. Passing both
  /// width and height under the default [ResizeImagePolicy.exact] stretches
  /// the source to that exact box regardless of its own aspect ratio, which
  /// would squash a cover-fit photo whenever it doesn't match the tile's
  /// shape. Cover-fit boxes are therefore only ever given a width, so the
  /// decode keeps the source's aspect ratio and [BoxFit.cover] does the
  /// cropping at paint time exactly as it does on the un-resized image
  /// today. Contain-fit boxes (the receipt photo) use
  /// [ResizeImagePolicy.fit] instead, which is the decode-time equivalent of
  /// [BoxFit.contain].
  static ImageProvider? provider(
    BuildContext context,
    String? path, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
  }) {
    final file = ImageStorage.resolve(path);
    if (file == null) return null;

    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (fit == BoxFit.contain) {
      return ResizeImage(
        FileImage(file),
        width: (width * dpr).round(),
        height: (height * dpr).round(),
        policy: ResizeImagePolicy.fit,
      );
    }
    return ResizeImage(FileImage(file), width: (width * dpr).round());
  }

  @override
  Widget build(BuildContext context) {
    final image = provider(
      context,
      path,
      width: width,
      height: height,
      fit: fit,
    );
    if (image == null) return placeholder ?? const SizedBox.shrink();
    return Image(image: image, width: width, height: height, fit: fit);
  }
}
