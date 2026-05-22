import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance.dart';
import '../repositories/attendance_repository.dart';
import 'auth_provider.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
    (ref) => AttendanceRepository(ref.watch(supabaseServiceProvider)));

class AttendanceController extends AsyncNotifier<List<AttendanceItem>> {
  AttendanceRepository get _repo => ref.read(attendanceRepositoryProvider);

  @override
  Future<List<AttendanceItem>> build() async {
    ref.watch(currentUserProvider);
    return _repo.list();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.list);
  }

  Future<void> create(AttendanceItem item) async {
    await _repo.create(item);
    await refresh();
  }

  Future<void> update(AttendanceItem item) async {
    await _repo.update(item);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await refresh();
  }
}

final attendanceProvider =
    AsyncNotifierProvider<AttendanceController, List<AttendanceItem>>(
        AttendanceController.new);
