import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RecentItem {
  final String id;
  final String title;
  final String type; // e.g., 'Price List', 'Invoice', etc.
  final String route;
  final dynamic extraData;
  final DateTime timestamp;

  RecentItem({
    required this.id,
    required this.title,
    required this.type,
    required this.route,
    this.extraData,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'route': route,
    'extraData': extraData,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RecentItem.fromJson(Map<String, dynamic> json) => RecentItem(
    id: json['id'],
    title: json['title'],
    type: json['type'],
    route: json['route'],
    extraData: json['extraData'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class RecentHistoryNotifier extends StateNotifier<List<RecentItem>> {
  static const String _boxName = 'recent_history';
  static const int _maxItems = 10;

  RecentHistoryNotifier() : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final box = await Hive.openBox(_boxName);
    final List<dynamic> raw = box.get('items', defaultValue: []);
    state = raw.map((e) => RecentItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> addItem(RecentItem item) async {
    // Remove existing if duplicate
    final filtered = state.where((e) => e.id != item.id || e.type != item.type).toList();
    
    // Add to top and limit
    final updated = [item, ...filtered];
    if (updated.length > _maxItems) {
      updated.removeRange(_maxItems, updated.length);
    }
    
    state = updated;
    final box = await Hive.openBox(_boxName);
    await box.put('items', state.map((e) => e.toJson()).toList());
  }

  Future<void> clearHistory() async {
    state = [];
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}

final recentHistoryProvider = StateNotifierProvider<RecentHistoryNotifier, List<RecentItem>>((ref) {
  return RecentHistoryNotifier();
});
