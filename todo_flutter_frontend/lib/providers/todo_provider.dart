import 'package:flutter/foundation.dart';

import '../data/todo.dart';
import '../data/todo_db.dart';

/// Available filter modes for the Todos list.
enum TodoFilter { all, completed }

/// PUBLIC_INTERFACE
/// Holds Todos state, interacts with SQLite, and exposes CRUD plus filtering APIs.
class TodoProvider extends ChangeNotifier {
  final TodoDb _db;

  TodoProvider({TodoDb? db}) : _db = db ?? TodoDb.instance;

  final List<Todo> _items = [];
  TodoFilter _filter = TodoFilter.all;
  bool _loading = false;

  /// PUBLIC_INTERFACE
  /// Whether the provider is currently performing a database operation.
  bool get isLoading => _loading;

  /// PUBLIC_INTERFACE
  /// Current active filter (all or completed).
  TodoFilter get filter => _filter;

  /// PUBLIC_INTERFACE
  /// Todos after applying the current filter.
  List<Todo> get todos {
    if (_filter == TodoFilter.completed) {
      return _items.where((t) => t.completed).toList(growable: false);
    }
    return List.unmodifiable(_items);
  }

  /// PUBLIC_INTERFACE
  /// Load all Todos from the database.
  Future<void> loadTodos() async {
    _loading = true;
    notifyListeners();
    try {
      final all = await _db.fetchAll();
      _items
        ..clear()
        ..addAll(all);
    } catch (e) {
      // In test environments, sqflite may not be available; keep list empty.
      debugPrint('loadTodos error: $e');
      _items.clear();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// PUBLIC_INTERFACE
  /// Set the current filter and notify listeners.
  void setFilter(TodoFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  /// PUBLIC_INTERFACE
  /// Create and persist a new Todo item.
  Future<void> addTodo(String title, {String? subtitle}) async {
    if (title.trim().isEmpty) return;
    try {
      final created = await _db.insert(Todo(title: title.trim(), subtitle: subtitle?.trim()));
      _items.insert(0, created);
    } catch (e) {
      debugPrint('addTodo error: $e');
    }
    notifyListeners();
  }

  /// PUBLIC_INTERFACE
  /// Edit an existing Todo's title/subtitle and persist changes.
  Future<void> editTodo(Todo todo, {required String title, String? subtitle}) async {
    if (todo.id == null) return;
    try {
      final updated = await _db.update(todo.copyWith(title: title.trim(), subtitle: subtitle?.trim()));
      final idx = _items.indexWhere((t) => t.id == todo.id);
      if (idx != -1) {
        _items[idx] = updated;
      }
    } catch (e) {
      debugPrint('editTodo error: $e');
    }
    notifyListeners();
  }

  /// PUBLIC_INTERFACE
  /// Delete the specified Todo.
  Future<void> deleteTodo(Todo todo) async {
    if (todo.id == null) return;
    try {
      await _db.delete(todo.id!);
      _items.removeWhere((t) => t.id == todo.id);
    } catch (e) {
      debugPrint('deleteTodo error: $e');
    }
    notifyListeners();
  }

  /// PUBLIC_INTERFACE
  /// Toggle the completion state of the specified Todo.
  Future<void> toggleComplete(Todo todo) async {
    if (todo.id == null) return;
    try {
      final updated = await _db.toggleComplete(todo);
      final idx = _items.indexWhere((t) => t.id == todo.id);
      if (idx != -1) {
        _items[idx] = updated;
      }
    } catch (e) {
      debugPrint('toggleComplete error: $e');
    }
    notifyListeners();
  }
}
