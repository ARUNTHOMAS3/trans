import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/recurring_expense_form_metrics.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

const double _addAccountDialogWidth = 780.0;
const double _addAccountLabelWidth = 150.0;
const double _addAccountCodeFieldWidth = 180.0;
const double _addAccountTopFieldWidth = 300.0;
const double _addAccountInfoCardWidth = 230.0;
const double _addAccountTopSectionGap = 16.0;
const double _addAccountFieldHeight = kRecurringExpenseCompactFieldHeight;

class _AddAccountResizableBox extends StatefulWidget {
  const _AddAccountResizableBox({
    required this.child,
    required this.initialHeight,
    required this.minHeight,
    this.maxHeight,
    this.onResize,
  });

  final Widget child;
  final double initialHeight;
  final double minHeight;
  final double? maxHeight;
  final ValueChanged<double>? onResize;

  @override
  State<_AddAccountResizableBox> createState() =>
      _AddAccountResizableBoxState();
}

class _AddAccountResizableBoxState extends State<_AddAccountResizableBox> {
  late double height;

  @override
  void initState() {
    super.initState();
    height = widget.initialHeight;
  }

  @override
  void didUpdateWidget(covariant _AddAccountResizableBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHeight != widget.initialHeight &&
        widget.initialHeight != height) {
      height = widget.initialHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            right: 4,
            bottom: 4,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: (details) {
                setState(() {
                  height += details.delta.dy;
                  if (height < widget.minHeight) {
                    height = widget.minHeight;
                  }
                  if (widget.maxHeight != null && height > widget.maxHeight!) {
                    height = widget.maxHeight!;
                  }
                });
                widget.onResize?.call(height);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: const SizedBox(
                  width: 12,
                  height: 12,
                  child: CustomPaint(painter: _AddAccountResizeHandlePainter()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAccountResizeHandlePainter extends CustomPainter {
  const _AddAccountResizeHandlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textMuted
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.2, size.height),
      Offset(size.width, size.height * 0.2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height),
      Offset(size.width, size.height * 0.6),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AddAccountDialog extends StatefulWidget {
  const AddAccountDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.1),
      pageBuilder: (context, anim1, anim2) {
        return const Align(
          alignment: Alignment.topCenter,
          child: AddAccountDialog(),
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
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameCtrl = TextEditingController();
  final _accountCodeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  double _descriptionHeight = 92;
  String _selectedAccountType = 'Fixed Asset';
  bool _isSubAccount = false;
  bool _showInZohoExpense = false;
  String? _selectedParentAccount;

  // Parent account options (mirrors the dummy accounts list)
  static const _parentAccountOptions = [
    'Bad Debt',
    'Bank Chargers',
    'Bank Fees and Charges',
    'Consultant Expense',
  ];

  static const _accountTypes = [
    'Fixed Asset',
    'Current Asset',
    'Current Liability',
    'Long-term Liability',
    'Equity',
    'Income',
    'Other Income',
    'Cost of Goods Sold',
    'Expense',
    'Other Expense',
  ];

  static const _typeDescriptions = {
    'Fixed Asset':
        'Any long term investment or an asset that cannot be converted into cash easily like:\n• Land and Buildings\n• Plant, Machinery and Equipment\n• Computers\n• Furniture',
    'Current Asset':
        'Assets that can be converted into cash within a year like receivables, inventory, cash and bank balances.',
    'Expense':
        'Day-to-day expenses incurred for running the business like office supplies, utilities, rent etc.',
  };

  // Category heading shown in the info card for each type
  static const _typeCategories = {
    'Fixed Asset': 'Asset',
    'Current Asset': 'Asset',
    'Current Liability': 'Liability',
    'Long-term Liability': 'Liability',
    'Equity': 'Equity',
    'Income': 'Income',
    'Other Income': 'Income',
    'Cost of Goods Sold': 'Expense',
    'Expense': 'Expense',
    'Other Expense': 'Expense',
  };

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    _accountCodeCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: _addAccountDialogWidth,
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
        child: Form(
          key: _formKey,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screenH - 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Create Account',
                          style: AppTextStyles.title.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Form body ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOP SECTION: compact two-column (form fields | info card)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width:
                                _addAccountLabelWidth +
                                AppTheme.space20 +
                                _addAccountTopFieldWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Account Type
                                _formField(
                                  label: 'Account Type',
                                  required: true,
                                  child: _fieldBoxWithWidth(
                                    _addAccountTopFieldWidth,
                                    FormDropdown<String>(
                                      height: _addAccountFieldHeight,
                                      value: _selectedAccountType,
                                      items: _accountTypes,
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(
                                            () => _selectedAccountType = v,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Account Name
                                _formField(
                                  label: 'Account Name',
                                  required: true,
                                  child: _fieldBoxWithWidth(
                                    _addAccountTopFieldWidth,
                                    CustomTextField(
                                      controller: _accountNameCtrl,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Account Name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                _formField(
                                  label: '',
                                  child: _fieldBoxWithWidth(
                                    _addAccountTopFieldWidth,
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: Checkbox(
                                            value: _isSubAccount,
                                            onChanged: (v) => setState(
                                              () => _isSubAccount = v ?? false,
                                            ),
                                            activeColor:
                                                AppTheme.primaryBlueDark,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Make this a sub-account',
                                            style: AppTextStyles.body.copyWith(
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const ZTooltip(
                                          message:
                                              'Select this option if you are creating a sub-account.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Parent Account (conditional)
                                if (_isSubAccount) ...[
                                  const SizedBox(height: 14),
                                  _formField(
                                    label: 'Parent Account',
                                    required: true,
                                    child: _fieldBoxWithWidth(
                                      _addAccountTopFieldWidth,
                                      FormDropdown<String>(
                                        height: _addAccountFieldHeight,
                                        value: _selectedParentAccount,
                                        hint: 'Select an account',
                                        items: _parentAccountOptions,
                                        onChanged: (v) => setState(
                                          () => _selectedParentAccount = v,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_typeDescriptions.containsKey(
                            _selectedAccountType,
                          )) ...[
                            const SizedBox(width: _addAccountTopSectionGap),
                            _AccountTypeInfoCard(
                              category:
                                  _typeCategories[_selectedAccountType] ??
                                  _selectedAccountType,
                              description:
                                  _typeDescriptions[_selectedAccountType],
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 18),

                      // BOTTOM SECTION: full-width fields (no info card beside)
                      // Account Code
                      _formField(
                        label: 'Account Code',
                        hasDottedUnderline: true,
                        tooltipMessage:
                            'A unique reference code for this account. It is limited to 50 characters and can comprise of letters, digits, hyphen and underscore.',
                        showTooltipIcon: false,
                        child: _fieldBoxWithWidth(
                          _addAccountCodeFieldWidth,
                          CustomTextField(controller: _accountCodeCtrl),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      _formField(
                        label: 'Description',
                        child: _fieldBoxWithWidth(
                          _addAccountTopFieldWidth,
                          _AddAccountResizableBox(
                            initialHeight: _descriptionHeight,
                            minHeight: 92,
                            maxHeight: 220,
                            onResize: (height) {
                              setState(() => _descriptionHeight = height);
                            },
                            child: CustomTextField(
                              controller: _descriptionCtrl,
                              hintText: 'Max. 500 characters',
                              maxLines: 4,
                              height: _descriptionHeight,
                              padding: const EdgeInsets.only(
                                left: 10,
                                top: 10,
                                right: 24,
                                bottom: 24,
                              ),
                              contentCase: ContentCase.sentence,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: 18),

                      // Zoho Expense
                      _formField(
                        label: 'Zoho Expense ?',
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: Checkbox(
                                value: _showInZohoExpense,
                                onChanged: (v) => setState(
                                  () => _showInZohoExpense = v ?? false,
                                ),
                                activeColor: AppTheme.primaryBlueDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Show as an active account in Zoho Expense',
                              style: AppTextStyles.body.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const ZTooltip(
                              message:
                                  'Enable to make this account available in Zoho Expense reports.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppTheme.borderLight),

                // ── Footer ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Theme(
                        data: AppTheme.themedWith(AppTheme.accentGreen),
                        child: ZButton.primary(
                          label: 'Save and Select',
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              Navigator.pop(
                                context,
                                _accountNameCtrl.text.trim(),
                              );
                            }
                          },
                        ),
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
        ),
      ),
    );
  }

  Widget _fieldBoxWithWidth(double width, Widget child) {
    final compactChild = _usesCompactFieldHeight(child)
        ? SizedBox(height: _addAccountFieldHeight, child: child)
        : child;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: compactChild,
      ),
    );
  }

  bool _usesCompactFieldHeight(Widget child) {
    if (child is CustomTextField) {
      return child.maxLines == null || child.maxLines == 1;
    }
    return child is FormDropdown<String>;
  }

  Widget _formField({
    required String label,
    required Widget child,
    bool required = false,
    Widget? trailing,
    bool hasDottedUnderline = false,
    String? tooltipMessage,
    bool showTooltipIcon = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _addAccountLabelWidth,
          child: Row(
            children: [
              if (tooltipMessage != null && !showTooltipIcon)
                ZTooltip(
                  message: tooltipMessage,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.help,
                    child: RichText(
                      text: TextSpan(
                        text: label,
                        style:
                            (required
                                    ? AppTextStyles.labelRequired
                                    : AppTextStyles.label)
                                .copyWith(
                                  color: required
                                      ? AppTheme.errorRed
                                      : AppTheme.textPrimary,
                                  fontWeight: required
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  decoration: hasDottedUnderline
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                  decorationStyle: hasDottedUnderline
                                      ? TextDecorationStyle.dotted
                                      : null,
                                  decorationColor: hasDottedUnderline
                                      ? AppTheme.textPrimary
                                      : null,
                                ),
                        children: required
                            ? [
                                TextSpan(
                                  text: '*',
                                  style: AppTextStyles.labelRequired.copyWith(
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ]
                            : [],
                      ),
                    ),
                  ),
                )
              else
                RichText(
                  text: TextSpan(
                    text: label,
                    style:
                        (required
                                ? AppTextStyles.labelRequired
                                : AppTextStyles.label)
                            .copyWith(
                              color: required
                                  ? AppTheme.errorRed
                                  : AppTheme.textPrimary,
                              fontWeight: required
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              decoration: hasDottedUnderline
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              decorationStyle: hasDottedUnderline
                                  ? TextDecorationStyle.dotted
                                  : null,
                              decorationColor: hasDottedUnderline
                                  ? AppTheme.textPrimary
                                  : null,
                            ),
                    children: required
                        ? [
                            TextSpan(
                              text: '*',
                              style: AppTextStyles.labelRequired.copyWith(
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ]
                        : [],
                  ),
                ),
              if (tooltipMessage != null && showTooltipIcon) ...[
                const SizedBox(width: 6),
                ZTooltip(message: tooltipMessage),
              ],
            ],
          ),
        ),
        Expanded(child: child),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }
}

/// Permanent info card shown next to the Account Type dropdown.
/// Always visible — not a hover tooltip.
class _AccountTypeInfoCard extends StatelessWidget {
  final String category;
  final String? description;

  const _AccountTypeInfoCard({required this.category, this.description});

  @override
  Widget build(BuildContext context) {
    // Parse description lines: split on \n and mark bullet lines
    final lines = (description ?? '').split('\n');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: _addAccountInfoCardWidth,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.sidebarColor, // dark navy, matching sidebar color
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category,
                style: AppTextStyles.body.copyWith(
                  color: AppTheme.backgroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...lines.map((line) {
                final isBullet = line.trimLeft().startsWith('\u2022');
                return Padding(
                  padding: EdgeInsets.only(
                    top: isBullet ? 2 : 4,
                    left: isBullet ? 0 : 0,
                  ),
                  child: Text(
                    line,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.backgroundColor,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Positioned(
          left: -6,
          top: 15,
          child: CustomPaint(
            size: const Size(6, 10),
            painter: _TrianglePainter(color: AppTheme.sidebarColor),
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(0, size.height / 2);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
