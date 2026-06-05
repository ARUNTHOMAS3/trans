import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/user_model.dart';
import '../repositories/user_management_repository.dart';

final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  final apiClient = ApiClient(); // Or use a shared apiClientProvider if available
  return UserManagementRepository(apiClient: apiClient);
});

final allUsersProvider = FutureProvider<List<User>>((ref) async {
  final repository = ref.read(userManagementRepositoryProvider);
  return repository.getUsers();
});
