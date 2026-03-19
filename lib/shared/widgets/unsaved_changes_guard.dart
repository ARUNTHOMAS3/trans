import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';

class UnsavedChangesGuard extends StatefulWidget {
  final Widget child;
  final bool isDirty;
  final VoidCallback? onDiscardChanges;
  final String title;
  final String message;
  final String stayLabel;
  final String discardLabel;

  const UnsavedChangesGuard({
    super.key,
    required this.child,
    required this.isDirty,
    this.onDiscardChanges,
    this.title = 'Leave this page?',
    this.message = 'If you leave, your unsaved changes will be discarded.',
    this.stayLabel = 'Stay Here',
    this.discardLabel = 'Leave & Discard Changes',
  });

  @override
  State<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends State<UnsavedChangesGuard> {
  bool _allowPop = false;
  bool _dialogOpen = false;

  Future<void> _confirmDiscard() async {
    if (!widget.isDirty || _dialogOpen || !mounted) return;

    _dialogOpen = true;
    final shouldDiscard = await showUnsavedChangesDialog(
      context,
      title: widget.title,
      message: widget.message,
      stayLabel: widget.stayLabel,
      discardLabel: widget.discardLabel,
    );
    _dialogOpen = false;

    if (!mounted || !shouldDiscard) return;

    if (widget.onDiscardChanges != null) {
      widget.onDiscardChanges!();
      return;
    }

    setState(() => _allowPop = true);
    Navigator.of(context).maybePop();
  }

  @override
  void didUpdateWidget(covariant UnsavedChangesGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isDirty && _allowPop) {
      _allowPop = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop || !widget.isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          if (_allowPop && mounted) {
            setState(() => _allowPop = false);
          }
          return;
        }
        _confirmDiscard();
      },
      child: widget.child,
    );
  }
}
