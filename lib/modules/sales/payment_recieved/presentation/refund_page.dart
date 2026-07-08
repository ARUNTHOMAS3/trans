import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/models/payment_record.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/providers/payment_recieves_provider.dart';

class RefundPage extends ConsumerStatefulWidget {
  final String paymentId;
  const RefundPage({super.key, required this.paymentId});

  @override
  ConsumerState<RefundPage> createState() => _RefundPageState();
}

class _RefundPageState extends ConsumerState<RefundPage> {
  final GlobalKey _datePickerKey = GlobalKey();
  
  late final TextEditingController _amountController;
  late final TextEditingController _refundedOnController;
  late final TextEditingController _referenceController;
  late final TextEditingController _descriptionController;

  String _fromAccount = 'Petty Cash';
  String _paymentMode = 'Cash';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _refundedOnController = TextEditingController(text: '05-06-2026');
    _referenceController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refundedOnController.dispose();
    _referenceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final formatted = intPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '\u20B9$formatted.$decPart';
  }

  Future<void> _selectDate() async {
    DateTime initial = DateTime.now();
    try {
      final parts = _refundedOnController.text.split('-');
      if (parts.length == 3) {
        initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}

    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: initial,
      targetKey: _datePickerKey,
    );
    if (picked != null) {
      final formatted = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      setState(() {
        _refundedOnController.text = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentRecievesProvider);
    final record = state.records.firstWhere(
      (r) => r.paymentNo == widget.paymentId,
      orElse: () => PaymentRecord(
        date: '',
        paymentNo: '',
        reference: '',
        customer: 'STARLEX HEALTH SERVICES & PRODUCTS PVT LTD',
        invoiceNo: '',
        mode: 'Cash',
        amount: 15000.0,
        unusedAmount: 15000.0,
      ),
    );

    final paymentModes = state.paymentModes;
    if (!_initialized) {
      _amountController.text = record.unusedAmount.toStringAsFixed(0);
      _paymentMode = state.defaultPaymentMode.isNotEmpty ? state.defaultPaymentMode : record.mode;
      _initialized = true;
    }

    if (!paymentModes.contains(_paymentMode)) {
      _paymentMode = state.defaultPaymentMode.isNotEmpty
          ? state.defaultPaymentMode
          : (paymentModes.isNotEmpty ? paymentModes.first : '');
    }

    final orgSystemId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Name',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.customer,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount Banner — full-width gray strip, no border
            Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: const Text(
                        'Amount*',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: CustomTextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      height: 40,
                      prefixWidget: const Text(
                        'INR',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      prefixBox: true,
                    ),
                  ),
                  const SizedBox(width: 40),
                  Text.rich(
                    TextSpan(
                      text: 'Balance :  ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                      children: [
                        TextSpan(
                          text: _fmt(record.unusedAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Layout Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column 1
                  Expanded(
                    child: Column(
                      children: [
                        _buildFormRow(
                          label: 'Refunded On*',
                          isLabelRed: true,
                          child: CustomTextField(
                            key: _datePickerKey,
                            controller: _refundedOnController,
                            readOnly: true,
                            onTap: _selectDate,
                            height: 40,
                            suffixWidget: const Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormRow(
                          label: 'Reference#',
                          child: CustomTextField(
                            controller: _referenceController,
                            height: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormRow(
                          label: 'Description',
                          child: CustomTextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            height: 80,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  // Column 2
                  Expanded(
                    child: Column(
                      children: [
                        _buildFormRow(
                          label: 'Payment Mode',
                          child: FormDropdown<String>(
                            value: _paymentMode,
                            items: paymentModes,
                            showSettings: true,
                            settingsLabel: 'Configure Payment Mode',
                            settingsIcon: Icons.add_circle_outline,
                            onSettingsTap: () {
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  return Dialog(
                                    backgroundColor: Colors.white,
                                    surfaceTintColor: Colors.transparent,
                                    alignment: Alignment.topCenter,
                                    insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 400,
                                        maxHeight: 720,
                                      ),
                                      child: _ConfigurePaymentModeDialog(
                                        initialModes: state.paymentModes,
                                        initialDefaultMode: state.defaultPaymentMode,
                                        onSave: (result) {
                                          ref.read(paymentRecievesProvider.notifier).updatePaymentModes(
                                            result.$1,
                                            result.$2,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            onChanged: (val) {
                              setState(() {
                                _paymentMode = val ?? 'Cash';
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormRow(
                          label: 'From Account*',
                          isLabelRed: true,
                          child: FormDropdown<String>(
                            value: _fromAccount,
                            items: const [
                              'Cash',
                              'Petty Cash',
                              'TESTINGS CASH',
                              'Undeposited Funds',
                              'Bank',
                              'Bandhan Bank',
                              'COMPANY BANK ACCOUNT',
                              'Zoho Payroll - Bank Account',
                              'TDS Payable',
                              'GST Payable',
                            ],
                            isItemEnabled: (item) => item != 'Cash' && item != 'Bank',
                            itemBuilder: (item, isSelected, isHovered) {
                              if (item == 'Cash' || item == 'Bank') {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                );
                              }
                              final bool isTestingCash = item == 'TESTINGS CASH';
                              final String displayLabel = isTestingCash ? '• TESTINGS CASH' : item;
                              final Color textColor = isHovered ? Colors.white : AppTheme.textPrimary;

                              return Container(
                                height: 40,
                                padding: EdgeInsets.only(
                                  left: isTestingCash ? 24.0 : 12.0,
                                  right: 12.0,
                                ),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textColor,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check,
                                        size: 16,
                                        color: isHovered ? Colors.white : const Color(0xFF2563EB),
                                      ),
                                  ],
                                ),
                              );
                            },
                            onChanged: (val) {
                              setState(() {
                                _fromAccount = val ?? 'Petty Cash';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 20),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    final amtText = _amountController.text.trim();
                    if (amtText.isEmpty) {
                      ZerpaiToast.error(context, 'Amount is required');
                      return;
                    }
                    final amtVal = double.tryParse(amtText);
                    if (amtVal == null || amtVal <= 0) {
                      ZerpaiToast.error(context, 'Please enter a valid amount');
                      return;
                    }
                    if (amtVal > record.unusedAmount) {
                      ZerpaiToast.error(
                        context,
                        'Refund amount cannot exceed remaining balance of ${_fmt(record.unusedAmount)}',
                      );
                      return;
                    }
                    ref.read(paymentRecievesProvider.notifier).refundRecord(record.paymentNo, amtVal);
                    ZerpaiToast.success(context, 'Refund processed successfully');
                    context.go('/$orgSystemId/sales/payments-received/${record.paymentNo}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(80, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    context.go('/$orgSystemId/sales/payments-received/${record.paymentNo}');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textBody,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    minimumSize: const Size(80, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textBody,
                    ),
                  ),
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormRow({
    String? label,
    Widget? labelWidget,
    bool isLabelRed = false,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: label == 'Description' ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 160,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 4.0),
            child: labelWidget ??
                Text(
                  label ?? '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isLabelRed ? FontWeight.w500 : FontWeight.normal,
                    color: isLabelRed ? const Color(0xFFDC2626) : AppTheme.textPrimary,
                  ),
                ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

// ── Configure Payment Mode Dialog ──────────────────────────────────────────────
class _ConfigurePaymentModeDialog extends StatefulWidget {
  final List<String> initialModes;
  final String initialDefaultMode;
  final ValueChanged<(List<String>, String)> onSave;

  const _ConfigurePaymentModeDialog({
    required this.initialModes,
    required this.initialDefaultMode,
    required this.onSave,
  });

  @override
  State<_ConfigurePaymentModeDialog> createState() => _ConfigurePaymentModeDialogState();
}

class _ConfigurePaymentModeDialogState extends State<_ConfigurePaymentModeDialog> {
  late List<String> _modes;
  late String _defaultMode;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _modes = List.from(widget.initialModes);
    _defaultMode = widget.initialDefaultMode;
    _controllers = _modes.map((m) => TextEditingController(text: m)).toList();
    _focusNodes = _modes.map((_) => FocusNode()).toList();

    for (final fn in _focusNodes) {
      fn.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    for (final fn in _focusNodes) {
      fn.removeListener(_onFocusChange);
      fn.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _addNewMode() {
    setState(() {
      _modes.add('');
      final ctrl = TextEditingController(text: '');
      _controllers.add(ctrl);
      final fn = FocusNode();
      _focusNodes.add(fn);
      fn.addListener(_onFocusChange);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        fn.requestFocus();
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 60,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _removeMode(int index) {
    setState(() {
      final removed = _modes[index];
      _modes.removeAt(index);
      _controllers.removeAt(index).dispose();
      _focusNodes.removeAt(index).dispose();

      if (_defaultMode == removed) {
        _defaultMode = _modes.isNotEmpty ? _modes.first : '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Configure Payment Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          // Scrollable list of payment modes
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(_modes.length, (index) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (index > 0) const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _PaymentModeRow(
                        label: _modes[index],
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        isDefault: _defaultMode == _modes[index] && _modes[index].isNotEmpty,
                        onSetDefault: () {
                          setState(() {
                            _modes[index] = _controllers[index].text.trim();
                            _defaultMode = _modes[index];
                          });
                        },
                        onDelete: () => _removeMode(index),
                        onChanged: (val) {
                          _modes[index] = val.trim();
                        },
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          // Add new mode button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addNewMode,
              icon: const Icon(Icons.add, size: 14),
              label: const Text(
                'Add New',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {
                  final List<String> finalModes = [];
                  for (int i = 0; i < _modes.length; i++) {
                    final txt = _controllers[i].text.trim();
                    if (txt.isNotEmpty && !finalModes.contains(txt)) {
                      finalModes.add(txt);
                    }
                  }

                  if (finalModes.isEmpty) {
                    ZerpaiToast.error(context, 'At least one payment mode is required');
                    return;
                  }

                  String finalDefault = _defaultMode;
                  if (!finalModes.contains(finalDefault)) {
                    finalDefault = finalModes.first;
                  }

                  widget.onSave((finalModes, finalDefault));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textBody,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textBody,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Payment Mode Row Widget ───────────────────────────────────────────────────
class _PaymentModeRow extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;
  final ValueChanged<String> onChanged;

  const _PaymentModeRow({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.isDefault,
    required this.onSetDefault,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_PaymentModeRow> createState() => _PaymentModeRowState();
}

class _PaymentModeRowState extends State<_PaymentModeRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final showActions = widget.isDefault || _isHovered || widget.focusNode.hasFocus;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  onChanged: widget.onChanged,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 160,
              alignment: Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: !showActions
                    ? const SizedBox.shrink()
                    : (widget.isDefault
                        ? Container(
                            key: const ValueKey('default'),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F772D),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Row(
                            key: const ValueKey('actions'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: widget.onSetDefault,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: const Color(0xFF6B7280),
                                ),
                                child: const Text(
                                  'Mark as Default',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: widget.onDelete,
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Color(0xFFDC2626),
                                  size: 16,
                                ),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                splashRadius: 12,
                              ),
                            ],
                          )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
