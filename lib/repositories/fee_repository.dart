import '../models/semester_fee.dart';
import '../services/supabase_service.dart';

class FeeRepository {
  FeeRepository(this._supabase);
  final SupabaseService _supabase;

  Future<List<SemesterFee>> list() async {
    final uid = _supabase.currentUserId;
    if (uid == null) return const [];
    final rows = await _supabase.client
        .from('semester_fees')
        .select()
        .eq('user_id', uid)
        .order('due_date', ascending: true);
    return (rows as List)
        .map((r) => SemesterFee.fromMap(r as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<SemesterFee> create(SemesterFee item) async {
    final uid = _supabase.currentUserId;
    if (uid == null) throw StateError('Not signed in');
    final row = await _supabase.client
        .from('semester_fees')
        .insert(item.toInsertMap(uid))
        .select()
        .single();
    return SemesterFee.fromMap(row);
  }

  Future<SemesterFee> update(SemesterFee item) async {
    final row = await _supabase.client
        .from('semester_fees')
        .update(item.toUpdateMap())
        .eq('id', item.id)
        .select()
        .single();
    return SemesterFee.fromMap(row);
  }

  Future<void> delete(String id) async {
    await _supabase.client.from('semester_fees').delete().eq('id', id);
  }
}
