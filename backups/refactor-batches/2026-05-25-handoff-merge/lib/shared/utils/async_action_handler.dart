// FILE: lib/shared/utils/async_action_handler.dart
// Centralised try/catch + toast + loading state pattern used across 30+
// screens in the sales, purchases, settings, and accountant modules.

import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

/// Handles the standard async action lifecycle:
/// set loading → execute → show toast → callback → unset loading.
///
/// Usage:
/// ```dart
/// await AsyncActionHandler.run(
///   context: context,
///   action: () => _service.save(payload),
///   setLoading: (v) => setState(() => _isSaving = v),
///   successMessage: 'Saved successfully',
///   onSuccess: () => context.pop(),
/// );
/// ```
class AsyncActionHandler {
  AsyncActionHandler._();

  /// Executes [action] with standard loading/success/error handling.
  ///
  /// - Calls [setLoading](true) before the action and [setLoading](false) after.
  /// - Shows [successMessage] toast on success (skipped if null).
  /// - Shows an error toast if the action throws; the message is
  ///   [errorPrefix] (if provided) followed by the exception string.
  /// - Calls [onSuccess] after the success toast (e.g. to pop the screen).
  ///   [onSuccess] is NOT called when the action throws.
  /// - Returns `true` if the action succeeded, `false` if it threw.
  static Future<bool> run({
    required BuildContext context,
    required Future<void> Function() action,
    required void Function(bool loading) setLoading,
    String? successMessage,
    VoidCallback? onSuccess,
    String? errorPrefix,
  }) async {
    setLoading(true);
    try {
      await action();
      if (successMessage != null && context.mounted) {
        ZerpaiToast.success(context, successMessage);
      }
      onSuccess?.call();
      return true;
    } catch (e) {
      if (context.mounted) {
        final msg = errorPrefix != null ? '$errorPrefix$e' : e.toString();
        ZerpaiToast.error(context, msg);
      }
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Convenience wrapper for delete actions with a default success message.
  ///
  /// Identical to [run] but defaults [successMessage] to 'Deleted successfully'.
  static Future<bool> delete({
    required BuildContext context,
    required Future<void> Function() action,
    required void Function(bool loading) setLoading,
    String successMessage = 'Deleted successfully',
    VoidCallback? onSuccess,
    String? errorPrefix,
  }) {
    return run(
      context: context,
      action: action,
      setLoading: setLoading,
      successMessage: successMessage,
      onSuccess: onSuccess,
      errorPrefix: errorPrefix,
    );
  }
}
