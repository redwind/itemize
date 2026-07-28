import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Stores item pictures inside the app's Documents directory and addresses them
/// by a path *relative* to it.
///
/// iOS gives an app a fresh sandbox container on reinstall and can change it on
/// update, so an absolute path recorded today may point nowhere tomorrow --
/// which would silently empty every item's photo. Persisting only the relative
/// part and rebuilding the absolute path at read time keeps pictures attached
/// across those moves.
class ImageStorage {
  static const _folder = 'images';
  static String? _documentsPath;

  /// Must be awaited during startup: the widgets that display pictures are
  /// synchronous, so the directory has to be known before the first build.
  static Future<void> init() async {
    _documentsPath = (await getApplicationDocumentsDirectory()).path;
  }

  static Future<String> _folderPath() async {
    _documentsPath ??= (await getApplicationDocumentsDirectory()).path;
    final directory = Directory('${_documentsPath!}/$_folder');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  /// Copies [sourcePath] into storage, returning the value to persist.
  static Future<String> saveFile(String sourcePath) async {
    final extension = sourcePath.split('.').last.toLowerCase();
    final name =
        '${const Uuid().v4()}.${extension.isEmpty || extension.length > 5 ? 'jpg' : extension}';
    await File(sourcePath).copy('${await _folderPath()}/$name');
    return '$_folder/$name';
  }

  /// Writes [bytes] into storage, returning the value to persist.
  static Future<String> saveBytes(Uint8List bytes, {String extension = 'png'}) async {
    final name = '${const Uuid().v4()}.$extension';
    await File('${await _folderPath()}/$name').writeAsBytes(bytes);
    return '$_folder/$name';
  }

  /// Deletes a stored picture, if it is still there.
  ///
  /// Only safe to call for a file nothing refers to any more. Most of the app
  /// deliberately leaves orphans alone: a photo dropped from a form that is
  /// then cancelled is still the saved item's photo, and deleting it eagerly
  /// would take a picture the owner never agreed to lose.
  static Future<void> delete(String? stored) async {
    final file = resolve(stored);
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Storage that will not give a file up is not worth failing a flow over.
    }
  }

  /// The directory pictures live in, created if it is not there yet.
  ///
  /// Exposed for the backup restore, which has to write files back under the
  /// exact names the archived items refer to; [saveBytes] mints a new name and
  /// would leave every restored item pointing at nothing.
  static Future<String> imagesDirectory() => _folderPath();

  /// The root the stored relative paths hang off.
  static Future<String> documentsDirectory() async {
    _documentsPath ??= (await getApplicationDocumentsDirectory()).path;
    return _documentsPath!;
  }

  static const _documentsMarker = '/Documents/';

  /// Resolved legacy paths, so scrolling a list does not re-stat the disk.
  static final Map<String, File> _legacyCache = {};

  /// Turns a stored value back into a file.
  ///
  /// Rows written before this change hold an absolute path baked against the
  /// sandbox container that was current at the time. When the container moves,
  /// iOS carries the files across but that recorded path stops resolving, so
  /// fall back to re-rooting the part below `Documents/` onto the current one.
  static File? resolve(String? stored) {
    if (stored == null || stored.isEmpty) return null;

    final documents = _documentsPath;

    if (!stored.startsWith('/')) {
      if (documents == null) return null;
      return File('$documents/$stored');
    }

    final cached = _legacyCache[stored];
    if (cached != null) return cached;

    final direct = File(stored);
    if (direct.existsSync()) {
      _legacyCache[stored] = direct;
      return direct;
    }
    if (documents == null) return direct;

    final index = stored.indexOf(_documentsMarker);
    if (index == -1) return direct;

    final rebased = File(
      '$documents/${stored.substring(index + _documentsMarker.length)}',
    );
    if (rebased.existsSync()) {
      _legacyCache[stored] = rebased;
      return rebased;
    }
    return direct;
  }
}
