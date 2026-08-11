import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the current inbox document count to drive the sidebar badge.
final documentsInboxCountProvider = StateProvider<int>((ref) => 0);

/// Tracks the list of user-created folders.
final documentsFoldersProvider = StateProvider<List<String>>((ref) => []);

