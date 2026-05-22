import '../models/task.dart';
import '../services/supabase_service.dart';

class TaskRepository {
  TaskRepository(this._supabase);
  final SupabaseService _supabase;

  Future<List<TaskItem>> list() async {
    final uid = _supabase.currentUserId;
    if (uid == null) return const [];
    final rows = await _supabase.client
        .from('tasks')
        .select()
        .eq('user_id', uid)
        .order('due_date', ascending: true);
    return (rows as List)
        .map((r) => TaskItem.fromMap(r as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<TaskItem> create(TaskItem task) async {
    final uid = _supabase.currentUserId;
    if (uid == null) throw StateError('Not signed in');
    final row = await _supabase.client
        .from('tasks')
        .insert(task.toInsertMap(uid))
        .select()
        .single();
    return TaskItem.fromMap(row);
  }

  Future<TaskItem> update(TaskItem task) async {
    final row = await _supabase.client
        .from('tasks')
        .update(task.toUpdateMap())
        .eq('id', task.id)
        .select()
        .single();
    return TaskItem.fromMap(row);
  }

  Future<void> delete(String id) async {
    await _supabase.client.from('tasks').delete().eq('id', id);
  }
}
