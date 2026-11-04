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
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY, name TEXT, description TEXT, sync_status INTEGER DEFAULT 1
          )
        ''');
          await db.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT, query TEXT, timestamp TEXT
          )
        ''');
          await db.execute('''
          CREATE TABLE favorites(
            id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT, item_id TEXT, title TEXT, data TEXT
          )
        ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('CREATE TABLE history(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT, query TEXT, timestamp TEXT)');
            await db.execute('CREATE TABLE favorites(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT, item_id TEXT, title TEXT, data TEXT)');
          }
        }
    );
  }

  static Future<void> insertHistory(String userId, String query) async {
    final db = await database;
    await db.insert('history', {'user_id': userId, 'query': query, 'timestamp': DateTime.now().toIso8601String()});
  }

  static Future<List>> getHistory(String userId) async {
    final db = await database;
    return await db.query('history', where: 'user_id = ?', whereArgs: [userId], orderBy: 'timestamp DESC');
  }

  static Future<void> toggleFavorite(String userId, String itemId, String title, String data) async {
    final db = await database;
    final exists = await db.query('favorites', where: 'user_id = ? AND item_id = ?', whereArgs: [userId, itemId]);
    if (exists.isEmpty) {
      await db.insert('favorites', {'user_id': userId, 'item_id': itemId, 'title': title, 'data': data});
    } else {
      await db.delete('favorites', where: 'user_id = ? AND item_id = ?', whereArgs: [userId, itemId]);
    }
  }

  static Future<List>> getFavorites(String userId) async {
    final db = await database;
    return await db.query('favorites', where: 'user_id = ?', whereArgs: [userId]);
  }
}