import 'package:flutter/material.dart';

Future<void> showTaxExportDialog(
  BuildContext context, {
  bool taxGroup = false,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Text(taxGroup ? 'Export tax groups' : 'Export taxes'),
      content: const Text(
        'Export is available after the settings repository is connected.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
