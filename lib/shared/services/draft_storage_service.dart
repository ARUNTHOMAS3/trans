import 'package:hive_flutter/hive_flutter.dart';

/// Persists form state to a local Hive box so users can recover from tab
/// crashes, accidental navigation, or network drops.
///
/// Keys are route-path constants (e.g. 'manual_journal_create', 'item_create').
/// Drafts survive app restarts. The 'local_drafts' box is opened outside the
/// version-bump clear loop in main.dart intentionally — user drafts must not
/// be wiped by an app update.
class DraftStorageService {
  static const _boxName = 'local_drafts';

  static Box get _box => Hive.box(_boxName);

  /// Persist [data] under [key]. Overwrites any existing draft.
  static Future<void> save(String key, Map<String, dynamic> data) async {
    await _box.put(key, data);
  }

  /// Returns the stored draft for [key], or null if none exists.
  static Map<String, dynamic>? load(String key) {
    final val = _box.get(key);
    if (val is Map) return Map<String, dynamic>.from(val);
    return null;
  }

  /// Erase the draft for [key]. Call on successful API save or manual cancel.
  static Future<void> clear(String key) async {
    await _box.delete(key);
  }

  /// Returns true if a draft exists for [key].
  static bool hasDraft(String key) => _box.containsKey(key);
}
