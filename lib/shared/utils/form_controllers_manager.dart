// FILE: lib/shared/utils/form_controllers_manager.dart
//
// Utility class that manages [TextEditingController] instances by string key,
// eliminating the boilerplate of declaring and disposing 40-50 controllers per
// screen.
//
// Usage:
//   final _controllers = FormControllersManager();
//
//   @override
//   void initState() {
//     super.initState();
//     _controllers.init({
//       'name': '',
//       'email': 'prefill@example.com',
//       'phone': '',
//     });
//   }
//
//   // Access:
//   _controllers['name']        // operator []
//   _controllers.get('name')    // explicit getter
//
//   // Update:
//   _controllers.set('email', 'new@example.com');
//   _controllers.clear('phone');
//   _controllers.clearAll();
//
//   @override
//   void dispose() {
//     _controllers.dispose();
//     super.dispose();
//   }

import 'package:flutter/widgets.dart';

/// Manages a keyed collection of [TextEditingController] instances.
///
/// Intended for use inside [StatefulWidget] state classes.  Create one instance
/// per screen, call [init] once in `initState`, and call [dispose] in the
/// widget's `dispose` method.
class FormControllersManager {
  final Map<String, TextEditingController> _controllers = {};

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Creates a [TextEditingController] for each key in [initialValues] with
  /// the corresponding string as its initial text.
  ///
  /// Calling [init] more than once is allowed; any key not already present will
  /// be added and any existing controller will have its text updated to the new
  /// initial value.
  void init(Map<String, String> initialValues) {
    initialValues.forEach((key, value) {
      if (_controllers.containsKey(key)) {
        _controllers[key]!.text = value;
      } else {
        _controllers[key] = TextEditingController(text: value);
      }
    });
  }

  /// Disposes all managed controllers and clears the internal map.
  ///
  /// Must be called from the owning widget's `dispose` method.
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  // ── Access ────────────────────────────────────────────────────────────────

  /// Returns the [TextEditingController] for [key].
  ///
  /// Throws [StateError] if [key] was not registered via [init].
  TextEditingController get(String key) {
    final controller = _controllers[key];
    if (controller == null) {
      throw StateError(
        'FormControllersManager: no controller registered for key "$key". '
        'Did you forget to include it in init()?',
      );
    }
    return controller;
  }

  /// Shorthand for [get].
  ///
  /// Throws [StateError] if [key] was not registered.
  TextEditingController operator [](String key) => get(key);

  /// Returns `true` if a controller is registered for [key].
  bool containsKey(String key) => _controllers.containsKey(key);

  // ── Mutation ──────────────────────────────────────────────────────────────

  /// Sets the text of the controller at [key] to [value].
  ///
  /// Throws [StateError] if [key] was not registered via [init].
  void set(String key, String value) => get(key).text = value;

  /// Clears the text of the controller at [key].
  ///
  /// Throws [StateError] if [key] was not registered via [init].
  void clear(String key) => get(key).clear();

  /// Clears the text of every managed controller.
  void clearAll() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  /// Returns a snapshot of every controller's current text, keyed by the same
  /// string used in [init].
  Map<String, String> toMap() {
    return {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };
  }
}
