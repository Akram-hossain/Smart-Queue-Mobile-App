import '../models/attendance.dart';
import '../services/supabase_service.dart';

class AttendanceRepository {
  AttendanceRepository(this._supabase);
  final SupabaseService _supabase;

  Future<List<AttendanceItem>> list() async {
    final uid = _supabase.currentUserId;
    if (uid == null) return const [];
    final rows = await _supabase.client
        .from('attendance')
        .select()
        .eq('user_id', uid)
        .order('subject_name', ascending: true);
    return (rows as List)
        .map((r) => AttendanceItem.fromMap(r as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<AttendanceItem> create(AttendanceItem item) async {
    final uid = _supabase.currentUserId;
    if (uid == null) throw StateError('Not signed in');
    final row = await _supabase.client
        .from('attendance')
        .insert(item.toInsertMap(uid))
        .select()
        .single();
    return AttendanceItem.fromMap(row);
  }

  Future<AttendanceItem> update(AttendanceItem item) async {
    final row = await _supabase.client
        .from('attendance')
        .update(item.toUpdateMap())
        .eq('id', item.id)
        .select()
        .single();
    return AttendanceItem.fromMap(row);
  }

  Future<void> delete(String id) async {
    await _supabase.client.from('attendance').delete().eq('id', id);
  }
}
