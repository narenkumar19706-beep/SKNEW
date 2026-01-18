import 'package:sqflite/sqflite.dart';

class LocationQueueItem {
  final int? id;
  final String? sosId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime capturedAt;

  LocationQueueItem({
    this.id,
    required this.sosId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.capturedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sos_id': sosId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'captured_at': capturedAt.toIso8601String(),
    };
  }

  factory LocationQueueItem.fromMap(Map<String, dynamic> map) {
    return LocationQueueItem(
      id: map['id'] as int?,
      sosId: map['sos_id'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: map['accuracy'] != null ? (map['accuracy'] as num).toDouble() : null,
      capturedAt: DateTime.parse(map['captured_at'] as String),
    );
  }
}

class LocationQueueService {
  static const _dbName = 'rrt_offline_queue.db';
  static const _tableName = 'location_queue';

  Database? _database;

  Future<Database> _getDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final path = '${await getDatabasesPath()}/$_dbName';
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sos_id TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL,
            captured_at TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<int> enqueue(LocationQueueItem item) async {
    final db = await _getDatabase();
    return db.insert(_tableName, item.toMap());
  }

  Future<List<LocationQueueItem>> fetchBatch({int limit = 50}) async {
    final db = await _getDatabase();
    final rows = await db.query(
      _tableName,
      orderBy: 'captured_at ASC',
      limit: limit,
    );
    return rows.map(LocationQueueItem.fromMap).toList();
  }

  Future<void> deleteBatch(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final db = await _getDatabase();
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      _tableName,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }
}
