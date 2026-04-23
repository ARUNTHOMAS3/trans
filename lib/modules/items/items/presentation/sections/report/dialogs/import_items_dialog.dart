import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

Future<String?> showImportItemsDialog(BuildContext context) {
  String selected = 'item';

  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Import Items List',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (ctx, _, __) {
      return SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 12,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: StatefulBuilder(
                      builder: (ctx, setState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ------------------------------------------------
                            // HEADER
                            // ------------------------------------------------
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.borderColor),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'Import Items List',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: AppTheme.textSecondary,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(null),
                                  ),
                                ],
                              ),
                            ),

                            // ------------------------------------------------
                            // BODY
                            // ------------------------------------------------
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                40,
                                24,
                                40,
                                24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RadioGroup<String>(
                                    groupValue: selected,
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => selected = v);
                                      }
                                    },
                                    child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _ImportRadioRow(
                                          value: 'item',
                                          label: 'Item',
                                        ),
                                        _ImportRadioRow(
                                          value: 'opening_stock',
                                          label: 'Opening Stock',
                                        ),
                                        _ImportRadioRow(
                                          value: 'composition_information',
                                          label: 'Composition Information',
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // ------------------------------------------------
                                  // ACTIONS
                                  // ------------------------------------------------
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF16A34A,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(ctx).pop(selected);
                                        },
                                        child: const Text(
                                          'Continue',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 10,
                                          ),
                                          side: const BorderSide(
                                            color: AppTheme.textMuted,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(null),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textBody,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.05),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ------------------------------------------------------------
// RADIO ROW (DUMB)
// ------------------------------------------------------------

class _ImportRadioRow extends StatelessWidget {
  final String value;
  final String label;

  const _ImportRadioRow({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Radio<String>(value: value, visualDensity: VisualDensity.compact),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
