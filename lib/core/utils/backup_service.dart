import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:itemize/core/utils/image_storage.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:itemize/data/models/service_record.dart';

/// Thrown when an archive is not one of ours, or is one we cannot read.
class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);

  @override
  String toString() => message;
}

/// What a restore did, so the user can be told rather than left guessing.
@immutable
class BackupImportResult {
  final int added;
  final int updated;
  final int photosRestored;
  final int schedulesRestored;
  final int recordsRestored;
  final DateTime? exportedAt;
  final int keptNewer;

  const BackupImportResult({
    required this.added,
    required this.updated,
    required this.photosRestored,
    this.schedulesRestored = 0,
    this.recordsRestored = 0,
    this.exportedAt,
    this.keptNewer = 0,
  });

  int get total => added + updated;
}

/// Exports and restores the whole inventory as one file the owner keeps.
///
/// Deliberately a file and not a server. The app has no backend, which is what
/// lets it be sold once instead of rented, and a home inventory is exactly the
/// kind of data people are least happy to see leave their device. The archive
/// goes wherever they send it — Files, iCloud, a Drive folder, a memory stick.
///
/// The archive is *not* encrypted. That is a real limitation and worth stating:
/// anyone holding the file can read the list and see the photographs. It was
/// left out because a password nobody can recover turns a backup into a way of
/// losing everything at the moment it is needed, and because the file inherits
/// whatever protection the place the owner puts it already has.
class BackupService {
  /// The extension the exported file carries.
  static const String fileExtension = 'itemize';

  /// Bumped if the layout inside the archive ever changes incompatibly.
  ///
  /// v2 added maintenance schedules and service history. A v1 archive restores
  /// fine — it simply has none — so the two are read by the same code.
  ///
  /// Not bumped for the fix that normalises every archived photo path to
  /// `images/<basename>`: that is the shape every archive has always used for
  /// photos saved through [ImageStorage], so an older app reading a freshly
  /// exported archive sees nothing new. Only the manifest strings for rows
  /// that still carried a pre-migration absolute path change, and those rows
  /// were unreadable on import before this fix anyway.
  static const int formatVersion = 2;

  static const String _manifestName = 'inventory.json';
  static const String _formatTag = 'itemize-backup';

  /// Writes every item and photo into a single archive, returning the file.
  ///
  /// The caller is expected to hand this straight to a share sheet: the file
  /// lands in a temporary directory the system is free to clear, and is not a
  /// backup until the owner has put it somewhere.
  Future<File> export(
    List<Asset> assets, {
    List<MaintenanceSchedule> schedules = const [],
    List<ServiceRecord> serviceRecords = const [],
  }) async {
    // Resolved here rather than in the isolate: ImageStorage keeps the
    // documents directory in static state that a spawned isolate would not
    // inherit.
    //
    // Keyed by archive entry name rather than by the stored path: rows from
    // before the multi-photo migration hold an absolute path baked against a
    // sandbox container that no longer exists on restore, and `_readArchive`
    // only ever unpacks entries under `images/`. Writing every photo under
    // `images/<basename>` — the same shape new photos already use — means a
    // legacy row's picture is actually there to unpack instead of being
    // zipped in under a name nothing will ever read back out.
    final photos = <String, String>{};
    final archiveNameByStoredPath = <String, String>{};
    final usedArchiveNames = <String>{};

    void include(String? stored) {
      if (stored == null || stored.isEmpty || archiveNameByStoredPath.containsKey(stored)) {
        return;
      }
      final file = ImageStorage.resolve(stored);
      if (file == null || !file.existsSync()) return;

      final basename = stored.split('/').last;
      final entryName = 'images/${_uniqueArchiveName(basename, usedArchiveNames)}';
      archiveNameByStoredPath[stored] = entryName;
      photos[entryName] = file.path;
    }

    for (final asset in assets) {
      asset.photoPaths.forEach(include);
      include(asset.receiptPath);
    }

    // A fresh copy per asset, never the caller's own list/object: the manifest
    // has to point at the relative name each photo was actually archived
    // under, but nothing else in the app should see its in-memory assets grow
    // an `images/` path it never asked to be given.
    String? translate(String? stored) =>
        stored == null ? null : (archiveNameByStoredPath[stored] ?? stored);
    final assetsForManifest = assets
        .map(
          (a) => a.copyWith(
            photoPaths: a.photoPaths.map((p) => archiveNameByStoredPath[p] ?? p).toList(),
            receiptPath: translate(a.receiptPath),
          ),
        )
        .toList();

    final manifest = jsonEncode({
      'format': _formatTag,
      'version': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'itemCount': assets.length,
      'assets': assetsForManifest.map((a) => a.toMap()).toList(),
      // Years of servicing history is the part that cannot be reconstructed
      // from memory, so a backup that left it behind would be the wrong half.
      'schedules': schedules.map((s) => s.toMap()).toList(),
      'serviceRecords': serviceRecords.map((r) => r.toMap()).toList(),
    });

    final directory = await Directory.systemTemp.createTemp('itemize_backup');
    final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final target = '${directory.path}/itemize-backup-$stamp.$fileExtension';

    await compute(_writeArchive, {
      'target': target,
      'manifest': manifest,
      'photos': photos,
    });

    return File(target);
  }

  /// Reads an archive back in, returning what it contained.
  ///
  /// Items are matched on id and overwritten; anything not in the archive is
  /// left alone. Restoring is therefore a merge, never a wipe — someone
  /// restoring an old backup onto a phone they have kept using does not lose
  /// what they added in between. That includes edits made after the backup
  /// was taken: a row is only overwritten when the archive's copy is not
  /// older than the local one, so a six-month-old backup cannot silently
  /// revert everything changed since. Rows kept for this reason are counted
  /// in [BackupImportResult.keptNewer].
  Future<BackupImportResult> import(
    String archivePath, {
    required Future<Asset?> Function(String id) findExisting,
    required Future<void> Function(Asset asset) addAsset,
    required Future<void> Function(Asset asset) updateAsset,
    Future<void> Function(MaintenanceSchedule schedule)? saveSchedule,
    Future<void> Function(ServiceRecord record)? saveServiceRecord,
  }) async {
    final imagesDirectory = await ImageStorage.imagesDirectory();

    final extracted = await compute(_readArchive, {
      'archive': archivePath,
      'imagesDirectory': imagesDirectory,
    });

    final manifestText = extracted['manifest'] as String?;
    if (manifestText == null) {
      throw const BackupFormatException(
        'This file is not an Itemize backup: it has no inventory in it.',
      );
    }

    final Map<String, dynamic> manifest;
    try {
      manifest = jsonDecode(manifestText) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupFormatException(
        'This backup is damaged and cannot be read.',
      );
    }

    if (manifest['format'] != _formatTag) {
      throw const BackupFormatException('This file is not an Itemize backup.');
    }

    final version = manifest['version'];
    if (version is! int || version > formatVersion) {
      throw const BackupFormatException(
        'This backup was made by a newer version of Itemize. Update the app, '
        'then try again.',
      );
    }

    final rows = manifest['assets'];
    if (rows is! List) {
      throw const BackupFormatException(
        'This backup is damaged and cannot be read.',
      );
    }

    var added = 0;
    var updated = 0;
    var keptNewer = 0;
    for (final row in rows) {
      if (row is! Map) continue;
      final Asset asset;
      try {
        asset = Asset.fromMap(Map<String, dynamic>.from(row));
      } catch (e) {
        // One unreadable row should not cost the owner the other four hundred.
        if (kDebugMode) print('Skipping unreadable backup row: $e');
        continue;
      }

      final existing = await findExisting(asset.id);
      if (existing == null) {
        await addAsset(asset);
        added++;
      } else if (_localIsNewer(existing.lastReviewedAt, asset.lastReviewedAt)) {
        keptNewer++;
      } else {
        await updateAsset(asset);
        updated++;
      }
    }

    // Restored after the items, so a schedule never lands before the thing it
    // belongs to. Absent from a v1 archive, which is not an error.
    final schedulesRestored = await _restoreChildren<MaintenanceSchedule>(
      manifest['schedules'],
      MaintenanceSchedule.fromMap,
      saveSchedule,
    );
    final recordsRestored = await _restoreChildren<ServiceRecord>(
      manifest['serviceRecords'],
      ServiceRecord.fromMap,
      saveServiceRecord,
    );

    final exportedAt = DateTime.tryParse('${manifest['exportedAt']}');

    return BackupImportResult(
      added: added,
      updated: updated,
      photosRestored: extracted['photoCount'] as int? ?? 0,
      schedulesRestored: schedulesRestored,
      recordsRestored: recordsRestored,
      exportedAt: exportedAt,
      keptNewer: keptNewer,
    );
  }

  /// Whether the row already on the device should win over the archive's.
  ///
  /// A null local date means the item has never been reviewed since being
  /// added, which is not a signal worth protecting — the backup overwrites
  /// it. A null archive date, on the other hand, must never beat a real local
  /// one: it means the archive is old enough to predate review tracking, and
  /// treating "unknown" as "newer" would let every such backup wipe out
  /// edits made since. A tie goes to the archive, so a restore still does
  /// something when both sides were reviewed at the same moment (typically:
  /// neither ever was).
  bool _localIsNewer(DateTime? local, DateTime? archived) {
    if (local == null) return false;
    if (archived == null) return true;
    return local.isAfter(archived);
  }

  /// Restores one of the child collections, skipping anything unreadable.
  Future<int> _restoreChildren<T>(
    Object? rows,
    T Function(Map<String, dynamic>) parse,
    Future<void> Function(T)? save,
  ) async {
    if (rows is! List || save == null) return 0;

    var restored = 0;
    for (final row in rows) {
      if (row is! Map) continue;
      try {
        await save(parse(Map<String, dynamic>.from(row)));
        restored++;
      } catch (e) {
        if (kDebugMode) print('Skipping unreadable backup row: $e');
      }
    }
    return restored;
  }
}

/// Picks an archive name for [basename], appending `-2`, `-3`, ... the first
/// time it collides with one already handed out.
///
/// Legacy rows carried an absolute path rooted in whichever directory the
/// photo happened to be picked from, so two different assets can perfectly
/// well share a basename (camera-roll exports love `IMG_0001.jpg`). Writing
/// both under the same archive entry would let the second silently overwrite
/// the first inside the zip.
String _uniqueArchiveName(String basename, Set<String> used) {
  if (used.add(basename)) return basename;

  final dot = basename.lastIndexOf('.');
  final stem = dot > 0 ? basename.substring(0, dot) : basename;
  final extension = dot > 0 ? basename.substring(dot) : '';

  var suffix = 2;
  var candidate = '$stem-$suffix$extension';
  while (!used.add(candidate)) {
    suffix++;
    candidate = '$stem-$suffix$extension';
  }
  return candidate;
}

/// Runs in a background isolate: zips the manifest and every photo.
void _writeArchive(Map<String, Object> args) {
  final target = args['target'] as String;
  final manifest = args['manifest'] as String;
  final photos = (args['photos'] as Map).cast<String, String>();

  final archive = Archive();
  final manifestBytes = utf8.encode(manifest);
  archive.addFile(
    ArchiveFile(
      BackupService._manifestName,
      manifestBytes.length,
      manifestBytes,
    ),
  );

  photos.forEach((entryName, absolute) {
    try {
      final bytes = File(absolute).readAsBytesSync();
      // The key is already the `images/<basename>` name the manifest was
      // rewritten to point at, so a restore can put each file back where its
      // item now expects to find it, legacy absolute paths included.
      archive.addFile(ArchiveFile(entryName, bytes.length, bytes));
    } catch (_) {
      // A photo that has gone missing is not a reason to refuse the backup.
    }
  });

  final encoded = ZipEncoder().encode(archive);
  File(target).writeAsBytesSync(encoded);
}

/// Runs in a background isolate: unzips photos to disk, returns the manifest.
///
/// Images are written out here rather than handed back as bytes so a large
/// library is never held in memory twice.
Map<String, Object?> _readArchive(Map<String, Object> args) {
  final archivePath = args['archive'] as String;
  final imagesDirectory = args['imagesDirectory'] as String;

  final archive = ZipDecoder().decodeBytes(
    File(archivePath).readAsBytesSync(),
  );

  String? manifest;
  var photoCount = 0;

  for (final entry in archive) {
    if (!entry.isFile) continue;

    if (entry.name == BackupService._manifestName) {
      manifest = utf8.decode(entry.content as List<int>, allowMalformed: true);
      continue;
    }

    // Only the images folder is unpacked, and only by base name. An archive
    // naming a file `../../somewhere` would otherwise write outside the app.
    if (!entry.name.startsWith('images/')) continue;
    final name = entry.name.split('/').last;
    if (name.isEmpty || name.contains('..')) continue;

    final out = File('$imagesDirectory/$name');
    // Names are UUIDs, so a file already there is the same file. Skipping it
    // keeps a restore from rewriting the whole photo library every time.
    if (!out.existsSync()) {
      out.writeAsBytesSync(entry.content as List<int>);
    }
    photoCount++;
  }

  return {'manifest': manifest, 'photoCount': photoCount};
}
