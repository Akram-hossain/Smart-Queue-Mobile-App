import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import 'auth_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
    (ref) => TaskRepository(ref.watch(supabaseServiceProvider)));

class TasksController extends AsyncNotifier<List<TaskItem>> {
  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  @override
  Future<List<TaskItem>> build() async {
    ref.watch(currentUserProvider);
    return _repo.list();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.list);
  }

  Future<void> create(TaskItem task) async {
    await _repo.create(task);
    await refresh();
  }

  Future<void> update(TaskItem task) async {
    await _repo.update(task);
    await refresh();
  }

  Future<void> toggleComplete(TaskItem task) async {
    final next = task.copyWith(
      status: task.status == TaskStatus.completed
          ? TaskStatus.pending
          : TaskStatus.completed,
    );
    await _repo.update(next);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await refresh();
  }
}

final tasksProvider =
    AsyncNotifierProvider<TasksController, List<TaskItem>>(TasksController.new);

/// Pending tasks ordered by due date — used by dashboard widgets.
final upcomingTasksProvider = Provider<List<TaskItem>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const <TaskItem>[];
  return tasks
      .where((t) => t.status != TaskStatus.completed)
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
});

List<TaskItem> tasksOfTypeUpcoming(List<TaskItem> all, TaskType type) {
  return all
      .where((t) => t.type == type && t.status != TaskStatus.completed)
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
}
