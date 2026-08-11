import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/phone_input_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/address_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/models/retainer_invoice_create_payload.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/models/retainer_invoices_model.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/providers/retainer_invoices_provider.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/customers/providers/customers_provider.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';

// ── Demo data ────────────────────────────────────────────────────────────────

class _CustomerItem {
  final String id;
  final String name;
  final String code;
  final String subtitle;
  final SalesCustomer? sourceCustomer;
  const _CustomerItem({
    required this.id,
    required this.name,
    required this.code,
    required this.subtitle,
    this.sourceCustomer,
  });

  factory _CustomerItem.fromSalesCustomer(SalesCustomer customer) {
    final companyName = customer.companyName?.trim() ?? '';
    return _CustomerItem(
      id: customer.id,
      name: customer.displayName.trim(),
      code: customer.customerNumber?.trim() ?? '',
      subtitle: companyName.isNotEmpty
          ? companyName
          : customer.displayName.trim(),
      sourceCustomer: customer,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CustomerItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}

const _kLocations = [
  'ZABNIX PRIVATE LIMITED',
  'Branch Office - Mumbai',
  'Branch Office - Delhi',
];

const _kTransactionSeries = ['Default Transaction Series', 'Custom Series'];

// ─────────────────────────────────────────────────────────────────────────────

/// A single description+amount line item row.
class _LineItem {
  final TextEditingController descriptionCtrl;
  final TextEditingController amountCtrl;
  final FocusNode amountFocusNode;

  _LineItem()
    : descriptionCtrl = TextEditingController(),
      amountCtrl = TextEditingController(text: '0.00'),
      amountFocusNode = FocusNode() {
    amountFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (amountFocusNode.hasFocus) {
      if (amountCtrl.text == '0.00') {
        amountCtrl.clear();
      }
    } else {
      if (amountCtrl.text.isEmpty) {
        amountCtrl.text = '0.00';
      }
    }
  }

  void dispose() {
    descriptionCtrl.dispose();
    amountFocusNode.removeListener(_onFocusChange);
    amountFocusNode.dispose();
    amountCtrl.dispose();
  }

  double get amount =>
      double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────

class RetainerInvoicesCreatePage extends ConsumerStatefulWidget {
  final String? invoiceId;
  const RetainerInvoicesCreatePage({super.key, this.invoiceId});

  @override
  ConsumerState<RetainerInvoicesCreatePage> createState() =>
      _RetainerInvoicesCreatePageState();
}

class _RetainerInvoicesCreatePageState
    extends ConsumerState<RetainerInvoicesCreatePage> {
  // ── Fields ──────────────────────────────────────────────────────────────
  bool _showCustomerDetails = false;
  _CustomerItem? _customer;
  List<Map<String, dynamic>> _customerAddresses = [];
  int _selectedAddressIndex = 0;
  final LayerLink _addressLayerLink = LayerLink();
  OverlayEntry? _addressOverlayEntry;
  GlobalKey? __dateKey;
  GlobalKey get _dateKey => __dateKey ??= GlobalKey();

  String _location = _kLocations.first;
  String _transactionSeries = _kTransactionSeries.first;
  late TextEditingController _invoiceNoCtrl;
  late TextEditingController _referenceCtrl;
  late DateTime _date;
  late TextEditingController _notesCtrl;
  late TextEditingController _termsCtrl;

  // ── Line items ─────────────────────────────────────────────────────────
  final List<_LineItem> _lineItems = [];

  // ── Validation ─────────────────────────────────────────────────────────
  bool _triedSave = false;
  bool _isSaving = false;
  bool get _customerError => _triedSave && _customer == null;

  // ── Computed ────────────────────────────────────────────────────────────
  double get _subTotal =>
      _lineItems.fold(0.0, (sum, item) => sum + item.amount);
  double get _roundOff {
    final rounded = _subTotal.roundToDouble();
    return rounded - _subTotal;
  }

  double get _total => _subTotal + _roundOff;

  final List<_CustomerItem> _manualCustomers = [];

  List<_CustomerItem> _customerItemsFromLiveData(
    List<SalesCustomer> liveCustomers,
  ) {
    final merged =
        liveCustomers
            .where((customer) => customer.displayName.trim().isNotEmpty)
            .map(_CustomerItem.fromSalesCustomer)
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    for (final manual in _manualCustomers) {
      final exists = merged.any(
        (item) =>
            item.id == manual.id ||
            item.name.trim().toLowerCase() == manual.name.trim().toLowerCase(),
      );
      if (!exists) {
        merged.add(manual);
      }
    }

    return merged;
  }

  _CustomerItem? _findCustomerItem(
    String value,
    List<_CustomerItem> availableCustomers,
  ) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return null;

    for (final customer in availableCustomers) {
      if (customer.id == value ||
          customer.name.trim().toLowerCase() == query ||
          customer.code.trim().toLowerCase() == query) {
        return customer;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _getDefaultAddressesFor(String name) {
    final nameLower = name.toLowerCase();
    if (name == 'CUS-3' ||
        nameLower.contains('cus-3') ||
        nameLower.contains('hyper store')) {
      return [
        {
          'companyName': 'test',
          'attention': 'test',
          'street1': 'ROOM NO 5/1331',
          'street2': 'OOTI ROAD, OPPOSITE OF JIO COMMUNICATIONS',
          'city': 'PERINTHALMANNA',
          'zip': '679322',
          'state': 'KL',
          'stateName': 'Kerala',
          'country': 'IN',
          'countryName': 'India',
          'phone': '+91-08129542640',
        },
        {
          'companyName': 'test2',
          'attention': 'test2',
          'street1': 'ROOM NO 5/1331',
          'street2': 'OOTI ROAD, OPPOSITE OF JIO COMMUNICATIONS',
          'city': 'PERINTHALMANNA',
          'zip': '679322',
          'state': 'KL',
          'stateName': 'Kerala',
          'country': 'IN',
          'countryName': 'India',
          'phone': '+91-08129542640',
        },
      ];
    }
    return [
      {
        'companyName': name,
        'attention': name,
        'street1': '123 Business Rd',
        'street2': 'Suite 100',
        'city': 'Ernakulam',
        'zip': '682001',
        'state': 'KL',
        'stateName': 'Kerala',
        'country': 'IN',
        'countryName': 'India',
        'phone': '+91-9876543210',
      },
    ];
  }

  @override
  void initState() {
    super.initState();

    // Initialize all controllers with defaults first
    _date = DateTime.now();
    _invoiceNoCtrl = TextEditingController(
      text: ref.read(retainerInvoicesProvider.notifier).nextInvoiceNo(),
    );
    _referenceCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _termsCtrl = TextEditingController();
    _lineItems.add(_LineItem());
    for (final item in _lineItems) {
      item.amountCtrl.addListener(_onAmountChanged);
    }

    // If in edit mode, load invoice data after first frame
    if (widget.invoiceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInvoiceForEdit(widget.invoiceId!);
      });
    }
  }

  /// Loads and populates the form with the existing invoice data for edit mode.
  void _loadInvoiceForEdit(String invoiceId) {
    final providerState = ref.read(retainerInvoicesProvider);
    final list = providerState.invoices;
    final idx = list.indexWhere((i) => i.id == invoiceId);
    if (idx == -1) return; // invoice not found

    final invoice = list[idx];

    // Dispose the old default line item before replacing
    for (final item in _lineItems) {
      item.amountCtrl.removeListener(_onAmountChanged);
      item.dispose();
    }
    _lineItems.clear();

    // Build the edit-mode line item
    final lineItem = _LineItem();
    lineItem.descriptionCtrl.text = invoice.notes.isNotEmpty
        ? invoice.notes
        : 'Retainer service';
    lineItem.amountCtrl.text = invoice.amount.toStringAsFixed(2);
    lineItem.amountCtrl.addListener(_onAmountChanged);
    _lineItems.add(lineItem);

    // Set controllers
    _invoiceNoCtrl.text = invoice.invoiceNo;
    _referenceCtrl.text = invoice.referenceNo ?? '';
    _notesCtrl.text = invoice.notes;
    _termsCtrl.text = invoice.termsAndConditions;
    _date = invoice.date;

    // Resolve customer
    final liveCustomers =
        ref.read(customersProvider).valueOrNull ?? const <SalesCustomer>[];
    final availableCustomers = _customerItemsFromLiveData(liveCustomers);
    final matchingCust =
        _findCustomerItem(invoice.customerId, availableCustomers) ??
        _findCustomerItem(invoice.customerName, availableCustomers);
    _CustomerItem resolvedCust;
    if (matchingCust != null) {
      resolvedCust = matchingCust;
    } else {
      resolvedCust = _CustomerItem(
        id: invoice.customerId,
        name: invoice.customerName,
        code: 'CUS-EDIT',
        subtitle: invoice.customerName,
      );
      _manualCustomers.add(resolvedCust);
    }

    setState(() {
      _customer = resolvedCust;
      _customerAddresses = _getDefaultAddressesFor(resolvedCust.name);
      _selectedAddressIndex = 0;
    });
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hideAddressSelectionOverlay(updateState: false);
    _invoiceNoCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    _termsCtrl.dispose();
    for (final item in _lineItems) {
      item.amountCtrl.removeListener(_onAmountChanged);
      item.dispose();
    }
    super.dispose();
  }

  void _showAddressSelectionOverlay() {
    if (_addressOverlayEntry != null) {
      _hideAddressSelectionOverlay();
      return;
    }

    final overlay = Overlay.of(context);
    _addressOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideAddressSelectionOverlay,
              child: const SizedBox.expand(),
            ),
            CompositedTransformFollower(
              link: _addressLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 24),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.transparent,
                  child: _buildAddressSelectionCard(),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_addressOverlayEntry!);
    setState(() {});
  }

  void _hideAddressSelectionOverlay({bool updateState = true}) {
    _addressOverlayEntry?.remove();
    _addressOverlayEntry = null;
    if (updateState && mounted) {
      setState(() {});
    }
  }

  Widget _buildAddressSelectionCard() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: List.generate(_customerAddresses.length, (i) {
                  final addr = _customerAddresses[i];
                  final isActive = i == _selectedAddressIndex;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAddressIndex = i;
                      });
                      _hideAddressSelectionOverlay();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF3B82F6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isActive
                              ? Colors.transparent
                              : AppTheme.borderLight,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addr['companyName'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...[
                                      if (addr['street1']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true)
                                        addr['street1'].toString(),
                                      if (addr['street2']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true)
                                        addr['street2'].toString(),
                                      '${addr['city'] ?? ''}${addr['city'] != null && addr['stateName'] != null ? ', ' : ''}${addr['stateName'] ?? addr['state'] ?? ''}'
                                          .trim(),
                                      '${addr['countryName'] ?? addr['country'] ?? ''}${addr['countryName'] != null && addr['zip'] != null ? ' , ' : ''}${addr['zip'] ?? ''}'
                                          .trim(),
                                      if (addr['phone']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true)
                                        addr['phone'].toString(),
                                    ]
                                    .where((line) => line.isNotEmpty)
                                    .map(
                                      (line) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 2,
                                        ),
                                        child: Text(
                                          line,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isActive
                                                ? Colors.white.withValues(
                                                    alpha: 0.9,
                                                  )
                                                : AppTheme.textSecondary,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () async {
                                _hideAddressSelectionOverlay();
                                await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => AddressDialog(
                                    title: 'BILLING ADDRESS',
                                    initialAddress: addr,
                                    onSave: (updated) {
                                      setState(() {
                                        _customerAddresses[i] = updated;
                                      });
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  LucideIcons.pencil,
                                  size: 12,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          InkWell(
            onTap: () async {
              _hideAddressSelectionOverlay();
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AddressDialog(
                  title: 'BILLING ADDRESS',
                  initialAddress: {
                    'companyName': '',
                    'attention': '',
                    'street1': '',
                    'street2': '',
                    'city': '',
                    'zip': '',
                    'state': '',
                    'stateName': '',
                    'country': 'IN',
                    'countryName': 'India',
                    'phone': '',
                  },
                  onSave: (newAddress) {
                    setState(() {
                      _customerAddresses.add(newAddress);
                      _selectedAddressIndex = _customerAddresses.length - 1;
                    });
                  },
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: 14,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'New address',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _orgId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

  String get _formattedDate {
    final d = _date;
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _addRow() {
    setState(() {
      final item = _LineItem();
      item.amountCtrl.addListener(_onAmountChanged);
      _lineItems.add(item);
    });
  }

  void _removeRow(int index) {
    if (_lineItems.length <= 1) return;
    setState(() {
      final item = _lineItems.removeAt(index);
      item.amountCtrl.removeListener(_onAmountChanged);
      item.dispose();
    });
  }

  void _cloneRow(int index) {
    setState(() {
      final source = _lineItems[index];
      final item = _LineItem();
      item.descriptionCtrl.text = source.descriptionCtrl.text;
      item.amountCtrl.text = source.amountCtrl.text;
      item.amountCtrl.addListener(_onAmountChanged);
      _lineItems.insert(index + 1, item);
    });
  }

  void _insertNewRowAt(int index) {
    setState(() {
      final item = _LineItem();
      item.amountCtrl.addListener(_onAmountChanged);
      _lineItems.insert(index + 1, item);
    });
  }

  bool _validate() {
    setState(() => _triedSave = true);
    if (_customer == null) return false;
    return true;
  }

  Future<void> _save({required RetainerStatus status}) async {
    if (!_validate()) {
      ZerpaiToast.error(context, 'Please fix the errors before saving.');
      return;
    }

    setState(() => _isSaving = true);

    final notifier = ref.read(retainerInvoicesProvider.notifier);
    final isEdit = widget.invoiceId != null;
    final itemPayloads = _lineItems
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final item = entry.value;
          final description = item.descriptionCtrl.text.trim();
          return RetainerInvoiceCreateItemPayload(
            description: description.isEmpty ? 'Retainer service' : description,
            amount: item.amount,
            lineNo: index + 1,
          );
        })
        .where((item) => item.amount != 0 || item.description.trim().isNotEmpty)
        .toList();

    final normalizedItems = itemPayloads.isEmpty
        ? const [
            RetainerInvoiceCreateItemPayload(
              description: 'Retainer service',
              amount: 0,
              lineNo: 1,
            ),
          ]
        : itemPayloads;

    final invoice = RetainerInvoice.create(
      id: isEdit
          ? widget.invoiceId!
          : DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNo: _invoiceNoCtrl.text.trim(),
      date: _date,
      customerId: _customer!.id,
      customerName: _customer!.name,
      amount: _subTotal,
      taxLabel: 'None',
      taxRate: 0.0,
      amountUsed: 0.0,
      referenceNo: _referenceCtrl.text.trim().isEmpty
          ? null
          : _referenceCtrl.text.trim(),
      status: status,
      notes: _notesCtrl.text.trim(),
      termsAndConditions: _termsCtrl.text.trim(),
      location: _location,
    );

    try {
      if (isEdit) {
        notifier.updateInvoice(invoice);
        ZerpaiToast.success(context, 'Retainer invoice updated successfully');
      } else {
        final payload = RetainerInvoiceCreatePayload(
          customerId: _customer!.id,
          retainerInvoiceNumber: _invoiceNoCtrl.text.trim(),
          retainerInvoiceDate: DateFormat('yyyy-MM-dd').format(_date),
          referenceNumber: _referenceCtrl.text.trim().isEmpty
              ? null
              : _referenceCtrl.text.trim(),
          customerNotes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
          termsConditions: _termsCtrl.text.trim().isEmpty
              ? null
              : _termsCtrl.text.trim(),
          subtotal: _subTotal,
          roundOff: _roundOff,
          totalAmount: _total,
          balanceAmount: _total,
          status: status.apiValue,
          items: normalizedItems,
        );

        final repository = ref.read(retainerInvoicesRepositoryProvider);
        final created = await repository.createRetainerInvoice(payload);
        notifier.addInvoice(
          invoice.copyWith(id: created['id']?.toString() ?? invoice.id),
        );
        ZerpaiToast.success(
          context,
          status == RetainerStatus.draft
              ? 'Retainer invoice saved as Draft'
              : 'Retainer invoice saved and marked as Sent',
        );
      }

      if (!mounted) return;
      if (isEdit) {
        context.go('/$_orgId/sales/retainer-invoices/${widget.invoiceId}');
      } else {
        context.go('/$_orgId${AppRoutes.salesRetainerInvoices}');
      }
    } catch (error) {
      if (!mounted) return;
      ZerpaiToast.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ── Date picker ─────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      targetKey: _dateKey,
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  // ── Invoice Number Preferences Dialog ────────────────────────────────────

  Future<void> _showInvoiceNumberPreferencesDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _InvoiceNumberPreferencesDialog(
        location: _location,
        transactionSeries: _transactionSeries,
        currentPrefix: 'RET-',
        currentNextNumber: _invoiceNoCtrl.text.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (result['mode'] == 'auto') {
          final prefix = result['prefix'] as String? ?? 'RET-';
          final nextNumber = result['nextNumber'] as String? ?? '00006';
          _invoiceNoCtrl.text = '$prefix$nextNumber';
        }
        // If mode == 'manual', do nothing – user types their own number
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final liveCustomers = customersAsync.valueOrNull ?? const <SalesCustomer>[];
    final availableCustomers = _customerItemsFromLiveData(liveCustomers);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Page header ─────────────────────────────────────────────
              _buildHeader(),
              // ── Scrollable body ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Full-bleed grey Customer & Location Block ──────────
                      _buildCustomerBlock(
                        availableCustomers,
                        isLoading:
                            customersAsync.isLoading &&
                            availableCustomers.isEmpty,
                      ),

                      // ── Remaining Form fields (40px side padding) ────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 24, 40, 0),
                        child: _buildRemainingFormFields(),
                      ),
                      const SizedBox(height: 24),
                      // ── Line items table (~75% width, 12px left padding) ──
                      FractionallySizedBox(
                        widthFactor: 0.75,
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLineItemsTable(),
                              const SizedBox(height: 16),
                              _buildAddRowAndSummary(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      _buildTermsAndConditions(),
                    ],
                  ),
                ),
              ),
              // ── Bottom action bar ───────────────────────────────────────
              _buildBottomBar(),
            ],
          ),
          if (_showCustomerDetails && _customer != null)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: _CustomerDetailsDrawer(
                customerName: _customer!.name,
                onClose: () {
                  setState(() {
                    _showCustomerDetails = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Header
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    final isEdit = widget.invoiceId != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 40, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.request_quote_outlined,
            size: 22,
            color: AppTheme.textPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEdit ? 'Edit Retainer Invoice' : 'New Retainer Invoice',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Form fields (label-left layout matching the screenshot)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _showNewCustomerDialog() async {
    final result = await showDialog<SalesCustomer>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _NewCustomerDialog(),
    );
    if (result != null) {
      ref.invalidate(customersProvider);
      final customerItem = _CustomerItem.fromSalesCustomer(result);
      setState(() {
        _manualCustomers.removeWhere((item) => item.id == customerItem.id);
        _manualCustomers.add(customerItem);
        _customer = customerItem;
        _customerAddresses = _getDefaultAddressesFor(_customer!.name);
        _selectedAddressIndex = 0;
      });
    }
  }

  Future<void> _showAdvancedSearchDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AdvancedCustomerSearchDialog(),
    );
    if (result != null && result.isNotEmpty) {
      final liveCustomers =
          ref.read(customersProvider).valueOrNull ?? const <SalesCustomer>[];
      final availableCustomers = _customerItemsFromLiveData(liveCustomers);
      setState(() {
        final existing = _findCustomerItem(result, availableCustomers);
        if (existing != null) {
          _customer = existing;
        } else {
          final newCust = _CustomerItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: result,
            code: '',
            subtitle: result,
          );
          _manualCustomers.add(newCust);
          _customer = newCust;
        }
        _customerAddresses = _getDefaultAddressesFor(_customer!.name);
        _selectedAddressIndex = 0;
      });
    }
  }

  Widget _buildCustomerBlock(
    List<_CustomerItem> availableCustomers, {
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 16, 40, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Name
          _FormField(
            label: 'Customer Name',
            required: true,
            highlightError: _customerError,
            child: Row(
              children: [
                SizedBox(
                  width: 350,
                  child: FormDropdown<_CustomerItem>(
                    height: 32,
                    value: _customer,
                    items: availableCustomers,
                    hint: isLoading
                        ? 'Loading customers...'
                        : 'Select or add a customer',
                    showSettings: true,
                    settingsLabel: 'New Customer',
                    settingsIcon: LucideIcons.plus,
                    onSettingsTap: _showNewCustomerDialog,
                    allowClear: true,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                    displayStringForValue: (c) => c.name,
                    searchStringForValue: (c) =>
                        '${c.name} ${c.code} ${c.subtitle}',
                    itemBuilder: (item, isSelected, isHovered) {
                      final Color titleColor = isHovered
                          ? Colors.white
                          : const Color(0xFF1F2937);
                      final Color codeColor = isHovered
                          ? Colors.white.withValues(alpha: 0.8)
                          : const Color(0xFF9CA3AF);
                      final Color subtitleColor = isHovered
                          ? Colors.white.withValues(alpha: 0.9)
                          : const Color(0xFF4B5563);
                      final Color avatarBg = isHovered
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFFF3F4F6);
                      final Color avatarTextColor = isHovered
                          ? Colors.white
                          : const Color(0xFF9CA3AF);
                      final Color bg = isHovered
                          ? const Color(0xFF3B82F6)
                          : (isSelected
                                ? const Color(0xFFF3F4F6)
                                : Colors.white);

                      return Container(
                        color: bg,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: avatarBg,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item.name.isNotEmpty
                                    ? item.name[0].toUpperCase()
                                    : '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: avatarTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.normal,
                                            color: titleColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (item.code.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '| ${item.code}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: codeColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.fileText,
                                        size: 12,
                                        color: isHovered
                                            ? Colors.white
                                            : const Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.subtitle,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: subtitleColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onChanged: (v) {
                      setState(() {
                        _customer = v;
                        if (v != null) {
                          _customerAddresses = _getDefaultAddressesFor(v.name);
                          _selectedAddressIndex = 0;
                        } else {
                          _customerAddresses = [];
                          _selectedAddressIndex = 0;
                        }
                      });
                    },
                    errorText: _customerError ? 'Required' : null,
                  ),
                ),
                InkWell(
                  onTap: _showAdvancedSearchDialog,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22B378),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.search,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_customer != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.borderLight),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.globe,
                          size: 13,
                          color: Color(0xFF22C55E),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'INR',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showCustomerDetails = !_showCustomerDetails;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E4F63),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${_customer!.name}'s Details",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Conditional Billing Address info block
          if (_customer != null && _customerAddresses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 200, top: 4, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CompositedTransformTarget(
                    link: _addressLayerLink,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'BILLING ADDRESS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _showAddressSelectionOverlay,
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              LucideIcons.pencil,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _customerAddresses[_selectedAddressIndex]['companyName'] ??
                        '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ...[
                        if (_customerAddresses[_selectedAddressIndex]['street1']
                                ?.toString()
                                .isNotEmpty ==
                            true)
                          _customerAddresses[_selectedAddressIndex]['street1']
                              .toString(),
                        if (_customerAddresses[_selectedAddressIndex]['street2']
                                ?.toString()
                                .isNotEmpty ==
                            true)
                          _customerAddresses[_selectedAddressIndex]['street2']
                              .toString(),
                        '${_customerAddresses[_selectedAddressIndex]['city'] ?? ''}${_customerAddresses[_selectedAddressIndex]['city'] != null && _customerAddresses[_selectedAddressIndex]['stateName'] != null ? ', ' : ''}${_customerAddresses[_selectedAddressIndex]['stateName'] ?? _customerAddresses[_selectedAddressIndex]['state'] ?? ''}'
                            .trim(),
                        '${_customerAddresses[_selectedAddressIndex]['countryName'] ?? _customerAddresses[_selectedAddressIndex]['country'] ?? ''}${_customerAddresses[_selectedAddressIndex]['countryName'] != null && _customerAddresses[_selectedAddressIndex]['zip'] != null ? ' , ' : ''}${_customerAddresses[_selectedAddressIndex]['zip'] ?? ''}'
                            .trim(),
                        if (_customerAddresses[_selectedAddressIndex]['phone']
                                ?.toString()
                                .isNotEmpty ==
                            true)
                          _customerAddresses[_selectedAddressIndex]['phone']
                              .toString(),
                      ]
                      .where((line) => line.isNotEmpty)
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            line,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRemainingFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Retainer Invoice Number
        _FormField(
          label: 'Retainer Invoice\nNumber',
          required: true,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  child: FormDropdown<String>(
                    height: 32,
                    value: _transactionSeries,
                    items: _kTransactionSeries,
                    hint: 'Series',
                    onChanged: (v) {
                      if (v != null) setState(() => _transactionSeries = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 220,
                  child: Stack(
                    children: [
                      CustomTextField(
                        height: 32,
                        controller: _invoiceNoCtrl,
                        hintText: 'RET-00006',
                      ),
                      Positioned(
                        right: 4,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: ZTooltip(
                            message:
                                'Click here to enable or disable auto-generation of Retainer Invoices numbers.',
                            child: InkWell(
                              onTap: _showInvoiceNumberPreferencesDialog,
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  LucideIcons.settings,
                                  size: 14,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
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
        // Reference#
        _FormField(
          label: 'Reference#',
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 220,
              child: CustomTextField(
                controller: _referenceCtrl,
                hintText: '',
                height: 32,
              ),
            ),
          ),
        ),
        // Retainer Invoice Date
        _FormField(
          label: 'Retainer Invoice Date',
          required: true,
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              key: _dateKey,
              onTap: _pickDate,
              child: Container(
                width: 220,
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formattedDate,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      LucideIcons.calendar,
                      size: 15,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ── Line items table
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildLineItemsTable() {
    const double amountColWidth = 160.0;

    // Header label style: uppercase, blue-gray #94A3B8
    final headerCellStyle = AppTheme.tableHeader.copyWith(
      fontSize: 11,
      color: AppTheme.textDisabled,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w600,
    );

    final listItems = List.generate(_lineItems.length, (index) {
      final item = _lineItems[index];
      final isLast = index == _lineItems.length - 1;

      bool isRowHovered = false;
      return StatefulBuilder(
        key: ValueKey(item),
        builder: (context, setState) {
          return MouseRegion(
            onEnter: (_) => setState(() => isRowHovered = true),
            onExit: (_) => setState(() => isRowHovered = false),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.drag_indicator,
                        size: 16,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        left: const BorderSide(color: AppTheme.borderColor),
                        right: const BorderSide(color: AppTheme.borderColor),
                        bottom: const BorderSide(color: AppTheme.borderColor),
                      ),
                      borderRadius: isLast
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            )
                          : BorderRadius.zero,
                    ),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        // Description field
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space20,
                            ),
                            child: TextField(
                              controller: item.descriptionCtrl,
                              style: AppTheme.tableCell,
                              decoration: InputDecoration(
                                hintText: 'Description',
                                hintStyle: AppTheme.tableCell.copyWith(
                                  color: AppTheme.textHint,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hoverColor: Colors.transparent,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 48,
                          color: AppTheme.borderColor,
                        ),
                        // Amount field
                        SizedBox(
                          width: amountColWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space20,
                            ),
                            child: TextField(
                              controller: item.amountCtrl,
                              focusNode: item.amountFocusNode,
                              textAlign: TextAlign.right,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: AppTheme.tableCell,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hoverColor: Colors.transparent,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Actions (Dots & Red X) outside the box
                Visibility(
                  visible: isRowHovered,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      () {
                        bool isHovered = false;
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return MouseRegion(
                              onEnter: (_) => setState(() => isHovered = true),
                              onExit: (_) => setState(() => isHovered = false),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  popupMenuTheme: PopupMenuThemeData(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      side: const BorderSide(
                                        color: AppTheme.borderLight,
                                      ),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  offset: const Offset(0, 24),
                                  onSelected: (val) {
                                    if (val == 'clone') {
                                      _cloneRow(index);
                                    } else if (val == 'insert') {
                                      _insertNewRowAt(index);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem<String>(
                                      value: 'clone',
                                      padding: EdgeInsets.zero,
                                      height: 32,
                                      child: _HoverPopupItem(text: 'Clone'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'insert',
                                      padding: EdgeInsets.zero,
                                      height: 32,
                                      child: _HoverPopupItem(
                                        text: 'Insert New Row',
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isHovered
                                          ? AppTheme.primaryBlue.withOpacity(
                                              0.05,
                                            )
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isHovered
                                            ? AppTheme.primaryBlue
                                            : const Color(0xFFDCDCDC),
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.more_horiz,
                                        size: 12,
                                        color: isHovered
                                            ? AppTheme.primaryBlue
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }(),
                      const SizedBox(width: 6),
                      () {
                        bool isHovered = false;
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return MouseRegion(
                              onEnter: (_) => setState(() => isHovered = true),
                              onExit: (_) => setState(() => isHovered = false),
                              child: InkWell(
                                onTap: () => _removeRow(index),
                                borderRadius: BorderRadius.circular(11),
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isHovered
                                        ? AppTheme.primaryBlue.withOpacity(0.05)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isHovered
                                          ? AppTheme.primaryBlue
                                          : const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.close,
                                      size: 11,
                                      color: isHovered
                                          ? AppTheme.primaryBlue
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: SizedBox(
                  height: 38,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space20,
                          ),
                          child: Text('DESCRIPTION', style: headerCellStyle),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 38,
                        color: AppTheme.borderColor,
                      ),
                      SizedBox(
                        width: amountColWidth,
                        child: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space20,
                          ),
                          child: Text(
                            'AMOUNT',
                            textAlign: TextAlign.right,
                            style: headerCellStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 62),
          ],
        ),
        ReorderableListView(
          buildDefaultDragHandles: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = _lineItems.removeAt(oldIndex);
              _lineItems.insert(newIndex, item);
            });
          },
          children: listItems,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Add row button + Summary
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAddRowAndSummary() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ⊕ Add New Row
              TextButton.icon(
                onPressed: _addRow,
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: AppTheme.textPrimary,
                ),
                label: const Text(
                  'Add New Row',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: AppTheme.borderLight),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Customer Notes
              const Text(
                'Customer Notes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText:
                        'Enter any notes to be displayed in your transaction',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFBBBBBB),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Summary table
        Container(
          width: 440,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              _SummaryRow(label: 'Sub Total', value: _subTotal),
              const SizedBox(height: 12),
              _SummaryRow(label: 'Round Off', value: _roundOff),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppTheme.borderLight),
              const SizedBox(height: 12),
              _SummaryRow(label: 'Total', value: _total, bold: true),
            ],
          ),
        ),
        const SizedBox(width: 62),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 16, 40, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Terms and conditions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 750,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: TextField(
              controller: _termsCtrl,
              maxLines: 5,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText:
                    'Enter the terms and conditions of your transaction to be displayed in your transaction',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Bottom action bar
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          // Save as Draft
          ZButton.secondary(
            label: 'Save as Draft',
            onPressed: _isSaving
                ? null
                : () => _save(status: RetainerStatus.draft),
          ),
          const SizedBox(width: 10),
          // Save and Send (primary green)
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () => _save(status: RetainerStatus.sent),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22B378),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save and Send',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          // Cancel
          ZButton.secondary(
            label: 'Cancel',
            onPressed: _isSaving
                ? null
                : () =>
                      context.go('/$_orgId${AppRoutes.salesRetainerInvoices}'),
          ),
          const Spacer(),
          // PDF Template
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PDF Template: ',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                'Standard Template',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryBlue,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.primaryBlue.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ── Private widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Form field row matching the Zoho Books label-left flat layout.
class _FormField extends StatelessWidget {
  final String label;
  final bool required;
  final bool highlightError;
  final Widget child;

  const _FormField({
    required this.label,
    this.required = false,
    this.highlightError = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: RichText(
                text: TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: required ? AppTheme.errorRed : AppTheme.textPrimary,
                    height: 1.3,
                  ),
                  children: required
                      ? const [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Summary row (label left, amount right).
class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Advanced Customer Search Dialog ──────────────────────────────────────────

class _AdvancedCustomerSearchDialog extends StatefulWidget {
  const _AdvancedCustomerSearchDialog();

  @override
  State<_AdvancedCustomerSearchDialog> createState() =>
      _AdvancedCustomerSearchDialogState();
}

class _AdvancedCustomerSearchDialogState
    extends State<_AdvancedCustomerSearchDialog> {
  String _searchCriteria = 'Customer Number';
  final _searchCtrl = TextEditingController();
  List<Map<String, String>> _allCustomers = [];
  List<Map<String, String>> _filteredResults = [];

  final List<String> _criteriaList = [
    'Customer Number',
    'Display Name',
    'Company Name',
    'First Name',
    'Last Name',
    'Email',
    'Phone',
    'GSTIN',
  ];

  @override
  void initState() {
    super.initState();
    // Demo data for advanced customer search
    _allCustomers = [
      {
        'number': 'CUS-1',
        'displayName': 'ZABNIX PRIVATE LIMITED',
        'companyName': 'ZABNIX PRIVATE LIMITED',
        'email': 'zabnixprivatelimited@mail.com',
        'phone': '+91-08129542640',
        'firstName': 'Zabnix',
        'lastName': 'Ltd',
        'gstin': '32AAAAA1111A1Z1',
      },
      {
        'number': 'CUS-2',
        'displayName': 'SAHAKAR MEDICALS AND SURGICALS ALANALLUR LLP',
        'companyName': 'SAHAKAR MEDICALS AND SURGICALS ALANALLUR LLP',
        'email': 'sahakar.alanallur@mail.com',
        'phone': '+91-08129542640',
        'firstName': 'Sahakar',
        'lastName': 'Alanallur',
        'gstin': '32BBBBB2222B2Z2',
      },
      {
        'number': 'CUS-3',
        'displayName': 'SAHAKAR MEDICALS AND SURGICALS HYPER STORE LLP',
        'companyName': 'SAHAKAR MEDICALS AND SURGICALS HYPER STORE LLP',
        'email': 'sahakar.hyper@gmail.com',
        'phone': '+91-08129542640',
        'firstName': 'Sahakar',
        'lastName': 'Hyper',
        'gstin': '32CCCCC3333C3Z3',
      },
      {
        'number': 'CUS-00021',
        'displayName': 'SAHAKAR MEDICALS AND SURGICALS KKL LLP',
        'companyName': 'SAHAKAR MEDICALS AND SURGICALS KKL LLP',
        'email': 'sahakar.kkl@gmail.com',
        'phone': '+91-08606259910',
        'firstName': 'Sahakar',
        'lastName': 'Kkl',
        'gstin': '32DDDDD4444D4Z4',
      },
      {
        'number': 'CUS-00020',
        'displayName': 'SAHAKAR MEDICALS AND SURGICALS MAKKARAPARAMBA LLP',
        'companyName': 'SAHAKAR MEDICALS AND SURGICALS MAKKARAPARAMBA LLP',
        'email': 'sahakar.makkara@gmail.com',
        'phone': '+91-08606259910',
        'firstName': 'Sahakar',
        'lastName': 'Makkaraparamba',
        'gstin': '32EEEEE5555E5Z5',
      },
      {
        'number': 'CUS-00019',
        'displayName': 'SAHAKAR MEDICALS AND SURGICALS THRISSUR LLP',
        'companyName': 'SAHAKAR MEDICALS AND SURGICALS THRISSUR LLP',
        'email': 'sahakar.thrissur@gmail.com',
        'phone': '+91-08606259910',
        'firstName': 'Sahakar',
        'lastName': 'Thrissur',
        'gstin': '32FFFFF6666F6Z6',
      },
    ];
    _filteredResults = List.from(_allCustomers);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredResults = List.from(_allCustomers);
        return;
      }
      _filteredResults = _allCustomers.where((cust) {
        String matchField = '';
        switch (_searchCriteria) {
          case 'Customer Number':
            matchField = cust['number'] ?? '';
            break;
          case 'Display Name':
            matchField = cust['displayName'] ?? '';
            break;
          case 'Company Name':
            matchField = cust['companyName'] ?? '';
            break;
          case 'First Name':
            matchField = cust['firstName'] ?? '';
            break;
          case 'Last Name':
            matchField = cust['lastName'] ?? '';
            break;
          case 'Email':
            matchField = cust['email'] ?? '';
            break;
          case 'Phone':
            matchField = cust['phone'] ?? '';
            break;
          case 'GSTIN':
            matchField = cust['gstin'] ?? '';
            break;
          default:
            matchField = cust['displayName'] ?? '';
        }
        return matchField.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(vertical: 0),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        width: 520,
        height: double.infinity,
        child: Column(
          children: [
            // Title Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Advanced Customer Search',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            // Search inputs bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Combined criteria dropdown and search text field
                  // Combined criteria dropdown and search text field
                  SizedBox(
                    width: 380,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 160,
                          child: FormDropdown<String>(
                            height: 32,
                            padding: const EdgeInsets.only(left: 6, right: 0),
                            value: _searchCriteria,
                            items: _criteriaList,
                            hint: 'Criteria',
                            showSearch: false,
                            fillColor: const Color(0xFFF3F4F6),
                            showRightBorder: false,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _searchCriteria = v);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: CustomTextField(
                            height: 32,
                            controller: _searchCtrl,
                            hintText: '',
                            showLeftBorder: false,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E), // Green
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 32),
                      fixedSize: const Size.fromHeight(32),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                border: Border(
                  top: BorderSide(color: AppTheme.borderLight),
                  bottom: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'EMAIL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'COMPANY NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'PHONE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table results list
            Expanded(
              child: _filteredResults.isEmpty
                  ? const Center(
                      child: Text(
                        'No customers found',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredResults.length,
                      itemBuilder: (context, index) {
                        final cust = _filteredResults[index];
                        return InkWell(
                          onTap: () =>
                              Navigator.pop(context, cust['displayName']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppTheme.borderLight),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cust['displayName'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        cust['number'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    cust['email'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    cust['companyName'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    cust['phone'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── New Customer Dialog ──────────────────────────────────────────────────────

class _NewCustomerDialog extends ConsumerStatefulWidget {
  const _NewCustomerDialog();

  @override
  ConsumerState<_NewCustomerDialog> createState() => _NewCustomerDialogState();
}

class _NewCustomerDialogState extends ConsumerState<_NewCustomerDialog>
    with SingleTickerProviderStateMixin {
  final _dialogFormKey = GlobalKey<FormState>();

  // General fields
  bool _isBusiness = true;
  String _salutation = 'Mr.';
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _customerNumberCtrl = TextEditingController(text: 'CUS-00023');
  final _phoneCodeCtrl = TextEditingController(text: '+91');
  final _phoneCtrl = TextEditingController();
  final _mobileCodeCtrl = TextEditingController(text: '+91');
  final _mobileCtrl = TextEditingController();
  String _language = 'English';
  final _billingAttentionCtrl = TextEditingController();
  String? _billingCountry = 'India';
  final _billingStreet1Ctrl = TextEditingController();
  final _billingStreet2Ctrl = TextEditingController();
  final _billingCityCtrl = TextEditingController();
  String? _billingState;
  final _billingPinCodeCtrl = TextEditingController();
  String _billingPhoneCode = '+91';
  final _billingPhoneCtrl = TextEditingController();
  final _billingFaxCtrl = TextEditingController();
  double _billingStreet1Height = 50;
  double _billingStreet2Height = 50;
  final _shippingAttentionCtrl = TextEditingController();
  String? _shippingCountry = 'India';
  final _shippingStreet1Ctrl = TextEditingController();
  final _shippingStreet2Ctrl = TextEditingController();
  final _shippingCityCtrl = TextEditingController();
  String? _shippingState;
  final _shippingPinCodeCtrl = TextEditingController();
  String _shippingPhoneCode = '+91';
  final _shippingPhoneCtrl = TextEditingController();
  final _shippingFaxCtrl = TextEditingController();
  double _shippingStreet1Height = 50;
  double _shippingStreet2Height = 50;
  final _customDemoFieldCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  double _remarksHeight = 94;
  bool _isSaving = false;

  // Tabs
  late TabController _tabController;

  // Other Details Tab fields
  String? _gstTreatment;
  String? _placeOfSupply;
  final _panCtrl = TextEditingController();
  bool _isTaxable = true;
  String _currency = 'INR- Indian Rupee';
  final _creditLimitCtrl = TextEditingController();
  String _paymentTerms = 'Net 360';
  String? _priceList;
  bool _enablePortal = false;
  List<PlatformFile>? _documents = [];
  bool _phoneHovered = false;
  bool _phoneFocused = false;
  bool _mobileHovered = false;
  bool _mobileFocused = false;
  String? _reportingTagAdgf;
  String? _reportingTagShedule;
  String? _reportingTagDemoAdvaced;
  String? _reportingTagErhj = 'dewewe';

  final List<String> _salutations = ['Mr.', 'Mrs.', 'Ms.', 'Miss', 'Dr.'];
  final List<String> _languages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Bengali',
    'Marathi',
  ];
  final List<String> _gstTreatments = [
    'Registered Business - Regular',
    'Registered Business - Composition',
    'Unregistered Business',
    'Consumer',
    'Overseas',
    'Special Economic Zone (SEZ)',
  ];
  final List<String> _states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
  ];
  final List<String> _countries = [
    'Afghanistan',
    'Aland Islands',
    'Albania',
    'Algeria',
    'American Samoa',
    'Andorra',
    'Angola',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Bahrain',
    'Bangladesh',
    'Belgium',
    'Bhutan',
    'Brazil',
    'Canada',
    'China',
    'Denmark',
    'Finland',
    'France',
    'Germany',
    'India',
    'Indonesia',
    'Ireland',
    'Italy',
    'Japan',
    'Kuwait',
    'Malaysia',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Norway',
    'Oman',
    'Pakistan',
    'Philippines',
    'Qatar',
    'Saudi Arabia',
    'Singapore',
    'South Africa',
    'Sri Lanka',
    'Sweden',
    'Switzerland',
    'Thailand',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Vietnam',
  ];
  final List<String> _currencies = [
    'INR- Indian Rupee',
    'USD- US Dollar',
    'EUR- Euro',
    'GBP- British Pound',
  ];
  final List<String> _paymentTermOptions = [
    'Due on Receipt',
    'Net 15',
    'Net 30',
    'Net 45',
    'Net 60',
    'Net 360',
  ];
  final List<String> _priceLists = [
    'Standard Price List',
    'Wholesale Price List',
    'Special Discount Price List',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _companyNameCtrl.dispose();
    _displayNameCtrl.dispose();
    _emailCtrl.dispose();
    _customerNumberCtrl.dispose();
    _phoneCodeCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCodeCtrl.dispose();
    _mobileCtrl.dispose();
    _billingAttentionCtrl.dispose();
    _billingStreet1Ctrl.dispose();
    _billingStreet2Ctrl.dispose();
    _billingCityCtrl.dispose();
    _billingPinCodeCtrl.dispose();
    _billingPhoneCtrl.dispose();
    _billingFaxCtrl.dispose();
    _shippingAttentionCtrl.dispose();
    _shippingStreet1Ctrl.dispose();
    _shippingStreet2Ctrl.dispose();
    _shippingCityCtrl.dispose();
    _shippingPinCodeCtrl.dispose();
    _shippingPhoneCtrl.dispose();
    _shippingFaxCtrl.dispose();
    _customDemoFieldCtrl.dispose();
    _remarksCtrl.dispose();
    _panCtrl.dispose();
    _creditLimitCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _copyBillingToShipping() {
    setState(() {
      _shippingAttentionCtrl.text = _billingAttentionCtrl.text;
      _shippingCountry = _billingCountry;
      _shippingStreet1Ctrl.text = _billingStreet1Ctrl.text;
      _shippingStreet2Ctrl.text = _billingStreet2Ctrl.text;
      _shippingCityCtrl.text = _billingCityCtrl.text;
      _shippingState = _billingState;
      _shippingPinCodeCtrl.text = _billingPinCodeCtrl.text;
      _shippingPhoneCode = _billingPhoneCode;
      _shippingPhoneCtrl.text = _billingPhoneCtrl.text;
      _shippingFaxCtrl.text = _billingFaxCtrl.text;
    });
  }

  void _onNameChanged() {
    if (_displayNameCtrl.text.isEmpty ||
        _displayNameCtrl.text ==
            '${_firstNameCtrl.text} ${_lastNameCtrl.text}'.trim()) {
      setState(() {
        _displayNameCtrl.text = '${_firstNameCtrl.text} ${_lastNameCtrl.text}'
            .trim();
      });
    }
  }

  String? _normalizedDigits(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return digits;
  }

  String? _customerNumberForSave() {
    final value = _customerNumberCtrl.text.trim();
    if (value.isEmpty || value == 'CUS-00023') {
      return null;
    }
    return value;
  }

  Future<void> _saveCustomer() async {
    if (_displayNameCtrl.text.trim().isEmpty) {
      ZerpaiToast.error(context, 'Display Name is required');
      return;
    }

    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final customer = SalesCustomer(
        id: '',
        customerNumber: _customerNumberForSave(),
        displayName: _displayNameCtrl.text.trim(),
        customerType: _isBusiness ? 'Business' : 'Individual',
        salutation: _salutation,
        firstName: _firstNameCtrl.text.trim().isEmpty
            ? null
            : _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim().isEmpty
            ? null
            : _lastNameCtrl.text.trim(),
        companyName: _companyNameCtrl.text.trim().isEmpty
            ? null
            : _companyNameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _normalizedDigits(_phoneCtrl.text),
        mobilePhone: _normalizedDigits(_mobileCtrl.text),
        customerLanguage: _language,
        gstTreatment: _gstTreatment,
        placeOfSupply: _placeOfSupply,
        pan: _panCtrl.text.trim().isEmpty ? null : _panCtrl.text.trim(),
        taxPreference: _isTaxable ? 'Taxable' : 'Tax Exempt',
        creditLimit: _creditLimitCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_creditLimitCtrl.text.trim()),
        paymentTerms: _paymentTerms,
        enablePortal: _enablePortal,
        isRecurring: false,
      );

      final createdCustomer = await ref
          .read(salesOrderControllerProvider.notifier)
          .createCustomer(customer);

      if (!mounted) return;
      ZerpaiToast.success(
        context,
        'Customer ${createdCustomer.displayName} created successfully!',
      );
      Navigator.pop(context, createdCustomer);
    } catch (error) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to save customer');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showCustomerNumberPreferencesDialog() async {
    final currentNumber = _customerNumberCtrl.text.trim();
    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(currentNumber);
    final currentPrefix = match?.group(1)?.trim().isNotEmpty == true
        ? match!.group(1)!.trim()
        : 'CUS-';
    final currentNextNumber = match?.group(2)?.trim().isNotEmpty == true
        ? match!.group(2)!.trim()
        : '00023';

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CustomerNumberPreferencesDialog(
        currentPrefix: currentPrefix,
        currentNextNumber: currentNextNumber,
      ),
    );

    if (!mounted || result == null) return;

    final prefix = result['prefix']?.trim() ?? currentPrefix;
    final nextNumber = result['nextNumber']?.trim() ?? currentNextNumber;

    setState(() {
      _customerNumberCtrl.text = '$prefix$nextNumber';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(vertical: 0),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        width: 760,
        height: double.infinity,
        child: Column(
          children: [
            // Title Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'New Customer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            // Scrollable fields Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Form(
                  key: _dialogFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Type
                      _buildDialogRow(
                        label: 'Customer Type',
                        tooltip:
                            'Select whether the customer is a Business or an Individual.',
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: true,
                              groupValue: _isBusiness,
                              onChanged: (val) =>
                                  setState(() => _isBusiness = val ?? true),
                              activeColor: AppTheme.primaryBlue,
                            ),
                            const Text(
                              'Business',
                              style: TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 20),
                            Radio<bool>(
                              value: false,
                              groupValue: _isBusiness,
                              onChanged: (val) =>
                                  setState(() => _isBusiness = val ?? false),
                              activeColor: AppTheme.primaryBlue,
                            ),
                            const Text(
                              'Individual',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      // Primary Contact
                      _buildDialogRow(
                        label: 'Primary Contact',
                        tooltip:
                            'Salutation, First Name and Last Name of contact.',
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 440,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: FormDropdown<String>(
                                    height: 32,
                                    value: _salutation,
                                    items: _salutations,
                                    hint: 'Salutation',
                                    showSearch: false,
                                    onChanged: (v) {
                                      if (v != null)
                                        setState(() => _salutation = v);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CustomTextField(
                                    height: 32,
                                    controller: _firstNameCtrl,
                                    hintText: 'First Name',
                                    onChanged: (_) => _onNameChanged(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CustomTextField(
                                    height: 32,
                                    controller: _lastNameCtrl,
                                    hintText: 'Last Name',
                                    onChanged: (_) => _onNameChanged(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Company Name
                      _buildDialogRow(
                        label: 'Company Name',
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 220,
                            child: CustomTextField(
                              height: 32,
                              controller: _companyNameCtrl,
                              hintText: '',
                            ),
                          ),
                        ),
                      ),

                      // Display Name
                      _buildDialogRow(
                        label: 'Display Name',
                        required: true,
                        tooltip:
                            'This name will be displayed on transaction records.',
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 220,
                            child: CustomTextField(
                              height: 32,
                              controller: _displayNameCtrl,
                              hintText: 'Select or type to add',
                            ),
                          ),
                        ),
                      ),

                      // Email Address
                      _buildDialogRow(
                        label: 'Email Address',
                        tooltip: 'Customer contact email.',
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 220,
                            child: CustomTextField(
                              height: 32,
                              controller: _emailCtrl,
                              hintText: '',
                              prefixIcon: LucideIcons.mail,
                            ),
                          ),
                        ),
                      ),

                      // Customer Number
                      _buildDialogRow(
                        label: 'Customer Number',
                        required: true,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 220,
                            child: CustomTextField(
                              height: 32,
                              controller: _customerNumberCtrl,
                              hintText: 'CUS-00023',
                              suffixWidget: InkWell(
                                onTap: _showCustomerNumberPreferencesDialog,
                                child: const Icon(
                                  LucideIcons.settings,
                                  size: 16,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Phone
                      _buildDialogRow(
                        label: 'Phone',
                        tooltip: 'Customer telephone numbers.',
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 440,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Focus(
                                    onFocusChange: (hasFocus) {
                                      setState(() {
                                        _phoneFocused = hasFocus;
                                      });
                                    },
                                    child: MouseRegion(
                                      onEnter: (_) =>
                                          setState(() => _phoneHovered = true),
                                      onExit: (_) =>
                                          setState(() => _phoneHovered = false),
                                      child: Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: _phoneFocused
                                                ? AppTheme.primaryBlueDark
                                                : (_phoneHovered
                                                      ? AppTheme.infoBlue
                                                      : AppTheme.borderColor),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 55,
                                              child: TextField(
                                                controller: _phoneCodeCtrl,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                      border: InputBorder.none,
                                                      enabledBorder:
                                                          InputBorder.none,
                                                      focusedBorder:
                                                          InputBorder.none,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                          ),
                                                      isDense: true,
                                                      hintText: '+91',
                                                    ),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              height: 32,
                                              color: _phoneFocused
                                                  ? AppTheme.primaryBlueDark
                                                  : (_phoneHovered
                                                        ? AppTheme.infoBlue
                                                        : AppTheme.borderColor),
                                            ),
                                            Expanded(
                                              child: TextField(
                                                controller: _phoneCtrl,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                keyboardType:
                                                    TextInputType.phone,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                  LengthLimitingTextInputFormatter(
                                                    10,
                                                  ),
                                                ],
                                                decoration:
                                                    const InputDecoration(
                                                      border: InputBorder.none,
                                                      enabledBorder:
                                                          InputBorder.none,
                                                      focusedBorder:
                                                          InputBorder.none,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                          ),
                                                      isDense: true,
                                                      hintText: 'Work Phone',
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Focus(
                                    onFocusChange: (hasFocus) {
                                      setState(() {
                                        _mobileFocused = hasFocus;
                                      });
                                    },
                                    child: MouseRegion(
                                      onEnter: (_) =>
                                          setState(() => _mobileHovered = true),
                                      onExit: (_) => setState(
                                        () => _mobileHovered = false,
                                      ),
                                      child: Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: _mobileFocused
                                                ? AppTheme.primaryBlueDark
                                                : (_mobileHovered
                                                      ? AppTheme.infoBlue
                                                      : AppTheme.borderColor),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 55,
                                              child: TextField(
                                                controller: _mobileCodeCtrl,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                      border: InputBorder.none,
                                                      enabledBorder:
                                                          InputBorder.none,
                                                      focusedBorder:
                                                          InputBorder.none,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                          ),
                                                      isDense: true,
                                                      hintText: '+91',
                                                    ),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              height: 32,
                                              color: _mobileFocused
                                                  ? AppTheme.primaryBlueDark
                                                  : (_mobileHovered
                                                        ? AppTheme.infoBlue
                                                        : AppTheme.borderColor),
                                            ),
                                            Expanded(
                                              child: TextField(
                                                controller: _mobileCtrl,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                keyboardType:
                                                    TextInputType.phone,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                  LengthLimitingTextInputFormatter(
                                                    10,
                                                  ),
                                                ],
                                                decoration:
                                                    const InputDecoration(
                                                      border: InputBorder.none,
                                                      enabledBorder:
                                                          InputBorder.none,
                                                      focusedBorder:
                                                          InputBorder.none,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                          ),
                                                      isDense: true,
                                                      hintText: 'Mobile',
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Customer Language
                      _buildDialogRow(
                        label: 'Customer Language',
                        tooltip: 'Language preference for templates.',
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 220,
                            child: FormDropdown<String>(
                              height: 32,
                              value: _language,
                              items: _languages,
                              hint: 'English',
                              showSearch: false,
                              onChanged: (v) {
                                if (v != null) setState(() => _language = v);
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tabbed details pane (Other Details, Address, etc.)
                      TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryBlue,
                        unselectedLabelColor: AppTheme.textSecondary,
                        indicatorColor: AppTheme.primaryBlue,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: AppTheme.borderLight,
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Other Details'),
                          Tab(text: 'Address'),
                          Tab(text: 'Custom Fields'),
                          Tab(text: 'Reporting Tags'),
                          Tab(text: 'Remarks'),
                        ],
                      ),

                      SizedBox(
                        height: 480,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOtherDetailsTab(),
                            _buildAddressTab(),
                            _buildCustomFieldsTab(),
                            _buildReportingTagsTab(),
                            _buildRemarksTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Save / Cancel Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
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

  Widget _buildOtherDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // GST Treatment
          _buildDialogRow(
            label: 'GST Treatment',
            required: true,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: FormDropdown<String>(
                  height: 32,
                  value: _gstTreatment,
                  items: _gstTreatments,
                  hint: 'Select a GST treatment',
                  onChanged: (v) => setState(() => _gstTreatment = v),
                ),
              ),
            ),
          ),

          // Place of Supply
          _buildDialogRow(
            label: 'Place of Supply',
            required: true,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: FormDropdown<String>(
                  height: 32,
                  value: _placeOfSupply,
                  items: _states,
                  hint: 'Select State',
                  onChanged: (v) => setState(() => _placeOfSupply = v),
                ),
              ),
            ),
          ),

          // PAN
          _buildDialogRow(
            label: 'PAN',
            tooltip: 'Enter customer\'s 10-character Permanent Account Number.',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: CustomTextField(
                  height: 32,
                  controller: _panCtrl,
                  hintText: '',
                ),
              ),
            ),
          ),

          // Tax Preference
          _buildDialogRow(
            label: 'Tax Preference',
            required: true,
            child: Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _isTaxable,
                  onChanged: (val) => setState(() => _isTaxable = val ?? true),
                  activeColor: AppTheme.primaryBlue,
                ),
                const Text('Taxable', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 20),
                Radio<bool>(
                  value: false,
                  groupValue: _isTaxable,
                  onChanged: (val) => setState(() => _isTaxable = val ?? false),
                  activeColor: AppTheme.primaryBlue,
                ),
                const Text('Tax Exempt', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),

          // Currency
          _buildDialogRow(
            label: 'Currency',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: FormDropdown<String>(
                  height: 32,
                  value: _currency,
                  items: _currencies,
                  hint: 'Select Currency',
                  showSearch: false,
                  onChanged: (v) {
                    if (v != null) setState(() => _currency = v);
                  },
                ),
              ),
            ),
          ),

          // Credit Limit
          _buildDialogRow(
            label: 'Credit Limit',
            tooltip: 'Set maximum outstanding balance allowed for customer.',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: CustomTextField(
                  height: 32,
                  controller: _creditLimitCtrl,
                  hintText: '',
                  prefixWidget: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'INR',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Payment Terms
          _buildDialogRow(
            label: 'Payment Terms',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: FormDropdown<String>(
                  height: 32,
                  value: _paymentTerms,
                  items: _paymentTermOptions,
                  hint: 'Select Payment Terms',
                  showSearch: false,
                  onChanged: (v) {
                    if (v != null) setState(() => _paymentTerms = v);
                  },
                ),
              ),
            ),
          ),

          // Price List
          _buildDialogRow(
            label: 'Price List',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: FormDropdown<String>(
                  height: 32,
                  value: _priceList,
                  items: _priceLists,
                  hint: 'Select Price List',
                  allowClear: true,
                  showSearch: false,
                  onChanged: (v) => setState(() => _priceList = v),
                ),
              ),
            ),
          ),

          // Enable Portal
          _buildDialogRow(
            label: 'Enable Portal?',
            tooltip: 'Allow portal access for this customer to view invoices.',
            child: Row(
              children: [
                Checkbox(
                  value: _enablePortal,
                  onChanged: (v) => setState(() => _enablePortal = v ?? false),
                  activeColor: AppTheme.primaryBlue,
                ),
                const Text(
                  'Allow portal access for this customer',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),

          // Documents Upload
          _buildDialogRow(
            label: 'Documents',
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FileUploadButton(
                    files: _documents ?? [],
                    onFilesChanged: (updated) {
                      setState(() {
                        _documents = updated;
                      });
                    },
                    maxFiles: 10,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'You can upload a maximum of 10 files, 10MB each',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Add more details link
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add more details',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.primaryBlue.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFieldsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDialogRow(
            label: 'demo feild',
            tooltip: 'FOR TESTING',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: CustomTextField(
                  height: 32,
                  controller: _customDemoFieldCtrl,
                  forceUppercase: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Note: ',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorRed,
                    height: 1.55,
                  ),
                ),
                TextSpan(
                  text:
                      'You can add additional fields for your Customers and Vendors and have these show up on your PDFs by going to Settings -> Preferences -> Customers and Vendors. You can also refine the address format of your Customers and Vendors from there.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary.withValues(alpha: 0.95),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportingTagsTab() {
    const reportingTagOptions = <String>[
      'efewre',
      'dewewe',
      'wewew',
      'dsdsd',
      'wewe',
    ];
    const adgfOptions = <String>['00001', 'edrftgyhnuj'];
    const sheduleOptions = <String>['H', 'H1'];
    const demoAdvancedOptions = <String>['demo 1', 'demo 2'];

    Widget buildTagDropdown({
      required String? value,
      required List<String> items,
      required ValueChanged<String?> onChanged,
      bool allowClear = false,
      bool showSearch = false,
      Widget Function(String item, bool isSelected, bool isHovered)? itemBuilder,
    }) {
      final resolvedValue = value == 'None' ? null : value;
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 220,
          child: FormDropdown<String>(
            height: 32,
            value: resolvedValue,
            items: items.where((item) => item != 'None').toList(),
            hint: 'None',
            showSearch: showSearch,
            allowClear: allowClear,
            borderRadius: BorderRadius.circular(8),
            menuMaxHeight: 180,
            maxVisibleItems: 4,
            itemBuilder: itemBuilder ?? _buildHoverOnlyDropdownItem,
            onChanged: onChanged,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        children: [
          _buildDialogRow(
            label: 'ADGF',
            child: buildTagDropdown(
              value: _reportingTagAdgf,
              items: adgfOptions,
              showSearch: true,
              onChanged: (value) => setState(() => _reportingTagAdgf = value),
            ),
          ),
          _buildDialogRow(
            label: 'shedule',
            child: buildTagDropdown(
              value: _reportingTagShedule,
              items: sheduleOptions,
              showSearch: true,
              onChanged: (value) => setState(() => _reportingTagShedule = value),
            ),
          ),
          _buildDialogRow(
            label: 'demo advaced\nreporting tag',
            child: buildTagDropdown(
              value: _reportingTagDemoAdvaced,
              items: demoAdvancedOptions,
              showSearch: true,
              onChanged: (value) =>
                  setState(() => _reportingTagDemoAdvaced = value),
            ),
          ),
          _buildDialogRow(
            label: 'erhj',
            required: true,
            child: buildTagDropdown(
              value: _reportingTagErhj,
              items: reportingTagOptions,
              allowClear: true,
              showSearch: true,
              itemBuilder: _buildReportingTagErhjDropdownItem,
              onChanged: (value) => setState(() => _reportingTagErhj = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 18, right: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildAddressColumn(
                  title: 'Billing Address',
                  attentionCtrl: _billingAttentionCtrl,
                  selectedCountry: _billingCountry,
                  onCountryChanged: (value) {
                    setState(() {
                      _billingCountry = value;
                      _billingState = null;
                    });
                  },
                  street1Ctrl: _billingStreet1Ctrl,
                  street2Ctrl: _billingStreet2Ctrl,
                  cityCtrl: _billingCityCtrl,
                  selectedState: _billingState,
                  onStateChanged: (value) =>
                      setState(() => _billingState = value),
                  pinCodeCtrl: _billingPinCodeCtrl,
                  phoneCode: _billingPhoneCode,
                  onPhoneCodeChanged: (value) {
                    setState(() => _billingPhoneCode = value ?? '+91');
                  },
                  phoneCtrl: _billingPhoneCtrl,
                  faxCtrl: _billingFaxCtrl,
                ),
              ),
              const SizedBox(width: 44),
              Expanded(
                child: _buildAddressColumn(
                  title: 'Shipping Address',
                  showCopyBilling: true,
                  onCopyBilling: _copyBillingToShipping,
                  attentionCtrl: _shippingAttentionCtrl,
                  selectedCountry: _shippingCountry,
                  onCountryChanged: (value) {
                    setState(() {
                      _shippingCountry = value;
                      _shippingState = null;
                    });
                  },
                  street1Ctrl: _shippingStreet1Ctrl,
                  street2Ctrl: _shippingStreet2Ctrl,
                  cityCtrl: _shippingCityCtrl,
                  selectedState: _shippingState,
                  onStateChanged: (value) =>
                      setState(() => _shippingState = value),
                  pinCodeCtrl: _shippingPinCodeCtrl,
                  phoneCode: _shippingPhoneCode,
                  onPhoneCodeChanged: (value) {
                    setState(() => _shippingPhoneCode = value ?? '+91');
                  },
                  phoneCtrl: _shippingPhoneCtrl,
                  faxCtrl: _shippingFaxCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFF59E0B), width: 2),
              ),
            ),
            child: const Text(
              'Note:\n'
              '• Add and manage additional addresses from this Customers and Vendors details section.\n'
              '• You can customise how customers\' addresses are displayed in transaction PDFs. To do this, go to Settings > Preferences > Customers and Vendors, and navigate to the Address Format sections.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.55,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(text: 'Remarks '),
                TextSpan(
                  text: '(For Internal Use)',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildResizableTextArea(
            controller: _remarksCtrl,
            height: _remarksHeight,
            onHeightChanged: (value) => setState(() => _remarksHeight = value),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressColumn({
    required String title,
    bool showCopyBilling = false,
    VoidCallback? onCopyBilling,
    required TextEditingController attentionCtrl,
    required String? selectedCountry,
    required ValueChanged<String?> onCountryChanged,
    required TextEditingController street1Ctrl,
    required TextEditingController street2Ctrl,
    required TextEditingController cityCtrl,
    required String? selectedState,
    required ValueChanged<String?> onStateChanged,
    required TextEditingController pinCodeCtrl,
    required String phoneCode,
    required ValueChanged<String?> onPhoneCodeChanged,
    required TextEditingController phoneCtrl,
    required TextEditingController faxCtrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            if (showCopyBilling) ...[
              const SizedBox(width: 8),
              const Text(
                '(',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 2),
              const Icon(
                LucideIcons.arrowDown,
                size: 13,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onCopyBilling,
                child: const Text(
                  'Copy billing address',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                ')',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        _buildAddressFieldRow(
          'Attention',
          CustomTextField(
            height: 32,
            controller: attentionCtrl,
            forceUppercase: false,
          ),
        ),
        _buildAddressFieldRow(
          'Country/Region',
          FormDropdown<String>(
            height: 32,
            value: selectedCountry,
            items: _countries,
            hint: 'Select',
            showSearch: true,
            menuMaxHeight: 260,
            maxVisibleItems: 7,
            itemBuilder: _buildHoverOnlyDropdownItem,
            onChanged: onCountryChanged,
          ),
        ),
        _buildAddressFieldRow(
          'Address',
          Column(
            children: [
              _buildResizableAddressInput(
                controller: street1Ctrl,
                hintText: 'Street 1',
                height: title == 'Billing Address'
                    ? _billingStreet1Height
                    : _shippingStreet1Height,
                onHeightChanged: (height) {
                  setState(() {
                    if (title == 'Billing Address') {
                      _billingStreet1Height = height;
                    } else {
                      _shippingStreet1Height = height;
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildResizableAddressInput(
                controller: street2Ctrl,
                hintText: 'Street 2',
                height: title == 'Billing Address'
                    ? _billingStreet2Height
                    : _shippingStreet2Height,
                onHeightChanged: (height) {
                  setState(() {
                    if (title == 'Billing Address') {
                      _billingStreet2Height = height;
                    } else {
                      _shippingStreet2Height = height;
                    }
                  });
                },
              ),
            ],
          ),
        ),
        _buildAddressFieldRow(
          'City',
          CustomTextField(
            height: 32,
            controller: cityCtrl,
            forceUppercase: false,
          ),
        ),
        _buildAddressFieldRow(
          'State',
          FormDropdown<String>(
            height: 32,
            value: selectedState,
            items: _states,
            hint: 'Select or type to add',
            allowCustomValue: true,
            showSearch: true,
            menuMaxHeight: 260,
            maxVisibleItems: 7,
            itemBuilder: _buildHoverOnlyDropdownItem,
            onChanged: onStateChanged,
          ),
        ),
        _buildAddressFieldRow(
          'Pin Code',
          CustomTextField(
            height: 32,
            controller: pinCodeCtrl,
            forceUppercase: false,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
        ),
        _buildAddressFieldRow(
          'Phone',
          PhoneInputField(
            height: 32,
            selectedPrefix: phoneCode,
            controller: phoneCtrl,
            hintText: 'Phone',
            onPrefixChanged: onPhoneCodeChanged,
          ),
        ),
        _buildAddressFieldRow(
          'Fax Number',
          CustomTextField(
            height: 32,
            controller: faxCtrl,
            forceUppercase: false,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressFieldRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: field),
        ],
      ),
    );
  }

  Widget _buildResizableAddressInput({
    required TextEditingController controller,
    required String hintText,
    required double height,
    required ValueChanged<double> onHeightChanged,
  }) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomTextField(
              height: height,
              controller: controller,
              hintText: hintText,
              forceUppercase: false,
              maxLines: null,
              padding: const EdgeInsets.fromLTRB(10, 10, 24, 10),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final adjustedDelta = details.delta.dy * 1.8;
                  final nextHeight = (height + adjustedDelta).clamp(
                    50.0,
                    140.0,
                  );
                  onHeightChanged(nextHeight);
                },
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CustomPaint(painter: _InlineResizeHandlePainter()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResizableTextArea({
    required TextEditingController controller,
    required double height,
    required ValueChanged<double> onHeightChanged,
  }) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomTextField(
              height: height,
              controller: controller,
              hintText: '',
              forceUppercase: false,
              maxLines: null,
              padding: const EdgeInsets.fromLTRB(10, 10, 24, 10),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final adjustedDelta = details.delta.dy * 1.8;
                  final nextHeight = (height + adjustedDelta).clamp(
                    94.0,
                    220.0,
                  );
                  onHeightChanged(nextHeight);
                },
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CustomPaint(painter: _InlineResizeHandlePainter()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoverOnlyDropdownItem(
    String item,
    bool isSelected,
    bool isHovered,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          item,
          style: TextStyle(
            fontSize: 12.5,
            color: isHovered ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildReportingTagErhjDropdownItem(
    String item,
    bool isSelected,
    bool isHovered,
  ) {
    final Color foregroundColor = isHovered ? Colors.white : AppTheme.textPrimary;
    final Color checkColor = isHovered ? Colors.white : const Color(0xFF3B82F6);
    final String displayText = switch (item) {
      'wewew' => '• wewew',
      'dsdsd' => '• dsdsd',
      _ => item,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isHovered
              ? const Color(0xFF3B82F6)
              : (isSelected ? const Color(0xFFF3F4F6) : Colors.white),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: foregroundColor,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    size: 15,
                    color: checkColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogRow({
    required String label,
    bool required = false,
    String? tooltip,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        text: label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: required
                              ? AppTheme.errorRed
                              : AppTheme.textPrimary,
                        ),
                        children: required
                            ? const [
                                TextSpan(
                                  text: ' *',
                                  style: TextStyle(
                                    color: AppTheme.errorRed,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  if (tooltip != null) ...[
                    const SizedBox(width: 4),
                    ZTooltip(
                      message: tooltip,
                      direction: ZTooltipDirection.bottom,
                      child: const Icon(
                        LucideIcons.helpCircle,
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
class _InlineResizeHandlePainter extends CustomPainter {
  const _InlineResizeHandlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textMuted
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.25, size.height),
      Offset(size.width, size.height * 0.25),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.55, size.height),
      Offset(size.width, size.height * 0.55),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Invoice Number Preferences Dialog
// ═══════════════════════════════════════════════════════════════════════════════

class _InvoiceNumberPreferencesDialog extends StatefulWidget {
  final String location;
  final String transactionSeries;
  final String currentPrefix;
  final String currentNextNumber;

  const _InvoiceNumberPreferencesDialog({
    required this.location,
    required this.transactionSeries,
    required this.currentPrefix,
    required this.currentNextNumber,
  });

  @override
  State<_InvoiceNumberPreferencesDialog> createState() =>
      _InvoiceNumberPreferencesDialogState();
}

class _InvoiceNumberPreferencesDialogState
    extends State<_InvoiceNumberPreferencesDialog> {
  static const List<String> _prefixPlaceholderOptions = <String>[
    'Fiscal Year Start',
    'Fiscal Year End',
    'Transaction Year',
    'Transaction Date',
    'Transaction Month',
  ];
  static const List<String> _prefixPlaceholderFormats = <String>['YY', 'YYYY'];

  // 'auto' or 'manual'
  String _mode = 'auto';
  late TextEditingController _prefixCtrl;
  late TextEditingController _nextNumberCtrl;
  bool _restartFiscalYear = false;

  @override
  void initState() {
    super.initState();
    _prefixCtrl = TextEditingController(text: widget.currentPrefix);
    _nextNumberCtrl = TextEditingController(
      text: widget.currentNextNumber.isEmpty
          ? '00006'
          : widget.currentNextNumber.padLeft(5, '0'),
    );
  }

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _nextNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _showPrefixPlaceholderMenu(BuildContext context) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          button.size.bottomLeft(Offset.zero),
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final selectedValue = await showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 30,
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'PLACEHOLDER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ),
        ..._prefixPlaceholderOptions.map((option) {
          return PopupMenuItem<String>(
            value: option,
            padding: EdgeInsets.zero,
            height: 36,
            child: _HoverablePlaceholderMenuItem(
              text: option,
              hasSubmenu: true,
              submenuItems: _prefixPlaceholderFormats,
              onSubmenuSelected: (format) {
                Navigator.of(context).pop('{$option-$format}');
              },
            ),
          );
        }),
      ],
    );

    if (!mounted || selectedValue == null) return;
    setState(() {
      _prefixCtrl.text += selectedValue;
      _prefixCtrl.selection = TextSelection.collapsed(
        offset: _prefixCtrl.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.only(
        top: 0,
        left: 80,
        right: 80,
        bottom: 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, minWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title bar ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              decoration: const BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Configure Retainer Invoice Number Preferences',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location + Associated Series
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.location,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 48),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Associated Series',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.transactionSeries,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(
                    color: AppTheme.borderColor.withValues(alpha: 0.5),
                    height: 1,
                    thickness: 1,
                  ),
                  const SizedBox(height: 20),

                  // Info text
                  const Text(
                    'Your retainer invoice numbers are set on auto-generate mode to save\nyour time. Are you sure about changing this setting?',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Option 1: Continue auto-generating ───────────────
                  InkWell(
                    onTap: () => setState(() => _mode = 'auto'),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Radio<String>(
                          value: 'auto',
                          groupValue: _mode,
                          onChanged: (v) => setState(() => _mode = v!),
                          activeColor: AppTheme.primaryBlue,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Continue auto-generating retainer invoice numbers',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.helpCircle,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),

                  // Auto-generate details (only visible when mode == auto)
                  if (_mode == 'auto') ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Prefix + Next Number
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Prefix',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 150,
                                    height: 36,
                                    child: Builder(
                                      builder: (buttonContext) {
                                        return TextField(
                                          controller: _prefixCtrl,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            suffixIcon: InkWell(
                                              onTap: () =>
                                                  _showPrefixPlaceholderMenu(
                                                    buttonContext,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                  top: 9,
                                                  bottom: 9,
                                                ),
                                                width: 14,
                                                height: 14,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.primaryBlue,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 9,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            suffixIconConstraints:
                                                const BoxConstraints(
                                                  minWidth: 32,
                                                  minHeight: 32,
                                                ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 8,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: AppTheme.borderColor,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: AppTheme.borderColor,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: AppTheme.primaryBlue,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Radio bullet between prefix and next number
                              Padding(
                                padding: const EdgeInsets.only(top: 22),
                                child: Radio<bool>(
                                  value: true,
                                  groupValue: true,
                                  onChanged: (_) {},
                                  activeColor: AppTheme.primaryBlue,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Next Number',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 140,
                                    height: 36,
                                    child: TextField(
                                      controller: _nextNumberCtrl,
                                      style: const TextStyle(fontSize: 13),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.borderColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.borderColor,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Fiscal year restart checkbox
                          InkWell(
                            onTap: () => setState(
                              () => _restartFiscalYear = !_restartFiscalYear,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Checkbox(
                                    value: _restartFiscalYear,
                                    onChanged: (v) => setState(
                                      () => _restartFiscalYear = v ?? false,
                                    ),
                                    activeColor: AppTheme.primaryBlue,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    side: const BorderSide(
                                      color: AppTheme.borderColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Restart numbering for retainer invoices at the start of each fiscal year.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // ── Option 2: Enter manually ─────────────────────────
                  InkWell(
                    onTap: () => setState(() => _mode = 'manual'),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Radio<String>(
                          value: 'manual',
                          groupValue: _mode,
                          onChanged: (v) => setState(() => _mode = v!),
                          activeColor: AppTheme.primaryBlue,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Enter retainer invoice numbers manually',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Action buttons ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                children: [
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'mode': _mode,
                          'prefix': _prefixCtrl.text,
                          'nextNumber': _nextNumberCtrl.text,
                          'restartFiscalYear': _restartFiscalYear,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3CB371),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        elevation: 0,
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
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 36,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
}

class _CustomerNumberPreferencesDialog extends StatefulWidget {
  final String currentPrefix;
  final String currentNextNumber;

  const _CustomerNumberPreferencesDialog({
    required this.currentPrefix,
    required this.currentNextNumber,
  });

  @override
  State<_CustomerNumberPreferencesDialog> createState() =>
      _CustomerNumberPreferencesDialogState();
}

class _CustomerNumberPreferencesDialogState
    extends State<_CustomerNumberPreferencesDialog> {
  late final TextEditingController _prefixCtrl;
  late final TextEditingController _nextNumberCtrl;

  @override
  void initState() {
    super.initState();
    _prefixCtrl = TextEditingController(text: widget.currentPrefix);
    _nextNumberCtrl = TextEditingController(text: widget.currentNextNumber);
  }

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _nextNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SizedBox(
        width: 570,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Configure Customer Numbers Preferences',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer numbers will be auto-generated based on the preferences\nbelow. For each new customer that is created, the number after the\nprefix will be incremented by 1.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textPrimary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 112,
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
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 32,
                              child: TextField(
                                controller: _prefixCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),
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
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 32,
                              child: TextField(
                                controller: _nextNumberCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF5EA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Note: If you want to change only this customer's number without affecting the current series, you can edit it directly from the Customer Number field after closing this popup.",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'prefix': _prefixCtrl.text,
                          'nextNumber': _nextNumberCtrl.text,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22A95E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 32,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        backgroundColor: const Color(0xFFF3F4F6),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
}

class _HoverPopupItem extends StatefulWidget {
  final String text;

  const _HoverPopupItem({required this.text});

  @override
  State<_HoverPopupItem> createState() => _HoverPopupItemState();
}

class _HoverPopupItemState extends State<_HoverPopupItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: double.infinity,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        color: _isHovered ? AppTheme.primaryBlue : Colors.white,
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: 12,
            color: _isHovered ? Colors.white : AppTheme.textPrimary,
            fontWeight: _isHovered ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _HoverablePlaceholderMenuItem extends StatefulWidget {
  final String text;
  final bool hasSubmenu;
  final List<String> submenuItems;
  final ValueChanged<String>? onSubmenuSelected;

  const _HoverablePlaceholderMenuItem({
    required this.text,
    this.hasSubmenu = false,
    this.submenuItems = const <String>[],
    this.onSubmenuSelected,
  });

  @override
  State<_HoverablePlaceholderMenuItem> createState() =>
      _HoverablePlaceholderMenuItemState();
}

class _HoverablePlaceholderMenuItemState
    extends State<_HoverablePlaceholderMenuItem> {
  bool _isHovered = false;
  bool _isHoveringSubmenu = false;
  OverlayEntry? _submenuOverlay;
  final LayerLink _layerLink = LayerLink();

  void _showSubmenu() {
    if (_submenuOverlay != null) return;

    final overlay = Overlay.of(context);
    _submenuOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideSubmenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(4, 0),
              child: Material(
                elevation: 6,
                color: Colors.transparent,
                child: MouseRegion(
                  onEnter: (_) => _isHoveringSubmenu = true,
                  onExit: (_) {
                    _isHoveringSubmenu = false;
                    Future<void>.delayed(const Duration(milliseconds: 50), () {
                      if (!_isHovered && !_isHoveringSubmenu) {
                        _hideSubmenu();
                      }
                    });
                  },
                  child: Container(
                    width: 124,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.submenuItems.map((item) {
                        return _PlaceholderSubmenuItem(
                          text: item,
                          onTap: () {
                            _hideSubmenu();
                            widget.onSubmenuSelected?.call(item);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_submenuOverlay!);
  }

  void _hideSubmenu() {
    _submenuOverlay?.remove();
    _submenuOverlay = null;
  }

  @override
  void dispose() {
    _hideSubmenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        if (widget.hasSubmenu) {
          _showSubmenu();
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        if (widget.hasSubmenu) {
          Future<void>.delayed(const Duration(milliseconds: 50), () {
            if (!_isHovered && !_isHoveringSubmenu) {
              _hideSubmenu();
            }
          });
        }
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        color: _isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 12,
                  color: _isHovered ? Colors.white : AppTheme.textPrimary,
                  fontWeight: _isHovered ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (widget.hasSubmenu)
              Icon(
                Icons.chevron_right,
                size: 14,
                color: _isHovered ? Colors.white : AppTheme.textSecondary,
              ),
          ],
        ),
      ),
    );

    if (widget.hasSubmenu) {
      content = CompositedTransformTarget(link: _layerLink, child: content);
    }

    return content;
  }
}

class _PlaceholderSubmenuItem extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _PlaceholderSubmenuItem({required this.text, required this.onTap});

  @override
  State<_PlaceholderSubmenuItem> createState() =>
      _PlaceholderSubmenuItemState();
}

class _PlaceholderSubmenuItemState extends State<_PlaceholderSubmenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          color: _isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 12,
              color: _isHovered ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerDetailsDrawer extends StatefulWidget {
  final String customerName;
  final VoidCallback onClose;

  const _CustomerDetailsDrawer({
    required this.customerName,
    required this.onClose,
  });

  @override
  State<_CustomerDetailsDrawer> createState() => _CustomerDetailsDrawerState();
}

class _CustomerDetailsDrawerState extends State<_CustomerDetailsDrawer> {
  String _activeTab = 'Details';
  bool _contactPersonsExpanded = true;
  bool _addressExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(-2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEFF1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.customerName.isNotEmpty
                              ? widget.customerName[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF78909C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.customerName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ZTooltip(
                                  message: 'View in Customers module',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {},
                                      child: const Icon(
                                        LucideIcons.externalLink,
                                        size: 14,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.building,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mail,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tabs Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTabButton('Details'),
                  const SizedBox(width: 24),
                  _buildTabButton('Activity Log'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppTheme.borderLight),

            // Content Pane
            Expanded(
              child: _activeTab == 'Details'
                  ? _buildDetailsView()
                  : _buildActivityLogView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label) {
    final isActive = _activeTab == label;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _activeTab = label),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppTheme.primaryBlue
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            Container(
              height: 2,
              width: label == 'Activity Log' ? 80 : 40,
              color: isActive ? AppTheme.primaryBlue : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Financial summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Outstanding Receivables',
                  value: '₹0.00',
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Unused Credits',
                  value: '₹0.00',
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Contact Details Section
          _buildDetailsSection(),
          const SizedBox(height: 16),

          // Accordion items
          _buildAccordionSection(
            title: 'Contact Persons',
            count: 1,
            isExpanded: _contactPersonsExpanded,
            onTap: () => setState(
              () => _contactPersonsExpanded = !_contactPersonsExpanded,
            ),
            content: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFECEFF1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.customerName.isNotEmpty
                            ? widget.customerName[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF78909C),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.star,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customerName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mail,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '-',
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
            ),
          ),
          const SizedBox(height: 12),
          _buildAccordionSection(
            title: 'Address',
            isExpanded: _addressExpanded,
            onTap: () => setState(() => _addressExpanded = !_addressExpanded),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.fileText,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Billing Address',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8, left: 6),
                  padding: const EdgeInsets.only(left: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customerName.toLowerCase().replaceAll(' ', ''),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'malayanakath(h)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'vengoor (po)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'perinthalmanna',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'Kerala 679322',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'India',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'Phone: +91-9895357101',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 28, color: AppTheme.borderLight),
                Row(
                  children: [
                    const SizedBox(width: 22),
                    const Text(
                      'Shipping Address',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8, left: 6),
                  padding: const EdgeInsets.only(left: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customerName.contains(' ')
                            ? widget.customerName.toLowerCase().replaceAll(
                                ' ',
                                '.',
                              )
                            : '${widget.customerName.toLowerCase()}.m',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'malayanakath(h)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'vengoor',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'PERINTHALMANNA',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'perinthalmanna',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'kerala 679322',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'India',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'Phone: +91-08606259910',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTimelineItem(
            user: 'zabnixprivatelimited',
            timestamp: '05-06-2026 07:46 PM',
            action: 'Retainer Invoice RET-00008 marked as sent',
            isCreatedAction: false,
          ),
          _buildTimelineItem(
            user: 'zabnixprivatelimited',
            timestamp: '05-06-2026 07:40 PM',
            action: 'Retainer Invoice RET-00006 of amount ₹10,000.00 created',
            isCreatedAction: true,
          ),
          _buildTimelineItem(
            user: 'zabnixprivatelimited',
            timestamp: '30-05-2026 04:39 PM',
            action: 'Invoice INV-000086 of amount ₹1,853.00 created',
            isCreatedAction: true,
          ),
          _buildTimelineItem(
            user: 'zabnixprivatelimited',
            timestamp: '30-05-2026 04:38 PM',
            action: 'Sales Order SO-00050 emailed',
            isCreatedAction: false,
          ),
          _buildTimelineItem(
            user: 'zabnixprivatelimited',
            timestamp: '30-05-2026 04:39 PM',
            action: 'Sales Order SO-00050 marked as open',
            isCreatedAction: false,
          ),
          _buildTimelineItem(
            user: 'zabnixprivatelimited',
            timestamp: '30-05-2026 04:39 PM',
            action: 'Sales Order SO-00050 of amount ₹1,853.00 created',
            isCreatedAction: true,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String user,
    required String timestamp,
    required String action,
    required bool isCreatedAction,
    bool isLast = false,
  }) {
    final circleColor = isCreatedAction
        ? const Color(0xFFFEFCE8)
        : const Color(0xFFFFF7ED);
    final borderColor = isCreatedAction
        ? const Color(0xFFFEF9C3)
        : const Color(0xFFFFEDD5);
    final iconColor = isCreatedAction
        ? const Color(0xFFEAB308)
        : const Color(0xFFF97316);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Center(
                  child: Icon(LucideIcons.fileText, size: 12, color: iconColor),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 1.5, color: const Color(0xFFE5E7EB)),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '•',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Widget icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 12),
          _buildDetailRow('Customer Type', 'Individual'),
          _buildDetailRow('Currency', 'INR'),
          _buildDetailRow('Credit Limit', '₹0.00'),
          _buildDetailRow('Payment Terms', 'Net 360'),
          _buildDetailRow('Portal Status', 'Disabled'),
          _buildDetailRow('Customer Language', 'English'),
          _buildDetailRow('Price List', 'Pricelist'),
          _buildDetailRow('GST Treatment', 'Unregistered Business'),
          _buildDetailRow('Place of Supply', 'Kerala'),
          _buildDetailRow('Tax Preference', 'Taxable', isLast: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionSection({
    required String title,
    int? count,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.chevron_right,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(padding: const EdgeInsets.all(16), child: content),
          ],
        ],
      ),
    );
  }
}
