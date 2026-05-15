import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/token.dart';

class QueueDb {
  QueueDb._();
  static final QueueDb instance = QueueDb._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'smartqueue.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            token_number INTEGER NOT NULL,
            issued_at TEXT NOT NULL,
            status TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<int> takeToken() async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT MAX(token_number) AS m FROM tokens',
    );
    final next = ((rows.first['m'] as int?) ?? 0) + 1;
    return db.insert('tokens', {
      'token_number': next,
      'issued_at': DateTime.now().toIso8601String(),
      'status': 'waiting',
    });
  }

  Future<List<QueueToken>> activeTokens() async {
    final db = await _database;
    final rows = await db.query(
      'tokens',
      where: 'status != ?',
      whereArgs: ['done'],
      orderBy: 'token_number ASC',
    );
    return rows.map(QueueToken.fromMap).toList();
  }

  Future<QueueToken?> getToken(int id) async {
    final db = await _database;
    final rows = await db.query(
      'tokens',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return QueueToken.fromMap(rows.first);
  }

  /// Marks the currently-serving token as done and promotes the next
  /// waiting token to "serving". Safe to call when nothing is serving.
  Future<void> callNext() async {
    final db = await _database;
    await db.update(
      'tokens',
      {'status': 'done'},
      where: 'status = ?',
      whereArgs: ['serving'],
    );
    final next = await db.query(
      'tokens',
      where: 'status = ?',
      whereArgs: ['waiting'],
      orderBy: 'token_number ASC',
      limit: 1,
    );
    if (next.isNotEmpty) {
      await db.update(
        'tokens',
        {'status': 'serving'},
        where: 'id = ?',
        whereArgs: [next.first['id']],
      );
    }
  }

  /// 0 = currently being served, N>0 = N tokens ahead, -1 = done/not found.
  Future<int> positionOf(int tokenId) async {
    final db = await _database;
    final me = await db.query(
      'tokens',
      where: 'id = ?',
      whereArgs: [tokenId],
      limit: 1,
    );
    if (me.isEmpty) return -1;
    final status = me.first['status'] as String;
    if (status == 'done') return -1;
    if (status == 'serving') return 0;

    final myNumber = me.first['token_number'] as int;
    final ahead = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM tokens '
      'WHERE status != ? AND token_number < ?',
      ['done', myNumber],
    );
    return (ahead.first['c'] as int?) ?? 0;
  }

  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('tokens');
  }
}
