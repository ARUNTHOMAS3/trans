import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class NumberPreferencesResult {
  final String prefix;
  final String nextNumber;

  const NumberPreferencesResult({
    required this.prefix,
    required this.nextNumber,
  });
}

class NumberPreferencesDialog extends StatefulWidget {
  final String entityName;
  final String initialPrefix;
  final String initialNextNumber;

  const NumberPreferencesDialog({
    super.key,
    required this.entityName,
    required this.initialPrefix,
    required this.initialNextNumber,
  });

  static Future<NumberPreferencesResult?> show(
    BuildContext context, {
    required String entityName,
    required String initialPrefix,
    required String initialNextNumber,
  }) {
    return showGeneralDialog<NumberPreferencesResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.1),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: NumberPreferencesDialog(
            entityName: entityName,
            initialPrefix: initialPrefix,
            initialNextNumber: initialNextNumber,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.1),
              end: Offset.zero,
            ).animate(anim1),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<NumberPreferencesDialog> createState() =>
      _NumberPreferencesDialogState();
}

class _NumberPreferencesDialogState extends State<NumberPreferencesDialog> {
  late final TextEditingController _prefixCtrl;
  late final TextEditingController _nextNumberCtrl;

  @override
  void initState() {
    super.initState();

    _prefixCtrl = TextEditingController(text: widget.initialPrefix);

    _nextNumberCtrl = TextEditingController(text: widget.initialNextNumber);
  }

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _nextNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entity = widget.entityName;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 460,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Configure $entity Numbers Preferences',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppTheme.borderColor),

            /// Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$entity numbers will be auto-generated based on the preferences below. '
                    'For each new $entity that is created, the number after the prefix '
                    'will be incremented by 1.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Prefix'),
                            const SizedBox(height: 6),
                            CustomTextField(controller: _prefixCtrl),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      SizedBox(
                        width: 140,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Next Number'),
                            const SizedBox(height: 6),
                            CustomTextField(
                              controller: _nextNumberCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Note: If you want to change only this $entity number '
                      'without affecting the current series, you can edit it '
                      'directly from the ${entity} Number field after closing '
                      'this popup.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppTheme.borderColor),

            /// Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              child: Row(
                children: [
                  ZButton.primary(
                    label: 'Save',
                    onPressed: () {
                      Navigator.pop(
                        context,
                        NumberPreferencesResult(
                          prefix: _prefixCtrl.text.trim(),
                          nextNumber: _nextNumberCtrl.text.trim(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
