import '../models/gpa_record.dart';
import '../services/supabase_service.dart';

class GpaRepository {
  GpaRepository(this._supabase);
  final SupabaseService _supabase;

  Future<List<GpaRecord>> list() async {
    final uid = _supabase.currentUserId;
    if (uid == null) return const [];
    final rows = await _supabase.client
        .from('gpa_records')
        .select()
        .eq('user_id', uid)
        .order('semester_label', ascending: true)
        .order('course_name', ascending: true);
    return (rows as List)
        .map((r) => GpaRecord.fromMap(r as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<GpaRecord> create(GpaRecord item) async {
    final uid = _supabase.currentUserId;
    if (uid == null) throw StateError('Not signed in');
    final row = await _supabase.client
        .from('gpa_records')
        .insert(item.toInsertMap(uid))
        .select()
        .single();
    return GpaRecord.fromMap(row);
  }

  Future<GpaRecord> update(GpaRecord item) async {
    final row = await _supabase.client
        .from('gpa_records')
        .update(item.toUpdateMap())
        .eq('id', item.id)
        .select()
        .single();
    return GpaRecord.fromMap(row);
  }

  Future<void> delete(String id) async {
    await _supabase.client.from('gpa_records').delete().eq('id', id);
  }
}
