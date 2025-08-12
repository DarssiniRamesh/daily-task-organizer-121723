

/// PUBLIC_INTERFACE
/// Represents a Todo item persisted locally.
class Todo {
  /// Unique identifier for the Todo. Will be null until persisted.
  final int? id;

  /// Title of the Todo (required).
  final String title;

  /// Optional subtitle or description.
  final String? subtitle;

  /// Whether the Todo is marked as completed.
  final bool completed;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  Todo({
    this.id,
    required this.title,
    this.subtitle,
    this.completed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // PUBLIC_INTERFACE
  /// Create a new Todo by copying current fields and overriding specified ones.
  Todo copyWith({
    int? id,
    String? title,
    String? subtitle,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // PUBLIC_INTERFACE
  /// Convert the Todo to a map suitable for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // PUBLIC_INTERFACE
  /// Create a Todo from a SQLite row map.
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String?,
      completed: (map['completed'] ?? 0) == 1,
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
    }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Todo &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            title == other.title &&
            subtitle == other.subtitle &&
            completed == other.completed &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, title, subtitle, completed, createdAt, updatedAt);

  @override
  String toString() => 'Todo(id: $id, title: $title, completed: $completed)';
}
