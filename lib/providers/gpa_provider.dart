import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gpa_record.dart';
import '../repositories/gpa_repository.dart';
import '../utils/grade.dart';
import 'auth_provider.dart';

final gpaRepositoryProvider = Provider<GpaRepository>(
    (ref) => GpaRepository(ref.watch(supabaseServiceProvider)));

class GpaController extends AsyncNotifier<List<GpaRecord>> {
  GpaRepository get _repo => ref.read(gpaRepositoryProvider);

  @override
  Future<List<GpaRecord>> build() async {
    ref.watch(currentUserProvider);
    return _repo.list();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.list);
  }

  Future<void> create(GpaRecord item) async {
    await _repo.create(item);
    await refresh();
  }

  Future<void> update(GpaRecord item) async {
    await _repo.update(item);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await refresh();
  }
}

final gpaProvider = AsyncNotifierProvider<GpaController, List<GpaRecord>>(
    GpaController.new);

final cgpaProvider = Provider<double>((ref) {
  final all = ref.watch(gpaProvider).valueOrNull ?? const <GpaRecord>[];
  return GradeCalc.gpa(all);
});

final gpaBySemesterProvider = Provider<Map<String, double>>((ref) {
  final all = ref.watch(gpaProvider).valueOrNull ?? const <GpaRecord>[];
  return GradeCalc.bySemester(all);
});
