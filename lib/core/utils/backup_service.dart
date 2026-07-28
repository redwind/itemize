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

  const BackupImportResult({
    required this.added,
    required this.updated,
    required this.photosRestored,
    this.schedulesRestored = 0,
    this.recordsRestored = 0,
    this.exportedAt,
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
    final manifest = jsonEncode({
      'format': _formatTag,
      'version': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'itemCount': assets.length,
      'assets': assets.map((a) => a.toMap()).toList(),
      // Years of servicing history is the part that cannot be reconstructed
      // from memory, so a backup that left it behind would be the wrong half.
      'schedules': schedules.map((s) => s.toMap()).toList(),
      'serviceRecords': serviceRecords.map((r) => r.toMap()).toList(),
    });

    // Resolved here rather than in the isolate: ImageStorage keeps the
    // documents directory in static state that a spawned isolate would not
    // inherit.
    final photos = <String, String>{};
    void include(String? stored) {
      if (stored == null || stored.isEmpty || photos.containsKey(stored)) return;
      final file = ImageStorage.resolve(stored);
      if (file != null && file.existsSync()) photos[stored] = file.path;
    }

    for (final asset in assets) {
      asset.photoPaths.forEach(include);
      include(asset.receiptPath);
    }

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
  /// what they added in between.
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

      if (await findExisting(asset.id) != null) {
        await updateAsset(asset);
        updated++;
      } else {
        await addAsset(asset);
        added++;
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
    );
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

  photos.forEach((stored, absolute) {
    try {
      final bytes = File(absolute).readAsBytesSync();
      // Stored under the very path the items refer to, so a restore can put
      // each file back where its item expects to find it.
      archive.addFile(ArchiveFile(stored, bytes.length, bytes));
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
