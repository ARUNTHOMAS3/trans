// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'items_repository.dart';
// import 'items_repository_impl.dart';

// /// Provider for Items repository with offline support (PRD Section 12.2)
// ///
// /// Uses online-first approach with automatic offline fallback
// final itemsRepositoryProvider = Provider<ItemRepository>((ref) {
//   return ItemsRepositoryImpl(); // ✅ Production repo with offline support
// });
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'items_repository.dart';
import 'items_repository_impl.dart';

/// Provider for Items repository with offline support (PRD Section 12.2)
///
/// Uses online-first approach with automatic offline fallback
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemsRepositoryImpl(); // ✅ Production repo with offline support
});
