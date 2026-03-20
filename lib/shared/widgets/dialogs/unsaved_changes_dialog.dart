import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';

Future<bool> showUnsavedChangesDialog(
  BuildContext context, {
  String title = 'Leave this page?',
  String message = 'If you leave, your unsaved changes will be discarded.',
  String stayLabel = 'Stay Here',
  String discardLabel = 'Leave & Discard Changes',
}) async {
  final result = await showZerpaiConfirmationDialog(
    context,
    title: title,
    message: message,
    confirmLabel: stayLabel,
    cancelLabel: discardLabel,
  );

  return result;
}
