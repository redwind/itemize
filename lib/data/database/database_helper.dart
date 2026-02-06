import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:itemize/data/models/asset.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('itemize.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
CREATE TABLE assets ( 
  id $idType, 
  name $textType,
  price $doubleType,
  currency $textType,
  category $textType,
  imagePath $textType,
  barcode $textNullable,
  purchaseDate $textType,
  warrantyExpiry $textNullable,
  isFavorite $boolType
  )
''');
  }

  Future<int> create(Asset asset) async {
    final db = await instance.database;
    return await db.insert('assets', asset.toMap());
  }

  Future<Asset> readAsset(String id) async {
    final db = await instance.database;

    final maps = await db.query(
      'assets',
      columns: null, // Select all
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Asset.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Asset>> readAllAssets() async {
    final db = await instance.database;
    final result = await db.query('assets');
    return result.map((json) => Asset.fromMap(json)).toList();
  }

  Future<int> update(Asset asset) async {
    final db = await instance.database;
    return db.update(
      'assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await instance.database;
    return await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
