import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itemize/core/utils/backup_service.dart';
import 'package:itemize/core/utils/image_storage.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:itemize/data/models/service_record.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Stands in for the platform channel, which unit tests do not have.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

/// The smallest thing that is unmistakably a distinct file on disk.
Uint8List fakePhoto(int seed) =>
    Uint8List.fromList(List<int>.generate(64, (i) => (i + seed) % 256));

Asset asset({
  required String id,
  String name = 'Sofa',
  List<String> photoPaths = const [],
  String? receiptPath,
  String? serialNumber,
  String? notes,
  DateTime? warrantyExpiry,
  DateTime? lastReviewedAt,
}) => Asset(
  id: id,
  name: name,
  price: 1234.56,
  currency: 'VND',
  room: 'Living Room',
  category: 'Furniture',
  photoPaths: photoPaths,
  receiptPath: receiptPath,
  serialNumber: serialNumber,
  brand: 'Ikea',
  model: 'KIVIK',
  notes: notes,
  barcode: '8935001234567',
  purchaseDate: DateTime(2024, 3, 1),
  warrantyExpiry: warrantyExpiry,
  isFavorite: true,
  lastReviewedAt: lastReviewedAt,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late BackupService service;
  late Map<String, Asset> store;
  late Map<String, MaintenanceSchedule> scheduleStore;
  late Map<String, ServiceRecord> recordStore;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('itemize_docs');
    PathProviderPlatform.instance = _FakePathProvider(documents.path);
    await ImageStorage.init();
    service = BackupService();
    store = {};
    scheduleStore = {};
    recordStore = {};
  });

  tearDown(() async {
    if (documents.existsSync()) await documents.delete(recursive: true);
  });

  /// Builds an archive around a hand-written manifest.
  String archiveWithManifest(String name, Object? manifest) {
    final archive = Archive();
    final bytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(ArchiveFile('inventory.json', bytes.length, bytes));
    final path = '${documents.path}/$name.itemize';
    File(path).writeAsBytesSync(ZipEncoder().encode(archive));
    return path;
  }

  Future<BackupImportResult> restore(String path) => service.import(
    path,
    findExisting: (id) async => store[id],
    addAsset: (a) async => store[a.id] = a,
    updateAsset: (a) async => store[a.id] = a,
    saveSchedule: (s) async => scheduleStore[s.id] = s,
    saveServiceRecord: (r) async => recordStore[r.id] = r,
  );

  group('round trip', () {
    test('every field survives export and restore', () async {
      final original = asset(
        id: 'a',
        name: 'Tủ lạnh Panasonic',
        serialNumber: 'SN-9',
        notes: 'Kitchen corner',
        warrantyExpiry: DateTime(2027, 3, 1),
      );

      final archive = await service.export([original]);
      final result = await restore(archive.path);

      expect(result.added, 1);
      expect(result.updated, 0);

      final restored = store['a']!;
      expect(restored.name, 'Tủ lạnh Panasonic');
      expect(restored.price, 1234.56);
      expect(restored.currency, 'VND');
      expect(restored.room, 'Living Room');
      expect(restored.category, 'Furniture');
      expect(restored.serialNumber, 'SN-9');
      expect(restored.brand, 'Ikea');
      expect(restored.model, 'KIVIK');
      expect(restored.notes, 'Kitchen corner');
      expect(restored.barcode, '8935001234567');
      expect(restored.purchaseDate, DateTime(2024, 3, 1));
      expect(restored.warrantyExpiry, DateTime(2027, 3, 1));
      expect(restored.isFavorite, isTrue);
    });

    test('photos come back onto disk where the items point', () async {
      final cover = await ImageStorage.saveBytes(fakePhoto(1), extension: 'jpg');
      final second = await ImageStorage.saveBytes(fakePhoto(2), extension: 'jpg');
      final receipt = await ImageStorage.saveBytes(fakePhoto(3), extension: 'jpg');

      final archive = await service.export([
        asset(id: 'a', photoPaths: [cover, second], receiptPath: receipt),
      ]);

      // The device is wiped and the app reinstalled: the archive is all there
      // is left.
      for (final stored in [cover, second, receipt]) {
        ImageStorage.resolve(stored)!.deleteSync();
      }

      final result = await restore(archive.path);

      expect(result.photosRestored, 3);
      expect(ImageStorage.resolve(cover)!.existsSync(), isTrue);
      expect(ImageStorage.resolve(second)!.existsSync(), isTrue);
      expect(ImageStorage.resolve(receipt)!.existsSync(), isTrue);
      expect(ImageStorage.resolve(cover)!.readAsBytesSync(), fakePhoto(1));
      expect(store['a']!.photoPaths, [cover, second]);
    });

    test('photo order is kept, so the cover stays the cover', () async {
      final one = await ImageStorage.saveBytes(fakePhoto(1), extension: 'jpg');
      final two = await ImageStorage.saveBytes(fakePhoto(2), extension: 'jpg');

      final archive = await service.export([
        asset(id: 'a', photoPaths: [two, one]),
      ]);
      await restore(archive.path);

      expect(store['a']!.photoPaths.first, two);
      expect(store['a']!.imagePath, two);
    });

    test('a large-ish inventory round-trips intact', () async {
      final many = [for (var i = 0; i < 120; i++) asset(id: 'id-$i', name: 'Item $i')];

      final archive = await service.export(many);
      final result = await restore(archive.path);

      expect(result.added, 120);
      expect(store.length, 120);
      expect(store['id-77']!.name, 'Item 77');
    });
  });

  group('legacy absolute photo paths', () {
    test('a pre-migration absolute path survives export and restore', () async {
      // Rows written before the multi-photo migration recorded an absolute
      // path baked against the sandbox container of the day, not the
      // `images/<name>` form ImageStorage has used since. Simulate one by
      // writing a photo straight to disk, outside of ImageStorage, and
      // pointing the asset at its absolute path -- exactly what such a row
      // still holds today.
      final legacyDir = await Directory(
        '${documents.path}/legacy_sandbox/images',
      ).create(recursive: true);
      final legacyFile = File('${legacyDir.path}/old-cover.jpg')
        ..writeAsBytesSync(fakePhoto(9));

      final archive = await service.export([
        asset(id: 'legacy', photoPaths: [legacyFile.path]),
      ]);

      // The device is wiped and reinstalled: the old sandbox container, and
      // with it the absolute path the row still remembers, is gone for good.
      await Directory('${documents.path}/legacy_sandbox').delete(recursive: true);

      final result = await restore(archive.path);

      expect(result.photosRestored, 1);
      final restoredPath = store['legacy']!.photoPaths.single;
      final resolved = ImageStorage.resolve(restoredPath);
      expect(
        resolved != null && resolved.existsSync(),
        isTrue,
        reason: 'the photo has to actually be on disk after restore, not '
            'just referenced by a manifest path nothing unpacked',
      );
      expect(resolved!.readAsBytesSync(), fakePhoto(9));
    });

    test('two legacy paths that share a basename do not overwrite each other',
        () async {
      final dirA = await Directory('${documents.path}/legacy_a').create(recursive: true);
      final dirB = await Directory('${documents.path}/legacy_b').create(recursive: true);
      final fileA = File('${dirA.path}/photo.jpg')..writeAsBytesSync(fakePhoto(11));
      final fileB = File('${dirB.path}/photo.jpg')..writeAsBytesSync(fakePhoto(22));

      final archive = await service.export([
        asset(id: 'x', photoPaths: [fileA.path]),
        asset(id: 'y', photoPaths: [fileB.path]),
      ]);

      await dirA.delete(recursive: true);
      await dirB.delete(recursive: true);

      final result = await restore(archive.path);

      expect(result.photosRestored, 2);

      final pathX = store['x']!.photoPaths.single;
      final pathY = store['y']!.photoPaths.single;
      expect(
        pathX,
        isNot(pathY),
        reason: 'two different photos must not end up under the same '
            'archive entry, or restoring one silently loses the other',
      );
      expect(ImageStorage.resolve(pathX)!.readAsBytesSync(), fakePhoto(11));
      expect(ImageStorage.resolve(pathY)!.readAsBytesSync(), fakePhoto(22));
    });
  });

  group('restore is a merge, never a wipe', () {
    test('items not in the backup are left alone', () async {
      store['kept'] = asset(id: 'kept', name: 'Added Later');

      final archive = await service.export([asset(id: 'a')]);
      await restore(archive.path);

      expect(store.containsKey('kept'), isTrue);
      expect(store['kept']!.name, 'Added Later');
    });

    test('an item already present is updated, not duplicated', () async {
      store['a'] = asset(id: 'a', name: 'Stale Name');

      final archive = await service.export([asset(id: 'a', name: 'Real Name')]);
      final result = await restore(archive.path);

      expect(result.added, 0);
      expect(result.updated, 1);
      expect(store.length, 1);
      expect(store['a']!.name, 'Real Name');
    });

    test('restoring the same backup twice changes nothing the second time',
        () async {
      final archive = await service.export([asset(id: 'a')]);

      final first = await restore(archive.path);
      final second = await restore(archive.path);

      expect(first.added, 1);
      expect(second.added, 0);
      expect(second.updated, 1);
      expect(store.length, 1);
    });

    test('a local edit made after the backup was taken is kept, not reverted',
        () async {
      store['a'] = asset(
        id: 'a',
        name: 'Edited After Backup',
        lastReviewedAt: DateTime(2026, 6, 1),
      );

      final archive = await service.export([
        asset(id: 'a', name: 'Stale From Backup', lastReviewedAt: DateTime(2026, 1, 1)),
      ]);
      final result = await restore(archive.path);

      expect(result.keptNewer, 1);
      expect(result.updated, 0);
      expect(store['a']!.name, 'Edited After Backup');
    });

    test('a local row untouched since the backup is still updated', () async {
      store['a'] = asset(id: 'a', name: 'Old Local', lastReviewedAt: DateTime(2026, 1, 1));

      final archive = await service.export([
        asset(id: 'a', name: 'Fresh From Backup', lastReviewedAt: DateTime(2026, 6, 1)),
      ]);
      final result = await restore(archive.path);

      expect(result.keptNewer, 0);
      expect(result.updated, 1);
      expect(store['a']!.name, 'Fresh From Backup');
    });

    test('a backup row with no review date cannot outrank a reviewed local one',
        () async {
      store['a'] = asset(
        id: 'a',
        name: 'Reviewed Locally',
        lastReviewedAt: DateTime(2026, 6, 1),
      );

      final archive = await service.export([
        asset(id: 'a', name: 'From Backup, Never Reviewed'),
      ]);
      final result = await restore(archive.path);

      expect(result.keptNewer, 1);
      expect(store['a']!.name, 'Reviewed Locally');
    });

    test('a local row that was never reviewed is not protected from the backup',
        () async {
      store['a'] = asset(id: 'a', name: 'Never Reviewed Locally');

      final archive = await service.export([
        asset(id: 'a', name: 'From Backup', lastReviewedAt: DateTime(2026, 6, 1)),
      ]);
      final result = await restore(archive.path);

      expect(result.keptNewer, 0);
      expect(result.updated, 1);
      expect(store['a']!.name, 'From Backup');
    });
  });

  group('bad input is refused, with something a person can act on', () {
    test('a file that is not an archive at all', () async {
      final junk = File('${documents.path}/notes.txt')
        ..writeAsStringSync('this is not a backup');

      expect(
        () => restore(junk.path),
        throwsA(isA<Exception>()),
      );
    });

    test('an archive with no manifest in it', () async {
      // A zip of something else entirely: photos, say.
      final other = await service.export([asset(id: 'a')]);
      final bytes = other.readAsBytesSync();
      // Corrupt the manifest name by truncating the archive.
      final broken = File('${documents.path}/broken.itemize')
        ..writeAsBytesSync(bytes.sublist(0, bytes.length ~/ 3));

      expect(() => restore(broken.path), throwsA(isA<Exception>()));
    });

    /// Builds an archive around a hand-written manifest.
    String archiveWithManifestLocal(String name, Object? manifest) {
      final archive = Archive();
      final bytes = utf8.encode(jsonEncode(manifest));
      archive.addFile(ArchiveFile('inventory.json', bytes.length, bytes));
      final path = '${documents.path}/$name.itemize';
      File(path).writeAsBytesSync(ZipEncoder().encode(archive));
      return path;
    }

    test('a backup from a future version is refused, not half-read', () async {
      final path = archiveWithManifestLocal('future', {
        'format': 'itemize-backup',
        'version': BackupService.formatVersion + 1,
        'assets': [asset(id: 'a').toMap()],
      });

      await expectLater(
        restore(path),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.message,
            'message',
            contains('newer version'),
          ),
        ),
      );
      expect(store, isEmpty, reason: 'nothing is written before the check');
    });

    test('a zip that is not ours is named as such', () async {
      final path = archiveWithManifestLocal('other', {
        'format': 'some-other-app',
        'version': 1,
        'assets': [],
      });

      await expectLater(
        restore(path),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.message,
            'message',
            contains('not an Itemize backup'),
          ),
        ),
      );
    });

    test('one unreadable row does not cost the owner the others', () async {
      final path = archiveWithManifestLocal('partial', {
        'format': 'itemize-backup',
        'version': 1,
        'assets': [
          asset(id: 'good-1').toMap(),
          {'id': 'broken', 'name': 'Missing everything else'},
          asset(id: 'good-2').toMap(),
        ],
      });

      final result = await restore(path);

      expect(result.added, 2);
      expect(store.keys, containsAll(['good-1', 'good-2']));
      expect(store.containsKey('broken'), isFalse);
    });
  });

  test('exporting an empty inventory produces a readable, empty backup',
      () async {
    final archive = await service.export([]);
    final result = await restore(archive.path);

    expect(result.added, 0);
    expect(result.updated, 0);
    expect(store, isEmpty);
  });

  group('maintenance and history', () {
    final schedule = MaintenanceSchedule(
      id: 'sched-1',
      assetId: 'a',
      title: 'Annual service',
      intervalMonths: 12,
      lastDoneAt: DateTime(2026, 5, 1),
      requiredForWarranty: true,
      notes: 'Gas Safe only',
    );

    final record = ServiceRecord(
      id: 'rec-1',
      assetId: 'a',
      date: DateTime(2026, 5, 1),
      kind: ServiceKind.maintenance,
      description: 'Annual service',
      cost: 145.50,
      provider: 'Gas Safe Ltd',
      scheduleId: 'sched-1',
    );

    test('years of history survive the round trip', () async {
      final archive = await service.export(
        [asset(id: 'a')],
        schedules: [schedule],
        serviceRecords: [record],
      );
      final result = await restore(archive.path);

      expect(result.schedulesRestored, 1);
      expect(result.recordsRestored, 1);

      final restoredSchedule = scheduleStore['sched-1']!;
      expect(restoredSchedule.title, 'Annual service');
      expect(restoredSchedule.intervalMonths, 12);
      expect(restoredSchedule.lastDoneAt, DateTime(2026, 5, 1));
      expect(restoredSchedule.requiredForWarranty, isTrue);
      expect(restoredSchedule.notes, 'Gas Safe only');

      final restoredRecord = recordStore['rec-1']!;
      expect(restoredRecord.kind, ServiceKind.maintenance);
      expect(restoredRecord.cost, 145.50);
      expect(restoredRecord.provider, 'Gas Safe Ltd');
      expect(restoredRecord.scheduleId, 'sched-1');
      expect(restoredRecord.date, DateTime(2026, 5, 1));
    });

    test('a backup with no maintenance in it restores cleanly', () async {
      final archive = await service.export([asset(id: 'a')]);
      final result = await restore(archive.path);

      expect(result.added, 1);
      expect(result.schedulesRestored, 0);
      expect(result.recordsRestored, 0);
    });

    test('an older v1 archive still restores its items', () async {
      // No schedules or history keys at all, as v1 wrote it.
      final path = archiveWithManifest('v1', {
        'format': 'itemize-backup',
        'version': 1,
        'assets': [asset(id: 'a').toMap()],
      });

      final result = await restore(path);

      expect(result.added, 1);
      expect(result.schedulesRestored, 0);
      expect(scheduleStore, isEmpty);
    });

    test('one unreadable schedule does not cost the others', () async {
      final path = archiveWithManifest('partial-children', {
        'format': 'itemize-backup',
        'version': 2,
        'assets': [asset(id: 'a').toMap()],
        'schedules': [
          schedule.toMap(),
          {'id': 'broken'},
          schedule.toMap()..['id'] = 'sched-2',
        ],
        'serviceRecords': [],
      });

      final result = await restore(path);

      expect(result.schedulesRestored, 2);
      expect(scheduleStore.keys, containsAll(['sched-1', 'sched-2']));
    });
  });
}
