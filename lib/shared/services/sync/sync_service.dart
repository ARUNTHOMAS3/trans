import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

/// The key for the local hive box that stores offline drafts
const String kOfflineDraftsBox = 'zerpai_offline_drafts';

enum SyncStatus { online, offline, syncing }

class SyncState {
  final SyncStatus status;
  final int draftCount;
  final bool isConnected;

  const SyncState({
    this.status = SyncStatus.online,
    this.draftCount = 0,
    this.isConnected = true,
  });

  SyncState copyWith({SyncStatus? status, int? draftCount, bool? isConnected}) {
    return SyncState(
      status: status ?? this.status,
      draftCount: draftCount ?? this.draftCount,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// A global service to manage online/offline state and drafts.
class SyncService extends StateNotifier<SyncState> {
  final Logger _logger = Logger();
  late Box _draftsBox;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncService() : super(const SyncState()) {
    _init();
  }

  Future<void> _init() async {
    // Open Hive Box for drafts
    if (!Hive.isBoxOpen(kOfflineDraftsBox)) {
      _draftsBox = await Hive.openBox(kOfflineDraftsBox);
    } else {
      _draftsBox = Hive.box(kOfflineDraftsBox);
    }

    _updateDraftCount();

    // Listen to connectivity changes
    // connectivity_plus 6.0 returns List<ConnectivityResult>
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isConnected = results.any(
        (result) => result != ConnectivityResult.none,
      );
      _updateConnectionStatus(isConnected);
    });

    // Check initial status
    final results = await Connectivity().checkConnectivity();
    final isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    _updateConnectionStatus(isConnected);
  }

  void _updateConnectionStatus(bool isConnected) {
    if (state.isConnected == isConnected) return; // No change

    state = state.copyWith(
      isConnected: isConnected,
      status: isConnected ? SyncStatus.online : SyncStatus.offline,
    );

    if (isConnected && _draftsBox.isNotEmpty) {
      // Logic handled by UI listener to prompt user
      _logger.i('Connection restored. ${_draftsBox.length} drafts pending.');
    }
  }

  void _updateDraftCount() {
    state = state.copyWith(draftCount: _draftsBox.length);
  }

  /// Save a draft to local storage when offline
  /// [key] should be unique enough, e.g. "composite_item_create_{timestamp}"
  /// [type] is a label for the UI, e.g. "Composite Item"
  /// [data] is the JSON payload
  Future<void> saveDraft(
    String key,
    String type,
    Map<String, dynamic> data,
  ) async {
    final draft = {
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    };
    await _draftsBox.put(key, draft);
    _updateDraftCount();
    _logger.i('Draft saved: $key');
  }

  /// Get all pending drafts
  Map<dynamic, dynamic> getDrafts() {
    return _draftsBox.toMap();
  }

  /// Delete a draft after successful sync
  Future<void> deleteDraft(String key) async {
    await _draftsBox.delete(key);
    _updateDraftCount();
  }

  /// Clear all drafts
  Future<void> clearAllDrafts() async {
    await _draftsBox.clear();
    _updateDraftCount();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

final syncServiceProvider = StateNotifierProvider<SyncService, SyncState>((
  ref,
) {
  return SyncService();
});
