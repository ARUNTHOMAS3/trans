import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Discard'),
            ),
          ],
        ),
      );

      if (discard == true) {
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
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): onSave!,
        if (onPublish != null)
          const SingleActivator(LogicalKeyboardKey.enter, control: true): onPublish!,
        if (onCancel != null)
          const SingleActivator(LogicalKeyboardKey.escape): () => _handleCancel(context),
        if (searchFocusNode != null || onSearch != null)
          const SingleActivator(LogicalKeyboardKey.slash): _handleSearchFocus,
      },
      child: Focus(
        autofocus: autofocus,
        child: child,
      ),
    );
  }
}
