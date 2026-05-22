import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/semester_fee.dart';
import '../repositories/fee_repository.dart';
import 'auth_provider.dart';

final feeRepositoryProvider = Provider<FeeRepository>(
    (ref) => FeeRepository(ref.watch(supabaseServiceProvider)));

class FeesController extends AsyncNotifier<List<SemesterFee>> {
  FeeRepository get _repo => ref.read(feeRepositoryProvider);

  @override
  Future<List<SemesterFee>> build() async {
    ref.watch(currentUserProvider);
    return _repo.list();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.list);
  }

  Future<void> create(SemesterFee item) async {
    await _repo.create(item);
    await refresh();
  }

  Future<void> update(SemesterFee item) async {
    await _repo.update(item);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await refresh();
  }
}

final feesProvider = AsyncNotifierProvider<FeesController, List<SemesterFee>>(
    FeesController.new);
