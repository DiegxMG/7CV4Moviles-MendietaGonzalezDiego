import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'practica5_offline.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY,
            name TEXT,
            description TEXT,
            sync_status INTEGER DEFAULT 1
          )
        ''');
      },
    );
  }

  static Future<void> insertItemLocal(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('items', item, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List>> getItemsLocal() async {
    final db = await database;
    return await db.query('items');
  }
}