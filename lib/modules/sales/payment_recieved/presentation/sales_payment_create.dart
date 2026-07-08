// Generated file - merged payment pages
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart' as coa;
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/data/services/payments_received_api_service.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/models/payment_record.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/presentation/configure_payment_mode_dialog.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/presentation/payment_recieved_skeleton.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/providers/payment_recieves_provider.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/shared/models/account_node.dart' as shared;
import 'package:zerpai_erp/shared/utils/org_scope_resolver.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/customer_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/radio_group.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';


class SalesPaymentCreateScreen extends ConsumerStatefulWidget {
  final String? initialCustomerId;
  final String? fromInvoiceId;
  final String? cloneId;
  final String? editPaymentId;
  final VoidCallback? onClose;
  final bool showLayout;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onSaveSuccess;

  final int initialTab;

  const SalesPaymentCreateScreen({
    super.key,
    this.initialCustomerId,
    this.fromInvoiceId,
    this.cloneId,
    this.editPaymentId,
    this.onClose,
    this.showLayout = true,
    this.onCancel,
    this.onSaveSuccess,
    this.initialTab = 0,
  });

  @override
  ConsumerState<SalesPaymentCreateScreen> createState() => _SalesPaymentCreateScreenState();
}

class _SalesPaymentCreateScreenState extends ConsumerState<SalesPaymentCreateScreen> {
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    if (_activeTab == 0) {
      return _InvoicePaymentBody(
        initialCustomerId: widget.initialCustomerId,
        fromInvoiceId: widget.fromInvoiceId,
        cloneId: widget.cloneId,
        editPaymentId: widget.editPaymentId,
        onClose: widget.onClose,
        showLayout: widget.showLayout,
        onCancel: widget.onCancel,
        onSaveSuccess: widget.onSaveSuccess,
        onTabChanged: (tab) => setState(() => _activeTab = tab),
      );
    } else {
      return _CustomerAdvanceBody(
        initialCustomerId: widget.initialCustomerId,
        cloneId: widget.cloneId,
        editPaymentId: widget.editPaymentId,
        onClose: widget.onClose,
        showLayout: widget.showLayout,
        onCancel: widget.onCancel,
        onSaveSuccess: widget.onSaveSuccess,
        onTabChanged: (tab) => setState(() => _activeTab = tab),
      );
    }
  }
}




































class CustomerItem {
  final String id;
  final String name;
  final String code;
  final String? email;
  final String? secondaryCode;
  const CustomerItem({
    required this.id,
    required this.name,
    required this.code,
    this.email,
    this.secondaryCode,
  });
}

class _InvoicePaymentBody extends ConsumerStatefulWidget {
  final String? initialCustomerId;
  final String? fromInvoiceId;
  final String? cloneId;
  final VoidCallback? onClose;
  final String? editPaymentId;
  final bool showLayout;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onSaveSuccess;
  final ValueChanged<int>? onTabChanged;

  const _InvoicePaymentBody({
    super.key,
    this.initialCustomerId,
    this.fromInvoiceId,
    this.cloneId,
    this.onClose,
    this.editPaymentId,
    this.showLayout = true,
    this.onCancel,
    this.onSaveSuccess,
    this.onTabChanged,
  });

  @override
  ConsumerState<_InvoicePaymentBody> createState() => _InvoicePaymentBodyState();
}

class _InvoicePaymentBodyState extends ConsumerState<_InvoicePaymentBody> {
  // ── Tab state ────────────────────────────────────────────────────────────
  int _activeTab = 0;

  // ── Field state ──────────────────────────────────────────────────────────
  CustomerItem? _selectedCustomer;
  String? _selectedLocation = 'ZABNIX PRIVATE LIMITED';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bankChargesController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController(text: '305');
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final GlobalKey _datePickerKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();

  OverlayEntry? _filterOverlayEntry;
  final LayerLink _filterLayerLink = LayerLink();
  bool _isFilterOpen = false;

  // PAN popover
  OverlayEntry? _panOverlayEntry;
  final LayerLink _panLayerLink = LayerLink();
  final TextEditingController _panController = TextEditingController();

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  List<PlatformFile> _attachedFiles = [];

  // Per-row editable state for unpaid invoices table
  final Map<String, TextEditingController> _invoicePaymentControllers = {};
  final Map<String, DateTime> _invoiceReceivedDates = {};
  final Map<String, GlobalKey> _datePickerKeys = {};
  bool _showCustomerSidebar = false;

  SalesCustomer _getSalesCustomer(CustomerItem item, List<SalesCustomer> list) {
    return list.firstWhere(
      (c) => c.id == item.id,
      orElse: () => SalesCustomer(
        id: item.id,
        displayName: item.name,
        customerNumber: item.code,
        email: item.email ?? '',
        customerType: 'Individual',
        currencyId: 'INR',
        creditLimit: 0.0,
        paymentTerms: 'Net 360',
        enablePortal: false,
        priceList: 'Pricelist',
        gstTreatment: 'Unregistered Business',
        placeOfSupply: 'Kerala',
        taxPreference: 'Taxable',
        receivables: 0.0,
        contactPersons: [
          CustomerContact(
            salutation: 'Mr.',
            firstName: 'Althaf',
            lastName: 'M',
            email: 'althaf.m@example.com',
            mobilePhone: '+91 9876543210',
          ),
        ],
      ),
    );
  }

  static const List<String> _paymentModes = [
    'Bank Remittance',
    'Bank Transfer',
    'Card',
    'Cash',
    'Cheque',
    'Credit Card',
    'Debit Card',
    'Netbanking',
    'TESTING CASH',
    'UPI',
  ];
  late List<String> _dynamicPaymentModes = List.from(_paymentModes);
  static const List<String> _taxDeductOptions = ['No Tax deducted', 'Yes, TDS (Income Tax)'];
  String? _selectedPaymentMode = 'Cash';
  String _selectedTaxDeducted = 'No Tax deducted';
  // Holds the selected "Deposit To" account id from the chart of accounts tree.
  String? _selectedDepositToId;

  /// Backend uuid of the record being edited (null when creating or when the
  /// edited row is a local-only mock with no persisted id).
  String? _editRecordId;

  /// "Received full amount" checkbox state.
  bool _receivedFullAmount = false;

  /// Unpaid invoices for the selected customer, loaded from the backend. Each
  /// entry carries the real invoice `id` so allocations can be persisted.
  List<Map<String, String>> _unpaidInvoices = [];
  bool _loadingInvoices = false;

  List<Map<String, String>> get _selectedCustomerUnpaidInvoices =>
      _unpaidInvoices;

  /// Loads the selected customer's unpaid invoices into [_unpaidInvoices].
  Future<void> _loadUnpaidInvoices() async {
    final customer = _selectedCustomer;
    if (customer == null) {
      setState(() => _unpaidInvoices = []);
      return;
    }
    setState(() => _loadingInvoices = true);
    try {
      final list =
          await PaymentsReceivedApiService().getUnpaidInvoices(customer.id);
      if (!mounted) return;
      setState(() => _unpaidInvoices = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _unpaidInvoices = []);
    } finally {
      if (mounted) setState(() => _loadingInvoices = false);
    }
  }

  /// Total amount due across the selected customer's unpaid invoices.
  double get _fullAmountDue {
    double total = 0;
    for (final inv in _selectedCustomerUnpaidInvoices) {
      total +=
          double.tryParse((inv['amountDue'] ?? '0').replaceAll(',', '')) ?? 0;
    }
    return total;
  }
  String? _selectedTdsTaxAccount = 'Advance Tax';
  String? _selectedTransactionSeries = 'Default Transaction Series';

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    if (widget.editPaymentId != null) {
      final state = ref.read(paymentRecievesProvider);
      final recordIndex = state.records.indexWhere((r) => r.paymentNo == widget.editPaymentId);
      if (recordIndex >= 0) {
        final record = state.records[recordIndex];
        _editRecordId = record.id;
        _paymentController.text = record.paymentNo;
        _amountController.text = record.amount.toString();
        _referenceController.text = record.reference;
        _selectedPaymentMode = record.mode;
        _selectedLocation = record.location;
        try {
          final parts = record.date.split('-');
          if (parts.length == 3) {
            _selectedDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        } catch (_) {}
      }
    }
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _closeFilterOverlay();
    _closeAddPanOverlay();
    _amountController.dispose();
    _panController.dispose();
    _bankChargesController.dispose();
    _paymentController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    for (final c in _invoicePaymentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Customer Name field with dropdown, PAN info and details pill button
  Widget _customerField(List<CustomerItem> customerItems) {
    return SizedBox(
      width: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: FormDropdown<CustomerItem>(
              value: _selectedCustomer,
              items: customerItems,
              hint: 'Select Customer',
              itemHeight: 56.0,
              displayStringForValue: (item) => item.name,
              searchStringForValue: (item) => '${item.name} ${item.code} ${item.email ?? ''} ${item.secondaryCode ?? ''}',
              onChanged: (val) {
                setState(() {
                  _selectedCustomer = val;
                  // Reset allocation state for the new customer.
                  _receivedFullAmount = false;
                  _invoicePaymentControllers.clear();
                  _invoiceReceivedDates.clear();
                  _unpaidInvoices = [];
                });
                _loadUnpaidInvoices();
              },
              itemBuilder: (item, isSelected, isHovered) {
                final firstLetter = item.name.isNotEmpty ? item.name[0].toUpperCase() : '';
                final hasSubtitle = item.email != null || item.secondaryCode != null;
                
                final Color titleColor = isHovered ? Colors.white : AppTheme.textPrimary;
                final Color subtitleColor = isHovered ? Colors.white.withValues(alpha: 0.8) : AppTheme.textSecondary;
                final Color avatarBgColor = isHovered 
                    ? const Color(0xFFDBEAFE) 
                    : const Color(0xFFF3F4F6);
                final Color avatarTextColor = isHovered 
                    ? const Color(0xFF2563EB) 
                    : const Color(0xFF4B5563);
                final Color iconColor = isHovered ? Colors.white.withValues(alpha: 0.9) : AppTheme.textSecondary;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: avatarBgColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          firstLetter,
                          style: TextStyle(
                            color: avatarTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: titleColor,
                                ),
                                children: [
                                  TextSpan(text: item.name),
                                  TextSpan(
                                    text: ' | ${item.code}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: isHovered ? Colors.white.withValues(alpha: 0.9) : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasSubtitle) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (item.email != null) ...[
                                    Icon(
                                      Icons.mail_outline,
                                      size: 12,
                                      color: iconColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        item.email!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtitleColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (item.secondaryCode != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '|',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ],
                                  if (item.secondaryCode != null) ...[
                                    Icon(
                                      Icons.description_outlined,
                                      size: 12,
                                      color: iconColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        item.secondaryCode!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtitleColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'PAN: ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              CompositedTransformTarget(
                link: _panLayerLink,
                child: InkWell(
                  onTap: _showAddPanOverlay,
                  child: const Text(
                    'Add PAN',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddPanOverlay() {
    if (_panOverlayEntry != null) return;
    _panOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeAddPanOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _panLayerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: _AddPanPopoverContent(
                  controller: _panController,
                  onSave: (pan) {
                    _closeAddPanOverlay();
                    // TODO: persist PAN
                  },
                  onClose: _closeAddPanOverlay,
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_panOverlayEntry!);
  }

  void _closeAddPanOverlay() {
    if (_panOverlayEntry != null) {
      _panOverlayEntry!.remove();
      _panOverlayEntry = null;
    }
  }

  Widget _buildDetailsButton() {
    return Material(
      color: const Color(0xFF3D4F6E),
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _showCustomerSidebar = !_showCustomerSidebar;
          });
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${_selectedCustomer?.name ?? 'Customer'}'s Details",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfigurePreferencesDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 0, left: 12, right: 12),
              constraints: const BoxConstraints(maxWidth: 650),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _ConfigurePaymentPreferencesDialog(
                location: _selectedLocation ?? 'ZABNIX PRIVATE LIMITED',
                associatedSeries: _selectedTransactionSeries ?? 'Default Transaction Series',
                initialNextNumber: _paymentController.text,
                onSave: (nextNum) {
                  setState(() {
                    _paymentController.text = nextNum;
                  });
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final offsetAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut));
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// Payment # field with two columns: dropdown and input with settings cog icon
  Widget _paymentBar() {
    final isEditing = widget.editPaymentId != null;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FormDropdown<String>(
            value: _selectedTransactionSeries,
            items: const ['Default Transaction Series'],
            hint: 'Select Series',
            onChanged: isEditing ? (val) {} : (val) => setState(() => _selectedTransactionSeries = val),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: CustomTextField(
            controller: _paymentController,
            enabled: !isEditing,
            suffixWidget: isEditing
                ? null
                : ZTooltip(
                    message: 'Click here to configure auto-generation of payment numbers.',
                    direction: ZTooltipDirection.bottom,
                    child: InkWell(
                      onTap: _showConfigurePreferencesDialog,
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppTheme.primaryBlue,
                        size: 18,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Tax Deducted radio button group
  Widget _taxDeductedBar() {
    return ZerpaiRadioGroup<String>(
      options: _taxDeductOptions,
      current: _selectedTaxDeducted,
      onChanged: (val) => setState(() => _selectedTaxDeducted = val),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Text(
      required ? "$text*" : text,
      style: required
          ? AppTextStyles.labelRequired
          : AppTextStyles.label.copyWith(color: AppTheme.textPrimary),
    );
  }

  /// Builds the "Deposit To" tree from the live chart of accounts:
  /// three non-selectable heads (Cash / Bank / Liabilities) each holding the
  /// matching real accounts as selectable children. A head is shown only when
  /// it has at least one account. The `__account_type__` id prefix makes
  /// [AccountTreeDropdown] render the row as a bold heading.
  List<shared.AccountNode> _buildDepositToNodes(List<coa.AccountNode> roots) {
    const groupNames = {'assets', 'liabilities', 'equity', 'income', 'expenses'};

    final cash = <shared.AccountNode>[];
    final bank = <shared.AccountNode>[];
    final liabilities = <shared.AccountNode>[];

    void visit(coa.AccountNode account) {
      final name = account.name.trim();
      final isGroupHeader = groupNames.contains(name.toLowerCase());
      if (account.isActive && !account.isDeleted && !isGroupHeader) {
        final type = account.accountType.toLowerCase();
        final group = account.accountGroup.toLowerCase();
        final leaf = shared.AccountNode(id: account.id, name: name);
        if (type.contains('cash')) {
          cash.add(leaf);
        } else if (type.contains('bank')) {
          bank.add(leaf);
        } else if (group.contains('liabil')) {
          liabilities.add(leaf);
        }
      }
      for (final child in account.children) {
        visit(child);
      }
    }

    for (final root in roots) {
      visit(root);
    }

    int byName(shared.AccountNode a, shared.AccountNode b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    cash.sort(byName);
    bank.sort(byName);
    liabilities.sort(byName);

    final nodes = <shared.AccountNode>[];
    if (cash.isNotEmpty) {
      nodes.add(shared.AccountNode(
        id: '__account_type__Cash',
        name: 'Cash',
        selectable: false,
        children: cash,
      ));
    }
    if (bank.isNotEmpty) {
      nodes.add(shared.AccountNode(
        id: '__account_type__Bank',
        name: 'Bank',
        selectable: false,
        children: bank,
      ));
    }
    if (liabilities.isNotEmpty) {
      nodes.add(shared.AccountNode(
        id: '__account_type__Liabilities',
        name: 'Liabilities',
        selectable: false,
        children: liabilities,
      ));
    }
    return nodes;
  }

  Widget _fieldRow(Widget label, Widget field, {bool fixHeight = true, CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center, double? maxWidth = 400}) {
    Widget content = fixHeight
        ? SizedBox(
            height: 40,
            child: field,
          )
        : field;
    if (maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      );
    }
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        SizedBox(
          width: 180,
          child: Align(
            alignment: Alignment.centerLeft,
            child: label,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: content,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final dayStr = d.day.toString().padLeft(2, '0');
    final monthStr = d.month.toString().padLeft(2, '0');
    return '$dayStr-$monthStr-${d.year}';
  }

  Widget _buildDateRangeFilter() {
    final dateStr = _filterStartDate != null && _filterEndDate != null
        ? '${_formatDate(_filterStartDate!)} – ${_formatDate(_filterEndDate!)}'
        : 'Filter by Date Range';

    return CompositedTransformTarget(
      link: _filterLayerLink,
      child: InkWell(
        onTap: _showFilterOverlay,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down, size: 14, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterOverlay() {
    if (_filterOverlayEntry != null) return;

    setState(() {
      _isFilterOpen = true;
    });

    _filterOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeFilterOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _filterLayerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: _DateRangePopoverContent(
                  initialStartDate: _filterStartDate,
                  initialEndDate: _filterEndDate,
                  formatDate: _formatDate,
                  onApply: (start, end) {
                    setState(() {
                      _filterStartDate = start;
                      _filterEndDate = end;
                    });
                    _closeFilterOverlay();
                  },
                  onCancel: _closeFilterOverlay,
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_filterOverlayEntry!);

  }

  void _closeFilterOverlay() {
    if (_filterOverlayEntry != null) {
      _filterOverlayEntry!.remove();
      _filterOverlayEntry = null;
      setState(() {
        _isFilterOpen = false;
      });
    }
  }

  Widget _buildClearAppliedAmountLink() {
    return InkWell(
      onTap: () {
        setState(() {
          for (final controller in _invoicePaymentControllers.values) {
            controller.text = '0.00';
          }
        });
      },
      child: const Text(
        'Clear Applied Amount',
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _tabItem('Invoice Payment', isActive: _activeTab == 0, onTap: () => setState(() => _activeTab = 0)),
            const SizedBox(width: 24),
            _tabItem('Customer Advance', isActive: _activeTab == 1, onTap: () {
              widget.onTabChanged?.call(1);
            }),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
              onPressed: _cancel,
            ),
          ],
        ),
      ),
      shape: const Border(
        bottom: BorderSide(color: AppTheme.borderColor, width: 1),
      ),
    );
  }

  Widget _tabItem(String text, {required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(color: AppTheme.primaryBlue, width: 3),
                )
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────
  void _saveAsDraft() {
    _performSave('DRAFT');
  }

  void _saveAsPaid() {
    _performSave('PAID');
  }

  Future<void> _performSave(String status) async {
    if (_selectedCustomer == null) {
      ZerpaiToast.error(context, 'Please select a customer.');
      return;
    }
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    if (amount <= 0) {
      ZerpaiToast.error(context, 'Please enter a valid amount.');
      return;
    }
    if (_selectedDepositToId == null || _selectedDepositToId!.isEmpty) {
      ZerpaiToast.error(context, 'Please select a deposit to account.');
      return;
    }

    final paymentNo = _paymentController.text.isNotEmpty
        ? _paymentController.text
        : 'PR-000000';
    final bankCharges =
        double.tryParse(_bankChargesController.text.replaceAll(',', '')) ?? 0.0;

    final payload = <String, dynamic>{
      'customer_id': _selectedCustomer!.id,
      'payment_number': paymentNo,
      'payment_type': 'INVOICE_PAYMENT',
      'payment_date': _isoDate(_selectedDate),
      'deposit_account_id': _selectedDepositToId,
      'payment_mode': _selectedPaymentMode,
      'reference_number':
          _referenceController.text.isEmpty ? null : _referenceController.text,
      'amount_received': amount,
      'bank_charges': bankCharges,
      'is_tds_deducted': _selectedTaxDeducted != 'No Tax deducted',
      'status': status == 'PAID' ? 'paid' : 'draft',
      'notes': _notesController.text.isEmpty ? null : _notesController.text,
      'allocations': _buildAllocations(),
      'attachments': _buildAttachmentsPayload(),
    };

    final isEditing = widget.editPaymentId != null && _editRecordId != null;
    Map<String, dynamic> result;
    try {
      final api = PaymentsReceivedApiService();
      result = isEditing
          ? await api.updatePayment(_editRecordId!, payload)
          : await api.createPayment(payload);
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to save payment. Please try again.');
      return;
    }

    if (!mounted) return;

    final savedId = (result['id'] as String?) ?? _editRecordId;

    final record = PaymentRecord(
      id: savedId,
      date: _formatDate(_selectedDate),
      paymentNo: paymentNo,
      reference: _referenceController.text,
      customer: _selectedCustomer!.name,
      invoiceNo: 'INV-2026-001',
      mode: _selectedPaymentMode ?? 'Cash',
      amount: amount,
      unusedAmount: amount,
      status: status,
      location: _selectedLocation ?? 'ZABNIX PRIVATE LIMITED',
      paymentType: 'INVOICE_PAYMENT',
    );

    ref.read(paymentRecievesProvider.notifier).upsertRecord(record);
    ZerpaiToast.success(context, 'Payment saved successfully');

    if (widget.onSaveSuccess != null) {
      widget.onSaveSuccess!(savedId ?? '');
    } else if (widget.onClose != null) {
      widget.onClose!();
    } else {
      final orgId = resolveOrgSystemId(context);
      context.go('/$orgId/sales/payments-received/${record.paymentNo}');
    }
  }

  void _toggleFullAmount(bool value) {
    setState(() {
      _receivedFullAmount = value;
      if (value) {
        _amountController.text = _fullAmountDue.toStringAsFixed(2);
      } else {
        _amountController.clear();
      }
    });
  }

  /// "Received full amount (₹x)" checkbox shown under the Amount Received field.
  Widget _buildReceivedFullAmount() {
    final formatted = NumberFormat('#,##0.00', 'en_IN').format(_fullAmountDue);
    return InkWell(
      onTap: () => _toggleFullAmount(!_receivedFullAmount),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: _receivedFullAmount,
                onChanged: (v) => _toggleFullAmount(v ?? false),
                activeColor: AppTheme.primaryBlue,
                checkColor: Colors.white,
                side: const BorderSide(color: Color(0xFF9CA3AF), width: 1.5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Received full amount (₹$formatted)',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Collects invoice allocations (rows with a payment amount > 0) for the
  /// `payment_received_allocations` table.
  List<Map<String, dynamic>> _buildAllocations() {
    final result = <Map<String, dynamic>>[];
    for (final inv in _unpaidInvoices) {
      final id = inv['id'];
      if (id == null || id.isEmpty) continue;
      final allocated = double.tryParse(
            (_invoicePaymentControllers[id]?.text ?? '').replaceAll(',', ''),
          ) ??
          0.0;
      if (allocated <= 0) continue;
      final receivedOn = _invoiceReceivedDates[id] ?? _selectedDate;
      result.add({
        'invoice_id': id,
        'invoice_amount':
            double.tryParse((inv['invoiceAmount'] ?? '0').replaceAll(',', '')) ?? 0,
        'amount_due':
            double.tryParse((inv['amountDue'] ?? '0').replaceAll(',', '')) ?? 0,
        'allocated_amount': allocated,
        'payment_received_on': _isoDate(receivedOn),
      });
    }
    return result;
  }

  /// Builds the attachment payload from the picked files. Each entry carries the
  /// file bytes as base64 so the backend can upload them to R2 and link rows in
  /// `payment_received_attachments`. Files without loaded bytes are skipped.
  List<Map<String, dynamic>> _buildAttachmentsPayload() {
    final result = <Map<String, dynamic>>[];
    for (final f in _attachedFiles) {
      final bytes = f.bytes;
      if (bytes == null) continue;
      result.add({
        'file_name': f.name,
        'file_type': f.extension,
        'file_size': f.size,
        'data_base64': base64Encode(bytes),
      });
    }
    return result;
  }

  /// Backend `payment_date` column is a SQL `date` — send `YYYY-MM-DD`.
  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _cancel() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    final orgId = resolveOrgSystemId(context);
    context.goNamed('PaymentsReceived', pathParameters: {'orgSystemId': orgId});
  }

  // ── Bottom Section Builders ──────────────────────────────────────────────

Widget _buildUnpaidInvoicesTable() {
    final List<Map<String, String>> invoices = _selectedCustomerUnpaidInvoices;

    // Ensure controllers exist for each invoice row
    for (final inv in invoices) {
      final id = inv['id'] ?? inv['number'] ?? '';
      _invoicePaymentControllers.putIfAbsent(id, () => TextEditingController(text: '0'));
      _invoiceReceivedDates.putIfAbsent(id, () => _selectedDate);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.tableHeaderBg,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('DATE', style: AppTheme.tableHeader.copyWith(fontSize: 12))),
                  const VerticalDivider(width: 32, thickness: 1, color: AppTheme.borderColor),
                  Expanded(flex: 2, child: Text('INVOICE NUMBER', style: AppTheme.tableHeader.copyWith(fontSize: 12))),
                  const VerticalDivider(width: 32, thickness: 1, color: AppTheme.borderColor),
                  Expanded(flex: 2, child: Text('LOCATION', style: AppTheme.tableHeader.copyWith(fontSize: 12))),
                  const VerticalDivider(width: 32, thickness: 1, color: AppTheme.borderColor),
                  Expanded(flex: 2, child: Text('INVOICE AMOUNT', style: AppTheme.tableHeader.copyWith(fontSize: 12), textAlign: TextAlign.right)),
                  const VerticalDivider(width: 32, thickness: 1, color: AppTheme.borderColor),
                  Expanded(flex: 2, child: Text('AMOUNT DUE', style: AppTheme.tableHeader.copyWith(fontSize: 12), textAlign: TextAlign.right)),
                  const VerticalDivider(width: 32, thickness: 1, color: AppTheme.borderColor),
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('PAYMENT RECEIVED ON', style: AppTheme.tableHeader.copyWith(fontSize: 12)),
                        const SizedBox(width: 4),
                        ZTooltip(
                          message: 'Date on which the payment was received for this invoice.',
                          child: const Icon(Icons.info_outline, size: 14, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 32, thickness: 1, color: AppTheme.borderColor),
                  Expanded(flex: 2, child: Text('PAYMENT', style: AppTheme.tableHeader.copyWith(fontSize: 12), textAlign: TextAlign.right)),
                ],
              ),
            ),
          ),
          // Table Body
          if (_loadingInvoices)
            Container(
              height: 100,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (invoices.isEmpty)
            Container(
              height: 100,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: const Text(
                'There are no unpaid invoices associated with this customer.',
                style: TextStyle(fontSize: 13, color: Color(0xFFD97706), fontWeight: FontWeight.w500),
              ),
            )
          else
            ...invoices.map((inv) {
              final id = inv['id'] ?? inv['number'] ?? '';
              final payCtrl = _invoicePaymentControllers[id]!;
              final receivedDate = _invoiceReceivedDates[id]!;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // DATE column – date + due date
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inv['date'] ?? '-', style: AppTheme.tableCell.copyWith(fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              'Due Date: ${inv['dueDate'] ?? '-'}',
                              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 32, thickness: 1, color: AppTheme.borderColor),
                      // INVOICE NUMBER
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(inv['number'] ?? '-', style: AppTheme.tableCell.copyWith(fontSize: 12)),
                        ),
                      ),
                      const VerticalDivider(width: 32, thickness: 1, color: AppTheme.borderColor),
                      // LOCATION
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(inv['location'] ?? '-', style: AppTheme.tableCell.copyWith(fontSize: 12)),
                        ),
                      ),
                      const VerticalDivider(width: 32, thickness: 1, color: AppTheme.borderColor),
                      // INVOICE AMOUNT
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(inv['invoiceAmount'] ?? '-', style: AppTheme.tableCell.copyWith(fontSize: 12), textAlign: TextAlign.right),
                        ),
                      ),
                      const VerticalDivider(width: 32, thickness: 1, color: AppTheme.borderColor),
                      // AMOUNT DUE
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(inv['amountDue'] ?? '-', style: AppTheme.tableCell.copyWith(fontSize: 12), textAlign: TextAlign.right),
                        ),
                      ),
                      const VerticalDivider(width: 32, thickness: 1, color: AppTheme.borderColor),
                      // PAYMENT RECEIVED ON – inline date picker
                      Builder(
                        builder: (context) {
                          final dateKey = _datePickerKeys.putIfAbsent(id, () => GlobalKey());
                          return Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 150,
                                height: 34,
                                child: InkWell(
                                  key: dateKey,
                                  onTap: () async {
                                    final picked = await ZerpaiDatePicker.show(
                                      context,
                                      initialDate: receivedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                      targetKey: dateKey,
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _invoiceReceivedDates[id] = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.borderColor),
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.white,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _formatDate(receivedDate),
                                            style: AppTheme.tableCell.copyWith(fontSize: 12),
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const VerticalDivider(width: 32, thickness: 1, color: AppTheme.borderColor),
                      // PAYMENT – editable field + Pay in Full link
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 34,
                              child: TextField(
                                controller: payCtrl,
                                textAlign: TextAlign.right,
                                keyboardType: TextInputType.number,
                                style: AppTheme.tableCell.copyWith(fontSize: 12),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderSide: const BorderSide(color: AppTheme.borderColor),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: AppTheme.borderColor),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: AppTheme.primaryBlue),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () {
                                final dueStr = inv['amountDue']?.replaceAll(',', '') ?? '0';
                                final dueVal = double.tryParse(dueStr) ?? 0.0;
                                setState(() {
                                  payCtrl.text = dueVal.toStringAsFixed(2);
                                });
                              },
                              child: const Text(
                                'Pay in Full',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w500,
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
            }).toList(),
          // Footer Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('**List contains only SENT invoices', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Text('Total', style: AppTheme.tableHeader.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 40),
                    Text(
                      _invoicePaymentControllers.values
                          .fold<double>(0, (sum, c) => sum + (double.tryParse(c.text.replaceAll(',', '')) ?? 0))
                          .toStringAsFixed(2),
                      style: AppTheme.tableCell.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final double amountReceived = double.tryParse(_amountController.text) ?? 0.00;
    final double amountUsed = _invoicePaymentControllers.values
        .fold<double>(0, (sum, c) => sum + (double.tryParse(c.text.replaceAll(',', '')) ?? 0));
    final double amountRefunded = 0.00;
    final double excess = amountReceived - amountUsed - amountRefunded;

    final numberFormat = NumberFormat('#,##0.00');

    // Dynamic styling based on excess amount
    final bool isExcessZero = excess == 0.00;
    final Color cardBgColor = isExcessZero ? const Color(0xFFF9FAFB) : const Color(0xFFFFF7ED);
    final Color labelColor = isExcessZero ? AppTheme.textSecondary : const Color(0xFFB45309);
    final Color iconColor = isExcessZero ? const Color(0xFF9CA3AF) : const Color(0xFFD97706);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(8),
          border: isExcessZero ? Border.all(color: const Color(0xFFE5E7EB)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _summaryRow('Amount Received :', numberFormat.format(amountReceived)),
            const SizedBox(height: 8),
            _summaryRow('Amount used for Payments :', numberFormat.format(amountUsed)),
            const SizedBox(height: 8),
            _summaryRow('Amount Refunded :', numberFormat.format(amountRefunded)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: iconColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Amount in Excess:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  '₹ ${numberFormat.format(excess)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 80,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            children: [
              TextSpan(
                text: 'Notes ',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              TextSpan(
                text: '(Internal use. Not visible to customer)',
                style: TextStyle(color: Color(0xFFB45309)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _notesController,
          maxLines: 4,
          height: 80,
          hintText: '',
        ),
      ],
    );
  }

  Widget _buildAttachmentsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        FileUploadButton(
          files: _attachedFiles,
          onFilesChanged: (updated) {
            setState(() {
              _attachedFiles = updated;
            });
          },
        ),
        const SizedBox(height: 6),
        const Text(
          'You can upload a maximum of 5 files, 5MB each',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(invoicePaymentCustomersProvider);

    if (customersAsync.hasError) {
      final error = customersAsync.error;
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
                const SizedBox(height: 16),
                Text(
                  error.toString().contains('token') || error.toString().contains('Unauthorized')
                      ? 'Session expired. Please sign in again.'
                      : 'Error loading customers: ${error.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(invoicePaymentCustomersProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (customersAsync.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: const PaymentFormSkeleton(maxWidth: 1200),
      );
    }

    final invoiceCustomers = customersAsync.value ?? [];
    final customerItems = invoiceCustomers.map((c) => CustomerItem(
      id: c.id,
      name: c.name,
      code: c.code,
      email: c.email,
      secondaryCode: c.code,
    )).toList();

    // Full customer records (from the customers table) used only to enrich the
    // details sidebar; the dropdown above is sourced from invoice_master.
    final customersList =
        ref.watch(salesCustomersProvider).valueOrNull ?? const <SalesCustomer>[];

    if (_selectedCustomer == null && customerItems.isNotEmpty) {
      if (widget.initialCustomerId != null) {
        final matchIndex = customerItems.indexWhere((c) => c.id == widget.initialCustomerId);
        if (matchIndex >= 0) {
          _selectedCustomer = customerItems[matchIndex];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadUnpaidInvoices();
          });
        }
      } else if (widget.editPaymentId != null) {
        final state = ref.read(paymentRecievesProvider);
        final recordIndex = state.records.indexWhere((r) => r.paymentNo == widget.editPaymentId);
        if (recordIndex >= 0) {
          final record = state.records[recordIndex];
          final matchIndex = customerItems.indexWhere(
            (c) => c.name.toLowerCase() == record.customer.toLowerCase(),
          );
          if (matchIndex >= 0) {
            _selectedCustomer = customerItems[matchIndex];
            // Load the customer's unpaid invoices after this build completes.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadUnpaidInvoices();
            });
          }
        }
      }
    }

    // Live chart-of-accounts grouped into Cash / Bank / Liabilities heads.
    final depositToNodes =
        _buildDepositToNodes(ref.watch(chartOfAccountsProvider).roots);

    final bodyWidget = Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 0. Customer Name*
                    _fieldRow(
                      _label('Customer Name', required: true),
                      _customerField(customerItems),
                      fixHeight: false,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      maxWidth: null,
                    ),
                    const SizedBox(height: 18),

                    // Fields below are shown dimmed (half opacity) and
                    // non-interactive until a customer is selected.
                    Opacity(
                      opacity: _selectedCustomer == null ? 0.3 : 1.0,
                      child: IgnorePointer(
                        ignoring: _selectedCustomer == null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                // 2. Amount Received*
                _fieldRow(
                  _label('Amount Received', required: true),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 40,
                        child: _AmountField(
                          controller: _amountController,
                          enabled: !_receivedFullAmount,
                        ),
                      ),
                      if (_selectedCustomer != null && _fullAmountDue > 0) ...[
                        const SizedBox(height: 8),
                        _buildReceivedFullAmount(),
                      ],
                    ],
                  ),
                  fixHeight: false,
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
                const SizedBox(height: 18),

                // 3. Bank Charges (if any)
                _fieldRow(
                  _label('Bank Charges (if any)'),
                  CustomTextField(
                    controller: _bankChargesController,
                    hintText: '',
                    autoFocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Payment Date*
                _fieldRow(
                  _label('Payment Date', required: true),
                  _DatePickerField(
                    dateKey: _datePickerKey,
                    selectedDate: _selectedDate,
                    onDateChanged: (d) => setState(() => _selectedDate = d),
                    formatDate: _formatDate,
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Payment #*
                _fieldRow(
                  _label('Payment #', required: true),
                  _paymentBar(),
                ),
                const SizedBox(height: 18),

                // 6. Payment Mode
                _fieldRow(
                  _label('Payment Mode'),
                  FormDropdown<String>(
                    value: _selectedPaymentMode,
                    items: _dynamicPaymentModes,
                    hint: 'Select payment mode',
                    onChanged: (val) => setState(() => _selectedPaymentMode = val),
                    showSettings: true,
                    settingsLabel: 'Configure Payment Mode',
                    settingsIcon: Icons.add_circle,
                    onSettingsTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) {
                          return ConfigurePaymentModeDialog(
                            paymentModes: _dynamicPaymentModes,
                            defaultPaymentMode: _selectedPaymentMode ?? 'Cash',
                            onSave: (updated, newDefault) {
                              setState(() {
                                _dynamicPaymentModes = updated;
                                _selectedPaymentMode = newDefault;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // 7. Deposit To*
                _fieldRow(
                  _label('Deposit To', required: true),
                  AccountTreeDropdown(
                    value: _selectedDepositToId,
                    nodes: depositToNodes,
                    hint: 'Select an account',
                    height: 40,
                    borderRadius: BorderRadius.circular(6),
                    onChanged: (val) => setState(() => _selectedDepositToId = val),
                  ),
                  fixHeight: false,
                ),
                const SizedBox(height: 18),

                // 8. Reference#
                _fieldRow(
                  _label('Reference#'),
                  CustomTextField(
                    controller: _referenceController,
                    hintText: '',
                  ),
                ),
                const SizedBox(height: 18),

                // 9. Tax deducted?
                _fieldRow(
                  _label('Tax deducted?'),
                  _taxDeductedBar(),
                  fixHeight: false,
                ),
                if (_selectedTaxDeducted == 'Yes, TDS (Income Tax)') ...[
                  const SizedBox(height: 18),
                  _fieldRow(
                    _label('TDS Tax Account', required: true),
                    FormDropdown<String>(
                      value: _selectedTdsTaxAccount,
                      items: const ['Advance Tax', 'TDS Payable', 'Other Account'],
                      hint: 'Select TDS Tax Account',
                      onChanged: (val) => setState(() => _selectedTdsTaxAccount = val),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // 10. Unpaid Invoices Header with Date Range Filter & Clear Link
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Unpaid Invoices',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildDateRangeFilter(),
                    const Spacer(),
                    _buildClearAppliedAmountLink(),
                  ],
                ),
                const SizedBox(height: 16),

                // 11. Unpaid Invoices Table
                _buildUnpaidInvoicesTable(),
                const SizedBox(height: 24),

                // 12. Amount Summary Card
                _buildSummaryCard(),
                const SizedBox(height: 24),

                // 13. Notes Field
                _buildNotesField(),
                const SizedBox(height: 20),

                // 14. Attachments Field
                _buildAttachmentsField(),
                const SizedBox(height: 20),

                // 15. Additional Fields Info
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    children: [
                      TextSpan(
                        text: 'Additional Fields: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: 'Start adding custom fields for your payments received by going to ',
                      ),
                      TextSpan(
                        text: 'Settings → Sales → Payments Received',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
                if (_isFilterOpen) const SizedBox(height: 250),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Details button pinned to the far right of the viewport
          if (_selectedCustomer != null)
            Positioned(
              top: 10,
              right: 0,
              child: _buildDetailsButton(),
            ),
          if (_showCustomerSidebar && _selectedCustomer != null)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: CustomerDetailsSidebar(
                customer: _getSalesCustomer(_selectedCustomer!, customersList),
                onClose: () => setState(() => _showCustomerSidebar = false),
              ),
            ),
        ],
      );

      final actionContainer = Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderColor)),
        ),
        child: _ActionButtons(
          onDraft: _saveAsDraft,
          onPaid: _saveAsPaid,
          onCancel: _cancel,
          paidEnabled: _selectedCustomer != null,
        ),
      );

      if (!widget.showLayout) {
        return Column(
          children: [
            Expanded(child: bodyWidget),
            actionContainer,
          ],
        );
      }

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: bodyWidget,
        bottomNavigationBar: actionContainer,
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Amount field with "INR" prefix box (styled with red border for validation state)
// ─────────────────────────────────────────────────────────────────────────────
class _AmountField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;

  const _AmountField({required this.controller, this.enabled = true});

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    // Show red/coral error border if non-numeric string (e.g. 'ASD') is entered
    final bool hasError = double.tryParse(widget.controller.text) == null &&
        widget.controller.text.isNotEmpty;

    final borderColor = hasError
        ? AppTheme.errorRed
        : (_isFocused ? AppTheme.primaryBlueDark : AppTheme.borderColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // INR prefix chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              border: Border(
                right: BorderSide(color: borderColor, width: 1),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                bottomLeft: Radius.circular(5),
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'INR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          // Input
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) =>
                  setState(() => _isFocused = hasFocus),
              child: TextField(
                controller: widget.controller,
                readOnly: !widget.enabled,
                enabled: widget.enabled,
                keyboardType: TextInputType.text,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  hoverColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatefulWidget {
  final GlobalKey dateKey;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final String Function(DateTime) formatDate;

  const _DatePickerField({
    required this.dateKey,
    required this.selectedDate,
    required this.onDateChanged,
    required this.formatDate,
  });

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        key: widget.dateKey,
        onTap: () async {
          final selected = await ZerpaiDatePicker.show(
            context,
            initialDate: widget.selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            targetKey: widget.dateKey,
          );
          if (selected != null) {
            widget.onDateChanged(selected);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _isHovered ? AppTheme.infoBlue : AppTheme.borderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            widget.formatDate(widget.selectedDate),
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons row
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final VoidCallback onDraft;
  final VoidCallback onPaid;
  final VoidCallback onCancel;
  final bool paidEnabled;

  const _ActionButtons({
    required this.onDraft,
    required this.onPaid,
    required this.onCancel,
    this.paidEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ZButton.secondary(
          label: 'Save as Draft',
          onPressed: onDraft,
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: paidEnabled ? onPaid : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successGreen, // brand green
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFA7F3D0),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text(
            'Save as Paid',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ZButton.secondary(
          label: 'Cancel',
          onPressed: onCancel,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Configure Payment Number Preferences Dialog (as shown in screenshot)
// ─────────────────────────────────────────────────────────────────────────────
class _ConfigurePaymentPreferencesDialog extends StatefulWidget {
  final String location;
  final String associatedSeries;
  final String initialNextNumber;
  final ValueChanged<String> onSave;

  const _ConfigurePaymentPreferencesDialog({
    required this.location,
    required this.associatedSeries,
    required this.initialNextNumber,
    required this.onSave,
  });

  @override
  State<_ConfigurePaymentPreferencesDialog> createState() =>
      _ConfigurePaymentPreferencesDialogState();
}

class _ConfigurePaymentPreferencesDialogState
    extends State<_ConfigurePaymentPreferencesDialog> {
  int _mode = 0; // 0: Auto-generate, 1: Manual
  final TextEditingController _prefixController = TextEditingController();
  late final TextEditingController _nextNumberController;
  bool _restartFiscalYear = false;

  @override
  void initState() {
    super.initState();
    _nextNumberController = TextEditingController(text: widget.initialNextNumber);
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _nextNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Bar
        Container(
           padding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 16),
           decoration: const BoxDecoration(
             color: Color(0xFFF9FAFB),
             border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              const Text(
                'Configure Payment Number Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.location,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Associated Series',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.associatedSeries,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 16),

              const Text(
                'Auto-generating payment numbers can save your time. Would you like to change your current setting?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Option 1: Auto-generate
              RadioScope<int>(
                value: _mode,
                onChanged: (val) => setState(() => _mode = val),
                child: Row(
                  children: [
                    RadioGroupItem<int>(
                      value: 0,
                      activeColor: AppTheme.primaryBlue,
                    ),
                    const Text(
                      'Auto-generate payment numbers',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),

              if (_mode == 0) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Prefix
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prefix',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 36,
                                  child: CustomTextField(
                                    controller: _prefixController,
                                    suffixWidget: const Icon(
                                      Icons.add_circle_outline,
                                      color: AppTheme.primaryBlue,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Next Number
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Next Number',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 36,
                                  child: CustomTextField(
                                    controller: _nextNumberController,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Fiscal Year Checkbox
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _restartFiscalYear,
                              activeColor: AppTheme.primaryBlue,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _restartFiscalYear = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Restart numbering for payments at the start of each fiscal year.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Option 2: Manual
              RadioScope<int>(
                value: _mode,
                onChanged: (val) => setState(() => _mode = val),
                child: Row(
                  children: [
                    RadioGroupItem<int>(
                      value: 1,
                      activeColor: AppTheme.primaryBlue,
                    ),
                    const Text(
                      'Add payment number manually for this payment',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave(_mode == 0 ? _nextNumberController.text : '');
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // green
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
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
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textBody,
                      side: const BorderSide(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
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
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom popover content for Date Range Filter
// ─────────────────────────────────────────────────────────────────────────────
class _DateRangePopoverContent extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String Function(DateTime) formatDate;
  final Function(DateTime?, DateTime?) onApply;
  final VoidCallback onCancel;

  const _DateRangePopoverContent({
    required this.initialStartDate,
    required this.initialEndDate,
    required this.formatDate,
    required this.onApply,
    required this.onCancel,
  });

  @override
  State<_DateRangePopoverContent> createState() => _DateRangePopoverContentState();
}

class _DateRangePopoverContentState extends State<_DateRangePopoverContent> {
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  final GlobalKey _startKey = GlobalKey();
  final GlobalKey _endKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tempStartDate = widget.initialStartDate;
    _tempEndDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FilterDatePickerField(
                  dateKey: _startKey,
                  selectedDate: _tempStartDate,
                  placeholder: 'dd-MM-yyyy',
                  onDateChanged: (d) => setState(() => _tempStartDate = d),
                  formatDate: widget.formatDate,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('-', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              Expanded(
                child: _FilterDatePickerField(
                  dateKey: _endKey,
                  selectedDate: _tempEndDate,
                  placeholder: 'dd-MM-yyyy',
                  onDateChanged: (d) => setState(() => _tempEndDate = d),
                  formatDate: widget.formatDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Note: If you\'ve entered a Payment amount for any unpaid invoices, those invoices will continue to be shown at the top of the list, irrespective of the Date Range filter that you apply.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  widget.onApply(_tempStartDate, _tempEndDate);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // success green
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Apply Filter',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textBody,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textBody,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempStartDate = null;
                    _tempEndDate = null;
                  });
                },
                child: const Text(
                  'Clear Selection',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────────────────────────────────────
// Date picker trigger field inside Date Range filter popover
// ─────────────────────────────────────────────────────────────────────────────
class _FilterDatePickerField extends StatefulWidget {
  final GlobalKey dateKey;
  final DateTime? selectedDate;
  final String placeholder;
  final ValueChanged<DateTime> onDateChanged;
  final String Function(DateTime) formatDate;

  const _FilterDatePickerField({
    required this.dateKey,
    required this.selectedDate,
    required this.placeholder,
    required this.onDateChanged,
    required this.formatDate,
  });

  @override
  State<_FilterDatePickerField> createState() => _FilterDatePickerFieldState();
}

class _FilterDatePickerFieldState extends State<_FilterDatePickerField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        key: widget.dateKey,
        onTap: () async {
          final selected = await ZerpaiDatePicker.show(
            context,
            initialDate: widget.selectedDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            targetKey: widget.dateKey,
          );
          if (selected != null) {
            widget.onDateChanged(selected);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _isHovered ? AppTheme.infoBlue : AppTheme.borderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            widget.selectedDate != null ? widget.formatDate(widget.selectedDate!) : widget.placeholder,
            style: TextStyle(
              fontSize: 13,
              color: widget.selectedDate != null ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add PAN Popover Content
// ─────────────────────────────────────────────────────────────────────────────
class _AddPanPopoverContent extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSave;
  final VoidCallback onClose;

  const _AddPanPopoverContent({
    required this.controller,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<_AddPanPopoverContent> createState() => _AddPanPopoverContentState();
}

class _AddPanPopoverContentState extends State<_AddPanPopoverContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'Add PAN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(4),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // PAN input
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: widget.controller,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppTheme.primaryBlue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Info note
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, size: 13, color: AppTheme.textSecondary),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'This PAN will be updated in contact and further transactions.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Save button
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () => widget.onSave(widget.controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerAdvanceBody extends ConsumerStatefulWidget {
  final String? initialCustomerId;
  final String? cloneId;
  final String? editPaymentId;
  final VoidCallback? onClose;
  final bool showLayout;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onSaveSuccess;
  final ValueChanged<int>? onTabChanged;

  const _CustomerAdvanceBody({
    super.key,
    this.initialCustomerId,
    this.cloneId,
    this.editPaymentId,
    this.onClose,
    this.showLayout = true,
    this.onCancel,
    this.onSaveSuccess,
    this.onTabChanged,
  });

  @override
  ConsumerState<_CustomerAdvanceBody> createState() => _CustomerAdvanceBodyState();
}

class _CustomerAdvanceBodyState extends ConsumerState<_CustomerAdvanceBody> {
  static const List<String> _paymentModes = [
    'Bank Remittance',
    'Bank Transfer',
    'Card',
    'Cash',
    'Cheque',
    'Credit Card',
    'Debit Card',
    'Netbanking',
    'TESTING CASH',
    'UPI',
  ];
  late List<String> _dynamicPaymentModes = List.from(_paymentModes);

  // ── Field state ──────────────────────────────────────────────────────────
  CustomerItem? _selectedCustomer;
  String? _placeOfSupply = '[KL] - Kerala';
  String? _selectedLocation = 'ZABNIX PRIVATE LIMITED';
  String? _selectedTax = 'Select a Tax';
  String? _selectedSeries = 'Default Transaction Series';
  String? _selectedPaymentMode = 'Cash';
  // Holds the selected "Deposit To" account id from the chart of accounts tree.
  String? _selectedDepositToId;

  /// Backend uuid of the record being edited (null when creating or when the
  /// edited row is a local-only mock with no persisted id).
  String? _editRecordId;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bankChargesController = TextEditingController();
  final TextEditingController _paymentNumberController = TextEditingController(text: '305');
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _gstTreatmentController = TextEditingController(text: 'Unregistered Business');
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final GlobalKey _datePickerKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  // PAN popover state
  OverlayEntry? _panOverlayEntry;
  final LayerLink _panLayerLink = LayerLink();

  List<PlatformFile> _attachedFiles = [];
  bool _showCustomerSidebar = false;

  SalesCustomer _getSalesCustomer(CustomerItem item, List<SalesCustomer> list) {
    return list.firstWhere(
      (c) => c.id == item.id,
      orElse: () => SalesCustomer(
        id: item.id,
        displayName: item.name,
        customerNumber: item.code,
        email: item.email ?? '',
        customerType: 'Individual',
        currencyId: 'INR',
        creditLimit: 0.0,
        paymentTerms: 'Net 360',
        enablePortal: false,
        priceList: 'Pricelist',
        gstTreatment: 'Unregistered Business',
        placeOfSupply: 'Kerala',
        taxPreference: 'Taxable',
        receivables: 0.0,
        contactPersons: [
          CustomerContact(
            salutation: 'Mr.',
            firstName: 'Althaf',
            lastName: 'M',
            email: 'althaf.m@example.com',
            mobilePhone: '+91 9876543210',
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.editPaymentId != null) {
      final state = ref.read(paymentRecievesProvider);
      final recordIndex =
          state.records.indexWhere((r) => r.paymentNo == widget.editPaymentId);
      if (recordIndex >= 0) {
        final record = state.records[recordIndex];
        _editRecordId = record.id;
        _paymentNumberController.text = record.paymentNo;
        _amountController.text = record.amount.toString();
        _referenceController.text = record.reference;
        _selectedPaymentMode = record.mode;
        _selectedLocation = record.location;
        try {
          final parts = record.date.split('-');
          if (parts.length == 3) {
            _selectedDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _closeAddPanOverlay();
    _descriptionController.dispose();
    _amountController.dispose();
    _bankChargesController.dispose();
    _paymentNumberController.dispose();
    _panController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final dayStr = d.day.toString().padLeft(2, '0');
    final monthStr = d.month.toString().padLeft(2, '0');
    return '$dayStr-$monthStr-${d.year}';
  }

  /// Backend `payment_date` column is a SQL `date` — send `YYYY-MM-DD`.
  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _performSave(String status) async {
    if (_selectedCustomer == null) {
      ZerpaiToast.error(context, 'Please select a customer.');
      return;
    }
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    if (amount <= 0) {
      ZerpaiToast.error(context, 'Please enter a valid amount.');
      return;
    }
    if (_selectedDepositToId == null || _selectedDepositToId!.isEmpty) {
      ZerpaiToast.error(context, 'Please select a deposit to account.');
      return;
    }

    final paymentNo = _paymentNumberController.text.isNotEmpty
        ? _paymentNumberController.text
        : 'PR-000000';
    final bankCharges =
        double.tryParse(_bankChargesController.text.replaceAll(',', '')) ?? 0.0;

    final payload = <String, dynamic>{
      'customer_id': _selectedCustomer!.id,
      'payment_number': paymentNo,
      'payment_type': 'CUSTOMER_ADVANCE',
      'payment_date': _isoDate(_selectedDate),
      'deposit_account_id': _selectedDepositToId,
      'place_of_supply': _placeOfSupply,
      'description_of_supply':
          _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'payment_mode': _selectedPaymentMode,
      'reference_number':
          _referenceController.text.isEmpty ? null : _referenceController.text,
      'amount_received': amount,
      'bank_charges': bankCharges,
      'excess_amount': amount,
      'status': status == 'PAID' ? 'paid' : 'draft',
      'notes': _notesController.text.isEmpty ? null : _notesController.text,
    };

    final isEditing = widget.editPaymentId != null && _editRecordId != null;
    Map<String, dynamic> result;
    try {
      final api = PaymentsReceivedApiService();
      result = isEditing
          ? await api.updatePayment(_editRecordId!, payload)
          : await api.createPayment(payload);
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to save payment. Please try again.');
      return;
    }

    if (!mounted) return;

    final savedId = (result['id'] as String?) ?? _editRecordId;

    final record = PaymentRecord(
      id: savedId,
      date: _formatDate(_selectedDate),
      paymentNo: paymentNo,
      reference: _referenceController.text,
      customer: _selectedCustomer!.name,
      invoiceNo: '',
      mode: _selectedPaymentMode ?? 'Cash',
      amount: amount,
      unusedAmount: amount,
      status: status,
      location: _selectedLocation ?? 'ZABNIX PRIVATE LIMITED',
      paymentType: 'CUSTOMER_ADVANCE',
    );

    ref.read(paymentRecievesProvider.notifier).upsertRecord(record);
    ZerpaiToast.success(context, 'Payment saved successfully');

    if (widget.onSaveSuccess != null) {
      widget.onSaveSuccess!(savedId ?? '');
      return;
    }
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    final orgId = resolveOrgSystemId(context);
    context.go('/$orgId/sales/payments-received/${record.paymentNo}');
  }

  /// Builds the "Deposit To" tree from the live chart of accounts:
  /// three non-selectable heads (Cash / Bank / Liabilities) each holding the
  /// matching real accounts as selectable children. A head is shown only when
  /// it has at least one account. The `__account_type__` id prefix makes
  /// [AccountTreeDropdown] render the row as a bold heading.
  List<shared.AccountNode> _buildDepositToNodes(List<coa.AccountNode> roots) {
    const groupNames = {'assets', 'liabilities', 'equity', 'income', 'expenses'};

    final cash = <shared.AccountNode>[];
    final bank = <shared.AccountNode>[];
    final liabilities = <shared.AccountNode>[];

    void visit(coa.AccountNode account) {
      final name = account.name.trim();
      final isGroupHeader = groupNames.contains(name.toLowerCase());
      if (account.isActive && !account.isDeleted && !isGroupHeader) {
        final type = account.accountType.toLowerCase();
        final group = account.accountGroup.toLowerCase();
        final leaf = shared.AccountNode(id: account.id, name: name);
        if (type.contains('cash')) {
          cash.add(leaf);
        } else if (type.contains('bank')) {
          bank.add(leaf);
        } else if (group.contains('liabil')) {
          liabilities.add(leaf);
        }
      }
      for (final child in account.children) {
        visit(child);
      }
    }

    for (final root in roots) {
      visit(root);
    }

    int byName(shared.AccountNode a, shared.AccountNode b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    cash.sort(byName);
    bank.sort(byName);
    liabilities.sort(byName);

    final nodes = <shared.AccountNode>[];
    if (cash.isNotEmpty) {
      nodes.add(shared.AccountNode(
        id: '__account_type__Cash',
        name: 'Cash',
        selectable: false,
        children: cash,
      ));
    }
    if (bank.isNotEmpty) {
      nodes.add(shared.AccountNode(
        id: '__account_type__Bank',
        name: 'Bank',
        selectable: false,
        children: bank,
      ));
    }
    if (liabilities.isNotEmpty) {
      nodes.add(shared.AccountNode(
        id: '__account_type__Liabilities',
        name: 'Liabilities',
        selectable: false,
        children: liabilities,
      ));
    }
    return nodes;
  }

  void _showAddPanOverlay() {
    if (_panOverlayEntry != null) return;
    _panOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeAddPanOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _panLayerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: _AdvAddPanPopoverContent(
                  controller: _panController,
                  onSave: (pan) {
                    _closeAddPanOverlay();
                    // TODO: persist PAN
                  },
                  onClose: _closeAddPanOverlay,
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_panOverlayEntry!);
  }

  void _closeAddPanOverlay() {
    if (_panOverlayEntry != null) {
      _panOverlayEntry!.remove();
      _panOverlayEntry = null;
    }
  }

  void _showConfigurePreferencesDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 0, left: 12, right: 12),
              constraints: const BoxConstraints(maxWidth: 650),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _AdvConfigurePaymentPreferencesDialog(
                location: _selectedLocation ?? 'ZABNIX PRIVATE LIMITED',
                associatedSeries: _selectedSeries ?? 'Default Transaction Series',
                initialNextNumber: _paymentNumberController.text,
                onSave: (nextNum) {
                  setState(() {
                    _paymentNumberController.text = nextNum;
                  });
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final offsetAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut));
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  void _showGstTreatmentDialog() {
    showConfigureTaxPreferencesDialog(context);
  }

void showConfigureTaxPreferencesDialog(BuildContext context) {
  String gstTreatment = "Unregistered Business";
  bool makePermanent = false;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            child: Container(
              width: 300,
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Configure Tax Preferences',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFFE74C3C),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GST Treatment',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          child: DropdownButtonFormField<String>(
                            value: gstTreatment,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "Unregistered Business",
                                child: Text("Unregistered Business"),
                              ),
                              DropdownMenuItem(
                                value: "Registered Business",
                                child: Text("Registered Business"),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                gstTreatment = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Make it permanent?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          value: makePermanent,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'Use these settings for all future\ntransactions of this customer.',
                            style: TextStyle(fontSize: 14),
                          ),
                          onChanged: (value) {
                            setState(() {
                              makePermanent = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      border: Border(
                        top: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 34,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF22C55E),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: handle update logic
                            },
                            child: const Text("Update"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 34,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}




  Widget _tabItem(String text, {required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(color: AppTheme.primaryBlue, width: 3),
                )
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _tabItem('Invoice Payment', isActive: false, onTap: () {
              final orgId = resolveOrgSystemId(context);
              context.goNamed(AppRoutes.salesPaymentsReceivedCreate, pathParameters: {'orgSystemId': orgId});
            }),
            const SizedBox(width: 24),
            _tabItem('Customer Advance', isActive: true, onTap: () {}),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
              onPressed: () {
                final orgId = resolveOrgSystemId(context);
                context.goNamed(AppRoutes.salesPaymentsReceived, pathParameters: {'orgSystemId': orgId});
              },
            ),
          ],
        ),
      ),
      shape: const Border(
        bottom: BorderSide(color: AppTheme.borderColor, width: 1),
      ),
    );
  }

  Widget _buildDetailsButton() {
    return Material(
      color: const Color(0xFF3D4F6E),
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _showCustomerSidebar = !_showCustomerSidebar;
          });
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${_selectedCustomer?.name ?? 'Customer'}'s Details",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customerField(List<CustomerItem> customerItems) {
    return SizedBox(
      width: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: FormDropdown<CustomerItem>(
              value: _selectedCustomer,
              items: customerItems,
              hint: 'Select Customer',
              itemHeight: 56.0,
              displayStringForValue: (item) => item.name,
              searchStringForValue: (item) => '${item.name} ${item.code} ${item.email ?? ''} ${item.secondaryCode ?? ''}',
              onChanged: (val) => setState(() => _selectedCustomer = val),
              itemBuilder: (item, isSelected, isHovered) {
                final firstLetter = item.name.isNotEmpty ? item.name[0].toUpperCase() : '';
                final hasSubtitle = item.email != null || item.secondaryCode != null;
                
                final Color titleColor = isHovered ? Colors.white : AppTheme.textPrimary;
                final Color subtitleColor = isHovered ? Colors.white.withValues(alpha: 0.8) : AppTheme.textSecondary;
                final Color avatarBgColor = isHovered 
                    ? const Color(0xFFDBEAFE) 
                    : const Color(0xFFF3F4F6);
                final Color avatarTextColor = isHovered 
                    ? const Color(0xFF2563EB) 
                    : const Color(0xFF4B5563);
                final Color iconColor = isHovered ? Colors.white.withValues(alpha: 0.9) : AppTheme.textSecondary;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: avatarBgColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          firstLetter,
                          style: TextStyle(
                            color: avatarTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: titleColor,
                                ),
                                children: [
                                  TextSpan(text: item.name),
                                  TextSpan(
                                    text: ' | ${item.code}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: isHovered ? Colors.white.withValues(alpha: 0.9) : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasSubtitle) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (item.email != null) ...[
                                    Icon(
                                      Icons.mail_outline,
                                      size: 12,
                                      color: iconColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        item.email!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtitleColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (item.secondaryCode != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '|',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ],
                                  if (item.secondaryCode != null) ...[
                                    Icon(
                                      Icons.description_outlined,
                                      size: 12,
                                      color: iconColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        item.secondaryCode!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtitleColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'PAN: ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              CompositedTransformTarget(
                link: _panLayerLink,
                child: InkWell(
                  onTap: _showAddPanOverlay,
                  child: const Text(
                    'Add PAN',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'GST Treatment: ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            Text(
              _gstTreatmentController.text,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
              const SizedBox(width: 4),
              InkWell(
                onTap: _showGstTreatmentDialog,
                child: const Icon(
                  Icons.edit_outlined,
                  size: 12,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentBar() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FormDropdown<String>(
            value: _selectedSeries,
            items: const ['Default Transaction Series'],
            hint: 'Select Series',
            onChanged: (val) => setState(() => _selectedSeries = val),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: CustomTextField(
            controller: _paymentNumberController,
            suffixWidget: ZTooltip(
              message: 'Click here to configure auto-generation of payment numbers.',
              direction: ZTooltipDirection.bottom,
              child: InkWell(
                onTap: _showConfigurePreferencesDialog,
                child: const Icon(
                  Icons.settings_outlined,
                  color: AppTheme.primaryBlue,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text, {bool required = false, bool isDashed = false}) {
    final baseStyle = required
        ? AppTextStyles.labelRequired
        : AppTextStyles.label.copyWith(color: AppTheme.textPrimary);

    if (isDashed) {
      return Text(
        required ? "$text*" : text,
        style: baseStyle.copyWith(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dashed,
          decorationColor: Colors.grey,
        ),
      );
    }
    return Text(
      required ? "$text*" : text,
      style: baseStyle,
    );
  }

  Widget _fieldRow(Widget label, Widget field, {bool fixHeight = true, CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center, double? maxWidth = 400}) {
    Widget content = fixHeight
        ? SizedBox(
            height: 40,
            child: field,
          )
        : field;
    if (maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      );
    }
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        SizedBox(
          width: 180,
          child: Align(
            alignment: Alignment.centerLeft,
            child: label,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: content,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);

    if (customersAsync.hasError) {
      final error = customersAsync.error;
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
                const SizedBox(height: 16),
                Text(
                  error.toString().contains('token') || error.toString().contains('Unauthorized')
                      ? 'Session expired. Please sign in again.'
                      : 'Error loading customers: ${error.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(salesCustomersProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (customersAsync.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: const PaymentFormSkeleton(),
      );
    }

    final customersList = customersAsync.value ?? [];
    final customerItems = customersList.map((c) => CustomerItem(
      id: c.id,
      name: c.displayName,
      code: c.customerNumber ?? '',
      email: c.email,
      secondaryCode: c.customerNumber,
    )).toList();

    if (widget.editPaymentId != null &&
        _selectedCustomer == null &&
        customerItems.isNotEmpty) {
      final state = ref.read(paymentRecievesProvider);
      final recordIndex =
          state.records.indexWhere((r) => r.paymentNo == widget.editPaymentId);
      if (recordIndex >= 0) {
        final record = state.records[recordIndex];
        final matchIndex = customerItems.indexWhere(
          (c) => c.name.toLowerCase() == record.customer.toLowerCase(),
        );
        if (matchIndex >= 0) {
          _selectedCustomer = customerItems[matchIndex];
        }
      }
    }

    // Live chart-of-accounts grouped into Cash / Bank / Liabilities heads.
    final depositToNodes =
        _buildDepositToNodes(ref.watch(chartOfAccountsProvider).roots);

    final bodyWidget = Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Customer Name*
                    _fieldRow(
                      _label('Customer Name', required: true),
                      _customerField(customerItems),
                      fixHeight: false,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      maxWidth: null,
                    ),
                    const SizedBox(height: 18),

                    // Fields below are shown dimmed (half opacity) and
                    // non-interactive until a customer is selected.
                    Opacity(
                      opacity: _selectedCustomer == null ? 0.3 : 1.0,
                      child: IgnorePointer(
                        ignoring: _selectedCustomer == null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                    // 2. Place of Supply*
                    _fieldRow(
                      _label('Place of Supply', required: true),
                      FormDropdown<String>(
                        value: _placeOfSupply,
                        items: const ['[KL] - Kerala'],
                        hint: 'Select supply place',
                        onChanged: (val) => setState(() => _placeOfSupply = val),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Description of Supply
                    _fieldRow(
                      _label('Description of Supply', isDashed: true),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomTextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            height: 60,
                            hintText: '',
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Will be displayed on the Payment Receipt',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      fixHeight: false,
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                    const SizedBox(height: 18),

                    // 5. Amount Received*
                    _fieldRow(
                      _label('Amount Received', required: true),
                      _AdvAmountField(controller: _amountController),
                    ),
                    const SizedBox(height: 18),

                    // 6. Bank Charges (if any)
                    _fieldRow(
                      _label('Bank Charges (if any)'),
                      CustomTextField(
                        controller: _bankChargesController,
                        hintText: '',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 7. Tax
                    _fieldRow(
                      _label('Tax'),
                      FormDropdown<String>(
                        value: _selectedTax,
                        items: const ['Select a Tax', '5% GST', '12% GST', '18% GST', '28% GST'],
                        hint: 'Select Tax',
                        onChanged: (val) => setState(() => _selectedTax = val),
                        
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 8. Payment Date*
                    _fieldRow(
                      _label('Payment Date', required: true),
                      _AdvDatePickerField(
                        dateKey: _datePickerKey,
                        selectedDate: _selectedDate,
                        onDateChanged: (d) => setState(() => _selectedDate = d),
                        formatDate: _formatDate,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 9. Payment #*
                    _fieldRow(
                      _label('Payment #', required: true),
                      _paymentBar(),
                    ),
                    const SizedBox(height: 18),

                    // 10. Payment Mode
                    _fieldRow(
                      _label('Payment Mode'),
                      FormDropdown<String>(
                        value: _selectedPaymentMode,
                        items: _dynamicPaymentModes,
                        hint: 'Select payment mode',
                        onChanged: (val) => setState(() => _selectedPaymentMode = val),
                        showSettings: true,
                        settingsLabel: 'Configure Payment Mode',
                        settingsIcon: Icons.add_circle,
                        onSettingsTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) {
                              return ConfigurePaymentModeDialog(
                                paymentModes: _dynamicPaymentModes,
                                defaultPaymentMode: _selectedPaymentMode ?? 'Cash',
                                onSave: (updated, newDefault) {
                                  setState(() {
                                    _dynamicPaymentModes = updated;
                                    _selectedPaymentMode = newDefault;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 11. Deposit To*
                    _fieldRow(
                      _label('Deposit To', required: true),
                      AccountTreeDropdown(
                        value: _selectedDepositToId,
                        nodes: depositToNodes,
                        hint: 'Select an account',
                        height: 40,
                        borderRadius: BorderRadius.circular(6),
                        onChanged: (val) => setState(() => _selectedDepositToId = val),
                      ),
                      fixHeight: false,
                    ),
                    const SizedBox(height: 18),

                    // 12. Reference#
                    _fieldRow(
                      _label('Reference#'),
                      CustomTextField(
                        controller: _referenceController,
                        hintText: '',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Full-width bottom sections ────────────────────────

                    // 13. Notes
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            children: [
                              TextSpan(
                                text: 'Notes ',
                                style: TextStyle(color: AppTheme.textPrimary),
                              ),
                              TextSpan(
                                text: '(Internal use. Not visible to customer)',
                                style: TextStyle(color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _notesController,
                          maxLines: 4,
                          height: 80,
                          hintText: '',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 14. Attachments
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attachments',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FileUploadButton(
                          files: _attachedFiles,
                          onFilesChanged: (updated) {
                            setState(() {
                              _attachedFiles = updated;
                            });
                          },
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'You can upload a maximum of 5 files, 5MB each',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 15. Additional Fields Info
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Additional Fields: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: 'Start adding custom fields for your payments received by going to ',
                          ),
                          TextSpan(
                            text: 'Settings → Sales → Payments Received',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Details button pinned to the far right of the viewport
          if (_selectedCustomer != null)
            Positioned(
              top: 10,
              right: 24,
              child: _buildDetailsButton(),
            ),
          if (_showCustomerSidebar && _selectedCustomer != null)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: CustomerDetailsSidebar(
                customer: _getSalesCustomer(_selectedCustomer!, customersList),
                onClose: () => setState(() => _showCustomerSidebar = false),
              ),
            ),
        ],
      );

      final actionContainer = Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          children: [
            ZButton.secondary(
              label: 'Save as Draft',
              onPressed: () => _performSave('DRAFT'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed:
                  _selectedCustomer == null ? null : () => _performSave('PAID'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // success green
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFA7F3D0),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Save as Paid',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ZButton.secondary(
              label: 'Cancel',
              onPressed: () {
                if (widget.onCancel != null) {
                  widget.onCancel!();
                  return;
                }
                if (widget.onClose != null) {
                  widget.onClose!();
                  return;
                }
                final orgId = resolveOrgSystemId(context);
                context.goNamed('PaymentsReceived', pathParameters: {'orgSystemId': orgId});
              },
            ),
          ],
        ),
      );

      if (!widget.showLayout) {
        return Column(
          children: [
            Expanded(child: bodyWidget),
            actionContainer,
          ],
        );
      }

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: bodyWidget,
        bottomNavigationBar: actionContainer,
      );
  }
}

// ── Copy helper widgets from createinvoicepayment.dart ───────────────────────────

class _AdvAmountField extends StatefulWidget {
  final TextEditingController controller;

  const _AdvAmountField({required this.controller});

  @override
  State<_AdvAmountField> createState() => _AdvAmountFieldState();
}

class _AdvAmountFieldState extends State<_AdvAmountField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    // Show red/coral error border if non-numeric string (e.g. 'ASD') is entered
    final bool hasError = double.tryParse(widget.controller.text) == null &&
        widget.controller.text.isNotEmpty;

    final borderColor = hasError
        ? AppTheme.errorRed
        : (_isFocused ? AppTheme.primaryBlueDark : AppTheme.borderColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // INR prefix chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              border: Border(
                right: BorderSide(color: borderColor, width: 1),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                bottomLeft: Radius.circular(5),
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'INR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          // Input
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) =>
                  setState(() => _isFocused = hasFocus),
              child: TextField(
                controller: widget.controller,
                keyboardType: TextInputType.text,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  hoverColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvDatePickerField extends StatefulWidget {
  final GlobalKey dateKey;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final String Function(DateTime) formatDate;

  const _AdvDatePickerField({
    required this.dateKey,
    required this.selectedDate,
    required this.onDateChanged,
    required this.formatDate,
  });

  @override
  State<_AdvDatePickerField> createState() => _AdvDatePickerFieldState();
}

class _AdvDatePickerFieldState extends State<_AdvDatePickerField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        key: widget.dateKey,
        onTap: () async {
          final selected = await ZerpaiDatePicker.show(
            context,
            initialDate: widget.selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            targetKey: widget.dateKey,
          );
          if (selected != null) {
            widget.onDateChanged(selected);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _isHovered ? AppTheme.infoBlue : AppTheme.borderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            widget.formatDate(widget.selectedDate),
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdvAddPanPopoverContent extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSave;
  final VoidCallback onClose;

  const _AdvAddPanPopoverContent({
    required this.controller,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<_AdvAddPanPopoverContent> createState() => _AdvAddPanPopoverContentState();
}

class _AdvAddPanPopoverContentState extends State<_AdvAddPanPopoverContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'Add PAN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(4),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // PAN input
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: widget.controller,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppTheme.primaryBlue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Info note
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, size: 13, color: AppTheme.textSecondary),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'This PAN will be updated in contact and further transactions.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Save button
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () => widget.onSave(widget.controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvConfigurePaymentPreferencesDialog extends StatefulWidget {
  final String location;
  final String associatedSeries;
  final String initialNextNumber;
  final ValueChanged<String> onSave;

  const _AdvConfigurePaymentPreferencesDialog({
    required this.location,
    required this.associatedSeries,
    required this.initialNextNumber,
    required this.onSave,
  });

  @override
  State<_AdvConfigurePaymentPreferencesDialog> createState() =>
      _AdvConfigurePaymentPreferencesDialogState();
}

class _AdvConfigurePaymentPreferencesDialogState
    extends State<_AdvConfigurePaymentPreferencesDialog> {
  int _mode = 0;
  final TextEditingController _prefixController = TextEditingController();
  late final TextEditingController _nextNumberController;
  bool _restartFiscalYear = false;

  @override
  void initState() {
    super.initState();
    _nextNumberController = TextEditingController(text: widget.initialNextNumber);
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _nextNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              const Text(
                'Configure Payment Number Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.location,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Associated Series',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.associatedSeries,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 16),
              const Text(
                'Auto-generating payment numbers can save your time. Would you like to change your current setting?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              RadioScope<int>(
                value: _mode,
                onChanged: (val) => setState(() => _mode = val),
                child: Row(
                  children: [
                    RadioGroupItem<int>(
                      value: 0,
                      activeColor: AppTheme.primaryBlue,
                    ),
                    const Text(
                      'Auto-generate payment numbers',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_mode == 0) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prefix',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 36,
                                  child: CustomTextField(
                                    controller: _prefixController,
                                    suffixWidget: const Icon(
                                      Icons.add_circle_outline,
                                      color: AppTheme.primaryBlue,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Next Number',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 36,
                                  child: CustomTextField(
                                    controller: _nextNumberController,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _restartFiscalYear,
                              activeColor: AppTheme.primaryBlue,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _restartFiscalYear = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Restart numbering for payments at the start of each fiscal year.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              RadioScope<int>(
                value: _mode,
                onChanged: (val) => setState(() => _mode = val),
                child: Row(
                  children: [
                    RadioGroupItem<int>(
                      value: 1,
                      activeColor: AppTheme.primaryBlue,
                    ),
                    const Text(
                      'Add payment number manually for this payment',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave(_mode == 0 ? _nextNumberController.text : '');
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
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
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textBody,
                      side: const BorderSide(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
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
            ],
          ),
        ),
      ],
    );
  }
}
