import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'todo.dart';

/// Local SQLite database for storing Todo items.
class TodoDb {
  TodoDb._();
  static final TodoDb instance = TodoDb._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'todo_flutter_frontend.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  FutureOr<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subtitle TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // PUBLIC_INTERFACE
  /// Fetch all todos ordered by created_at DESC (latest first).
  Future<List<Todo>> fetchAll() async {
    final db = await database;
    final rows = await db.query(
      'todos',
      orderBy: 'created_at DESC',
    );
    return rows.map((e) => Todo.fromMap(e)).toList();
  }

  // PUBLIC_INTERFACE
  /// Fetch todos where completed=1 ordered by updated_at DESC.
  Future<List<Todo>> fetchCompleted() async {
    final db = await database;
    final rows = await db.query(
      'todos',
      where: 'completed = ?',
      whereArgs: const [1],
      orderBy: 'updated_at DESC',
    );
    return rows.map((e) => Todo.fromMap(e)).toList();
  }

  // PUBLIC_INTERFACE
  /// Insert a new Todo and return the inserted Todo with id.
  Future<Todo> insert(Todo todo) async {
    final db = await database;
    final now = DateTime.now();
    final toInsert = todo.copyWith(createdAt: now, updatedAt: now);
    final id = await db.insert('todos', toInsert.toMap());
    return toInsert.copyWith(id: id);
  }

  // PUBLIC_INTERFACE
  /// Update an existing Todo and return the updated Todo.
  Future<Todo> update(Todo todo) async {
    if (todo.id == null) throw ArgumentError('Cannot update a Todo without an id');
    final db = await database;
    final updated = todo.copyWith(updatedAt: DateTime.now());
    await db.update(
      'todos',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return updated;
  }

  // PUBLIC_INTERFACE
  /// Delete a Todo by id.
  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // PUBLIC_INTERFACE
  /// Toggle the completed flag for the given Todo and persist the change.
  Future<Todo> toggleComplete(Todo todo) async {
    final toggled = todo.copyWith(completed: !todo.completed, updatedAt: DateTime.now());
    return update(toggled);
  }

  // PUBLIC_INTERFACE
  /// Delete all todos (primarily for debugging or reset flows).
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('todos');
  }

  // PUBLIC_INTERFACE
  /// Close the underlying database instance.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
