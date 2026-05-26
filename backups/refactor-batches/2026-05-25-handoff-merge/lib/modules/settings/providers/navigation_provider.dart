import 'package:flutter_riverpod/flutter_riverpod.dart';

// Navigation provider to manage the selected index in the sidebar
class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0); // Default to home index

  void setSelectedIndex(int index) {
    state = index;
  }

  void increment() {
    state = state + 1;
  }

  void decrement() {
    state = state - 1;
  }
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, int>((ref) => NavigationNotifier());
