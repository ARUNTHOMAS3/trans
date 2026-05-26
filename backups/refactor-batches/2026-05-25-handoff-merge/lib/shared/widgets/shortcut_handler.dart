import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';

/// A wrapper widget that handles common keyboard shortcuts like Ctrl+S (Save),
/// Ctrl+Enter (Publish), Esc (Cancel), and '/' (Search Focus).
class ShortcutHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSave;
  final VoidCallback? onPublish; // Typically Ctrl + Enter
  final VoidCallback? onCancel;
  final VoidCallback? onSearch; // Typically triggered by '/'
  final bool isDirty;
  final FocusNode? searchFocusNode;
  final bool autofocus;

  const ShortcutHandler({
    super.key,
    required this.child,
    this.onSave,
    this.onPublish,
    this.onCancel,
    this.onSearch,
    this.isDirty = false,
    this.searchFocusNode,
    this.autofocus = true,
  });

  Future<void> _handleCancel(BuildContext context) async {
    if (onCancel == null) return;

    if (isDirty) {
      final discard = await showUnsavedChangesDialog(
        context,
        title: 'Leave this page?',
        message: 'If you leave, your unsaved changes will be discarded.',
        stayLabel: 'Stay Here',
        discardLabel: 'Leave & Discard Changes',
      );

      if (discard) {
        onCancel!();
      }
    } else {
      onCancel!();
    }
  }

  void _handleSearchFocus() {
    if (searchFocusNode != null) {
      searchFocusNode!.requestFocus();
    } else if (onSearch != null) {
      onSearch!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        if (onSave != null)
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              onSave!,
        if (onPublish != null)
          const SingleActivator(LogicalKeyboardKey.enter, control: true):
              onPublish!,
        if (onCancel != null)
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              _handleCancel(context),
        if (searchFocusNode != null || onSearch != null)
          const SingleActivator(LogicalKeyboardKey.slash): _handleSearchFocus,
      },
      child: Focus(autofocus: autofocus, child: child),
    );
  }
}
