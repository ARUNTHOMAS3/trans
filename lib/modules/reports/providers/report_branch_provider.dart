import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

final reportBranchNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final response = await repo.getCurrentBranchHeader();
  return response['branchName']?.toString().trim() ?? '';
});
