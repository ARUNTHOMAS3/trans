import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped whenever an approval decision is recorded, so an approvals list that
/// is already built re-reads instead of showing the status it fetched when it
/// first loaded.
///
/// The overview is a child route of the report, so returning to the report pops
/// back to a State that is still alive — `initState` never runs again and an
/// approve or reject made on the overview would need a manual refresh to show.
///
/// Mirrors `purchaseRequestListRefreshProvider`. If a third list needs this,
/// promote both to a shared `StateProvider.family<int, String>` keyed by list
/// id rather than adding another bespoke token.
final approvalsListRefreshProvider = StateProvider<int>((ref) => 0);
