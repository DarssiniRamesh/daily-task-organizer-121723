import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/todo.dart';
import '../providers/todo_provider.dart';

const _figmaPrimary = Color(0xFF9395D3); // app bar + accent
const _figmaBg = Color(0xFFD6D7EF); // background
const _figmaWhite = Color(0xFFFFFFFF);
const _titleColor = _figmaPrimary; // todo title
const _subtitleColor = Color(0xFF000000);
const _labelCompleted = Color(0xFF8B8787);

/// PUBLIC_INTERFACE
/// Main TODO screen: header, list, FAB, and bottom filter bar.
class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  @override
  void initState() {
    super.initState();
    // Load todos when screen initializes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TodoProvider>().loadTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final todos = provider.todos;

    return Scaffold(
      backgroundColor: _figmaBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: _TodoList(
                todos: todos,
                isLoading: provider.isLoading,
                onEdit: (todo) => _showTodoEditor(context, existing: todo),
                onDelete: (todo) => context.read<TodoProvider>().deleteTodo(todo),
                onToggle: (todo) => context.read<TodoProvider>().toggleComplete(todo),
              ),
            ),
            const SizedBox(height: 68), // Leave space for custom bottom nav (positioned absolute-like)
          ],
        ),
      ),
      floatingActionButton: _Fab(onPressed: () => _showTodoEditor(context)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _BottomFilterBar(
        filter: provider.filter,
        onFilterChanged: (f) => context.read<TodoProvider>().setFilter(f),
      ),
    );
  }

  Future<void> _showTodoEditor(BuildContext context, {Todo? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final subtitleController = TextEditingController(text: existing?.subtitle ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  existing == null ? 'Add ToDo' : 'Edit ToDo',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _figmaPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          if (existing == null) {
                            await context.read<TodoProvider>().addTodo(
                                  titleController.text,
                                  subtitle: subtitleController.text,
                                );
                          } else {
                            await context.read<TodoProvider>().editTodo(
                                  existing,
                                  title: titleController.text,
                                  subtitle: subtitleController.text,
                                );
                          }
                          if (ctx.mounted) Navigator.of(ctx).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _figmaPrimary,
                          foregroundColor: _figmaWhite,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // Optional snack feedback
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Todo added' : 'Todo updated'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Custom header block (118px height) to match Figma rather than a Material AppBar.
    return Container(
      height: 118,
      width: double.infinity,
      color: _figmaPrimary,
      padding: const EdgeInsets.only(left: 19, right: 19, bottom: 28),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              'TODO APP',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _figmaWhite,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Positioned(
            right: 0,
            top: 16,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.calendar_today),
              color: _figmaWhite,
              tooltip: 'Calendar',
            ),
          ),
        ],
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final VoidCallback onPressed;
  const _Fab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: 'Add New ToDo',
      backgroundColor: _figmaPrimary,
      foregroundColor: _figmaWhite,
      shape: const CircleBorder(),
      child: const Icon(Icons.add),
    );
  }
}

class _BottomFilterBar extends StatelessWidget {
  final TodoFilter filter;
  final ValueChanged<TodoFilter> onFilterChanged;

  const _BottomFilterBar({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isAll = filter == TodoFilter.all;
    final isCompleted = filter == TodoFilter.completed;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 60),
      decoration: const BoxDecoration(
        color: _figmaWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _FilterButton(
            icon: Icons.playlist_add,
            label: 'All',
            active: isAll,
            onTap: () => onFilterChanged(TodoFilter.all),
          ),
          _FilterButton(
            icon: Icons.task_alt,
            label: 'Completed',
            active: isCompleted,
            inactiveColor: _labelCompleted,
            onTap: () => onFilterChanged(TodoFilter.completed),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? inactiveColor;

  const _FilterButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _figmaPrimary : (inactiveColor ?? _figmaPrimary);
    final labelColor = active ? _figmaPrimary : (inactiveColor ?? _figmaPrimary);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: labelColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoList extends StatelessWidget {
  final List<Todo> todos;
  final bool isLoading;
  final ValueChanged<Todo> onEdit;
  final ValueChanged<Todo> onDelete;
  final ValueChanged<Todo> onToggle;

  const _TodoList({
    required this.todos,
    required this.isLoading,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (todos.isEmpty) {
      return Center(
        child: Text(
          'No todos yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(7.5, 20, 7.5, 20),
      itemCount: todos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 21),
      itemBuilder: (ctx, i) {
        final t = todos[i];
        return Dismissible(
          key: ValueKey('todo_${t.id ?? t.title}_$i'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => onDelete(t),
          child: _TodoCard(
            todo: t,
            onEdit: () => onEdit(t),
            onDelete: () => onDelete(t),
            onToggle: () => onToggle(t),
          ),
        );
      },
    );
  }
}

class _TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _TodoCard({
    required this.todo,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: _titleColor,
          fontSize: 13,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _subtitleColor,
          fontSize: 10,
        );

    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: _figmaWhite,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.only(left: 20, right: 82, top: 16, bottom: 16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Titles(
                title: todo.title,
                subtitle: todo.subtitle ?? '',
                titleStyle: todo.completed
                    ? titleStyle?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: _titleColor.withValues(alpha: 0.8),
                      )
                    : titleStyle,
                subtitleStyle: subtitleStyle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: Icon(Icons.edit, color: Colors.indigo.shade200, size: 22),
                ),
                const SizedBox(width: 20),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: Colors.indigo.shade200, size: 22),
                ),
                const SizedBox(width: 20),
                IconButton(
                  tooltip: todo.completed ? 'Mark Incomplete' : 'Mark Complete',
                  onPressed: onToggle,
                  icon: Icon(
                    todo.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: todo.completed ? Colors.green : Colors.indigo.shade200,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Titles extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const _Titles({
    required this.title,
    required this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Text(subtitle, style: subtitleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
