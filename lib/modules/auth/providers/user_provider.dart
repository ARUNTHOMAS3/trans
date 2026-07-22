import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:zerpai_erp/core/services/api_client.dart';
import '../models/user_model.dart';
import '../repositories/user_management_repository.dart';

final userManagementRepositoryProvider = Provider<UserManagementRepository>((
  ref,
) {
  final apiClient =
      ApiClient(); // Or use a shared apiClientProvider if available
  return UserManagementRepository(apiClient: apiClient);
});

final allUsersProvider = FutureProvider<List<User>>((ref) async {
  final repository = ref.read(userManagementRepositoryProvider);
  return repository.getUsers();
});

/// Queries the Supabase `users` table directly so returned IDs match
/// the FK on `purchase_requests.assignee_id` (and other business tables).
/// Use this wherever you need to save a user ID to the database.
final supabaseUsersProvider = FutureProvider<List<User>>((ref) async {
  final res = await Supabase.instance.client
      .from('users')
      .select('id, full_name, email, is_active')
      .eq('is_active', true)
      .order('full_name');
  return (res as List<dynamic>).map((row) {
    final m = row as Map<String, dynamic>;
    return User.fromJson({
      'id': m['id'],
      'full_name': m['full_name'],
      'email': m['email'],
      'is_active': m['is_active'] ?? true,
      'role': '',
      'orgId': '',
      'orgName': '',
      'orgSystemId': '',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }).toList();
});
