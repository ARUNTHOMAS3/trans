import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class RecurringInvoicePreferencesDialog extends StatefulWidget {
  final String initialPreference;
  final bool initialSendEmail;

  const RecurringInvoicePreferencesDialog({
    super.key,
    required this.initialPreference,
    required this.initialSendEmail,
  });

  @override
  State<RecurringInvoicePreferencesDialog> createState() =>
      _RecurringInvoicePreferencesDialogState();
}

class _RecurringInvoicePreferencesDialogState
    extends State<RecurringInvoicePreferencesDialog> {
  late String _preference;
  late bool _sendEmail;
  late bool _applyExcessPayments;
  late bool _applyCreditNotes;
  late String _paymentSuccessAction;
  late String _paymentFailureAction;
  late bool _suspendOnFailure;
  late bool _disableCardSaving;

  static const List<String> _paymentSuccessActions = [
    'Send Thank-you Email along with the invoice',
    'Send invoice only',
    'Do not send any follow-up email',
  ];

  static const List<String> _paymentFailureActions = [
    'Send Payment Failure Email Notification',
    'Retry and notify customer',
    'Do not notify customer',
  ];

  static const List<_PreferenceOption> _options = [
    _PreferenceOption(
      value: 'drafts',
      title: 'Create Invoices as Drafts',
      description:
          'Invoices will be saved as drafts. You can review and send them to your customers for payment.',
    ),
    _PreferenceOption(
      value: 'send',
      title: 'Create, Push, and Send Invoices',
      description:
          'Invoices will be pushed to the IRP and sent to your customers for payment.',
    ),
    _PreferenceOption(
      value: 'charge',
      title: 'Create, Charge, Push, and Send Invoices',
      description:
          'Your customer\'s payment method associated with the recurring invoice will be charged automatically. Next, the invoices will be pushed to the IRP and then sent to your customers.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _preference = widget.initialPreference;
    _sendEmail = widget.initialSendEmail;
    _applyExcessPayments = false;
    _applyCreditNotes = true;
    _paymentSuccessAction = _paymentSuccessActions.first;
    _paymentFailureAction = _paymentFailureActions.first;
    _suspendOnFailure = false;
    _disableCardSaving = false;

    if (!_options.any((option) => option.value == _preference)) {
      _preference = _options.first.value;
    }
  }

  void _handleSave() {
    Navigator.of(context).pop({
      'preference': _preference,
      'sendEmail': _sendEmail,
      'applyExcessPayments': _applyExcessPayments,
      'applyCreditNotes': _applyCreditNotes,
      'paymentSuccessAction': _paymentSuccessAction,
      'paymentFailureAction': _paymentFailureAction,
      'suspendOnFailure': _suspendOnFailure,
      'disableCardSaving': _disableCardSaving,
    });
  }

  void _openPreferencesPage() {
    Navigator.of(context).pop();
    context.go(AppRoutes.salesRecurringInvoicesPreferences);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(28, 6, 28, 20),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 920,
          maxWidth: 1020,
          maxHeight: screenHeight - 12,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recurring Invoices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info,
                                size: 18,
                                color: Color(0xFF3B82F6),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Recurring Invoices are automatically created based on a configured schedule. Here you can configure the auto-charging option and the process of sending these invoices to your customers.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 2, 22, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int index = 0; index < _options.length; index++) ...[
                              _PreferenceTile(
                                option: _options[index],
                                isSelected:
                                    _preference == _options[index].value,
                                sendEmail: _sendEmail,
                                applyExcessPayments: _applyExcessPayments,
                                applyCreditNotes: _applyCreditNotes,
                                paymentSuccessAction: _paymentSuccessAction,
                                paymentFailureAction: _paymentFailureAction,
                                suspendOnFailure: _suspendOnFailure,
                                disableCardSaving: _disableCardSaving,
                                onOpenPreferencesPage: _openPreferencesPage,
                                onTap: () => setState(
                                  () => _preference = _options[index].value,
                                ),
                                onSendEmailChanged:
                                    _options[index].value == 'drafts'
                                        ? (value) {
                                            if (value != null) {
                                              setState(() => _sendEmail = value);
                                            }
                                          }
                                        : null,
                                onApplyExcessPaymentsChanged:
                                    _options[index].value == 'send'
                                        ? (value) {
                                            if (value != null) {
                                              setState(
                                                () => _applyExcessPayments =
                                                    value,
                                              );
                                            }
                                          }
                                        : null,
                                onApplyCreditNotesChanged:
                                    _options[index].value == 'send'
                                        ? (value) {
                                            if (value != null) {
                                              setState(
                                                () => _applyCreditNotes = value,
                                              );
                                            }
                                          }
                                        : null,
                                onPaymentSuccessActionChanged:
                                    _options[index].value == 'charge'
                                        ? (value) {
                                            if (value != null) {
                                              setState(
                                                () => _paymentSuccessAction =
                                                    value,
                                              );
                                            }
                                          }
                                        : null,
                                onPaymentFailureActionChanged:
                                    _options[index].value == 'charge'
                                        ? (value) {
                                            if (value != null) {
                                              setState(
                                                () => _paymentFailureAction =
                                                    value,
                                              );
                                            }
                                          }
                                        : null,
                                onSuspendOnFailureChanged:
                                    _options[index].value == 'charge'
                                        ? (value) {
                                            if (value != null) {
                                              setState(
                                                () => _suspendOnFailure =
                                                    value,
                                              );
                                            }
                                          }
                                        : null,
                                onDisableCardSavingChanged:
                                    _options[index].value == 'charge'
                                        ? (value) {
                                            if (value != null) {
                                              setState(
                                                () => _disableCardSaving =
                                                    value,
                                              );
                                            }
                                          }
                                        : null,
                              ),
                              if (index < _options.length - 1)
                                const SizedBox(height: 22),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF4E5),
                          border: Border(
                            top: BorderSide(color: Color(0xFFF3E4CC)),
                            bottom: BorderSide(color: Color(0xFFF3E4CC)),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Color(0xFF4B5563),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'The above changes are applicable only to this recurring invoice.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                child: Row(
                  children: [
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22A95E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceOption {
  final String value;
  final String title;
  final String description;

  const _PreferenceOption({
    required this.value,
    required this.title,
    required this.description,
  });
}

class _PreferenceTile extends StatelessWidget {
  final _PreferenceOption option;
  final bool isSelected;
  final bool sendEmail;
  final bool applyExcessPayments;
  final bool applyCreditNotes;
  final String paymentSuccessAction;
  final String paymentFailureAction;
  final bool suspendOnFailure;
  final bool disableCardSaving;
  final VoidCallback onOpenPreferencesPage;
  final VoidCallback onTap;
  final ValueChanged<bool?>? onSendEmailChanged;
  final ValueChanged<bool?>? onApplyExcessPaymentsChanged;
  final ValueChanged<bool?>? onApplyCreditNotesChanged;
  final ValueChanged<String?>? onPaymentSuccessActionChanged;
  final ValueChanged<String?>? onPaymentFailureActionChanged;
  final ValueChanged<bool?>? onSuspendOnFailureChanged;
  final ValueChanged<bool?>? onDisableCardSavingChanged;

  const _PreferenceTile({
    required this.option,
    required this.isSelected,
    required this.sendEmail,
    required this.applyExcessPayments,
    required this.applyCreditNotes,
    required this.paymentSuccessAction,
    required this.paymentFailureAction,
    required this.suspendOnFailure,
    required this.disableCardSaving,
    required this.onOpenPreferencesPage,
    required this.onTap,
    required this.onSendEmailChanged,
    required this.onApplyExcessPaymentsChanged,
    required this.onApplyCreditNotesChanged,
    required this.onPaymentSuccessActionChanged,
    required this.onPaymentFailureActionChanged,
    required this.onSuspendOnFailureChanged,
    required this.onDisableCardSavingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFD1D5DB),
                      width: isSelected ? 2 : 1.5,
                    ),
                    color: Colors.white,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF7C8698),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (option.value == 'drafts' && isSelected) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Notification Preferences',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onOpenPreferencesPage,
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.settings,
                                  size: 14,
                                  color: Color(0xFF3B82F6),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Change Preference',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: sendEmail,
                            onChanged: onSendEmailChanged,
                            activeColor: const Color(0xFF60A5FA),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Send email notifications when invoices are created as drafts.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (option.value == 'send' && isSelected) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreferenceCheckboxRow(
                      value: applyExcessPayments,
                      onChanged: onApplyExcessPaymentsChanged,
                      label:
                          'Apply customer\'s excess payments to their recurring invoices',
                    ),
                    const SizedBox(height: 10),
                    _PreferenceCheckboxRow(
                      value: applyCreditNotes,
                      onChanged: onApplyCreditNotesChanged,
                      label:
                          'Apply customer\'s credit notes to their recurring invoices',
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (option.value == 'charge' && isSelected) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        InkWell(
                          onTap: onOpenPreferencesPage,
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.settings,
                                  size: 14,
                                  color: Color(0xFF3B82F6),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Change Preference',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ChargeActionCard(
                            icon: LucideIcons.thumbsUp,
                            title: 'On Payment Success',
                            value: paymentSuccessAction,
                            items:
                                _RecurringInvoicePreferencesDialogState
                                    ._paymentSuccessActions,
                            onChanged: onPaymentSuccessActionChanged!,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ChargeActionCard(
                            icon: LucideIcons.thumbsDown,
                            title: 'On Payment Failure',
                            value: paymentFailureAction,
                            items:
                                _RecurringInvoicePreferencesDialogState
                                    ._paymentFailureActions,
                            onChanged: onPaymentFailureActionChanged!,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PreferenceCheckboxRow(
                      value: suspendOnFailure,
                      onChanged: onSuspendOnFailureChanged,
                      label: 'After failure, suspend the recurring invoice',
                    ),
                    const SizedBox(height: 12),
                    _PreferenceCheckboxRow(
                      value: disableCardSaving,
                      onChanged: onDisableCardSavingChanged,
                      label: 'Disable automatic saving of card details',
                      helperText:
                          'This option would disable the automatic selection of the option to save card details in the Customer Portal.',
                    ),
                    const SizedBox(height: 12),
                    _PreferenceCheckboxRow(
                      value: applyExcessPayments,
                      onChanged: onApplyExcessPaymentsChanged,
                      label:
                          'Apply customer\'s excess payments to their recurring invoices',
                    ),
                    const SizedBox(height: 12),
                    _PreferenceCheckboxRow(
                      value: applyCreditNotes,
                      onChanged: onApplyCreditNotesChanged,
                      label:
                          'Apply customer\'s credit notes to their recurring invoices',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text(
                'Note: Since your customer will be autocharged, payment reminder will be disabled.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreferenceCheckboxRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String label;
  final String? helperText;

  const _PreferenceCheckboxRow({
    required this.value,
    required this.onChanged,
    required this.label,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF60A5FA),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (helperText != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              helperText!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF7C8698),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChargeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _ChargeActionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF667085),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: SizedBox(
              height: 36,
              child: FormDropdown<String>(
                value: value,
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
