import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/transaction_series_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/models/account_node.dart' as shared_account;
import 'package:zerpai_erp/modules/purchases/payments_made/presentation/widgets/tax_preferences_popover.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/modules/purchases/payments_made/presentation/pages/purchases_payments_made_list.dart'
    hide PaymentMade;
import 'package:zerpai_erp/shared/utils/org_scope_resolver.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/widgets/vendor_sidebar.dart';
import 'package:zerpai_erp/modules/purchases/bills/providers/purchases_bills_provider.dart';
import 'package:zerpai_erp/modules/purchases/bills/models/purchases_bills_bill_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/modules/purchases/payments_made/providers/purchases_payments_made_provider.dart';
import 'package:zerpai_erp/modules/purchases/payments_made/models/purchases_payments_made_model.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/shared/utils/web_safe_platform_file.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';

class PaymentsMadeTdsRateItem {
  final String id;
  final String name;
  final double rate;
  const PaymentsMadeTdsRateItem({
    required this.id,
    required this.name,
    required this.rate,
  });

  factory PaymentsMadeTdsRateItem.fromJson(Map<String, dynamic> json) {
    return PaymentsMadeTdsRateItem(
      id: json['id']?.toString() ?? '',
      name: (json['tax_name'] ?? json['tds_name'] ?? '').toString(),
      rate:
          double.tryParse(
            (json['base_rate'] ?? json['tds_rate'] ?? '0').toString(),
          ) ??
          0.0,
    );
  }
}

final paymentsMadeTdsRatesProvider =
    FutureProvider<List<PaymentsMadeTdsRateItem>>((ref) async {
      try {
        final rows = await Supabase.instance.client
            .from('tds_rates')
            .select('id, tax_name, base_rate')
            .eq('is_active', true)
            .order('base_rate');

        return (rows as List)
            .map(
              (r) => PaymentsMadeTdsRateItem.fromJson(
                Map<String, dynamic>.from(r as Map),
              ),
            )
            .where((t) => t.id.isNotEmpty && t.name.isNotEmpty)
            .toList();
      } catch (e) {
        debugPrint('tds_rates fetch failed: $e');
        return const [];
      }
    });

class TaxItem {
  final String label;
  final bool isHeader;

  const TaxItem(this.label, {this.isHeader = false});
}

final paymentsMadeTaxesProvider = FutureProvider<List<TaxItem>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final groupRows = await supabase
        .from('tax_groups')
        .select('tax_group_name')
        .eq('is_active', true);
    final rateRows = await supabase
        .from('tax_rates')
        .select('tax_name')
        .eq('is_active', true);

    final List<TaxItem> items = [];
    items.add(const TaxItem('Tax Groups', isHeader: true));
    for (final r in groupRows) {
      final name = r['tax_group_name']?.toString() ?? '';
      if (name.isNotEmpty) items.add(TaxItem(name));
    }
    items.add(const TaxItem('Tax Rates', isHeader: true));
    for (final r in rateRows) {
      final name = r['tax_name']?.toString() ?? '';
      if (name.isNotEmpty) items.add(TaxItem(name));
    }
    return items;
  } catch (e) {
    debugPrint('taxes fetch failed: $e');
    return const [];
  }
});

class PaidThroughItem {
  final String? id;
  final String label;
  final bool isHeader;
  final bool isBullet;

  const PaidThroughItem(
    this.label, {
    this.id,
    this.isHeader = false,
    this.isBullet = false,
  });
}

class CreatePaymentMadePage extends ConsumerStatefulWidget {
  final List<String>? billIds;
  final String? paymentId;
  final String? paymentNumber;

  const CreatePaymentMadePage({
    super.key,
    this.billIds,
    this.paymentId,
    this.paymentNumber,
  });

  @override
  ConsumerState<CreatePaymentMadePage> createState() =>
      _CreatePaymentMadePageState();
}

class _CreatePaymentMadePageState extends ConsumerState<CreatePaymentMadePage> {
  PaymentNumberPreferences _paymentPreferences = const PaymentNumberPreferences(
    autoGenerate: true,
    autoPrefix: 'PAY-',
    nextNumber: '98',
    manualPrefix: '',
    manualPaymentNumber: '',
    restartFiscalYear: false,
  );
  final _paymentNumberController = TextEditingController(text: '98');
  final _paymentAmountController = TextEditingController();
  final _paymentReferenceController = TextEditingController();
  final _paymentDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _descriptionOfSupplyController = TextEditingController();

  final LayerLink _uploadDropdownLink = LayerLink();
  final LayerLink _fileBadgeLink = LayerLink();
  final LayerLink _billPaymentAmountLink = LayerLink();
  OverlayEntry? _uploadDropdownOverlayEntry;
  OverlayEntry? _fileBadgeOverlayEntry;
  OverlayEntry? _paymentAmountReflectionOverlayEntry;
  bool _isUploadDropdownOpen = false;
  List<PlatformFile> _uploadedFiles = [];

  final ScrollController _formScrollController = ScrollController();
  bool _isFormAtTop = true;
  bool _isSaving = false;
  bool _isLoadingExistingPayment = false;
  String? _editingPaymentDbId;

  Vendor? _selectedVendor;
  final Map<String, TextEditingController> _billPaymentControllers = {};
  final Map<String, String> _billPaymentDates = {};
  final Map<String, GlobalKey> _billDateKeys = {};
  final Set<String> _hoveredBillDateIds = <String>{};
  String? _paymentTransactionSeriesId;
  List<TransactionSeriesOption> _paymentTransactionSeriesOptions = const [];
  String _paymentLocation = 'ZABNIX PRIVATE LIMITED';
  DateTime _paymentDateVal = DateTime.now();
  String _paymentMode = 'Cash';
  List<String> _paymentModeOptions = List<String>.from(_defaultPaymentModes);
  PaidThroughItem? _paymentPaidFrom;
  PaidThroughItem? _depositTo;
  bool _showVendorDetailsPanel = false;
  bool _isBillPayment = true;
  bool _payFullAmount = false;

  String _sourceOfSupply = '[KL] - Kerala';
  String _destinationOfSupply = '[KL] - Kerala';
  String? _location;
  String? _transferToAccountId;
  final _erhjController = TextEditingController();
  bool _reverseCharge = false;
  String? _selectedTdsTax;
  TaxItem? _selectedTax;
  String? _pendingPaidThroughAccountId;
  String? _pendingDepositToAccountId;
  String? _pendingTdsTaxId;

  // Tax options loaded dynamically â€” see paymentsMadeTaxesProvider

  static const List<String> _statesOptions = [
    '[KL] - Kerala',
    '[KA] - Karnataka',
    '[TN] - Tamil Nadu',
    '[MH] - Maharashtra',
    '[DL] - Delhi',
  ];

  static const List<String> _defaultPaymentModes = [
    'Bank Remittance',
    'Bank Transfer',
    'Card',
    'Cash',
    'Cheque',
    'Credit Card',
    'Debit Card',
  ];

  final GlobalKey _paymentDateKey = GlobalKey();

  List<PaidThroughItem> _buildPaidThroughOptions(List<AccountNode> roots) {
    final List<PaidThroughItem> options = [];

    final List<AccountNode> allAccounts = [];
    void flatten(List<AccountNode> nodes) {
      for (final node in nodes) {
        allAccounts.add(node);
        if (node.children.isNotEmpty) {
          flatten(node.children);
        }
      }
    }

    flatten(roots);

    final Map<String, AccountNode> accountMap = {
      for (final acc in allAccounts) acc.id: acc,
    };

    final Set<String> parentIds = {};
    for (final acc in allAccounts) {
      if (acc.parentId != null && acc.parentId!.isNotEmpty) {
        parentIds.add(acc.parentId!);
      }
    }

    final Set<String> processedIds = {};

    for (final parentId in parentIds) {
      final parentNode = accountMap[parentId];
      if (parentNode == null) continue;

      options.add(
        PaidThroughItem(parentNode.systemAccountName, isHeader: true),
      );
      processedIds.add(parentId);

      final children = allAccounts
          .where((acc) => acc.parentId == parentId)
          .toList();
      for (final child in children) {
        options.add(
          PaidThroughItem(
            child.systemAccountName,
            id: child.id,
            isBullet: true,
          ),
        );
        processedIds.add(child.id);
      }
    }

    for (final acc in allAccounts) {
      if (processedIds.contains(acc.id)) continue;

      final String nameLower = acc.systemAccountName.toLowerCase();
      if (nameLower == 'assets' ||
          nameLower == 'liabilities' ||
          nameLower == 'income' ||
          nameLower == 'expenses' ||
          nameLower == 'equity') {
        continue;
      }

      options.add(
        PaidThroughItem(
          acc.systemAccountName,
          id: acc.id,
          isHeader: false,
          isBullet: false,
        ),
      );
    }

    return options;
  }

  PaidThroughItem? _findPaidThroughItemById(
    List<PaidThroughItem> options,
    String? id,
  ) {
    if (id == null || id.isEmpty) return null;
    for (final option in options) {
      if (!option.isHeader && option.id == id) {
        return option;
      }
    }
    return null;
  }

  List<shared_account.AccountNode> _buildDepositAccountTree(
    List<AccountNode> roots,
  ) {
    final flatAccounts = <AccountNode>[];

    void collect(List<AccountNode> nodes) {
      for (final node in nodes) {
        if (node.isActive && !node.isDeleted) {
          flatAccounts.add(node);
        }
        if (node.children.isNotEmpty) {
          collect(node.children);
        }
      }
    }

    collect(roots);

    final uniqueById = <String, AccountNode>{};
    for (final account in flatAccounts) {
      uniqueById[account.id] = account.copyWith(children: const []);
    }

    final childrenByParent = <String, List<AccountNode>>{};
    for (final account in uniqueById.values) {
      final parentId = account.parentId;
      if (parentId != null &&
          parentId.isNotEmpty &&
          uniqueById.containsKey(parentId)) {
        childrenByParent.putIfAbsent(parentId, () => []).add(account);
      }
    }

    shared_account.AccountNode buildNode(AccountNode account) {
      final childAccounts = List<AccountNode>.from(
        childrenByParent[account.id] ?? const <AccountNode>[],
      )..sort((a, b) => a.userAccountName.toLowerCase().compareTo(
          b.userAccountName.toLowerCase(),
        ));

      final childNodes = childAccounts.map(buildNode).toList();
      final displayName = account.userAccountName.trim().isNotEmpty
          ? account.userAccountName.trim()
          : account.systemAccountName.trim();

      return shared_account.AccountNode(
        id: account.id,
        name: displayName,
        selectable: childNodes.isEmpty,
        children: childNodes,
      );
    }

    final rootAccounts = uniqueById.values.where((account) {
      final parentId = account.parentId;
      return parentId == null ||
          parentId.isEmpty ||
          !uniqueById.containsKey(parentId);
    }).toList();

    final parentRootAccounts = rootAccounts.where((account) {
      final children = childrenByParent[account.id] ?? const <AccountNode>[];
      return children.isNotEmpty;
    }).toList()
      ..sort((a, b) => a.userAccountName.toLowerCase().compareTo(
          b.userAccountName.toLowerCase(),
        ));

    final standaloneRootAccounts = rootAccounts.where((account) {
      final children = childrenByParent[account.id] ?? const <AccountNode>[];
      return children.isEmpty;
    }).toList()
      ..sort((a, b) => a.userAccountName.toLowerCase().compareTo(
          b.userAccountName.toLowerCase(),
        ));

    return [
      ...parentRootAccounts.map(buildNode),
      ...standaloneRootAccounts.map(buildNode),
    ];
  }

  String? _findDepositAccountLabelById(
    List<shared_account.AccountNode> nodes,
    String? id,
  ) {
    if (id == null || id.isEmpty) return null;
    for (final node in nodes) {
      if (node.id == id) return node.name;
      final childMatch = _findDepositAccountLabelById(node.children, id);
      if (childMatch != null) return childMatch;
    }
    return null;
  }

  bool _isVendorAdvancePaymentType(
    String? rawPaymentType,
    List<dynamic> allocations,
    Map<String, dynamic>? taxRow,
  ) {
    final normalized = (rawPaymentType ?? '')
        .trim()
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    if (normalized == 'VENDOR_ADVANCE' || normalized.contains('ADVANCE')) {
      return true;
    }

    // Vendor advance records typically have no bill allocations but do carry
    // tax/supply metadata used by the advance edit form.
    if (allocations.isEmpty && taxRow != null) {
      return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _selectedVendor = null;
    _paymentDateController.text = DateFormat(
      'dd-MM-yyyy',
    ).format(_paymentDateVal);
    _paymentAmountController.addListener(_onAmountChanged);
    _formScrollController.addListener(() {
      final atTop = _formScrollController.offset < 10;
      if (atTop != _isFormAtTop) {
        setState(() => _isFormAtTop = atTop);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializePage();
    });
  }

  bool get _isEditMode =>
      (widget.paymentId != null && widget.paymentId!.trim().isNotEmpty) ||
      (widget.paymentNumber != null && widget.paymentNumber!.trim().isNotEmpty);

  Future<void> _initializePage() async {
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
    if (orgSettings != null && orgSettings.name.isNotEmpty) {
      setState(() {
        _paymentLocation = orgSettings.name;
        _location = orgSettings.name;
      });
    }
    await Future.wait([
      ref.read(vendorProvider.notifier).loadVendors(),
      ref.read(billsProvider.notifier).loadBills(),
      _loadPaymentModes(),
      _loadPaymentTransactionSeries(),
    ]);
    if (_isEditMode) {
      await _loadExistingPayment();
    }
  }

  Future<void> _loadPaymentModes() async {
    try {
      final entityId = ref.read(entityProvider).entityId;
      if (entityId != null && entityId.isNotEmpty) {
        final supabase = Supabase.instance.client;
        var response = await supabase
            .from('payment_made_payment_mode')
            .select('name, is_default')
            .eq('entity_id', entityId)
            .eq('is_deleted', false)
            .order('name');
        
        if (response.isEmpty) {
          final List<Map<String, dynamic>> seedRows = _defaultPaymentModes.map((mode) => {
            'entity_id': entityId,
            'name': mode,
            'is_default': mode.toLowerCase() == 'cash',
            'is_deleted': false,
          }).toList();
          
          await supabase.from('payment_made_payment_mode').insert(seedRows);
          
          response = await supabase
              .from('payment_made_payment_mode')
              .select('name, is_default')
              .eq('entity_id', entityId)
              .eq('is_deleted', false)
              .order('name');
        }

        if (response.isNotEmpty) {
          final List<String> loadedModes = List<String>.from(
            response.map((e) => e['name'] as String),
          );
          setState(() {
            _paymentModeOptions = loadedModes;
            final hasDefault = response.any((e) => e['is_default'] == true);
            if (hasDefault) {
              final defaultModeRow = response.firstWhere((e) => e['is_default'] == true);
              _paymentMode = defaultModeRow['name'] as String;
            } else if (!_paymentModeOptions.contains(_paymentMode) && _paymentModeOptions.isNotEmpty) {
              _paymentMode = _paymentModeOptions.first;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load payment modes: $e');
    }
  }

  Future<void> _loadPaymentTransactionSeries() async {
    try {
      final entityId = ref.read(entityProvider).entityId;
      if (entityId == null || entityId.isEmpty) return;

      final rows = await Supabase.instance.client
          .from('transaction_series')
          .select('id, name, code')
          .eq('entity_id', entityId)
          .order('created_at');

      if (!mounted) return;

      final options = (rows as List)
          .map((raw) => Map<String, dynamic>.from(raw as Map))
          .map((row) {
            final id = (row['id'] ?? '').toString();
            final name = (row['name'] ?? '').toString().trim();
            final code = (row['code'] ?? '').toString().trim();
            final label = name.isNotEmpty
                ? name
                : code.isNotEmpty
                    ? code
                    : id;
            return TransactionSeriesOption(id: id, name: label);
          })
          .where((option) => option.id.isNotEmpty && option.name.isNotEmpty)
          .toList();

      setState(() {
        _paymentTransactionSeriesOptions = options;
        if ((_paymentTransactionSeriesId == null ||
                _paymentTransactionSeriesId!.isEmpty) &&
            options.isNotEmpty) {
          _paymentTransactionSeriesId = options.first.id;
        }
      });
    } catch (e) {
      debugPrint('Failed to load payment transaction series: $e');
    }
  }

  Future<void> _loadExistingPayment() async {
    if (!mounted) return;
    setState(() {
      _isLoadingExistingPayment = true;
    });

    try {
      final supabase = Supabase.instance.client;
      dynamic masterRow;

      if (widget.paymentId != null && widget.paymentId!.trim().isNotEmpty) {
        masterRow = await supabase
            .from('payment_made_master')
            .select('*')
            .eq('id', widget.paymentId!.trim())
            .maybeSingle();
      } else if (widget.paymentNumber != null &&
          widget.paymentNumber!.trim().isNotEmpty) {
        masterRow = await supabase
            .from('payment_made_master')
            .select('*')
            .eq('payment_number', widget.paymentNumber!.trim())
            .maybeSingle();
      }

      if (masterRow == null) {
        return;
      }

      final paymentDbId = (masterRow['id'] ?? '').toString();
      final allocations = await supabase
          .from('payment_made_bill_allocations')
          .select('*')
          .eq('payment_made_id', paymentDbId);
      final taxRow = await supabase
          .from('payment_made_tax')
          .select('*')
          .eq('payment_made_id', paymentDbId)
          .maybeSingle();
      final attachments = await supabase
          .from('payment_made_attachments')
          .select('*')
          .eq('payment_made_id', paymentDbId);

      _applyExistingPaymentData(
        Map<String, dynamic>.from(masterRow as Map),
        List<dynamic>.from(allocations as List),
        taxRow == null ? null : Map<String, dynamic>.from(taxRow as Map),
        List<dynamic>.from(attachments as List),
      );
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to load payment details: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExistingPayment = false;
        });
      }
    }
  }

  void _applyExistingPaymentData(
    Map<String, dynamic> master,
    List<dynamic> allocations,
    Map<String, dynamic>? taxRow,
    List<dynamic> attachments,
  ) {
    final vendors = ref.read(vendorProvider).vendors;
    final bills = ref.read(billsProvider).bills;
    final vendorId = (master['vendor_id'] ?? '').toString();
    Vendor? matchedVendor;
    for (final vendor in vendors) {
      if (vendor.id == vendorId) {
        matchedVendor = vendor;
        break;
      }
    }
    final matchedVendorBills = matchedVendor == null
        ? const <PurchasesBill>[]
        : bills.where((b) => b.vendorId == matchedVendor!.id).toList();

    final paymentDateRaw = master['payment_date']?.toString();
    final paymentDate = paymentDateRaw != null && paymentDateRaw.isNotEmpty
        ? DateTime.tryParse(paymentDateRaw)
        : null;
    final paymentType = (master['payment_type'] ?? 'RECORD_PAYMENT').toString();
    final amountValue =
        double.tryParse((master['payment_amount'] ?? '0').toString()) ?? 0.0;

    setState(() {
      _editingPaymentDbId = (master['id'] ?? '').toString();
      _selectedVendor = matchedVendor;
      _isBillPayment = !_isVendorAdvancePaymentType(
        paymentType,
        allocations,
        taxRow,
      );
      final loadedTransactionSeriesId = (master['transaction_series_id'] ?? '')
          .toString()
          .trim();
      if (loadedTransactionSeriesId.isNotEmpty) {
        _paymentTransactionSeriesId = loadedTransactionSeriesId;
      }
      _paymentNumberController.text = (master['payment_number'] ?? '')
          .toString();
      _paymentReferenceController.text = (master['reference_number'] ?? '')
          .toString();
      _notesController.text = (master['notes'] ?? '').toString();
      _paymentAmountController.text = amountValue > 0
          ? amountValue.toStringAsFixed(2)
          : '';
      _transferToAccountId = null;
      _erhjController.clear();
      _selectedTax = null;
      _selectedTdsTax = null;
      _sourceOfSupply = '[KL] - Kerala';
      _destinationOfSupply = '[KL] - Kerala';
      _descriptionOfSupplyController.clear();

      final loadedPaymentMode = (master['payment_mode'] ?? '')
          .toString()
          .trim();
      if (loadedPaymentMode.isNotEmpty) {
        _paymentMode = loadedPaymentMode;
        if (!_paymentModeOptions.contains(loadedPaymentMode)) {
          _paymentModeOptions = [..._paymentModeOptions, loadedPaymentMode];
        }
      }

      _pendingPaidThroughAccountId = (master['paid_through_account_id'] ?? '')
          .toString();
      _pendingDepositToAccountId = (master['deposit_to_account_id'] ?? '')
          .toString();

      if (paymentDate != null) {
        _paymentDateVal = paymentDate;
        _paymentDateController.text = DateFormat(
          'dd-MM-yyyy',
        ).format(paymentDate);
      }

      for (final controller in _billPaymentControllers.values) {
        controller.dispose();
      }
      _billPaymentControllers.clear();
      _billPaymentDates.clear();
      for (final raw in allocations) {
        final row = Map<String, dynamic>.from(raw as Map);
        final billId = (row['bill_id'] ?? '').toString();
        if (billId.isEmpty) continue;

        final allocatedAmount =
            double.tryParse(
              (row['allocated_amount'] ?? row['amount'] ?? '0').toString(),
            ) ??
            0.0;
        final rowPaymentDateRaw = row['payment_date']?.toString();
        final rowPaymentDate =
            rowPaymentDateRaw != null && rowPaymentDateRaw.isNotEmpty
            ? DateTime.tryParse(rowPaymentDateRaw)
            : null;

        _getBillController(billId).text = allocatedAmount > 0
            ? allocatedAmount.toStringAsFixed(2)
            : '';
        _billPaymentDates[billId] = DateFormat(
          'dd-MM-yyyy',
        ).format(rowPaymentDate ?? paymentDate ?? _paymentDateVal);
      }

      _payFullAmount =
          allocations.isNotEmpty &&
          matchedVendor != null &&
          matchedVendorBills.isNotEmpty &&
          matchedVendorBills.every((bill) {
            final controller = _billPaymentControllers[bill.id];
            if (controller == null) return false;
            final allocated = double.tryParse(controller.text) ?? 0.0;
            return (allocated - bill.total).abs() < 0.01;
          });

      _reverseCharge = (taxRow?['reverse_charge'] as bool?) ?? false;
      final taxSource = taxRow?['source_of_supply']?.toString().trim();
      if (taxSource != null && taxSource.isNotEmpty) {
        _sourceOfSupply = taxSource;
      }
      final taxDestination = taxRow?['destination_of_supply']
          ?.toString()
          .trim();
      if (taxDestination != null && taxDestination.isNotEmpty) {
        _destinationOfSupply = taxDestination;
      }
      _descriptionOfSupplyController.text =
          (taxRow?['description_of_supply'] ?? '').toString();
      _pendingTdsTaxId = taxRow?['tds_tax_id']?.toString();

      _uploadedFiles = attachments.map((raw) {
        final file = Map<String, dynamic>.from(raw as Map);
        return WebSafePlatformFile(
          name: (file['file_name'] ?? '').toString(),
          size: int.tryParse((file['file_size'] ?? '0').toString()) ?? 0,
          path: file['file_path']?.toString(),
        );
      }).toList();
    });

    _recalculateTotalAllocated();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  void _dismissPaymentAmountReflectionOverlay() {
    _paymentAmountReflectionOverlayEntry?.remove();
    _paymentAmountReflectionOverlayEntry = null;
  }

  void _applyEnteredAmountToBillPayments(List<PurchasesBill> vendorBills) {
    final enteredAmount =
        double.tryParse(_paymentAmountController.text.trim()) ?? 0.0;
    double remainingAmount = enteredAmount;

    for (final bill in vendorBills) {
      final controller = _getBillController(bill.id);
      if (remainingAmount <= 0) {
        controller.text = '';
        continue;
      }

      final allocatedAmount =
          remainingAmount >= bill.total ? bill.total : remainingAmount;
      controller.text = allocatedAmount.toStringAsFixed(2);
      remainingAmount -= allocatedAmount;
    }

    _recalculateTotalAllocated();
  }

  void _showPaymentAmountReflectionPrompt(List<PurchasesBill> vendorBills) {
    _dismissPaymentAmountReflectionOverlay();

    final enteredAmount =
        double.tryParse(_paymentAmountController.text.trim()) ?? 0.0;
    if (!_isBillPayment || enteredAmount <= 0 || vendorBills.isEmpty || !mounted) {
      return;
    }

    _paymentAmountReflectionOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _dismissPaymentAmountReflectionOverlay,
              ),
            ),
            CompositedTransformFollower(
              link: _billPaymentAmountLink,
              showWhenUnlinked: false,
              offset: const Offset(-8, 44),
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -6,
                      left: 36,
                      child: Transform.rotate(
                        angle: 0.785398,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 206,
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Would you like this amount to be\nreflected in the Payment field?',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _applyEnteredAmountToBillPayments(vendorBills);
                                  _dismissPaymentAmountReflectionOverlay();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Yes',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _dismissPaymentAmountReflectionOverlay,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'No',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
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
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_paymentAmountReflectionOverlayEntry!);
  }

  String _paymentTransactionSeriesLabel() {
    final selectedId = _paymentTransactionSeriesId;
    if (selectedId == null || selectedId.isEmpty) {
      return 'No transaction series selected';
    }

    for (final option in _paymentTransactionSeriesOptions) {
      if (option.id == selectedId) {
        return option.name;
      }
    }

    return selectedId;
  }

  Future<void> _handleAddTransactionSeries() async {
    if (!mounted) return;
    ZerpaiToast.info(
      context,
      'Create the required transaction series in Settings, then reopen this page.',
    );
  }

  Future<void> _showPreferencesDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return ConfigurePaymentNumberPreferencesDialog(
          currentLocation: _paymentLocation,
          currentSeries: _paymentTransactionSeriesLabel(),
          initialPreferences: _paymentPreferences,
        );
      },
    );

    if (result == null) return;

    final autoGenerate = result['autoGenerate'] as bool? ?? true;
    final prefix = autoGenerate 
        ? (result['autoPrefix'] as String? ?? '').trim()
        : (result['manualPrefix'] as String? ?? '').trim();
    final nextNumber = (result['nextNumber'] as String? ?? '').trim();

    setState(() {
      _paymentPreferences = PaymentNumberPreferences(
        autoGenerate: autoGenerate,
        autoPrefix: result['autoPrefix'] as String? ?? 'PAY-',
        nextNumber: result['nextNumber'] as String? ?? '98',
        manualPrefix: result['manualPrefix'] as String? ?? '',
        manualPaymentNumber: result['nextNumber'] as String? ?? '',
        restartFiscalYear: result['restartFiscalYear'] as bool? ?? false,
      );
      _paymentNumberController.text = '$prefix$nextNumber';
    });
  }

  Future<void> _showConfigurePaymentModeDialog() async {
    final entityId = ref.read(entityProvider).entityId ?? '';
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ConfigurePaymentModeDialog(
        entityId: entityId,
        initialModes: _paymentModeOptions,
        onSave: (result) {
          if (result.isEmpty) return;
          setState(() {
            _paymentModeOptions = result;
            if (!_paymentModeOptions.contains(_paymentMode)) {
              _paymentMode = _paymentModeOptions.first;
            }
          });
        },
      ),
    );
  }

  Future<PaidThroughItem?> _showExcessPaymentDialog(double excessAmount) async {
    final accountsState = ref.read(chartOfAccountsProvider);
    final depositOptions = _buildPaidThroughOptions(accountsState.roots)
        .where((item) => !item.isHeader)
        .toList();
    final depositAccountTree = _buildDepositAccountTree(accountsState.roots);

    PaidThroughItem? selectedDepositTo = _depositTo;
    if (selectedDepositTo == null && depositOptions.isNotEmpty) {
      for (final option in depositOptions) {
        if (option.label == 'Prepaid Expenses') {
          selectedDepositTo = option;
          break;
        }
      }
      selectedDepositTo ??= depositOptions.first;
    }

    return showDialog<PaidThroughItem?>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool showDepositDropdown = false;
        PaidThroughItem? localSelectedDepositTo = selectedDepositTo;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screenSize = MediaQuery.of(context).size;
            final dialogWidth = screenSize.width < 500 ? screenSize.width : 500.0;
            final baseHeight = showDepositDropdown ? 312.0 : 253.22;
            final dialogHeight = screenSize.height < baseHeight
                ? screenSize.height
                : baseHeight;

            return Dialog(
              alignment: Alignment.topCenter,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              insetPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: dialogWidth,
                height: dialogHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Excess Payment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: const Icon(
                              LucideIcons.x,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B),
                                      width: 2,
                                    ),
                                    color: Colors.white,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '!',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFFF59E0B),
                                      height: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "You're about to record an excess payment of ₹${_formatAmount(excessAmount)}. This will be stored as credits for the vendor. Do you want to continue?",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.55,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (!showDepositDropdown)
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  const Text(
                                    'Note: The excess amount will be deposited in the',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                      height: 1.5,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        showDepositDropdown = true;
                                      });
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          localSelectedDepositTo?.label ??
                                              'Prepaid Expenses',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryBlue,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          LucideIcons.pencil,
                                          size: 13,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Note: The excess amount will be deposited in the',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: 218,
                                    child: AccountTreeDropdown(
                                      value: localSelectedDepositTo?.id,
                                      nodes: depositAccountTree,
                                      hint:
                                          _findDepositAccountLabelById(
                                            depositAccountTree,
                                            localSelectedDepositTo?.id,
                                          ) ??
                                          'Select Account',
                                      onChanged: (value) {
                                        if (value == null || value.isEmpty) {
                                          return;
                                        }
                                        final matchedOption =
                                            _findPaidThroughItemById(
                                              depositOptions,
                                              value,
                                            );
                                        setDialogState(() {
                                          localSelectedDepositTo =
                                              matchedOption ??
                                              PaidThroughItem(
                                                _findDepositAccountLabelById(
                                                      depositAccountTree,
                                                      value,
                                                    ) ??
                                                    value,
                                                id: value,
                                              );
                                        });
                                      },
                                      height: 38,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                SizedBox(
                                  height: 36,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(
                                      dialogContext,
                                    ).pop(localSelectedDepositTo),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF22C55E),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: const Text(
                                      'Continue to Save',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 36,
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF111827),
                                      backgroundColor: const Color(0xFFF9FAFB),
                                      side: const BorderSide(
                                        color: Color(0xFFD1D5DB),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
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
                          ],
                        ),
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

  @override
  void dispose() {
    _dismissPaymentAmountReflectionOverlay();
    _uploadDropdownOverlayEntry?.remove();
    _uploadDropdownOverlayEntry = null;
    _paymentAmountController.removeListener(_onAmountChanged);
    _paymentNumberController.dispose();
    _paymentAmountController.dispose();
    _paymentReferenceController.dispose();
    _paymentDateController.dispose();
    _notesController.dispose();
    _descriptionOfSupplyController.dispose();
    _formScrollController.dispose();
    for (final c in _billPaymentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _formScrollController,
                        child: _buildForm(context),
                      ),
                    ),
                    _buildBottomActionsBar(context),
                  ],
                ),
              ),
            ],
          ),
          if (_showVendorDetailsPanel && _selectedVendor != null)
            VendorSidebar(
              vendor: _selectedVendor!,
              onClose: () => setState(() => _showVendorDetailsPanel = false),
            ),
          if (!_showVendorDetailsPanel &&
              _selectedVendor != null &&
              !_isEditMode)
            Positioned(
              top: 68,
              right: 0,
              child: AnimatedOpacity(
                opacity: _isFormAtTop ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_isFormAtTop,
                  child: VendorSideTag(
                    vendorName: _selectedVendor!.displayName,
                    onTap: () => setState(() => _showVendorDetailsPanel = true),
                  ),
                ),
              ),
            ),
          if (_isSaving || _isLoadingExistingPayment)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white54,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    if (_isEditMode) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text(
                  'Edit Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 22, color: AppTheme.textSecondary),
              onPressed: () {
                final state = GoRouterState.of(context);
                context.goNamed(
                  AppRoutes.paymentsMade,
                  pathParameters: state.pathParameters,
                );
              },
            ),
          ],
        ),
      );
    }

    return Container(
      height: 48,
      color: const Color(0xFFF9FAFB),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(height: 1, color: AppTheme.borderColor),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: 56),
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildTabButton('Bill Payment', _isBillPayment),
                      const SizedBox(width: 8),
                      _buildTabButton('Vendor Advance', !_isBillPayment),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 56, bottom: 4),
                child: IconButton(
                  onPressed: () {
                    final state = GoRouterState.of(context);
                    context.goNamed(
                      AppRoutes.paymentsMade,
                      pathParameters: state.pathParameters,
                    );
                  },
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isActive) {
    final Widget tabWidget = isActive
        ? Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.primaryBlue, width: 3),
                left: BorderSide(color: AppTheme.borderColor),
                right: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                
              ),
            ),
          )
        : Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBlue,
                
              ),
            ),
          );

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          setState(() {
            _isBillPayment = label == 'Bill Payment';
          });
        }
      },
      child: tabWidget,
    );
  }

  Widget _buildForm(BuildContext context) {
    final vendorState = ref.watch(vendorProvider);
    final billsState = ref.watch(billsProvider);
    final vendorBills = _selectedVendor == null
        ? <PurchasesBill>[]
        : billsState.bills
              .where((b) => b.vendorId == _selectedVendor!.id)
              .toList();
    final accountsState = ref.watch(chartOfAccountsProvider);
    final paidThroughOptions = _buildPaidThroughOptions(accountsState.roots);

    final statesAsync = ref.watch(statesProvider('IN'));
    final List<Map<String, String>> dbStates = statesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const [],
    );
    final List<String> statesList = dbStates
        .map((state) {
          final code = (state['code'] ?? '').trim();
          final name = (state['name'] ?? '').trim();
          if (code.isEmpty) return name;
          if (name.isEmpty) return '[$code]';
          return '[$code] - $name';
        })
        .where((val) => val.trim().isNotEmpty)
        .toList();

    final List<String> supplyOptions = statesList.isNotEmpty ? statesList : _statesOptions;

    if (statesList.isNotEmpty) {
      if (!statesList.contains(_sourceOfSupply)) {
        final match = statesList.firstWhere(
          (s) => s.toLowerCase().contains('kerala') || s.toLowerCase().contains('[kl]'),
          orElse: () => statesList.first,
        );
        _sourceOfSupply = match;
      }
      if (!statesList.contains(_destinationOfSupply)) {
        final match = statesList.firstWhere(
          (s) => s.toLowerCase().contains('kerala') || s.toLowerCase().contains('[kl]'),
          orElse: () => statesList.first,
        );
        _destinationOfSupply = match;
      }
    }

    final tdsRatesAsync = ref.watch(paymentsMadeTdsRatesProvider);
    final taxesAsync = ref.watch(paymentsMadeTaxesProvider);
    final List<String> tdsOptions = tdsRatesAsync.maybeWhen(
      data: (list) => list.map((e) => e.name).toList(),
      orElse: () => const [],
    );
    final List<TaxItem> taxOptions = taxesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const [],
    );

    if (_pendingTdsTaxId != null && tdsRatesAsync.hasValue) {
      PaymentsMadeTdsRateItem? matchedTds;
      for (final item
          in tdsRatesAsync.value ?? const <PaymentsMadeTdsRateItem>[]) {
        if (item.id == _pendingTdsTaxId) {
          matchedTds = item;
          break;
        }
      }
      if (matchedTds != null) {
        _selectedTdsTax = matchedTds.name;
        _pendingTdsTaxId = null;
      }
    }

    if (_paymentPaidFrom == null && paidThroughOptions.isNotEmpty) {
      if (_pendingPaidThroughAccountId != null &&
          _pendingPaidThroughAccountId!.isNotEmpty) {
        for (final option in paidThroughOptions) {
          if (!option.isHeader &&
              (option.id == _pendingPaidThroughAccountId ||
                  option.label == _pendingPaidThroughAccountId)) {
            _paymentPaidFrom = option;
            break;
          }
        }
      }
      _paymentPaidFrom ??= paidThroughOptions.firstWhere(
        (e) => e.label == 'Petty Cash' && !e.isHeader,
        orElse: () => paidThroughOptions.firstWhere(
          (e) => !e.isHeader,
          orElse: () => paidThroughOptions.first,
        ),
      );
      _pendingPaidThroughAccountId = null;
    }

    if (_depositTo == null && paidThroughOptions.isNotEmpty) {
      if (_pendingDepositToAccountId != null &&
          _pendingDepositToAccountId!.isNotEmpty) {
        for (final option in paidThroughOptions) {
          if (!option.isHeader &&
              (option.id == _pendingDepositToAccountId ||
                  option.label == _pendingDepositToAccountId)) {
            _depositTo = option;
            break;
          }
        }
      }
      _depositTo ??= paidThroughOptions.firstWhere(
        (e) => e.label == 'Vendor Advance Clearing' && !e.isHeader,
        orElse: () => paidThroughOptions.firstWhere(
          (e) => e.label == 'Prepaid Expenses' && !e.isHeader,
          orElse: () => paidThroughOptions.firstWhere(
            (e) => !e.isHeader,
            orElse: () => paidThroughOptions.first,
          ),
        ),
      );
      _pendingDepositToAccountId = null;
    }

    _location ??= _paymentLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isEditMode && !_isBillPayment) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFFFFF7ED),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.alertTriangle,
                  color: Color(0xFFF59E0B),
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'This transaction is categorized in Bandhan Bank. Hence, some fields cannot be modified.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Uncategorize now >',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Container(
          color: const Color(0xFFF9FAFB),
          padding: const EdgeInsets.fromLTRB(56, 16, 40, 16),
          child: _buildVendorHeaderSection(vendorState, supplyOptions),
        ),
        if (_isBillPayment)
          const Divider(height: 1, color: AppTheme.borderColor),
        Opacity(
          opacity: _selectedVendor == null ? 0.35 : 1.0,
          child: IgnorePointer(
            ignoring: _selectedVendor == null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 24, 220, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _isBillPayment
                    ? _buildBillPaymentFields(
                        context,
                        paidThroughOptions,
                        taxOptions,
                        tdsOptions,
                        vendorBills,
                        _isEditMode,
                      )
                    : _buildVendorAdvanceFields(
                        context,
                        paidThroughOptions,
                        taxOptions,
                        tdsOptions,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVendorHeaderSection(VendorState vendorState, List<String> supplyOptions) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(right: _isEditMode && !_isBillPayment ? 260 : 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormRow(
                label: 'Vendor Name',
                required: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FormDropdown<Vendor>(
                      value: _selectedVendor,
                      items: vendorState.vendors,
                      enabled: !_isEditMode,
                      onChanged: (val) {
                        setState(() {
                          _selectedVendor = val;
                          _billPaymentControllers.clear();
                          _billPaymentDates.clear();
                          _billDateKeys.clear();
                          if (val != null) {
                            if (val.sourceOfSupply == 'Karnataka') {
                              _sourceOfSupply = '[KA] - Karnataka';
                              _destinationOfSupply = '[KA] - Karnataka';
                            } else {
                              _sourceOfSupply = '[KL] - Kerala';
                              _destinationOfSupply = '[KL] - Kerala';
                            }
                          }
                        });
                      },
                      displayStringForValue: (v) => v.displayName,
                      searchStringForValue: (v) =>
                          '${v.displayName} ${v.vendorNumber ?? ''} ${v.email ?? ''}',
                      hint: 'Select Vendor',
                      height: 36,
                      showSearch: true,
                      itemBuilder: (vendor, isSelected, isHovered) {
                        final Color textColor = isHovered
                            ? Colors.white
                            : (isSelected
                                  ? const Color(0xFF111827)
                                  : AppTheme.textPrimary);
                        final Color subTextColor = isHovered
                            ? Colors.white70
                            : AppTheme.textSecondary;
                        final Color avatarBgColor = isHovered
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFFE5E7EB);
                        final Color avatarTextColor = isHovered
                            ? Colors.white
                            : AppTheme.textSecondary;
                        final initials = vendor.displayName.isNotEmpty
                            ? vendor.displayName[0].toUpperCase()
                            : '';
                        final List<Widget> subtextItems = [];
                        if (vendor.email != null && vendor.email!.isNotEmpty) {
                          subtextItems.add(
                            Icon(
                              Icons.mail_outline,
                              size: 13,
                              color: subTextColor,
                            ),
                          );
                          subtextItems.add(const SizedBox(width: 4));
                          subtextItems.add(
                            Text(
                              vendor.email!,
                              style: TextStyle(
                                fontSize: 11,
                                color: subTextColor,
                              ),
                            ),
                          );
                        }
                        if (vendor.email != null &&
                            vendor.email!.isNotEmpty &&
                            vendor.companyName != null &&
                            vendor.companyName!.isNotEmpty) {
                          subtextItems.add(const SizedBox(width: 8));
                          subtextItems.add(
                            Text(
                              '|',
                              style: TextStyle(
                                fontSize: 11,
                                color: subTextColor,
                              ),
                            ),
                          );
                          subtextItems.add(const SizedBox(width: 8));
                        }
                        if (vendor.companyName != null &&
                            vendor.companyName!.isNotEmpty) {
                          subtextItems.add(
                            Icon(
                              Icons.description_outlined,
                              size: 13,
                              color: subTextColor,
                            ),
                          );
                          subtextItems.add(const SizedBox(width: 4));
                          subtextItems.add(
                            Flexible(
                              child: Text(
                                vendor.companyName!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subTextColor,
                                ),
                              ),
                            ),
                          );
                        }
                        return Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: avatarBgColor,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: avatarTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            vendor.displayName,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        if (vendor.vendorNumber != null &&
                                            vendor.vendorNumber!.isNotEmpty) ...[
                                          Text(
                                            ' | ',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: textColor.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            vendor.vendorNumber!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: subTextColor,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(children: subtextItems),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: isHovered
                                      ? Colors.white
                                      : const Color(0xFF1D4ED8),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (!_isBillPayment && _selectedVendor != null) ...[
                      const SizedBox(height: 8),
                      IgnorePointer(
                        ignoring: _isEditMode,
                        child: TaxPreferencesPopover(
                          initialGstTreatment:
                              _selectedVendor!.gstTreatment ??
                              'Unregistered Business',
                          onUpdate: (val) {
                            setState(() {
                              try {
                                _selectedVendor =
                                    _selectedVendor!.copyWith(gstTreatment: val);
                              } catch (_) {}
                            });
                          },
                          child: Row(
                            children: [
                              const Text(
                                'GST Treatment: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                _selectedVendor!.gstTreatment ??
                                    'Unregistered Business',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (!_isEditMode) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  LucideIcons.edit3,
                                  size: 13,
                                  color: AppTheme.primaryBlue,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!_isBillPayment) ...[
                const SizedBox(height: 16),
                Opacity(
                  opacity: _selectedVendor == null ? 0.35 : 1.0,
                  child: IgnorePointer(
                    ignoring: _selectedVendor == null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFormRow(
                          label: 'Source of Supply',
                          required: true,
                          child: FormDropdown<String>(
                            value: _sourceOfSupply,
                            items: supplyOptions,
                            enabled: !_isEditMode,
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => _sourceOfSupply = val);
                            },
                            height: 36,
                            showSearch: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormRow(
                          label: 'Destination of Supply',
                          required: true,
                          child: FormDropdown<String>(
                            value: _destinationOfSupply,
                            items: supplyOptions,
                            enabled: !_isEditMode,
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => _destinationOfSupply = val);
                            },
                            height: 36,
                            showSearch: true,
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

      ],
    );
  }

  List<Widget> _buildBillPaymentFields(
    BuildContext context,
    List<PaidThroughItem> paidThroughOptions,
    List<TaxItem> taxOptions,
    List<String> tdsOptions,
    List<PurchasesBill> vendorBills,
    bool isEditMode,
  ) {
    return [
      // Row 3 â€” Payment #
      _buildFormRow(
        label: 'Payment #',
        required: true,
        child: Row(
          children: [
            SizedBox(
              width: 220,
              child: TransactionSeriesDropdown(
                series: _paymentTransactionSeriesOptions,
                selectedIds: _paymentTransactionSeriesId == null
                    ? const []
                    : [_paymentTransactionSeriesId!],
                multiSelect: false,
                includeDefaultOption: false,
                placeholder: 'Select payment series',
                accentColor: AppTheme.primaryBlue,
                showAddOption: false,
                onChanged: (ids) {
                  setState(() {
                    _paymentTransactionSeriesId =
                        ids.isNotEmpty ? ids.first : null;
                  });
                },
                onAddTap: _handleAddTransactionSeries,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 148,
              child: CustomTextField(
                controller: _paymentNumberController,
                height: 36,
                suffixSeparator: false,
                suffixWidget: ZTooltip(
                  message:
                      'Click here to configure auto-generation of payment numbers.',
                  direction: ZTooltipDirection.bottom,
                  child: InkWell(
                    onTap: _showPreferencesDialog,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
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
      const SizedBox(height: 16),

      // Row 4 â€” Payment Made
      _buildFormRow(
        label: 'Payment Made',
        required: true,
        child: Row(
          children: [
            Expanded(
              child: CompositedTransformTarget(
                link: _billPaymentAmountLink,
                child: Row(
                  children: [
                    Container(
                      height: 36,
                      width: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'INR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                          
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomTextField(
                        controller: _paymentAmountController,
                        height: 36,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onSubmitted: (_) =>
                            _showPaymentAmountReflectionPrompt(vendorBills),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                        showLeftBorder: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),

      _buildFormRow(
        label: '',
        child: Row(
          children: [
            Checkbox(
              value: _payFullAmount,
              onChanged: (val) {
                setState(() {
                  _payFullAmount = val ?? false;
                  if (_payFullAmount) {
                    final totalDue = vendorBills.fold(
                      0.0,
                      (sum, bill) => sum + bill.total,
                    );
                    for (final bill in vendorBills) {
                      _getBillController(bill.id).text = bill.total
                          .toStringAsFixed(2);
                    }
                    _paymentAmountController.text = totalDue.toStringAsFixed(2);
                    _recalculateTotalAllocated();
                  } else {
                    for (final bill in vendorBills) {
                      _getBillController(bill.id).text = '';
                    }
                    _paymentAmountController.text = '';
                  }
                });
              },
              activeColor: AppTheme.primaryBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                setState(() {
                  _payFullAmount = !_payFullAmount;
                  if (_payFullAmount) {
                    final totalDue = vendorBills.fold(
                      0.0,
                      (sum, bill) => sum + bill.total,
                    );
                    for (final bill in vendorBills) {
                      _getBillController(bill.id).text = bill.total
                          .toStringAsFixed(2);
                    }
                    _paymentAmountController.text = totalDue.toStringAsFixed(2);
                    _recalculateTotalAllocated();
                  } else {
                    for (final bill in vendorBills) {
                      _getBillController(bill.id).text = '';
                    }
                    _paymentAmountController.text = '';
                  }
                });
              },
              child: Builder(
                builder: (ctx) {
                  final totalDue = vendorBills.fold(
                    0.0,
                    (sum, b) => sum + b.total,
                  );
                  final fmt = NumberFormat('#,##,##0.00', 'en_IN');
                  final amtStr = totalDue > 0
                      ? ' (\u20B9${fmt.format(totalDue)})'
                      : '';
                  return Text(
                    'Pay full amount$amtStr',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),

      // Row 5 — Integrations Banner

      // Row 6 â€” Payment Date
      _buildFormRow(
        label: 'Payment Date',
        required: true,
        child: Container(
          key: _paymentDateKey,
          child: CustomTextField(
            controller: _paymentDateController,
            readOnly: true,
            height: 36,
            suffixWidget: const Icon(
              LucideIcons.calendar,
              size: 15,
              color: AppTheme.textSecondary,
            ),
            onTap: () async {
              final picked = await ZerpaiDatePicker.show(
                context,
                initialDate: _paymentDateVal,
                targetKey: _paymentDateKey,
              );
              if (picked == null) return;
              setState(() {
                _paymentDateVal = picked;
                _paymentDateController.text = DateFormat(
                  'dd-MM-yyyy',
                ).format(picked);
              });
            },
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Row 7 â€” Payment Mode
      _buildFormRow(
        label: 'Payment Mode',
        required: false,
        child: FormDropdown<String>(
          value: _paymentMode,
          items: _paymentModeOptions,
          onChanged: (val) {
            if (val == null) return;
            setState(() => _paymentMode = val);
          },
          height: 36,
          showSearch: true,

          showSettings: true,
          settingsLabel: 'Configure Payment Mode',
          settingsIcon: Icons.add_circle_outline,
          onSettingsTap: _showConfigurePaymentModeDialog,
          itemBuilder: (item, isSelected, isHovered) {
            final Color textColor = isHovered
                ? Colors.white
                : (isSelected ? const Color(0xFF111827) : AppTheme.textPrimary);

            return Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.transparent,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.normal,
                        
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: isHovered ? Colors.white : const Color(0xFF1D4ED8),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),

      // Row 8 â€” Paid Through
      _buildFormRow(
        label: 'Paid Through',
        required: true,
        child: FormDropdown<PaidThroughItem>(
          value: _paymentPaidFrom,
          items: paidThroughOptions,
          onChanged: (val) {
            if (val == null) return;
            setState(() => _paymentPaidFrom = val);
          },
          displayStringForValue: (v) => v.label,
          searchStringForValue: (v) => v.label,
          height: 36,
          showSearch: true,

          isItemEnabled: (item) => !item.isHeader,
          itemBuilder: (item, isSelected, isHovered) {
            if (item.isHeader) {
              return Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.transparent,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    
                  ),
                ),
              );
            }

            // Child item (indented)
            final Color textColor = isHovered
                ? Colors.white
                : (isSelected
                      ? const Color(0xFF111827)
                      : (item.isBullet
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary));
            final String displayLabel = item.isBullet
                ? '\u2022 ${item.label}'
                : item.label;

            return Container(
              height: 36,
              padding: const EdgeInsets.only(left: 24, right: 12),
              color: Colors.transparent,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.normal,
                        
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: isHovered ? Colors.white : const Color(0xFF1D4ED8),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),

      // Row 9 â€” Reference#
      _buildFormRow(
        label: 'Reference#',
        required: false,
        child: CustomTextField(
          controller: _paymentReferenceController,
          height: 36,
        ),
      ),
      const SizedBox(height: 12),

      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 24),
          child: GestureDetector(
            onTap: () {
              setState(() {
                for (final controller in _billPaymentControllers.values) {
                  controller.text = '';
                }
              });
              _recalculateTotalAllocated();
            },
            child: const Text(
              'Clear Applied Amount',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
      _buildBillsTable(),
      const SizedBox(height: 16),
      _buildTotalRow(),
      const SizedBox(height: 16),
      const Divider(height: 1, color: AppTheme.borderColor),
      const SizedBox(height: 24),
      Align(alignment: Alignment.centerRight, child: _buildPeachSummaryCard()),
      const SizedBox(height: 24),
      _buildNotesSection(isEditMode: _isEditMode),
      const SizedBox(height: 24),
      _buildAttachmentsSection(),
    ];
  }

  List<Widget> _buildVendorAdvanceFields(
    BuildContext context,
    List<PaidThroughItem> paidThroughOptions,
    List<TaxItem> taxOptions,
    List<String> tdsOptions,
  ) {
    return [
      // Row 5 â€” Payment #
      _buildFormRow(
        label: 'Payment #',
        required: true,
        child: Row(
          children: [
            SizedBox(
              width: 220,
              child: TransactionSeriesDropdown(
                series: _paymentTransactionSeriesOptions,
                selectedIds: _paymentTransactionSeriesId == null
                    ? const []
                    : [_paymentTransactionSeriesId!],
                multiSelect: false,
                includeDefaultOption: false,
                placeholder: 'Select payment series',
                accentColor: AppTheme.primaryBlue,
                showAddOption: false,
                onChanged: (ids) {
                  setState(() {
                    _paymentTransactionSeriesId =
                        ids.isNotEmpty ? ids.first : null;
                  });
                },
                onAddTap: _handleAddTransactionSeries,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 148,
              child: CustomTextField(
                controller: _paymentNumberController,
                height: 36,
                suffixSeparator: false,
                suffixWidget: ZTooltip(
                  message:
                      'Click here to configure auto-generation of payment numbers.',
                  direction: ZTooltipDirection.bottom,
                  child: InkWell(
                    onTap: _showPreferencesDialog,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
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
      const SizedBox(height: 16),

      // Row 6 â€” Description of Supply
      _buildFormRow(
        label: 'Description of Supply',
        required: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _descriptionOfSupplyController,
              maxLines: 3,
              height: 72,
            ),
            const SizedBox(height: 4),
            const Text(
              'Will be displayed on the Payment Voucher',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Row 7 â€” Payment Made
      _buildFormRow(
        label: 'Payment Made',
        required: true,
        child: Row(
          children: [
            Container(
              height: 36,
              width: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'INR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  
                ),
              ),
            ),
            Expanded(
              child: CustomTextField(
                controller: _paymentAmountController,
                height: 36,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                showLeftBorder: false,
              ),
            ),
          ],
        ),
      ),
      if (_isEditMode) ...[
        const SizedBox(height: 4),
        _buildFormRow(
          label: '',
          child: const Text(
            'Unused Amount: ₹10,000.00*',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFDC2626),
            ),
          ),
        ),
      ],
      const SizedBox(height: 8),

      // Row 8 â€” Integrations Banner

      // Row 9 â€” Reverse Charge Checkbox
      _buildFormRow(
        label: 'Reverse Charge',
        required: false,
        child: Row(
          children: [
            Checkbox(
              value: _reverseCharge,
              onChanged: (val) {
                setState(() {
                  _reverseCharge = val ?? false;
                });
              },
              activeColor: AppTheme.primaryBlue,
            ),
            const Text(
              'This transaction is applicable for reverse charge',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      if (_reverseCharge) ...[
        // Row 9b â€” Tax Dropdown
        _buildFormRow(
          label: 'Tax',
          required: false,
          child: FormDropdown<TaxItem>(
            value: _selectedTax,
            items: taxOptions,
            onChanged: (val) {
              setState(() => _selectedTax = val);
            },
            displayStringForValue: (v) => v.label,
            searchStringForValue: (v) => v.label,
            hint: 'Select a Tax',
            height: 36,
            showSearch: true,

            isItemEnabled: (item) => !item.isHeader,
            itemBuilder: (item, isSelected, isHovered) {
              if (item.isHeader) {
                return Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.transparent,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      
                    ),
                  ),
                );
              }

              final Color textColor = isHovered
                  ? Colors.white
                  : (isSelected
                        ? const Color(0xFF111827)
                        : AppTheme.textPrimary);

              return Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.transparent,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                          
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: isHovered
                            ? Colors.white
                            : const Color(0xFF1D4ED8),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],

      _buildFormRow(
        label: 'Transfer To',
        required: false,
        child: FormDropdown<PaidThroughItem>(
          value: paidThroughOptions.isNotEmpty ? paidThroughOptions.firstWhere((e) => e.id == _transferToAccountId, orElse: () => paidThroughOptions.first) : null,
          items: paidThroughOptions,
          onChanged: (val) {
            if (val != null) {
              setState(() => _transferToAccountId = val.id);
            }
          },
          displayStringForValue: (v) => v.label,
          searchStringForValue: (v) => v.label,
          hint: 'Select a bank account',
          height: 36,
          showSearch: true,
        ),
      ),
      const SizedBox(height: 16),

      // Row 15 — Reference#
      _buildFormRow(
        label: 'Reference#',
        required: false,
        child: CustomTextField(
          controller: _paymentReferenceController,
          height: 36,
        ),
      ),
      const SizedBox(height: 24),

      // Row 10 — TDS Dropdown
      _buildFormRow(
        label: 'TDS',
        required: false,
        child: FormDropdown<String>(
          value: _selectedTdsTax,
          items: tdsOptions,
          onChanged: (val) {
            setState(() => _selectedTdsTax = val);
          },
          hint: 'Select a Tax',
          height: 36,
          showSearch: false,
        ),
      ),
      const SizedBox(height: 16),

      // Row 11 â€” Payment Date
      _buildFormRow(
        label: 'Payment Date',
        required: true,
        child: Container(
          key: _paymentDateKey,
          child: CustomTextField(
            controller: _paymentDateController,
            readOnly: true,
            height: 36,
            suffixWidget: const Icon(
              LucideIcons.calendar,
              size: 15,
              color: AppTheme.textSecondary,
            ),
            onTap: () async {
              final picked = await ZerpaiDatePicker.show(
                context,
                initialDate: _paymentDateVal,
                targetKey: _paymentDateKey,
              );
              if (picked == null) return;
              setState(() {
                _paymentDateVal = picked;
                _paymentDateController.text = DateFormat(
                  'dd-MM-yyyy',
                ).format(picked);
              });
            },
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Row 12 â€” Payment Mode
      _buildFormRow(
        label: 'Payment Mode',
        required: false,
        child: FormDropdown<String>(
          value: _paymentMode,
          items: _paymentModeOptions,
          onChanged: (val) {
            if (val == null) return;
            setState(() => _paymentMode = val);
          },
          height: 36,
          showSearch: true,

          showSettings: true,
          settingsLabel: 'Configure Payment Mode',
          settingsIcon: Icons.add_circle_outline,
          onSettingsTap: _showConfigurePaymentModeDialog,
          itemBuilder: (item, isSelected, isHovered) {
            final Color textColor = isHovered
                ? Colors.white
                : (isSelected ? const Color(0xFF111827) : AppTheme.textPrimary);

            return Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.transparent,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.normal,
                        
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: isHovered ? Colors.white : const Color(0xFF1D4ED8),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),

      // Row 13 â€” Paid Through
      _buildFormRow(
        label: 'Paid Through',
        required: true,
        child: FormDropdown<PaidThroughItem>(
          value: _paymentPaidFrom,
          items: paidThroughOptions,
          onChanged: (val) {
            if (val == null) return;
            setState(() => _paymentPaidFrom = val);
          },
          displayStringForValue: (v) => v.label,
          searchStringForValue: (v) => v.label,
          height: 36,
          showSearch: true,

          isItemEnabled: (item) => !item.isHeader,
          itemBuilder: (item, isSelected, isHovered) {
            if (item.isHeader) {
              return Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.transparent,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    
                  ),
                ),
              );
            }

            // Child item (indented)
            final Color textColor = isHovered
                ? Colors.white
                : (isSelected
                      ? const Color(0xFF111827)
                      : (item.isBullet
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary));
            final String displayLabel = item.isBullet
                ? '\u2022 ${item.label}'
                : item.label;

            return Container(
              height: 36,
              padding: const EdgeInsets.only(left: 24, right: 12),
              color: Colors.transparent,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.normal,
                        
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: isHovered ? Colors.white : const Color(0xFF1D4ED8),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),

      // Row 14 â€” Deposit To
      _buildFormRow(
        label: 'Deposit To',
        required: false,
        child: FormDropdown<PaidThroughItem>(
          value: _depositTo,
          items: paidThroughOptions,
          onChanged: (val) {
            if (val == null) return;
            setState(() => _depositTo = val);
          },
          displayStringForValue: (v) => v.label,
          searchStringForValue: (v) => v.label,
          height: 36,
          showSearch: true,

          isItemEnabled: (item) => !item.isHeader,
          itemBuilder: (item, isSelected, isHovered) {
            if (item.isHeader) {
              return Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.transparent,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    
                  ),
                ),
              );
            }

            // Child item (indented)
            final Color textColor = isHovered
                ? Colors.white
                : (isSelected
                      ? const Color(0xFF111827)
                      : (item.isBullet
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary));
            final String displayLabel = item.isBullet
                ? '\u2022 ${item.label}'
                : item.label;

            return Container(
              height: 36,
              padding: const EdgeInsets.only(left: 24, right: 12),
              color: Colors.transparent,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.normal,
                        
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: isHovered ? Colors.white : const Color(0xFF1D4ED8),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),

      // Row 15 â€” Reference#
      _buildFormRow(
        label: 'Reference#',
        required: false,
        child: CustomTextField(
          controller: _paymentReferenceController,
          height: 36,
        ),
      ),
      const SizedBox(height: 24),

      _buildNotesSection(),
      const SizedBox(height: 24),
      _buildAttachmentsSection(),
    ];
  }

  Widget _buildFormRow({
    required String label,
    required Widget child,
    bool required = false,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double maxWidth = 400.0,
  }) {
    final labelColor = required
        ? const Color(0xFFD32F2F)
        : AppTheme.textPrimary;
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        SizedBox(
          width: 140,
          child: Padding(
            padding: EdgeInsets.only(
              top: crossAxisAlignment == CrossAxisAlignment.start ? 8 : 0,
            ),
            child: RichText(
              text: TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                  
                  decoration: label == 'Description of Supply'
                      ? TextDecoration.underline
                      : null,
                  decorationStyle: label == 'Description of Supply'
                      ? TextDecorationStyle.dotted
                      : null,
                ),
                children: [
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: maxWidth, child: child),
          ),
        ),
      ],
    );
  }

  TextEditingController _getBillController(String billId) {
    return _billPaymentControllers.putIfAbsent(
      billId,
      () => TextEditingController()..addListener(_recalculateTotalAllocated),
    );
  }

  String _getBillPaymentDate(String billId) {
    return _billPaymentDates.putIfAbsent(
      billId,
      () => _paymentDateController.text,
    );
  }

  GlobalKey _getBillDateKey(String billId) {
    return _billDateKeys.putIfAbsent(billId, () => GlobalKey());
  }

  void _recalculateTotalAllocated() {
    if (!mounted) return;
    setState(() {
      // Bill-row edits should refresh dependent UI, but must not overwrite
      // the user-entered Payment Made amount.
    });
  }

  Widget _buildBillRow(PurchasesBill bill) {
    final billAmtController = _getBillController(bill.id);
    final paymentDateText = _getBillPaymentDate(bill.id);

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              // Date
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 12, 8),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.billDate != null
                              ? DateFormat('dd-MM-yyyy').format(bill.billDate!)
                              : '',
                          style: AppTheme.tableCell,
                        ),
                        if (bill.dueDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Due Date: ${DateFormat('dd-MM-yyyy').format(bill.dueDate!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppTheme.borderColor),
              // Bill#
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      bill.billNumber ?? '',
                      style: AppTheme.tableCell,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppTheme.borderColor),
              // PO#
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      bill.orderNumber ?? '',
                      style: AppTheme.tableCell,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppTheme.borderColor),
              // Location
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      bill.warehouseName ?? '',
                      style: AppTheme.tableCell,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppTheme.borderColor),
              // Bill Amount
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      bill.total.toStringAsFixed(2),
                      style: AppTheme.tableCell,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppTheme.borderColor),
              // Amount Due
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      bill.total.toStringAsFixed(2),
                      style: AppTheme.tableCell,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppTheme.borderColor),
              // Payment Made on
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: MouseRegion(
                      onEnter: (_) => setState(() {
                        _hoveredBillDateIds.add(bill.id);
                      }),
                      onExit: (_) => setState(() {
                        _hoveredBillDateIds.remove(bill.id);
                      }),
                      child: GestureDetector(
                        onTap: () async {
                          final parsed =
                              DateFormat(
                                'dd-MM-yyyy',
                              ).tryParse(paymentDateText) ??
                              DateTime.now();
                          final picked = await ZerpaiDatePicker.show(
                            context,
                            initialDate: parsed,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            targetKey: _getBillDateKey(bill.id),
                          );
                          if (picked != null) {
                            setState(() {
                              _billPaymentDates[bill.id] = DateFormat(
                                'dd-MM-yyyy',
                              ).format(picked);
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          key: _getBillDateKey(bill.id),
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _hoveredBillDateIds.contains(bill.id)
                                  ? AppTheme.infoBlue
                                  : AppTheme.borderColor,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  paymentDateText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const Icon(
                                LucideIcons.calendar,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppTheme.borderColor),
              // Payment input field + Pay in Full
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 24, 8),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 32,
                          child: CustomTextField(
                            controller: billAmtController,
                            height: 32,
                            textAlign: TextAlign.right,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              
                            ),
                            hintText: '0.00',
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              billAmtController.text = bill.total
                                  .toStringAsFixed(2);
                              _recalculateTotalAllocated();
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 3,
                            ),
                            child: Text(
                              'Pay in Full',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryBlue,
                                
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
      ],
    );
  }

  Widget _buildBillsTable() {
    final billsState = ref.watch(billsProvider);
    final vendorBills = billsState.bills
        .where((b) => b.vendorId == _selectedVendor?.id)
        .toList();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFF9FAFB),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, color: AppTheme.borderColor),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Text(
                        'Bill#',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, color: AppTheme.borderColor),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Text(
                        'PO#',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, color: AppTheme.borderColor),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Text(
                        'Warehouse',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, color: AppTheme.borderColor),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Text(
                        'Bill Amount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, color: AppTheme.borderColor),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Text(
                        'Amount Due',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, color: AppTheme.borderColor),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Payment Made on',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                                
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const ZTooltip(
                            message: 'The most recent of the Bill Date or Payment Date will be set here.',
                            direction: ZTooltipDirection.top,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 1, color: AppTheme.borderColor),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 24, 12),
                      child: Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          if (billsState.isLoading)
            const Skeletonizer(
              enabled: true,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: ZTableSkeleton(rows: 3, columns: 6),
              ),
            )
          else if (vendorBills.isEmpty)
            Container(
              height: 180,
              color: Colors.white,
              alignment: Alignment.center,
              child: const Text(
                'There are no bills for this vendor.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                  
                ),
              ),
            )
          else
            ...vendorBills.map((bill) => _buildBillRow(bill)),
        ],
      ),
    );
  }

  double _getPaymentAmount() {
    final text = _paymentAmountController.text.trim();
    if (text.isEmpty) return 0.0;
    return double.tryParse(text) ?? 0.0;
  }

  String _formatAmount(double val) {
    return val.toStringAsFixed(2);
  }

  double _getAllocatedPaymentAmount() {
    double total = 0.0;
    for (final controller in _billPaymentControllers.values) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        total += double.tryParse(text) ?? 0.0;
      }
    }
    return total;
  }

  Widget _buildTotalRow() {
    final amtVal = _getPaymentAmount();
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Total :',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              
            ),
          ),
          const SizedBox(width: 48),
          Text(
            _formatAmount(amtVal),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeachSummaryCard() {
    final amt = _getPaymentAmount();
    final amountUsed = _getAllocatedPaymentAmount();
    final amountInExcess = amt - amountUsed;
    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummaryRow('Amount Paid:', _formatAmount(amt)),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Amount used for Payments:',
            _formatAmount(amountUsed),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow('Amount Refunded:', '0.00'),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Amount in Excess:',
            '₹ ${_formatAmount(amountInExcess)}',
            isExcess: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isExcess = false}) {
    final displayValue = isExcess
        ? '₹ ${_formatAmount(_getPaymentAmount() - _getAllocatedPaymentAmount())}'
        : value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                child: isExcess
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: Stack(
                          alignment: Alignment.center,
                          children: const [
                            CustomPaint(
                              size: Size(14, 14),
                              painter: _FilledTrianglePainter(
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              child: Text(
                                '!',
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF92400E),
                    
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          displayValue,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isExcess ? FontWeight.w600 : FontWeight.w500,
            color: const Color(0xFF92400E),
            
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection({bool isEditMode = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditMode
              ? 'Notes (Internal use. Not visible to vendor)'
              : 'Notes',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 650,
          child: CustomTextField(
            controller: _notesController,
            maxLines: 3,
            height: 72,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
            
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _uploadDropdownLink,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Upload Button
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickAttachmentFiles,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.upload,
                            size: 15,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Upload File',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                              
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Split Chevron Dropdown Button
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: const BorderSide(color: AppTheme.borderColor),
                    bottom: const BorderSide(color: AppTheme.borderColor),
                    right: const BorderSide(color: AppTheme.borderColor),
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleUploadDropdown,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                    child: Icon(
                      _isUploadDropdownOpen
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              if (_uploadedFiles.isNotEmpty) ...[
                const SizedBox(width: 8),
                CompositedTransformTarget(
                  link: _fileBadgeLink,
                  child: Material(
                    color: AppTheme.infoBlue,
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      onTap: _toggleFileBadgeOverlay,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.paperclip,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_uploadedFiles.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'You can upload a maximum of 5 files, 10MB each',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
            
          ),
        ),
        const SizedBox(height: 32),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              
            ),
            children: [
              TextSpan(
                text: 'Additional Fields: ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              TextSpan(
                text:
                    'Start adding custom fields for your payments made by going to ',
              ),
              TextSpan(
                text: 'Settings → Purchases → Payments Made.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleUploadDropdown() {
    if (_isUploadDropdownOpen) {
      _closeUploadDropdown();
    } else {
      _openUploadDropdown();
    }
  }

  void _toggleFileBadgeOverlay() {
    if (_fileBadgeOverlayEntry != null) {
      _closeFileBadgeOverlay();
    } else {
      _openFileBadgeOverlay();
    }
  }

  void _openFileBadgeOverlay() {
    _closeFileBadgeOverlay();
    _fileBadgeOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeFileBadgeOverlay,
              behavior: HitTestBehavior.translucent,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _fileBadgeLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 40),
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(8),
              color: Colors.transparent,
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _uploadedFiles
                        .asMap()
                        .entries
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.file, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    e.value.name,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () {
                                    _removeAttachmentFile(e.key);
                                    if (_uploadedFiles.isEmpty) {
                                      _closeFileBadgeOverlay();
                                    } else {
                                      _fileBadgeOverlayEntry?.markNeedsBuild();
                                    }
                                  },
                                  child: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_fileBadgeOverlayEntry!);
  }

  void _closeFileBadgeOverlay() {
    _fileBadgeOverlayEntry?.remove();
    _fileBadgeOverlayEntry = null;
  }

  void _openUploadDropdown() {
    _closeUploadDropdown();
    _uploadDropdownOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeUploadDropdown,
              behavior: HitTestBehavior.translucent,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _uploadDropdownLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 40),
            child: Material(
              color: Colors.transparent,
              child: _UploadDropdownMenu(
                onDismiss: _closeUploadDropdown,
                onSelect: (option) {
                  if (option == 'Attach From Desktop' ||
                      option == 'Attach From Documents') {
                    _pickAttachmentFiles();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected: $option')),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_uploadDropdownOverlayEntry!);
    setState(() => _isUploadDropdownOpen = true);
  }

  void _closeUploadDropdown() {
    _uploadDropdownOverlayEntry?.remove();
    _uploadDropdownOverlayEntry = null;
    if (mounted && _isUploadDropdownOpen) {
      setState(() => _isUploadDropdownOpen = false);
    }
  }

  Future<void> _pickAttachmentFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final remaining = 5 - _uploadedFiles.length;
    if (remaining <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 files allowed')),
        );
      }
      return;
    }

    final List<PlatformFile> validFiles = [];
    for (final file in result.files.take(remaining)) {
      if (file.size <= 10 * 1024 * 1024) {
        validFiles.add(file);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${file.name} exceeds 10MB size limit')),
          );
        }
      }
    }

    if (validFiles.isNotEmpty) {
      setState(() {
        _uploadedFiles = [..._uploadedFiles, ...validFiles];
      });
    }
  }

  void _removeAttachmentFile(int index) {
    setState(() {
      _uploadedFiles = List<PlatformFile>.from(_uploadedFiles)..removeAt(index);
    });
  }

  Future<void> _savePayment(String status) async {
    if (_selectedVendor == null) {
      ZerpaiToast.error(context, 'Please select a vendor');
      return;
    }

    final double paymentAmount =
        double.tryParse(_paymentAmountController.text) ?? 0.0;
    if (paymentAmount <= 0.0) {
      ZerpaiToast.error(context, 'Please enter a valid payment amount');
      return;
    }

    if (_paymentPaidFrom == null) {
      ZerpaiToast.error(context, 'Please select Paid Through account');
      return;
    }

    try {
      final paidThroughRef = _paymentPaidFrom!.id ?? _paymentPaidFrom!.label;

      final List<Map<String, dynamic>> allocations = [];
      final billsState = ref.read(billsProvider);
      final vendorBills = billsState.bills
          .where((b) => b.vendorId == _selectedVendor!.id)
          .toList();

      double totalAllocatedVal = 0.0;
      for (final bill in vendorBills) {
        final controller = _billPaymentControllers[bill.id];
        if (controller != null) {
          final amtText = controller.text.trim();
          if (amtText.isNotEmpty) {
            final double amt = double.tryParse(amtText) ?? 0.0;
            if (amt > 0.0) {
              totalAllocatedVal += amt;
              allocations.add({
                'bill_id': bill.id,
                'bill_amount': bill.total,
                'amount_due': bill.total,
                'allocated_amount': amt,
                'payment_date': _paymentDateController.text.isNotEmpty
                    ? DateFormat('dd-MM-yyyy')
                          .parse(_paymentDateController.text)
                          .toIso8601String()
                          .split('T')[0]
                    : DateTime.now().toIso8601String().split('T')[0],
              });
            }
          }
        }
      }

      final double excess = (paymentAmount - totalAllocatedVal).clamp(
        0.0,
        double.infinity,
      );

      if (excess > 0) {
        final selectedDepositTo = await _showExcessPaymentDialog(excess);
        if (selectedDepositTo == null) {
          return;
        }
        _depositTo = selectedDepositTo;
      }

      final depositToRef = _depositTo?.id ?? _depositTo?.label;

      String orgId = '';
      try {
        orgId = resolveOrgSystemId(context);
      } catch (_) {}
      if (orgId.isEmpty) {
        orgId = '600000000000';
      }

      Map<String, dynamic>? taxPayload;
      if (!_isBillPayment) {
        final tdsRatesAsync = ref.read(paymentsMadeTdsRatesProvider);
        final tdsList = tdsRatesAsync.value ?? [];
        String? tdsTaxId;
        double tdsPct = 0.0;
        double tdsAmt = 0.0;

        if (_selectedTdsTax != null) {
          final selectedTds = tdsList.firstWhere(
            (t) => t.name == _selectedTdsTax,
            orElse: () =>
                const PaymentsMadeTdsRateItem(id: '', name: '', rate: 0.0),
          );
          if (selectedTds.id.isNotEmpty) {
            tdsTaxId = selectedTds.id;
            tdsPct = selectedTds.rate;
            tdsAmt = paymentAmount * (tdsPct / 100.0);
          }
        }

        taxPayload = {
          'gst_treatment':
              _selectedVendor!.gstTreatment ?? 'Unregistered Business',
          'gstin': _selectedVendor!.gstin ?? '',
          'source_of_supply': _sourceOfSupply,
          'destination_of_supply': _destinationOfSupply,
          'description_of_supply': _descriptionOfSupplyController.text.trim(),
          'reverse_charge': _reverseCharge,
          if (tdsTaxId != null) 'tds_tax_id': tdsTaxId,
          'tds_percentage': tdsPct,
          'tds_amount': tdsAmt,
        };
      }

      setState(() {
        _isSaving = true;
      });

      final List<Map<String, dynamic>> attachmentsPayload = [];
      final storage = StorageService();
      for (final file in _uploadedFiles) {
        String? existingPath;
        try {
          existingPath = file.path?.trim();
        } catch (_) {}
        if (existingPath != null &&
            (existingPath.startsWith('http://') ||
                existingPath.startsWith('https://'))) {
          attachmentsPayload.add({
            'file_name': file.name,
            'file_path': existingPath,
            'original_file_name': file.name,
            'file_size': file.size,
            'file_type': file.extension ?? 'application/octet-stream',
            'remarks': '',
          });
          continue;
        }

        final fileUrl = await storage.uploadPaymentAttachment(file);
        if (fileUrl != null) {
          attachmentsPayload.add({
            'file_name': file.name,
            'file_path': fileUrl,
            'original_file_name': file.name,
            'file_size': file.size,
            'file_type': file.extension ?? 'application/octet-stream',
            'remarks': '',
          });
        }
      }

      final payment = PaymentMade(
        id: _editingPaymentDbId ?? '',
        entityId: '',
        vendorId: _selectedVendor!.id,
        paymentType: _isBillPayment ? 'RECORD_PAYMENT' : 'VENDOR_ADVANCE',
        transactionSeriesId: _paymentTransactionSeriesId,
        paymentNumber: _paymentNumberController.text.trim(),
        paymentDate: _paymentDateVal,
        paymentAmount: paymentAmount,
        paidThroughAccountId: paidThroughRef,
        depositToAccountId: depositToRef,
        paymentMode: _paymentMode,
        referenceNumber: _paymentReferenceController.text.trim(),
        status: status,
        notes: _notesController.text.trim(),
        totalAllocated: totalAllocatedVal,
        excessAmount: excess,
        billAllocations: allocations,
        paymentMadeTax: taxPayload,
        paymentMadeAttachments: attachmentsPayload,
      );

      if (_editingPaymentDbId != null && _editingPaymentDbId!.isNotEmpty) {
        await ref
            .read(paymentsMadeRepositoryProvider)
            .updatePaymentMade(_editingPaymentDbId!, payment);
      } else {
        await ref
            .read(paymentsMadeRepositoryProvider)
            .createPaymentMade(payment);
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ZerpaiToast.success(
          context,
          _editingPaymentDbId != null && _editingPaymentDbId!.isNotEmpty
              ? 'Payment updated successfully'
              : 'Payment saved successfully',
        );
        context.go('/$orgId/purchases/payments-made/report');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ZerpaiToast.error(context, 'Failed to save payment: $e');
      }
    }
  }

  Widget _buildBottomActionsBar(BuildContext context) {
    final bool useEditFooter = _isEditMode;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
      child: Row(
        children: [
          if (!useEditFooter) ...[
            Opacity(
              opacity: _selectedVendor == null ? 0.5 : 1.0,
              child: IgnorePointer(
                ignoring: _selectedVendor == null,
                child: OutlinedButton(
                  onPressed: () => _savePayment('draft'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Save as Draft',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textBody,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Opacity(
            opacity: _selectedVendor == null ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: _selectedVendor == null,
              child: ElevatedButton(
                onPressed: () => _savePayment('paid'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  useEditFooter ? 'Save' : 'Save as Paid',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              final state = GoRouterState.of(context);
              context.goNamed(
                AppRoutes.paymentsMade,
                pathParameters: state.pathParameters,
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
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
    );
  }
}

class _UploadDropdownMenu extends StatefulWidget {
  final VoidCallback onDismiss;
  final ValueChanged<String> onSelect;

  const _UploadDropdownMenu({required this.onDismiss, required this.onSelect});

  @override
  State<_UploadDropdownMenu> createState() => _UploadDropdownMenuState();
}

class _UploadDropdownMenuState extends State<_UploadDropdownMenu> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          _buildItem(0, 'Attach From Desktop'),
          _buildItem(1, 'Attach From Documents'),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildItem(int index, String text) {
    final isHovered = _hoveredIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () {
          widget.onSelect(text);
          widget.onDismiss();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isHovered ? const Color(0xFF1D4ED8) : Colors.transparent,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: isHovered ? Colors.white : AppTheme.textPrimary,
              
            ),
          ),
        ),
      ),
    );
  }
}

class ConfigurePaymentModeDialog extends StatefulWidget {
  final String entityId;
  final List<String> initialModes;
  final ValueChanged<List<String>> onSave;

  const ConfigurePaymentModeDialog({
    super.key,
    required this.entityId,
    required this.initialModes,
    required this.onSave,
  });

  @override
  State<ConfigurePaymentModeDialog> createState() =>
      _ConfigurePaymentModeDialogState();
}

class _ConfigurePaymentModeDialogState
    extends State<ConfigurePaymentModeDialog> {
  late final List<TextEditingController> _controllers;
  String _defaultMode = 'Cash';
  int? _hoveredModeIndex;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialModes.isEmpty
        ? const ['Cash']
        : widget.initialModes;
    _controllers = seed
        .map((mode) => TextEditingController(text: mode))
        .toList();
    final matchedDefault = seed.where(
      (mode) => mode.trim().toLowerCase() == 'cash',
    );
    if (matchedDefault.isNotEmpty) {
      _defaultMode = matchedDefault.first;
    } else {
      _defaultMode = seed.first;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addMode() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeMode(int index) {
    if (_controllers.length <= 1) return;

    setState(() {
      final removedValue = _controllers[index].text.trim();
      final controller = _controllers.removeAt(index);
      controller.dispose();

      if (removedValue.toLowerCase() == _defaultMode.trim().toLowerCase()) {
        _defaultMode = _controllers.first.text.trim().isEmpty
            ? 'Cash'
            : _controllers.first.text.trim();
      }
      if (_hoveredModeIndex == index) {
        _hoveredModeIndex = null;
      }
    });
  }

  void _markAsDefault(int index) {
    setState(() {
      final candidate = _controllers[index].text.trim();
      if (candidate.isNotEmpty) {
        _defaultMode = candidate;
      }
    });
  }

  void _save() async {
    final values = _controllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (values.isEmpty) {
      widget.onSave(widget.initialModes);
      Navigator.of(context).pop();
      return;
    }

    values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (widget.entityId.isNotEmpty) {
      try {
        final supabase = Supabase.instance.client;
        
        final currentRows = await supabase
            .from('payment_made_payment_mode')
            .select('id, name, is_default')
            .eq('entity_id', widget.entityId);
            
        final currentModes = List<Map<String, dynamic>>.from(currentRows as List);
        final Map<String, Map<String, dynamic>> dbModesMap = {
          for (var item in currentModes) item['name'] as String: item
        };

        final Set<String> newNamesSet = values.toSet();

        for (var dbMode in currentModes) {
          final name = dbMode['name'] as String;
          if (!newNamesSet.contains(name)) {
            await supabase
                .from('payment_made_payment_mode')
                .update({'is_deleted': true, 'is_default': false})
                .eq('id', dbMode['id']);
          }
        }

        for (var name in values) {
          final isDef = (name == _defaultMode);
          final existing = dbModesMap[name];
          if (existing != null) {
            await supabase
                .from('payment_made_payment_mode')
                .update({
                  'is_deleted': false,
                  'is_default': isDef,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', existing['id']);
          } else {
            await supabase
                .from('payment_made_payment_mode')
                .insert({
                  'entity_id': widget.entityId,
                  'name': name,
                  'is_default': isDef,
                  'is_deleted': false,
                });
          }
        }
      } catch (e) {
        debugPrint('Failed to save payment modes: $e');
      }
    }

    widget.onSave(values);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.only(top: 0, left: 24, right: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 760),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Payment Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                          
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...List.generate(_controllers.length, (index) {
                        final isDefault =
                            _controllers[index].text.trim().toLowerCase() ==
                            _defaultMode.trim().toLowerCase();
                        final isHovered = _hoveredModeIndex == index;
                        return MouseRegion(
                          onEnter: (_) =>
                              setState(() => _hoveredModeIndex = index),
                          onExit: (_) =>
                              setState(() => _hoveredModeIndex = null),
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 12, top: 2),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppTheme.borderColor),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 200,
                                  child: CustomTextField(
                                    controller: _controllers[index],
                                    height: 30,
                                    hintText: 'Enter payment mode',
                                  ),
                                ),
                                if (isDefault) ...[
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2F8F2F),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const Text(
                                      'Default',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        
                                      ),
                                    ),
                                  ),
                                ] else if (isHovered) ...[
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () => _markAsDefault(index),
                                    child: const Text(
                                      'Mark as Default',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF6B7280),
                                        
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => _removeMode(index),
                                    child: const Icon(
                                      LucideIcons.xCircle,
                                      size: 14,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _addMode,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 2, bottom: 12),
                          child: Text(
                            '+ Add New',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryBlue,
                              
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppTheme.borderColor)),
                ),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
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
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                        foregroundColor: const Color(0xFF374151),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
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

class _FilledTrianglePainter extends CustomPainter {
  final Color color;

  const _FilledTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(size.width / 2, 1)
      ..lineTo(size.width - 1, size.height - 1.5)
      ..lineTo(1, size.height - 1.5)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FilledTrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class VendorSideTag extends StatelessWidget {
  final String vendorName;
  final VoidCallback onTap;

  const VendorSideTag({
    super.key,
    required this.vendorName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF475569),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              vendorName.length > 20
                  ? '${vendorName.substring(0, 20)}...'
                  : vendorName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

