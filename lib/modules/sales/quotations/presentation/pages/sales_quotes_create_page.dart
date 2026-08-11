import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/app/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
// import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
// import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
// import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
// import 'package:zerpai_erp/modules/items/items/presentation/sections/items_stock_providers.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/providers/pricelist_provider.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
// import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_item_model.dart';
// import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/advanced_customer_search_dialog.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/sales_order_item_row.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
// import 'package:zerpai_erp/shared/providers/lookup_providers.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/address_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/add_contact_person_dialog.dart';
// import 'package:zerpai_erp/shared/widgets/dialogs/inventory_bin_batch_foc.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
// import 'package:zerpai_erp/shared/widgets/inputs/warehouse_popover.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_adaptive_menu.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/bulk_items_dialog.dart';
import 'package:zerpai_erp/modules/sales/customers/presentation/sales_customer_create.dart';
import 'package:zerpai_erp/modules/sales/customers/presentation/widgets/customer_sidebar.dart';
// import 'package:zerpai_erp/modules/sales/customers/presentation/sales_customer_create.dart';
// import 'package:zerpai_erp/modules/sales/customers/presentation/sales_customer_create.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/shared/widgets/hsn_sac_search_modal.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/sales_item_quick_edit_dialog.dart';
import 'package:zerpai_erp/modules/sales/models/hsn_sac_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/po_item_details_sidebar_widget.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/manage_tds_tcs_rates_dialog.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';

final salesQuotationProductsProvider = FutureProvider<List<Item>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('products')
        .select('*')
        .order('product_name', ascending: true);
    
    return (response as List).map((json) => Item.fromJson(json)).toList();
  } catch (e) {
    debugPrint('Error loading products from Supabase products: $e');
    return [];
  }
});

final salesQuotationTransactionSeriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final entityId = ref.watch(entityProvider).entityId ?? '';
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('transaction_series')
        .select('name')
        .eq('entity_id', entityId)
        .order('name', ascending: true);
    
    final List<String> list = (response as List)
        .map((row) => row['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    
    return list;
  } catch (e) {
    debugPrint('Error loading transaction series from Supabase: $e');
    return [];
  }
});

final salesQuotationPriceListsProvider =
    Provider<AsyncValue<List<PriceList>>>((ref) {
      return ref.watch(activeSalesPriceListsAsyncProvider);
    });

class TaxOption {
  final String id;
  final String name;
  final double rate;
  const TaxOption({required this.id, required this.name, required this.rate});
}

class SalesQuotationTaxesState {
  final List<TaxOption> taxGroups;
  final List<TaxOption> taxRatesIgst;
  const SalesQuotationTaxesState({required this.taxGroups, required this.taxRatesIgst});
}

final salesQuotationTaxesProvider = FutureProvider<SalesQuotationTaxesState>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    
    // 1. Fetch active tax groups
    final taxGroupsResponse = await supabase
        .from('tax_groups')
        .select('id, tax_group_name, tax_rate')
        .eq('is_active', true)
        .order('tax_group_name', ascending: true);
        
    final groups = (taxGroupsResponse as List).map((row) {
      return TaxOption(
        id: row['id']?.toString() ?? '',
        name: row['tax_group_name']?.toString() ?? '',
        rate: double.tryParse(row['tax_rate']?.toString() ?? '0') ?? 0.0,
      );
    }).toList();
    
    // 2. Fetch active tax rates filtering by IGST only
    final taxRatesResponse = await supabase
        .from('tax_rates')
        .select('id, tax_name, tax_rate')
        .eq('is_active', true)
        .ilike('tax_name', '%igst%')
        .order('tax_name', ascending: true);
        
    final rates = (taxRatesResponse as List).map((row) {
      return TaxOption(
        id: row['id']?.toString() ?? '',
        name: row['tax_name']?.toString() ?? '',
        rate: double.tryParse(row['tax_rate']?.toString() ?? '0') ?? 0.0,
      );
    }).toList();
    
    return SalesQuotationTaxesState(taxGroups: groups, taxRatesIgst: rates);
  } catch (e) {
    debugPrint('Error loading taxes from Supabase: $e');
    return const SalesQuotationTaxesState(taxGroups: [], taxRatesIgst: []);
  }
});

final salesQuotationStatesFromDbProvider = FutureProvider<List<String>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('states')
        .select('name')
        .order('name', ascending: true);
    
    return (response as List)
        .map((row) => row['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  } catch (e) {
    debugPrint('Error loading states from Supabase: $e');
    return [];
  }
});

class TdsRateOption {
  final String id;
  final String name;
  final double rate;
  const TdsRateOption({required this.id, required this.name, required this.rate});
}

final salesQuotationTdsRatesProvider = FutureProvider<List<TdsRateOption>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('tds_rates')
        .select('id, tax_name, base_rate')
        .eq('is_active', true)
        .order('tax_name', ascending: true);
    
    return (response as List).map((row) {
      return TdsRateOption(
        id: row['id']?.toString() ?? '',
        name: row['tax_name']?.toString() ?? '',
        rate: double.tryParse(row['base_rate']?.toString() ?? '0') ?? 0.0,
      );
    }).toList();
  } catch (e) {
    debugPrint('Error loading TDS rates from Supabase: $e');
    return [];
  }
});

class TcsRateOption {
  final String id;
  final String name;
  final double rate;
  const TcsRateOption({required this.id, required this.name, required this.rate});
}

final salesQuotationTcsRatesProvider = FutureProvider<List<TcsRateOption>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('tcs_rates')
        .select('id, tax_name, rate')
        .eq('is_active', true)
        .order('tax_name', ascending: true);
    
    return (response as List).map((row) {
      return TcsRateOption(
        id: row['id']?.toString() ?? '',
        name: row['tax_name']?.toString() ?? '',
        rate: double.tryParse(row['rate']?.toString() ?? '0') ?? 0.0,
      );
    }).toList();
  } catch (e) {
    debugPrint('Error loading TCS rates from Supabase: $e');
    return [];
  }
});

class SalespersonOption {
  final String id;
  final String name;
  const SalespersonOption({required this.id, required this.name});
}

class QuoteContactPersonOption {
  final String id;
  final String? salutation;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? workPhone;
  final String? mobilePhone;

  const QuoteContactPersonOption({
    required this.id,
    this.salutation,
    this.firstName,
    this.lastName,
    this.email,
    this.workPhone,
    this.mobilePhone,
  });

  String get displayName {
    final parts = <String>[
      if (salutation != null && salutation!.trim().isNotEmpty) salutation!.trim(),
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ];
    return parts.join(' ').trim();
  }

  String get primaryLabel {
    final name = displayName;
    if (name.isNotEmpty) {
      return name;
    }
    if (email != null && email!.trim().isNotEmpty) {
      return email!.trim();
    }
    if (mobilePhone != null && mobilePhone!.trim().isNotEmpty) {
      return mobilePhone!.trim();
    }
    if (workPhone != null && workPhone!.trim().isNotEmpty) {
      return workPhone!.trim();
    }
    return id;
  }

  String get searchLabel {
    return [
      primaryLabel,
      if (email != null && email!.trim().isNotEmpty) email!.trim(),
      if (mobilePhone != null && mobilePhone!.trim().isNotEmpty) mobilePhone!.trim(),
      if (workPhone != null && workPhone!.trim().isNotEmpty) workPhone!.trim(),
    ].join(' ');
  }
}

class _QuoteCommunicationChannelConfig {
  final bool all;
  final bool email;
  final bool sms;

  const _QuoteCommunicationChannelConfig({
    this.all = false,
    this.email = true,
    this.sms = false,
  });

  _QuoteCommunicationChannelConfig copyWith({
    bool? all,
    bool? email,
    bool? sms,
  }) {
    return _QuoteCommunicationChannelConfig(
      all: all ?? this.all,
      email: email ?? this.email,
      sms: sms ?? this.sms,
    );
  }
}

final salesQuotationSalespersonsProvider = FutureProvider<List<SalespersonOption>>((ref) async {
  try {
    final entityId = ref.watch(entityProvider).entityId ?? '';
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('users')
        .select('id, full_name')
        .eq('entity_id', entityId)
        .eq('is_active', true)
        .order('full_name', ascending: true);
    
    return (response as List).map((row) {
      return SalespersonOption(
        id: row['id']?.toString() ?? '',
        name: row['full_name']?.toString() ?? '',
      );
    }).toList();
  } catch (e) {
    debugPrint('Error loading salespersons from Supabase: $e');
    return [];
  }
});

final salesQuotationCustomerContactPersonsProvider =
    FutureProvider.family<List<QuoteContactPersonOption>, String?>((
      ref,
      customerId,
    ) async {
      try {
        final normalizedCustomerId = customerId?.trim() ?? '';
        if (normalizedCustomerId.isEmpty) {
          return const <QuoteContactPersonOption>[];
        }

        final entityId = ref.watch(entityProvider).entityId ?? '';
        final supabase = Supabase.instance.client;
        List response = const [];
        if (entityId.isNotEmpty) {
          try {
            response = await supabase
                    .from('customer_contact_persons')
                    .select(
                      'id, customer_id, salutation, first_name, last_name, email, work_phone, mobile_phone, display_order',
                    )
                    .eq('customer_id', normalizedCustomerId)
                    .eq('entity_id', entityId)
                    .order('display_order', ascending: true)
                    .order('first_name', ascending: true)
                    .order('last_name', ascending: true)
                as List;
          } catch (_) {
            response = const [];
          }
        }

        if (response.isEmpty) {
          response = await supabase
              .from('customer_contact_persons')
              .select(
                'id, customer_id, salutation, first_name, last_name, email, work_phone, mobile_phone, display_order',
              )
              .eq('customer_id', normalizedCustomerId)
              .order('display_order', ascending: true)
              .order('first_name', ascending: true)
              .order('last_name', ascending: true)
              as List;
        }

        return response
            .map(
              (row) => QuoteContactPersonOption(
                id: row['id']?.toString() ?? '',
                salutation: row['salutation']?.toString(),
                firstName: row['first_name']?.toString(),
                lastName: row['last_name']?.toString(),
                email: row['email']?.toString(),
                workPhone: row['work_phone']?.toString(),
                mobilePhone: row['mobile_phone']?.toString(),
              ),
            )
            .where((contact) => contact.id.isNotEmpty)
            .toList();
      } catch (e) {
        debugPrint('Error loading customer contact persons from Supabase: $e');
        return const <QuoteContactPersonOption>[];
      }
    });

class SalesQuoteCreateScreen extends ConsumerStatefulWidget {
  final String? editQuoteId;
  final String? cloneQuoteId;
  final Map<String, dynamic>? initialCloneData;
  const SalesQuoteCreateScreen({
    super.key,
    this.editQuoteId,
    this.cloneQuoteId,
    this.initialCloneData,
  });

  @override
  ConsumerState<SalesQuoteCreateScreen> createState() =>
      _SalesQuoteCreateScreenState();
}

class _SalesQuoteCreateScreenState
    extends ConsumerState<SalesQuoteCreateScreen> {
  static const double _labelWidth = 142;
  static const double _fieldWidth = 268;
  static const double _wideFieldWidth = 460;
  static const double _fieldHeight = 32;
  static const double _smallFieldHeight = 30;
  static const double _dateFieldHeight = 34;
  static const double _lowerContentWidth = 1120;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _quoteDateKey = GlobalKey();
  final GlobalKey _expiryDateKey = GlobalKey();
  final LayerLink _quoteDateLink = LayerLink();
  final LayerLink _expiryDateLink = LayerLink();
  final LayerLink _billingAddressLink = LayerLink();
  final LayerLink _shippingAddressLink = LayerLink();
  final LayerLink _gstTaxLink = LayerLink();

  OverlayEntry? _addressDropdownOverlay;
  OverlayEntry? _gstTaxOverlay;

  bool _isDirty = false;
  bool _createRetainerInvoice = false;
  bool _useTds = true;
  bool _isSaving = false;
  bool _isLoadingExisting = false; // will be set true immediately in initState if editing
  bool _isQuoteNumberAutoGenerate = true;
  int? _hoveredRowIndex;
  bool _showBulkUpdateToolbar = false;
  final Set<int> _selectedRows = {};
  OverlayEntry? _rowActionsOverlay;
  OverlayEntry? _itemActionsOverlay;
  // bool _showAdditionalInfo = true;

  String? _selectedCustomerId;
  String? _selectedPlaceOfSupply;
  SalesCustomer? _selectedCustomerOverride;
  String _selectedSeries = 'Default Transaction Series';
  String? _selectedSalesperson;
  String? _selectedPriceListId;
  String? _selectedWarehouseId;
  String? _selectedTaxId;
  List<String> _selectedShareQuoteWithIds = <String>[];
  final Map<String, _QuoteCommunicationChannelConfig>
  _communicationChannelsByContactId =
      <String, _QuoteCommunicationChannelConfig>{};

  late final TextEditingController _quoteNumberCtrl;
  late final TextEditingController _referenceCtrl;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _customerNotesCtrl;
  late final TextEditingController _termsCtrl;
  late final TextEditingController _shippingCtrl;
  late final TextEditingController _adjustmentCtrl;
  late final TextEditingController _adjustmentLabelCtrl;
  late final TextEditingController _retainerPercentageCtrl;

  DateTime _quoteDate = DateTime.now();
  DateTime? _expiryDate = DateTime.now();

  OverlayEntry? _reportingTagsOverlay;
  OverlayEntry? _bulkActionsOverlay;
  final LayerLink _bulkActionsLink = LayerLink();
  String? _hoveredBulkAction;
  bool _showAllAdditionalInformation = true;
  OverlayEntry? _addRowOverlay;
  final LayerLink _addRowLink = LayerLink();
  OverlayEntry? _addBulkOverlay;
  // final LayerLink _addBulkLink = LayerLink();
  OverlayEntry? _hsnOverlay;
  SalesOrderItemRow? _activeHsnRow;
  OverlayEntry? _uploadOverlay;
  final LayerLink _uploadLink = LayerLink();
  bool _isAddHeaderHovered = false;
  OverlayEntry? _attachmentListOverlay;
  OverlayEntry? _customerDetailsSidebarOverlay;
  final LayerLink _attachmentBadgeLink = LayerLink();
  List<PlatformFile> _attachedFiles = [];
  bool _isUploadButtonHovered = false;

  final List<SalesOrderItemRow> _rows = <SalesOrderItemRow>[];
  List<Map<String, dynamic>> _tdsRatesList = [];
  List<Map<String, dynamic>> _tdsSectionsList = [];
  List<Map<String, dynamic>> _tcsRatesList = [];
  List<Map<String, dynamic>> _tcsNaturesList = [];
  bool _isLoadingTdsRates = false;

  double _subTotal = 0;
  double _taxTotal = 0;
  Map<String, double> _taxBreakdown = const {};
  double _tdsTcsAmount = 0;
  double _total = 0;
  // String _selectedStockView = 'Stock on Hand';
  // String? _selectedStockType = 'Accounting';





  Future<void> _loadTdsRates() async {
    if (_isLoadingTdsRates) return;
    _isLoadingTdsRates = true;
    try {
      final lookupsService = LookupsApiService();
      final List<Map<String, dynamic>> tdsRates = await lookupsService.getTdsRates();
      final List<Map<String, dynamic>> tdsSections = await lookupsService.getTdsSections();
      final List<Map<String, dynamic>> tcsRates = await lookupsService.getTcsRates();
      final List<Map<String, dynamic>> tcsNatures = await lookupsService.getTcsNatures();
      if (mounted) {
        setState(() {
          _tdsRatesList = tdsRates;
          _tdsSectionsList = tdsSections;
          _tcsRatesList = tcsRates;
          _tcsNaturesList = tcsNatures;
        });
      }
    } catch (e) {
      debugPrint('Error loading TDS/TCS rates: $e');
    } finally {
      _isLoadingTdsRates = false;
    }
  }

  void _showManageTdsRatesDialog() {
    showDialog(
      context: context,
      builder: (context) => ManageTdsTcsRatesDialog(
        title: 'Manage TDS Rates',
        isTcs: false,
        items: _tdsRatesList,
        sections: _tdsSectionsList,
        selectedId: _selectedTaxId,
        onSelect: (value) {
          setState(() {
            _selectedTaxId = value['id']?.toString() ?? '';
          });
          _calculateTotals();
          ref.invalidate(salesQuotationTdsRatesProvider);
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncTdsRates(items);
          if (mounted) {
            setState(() {
              _tdsRatesList = updated;
            });
          }
          ref.invalidate(salesQuotationTdsRatesProvider);
          return updated;
        },
        onDeleteCheck: (item) async {
          if (item['id'] == null || item['id'].toString().startsWith('new_')) {
            return null;
          }
          try {
            final lookupsService = LookupsApiService();
            final usage = await lookupsService.checkLookupUsage(
              'tds-rates',
              item['id'].toString(),
            );
            if (usage['inUse'] == true) {
              return usage['message'] ??
                  'This TDS rate is in use and cannot be deleted.';
            }
          } catch (e) {
            AppLogger.error(
              'Error checking TDS rate usage',
              error: e,
              module: 'sales',
            );
          }
          return null;
        },
      ),
    );
  }

  void _showManageTcsRatesDialog() {
    showDialog(
      context: context,
      builder: (context) => ManageTdsTcsRatesDialog(
        title: 'Manage TCS Rates',
        isTcs: true,
        items: _tcsRatesList,
        sections: _tcsNaturesList,
        selectedId: _selectedTaxId,
        onSelect: (value) {
          setState(() {
            _selectedTaxId = value['id']?.toString() ?? '';
          });
          _calculateTotals();
          ref.invalidate(salesQuotationTcsRatesProvider);
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncTcsRates(items);
          if (mounted) {
            setState(() {
              _tcsRatesList = updated;
            });
          }
          ref.invalidate(salesQuotationTcsRatesProvider);
          return updated;
        },
        onDeleteCheck: (item) async {
          if (item['id'] == null || item['id'].toString().startsWith('new_')) {
            return null;
          }
          try {
            final lookupsService = LookupsApiService();
            final usage = await lookupsService.checkLookupUsage(
              'tcs-rates',
              item['id'].toString(),
            );
            if (usage['inUse'] == true) {
              return usage['message'] ??
                  'This TCS rate is in use and cannot be deleted.';
            }
          } catch (e) {
            AppLogger.error(
              'Error checking TCS rate usage',
              error: e,
              module: 'sales',
            );
          }
          return null;
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _quoteNumberCtrl = TextEditingController();
    _referenceCtrl = TextEditingController();
    _subjectCtrl = TextEditingController();
    _customerNotesCtrl = TextEditingController();
    _termsCtrl = TextEditingController();
    _shippingCtrl = TextEditingController(text: '0.00');
    _adjustmentCtrl = TextEditingController(text: '0.00');
    _adjustmentLabelCtrl = TextEditingController(text: 'Adjustment');
    _retainerPercentageCtrl = TextEditingController();

    _shippingCtrl.addListener(_calculateTotals);
    _adjustmentCtrl.addListener(_calculateTotals);
    _loadTdsRates();

    if (widget.initialCloneData != null) {
      _isQuoteNumberAutoGenerate = true;
      _isLoadingExisting = true;
      _quoteNumberCtrl.text = '';
      _customerNotesCtrl.text = '';
      _shippingCtrl.text = '0.00';
      _adjustmentCtrl.text = '0.00';
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyInitialCloneData(widget.initialCloneData!),
      );
    } else if (_sourceQuoteId != null) {
      _isQuoteNumberAutoGenerate = !_isEditMode;
      _isLoadingExisting = true; // set synchronously before first build
      // clear defaults that would flash before DB data arrives
      _quoteNumberCtrl.text = '';
      _customerNotesCtrl.text = '';
      _shippingCtrl.text = '0.00';
      _adjustmentCtrl.text = '0.00';
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingQuote());
    } else {
      _addItemRow();
      _initializeQuoteNumber();
    }
  }

  bool get _isEditMode => widget.editQuoteId != null;
  bool get _isCloneMode =>
      widget.cloneQuoteId != null || widget.initialCloneData != null;
  String? get _sourceQuoteId => widget.editQuoteId ?? widget.cloneQuoteId;

  Future<String?> _resolveQuoteDbIdFromAnyIdentifier(String? rawId) async {
    final identifier = rawId?.trim() ?? '';
    if (identifier.isEmpty) {
      return null;
    }
    final supabase = Supabase.instance.client;

    try {
      final byId = await supabase
          .from('sales_quotations')
          .select('id')
          .eq('id', identifier)
          .maybeSingle();
      final resolved = byId?['id']?.toString().trim() ?? '';
      if (resolved.isNotEmpty) {
        return resolved;
      }
    } catch (_) {}

    try {
      final byNumber = await supabase
          .from('sales_quotations')
          .select('id')
          .eq('quotation_number', identifier)
          .maybeSingle();
      final resolved = byNumber?['id']?.toString().trim() ?? '';
      if (resolved.isNotEmpty) {
        return resolved;
      }
    } catch (_) {}

    return null;
  }

  Future<Map<String, Item>> _loadQuoteProductsById(
    List<String> productIds,
  ) async {
    final byId = <String, Item>{};
    if (productIds.isEmpty) {
      return byId;
    }
    try {
      final providerProducts = await ref.read(
        salesQuotationProductsProvider.future,
      );
      for (final product in providerProducts) {
        final productId = product.id?.trim() ?? '';
        if (productId.isNotEmpty && productIds.contains(productId)) {
          byId[productId] = product;
        }
      }
    } catch (e) {
      debugPrint('Provider products lookup warning: $e');
    }
    return byId;
  }

  Future<List<dynamic>> _fetchQuoteItemRows(String resolvedDbId) async {
    final rows = await Supabase.instance.client
        .from('sales_quotation_items')
        .select(
          '*, '
          'product:products('
          'id, product_name, selling_price, sales_description, hsn_code:hsn_sac_code, sku, type, unit_id'
          ')',
        )
        .eq('quotation_id', resolvedDbId)
        .order('line_no', ascending: true);
    return rows as List<dynamic>;
  }

  Item? _buildHydratedQuoteItem(
    Map<String, dynamic> itemRow, {
    required Map<String, Map<String, dynamic>> productMap,
    required Map<String, Item> providerProductsById,
  }) {
    final productId = itemRow['product_id']?.toString() ?? '';
    final joinedProduct =
        itemRow['product'] is Map
            ? Map<String, dynamic>.from(itemRow['product'] as Map)
            : null;
    final product = joinedProduct ?? productMap[productId];
    final providerProduct = providerProductsById[productId];

    if (product != null) {
      return Item(
        id: product['id']?.toString() ?? productId,
        productName: product['product_name']?.toString() ?? '',
        sellingPrice:
            double.tryParse(product['selling_price']?.toString() ?? '0') ?? 0,
        salesDescription: product['sales_description']?.toString(),
        hsnCode: product['hsn_code']?.toString(),
        sku: product['sku']?.toString(),
        type: product['type']?.toString() ?? 'goods',
        itemCode:
            product['sku']?.toString() ??
            product['id']?.toString() ??
            productId,
        unitId: product['unit_id']?.toString() ?? '',
      );
    }

    if (providerProduct != null) {
      return providerProduct;
    }

    if (productId.isEmpty) {
      return null;
    }

    final fallbackName =
        itemRow['name']?.toString().trim().isNotEmpty == true
            ? itemRow['name'].toString().trim()
            : itemRow['description']?.toString().trim().isNotEmpty == true
            ? itemRow['description'].toString().trim()
            : productId;

    return Item(
      id: productId,
      productName: fallbackName,
      sellingPrice: double.tryParse(itemRow['rate']?.toString() ?? '0') ?? 0,
      salesDescription: itemRow['description']?.toString(),
      hsnCode: itemRow['hsn_code']?.toString(),
      type: 'goods',
      itemCode: productId,
      unitId: '',
    );
  }

  Future<void> _populateRowsFromDbQuoteItems(String resolvedDbId) async {
    final itemsData = await _fetchQuoteItemRows(resolvedDbId);
    final productIds = itemsData
        .map((i) => i['product_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    final productMap = <String, Map<String, dynamic>>{};
    if (productIds.isNotEmpty) {
      try {
        final prodRes = await Supabase.instance.client
            .from('products')
            .select(
              'id, product_name, selling_price, sales_description, hsn_code:hsn_sac_code, sku, type, unit_id',
            )
            .inFilter('id', productIds);
        for (final p in (prodRes as List)) {
          productMap[p['id'].toString()] = Map<String, dynamic>.from(p);
        }
      } catch (e) {
        debugPrint('Products lookup warning: $e');
      }
    }

    final providerProductsById = await _loadQuoteProductsById(productIds);

    _rows.clear();
    for (final raw in itemsData) {
      if (raw is! Map) {
        continue;
      }
      final itemRow = Map<String, dynamic>.from(raw);
      final quantity =
          double.tryParse(itemRow['quantity']?.toString() ?? '1') ?? 1;
      final rate = double.tryParse(itemRow['rate']?.toString() ?? '0') ?? 0;
      final discountValue =
          double.tryParse(itemRow['discount_value']?.toString() ?? '0') ?? 0;

      final row = SalesOrderItemRow(
        quantityCtrl: TextEditingController(
          text: quantity == quantity.roundToDouble()
              ? quantity.toStringAsFixed(0)
              : quantity.toString(),
        ),
        rateCtrl: TextEditingController(text: rate.toStringAsFixed(2)),
        discountCtrl: TextEditingController(
          text: discountValue == discountValue.roundToDouble()
              ? discountValue.toStringAsFixed(0)
              : discountValue.toString(),
        ),
        descriptionCtrl: TextEditingController(
          text: itemRow['description']?.toString() ?? '',
        ),
        itemId: itemRow['product_id']?.toString() ?? '',
        discountType: itemRow['discount_type']?.toString() ?? '%',
        taxId: itemRow['tax_id']?.toString() ?? 'Non-Taxable',
        warehouseId: itemRow['warehouse_id']?.toString(),
        item: _buildHydratedQuoteItem(
          itemRow,
          productMap: productMap,
          providerProductsById: providerProductsById,
        ),
      );
      row.hsnCode = itemRow['hsn_code']?.toString();
      _setupRowListeners(row);
      _rows.add(row);
    }

    _selectedWarehouseId = _rows
        .map((row) => row.warehouseId?.trim())
        .where((warehouseId) => warehouseId != null && warehouseId.isNotEmpty)
        .cast<String?>()
        .firstWhere((warehouseId) => warehouseId != null, orElse: () => null);
  }

  Future<void> _applyInitialCloneData(Map<String, dynamic> data) async {
    if (mounted) {
      setState(() => _isLoadingExisting = true);
    }
    try {
      _referenceCtrl.text = data['referenceNumber']?.toString() ?? '';
      _subjectCtrl.text = data['subject']?.toString() ?? '';
      _customerNotesCtrl.text = data['customerNotes']?.toString() ?? '';
      _termsCtrl.text = data['termsAndConditions']?.toString() ?? '';
      _shippingCtrl.text = (data['shippingCharge'] ?? 0).toString();
      _adjustmentCtrl.text = (data['adjustment'] ?? 0).toString();

      final quotationDate = data['quotationDate']?.toString();
      if (quotationDate != null && quotationDate.trim().isNotEmpty) {
        _quoteDate = DateTime.tryParse(quotationDate) ?? _quoteDate;
      }

      final expiryDate = data['expiryDate']?.toString();
      if (expiryDate != null && expiryDate.trim().isNotEmpty) {
        _expiryDate = DateTime.tryParse(expiryDate);
      }

      _selectedCustomerId = data['customerId']?.toString();
      _selectedPlaceOfSupply = data['placeOfSupply']?.toString();
      _selectedSalesperson = data['salespersonId']?.toString();
      _selectedPriceListId = data['priceListId']?.toString();
      _selectedWarehouseId = data['warehouseId']?.toString();

      final customerMap =
          data['customer'] is Map
              ? Map<String, dynamic>.from(data['customer'] as Map)
              : null;
      if (customerMap != null && customerMap.isNotEmpty) {
        _selectedCustomerOverride = SalesCustomer.fromJson(customerMap);
      }

      final resolvedDbId =
          await _resolveQuoteDbIdFromAnyIdentifier(widget.cloneQuoteId) ??
          await _resolveQuoteDbIdFromAnyIdentifier(data['dbId']?.toString()) ??
          await _resolveQuoteDbIdFromAnyIdentifier(
            data['quoteNumber']?.toString(),
          );

      if (resolvedDbId != null) {
        await _populateRowsFromDbQuoteItems(resolvedDbId);
      } else {
        _rows.clear();
        final clonedItems =
            data['items'] is List
                ? List<dynamic>.from(data['items'] as List)
                : const <dynamic>[];

        for (final item in clonedItems) {
          if (item is! Map) {
            continue;
          }
          final itemMap = Map<String, dynamic>.from(item);
          final productId = itemMap['product_id']?.toString() ?? '';
          final quantity =
              double.tryParse(itemMap['quantity']?.toString() ?? '1') ?? 1;
          final rate =
              double.tryParse(itemMap['rate']?.toString() ?? '0') ?? 0;
          final discountValue =
              double.tryParse(itemMap['discount_value']?.toString() ?? '0') ??
              0;
          final itemName = itemMap['name']?.toString().trim() ?? '';
          final description = itemMap['description']?.toString() ?? '';

          final resolvedItem =
              productId.isNotEmpty || itemName.isNotEmpty
                  ? Item(
                    id: productId,
                    productName: itemName.isNotEmpty ? itemName : '-',
                    sellingPrice: rate,
                    salesDescription:
                        description.isNotEmpty ? description : null,
                    hsnCode: itemMap['hsn_code']?.toString(),
                    type: 'goods',
                    itemCode: productId.isNotEmpty ? productId : itemName,
                    unitId: '',
                  )
                  : null;

          final row = SalesOrderItemRow(
            quantityCtrl: TextEditingController(
              text: quantity == quantity.roundToDouble()
                  ? quantity.toStringAsFixed(0)
                  : quantity.toString(),
            ),
            rateCtrl: TextEditingController(text: rate.toStringAsFixed(2)),
            discountCtrl: TextEditingController(
              text: discountValue == discountValue.roundToDouble()
                  ? discountValue.toStringAsFixed(0)
                  : discountValue.toString(),
            ),
            descriptionCtrl: TextEditingController(text: description),
            itemId: productId,
            discountType: itemMap['discount_type']?.toString() ?? '%',
            taxId: itemMap['tax_id']?.toString() ?? 'Non-Taxable',
            warehouseId: itemMap['warehouse_id']?.toString(),
            item: resolvedItem,
          );
          row.hsnCode = itemMap['hsn_code']?.toString();
          _setupRowListeners(row);
          _rows.add(row);
        }
      }

      if (_rows.isEmpty) {
        _addItemRow();
      }

      _quoteNumberCtrl.text = '';
      await _initializeQuoteNumber();
      _calculateTotals();
    } catch (e) {
      debugPrint('Failed to apply clone payload: $e');
      if (_rows.isEmpty) {
        _addItemRow();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingExisting = false);
      }
    }
  }

  Future<void> _loadExistingQuote() async {
    if (mounted) setState(() => _isLoadingExisting = true);
    try {
      final supabase = Supabase.instance.client;
      final editId = _sourceQuoteId!;

      // ── 1. Fetch quote header by id or quotation_number ───────────────────
      Map<String, dynamic>? quoteData;
      try {
        quoteData = await supabase
            .from('sales_quotations')
            .select('*')
            .eq('id', editId)
            .maybeSingle();
      } catch (_) {}

      if (quoteData == null) {
        quoteData = await supabase
            .from('sales_quotations')
            .select('*')
            .eq('quotation_number', editId)
            .maybeSingle();
      }

      if (quoteData == null) {
        throw Exception('Quotation not found with ID/Number: $editId');
      }

      final resolvedDbId = quoteData['id'].toString();

      // ── 2. Fetch customer separately using customer_id ───────────────────
      final customerId = quoteData['customer_id']?.toString() ?? '';
      Map<String, dynamic>? customerData;
      if (customerId.isNotEmpty) {
        try {
          customerData = await supabase
              .from('customers')
              .select(
                'id, display_name, email, phone, gst_treatment, company_name, '
                'billing_address_street1:billing_address_street, billing_address_street2:billing_address_place, billing_address_city, '
                'billing_address_state_id:billing_address_state, billing_address_zip, billing_address_country_id:billing_country_region, billing_address_phone, '
                'shipping_address_street1:shipping_address_street, shipping_address_street2:shipping_address_place, shipping_address_city, '
                'shipping_address_state_id:shipping_address_state, shipping_address_zip, shipping_address_country_id:shipping_country_region, shipping_address_phone',
              )
              .eq('id', customerId)
              .maybeSingle();
        } catch (custErr) {
          debugPrint('Customer lookup warning: $custErr');
        }
      }

      // ── 3. Fetch quote items with joined product data for reliable clone/edit hydration ──
      List<dynamic> itemsData = [];
      try {
        final itemsRes = await supabase
            .from('sales_quotation_items')
            .select(
              '*, '
              'product:products('
              'id, product_name, selling_price, sales_description, hsn_code:hsn_sac_code, sku, type, unit_id'
              ')',
            )
            .eq('quotation_id', resolvedDbId)
            .order('line_no', ascending: true);
        itemsData = itemsRes as List<dynamic>;
      } catch (itemErr) {
        debugPrint('Items lookup warning: $itemErr');
      }

      // Fetch products for items if any
      final productIds = itemsData
          .map((i) => i['product_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> productMap = {};
      if (productIds.isNotEmpty) {
        try {
          final prodRes = await supabase
              .from('products')
              .select('id, product_name, selling_price, sales_description, hsn_code:hsn_sac_code, sku, type, unit_id')
              .inFilter('id', productIds);
          for (final p in (prodRes as List)) {
            productMap[p['id'].toString()] = Map<String, dynamic>.from(p);
          }
        } catch (prodErr) {
          debugPrint('Products lookup warning: $prodErr');
        }
      }

      final Map<String, Item> providerProductsById = <String, Item>{};
      if (productIds.isNotEmpty) {
        try {
          final providerProducts = await ref.read(
            salesQuotationProductsProvider.future,
          );
          for (final product in providerProducts) {
            final productId = product.id?.trim() ?? '';
            if (productId.isNotEmpty) {
              providerProductsById[productId] = product;
            }
          }
        } catch (providerErr) {
          debugPrint('Provider products lookup warning: $providerErr');
        }
      }

      if (!mounted) return;

      // ── 4. Populate header fields ────────────────────────────────────────
      _quoteNumberCtrl.text = quoteData['quotation_number']?.toString() ?? '';
      _referenceCtrl.text = quoteData['reference_number']?.toString() ?? '';
      _subjectCtrl.text = quoteData['subject']?.toString() ?? '';
      _customerNotesCtrl.text = quoteData['customer_notes']?.toString() ?? '';
      _termsCtrl.text = quoteData['terms_and_conditions']?.toString() ?? '';
      _shippingCtrl.text = (quoteData['shipping_charge'] ?? 0).toString();
      _adjustmentCtrl.text = (quoteData['adjustment'] ?? 0).toString();

      if (quoteData['quotation_date'] != null) {
        _quoteDate = DateTime.tryParse(quoteData['quotation_date'].toString()) ?? _quoteDate;
      }
      if (quoteData['expiry_date'] != null) {
        _expiryDate = DateTime.tryParse(quoteData['expiry_date'].toString());
      }

      _selectedCustomerId = customerId.isNotEmpty ? customerId : null;
      _selectedPlaceOfSupply = quoteData['place_of_supply']?.toString();
      _selectedSalesperson = quoteData['salesperson_id']?.toString();
      _selectedPriceListId = quoteData['price_list_id']?.toString();

      // Pre-populate customer override for the dropdown display
      if (customerData != null && customerId.isNotEmpty) {
        _selectedCustomerOverride = SalesCustomer.fromJson(customerData);
      }

      // ── 5. Populate item rows ─────────────────────────────────────────────
      _rows.clear();
      for (final itemRow in itemsData) {
        final productId = itemRow['product_id']?.toString() ?? '';
        final joinedProduct =
            itemRow['product'] is Map
                ? Map<String, dynamic>.from(itemRow['product'] as Map)
                : null;
        final product = joinedProduct ?? productMap[productId];
        final providerProduct = providerProductsById[productId];
        final resolvedItem = product != null
            ? Item(
                id: product['id']?.toString() ?? '',
                productName: product['product_name']?.toString() ?? '',
                sellingPrice:
                    double.tryParse(product['selling_price']?.toString() ?? '0') ??
                    0,
                salesDescription: product['sales_description']?.toString(),
                hsnCode: product['hsn_code']?.toString(),
                sku: product['sku']?.toString(),
                type: product['type']?.toString() ?? 'goods',
                itemCode:
                    product['sku']?.toString() ??
                    product['id']?.toString() ??
                    '',
                unitId: product['unit_id']?.toString() ?? '',
              )
            : providerProduct;

        final row = SalesOrderItemRow(
          quantityCtrl: TextEditingController(
            text: (itemRow['quantity'] ?? 1).toString(),
          ),
          rateCtrl: TextEditingController(
            text: double.tryParse(
              (itemRow['rate'] ?? 0).toString(),
            )?.toStringAsFixed(2) ?? '0.00',
          ),
          discountCtrl: TextEditingController(
            text: (itemRow['discount_value'] ?? 0).toString(),
          ),
          descriptionCtrl: TextEditingController(
            text: itemRow['description']?.toString() ?? '',
          ),
          itemId: productId,
          discountType: itemRow['discount_type']?.toString() ?? '%',
          taxId: itemRow['tax_id']?.toString() ?? 'Non-Taxable',
          warehouseId: itemRow['warehouse_id']?.toString(),
          item: resolvedItem,
        );
        row.hsnCode = itemRow['hsn_code']?.toString();
        _setupRowListeners(row);
        _rows.add(row);
      }

      _selectedWarehouseId = _rows
          .map((row) => row.warehouseId?.trim())
          .where((warehouseId) => warehouseId != null && warehouseId.isNotEmpty)
          .cast<String?>()
          .firstWhere((warehouseId) => warehouseId != null, orElse: () => null);

      if (_isCloneMode) {
        _quoteNumberCtrl.text = '';
        await _initializeQuoteNumber();
      }

      if (_rows.isEmpty) _addItemRow();
      _calculateTotals();
    } catch (e, stack) {
      debugPrint('❌ _loadExistingQuote error: $e');
      debugPrint(stack.toString());
      if (mounted) {
        ZerpaiToast.error(
          context,
          'Failed to load quote data: ${e.toString()}',
        );
      }
      if (_rows.isEmpty) _addItemRow();
    } finally {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }


  Future<void> _initializeQuoteNumber() async {
    if (!_isQuoteNumberAutoGenerate) {
      return;
    }

    final nextNumber = await _generateNextQuoteNumber();
    if (!mounted || nextNumber == null) {
      return;
    }

    setState(() {
      _quoteNumberCtrl.text = nextNumber;
    });
  }

  Future<String?> _generateNextQuoteNumber() async {
    var entityId = ref.read(entityProvider).entityId?.trim();
    if (entityId == null || entityId.isEmpty) {
      final user = ref.read(authUserProvider);
      entityId = user?.orgEntityId?.trim();
    }
    if (entityId == null || entityId.isEmpty) {
      return null;
    }

    try {
      final supabase = Supabase.instance.client;
      final rows = await supabase
          .from('sales_quotations')
          .select('quotation_number')
          .eq('entity_id', entityId)
          .order('created_at', ascending: false)
          .limit(200);

      var maxValue = 4;
      for (final row in (rows as List)) {
        final quoteNumber = (row['quotation_number'] ?? '').toString().trim();
        final match = RegExp(r'(\d+)$').firstMatch(quoteNumber);
        if (match == null) {
          continue;
        }
        final parsed = int.tryParse(match.group(1)!);
        if (parsed != null && parsed > maxValue) {
          maxValue = parsed;
        }
      }

      return 'QT-${(maxValue + 1).toString().padLeft(5, '0')}';
    } catch (e) {
      debugPrint('Failed to generate next quote number: $e');
      return null;
    }
  }

  bool _isUuidLike(String? value) {
    if (value == null) {
      return false;
    }
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }

  void _showCustomerDetailsSidebar(SalesCustomer customer) {
    _customerDetailsSidebarOverlay?.remove();
    _customerDetailsSidebarOverlay = null;

    final currencyLabel = _resolveCustomerCurrencyLabel(customer);

    _customerDetailsSidebarOverlay = OverlayEntry(
       builder: (context) => Stack(
         children: [
           GestureDetector(
             onTap: () {
               _customerDetailsSidebarOverlay?.remove();
               _customerDetailsSidebarOverlay = null;
             },
             child: Container(color: Colors.black.withValues(alpha: 0.05)),
           ),
           Positioned(
             right: 0,
             top: 0,
             bottom: 0,
             child: Material(
               color: Colors.transparent,
               child: CustomerDetailsSidebar(
                 customer: customer,
                 currencyLabel: currencyLabel,
                 onClose: () {
                   _customerDetailsSidebarOverlay?.remove();
                   _customerDetailsSidebarOverlay = null;
                 },
               ),
             ),
           ),
         ],
       ),
    );

    Overlay.of(context).insert(_customerDetailsSidebarOverlay!);
  }

  @override
  void dispose() {
    _customerDetailsSidebarOverlay?.remove();
    _customerDetailsSidebarOverlay = null;
    if (_reportingTagsOverlay != null) {
      _reportingTagsOverlay?.remove();
      _reportingTagsOverlay = null;
    }
    if (_bulkActionsOverlay != null) {
      _bulkActionsOverlay?.remove();
      _bulkActionsOverlay = null;
    }
    if (_addRowOverlay != null) {
      _addRowOverlay?.remove();
      _addRowOverlay = null;
    }
    if (_addBulkOverlay != null) {
      _addBulkOverlay?.remove();
      _addBulkOverlay = null;
    }
    _hsnOverlay?.remove();
    _hsnOverlay = null;
    _activeHsnRow = null;
    _uploadOverlay?.remove();
    _uploadOverlay = null;
    _attachmentListOverlay?.remove();
    _attachmentListOverlay = null;
    _closeAddressDropdownOverlay();
    _closeGstTaxOverlay();
    _quoteNumberCtrl.dispose();
    _referenceCtrl.dispose();
    _subjectCtrl.dispose();
    _customerNotesCtrl.dispose();
    _termsCtrl.dispose();
    _shippingCtrl.dispose();
    _adjustmentCtrl.dispose();
    _adjustmentLabelCtrl.dispose();
    _retainerPercentageCtrl.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty && mounted) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _handleCancel() async {
    if (_isDirty) {
      final shouldDiscard = await showUnsavedChangesDialog(
        context,
        message: 'If you leave, your unsaved quote changes will be discarded.',
      );
      if (!mounted || !shouldDiscard) {
        return;
      }
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.salesQuotations);
    }
  }

  void _setupRowListeners(SalesOrderItemRow row) {
    row.quantityCtrl.addListener(() {
      _syncRowRateFromCustomer(row);
      _calculateTotals();
    });
    row.rateCtrl.addListener(_calculateTotals);
    row.discountCtrl.addListener(_calculateTotals);
    row.rateFocus.addListener(() {
      if (!row.rateFocus.hasFocus) {
        _handleRateCalculation(row);
      }
    });
  }

  void _addItemRow() {
    final row = SalesOrderItemRow(
      quantityCtrl: TextEditingController(text: '1'),
      rateCtrl: TextEditingController(text: '0.00'),
      discountCtrl: TextEditingController(text: '0'),
      discountType: '%',
      taxId: 'Non-Taxable',
    );
    _setupRowListeners(row);
    setState(() => _rows.add(row));
  }

  bool _hasEmptyItemRow({SalesOrderItemRow? excludingRow}) {
    for (final existingRow in _rows) {
      if (identical(existingRow, excludingRow) || existingRow.isHeader) {
        continue;
      }
      final hasNoItem =
          existingRow.item == null && existingRow.itemId.trim().isEmpty;
      if (hasNoItem) {
        return true;
      }
    }
    return false;
  }

  void _removeItemRow(int index) {
    if (_rows.length == 1) {
      final row = _rows.first;
      setState(() {
        row.itemId = '';
        row.item = null;
        row.taxId = 'Non-Taxable';
        row.discountType = '%';
        row.quantityCtrl.text = '1';
        row.rateCtrl.text = '0.00';
        row.discountCtrl.text = '0';
      });
      _calculateTotals();
      return;
    }

    setState(() {
      _rows.removeAt(index).dispose();
    });
    _calculateTotals();
  }

  SalesCustomer? _selectedCustomer(List<SalesCustomer> customers) {
    final override = _selectedCustomerOverride;
    if (override != null && override.id == _selectedCustomerId) {
      return override;
    }
    for (final customer in customers) {
      if (customer.id == _selectedCustomerId) {
        return customer;
      }
    }
    return null;
  }

  void _syncAllRowRatesFromCustomer(List<SalesCustomer> customers) {
    final customer = _selectedCustomer(customers);
    if (customer == null) {
      return;
    }

    final priceLists = ref.read(salesQuotationPriceListsProvider).valueOrNull;
    if (priceLists == null) {
      return;
    }

    for (final row in _rows) {
      _updateRowRate(row, customer, priceLists);
    }
    _calculateTotals();
  }

  void _syncRowRateFromCustomer(SalesOrderItemRow row) {
    final customers = ref.read(salesCustomersProvider).valueOrNull;
    final customer = customers == null ? null : _selectedCustomer(customers);
    final priceLists = ref.read(salesQuotationPriceListsProvider).valueOrNull;
    if (customer == null || priceLists == null) {
      return;
    }
    _updateRowRate(row, customer, priceLists);
  }

  void _updateRowRate(
    SalesOrderItemRow row,
    SalesCustomer customer,
    List<PriceList> priceLists,
  ) {
    if (row.item == null) {
      return;
    }

    final priceListId = _resolvedRowPriceListId(row, customer);
    if (priceListId == null || priceListId.isEmpty || priceListId == 'Select') {
      return;
    }

    final matches = priceLists.where((priceList) => priceList.id == priceListId);
    if (matches.isEmpty) {
      return;
    }

    final priceList = matches.first;
    final quantity = double.tryParse(row.quantityCtrl.text) ?? 1;
    final newRate = priceList.calculatePrice(
      row.itemId,
      (row.item!.sellingPrice ?? 0).toDouble(),
      quantity: quantity,
    );

    final formattedRate = newRate.toStringAsFixed(2);
    if (row.rateCtrl.text != formattedRate) {
      row.rateCtrl.text = formattedRate;
    }
  }

  String? _resolvedRowPriceListId(
    SalesOrderItemRow row,
    SalesCustomer? customer,
  ) {
    if (row.priceListId != null) {
      final explicitValue = row.priceListId!.trim();
      return explicitValue.isEmpty ? null : explicitValue;
    }
    return _selectedPriceListId ?? customer?.priceList;
  }

  bool _priceListIncludesItem(
    PriceList priceList,
    String itemId, {
    String? productName,
  }) {
    if (priceList.priceListType != 'individual_items') {
      return true;
    }
    final normalizedItemId = itemId.trim().toLowerCase();
    final normalizedProductName = productName?.trim().toLowerCase() ?? '';

    for (final rate in priceList.itemRates ?? const <PriceListItemRate>[]) {
      final rateItemId = rate.itemId.trim().toLowerCase();
      final rateItemName = rate.itemName?.trim().toLowerCase() ?? '';
      if (rateItemId == normalizedItemId ||
          (normalizedProductName.isNotEmpty &&
              (rateItemId == normalizedProductName ||
                  rateItemName == normalizedProductName)) ||
          (rateItemName.isNotEmpty && rateItemName == normalizedItemId)) {
        return true;
      }
    }
    return false;
  }

  void _showAdvancedCustomerSearch(List<SalesCustomer> customers) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Advanced Customer Search',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) => AdvancedCustomerSearchDialog(
        customers: customers,
        onSelect: (customer) {
          setState(() {
            _selectedCustomerId = customer.id;
            _selectedCustomerOverride = customer;
            _selectedPlaceOfSupply = _normalizedPlaceOfSupply(
              customer.placeOfSupply ??
                  customer.shippingAddressStateId ??
                  customer.billingAddressStateId,
            );
          });
          _syncAllRowRatesFromCustomer(customers);
        },
      ),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  double _discountAmount(SalesOrderItemRow row) {
    final quantity = double.tryParse(row.quantityCtrl.text) ?? 0;
    final rate = _getParsedRate(row);
    final discount = double.tryParse(row.discountCtrl.text) ?? 0;
    final gross = quantity * rate;

    if (row.discountType == '%') {
      return gross * (discount / 100);
    }
    return discount;
  }

  double _rowAmount(SalesOrderItemRow row) {
    if (row.itemId.isEmpty) {
      return 0;
    }

    final quantity = double.tryParse(row.quantityCtrl.text) ?? 0;
    final rate = _getParsedRate(row);
    final gross = quantity * rate;
    final discountAmount = _discountAmount(row);
    return gross - discountAmount;
  }

  String? _normalizedQuoteItemTaxId(
    String? taxId,
    List<TaxOption> activeTaxes,
  ) {
    final normalized = taxId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (!_isUuidLike(normalized)) {
      return null;
    }
    for (final tax in activeTaxes) {
      if (tax.id == normalized) {
        return normalized;
      }
    }
    return null;
  }

  bool _isKeralaPlaceOfSupply([String? value]) {
    return (value ?? _selectedPlaceOfSupply ?? '').trim().toLowerCase() ==
        'kerala';
  }

  bool _isGstTaxOption(TaxOption tax) {
    final normalizedName = tax.name.trim().toLowerCase();
    return normalizedName.contains('gst');
  }

  List<TaxOption> _resolveActiveTaxes(SalesQuotationTaxesState? taxesState) {
    if (taxesState == null) {
      return const <TaxOption>[];
    }
    if (_isKeralaPlaceOfSupply()) {
      return taxesState.taxGroups.where(_isGstTaxOption).toList();
    }
    return taxesState.taxRatesIgst;
  }

  void _applyPlaceOfSupply(String? value) {
    final normalizedValue = value?.trim();
    final taxesState = ref.read(salesQuotationTaxesProvider).valueOrNull;
    final nextIsKerala = _isKeralaPlaceOfSupply(normalizedValue);
    final activeTaxes = taxesState == null
        ? const <TaxOption>[]
        : (nextIsKerala
            ? taxesState.taxGroups.where(_isGstTaxOption).toList()
            : taxesState.taxRatesIgst);
    final validTaxIds = activeTaxes.map((tax) => tax.id).toSet();

    setState(() {
      _selectedPlaceOfSupply = normalizedValue;
      for (final row in _rows) {
        final taxId = row.taxId?.trim();
        if (taxId != null &&
            taxId.isNotEmpty &&
            taxId != 'Non-Taxable' &&
            taxId != 'Out of Scope' &&
            taxId != 'Non-GST Supply' &&
            !validTaxIds.contains(taxId)) {
          row.taxId = 'Non-Taxable';
        }
      }
    });
    _calculateTotals();
  }

  void _calculateTotals() {
    final taxesAsync = ref.read(salesQuotationTaxesProvider);
    final taxesState = taxesAsync.valueOrNull;
    final isKerala = _isKeralaPlaceOfSupply();
    final List<TaxOption> activeTaxes = _resolveActiveTaxes(taxesState);
    final tdsRates = ref.read(salesQuotationTdsRatesProvider).valueOrNull ??
        const <TdsRateOption>[];
    final tcsRates = ref.read(salesQuotationTcsRatesProvider).valueOrNull ??
        const <TcsRateOption>[];

    double subTotal = 0;
    double taxTotal = 0;
    final taxBreakdown = <String, double>{};
    for (final row in _rows) {
      final rowAmount = _rowAmount(row);
      subTotal += rowAmount;
      if (row.taxId != null) {
        final tax = activeTaxes.firstWhere(
          (t) => t.id == row.taxId,
          orElse: () => const TaxOption(id: '', name: '', rate: 0.0),
        );
        if (tax.rate > 0) {
          final rowTaxAmount = rowAmount * (tax.rate / 100);
          taxTotal += rowTaxAmount;
          for (final entry in _buildTaxBreakdownEntries(tax, rowTaxAmount, isKerala)) {
            taxBreakdown.update(
              entry.key,
              (existing) => existing + entry.value,
              ifAbsent: () => entry.value,
            );
          }
        }
      }
    }

    final shipping = double.tryParse(_shippingCtrl.text) ?? 0;
    final adjustment = double.tryParse(_adjustmentCtrl.text) ?? 0;
    final preTaxDeductionTotal = subTotal + taxTotal + shipping + adjustment;
    double selectedRate = 0;
    if (_selectedTaxId != null) {
      if (_useTds) {
        final selectedTds = tdsRates.firstWhere(
          (t) => t.id == _selectedTaxId,
          orElse: () => const TdsRateOption(id: '', name: '', rate: 0.0),
        );
        selectedRate = selectedTds.rate;
      } else {
        final selectedTcs = tcsRates.firstWhere(
          (t) => t.id == _selectedTaxId,
          orElse: () => const TcsRateOption(id: '', name: '', rate: 0.0),
        );
        selectedRate = selectedTcs.rate;
      }
    }
    final tdsTcsAmount = preTaxDeductionTotal * (selectedRate / 100);
    final total = _useTds
        ? preTaxDeductionTotal - tdsTcsAmount
        : preTaxDeductionTotal + tdsTcsAmount;

    setState(() {
      _subTotal = subTotal;
      _taxTotal = taxTotal;
      _taxBreakdown = taxBreakdown;
      _tdsTcsAmount = tdsTcsAmount;
      _total = total;
    });
  }

  List<MapEntry<String, double>> _buildTaxBreakdownEntries(
    TaxOption tax,
    double taxAmount,
    bool isKerala,
  ) {
    final rawName = tax.name.trim();
    if (rawName.isEmpty) {
      return const [];
    }

    final normalized = rawName.toLowerCase();
    final isGst =
        normalized.contains('gst') ||
        normalized.contains('cgst') ||
        normalized.contains('sgst') ||
        normalized.contains('igst');
    if (!isGst) {
      return [MapEntry(rawName, taxAmount)];
    }

    if (isKerala) {
      final halfRate = tax.rate / 2;
      final halfAmount = taxAmount / 2;
      final rateLabel = _formatTaxRateLabel(halfRate);
      return [
        MapEntry('CGST$rateLabel [$rateLabel%]', halfAmount),
        MapEntry('SGST$rateLabel [$rateLabel%]', halfAmount),
      ];
    }

    final rateLabel = _formatTaxRateLabel(tax.rate);
    return [MapEntry('IGST$rateLabel [$rateLabel%]', taxAmount)];
  }

  String _formatTaxRateLabel(double rate) {
    final rounded = rate.roundToDouble();
    if ((rate - rounded).abs() < 0.0001) {
      return rounded.toInt().toString();
    }
    return rate.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  Future<void> _pickQuoteDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _quoteDate,
      targetKey: _quoteDateKey,
      targetLink: _quoteDateLink,
    );
    if (picked == null) {
      return;
    }
    setState(() => _quoteDate = picked);
  }

  Future<void> _pickExpiryDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _expiryDate ?? _quoteDate,
      targetKey: _expiryDateKey,
      targetLink: _expiryDateLink,
    );
    if (picked == null) {
      return;
    }
    setState(() => _expiryDate = picked);
  }

  Future<void> _showAddContactPersonDialog([String? customerId]) async {
    final effectiveCustomerId = (customerId ?? _selectedCustomerId)?.trim();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (context) => const AddContactPersonDialog(),
    );

    if (!mounted || result == null) {
      return;
    }

    final firstName = (result['firstName']?.toString() ?? '').trim();
    final lastName = (result['lastName']?.toString() ?? '').trim();
    final email = (result['email']?.toString() ?? '').trim();
    final workPhonePrefix = (result['workPhonePrefix']?.toString() ?? '').trim();
    final workPhone = (result['workPhone']?.toString() ?? '').trim();
    final mobilePrefix = (result['mobilePrefix']?.toString() ?? '').trim();
    final mobile = (result['mobile']?.toString() ?? '').trim();
    final hasAnyValue = firstName.isNotEmpty ||
        lastName.isNotEmpty ||
        email.isNotEmpty ||
        workPhone.isNotEmpty ||
        mobile.isNotEmpty;

    if (!hasAnyValue) {
      ZerpaiToast.error(context, 'Enter at least one contact detail.');
      return;
    }

    if (effectiveCustomerId == null || effectiveCustomerId.isEmpty) {
      ZerpaiToast.error(context, 'Select a customer first.');
      return;
    }

    try {
      final entityId = ref.read(entityProvider).entityId ?? '';
      final supabase = Supabase.instance.client;
      final payload = <String, dynamic>{
        'customer_id': effectiveCustomerId,
        'salutation': (result['salutation']?.toString() ?? '').trim().isEmpty
            ? null
            : result['salutation']?.toString().trim(),
        'first_name': firstName.isEmpty ? null : firstName,
        'last_name': lastName.isEmpty ? null : lastName,
        'email': email.isEmpty ? null : email,
        'work_phone': workPhone.isEmpty
            ? null
            : '${workPhonePrefix.isEmpty ? '' : workPhonePrefix} $workPhone'.trim(),
        'mobile_phone': mobile.isEmpty
            ? null
            : '${mobilePrefix.isEmpty ? '' : mobilePrefix} $mobile'.trim(),
        if (entityId.isNotEmpty) 'entity_id': entityId,
      };

      final inserted = await supabase
          .from('customer_contact_persons')
          .insert(payload)
          .select(
            'id, customer_id, salutation, first_name, last_name, email, work_phone, mobile_phone, display_order',
          )
          .single();

      ref.invalidate(
        salesQuotationCustomerContactPersonsProvider(effectiveCustomerId),
      );

      if (!mounted) return;
      setState(() {
        final insertedId = inserted['id']?.toString();
        if (insertedId != null && insertedId.isNotEmpty) {
          if (!_selectedShareQuoteWithIds.contains(insertedId)) {
            _selectedShareQuoteWithIds = <String>[
              ..._selectedShareQuoteWithIds,
              insertedId,
            ];
          }
          _communicationChannelsByContactId.putIfAbsent(
            insertedId,
            () => const _QuoteCommunicationChannelConfig(),
          );
        }
      });
      ZerpaiToast.success(context, 'Contact person added successfully.');
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(
        context,
        ErrorHandler.getFriendlyMessage(e),
      );
    }
  }

  void _syncCommunicationChannelSelections(List<String> contactIds) {
    final activeIds = contactIds.toSet();
    _communicationChannelsByContactId.removeWhere(
      (contactId, _) => !activeIds.contains(contactId),
    );
    for (final contactId in contactIds) {
      _communicationChannelsByContactId.putIfAbsent(
        contactId,
        () => const _QuoteCommunicationChannelConfig(),
      );
    }
  }

  Future<void> _showCommunicationChannelsDialog(
    List<QuoteContactPersonOption> contacts,
  ) async {
    if (contacts.isEmpty) return;

    final result =
        await showDialog<Map<String, _QuoteCommunicationChannelConfig>>(
          context: context,
          barrierDismissible: true,
          builder: (_) => _QuoteCommunicationChannelsDialog(
            contacts: contacts,
            initialConfig: {
              for (final contact in contacts)
                contact.id:
                    _communicationChannelsByContactId[contact.id] ??
                    const _QuoteCommunicationChannelConfig(),
            },
          ),
        );

    if (!mounted || result == null) return;

    setState(() {
      _communicationChannelsByContactId.addAll(result);
    });
  }

  Future<void> _saveQuote(String status) async {
    if (!(_formKey.currentState?.validate() ?? true)) {
      return;
    }

    if (_selectedCustomerId == null) {
      ZerpaiToast.error(context, 'Select a customer before saving the quote.');
      return;
    }

    final validRows = _rows.where((row) => row.itemId.trim().isNotEmpty).toList();
    if (validRows.isEmpty) {
      ZerpaiToast.error(context, 'Add at least one item before saving the quote.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(authUserProvider);
      var entityId = ref.read(entityProvider).entityId?.trim();
      if (entityId == null || entityId.isEmpty) {
        entityId = user?.orgEntityId?.trim();
      }
      if (entityId == null || entityId.isEmpty) {
        throw Exception('Active entity not found. Select a branch or organization and try again.');
      }

      final supabase = Supabase.instance.client;
      if (!_isEditMode && _isQuoteNumberAutoGenerate) {
        final nextNumber = await _generateNextQuoteNumber();
        if (nextNumber != null && nextNumber.isNotEmpty) {
          _quoteNumberCtrl.text = nextNumber;
        }
      }

      final normalizedStatus = status == 'draft' ? 'draft' : 'sent';
      final taxesAsync = ref.read(salesQuotationTaxesProvider);
      final taxesState = taxesAsync.valueOrNull;
      final List<TaxOption> activeTaxes = _resolveActiveTaxes(taxesState);
      final discountTotal = _rows.fold<double>(
        0.0,
        (sum, row) => sum + _discountAmount(row),
      );

      final quotePayload = {
        'customer_id': _selectedCustomerId!,
        'quotation_number': _quoteNumberCtrl.text,
        'quotation_date': DateFormat('yyyy-MM-dd').format(_quoteDate),
        'expiry_date': _expiryDate != null
            ? DateFormat('yyyy-MM-dd').format(_expiryDate!)
            : null,
        'reference_number': _referenceCtrl.text,
        'subject': _subjectCtrl.text,
        'customer_notes': _customerNotesCtrl.text,
        'terms_and_conditions': _termsCtrl.text,
        'subtotal': _subTotal,
        'discount_total': discountTotal,
        'tax_total': _taxTotal,
        'shipping_charge': double.tryParse(_shippingCtrl.text) ?? 0.0,
        'adjustment': double.tryParse(_adjustmentCtrl.text) ?? 0.0,
        'grand_total': _total,
        'status': normalizedStatus,
        'place_of_supply': _selectedPlaceOfSupply,
        'price_list_id': _selectedPriceListId,
        'salesperson_id': _selectedSalesperson != null &&
                _selectedSalesperson!.length > 10
            ? _selectedSalesperson
            : null,
      };

      String resolvedQuoteId;

      if (_isEditMode) {
        // ── EDIT MODE: update header, replace items ─────────────────────────
        resolvedQuoteId = widget.editQuoteId!;
        await supabase
            .from('sales_quotations')
            .update(quotePayload)
            .eq('id', resolvedQuoteId);

        // Delete old items and re-insert fresh set
        await supabase
            .from('sales_quotation_items')
            .delete()
            .eq('quotation_id', resolvedQuoteId);
      } else {
        // ── CREATE MODE: insert new quote ───────────────────────────────────
        final insertResult = await supabase
            .from('sales_quotations')
            .insert({'entity_id': entityId, ...quotePayload})
            .select('id')
            .single();
        resolvedQuoteId = insertResult['id'] as String;
      }

      // Insert item rows (same for both modes after old items deleted)
      int lineNo = 1;
      final List<Map<String, dynamic>> itemRows = [];
      for (final row in validRows) {
        if (row.itemId.isEmpty) continue;

        final qty = double.tryParse(row.quantityCtrl.text) ?? 0;
        final rate = _getParsedRate(row);
        final discVal = double.tryParse(row.discountCtrl.text) ?? 0;
        final discAmt = _discountAmount(row);

        itemRows.add({
          'quotation_id': resolvedQuoteId,
          'line_no': lineNo++,
          'product_id': row.itemId,
          'quantity': qty,
          'rate': rate,
          'description': row.descriptionCtrl.text,
          'discount_type': row.discountType,
          'discount_value': discVal,
          'discount_amount': discAmt,
          'tax_id': _normalizedQuoteItemTaxId(row.taxId, activeTaxes),
          'warehouse_id': row.warehouseId,
          'hsn_code': row.hsnCode,
          'line_total': (qty * rate) - discAmt,
        });
      }

      if (itemRows.isNotEmpty) {
        await supabase.from('sales_quotation_items').insert(itemRows);
      }

      // Upload and save attachments if any
      if (_attachedFiles.isNotEmpty) {
        final storage = StorageService();
        final List<Map<String, dynamic>> attachmentRows = [];
        for (final file in _attachedFiles) {
          final fileUrl = await storage.uploadQuotationAttachment(file);
          if (fileUrl != null) {
            final ext = file.extension?.toLowerCase() ?? '';
            String mimeType = 'application/octet-stream';
            if (ext == 'pdf') {
              mimeType = 'application/pdf';
            } else if (ext == 'jpg' || ext == 'jpeg') {
              mimeType = 'image/jpeg';
            } else if (ext == 'png') {
              mimeType = 'image/png';
            }

            attachmentRows.add({
              'quotation_id': resolvedQuoteId,
              'file_name': file.name,
              'storage_path': fileUrl,
              'mime_type': mimeType,
              'file_size': file.size,
              'uploaded_by': user?.id,
            });
          }
        }
        if (attachmentRows.isNotEmpty) {
          await supabase.from('sales_quotation_attachments').insert(attachmentRows);
        }
      }

      // Save quotation activity
      try {
        await supabase.from('sales_quotation_activity').insert({
          'quotation_id': resolvedQuoteId,
          'action': _isEditMode ? 'edited' : 'created',
          'description': _isEditMode
              ? 'Quote edited — updated to ₹${_total.toStringAsFixed(2)}'
              : 'Quote created for ₹${_total.toStringAsFixed(2)}',
          'performed_by': user?.id,
        });
      } catch (actErr) {
        debugPrint('Failed to save quote activity: $actErr');
      }

      final savedQuote = await supabase
          .from('sales_quotations')
          .select('id, quotation_number, entity_id')
          .eq('id', resolvedQuoteId)
          .maybeSingle();

      if (savedQuote == null) {
        throw Exception(
          'Quote save could not be verified in sales_quotations. Redirect blocked.',
        );
      }

      ref.invalidate(salesQuotesProvider);

      if (!mounted) {
        return;
      }
      setState(() {
        _isDirty = false;
        _isSaving = false;
      });

      ZerpaiToast.success(
        context,
        _isEditMode
            ? 'Quote ${savedQuote['quotation_number'] ?? ''} updated successfully.'
            : 'Quote ${savedQuote['quotation_number'] ?? ''} saved successfully.',
      );

      if (_isEditMode) {
        // Go back to the overview page for the edited quote
        context.go('/sales/quotations/$resolvedQuoteId');
      } else if (status == 'draft') {
        context.go(AppRoutes.salesQuotations);
      } else {
        context.go('/sales/quotations/$resolvedQuoteId/email');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ZerpaiToast.error(context, ErrorHandler.getFriendlyMessage(error));
    }
  }


  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final productsAsync = ref.watch(salesQuotationProductsProvider);
    final priceListsAsync = ref.watch(salesQuotationPriceListsProvider);
    final seriesAsync = ref.watch(salesQuotationTransactionSeriesProvider);
    final taxesAsync = ref.watch(salesQuotationTaxesProvider);
    
    final taxesState = taxesAsync.valueOrNull;
    final List<TaxOption> activeTaxes = _resolveActiveTaxes(taxesState);

    if (_isLoadingExisting) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      onCancel: _handleCancel,
      isDirty: _isDirty,
      footer: _buildFooter(),
      child: Form(
        key: _formKey,
        onChanged: _markDirty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildPageChrome(
                customersAsync,
                productsAsync.valueOrNull ?? <Item>[],
                priceListsAsync,
                seriesAsync.valueOrNull ?? <String>['Default Transaction Series'],
                activeTaxes,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPageChrome(
    AsyncValue<List<SalesCustomer>> customersAsync,
    List<Item> items,
    AsyncValue<List<PriceList>> priceListsAsync,
    List<String> seriesList,
    List<TaxOption> activeTaxes,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleBar(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCustomerSection(customersAsync),
              _buildDivider(),
              _buildDetailsSection(priceListsAsync, seriesList),
              _buildSubjectSection(),
              _buildDivider(),
              _buildPriceListRow(priceListsAsync),
              const SizedBox(height: 10),
              _buildItemsTable(items, activeTaxes),
              const SizedBox(height: 12),
              _buildNotesAndSummary(),
              const SizedBox(height: 14),
              _buildTermsSection(),
              _buildDivider(),
              _buildRetainerSection(),
              const SizedBox(height: 24),
              _buildAdditionalFieldsNote(),
              const SizedBox(height: 22),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Row(
        children: [
          Icon(
            _isEditMode ? LucideIcons.pencil : LucideIcons.calendarRange,
            size: 24,
            color: AppTheme.textPrimary,
          ),
          const SizedBox(width: 12),
          Text(
            _isEditMode ? 'Edit Quote' : 'New Quote',
            style: AppTheme.textPrimaryStyle(18, FontWeight.w500),
          ),
          const Spacer(),
          InkWell(
            onTap: _handleCancel,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.close,
                size: 22,
                color: Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(AsyncValue<List<SalesCustomer>> customersAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          customersAsync.when(
            data: (customers) {
              final selectedCustomer = _selectedCustomer(customers);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _labelWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: RichText(
                        text: TextSpan(
                          text: 'Customer Name',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: AppTheme.errorRed,
                          ),
                          children: const [
                            TextSpan(
                              text: '*',
                              style: TextStyle(
                                color: AppTheme.errorRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 530,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: FormDropdown<String>(
                                          value: _selectedCustomerId,
                                          items: customers
                                              .map((customer) => customer.id)
                                              .toList(),
                                          hint: 'Select or add a customer',
                                          height: _fieldHeight,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(4),
                                            bottomLeft: Radius.circular(4),
                                          ),
                                          showSettings: true,
                                          settingsLabel: 'New Customer',
                                          settingsIcon: LucideIcons.plus,
                                          onSettingsTap: _showNewCustomerDialog,
                                          itemHeight: 56,
                                          itemBuilder: (id, isSelected, isHovered) {
                                            final customer = customers.firstWhere(
                                              (c) => c.id == id,
                                              orElse: () => SalesCustomer(id: id, displayName: id),
                                            );
                                            return _buildCustomerDropdownItem(
                                              customer,
                                              isSelected,
                                              isHovered,
                                            );
                                          },
                                          displayStringForValue: (id) {
                                            for (final customer in customers) {
                                              if (customer.id == id) {
                                                return customer.displayName;
                                              }
                                            }
                                            return id;
                                          },
                                          onChanged: (value) {
                                            SalesCustomer? customer;
                                            for (final candidate in customers) {
                                              if (candidate.id == value) {
                                                customer = candidate;
                                                break;
                                              }
                                            }
                                            setState(() {
                                              _selectedCustomerId = value;
                                              _selectedCustomerOverride = customer;
                                              _selectedShareQuoteWithIds = <String>[];
                                              _selectedPlaceOfSupply =
                                                  customer == null
                                                  ? null
                                                  : _normalizedPlaceOfSupply(
                                                      customer.placeOfSupply ??
                                                          customer.shippingAddressStateId ??
                                                          customer.billingAddressStateId,
                                                    );
                                            });
                                            _syncAllRowRatesFromCustomer(
                                              customers,
                                            );
                                          },
                                        ),
                                      ),
                                      Material(
                                        color: AppTheme.accentGreen,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(4),
                                          bottomRight: Radius.circular(4),
                                        ),
                                        child: InkWell(
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(4),
                                            bottomRight: Radius.circular(4),
                                          ),
                                          onTap: () =>
                                              _showAdvancedCustomerSearch(
                                                customers,
                                              ),
                                          child: SizedBox(
                                            width: 38,
                                            height: _fieldHeight,
                                            child: const Icon(
                                              LucideIcons.search,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selectedCustomer != null) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    height: _fieldHeight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppTheme.borderLight,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          LucideIcons.circleDollarSign,
                                          size: 14,
                                          color: Color(0xFF10B981),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _resolveCustomerCurrencyLabel(
                                            selectedCustomer,
                                          ),
                                          style: AppTheme.textPrimaryStyle(
                                            12,
                                            FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (selectedCustomer != null) ...[
                              const Spacer(),
                              SlidingCustomerDetailsCard(
                                customer: selectedCustomer,
                                builder: _buildCustomerDetailsCard,
                              ),
                            ],
                          ],
                        ),
                        if (selectedCustomer != null) ...[
                          const SizedBox(height: 12),
                          _buildSelectedCustomerInfo(selectedCustomer),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Customer Name*'),
                  ),
                ),
                Expanded(
                  child: Skeleton(height: _fieldHeight, width: _wideFieldWidth),
                ),
              ],
            ),
            error: (error, _) => Text(
              'Unable to load customers',
              style: AppTheme.bodyText.copyWith(color: AppTheme.errorRed),
            ),
          ),
          customersAsync.when(
            data: (customers) {
              final selectedCustomer = _selectedCustomer(customers);
              if (selectedCustomer == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildPlaceOfSupplyField(selectedCustomer),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(
    AsyncValue<List<PriceList>> priceListsAsync,
    List<String> seriesList,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        children: [
          _buildFormRow(
            label: 'Quote#',
            required: true,
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: _fieldWidth,
                  child: FormDropdown<String>(
                    value: seriesList.contains(_selectedSeries) ? _selectedSeries : (seriesList.isNotEmpty ? seriesList.first : null),
                    items: seriesList,
                    height: _fieldHeight,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSeries = value);
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: CustomTextField(
                    controller: _quoteNumberCtrl,
                    height: _fieldHeight,
                    contentCase: ContentCase.none,
                    suffixWidget: ZTooltip(
                      message:
                          'Click here to enable or disable auto-generation of Quote numbers.',
                      direction: ZTooltipDirection.top,
                      child: InkWell(
                        onTap: _showQuoteNumberPreferencesDialog,
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            LucideIcons.settings,
                            size: 16,
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
          _buildFormRow(
            label: 'Reference#',
            child: SizedBox(
              width: _fieldWidth,
              child: CustomTextField(
                controller: _referenceCtrl,
                height: _fieldHeight,
                contentCase: ContentCase.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFormRow(
            label: 'Quote Date',
            required: true,
            child: Wrap(
              spacing: 32,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ZohoDateField(
                  fieldKey: _quoteDateKey,
                  layerLink: _quoteDateLink,
                  width: _fieldWidth,
                  text: DateFormat('dd-MM-yyyy').format(_quoteDate),
                  onTap: _pickQuoteDate,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Expiry Date',
                        style: AppTheme.bodyText.copyWith(fontSize: 13),
                      ),
                    ),
                    _ZohoDateField(
                      fieldKey: _expiryDateKey,
                      layerLink: _expiryDateLink,
                      width: _fieldWidth,
                      text: DateFormat('dd-MM-yyyy').format(_expiryDate!),
                      onTap: _pickExpiryDate,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildThinRule(),
          const SizedBox(height: 18),
          _buildFormRow(
            label: 'Salesperson',
            child: SizedBox(
              width: _fieldWidth,
              child: Consumer(
                builder: (context, ref, child) {
                  final salespersonsAsync = ref.watch(salesQuotationSalespersonsProvider);
                  final salespersons = salespersonsAsync.valueOrNull ?? const <SalespersonOption>[];
                  final validValue = salespersons.any((s) => s.id == _selectedSalesperson)
                      ? _selectedSalesperson
                      : null;
                  
                  return FormDropdown<String>(
                    value: validValue,
                    items: salespersons.map((s) => s.id).toList(),
                    height: _fieldHeight,
                    allowClear: true,
                    alwaysShowClear: true,
                    showClearDivider: true,
                    displayStringForValue: (id) {
                      for (final person in salespersons) {
                        if (person.id == id) {
                          return person.name;
                        }
                      }
                      return id;
                    },
                    onChanged: (value) => setState(() => _selectedSalesperson = value),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),
          _buildThinRule(),
        ],
      ),
    );
  }

  Widget _buildSubjectSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: _buildFormRow(
        label: 'Subject',
        trailingLabelIcon: const ZTooltip(
          message:
              'You can enter up to 250 characters. If you do not require this field, you can mark it as inactive under quote preferences.',
          direction: ZTooltipDirection.top,
          child: Icon(
            LucideIcons.helpCircle,
            size: 15,
            color: Color(0xFF8B8FA3),
          ),
        ),
        child: SizedBox(
          width: _fieldWidth,
          child: CustomTextField(
            controller: _subjectCtrl,
            height: _fieldHeight,
            hintText: 'Let your customer know what this Quote is for',
            contentCase: ContentCase.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceListRow(AsyncValue<List<PriceList>> priceListsAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 18, 14),
      child: Row(
        children: [
          const Icon(
            LucideIcons.clipboardList,
            size: 17,
            color: Color(0xFF7C8598),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 170,
            child: priceListsAsync.when(
              data: (priceLists) {
                final validValue = priceLists.any(
                  (priceList) => priceList.id == _selectedPriceListId,
                )
                    ? _selectedPriceListId
                    : null;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: validValue != null
                        ? Border.all(color: const Color(0xFFBFDBFE), width: 1)
                        : null,
                    boxShadow: validValue != null
                        ? const [
                            BoxShadow(
                              color: Color(0x1A3B82F6),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: FormDropdown<String>(
                    value: validValue,
                    items: priceLists.map((priceList) => priceList.id).toList(),
                    hint: 'Select Price List',
                    height: _smallFieldHeight,
                    allowClear: true,
                    alwaysShowClear: true,
                    showClearDivider: true,
                    hideBorderDefault: true,
                    fillColor: Colors.white,
                    border: Border.all(color: Colors.transparent),
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    displayStringForValue: (id) {
                      for (final priceList in priceLists) {
                        if (priceList.id == id) {
                          return priceList.name;
                        }
                      }
                      return id;
                    },
                    onChanged: (value) {
                      setState(() {
                        _selectedPriceListId = value;
                        for (final row in _rows) {
                          row.priceListId = value;
                        }
                      });
                      final customers = ref
                          .read(salesCustomersProvider)
                          .valueOrNull;
                      if (customers != null) {
                        _syncAllRowRatesFromCustomer(customers);
                      }
                    },
                  ),
                );
              },
              loading: () =>
                  const Skeleton(height: _smallFieldHeight, width: 170),
              error: (error, _) => Text(
                'Select Price List',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(List<Item> items, List<TaxOption> activeTaxes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Align(
        alignment: Alignment.centerLeft,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double minTableWidth = 1120.0;
            final double availableWidth = constraints.maxWidth;
            final bool needsScroll = availableWidth < minTableWidth;

            Widget child = SizedBox(
              width: minTableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 60,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 60),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                              child: Row(
                                children: [
                                  Text(
                                    'Item Table',
                                    style: AppTheme.textPrimaryStyle(14, FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  if (!_showBulkUpdateToolbar)
                                    CompositedTransformTarget(
                                      link: _bulkActionsLink,
                                      child: TextButton.icon(
                                        onPressed: _toggleBulkActionsMenu,
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.primaryBlue,
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        icon: const Icon(
                                          LucideIcons.checkCircle2,
                                          size: 16,
                                        ),
                                        label: const Text('Bulk Actions'),
                                      ),
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(LucideIcons.x, size: 16),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: AppTheme.primaryBlue,
                                      onPressed: () {
                                        setState(() {
                                          _showBulkUpdateToolbar = false;
                                          _selectedRows.clear();
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 60),
                            child: _buildTableHeader(),
                          ),
                          Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _rows.length,
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  int index = newIndex;
                                  if (index > oldIndex) {
                                    index -= 1;
                                  }
                                  final item = _rows.removeAt(oldIndex);
                                  _rows.insert(index, item);
                                });
                              },
                              itemBuilder: (context, index) {
                                final row = _rows[index];
                                return _buildItemRow(
                                  index,
                                  row,
                                  items,
                                  activeTaxes,
                                  key: ValueKey(row),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );

            if (needsScroll) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: child,
              );
            }
            return child;
          },
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFE),
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
          left: BorderSide(color: AppTheme.borderLight),
          right: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: const SizedBox(height: 42),
          ),
          Expanded(
            flex: 40,
            child: _buildTableHeaderCell(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              showRightBorder: true,
              child: const Text('ITEM DETAILS', style: _tableHeaderStyle),
            ),
          ),
          Expanded(
            flex: 11,
            child: _buildTableHeaderCell(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              showRightBorder: true,
              child: const Text('QUANTITY', style: _tableHeaderStyle),
            ),
          ),
          Expanded(
            flex: 13,
            child: _buildTableHeaderCell(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              showRightBorder: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('RATE', style: _tableHeaderStyle),
                  SizedBox(width: 5),
                  ZTooltip(
                    message:
                        'You can perform basic calculations directly in this field using parentheses ( ) and arithmetic operators: + - / *',
                    direction: ZTooltipDirection.top,
                    child: Icon(
                      LucideIcons.calculator,
                      size: 12,
                      color: Color(0xFF2F3441),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: _buildTableHeaderCell(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              showRightBorder: true,
              child: const Text('DISCOUNT', style: _tableHeaderStyle),
            ),
          ),
          Expanded(
            flex: 15,
            child: _buildTableHeaderCell(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              showRightBorder: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('TAX', style: _tableHeaderStyle),
                  SizedBox(width: 4),
                  ZTooltip(
                    message:
                        'Tax can only be applied to an item after choosing a customer. Please select a customer from the Customer Name drop-down.',
                    direction: ZTooltipDirection.top,
                    child: Icon(
                      LucideIcons.helpCircle,
                      size: 14,
                      color: Color(0xFFA2A8B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: _buildTableHeaderCell(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Text('AMOUNT', style: _tableHeaderStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell({
    required Widget child,
    required Alignment alignment,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8),
    bool showRightBorder = false,
  }) {
    return Container(
      height: 42,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        border: showRightBorder
            ? const Border(
                right: BorderSide(color: AppTheme.borderLight),
              )
            : null,
      ),
      child: child,
    );
  }

  // Widget _buildDiscountTypeToggle(SalesOrderItemRow row) {
  //   final isPercent = row.discountType == '%';
  //   return Container(
  //     height: 54,
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(6),
  //       border: Border.all(color: AppTheme.borderLight),
  //       color: Colors.white,
  //     ),
  //     child: Column(
  //       children: [
  //         Expanded(
  //           child: _buildDiscountTypeOption(
  //             label: '%',
  //             selected: isPercent,
  //             onTap: () {
  //               setState(() => row.discountType = '%');
  //               _calculateTotals();
  //             },
  //           ),
  //         ),
  //         Container(height: 1, color: AppTheme.borderLight),
  //         Expanded(
  //           child: _buildDiscountTypeOption(
  //             label: '₹',
  //             selected: !isPercent,
  //             onTap: () {
  //               setState(() => row.discountType = 'Value');
  //               _calculateTotals();
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildDiscountTypeOption({
  //   required String label,
  //   required bool selected,
  //   required VoidCallback onTap,
  // }) {
  //   return Material(
  //     color: Colors.transparent,
  //     child: InkWell(
  //       onTap: onTap,
  //       borderRadius: BorderRadius.circular(5),
  //       child: Container(
  //         margin: const EdgeInsets.all(3),
  //         decoration: BoxDecoration(
  //           color: selected ? AppTheme.primaryBlue : Colors.transparent,
  //           borderRadius: BorderRadius.circular(4),
  //         ),
  //         alignment: Alignment.center,
  //         child: Text(
  //           label,
  //           style: TextStyle(
  //             fontSize: 12,
  //             fontWeight: FontWeight.w600,
  //             color: selected ? Colors.white : AppTheme.textPrimary,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildReportingTagsBar(SalesOrderItemRow row) {
    return CompositedTransformTarget(
      link: row.reportingTagsLink,
      child: InkWell(
        onTap: () => _toggleReportingTagsOverlay(row.reportingTagsLink),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: AppTheme.borderLight),
              right: BorderSide(color: AppTheme.borderLight),
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.tag,
                size: 15,
                color: Color(0xFF7B8794),
              ),
              const SizedBox(width: 10),
              Text(
                'Reporting Tags',
                style: AppTheme.bodyText.copyWith(fontSize: 13),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: Color(0xFF7B8794),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, SalesOrderItemRow row, List<Item> items, List<TaxOption> activeTaxes, {Key? key}) {
    if (row.isHeader) {
      final isHovered = _hoveredRowIndex == index;
      return MouseRegion(
        key: key,
        onEnter: (_) => setState(() => _hoveredRowIndex = index),
        onExit: (_) {
          if (_rowActionsOverlay == null && _hoveredRowIndex == index) {
            setState(() => _hoveredRowIndex = null);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: AppTheme.borderLight),
                    right: BorderSide(color: AppTheme.borderLight),
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
                height: 40,
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: SizedBox(
                        width: 26,
                        child: Icon(
                          Icons.drag_indicator,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: row.descriptionCtrl,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Type a header...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 60,
              height: 40,
              alignment: Alignment.center,
              child: isHovered
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _removeItemRow(index),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFFECDCA)),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Color(0xFFFDA29B),
                        ),
                      ),
                    )
                  : const SizedBox(height: 40),
            ),
          ],
        ),
      );
    }
    final amount = _rowAmount(row);
    Item? selectedItem = row.item;
    if (selectedItem == null && row.itemId.trim().isNotEmpty) {
      for (final item in items) {
        if ((item.id ?? '').trim() == row.itemId.trim()) {
          selectedItem = item;
          row.item = item;
          break;
        }
      }
    }
    selectedItem ??= row.itemId.trim().isNotEmpty
        ? Item(
            id: row.itemId,
            productName: row.descriptionCtrl.text.trim().isNotEmpty
                ? row.descriptionCtrl.text.trim()
                : '-',
            sellingPrice: _getParsedRate(row),
            salesDescription: row.descriptionCtrl.text.trim(),
            hsnCode: row.hsnCode,
            type: 'goods',
            itemCode: row.itemId,
            unitId: '',
          )
        : null;
    final isSelected = selectedItem != null;
    final showAdditional = isSelected && row.showAdditionalInfo;
    final rowHeight = showAdditional ? 124.0 : 58.0;
    final customers = ref.watch(salesCustomersProvider).valueOrNull;
    final selectedCustomer =
        customers == null ? null : _selectedCustomer(customers);
    final priceLists = ref.watch(salesQuotationPriceListsProvider).valueOrNull;
    final targetPriceListId = _resolvedRowPriceListId(row, selectedCustomer);
    PriceList? selectedPriceList;
    if (priceLists != null) {
      for (final priceList in priceLists) {
        if (priceList.id == targetPriceListId) {
          selectedPriceList = priceList;
          break;
        }
      }
    }
    final bool priceListItemMissing =
        selectedPriceList != null &&
        row.itemId.isNotEmpty &&
        !_priceListIncludesItem(
          selectedPriceList,
          row.itemId,
          productName: selectedItem?.productName,
        );
    const taxGroupHeadingId = '__tax_group_heading__';
    const outOfScopeTaxId = 'Out of Scope';
    const nonGstSupplyTaxId = 'Non-GST Supply';
    final taxDropdownItems = <String>[
      'Non-Taxable',
      outOfScopeTaxId,
      nonGstSupplyTaxId,
      if (activeTaxes.isNotEmpty) taxGroupHeadingId,
      ...activeTaxes.map((t) => t.id),
    ];

    final isHovered = _hoveredRowIndex == index;

    return Row(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── table row content ──────────────────────────────────────────
        Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredRowIndex = index),
            onExit: (_) {
              if (_rowActionsOverlay == null && _hoveredRowIndex == index) {
                setState(() => _hoveredRowIndex = null);
              }
            },
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isHovered ? const Color(0xFFF9FAFB) : Colors.white,
                    border: const Border(
                      left: BorderSide(color: AppTheme.borderLight),
                      right: BorderSide(color: AppTheme.borderLight),
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: SizedBox(
                      width: 26,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Icon(
                          Icons.drag_indicator,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 40,
                    child: Container(
                      height: rowHeight,
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: AppTheme.borderLight)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              width: 34,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppTheme.bgDisabled,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: const Icon(
                                LucideIcons.image,
                                size: 16,
                                color: Color(0xFFB5BAC7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: isSelected
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              selectedItem.productName,
                                              style: AppTheme.textPrimaryStyle(
                                                13,
                                                FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          CompositedTransformTarget(
                                            link: row.itemActionsLink,
                                            child: InkWell(
                                              onTap: () => _toggleItemActionsOverlay(row),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(0xFFB8BFCC),
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.more_horiz,
                                                  size: 10,
                                                  color: Color(0xFFB8BFCC),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                row.itemId = '';
                                                row.item = null;
                                                row.hsnCode = null;
                                                row.descriptionCtrl.clear();
                                                row.priceListId = null;
                                                row.rateCtrl.text = '0.00';
                                                row.discountCtrl.text = '0';
                                                row.taxId = 'Non-Taxable';
                                              });
                                              _calculateTotals();
                                            },
                                            child: const Icon(
                                              LucideIcons.xCircle,
                                              size: 14,
                                              color: Color(0xFFB8BFCC),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (row.showAdditionalInfo) ...[
                                        const SizedBox(height: 4),
                                        CustomTextField(
                                          controller: row.descriptionCtrl,
                                          height: 36,
                                          contentCase: ContentCase.none,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryBlue,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                              child: Text(
                                                selectedItem.type == 'service'
                                                    ? 'SERVICE'
                                                    : 'GOODS',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              selectedItem.type == 'service'
                                                  ? 'SAC Code: '
                                                  : 'HSN Code: ',
                                              style: AppTheme.bodyText.copyWith(
                                                fontSize: 12,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            CompositedTransformTarget(
                                              link: row.hsnLink,
                                              child: GestureDetector(
                                                onTap: () => _toggleHsnOverlay(row),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      row.hsnCode ?? '—',
                                                      style: AppTheme.textPrimaryStyle(
                                                        12,
                                                        FontWeight.w600,
                                                      ).copyWith(color: AppTheme.primaryBlue),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      LucideIcons.pencil,
                                                      size: 11,
                                                      color: AppTheme.primaryBlue,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: FormDropdown<String>(
                                      value: row.itemId.isEmpty ? null : row.itemId,
                                      items: items
                                          .where((item) => item.id != null)
                                          .map((item) => item.id!)
                                          .toList(),
                                      hint: 'Type or click to select an item.',
                                      height: 30,
                                      itemEstimatedHeight: 52,
                                      hideBorderDefault: true,
                                      fillColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(horizontal: 0),
                                      displayStringForValue: (id) {
                                        for (final item in items) {
                                          if (item.id == id) {
                                            return item.productName;
                                          }
                                        }
                                        return id;
                                      },
                                      itemBuilder: (id, isSelected, isHovered) {
                                        final matchedItem = items
                                            .cast<dynamic>()
                                            .firstWhere(
                                              (item) => item.id == id,
                                              orElse: () => null,
                                            );
                                        final rateValue =
                                            matchedItem?.sellingPrice is num
                                                ? (matchedItem!.sellingPrice as num)
                                                    .toDouble()
                                                : 0.0;
                                        final foregroundColor = isHovered
                                            ? Colors.white
                                            : AppTheme.textPrimary;
                                        final secondaryColor = isHovered
                                            ? Colors.white
                                            : AppTheme.textSecondary;

                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          color: Colors.transparent,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                matchedItem?.productName ?? id,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                  color: foregroundColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Rate: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(rateValue)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: secondaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      onChanged: (value) {
                                        if (value == null) {
                                          return;
                                        }
                                        for (final item in items) {
                                          if (item.id == value) {
                                            final wasEmptyRow =
                                                row.item == null &&
                                                row.itemId.trim().isEmpty;
                                            setState(() {
                                              row.itemId = value;
                                              row.item = item;
                                              row.warehouseId ??= _selectedWarehouseId;
                                              row.descriptionCtrl.text =
                                                  item.salesDescription
                                                              ?.trim()
                                                              .isNotEmpty ==
                                                          true
                                                      ? item.salesDescription!.trim()
                                                      : 'sales description demo txt';
                                              row.hsnCode = item.hsnCode ?? '30049084';
                                              row.rateCtrl.text = (item.sellingPrice ?? 0)
                                                  .toStringAsFixed(2);
                                              if (wasEmptyRow &&
                                                  !_hasEmptyItemRow(
                                                    excludingRow: row,
                                                  )) {
                                                final newRow = SalesOrderItemRow(
                                                  quantityCtrl:
                                                      TextEditingController(
                                                    text: '1',
                                                  ),
                                                  rateCtrl:
                                                      TextEditingController(
                                                    text: '0.00',
                                                  ),
                                                  discountCtrl:
                                                      TextEditingController(
                                                    text: '0',
                                                  ),
                                                  discountType: '%',
                                                  taxId: 'Non-Taxable',
                                                );
                                                _setupRowListeners(newRow);
                                                _rows.add(newRow);
                                              }
                                            });
                                            _syncRowRateFromCustomer(row);
                                            _calculateTotals();
                                            return;
                                          }
                                        }
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 11,
                    child: _buildQuantityColumn(
                      row,
                      height: rowHeight,
                      edge: _tableCellEdge,
                    ),
                  ),
                  Expanded(
                    flex: 13,
                    child: Container(
                      height: rowHeight,
                      decoration: BoxDecoration(border: _tableCellEdge),
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _tableNumberInput(
                            row.rateCtrl,
                            textAlign: TextAlign.center,
                            focusNode: row.rateFocus,
                            keyboardType: TextInputType.text,
                            onTap: () => row.rateCtrl.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: row.rateCtrl.text.length,
                            ),
                            onSubmitted: (_) => _handleRateCalculation(row),
                          ),
                          if (showAdditional) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 30,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (priceListItemMissing) ...[
                                    ZTooltip(
                                      message:
                                          "This item has not been included in the selected price list. So, the item's default rate has been used.",
                                      direction: ZTooltipDirection.bottom,
                                      child: const Icon(
                                        LucideIcons.alertCircle,
                                        size: 16,
                                        color: AppTheme.warningOrange,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        border: selectedPriceList != null
                                            ? Border.all(
                                                color: const Color(0xFFBFDBFE),
                                                width: 1,
                                              )
                                            : null,
                                        boxShadow: selectedPriceList != null
                                            ? const [
                                                BoxShadow(
                                                  color: Color(0x1A3B82F6),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: FormDropdown<String>(
                                        value: selectedPriceList?.id,
                                        items: priceLists
                                                ?.map((priceList) => priceList.id)
                                                .toList() ??
                                            const <String>[],
                                        hint: 'Apply Price List',
                                        allowClear: true,
                                        alwaysShowClear: true,
                                        showClearDivider: true,
                                        hideBorderDefault: true,
                                        fillColor: Colors.white,
                                        border: Border.all(
                                          color: Colors.transparent,
                                        ),
                                        padding: const EdgeInsets.only(
                                          left: 8,
                                          right: 4,
                                        ),
                                        displayStringForValue: (id) {
                                          if (priceLists == null) {
                                            return id;
                                          }
                                          for (final priceList in priceLists) {
                                            if (priceList.id == id) {
                                              return priceList.name;
                                            }
                                          }
                                          return id;
                                        },
                                        onChanged: (value) {
                                          setState(() {
                                            row.priceListId = value ?? '';
                                            if (value == null || value.isEmpty) {
                                              row.rateCtrl.text = ((selectedItem?.sellingPrice ?? 0)
                                                      .toDouble())
                                                  .toStringAsFixed(2);
                                            }
                                          });
                                          _syncRowRateFromCustomer(row);
                                          _calculateTotals();
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _showItemDetailsSidebar(row, initialTabIndex: 2),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                child: Text(
                                  'Recent Transactions',
                                  style: AppTheme.textPrimaryStyle(
                                    11,
                                    FontWeight.w500,
                                  ).copyWith(
                                    color: AppTheme.primaryBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 12,
                    child: Container(
                      height: rowHeight,
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: AppTheme.borderLight)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _tableNumberInput(
                                row.discountCtrl,
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 42,
                              child: FormDropdown<String>(
                                value: row.discountType == '%' ? '%' : '₹',
                                items: const <String>['%', '₹'],
                                height: 30,
                                showSearch: false,
                                menuWidth: 70,
                                hideBorderDefault: true,
                                fillColor: Colors.transparent,
                                textAlign: TextAlign.center,
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                onChanged: (value) {
                                  setState(
                                    () => row.discountType =
                                        value == '₹' ? 'Value' : '%',
                                  );
                                  _calculateTotals();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 15,
                    child: Container(
                      height: rowHeight,
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: AppTheme.borderLight)),
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                          child: FormDropdown<String>(
                            value: taxDropdownItems.contains(row.taxId)
                                ? row.taxId
                                : 'Non-Taxable',
                            items: taxDropdownItems,
                            hint: 'Non-Taxable',
                            height: 28,
                            hideBorderDefault: true,
                            fillColor: Colors.transparent,
                            border: Border.all(color: Colors.transparent),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemEstimatedHeight: 46,
                            isItemEnabled: (id) => id != taxGroupHeadingId,
                            displayStringForValue: (id) {
                              if (id == taxGroupHeadingId) return 'Tax Group';
                              if (id == outOfScopeTaxId) return outOfScopeTaxId;
                              if (id == nonGstSupplyTaxId) return nonGstSupplyTaxId;
                              if (id == 'Non-Taxable') return 'Non-Taxable';
                              for (final tax in activeTaxes) {
                                if (tax.id == id) return tax.name;
                              }
                              return id;
                            },
                            itemBuilder: (id, isSelected, isHovered) {
                              if (id == taxGroupHeadingId) {
                                return const Padding(
                                  padding: EdgeInsets.fromLTRB(12, 8, 12, 6),
                                  child: Text(
                                    'Tax Group',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                );
                              }

                              String title = id;
                              String? subtitle;
                              if (id == 'Non-Taxable') {
                                title = 'Non-Taxable';
                              } else if (id == outOfScopeTaxId) {
                                title = 'Out of Scope';
                                subtitle =
                                    "Supplies on which you don't charge any GST or include them in the returns.";
                              } else if (id == nonGstSupplyTaxId) {
                                title = 'Non-GST Supply';
                                subtitle =
                                    'Supplies which do not come under GST such as petroleum products and liquor.';
                              } else {
                                final matchedTax = activeTaxes.cast<TaxOption?>().firstWhere(
                                  (tax) => tax?.id == id,
                                  orElse: () => null,
                                );
                                title = matchedTax?.name ?? id;
                              }

                              final titleColor = isHovered
                                  ? Colors.white
                                  : AppTheme.textPrimary;
                              final subtitleColor = isHovered
                                  ? Colors.white
                                  : AppTheme.textSecondary;

                              return Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: titleColor,
                                      ),
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          height: 1.25,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                            onChanged: (value) {
                              setState(() => row.taxId = value ?? 'Non-Taxable');
                              _calculateTotals();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 12,
                    child: Container(
                      height: rowHeight,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 12, top: 12),
                      child: Text(
                        amount.toStringAsFixed(2),
                        style: AppTheme.textPrimaryStyle(13, FontWeight.w700),
                      ),
                    ),
                  ),
                    ],
                  ),
                ),
                if (row.showAdditionalInfo) _buildReportingTagsBar(row),
              ],
            ),
          ),
        ),
        // ── 60 px side zone — keeps hover alive + holds action buttons ──
        MouseRegion(
          onEnter: (_) => setState(() => _hoveredRowIndex = index),
          onExit: (_) {
            if (_rowActionsOverlay == null && _hoveredRowIndex == index) {
              setState(() => _hoveredRowIndex = null);
            }
          },
          child: SizedBox(
            width: 60,
            height: 46,
            child: isHovered
                ? Padding(
                    padding: const EdgeInsets.only(left: 6, top: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CompositedTransformTarget(
                          link: row.moreActionsLink,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _toggleRowActionsOverlay(row, items),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: const Icon(
                                Icons.more_horiz,
                                size: 14,
                                color: Color(0xFF98A2B3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _removeItemRow(index),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFFECDCA)),
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              size: 13,
                              color: Color(0xFFF04438),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsOverlayItem({
    required String label,
    required bool showHighlight,
    required ValueChanged<bool> onHover,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onHover: onHover,
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: showHighlight ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: showHighlight ? Colors.white : const Color(0xFF7B8794),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: showHighlight ? FontWeight.w600 : FontWeight.w500,
                color: showHighlight ? Colors.white : const Color(0xFF111827).withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleItemActionsOverlay(SalesOrderItemRow row) {
    if (_itemActionsOverlay != null) {
      _itemActionsOverlay?.remove();
      _itemActionsOverlay = null;
      setState(() {});
      return;
    }

    String? hoveredItem;
    _itemActionsOverlay = ZAdaptiveMenu.show(
      context: context,
      link: row.itemActionsLink,
      width: 170,
      alignLeft: true,
      onClose: () {
        _itemActionsOverlay?.remove();
        _itemActionsOverlay = null;
        setState(() {});
      },
      builder: (context) => StatefulBuilder(
        builder: (context, setOverlayState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingsOverlayItem(
                label: 'Edit Item',
                icon: LucideIcons.pencil,
                showHighlight: hoveredItem == 'edit',
                onHover: (v) => setOverlayState(
                  () => hoveredItem = v ? 'edit' : null,
                ),
                onTap: () {
                  _itemActionsOverlay?.remove();
                  _itemActionsOverlay = null;
                  setState(() {});
                  if (row.item != null) {
                    showDialog(
                      context: context,
                      builder: (ctx) => SalesItemQuickEditDialog(
                        item: row.item!,
                        onUpdated: (newItem) {
                          setState(() {
                            row.item = newItem;
                            row.rateCtrl.text =
                                newItem.sellingPrice?.toStringAsFixed(2) ?? '0.00';
                            if (newItem.salesDescription != null) {
                              row.descriptionCtrl.text = newItem.salesDescription!;
                            }
                          });
                          _syncRowRateFromCustomer(row);
                          _calculateTotals();
                        },
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 4),
              _buildSettingsOverlayItem(
                label: 'View Item Details',
                icon: LucideIcons.shoppingBag,
                showHighlight: hoveredItem == 'view',
                onHover: (v) => setOverlayState(
                  () => hoveredItem = v ? 'view' : null,
                ),
                onTap: () {
                  _itemActionsOverlay?.remove();
                  _itemActionsOverlay = null;
                  setState(() {});
                  _showItemDetailsSidebar(row);
                },
              ),
            ],
          );
        },
      ),
    );
    setState(() {});
  }

  void _showItemDetailsSidebar(
    SalesOrderItemRow row, {
    int initialTabIndex = 0,
  }) {
    if (row.itemId.isNotEmpty) {
      POItemDetailsSidebar.show(
        context,
        PurchaseOrderItem(
          productId: row.itemId,
          productName: row.item?.productName ?? '',
          itemCode: row.item?.itemCode,
          productType: row.item?.type ?? 'goods',
          rate: _getParsedRate(row),
          quantity: double.tryParse(row.quantityCtrl.text) ?? 0.0,
          amount: _getParsedRate(row) * (double.tryParse(row.quantityCtrl.text) ?? 0.0),
          accountName: row.accountName,
        ),
        initialTabIndex: initialTabIndex,
      );
    }
  }

  void _toggleRowActionsOverlay(SalesOrderItemRow row, List<Item>? products) {
    if (_rowActionsOverlay != null) {
      _rowActionsOverlay?.remove();
      _rowActionsOverlay = null;
      setState(() => _hoveredRowIndex = null);
      return;
    }

    String? hoveredItem;
    _rowActionsOverlay = ZAdaptiveMenu.show(
      context: context,
      link: row.moreActionsLink,
      width: 220,
      alignLeft: false,
      onClose: () {
        _rowActionsOverlay?.remove();
        _rowActionsOverlay = null;
        setState(() => _hoveredRowIndex = null);
      },
      builder: (context) => StatefulBuilder(
        builder: (context, setOverlayState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingsOverlayItem(
                label: row.showAdditionalInfo
                    ? 'Hide Additional Information'
                    : 'Show Additional Information',
                showHighlight: hoveredItem == 'additional',
                onHover: (v) => setOverlayState(
                  () => hoveredItem = v ? 'additional' : null,
                ),
                onTap: () {
                  setState(() => row.showAdditionalInfo = !row.showAdditionalInfo);
                  _rowActionsOverlay?.remove();
                  _rowActionsOverlay = null;
                  setState(() {});
                },
              ),
              const SizedBox(height: 4),
              _buildSettingsOverlayItem(
                label: 'Clone',
                showHighlight: hoveredItem == 'clone',
                onHover: (v) => setOverlayState(
                  () => hoveredItem = v ? 'clone' : null,
                ),
                onTap: () {
                  final idx = _rows.indexOf(row);
                  if (idx != -1) {
                    setState(() {
                      final newRow = SalesOrderItemRow(
                        quantityCtrl: TextEditingController(text: row.quantityCtrl.text),
                        rateCtrl: TextEditingController(text: row.rateCtrl.text),
                        discountCtrl: TextEditingController(text: row.discountCtrl.text),
                        descriptionCtrl: TextEditingController(text: row.descriptionCtrl.text),
                        itemId: row.itemId,
                        item: row.item,
                        discountType: row.discountType,
                        taxId: row.taxId,
                        showAdditionalInfo: row.showAdditionalInfo,
                      );
                      newRow.hsnCode = row.hsnCode;
                      _setupRowListeners(newRow);
                      _rows.insert(idx + 1, newRow);
                    });
                    _calculateTotals();
                  }
                  _rowActionsOverlay?.remove();
                  _rowActionsOverlay = null;
                },
              ),
              const Divider(height: 17, color: Color(0xFFE5E7EB)),
              _buildSettingsOverlayItem(
                label: 'Insert New Row',
                showHighlight: hoveredItem == 'insert',
                onHover: (v) => setOverlayState(
                  () => hoveredItem = v ? 'insert' : null,
                ),
                onTap: () {
                  final idx = _rows.indexOf(row);
                  if (idx != -1) {
                    setState(() {
                      final newRow = SalesOrderItemRow(
                        quantityCtrl: TextEditingController(text: '1'),
                        rateCtrl: TextEditingController(text: '0.00'),
                        discountCtrl: TextEditingController(text: '0'),
                      );
                      _setupRowListeners(newRow);
                      _rows.insert(idx + 1, newRow);
                    });
                  }
                  _rowActionsOverlay?.remove();
                  _rowActionsOverlay = null;
                },
              ),
              const SizedBox(height: 4),
              _buildSettingsOverlayItem(
                label: 'Insert Items in Bulk',
                showHighlight: hoveredItem == 'bulk',
                onHover: (v) => setOverlayState(
                  () => hoveredItem = v ? 'bulk' : null,
                ),
                onTap: () {
                  _rowActionsOverlay?.remove();
                  _rowActionsOverlay = null;
                  if (products == null) return;
                  showDialog(
                    context: context,
                    builder: (context) => BulkItemsDialog(
                      products: products,
                      onItemsSelected: (selectedItems) {
                        setState(() {
                          int insertIdx = _rows.indexOf(row) + 1;
                          selectedItems.forEach((item, quantity) {
                            final newRow = SalesOrderItemRow(
                              quantityCtrl: TextEditingController(text: quantity.toString()),
                              rateCtrl: TextEditingController(
                                text: (item.sellingPrice ?? 0) == 0
                                    ? '0.00'
                                    : (item.sellingPrice ?? 0).toStringAsFixed(2),
                              ),
                              discountCtrl: TextEditingController(text: '0'),
                              itemId: item.id ?? '',
                              item: item,
                            );
                            _setupRowListeners(newRow);
                            _rows.insert(insertIdx, newRow);
                            insertIdx++;
                          });
                          _calculateTotals();
                        });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              _buildSettingsOverlayItem(
                label: 'Insert New Header',
                showHighlight: hoveredItem == 'header',
                onHover: (v) => setOverlayState(
                  () => hoveredItem = v ? 'header' : null,
                ),
                onTap: () {
                  final idx = _rows.indexOf(row);
                  if (idx != -1) {
                    setState(() {
                      _rows.insert(
                        idx + 1,
                        SalesOrderItemRow(
                          quantityCtrl: TextEditingController(text: '0'),
                          rateCtrl: TextEditingController(text: '0.00'),
                          discountCtrl: TextEditingController(text: '0'),
                          isHeader: true,
                        ),
                      );
                    });
                  }
                  _rowActionsOverlay?.remove();
                  _rowActionsOverlay = null;
                },
              ),
            ],
          );
        },
      ),
    );
    setState(() {});
  }

  // Widget _tableNumberField(
  //   TextEditingController controller, {
  //   BoxBorder? edge,
  //   TextAlign textAlign = TextAlign.right,
  //   double height = 58,
  //   bool alignTop = false,
  //   String? footerText,
  // }) {
  //   return Container(
  //     height: height,
  //     decoration: BoxDecoration(border: edge),
  //     padding: EdgeInsets.fromLTRB(8, alignTop ? 6 : 0, 8, 4),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       mainAxisAlignment:
  //           alignTop ? MainAxisAlignment.start : MainAxisAlignment.center,
  //       children: [
  //         _tableNumberInput(
  //           controller,
  //           textAlign: textAlign,
  //         ),
  //         if (footerText != null) ...[
  //           const SizedBox(height: 2),
  //           Text(
  //             footerText,
  //             style: AppTheme.bodyText.copyWith(
  //               fontSize: 11,
  //               color: AppTheme.textPrimary,
  //               height: 1,
  //             ),
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  Widget _tableNumberInput(
    TextEditingController controller, {
    TextAlign textAlign = TextAlign.right,
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onTap,
    TextInputType keyboardType = const TextInputType.numberWithOptions(decimal: true),
  }) {
    return CustomTextField(
      controller: controller,
      focusNode: focusNode,
      height: 30,
      keyboardType: keyboardType,
      textAlign: textAlign,
      contentCase: ContentCase.none,
      hideBorderDefault: true,
      fillColor: Colors.transparent,
      onSubmitted: onSubmitted,
      onTap: onTap,
    );
  }

  Widget _buildNotesAndSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: _lowerContentWidth,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final notes = _buildLowerLeftColumn();
              final summary = _buildSummaryCard();

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    notes,
                    const SizedBox(height: 16),
                    summary,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: notes),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 560,
                    child: summary,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLowerLeftColumn() {
    return SizedBox(
      height: 306,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CompositedTransformTarget(
                link: _addRowLink,
                child: _ActionChip(
                  label: 'Add New Row',
                  icon: LucideIcons.plusCircle,
                  trailingIcon: Icons.arrow_drop_down,
                  onTap: _addItemRow,
                  onTrailingTap: _toggleAddRowOverlay,
                ),
              ),
              _ActionChip(
                label: 'Add Items in Bulk',
                icon: LucideIcons.plusCircle,
                onTap: _openBulkItemsDialog,
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Customer Notes',
            style: AppTheme.bodyText.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 460,
            child: CustomTextField(
              controller: _customerNotesCtrl,
              height: 52,
              maxLines: 2,
              contentCase: ContentCase.sentence,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog({
    required bool isBilling,
    Map<String, dynamic>? initialAddress,
  }) {
    final customers = ref.read(salesCustomersProvider).valueOrNull ?? const [];
    final selectedCustomer = _selectedCustomer(customers);
    if (selectedCustomer == null) {
      ZerpaiToast.error(
        context,
        'Select a customer before editing the address.',
      );
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Address Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) {
        final c = selectedCustomer;
        final existingAddress = initialAddress ??
            <String, dynamic>{
              'companyName': c.companyName,
              'attention': '',
              'street1': isBilling
                  ? (c.billingAddressStreet1 ?? '')
                  : (c.shippingAddressStreet1 ?? ''),
              'street2': isBilling
                  ? (c.billingAddressStreet2 ?? '')
                  : (c.shippingAddressStreet2 ?? ''),
              'city': isBilling
                  ? (c.billingAddressCity ?? '')
                  : (c.shippingAddressCity ?? ''),
              'zip': isBilling
                  ? (c.billingAddressZip ?? '')
                  : (c.shippingAddressZip ?? ''),
              'phone': isBilling
                  ? (c.billingAddressPhone ?? c.phone ?? '')
                  : (c.shippingAddressPhone ?? c.phone ?? ''),
              'country': isBilling
                  ? (c.billingAddressCountryId ?? '')
                  : (c.shippingAddressCountryId ?? ''),
              'state': isBilling
                  ? (c.billingAddressStateId ?? '')
                  : (c.shippingAddressStateId ?? ''),
              'address_type': isBilling ? 'billing' : 'shipping',
              'is_default_billing': isBilling,
            };

        return AddressDialog(
          title: isBilling ? 'Billing Address' : 'Shipping Address',
          initialAddress: existingAddress,
          onSave: (val) async {
            final street1 = val['street1'] as String?;
            final street2 = val['street2'] as String?;
            final city = val['city'] as String?;
            final state = val['state'] as String?;
            final stateName = val['stateName'] as String?;
            final zip = val['zip'] as String?;
            final country = val['country'] as String?;
            final countryName = val['countryName'] as String?;
            final phone = val['phone'] as String?;

            final countriesList =
                ref.read(countriesProvider(null)).valueOrNull ?? [];
            final billingCountryObj = countriesList.firstWhere(
              (item) =>
                  item['id'] == c.billingAddressCountryId ||
                  item['name']?.toLowerCase() ==
                      c.billingAddressCountryId?.toLowerCase() ||
                  item['shortCode']?.toLowerCase() ==
                      c.billingAddressCountryId?.toLowerCase(),
              orElse: () => <String, String>{},
            );
            final billingCountryUuid =
                billingCountryObj['id'] ?? c.billingAddressCountryId;

            final shippingCountryObj = countriesList.firstWhere(
              (item) =>
                  item['id'] == c.shippingAddressCountryId ||
                  item['name']?.toLowerCase() ==
                      c.shippingAddressCountryId?.toLowerCase() ||
                  item['shortCode']?.toLowerCase() ==
                      c.shippingAddressCountryId?.toLowerCase(),
              orElse: () => <String, String>{},
            );
            final shippingCountryUuid =
                shippingCountryObj['id'] ?? c.shippingAddressCountryId;

            final billingStates =
                (billingCountryUuid != null && billingCountryUuid.isNotEmpty)
                ? (ref.read(statesProvider(billingCountryUuid)).valueOrNull ??
                      [])
                : <Map<String, String>>[];
            final billingStateObj = billingStates.firstWhere(
              (item) =>
                  item['id'] == c.billingAddressStateId ||
                  item['name']?.toLowerCase() ==
                      c.billingAddressStateId?.toLowerCase() ||
                  item['code']?.toLowerCase() ==
                      c.billingAddressStateId?.toLowerCase(),
              orElse: () => <String, String>{},
            );
            final billingStateUuid =
                billingStateObj['id'] ?? c.billingAddressStateId;

            final shippingStates =
                (shippingCountryUuid != null && shippingCountryUuid.isNotEmpty)
                ? (ref.read(statesProvider(shippingCountryUuid)).valueOrNull ??
                      [])
                : <Map<String, String>>[];
            final shippingStateObj = shippingStates.firstWhere(
              (item) =>
                  item['id'] == c.shippingAddressStateId ||
                  item['name']?.toLowerCase() ==
                      c.shippingAddressStateId?.toLowerCase() ||
                  item['code']?.toLowerCase() ==
                      c.shippingAddressStateId?.toLowerCase(),
              orElse: () => <String, String>{},
            );
            final shippingStateUuid =
                shippingStateObj['id'] ?? c.shippingAddressStateId;

            setState(() {
              _selectedCustomerOverride = isBilling
                  ? c.copyWith(
                      billingAddressStreet1: street1,
                      billingAddressStreet2: street2,
                      billingAddressCity: city,
                      billingAddressStateId: stateName,
                      billingAddressZip: zip,
                      billingAddressCountryId: countryName,
                      billingAddressPhone: phone,
                    )
                  : c.copyWith(
                      shippingAddressStreet1: street1,
                      shippingAddressStreet2: street2,
                      shippingAddressCity: city,
                      shippingAddressStateId: stateName,
                      shippingAddressZip: zip,
                      shippingAddressCountryId: countryName,
                      shippingAddressPhone: phone,
                    );
            });

            try {
              final billingAddressPayload = <String, dynamic>{
                'street1': isBilling ? street1 : c.billingAddressStreet1,
                'place': isBilling ? street2 : c.billingAddressStreet2,
                'city': isBilling ? city : c.billingAddressCity,
                'stateId': isBilling ? state : billingStateUuid,
                'zip': isBilling ? zip : c.billingAddressZip,
                'countryId': isBilling ? country : billingCountryUuid,
                'phone': isBilling ? phone : c.billingAddressPhone,
              };

              final shippingAddressPayload = <String, dynamic>{
                'street1': !isBilling ? street1 : c.shippingAddressStreet1,
                'place': !isBilling ? street2 : c.shippingAddressStreet2,
                'city': !isBilling ? city : c.shippingAddressCity,
                'stateId': !isBilling ? state : shippingStateUuid,
                'zip': !isBilling ? zip : c.shippingAddressZip,
                'countryId': !isBilling ? country : shippingCountryUuid,
                'phone': !isBilling ? phone : c.shippingAddressPhone,
              };

              await ref
                  .read(salesOrderControllerProvider.notifier)
                  .updateCustomer(
                    c.id,
                    <String, dynamic>{
                      'billingAddress': billingAddressPayload,
                      'shippingAddress': shippingAddressPayload,
                    },
                  );
              if (mounted) {
                ZerpaiToast.success(context, 'Customer address updated');
              }
            } catch (error) {
              if (mounted) {
                ZerpaiToast.error(
                  context,
                  'Failed to update customer address: $error',
                );
              }
            }
          },
        );
      },
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  void _closeAddressDropdownOverlay() {
    _addressDropdownOverlay?.remove();
    _addressDropdownOverlay = null;
  }

  void _closeGstTaxOverlay() {
    _gstTaxOverlay?.remove();
    _gstTaxOverlay = null;
  }

  void _toggleGstTaxOverlay(String initialGst) {
    final customers = ref.read(salesCustomersProvider).valueOrNull ?? const [];
    final selectedCustomer = _selectedCustomer(customers);
    if (selectedCustomer == null) {
      return;
    }

    if (_gstTaxOverlay != null) {
      _closeGstTaxOverlay();
      setState(() {});
      return;
    }

    _gstTaxOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _closeGstTaxOverlay();
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _gstTaxLink,
            showWhenUnlinked: false,
            offset: const Offset(-333, 20),
            child: Material(
              color: Colors.transparent,
              child: _ConfigureTaxPreferencesDialog(
                initialGst: initialGst,
                initialGstin: selectedCustomer.gstin ?? '',
                onUpdate: (newGst, newGstin, isPermanent) async {
                  setState(() {
                    _selectedCustomerOverride = selectedCustomer.copyWith(
                      gstTreatment: newGst,
                      gstin: newGstin,
                    );
                  });
                  if (isPermanent) {
                    try {
                      await ref
                          .read(salesOrderControllerProvider.notifier)
                          .updateCustomer(
                            selectedCustomer.id,
                            <String, dynamic>{
                              'gstTreatment': newGst,
                              'gstin': newGstin,
                            },
                          );
                      if (context.mounted) {
                        ZerpaiToast.success(
                          context,
                          'Tax preference updated in database',
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ZerpaiToast.error(
                          context,
                          'Failed to update database: $error',
                        );
                      }
                    }
                  }
                  _closeGstTaxOverlay();
                },
                onCancel: () {
                  _closeGstTaxOverlay();
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_gstTaxOverlay!);
    setState(() {});
  }

  Map<String, dynamic> _normalizeAddress(Map<String, dynamic> address) {
    return <String, dynamic>{
      'attention': address['attention']?.toString() ?? '',
      'street1': (address['street1'] ?? address['street'] ?? '').toString(),
      'street2': (address['street2'] ?? address['place'] ?? '').toString(),
      'city': address['city']?.toString() ?? '',
      'state': address['state']?.toString() ?? '',
      'zip': (address['zip'] ?? address['pincode'] ?? '').toString(),
      'country': (address['country'] ??
              address['countryRegion'] ??
              address['country_region'] ??
              '')
          .toString(),
      'phone': address['phone']?.toString() ?? '',
      if (address['id'] != null) 'id': address['id'].toString(),
    };
  }

  bool _areAddressesEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    String norm(dynamic value) =>
        (value?.toString() ?? '').trim().toLowerCase();

    if (norm(a['street1'] ?? a['street']) !=
        norm(b['street1'] ?? b['street'])) {
      return false;
    }
    if (norm(a['street2'] ?? a['place'] ?? a['street_2']) !=
        norm(b['street2'] ?? b['place'] ?? b['street_2'])) {
      return false;
    }
    if (norm(a['city']) != norm(b['city'])) {
      return false;
    }
    if (norm(a['state']) != norm(b['state'])) {
      return false;
    }
    if (norm(a['zip'] ?? a['pincode']) != norm(b['zip'] ?? b['pincode'])) {
      return false;
    }
    if (norm(a['country'] ?? a['countryRegion'] ?? a['country_region']) !=
        norm(b['country'] ?? b['countryRegion'] ?? b['country_region'])) {
      return false;
    }
    if (norm(a['phone']) != norm(b['phone'])) {
      return false;
    }
    if (norm(a['attention']) != norm(b['attention'])) {
      return false;
    }
    return true;
  }

  List<Map<String, dynamic>> _getAllCustomerAddresses(SalesCustomer customer) {
    final list = <Map<String, dynamic>>[];

    final hasBilling = [
      customer.billingAddressStreet1,
      customer.billingAddressStreet2,
      customer.billingAddressCity,
      customer.billingAddressZip,
      customer.billingAddressCountryId,
      customer.billingAddressStateId,
    ].any((value) => value != null && value.toString().isNotEmpty);
    if (hasBilling) {
      list.add(<String, dynamic>{
        'attention': customer.companyName ?? customer.displayName,
        'street1': customer.billingAddressStreet1 ?? '',
        'street2': customer.billingAddressStreet2 ?? '',
        'city': customer.billingAddressCity ?? '',
        'state': customer.billingAddressStateId ?? '',
        'zip': customer.billingAddressZip ?? '',
        'country': customer.billingAddressCountryId ?? '',
        'phone': customer.billingAddressPhone ?? '',
        'is_default_billing': true,
        'address_type': 'billing',
      });
    }

    final hasShipping = [
      customer.shippingAddressStreet1,
      customer.shippingAddressStreet2,
      customer.shippingAddressCity,
      customer.shippingAddressZip,
      customer.shippingAddressCountryId,
      customer.shippingAddressStateId,
    ].any((value) => value != null && value.toString().isNotEmpty);
    if (hasShipping) {
      list.add(<String, dynamic>{
        'attention': customer.companyName ?? customer.displayName,
        'street1': customer.shippingAddressStreet1 ?? '',
        'street2': customer.shippingAddressStreet2 ?? '',
        'city': customer.shippingAddressCity ?? '',
        'state': customer.shippingAddressStateId ?? '',
        'zip': customer.shippingAddressZip ?? '',
        'country': customer.shippingAddressCountryId ?? '',
        'phone': customer.shippingAddressPhone ?? '',
        'is_default_shipping': true,
        'address_type': 'shipping',
      });
    }

    for (final rawAddress in customer.additionalAddresses) {
      final normalized = _normalizeAddress(rawAddress);
      final hasContent = [
        normalized['street1'],
        normalized['street2'],
        normalized['city'],
        normalized['state'],
        normalized['zip'],
        normalized['country'],
        normalized['phone'],
      ].any((value) => (value?.toString() ?? '').trim().isNotEmpty);
      if (!hasContent) {
        continue;
      }

      final address = <String, dynamic>{
        ...rawAddress,
        ...normalized,
        'attention':
            (rawAddress['attention'] ??
                    rawAddress['companyName'] ??
                    rawAddress['company_name'] ??
                    customer.companyName ??
                    customer.displayName)
                .toString(),
        'address_type':
            (rawAddress['address_type'] ??
                    rawAddress['type'] ??
                    rawAddress['addressType'] ??
                    '')
                .toString(),
        'is_default_billing': rawAddress['is_default_billing'] == true,
        'is_default_shipping': rawAddress['is_default_shipping'] == true,
      };

      final exists = list.any((existing) => _areAddressesEqual(existing, address));
      if (!exists) {
        list.add(address);
      }
    }

    return list;
  }

  Future<void> _updateCustomerAddress({
    required SalesCustomer customer,
    required Map<String, dynamic> address,
    required bool isBilling,
  }) async {
    final normalizedAddr = _normalizeAddress(address);
    final countriesList = ref.read(countriesProvider(null)).valueOrNull ?? [];

    String? billingCountry = isBilling
        ? normalizedAddr['country'] as String?
        : customer.billingAddressCountryId;
    String? shippingCountry = !isBilling
        ? normalizedAddr['country'] as String?
        : customer.shippingAddressCountryId;

    final billingCountryObj = countriesList.firstWhere(
      (item) =>
          item['id'] == billingCountry ||
          item['name']?.toLowerCase() == billingCountry?.toLowerCase() ||
          item['shortCode']?.toLowerCase() == billingCountry?.toLowerCase(),
      orElse: () => <String, String>{},
    );
    final billingCountryUuid = billingCountryObj['id'] ?? billingCountry;

    final shippingCountryObj = countriesList.firstWhere(
      (item) =>
          item['id'] == shippingCountry ||
          item['name']?.toLowerCase() == shippingCountry?.toLowerCase() ||
          item['shortCode']?.toLowerCase() == shippingCountry?.toLowerCase(),
      orElse: () => <String, String>{},
    );
    final shippingCountryUuid = shippingCountryObj['id'] ?? shippingCountry;

    final billingStates =
        (billingCountryUuid != null && billingCountryUuid.isNotEmpty)
        ? (ref.read(statesProvider(billingCountryUuid)).valueOrNull ?? [])
        : <Map<String, String>>[];
    String? billingState = isBilling
        ? normalizedAddr['state'] as String?
        : customer.billingAddressStateId;
    final billingStateObj = billingStates.firstWhere(
      (item) =>
          item['id'] == billingState ||
          item['name']?.toLowerCase() == billingState?.toLowerCase() ||
          item['code']?.toLowerCase() == billingState?.toLowerCase(),
      orElse: () => <String, String>{},
    );
    final billingStateUuid = billingStateObj['id'] ?? billingState;

    final shippingStates =
        (shippingCountryUuid != null && shippingCountryUuid.isNotEmpty)
        ? (ref.read(statesProvider(shippingCountryUuid)).valueOrNull ?? [])
        : <Map<String, String>>[];
    String? shippingState = !isBilling
        ? normalizedAddr['state'] as String?
        : customer.shippingAddressStateId;
    final shippingStateObj = shippingStates.firstWhere(
      (item) =>
          item['id'] == shippingState ||
          item['name']?.toLowerCase() == shippingState?.toLowerCase() ||
          item['code']?.toLowerCase() == shippingState?.toLowerCase(),
      orElse: () => <String, String>{},
    );
    final shippingStateUuid = shippingStateObj['id'] ?? shippingState;

    final billingAddressPayload = <String, dynamic>{
      'street1': isBilling
          ? normalizedAddr['street1']
          : customer.billingAddressStreet1,
      'place': isBilling
          ? normalizedAddr['street2']
          : customer.billingAddressStreet2,
      'city': isBilling ? normalizedAddr['city'] : customer.billingAddressCity,
      'stateId': isBilling ? normalizedAddr['state'] : billingStateUuid,
      'zip': isBilling ? normalizedAddr['zip'] : customer.billingAddressZip,
      'countryId': isBilling
          ? normalizedAddr['country']
          : billingCountryUuid,
      'phone': isBilling
          ? normalizedAddr['phone']
          : customer.billingAddressPhone,
    };

    final shippingAddressPayload = <String, dynamic>{
      'street1': !isBilling
          ? normalizedAddr['street1']
          : customer.shippingAddressStreet1,
      'place': !isBilling
          ? normalizedAddr['street2']
          : customer.shippingAddressStreet2,
      'city': !isBilling
          ? normalizedAddr['city']
          : customer.shippingAddressCity,
      'stateId': !isBilling ? normalizedAddr['state'] : shippingStateUuid,
      'zip': !isBilling ? normalizedAddr['zip'] : customer.shippingAddressZip,
      'countryId': !isBilling
          ? normalizedAddr['country']
          : shippingCountryUuid,
      'phone': !isBilling
          ? normalizedAddr['phone']
          : customer.shippingAddressPhone,
    };

    setState(() {
      _selectedCustomerOverride = isBilling
          ? customer.copyWith(
              billingAddressStreet1:
                  normalizedAddr['street1']?.toString(),
              billingAddressStreet2:
                  normalizedAddr['street2']?.toString(),
              billingAddressCity: normalizedAddr['city']?.toString(),
              billingAddressStateId: normalizedAddr['state']?.toString(),
              billingAddressZip: normalizedAddr['zip']?.toString(),
              billingAddressCountryId: normalizedAddr['country']?.toString(),
              billingAddressPhone: normalizedAddr['phone']?.toString(),
            )
          : customer.copyWith(
              shippingAddressStreet1:
                  normalizedAddr['street1']?.toString(),
              shippingAddressStreet2:
                  normalizedAddr['street2']?.toString(),
              shippingAddressCity: normalizedAddr['city']?.toString(),
              shippingAddressStateId: normalizedAddr['state']?.toString(),
              shippingAddressZip: normalizedAddr['zip']?.toString(),
              shippingAddressCountryId: normalizedAddr['country']?.toString(),
              shippingAddressPhone: normalizedAddr['phone']?.toString(),
            );
    });

    await ref.read(salesOrderControllerProvider.notifier).updateCustomer(
      customer.id,
      <String, dynamic>{
        'billingAddress': billingAddressPayload,
        'shippingAddress': shippingAddressPayload,
      },
    );
  }

  void _showAddressDropdownList({
    required SalesCustomer customer,
    required bool isBilling,
    required LayerLink link,
  }) {
    _closeAddressDropdownOverlay();
    final allAddresses = _getAllCustomerAddresses(customer);

    _addressDropdownOverlay = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeAddressDropdownOverlay,
        child: Stack(
          children: [
            const Positioned.fill(child: SizedBox.expand()),
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 6),
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  child: Container(
                    width: 356,
                    constraints: const BoxConstraints(maxHeight: 380),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(10),
                            itemCount: allAddresses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) => _buildAddressDropdownItem(
                              customer: customer,
                              address: allAddresses[i],
                              isBilling: isBilling,
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        InkWell(
                          onTap: () {
                            _closeAddressDropdownOverlay();
                            _showAddressDialog(isBilling: isBilling);
                          },
                          child: SizedBox(
                            height: 38,
                            child: Row(
                              children: const [
                                SizedBox(width: 14),
                                Icon(
                                  LucideIcons.plusCircle,
                                  size: 14,
                                  color: AppTheme.primaryBlue,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'New address',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
    );
    Overlay.of(context).insert(_addressDropdownOverlay!);
  }

  Widget _buildAddressDropdownItem({
    required SalesCustomer customer,
    required Map<String, dynamic> address,
    required bool isBilling,
  }) {
    final attention = address['attention'] as String? ?? '';
    final street1 = address['street1'] as String? ?? '';
    final street2 = address['street2'] as String? ?? '';
    final city = address['city'] as String? ?? '';
    final state = address['state'] as String? ?? '';
    final zip = address['zip'] as String? ?? '';
    final country = address['country'] as String? ?? '';
    final phone = address['phone'] as String? ?? '';

    final countries = ref.read(countriesProvider(null)).valueOrNull ?? [];
    final countryMap = countries.firstWhere(
      (item) => item['id'] == country || item['shortCode'] == country,
      orElse: () => <String, String>{},
    );
    final countryName = countryMap['name'] ?? country;

    final states = country.isNotEmpty
        ? (ref.read(statesProvider(country)).valueOrNull ?? [])
        : <Map<String, String>>[];
    Map<String, String>? stateMap;
    for (final item in states) {
      if (item['id'] == state || item['code'] == state) {
        stateMap = item;
        break;
      }
    }
    final stateName = stateMap?['name'] ?? state;

    final isAddrBilling =
        address['is_default_billing'] == true ||
        address['address_type'] == 'billing';
    final isAddrShipping =
        address['is_default_shipping'] == true ||
        address['address_type'] == 'shipping';

    var canEdit = true;
    if (isBilling) {
      if (isAddrShipping && !isAddrBilling) {
        canEdit = false;
      }
    } else {
      if (isAddrBilling && !isAddrShipping) {
        canEdit = false;
      }
    }

    final activeAddress = <String, dynamic>{
      'attention': customer.companyName ?? customer.displayName,
      'street1': isBilling
          ? customer.billingAddressStreet1 ?? ''
          : customer.shippingAddressStreet1 ?? '',
      'street2': isBilling
          ? customer.billingAddressStreet2 ?? ''
          : customer.shippingAddressStreet2 ?? '',
      'city': isBilling
          ? customer.billingAddressCity ?? ''
          : customer.shippingAddressCity ?? '',
      'state': isBilling
          ? customer.billingAddressStateId ?? ''
          : customer.shippingAddressStateId ?? '',
      'zip': isBilling
          ? customer.billingAddressZip ?? ''
          : customer.shippingAddressZip ?? '',
      'country': isBilling
          ? customer.billingAddressCountryId ?? ''
          : customer.shippingAddressCountryId ?? '',
      'phone': isBilling
          ? customer.billingAddressPhone ?? ''
          : customer.shippingAddressPhone ?? '',
    };
    final isSelected =
        _areAddressesEqual(activeAddress, address) &&
        (isBilling ? isAddrBilling : isAddrShipping);

    final lines = <String>[
      if (street1.isNotEmpty) street1,
      if (street2.isNotEmpty) street2,
      [city, stateName, zip].where((s) => s.isNotEmpty).join(', '),
      if (countryName.isNotEmpty) countryName,
      if (phone.isNotEmpty) phone,
    ];

    var isHovered = false;
    return StatefulBuilder(
      builder: (ctx, setSt) => MouseRegion(
        onEnter: (_) => setSt(() => isHovered = true),
        onExit: (_) => setSt(() => isHovered = false),
        child: GestureDetector(
          onTap: () async {
            _closeAddressDropdownOverlay();
            try {
              await _updateCustomerAddress(
                customer: customer,
                address: address,
                isBilling: isBilling,
              );
              if (mounted) {
                ZerpaiToast.success(context, 'Customer address updated');
              }
            } catch (error) {
              if (mounted) {
                ZerpaiToast.error(
                  context,
                  'Failed to update address: $error',
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              color: isHovered
                  ? const Color(0xFF3B82F6)
                  : (isSelected
                        ? const Color(0xFFF1F5F9)
                        : Colors.white),
              border: Border.all(
                color: isHovered
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE5E7EB),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        attention.isNotEmpty
                            ? attention
                            : (isBilling
                                  ? 'Billing Address'
                                  : 'Shipping Address'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isHovered
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (canEdit)
                      InkWell(
                        onTap: () {
                          _closeAddressDropdownOverlay();
                          _showAddressDialog(
                            isBilling: isBilling,
                            initialAddress: address,
                          );
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isHovered
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isHovered
                                  ? Colors.white.withValues(alpha: 0.55)
                                  : const Color(0xFFD9E2F6),
                            ),
                          ),
                          child: Icon(
                            LucideIcons.pencil,
                            size: 11,
                            color: isHovered
                                ? Colors.white
                                : AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final line in lines)
                  Text(
                    line,
                    style: TextStyle(
                      fontSize: 11,
                      color: isHovered
                          ? Colors.white
                          : const Color(0xFF4B5563),
                      height: 1.45,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showQuoteNumberPreferencesDialog() async {
    final currentNumber = _quoteNumberCtrl.text.trim();
    final splitIndex = currentNumber.lastIndexOf(RegExp(r'[0-9]'));
    String prefix = 'QT-';
    String nextNumber = '000005';

    if (splitIndex >= 0) {
      int firstDigitIndex = currentNumber.indexOf(RegExp(r'[0-9]'));
      if (firstDigitIndex > 0) {
        prefix = currentNumber.substring(0, firstDigitIndex);
        nextNumber = currentNumber.substring(firstDigitIndex);
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => _QuoteNumberPreferencesDialog(
        currentPrefix: prefix,
        currentNextNumber: nextNumber,
        isAutoGenerate: _isQuoteNumberAutoGenerate,
        locationLabel:
            ref.read(orgSettingsProvider).valueOrNull?.name.trim().isNotEmpty ==
                true
            ? ref.read(orgSettingsProvider).valueOrNull!.name.trim()
            : '-',
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _isQuoteNumberAutoGenerate =
          result['isAutoGenerate'] as bool? ?? _isQuoteNumberAutoGenerate;
      final prefixValue = result['prefix'] as String? ?? prefix;
      final nextValue = result['nextNumber'] as String? ?? nextNumber;
      _quoteNumberCtrl.text = '$prefixValue$nextValue';
    });
  }

  Widget _buildSelectedCustomerInfo(SalesCustomer customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 180,
              child: _buildCustomerAddressBlock(
                customer: customer,
                label: 'BILLING ADDRESS',
                link: _billingAddressLink,
                isBilling: true,
              ),
            ),
            const SizedBox(width: 34),
            SizedBox(
              width: 180,
              child: _buildCustomerAddressBlock(
                customer: customer,
                label: 'SHIPPING ADDRESS',
                link: _shippingAddressLink,
                isBilling: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'GST Treatment: ',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    customer.gstTreatment ?? 'Unregistered Business',
                    style: AppTheme.textPrimaryStyle(13, FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
                  CompositedTransformTarget(
                    link: _gstTaxLink,
                    child: InkWell(
                      onTap: () => _toggleGstTaxOverlay(
                        customer.gstTreatment ?? 'Unregistered Business',
                      ),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          LucideIcons.pencil,
                          size: 13,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceOfSupplyField(SalesCustomer customer) {
    final statesAsync = ref.watch(salesQuotationStatesFromDbProvider);
    final statesList = statesAsync.valueOrNull ?? const <String>[];
    final fallbackValue = _selectedPlaceOfSupply ??
        customer.placeOfSupply ??
        customer.shippingAddressStateId ??
        customer.billingAddressStateId;
    final items = List<String>.from(statesList);
    if (fallbackValue != null && fallbackValue.trim().isNotEmpty) {
      final exists = items.any(
        (item) => item.toLowerCase() == fallbackValue.trim().toLowerCase(),
      );
      if (!exists) {
        items.insert(0, fallbackValue.trim());
      }
    }

    return _buildFormRow(
      label: 'Place of Supply',
      required: true,
      child: SizedBox(
        width: 300,
        child: FormDropdown<String>(
          value: fallbackValue != null && items.contains(fallbackValue.trim())
              ? fallbackValue.trim()
              : null,
          items: items,
          hint: statesAsync.isLoading
              ? 'Loading states...'
              : 'Select Place of Supply',
          height: _fieldHeight,
          onChanged: _applyPlaceOfSupply,
        ),
      ),
    );
  }

  Widget _buildCustomerAddressBlock(
    {
    required SalesCustomer customer,
    required String label,
    required LayerLink link,
    required bool isBilling,
  }) {
    final attention = customer.companyName ?? customer.displayName;
    final street1 = isBilling
        ? customer.billingAddressStreet1
        : customer.shippingAddressStreet1;
    final street2 = isBilling
        ? customer.billingAddressStreet2
        : customer.shippingAddressStreet2;
    final city = isBilling
        ? customer.billingAddressCity
        : customer.shippingAddressCity;
    final state = isBilling
        ? customer.billingAddressStateId
        : customer.shippingAddressStateId;
    final zip = isBilling
        ? customer.billingAddressZip
        : customer.shippingAddressZip;
    final country = isBilling
        ? customer.billingAddressCountryId
        : customer.shippingAddressCountryId;
    final phone = isBilling
        ? (customer.billingAddressPhone ?? customer.phone)
        : (customer.shippingAddressPhone ?? customer.phone);
    final hasAddress = [
      street1,
      street2,
      city,
      state,
      zip,
      country,
      phone,
    ].any((value) => value != null && value.trim().isNotEmpty);
    final lines = <String>[
      if (street1 != null && street1.isNotEmpty) street1,
      if (street2 != null && street2.isNotEmpty) street2,
      [city ?? '', state ?? '', zip ?? '']
          .where((entry) => entry.isNotEmpty)
          .join(', '),
      if (country != null && country.isNotEmpty) country,
      if (phone != null && phone.isNotEmpty) phone,
    ].where((entry) => entry.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 6),
            CompositedTransformTarget(
              link: link,
              child: InkWell(
                onTap: () => _showAddressDropdownList(
                  customer: customer,
                  isBilling: isBilling,
                  link: link,
                ),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    LucideIcons.pencil,
                    size: 13,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!hasAddress)
          GestureDetector(
            onTap: () => _showAddressDialog(isBilling: isBilling),
            child: Text(
              'New address',
              style: AppTheme.textPrimaryStyle(
                12,
                FontWeight.w500,
              ).copyWith(color: AppTheme.primaryBlue),
            ),
          )
        else ...[
          Text(
            attention,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCustomerDetailsCard(SalesCustomer customer) {
    return Material(
      color: const Color(0xFF4C556D),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () {
          _showCustomerDetailsSidebar(customer);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minWidth: 236),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${customer.displayName}'s Details",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizedPlaceOfSupply(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return '[KL] - Kerala';
    }
    if (value.contains('[')) {
      return value;
    }

    final lower = value.toLowerCase();
    if (lower.contains('kerala')) return '[KL] - Kerala';
    if (lower.contains('tamil')) return '[TN] - Tamil Nadu';
    if (lower.contains('karnataka')) return '[KA] - Karnataka';
    return value;
  }

  String _resolveCustomerCurrencyLabel(SalesCustomer customer) {
    final raw = customer.currencyId?.trim();
    if (raw == null || raw.isEmpty) {
      return 'INR';
    }
    final uuidLike = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (uuidLike.hasMatch(raw)) {
      return 'INR';
    }
    final upper = raw.toUpperCase();
    if (upper.contains('INR')) {
      return 'INR';
    }
    if (upper.length > 4) {
      return 'INR';
    }
    return upper;
  }

  // List<String> _addressLines({
  //   required String? name,
  //   required String address,
  //   required String? phone,
  // }) {
  //   final lines = <String>[];
  //   if (name != null && name.trim().isNotEmpty) {
  //     lines.add(name.trim());
  //   }
  //   if (address != 'N/A') {
  //     lines.addAll(address.split('\n').where((line) => line.trim().isNotEmpty));
  //   }
  //   if (phone != null && phone.trim().isNotEmpty) {
  //     lines.add('Phone: ${phone.trim()}');
  //   }
  //   return lines;
  // }

  Widget _buildSummaryCard() {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 560,
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          _summaryValueRow('Sub Total', _subTotal, bold: true),
          const SizedBox(height: 16),
          _buildShippingSummaryRow(),
          const SizedBox(height: 16),
          if (_taxBreakdown.isNotEmpty) ...[
            ..._taxBreakdown.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _summaryValueRow(entry.key, entry.value),
              ),
            ),
          ],
          if (_useTds) ...[
            _buildTaxSummaryRow(),
            const SizedBox(height: 16),
            _buildAdjustmentSummaryRow(),
          ] else ...[
            _buildAdjustmentSummaryRow(),
            const SizedBox(height: 16),
            _buildTaxSummaryRow(),
          ],
          const SizedBox(height: 16),
          _summaryValueRow('Round Off', 0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: AppTheme.borderLight),
          ),
          Row(
            children: [
              Text(
                'Total ( \u20B9 )',
              style: AppTheme.textPrimaryStyle(15, FontWeight.w700),
              ),
              const Spacer(),
              Text(
                _total.toStringAsFixed(2),
                style: AppTheme.textPrimaryStyle(15, FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShippingSummaryRow() {
    return _summaryInputRow(
      'Shipping Charges',
      controller: _shippingCtrl,
      amount: double.tryParse(_shippingCtrl.text) ?? 0,
      suffixIcon: const ZTooltip(
        message: 'Amount spent on shipping the goods.',
        direction: ZTooltipDirection.top,
        child: Icon(
          LucideIcons.helpCircle,
          size: 14,
          color: Color(0xFF7C8598),
        ),
      ),
    );
  }

  Widget _buildAdjustmentSummaryRow() {
    return _summaryInputRow(
      _adjustmentLabelCtrl.text,
      controller: _adjustmentCtrl,
      amount: double.tryParse(_adjustmentCtrl.text) ?? 0,
      labelField: CustomTextField(
        controller: _adjustmentLabelCtrl,
        height: _dateFieldHeight,
        contentCase: ContentCase.none,
      ),
      labelWidth: 142,
      suffixIcon: const ZTooltip(
        message:
            'Add any other +ve or -ve charges that need to be applied to adjust the total amount of the transaction Eg. +10 or -10.',
        direction: ZTooltipDirection.top,
        child: Icon(
          LucideIcons.helpCircle,
          size: 14,
          color: Color(0xFF7C8598),
        ),
      ),
    );
  }

  Widget _buildTaxSummaryRow() {
    final tdsRatesAsync = ref.watch(salesQuotationTdsRatesProvider);
    final tdsRates = tdsRatesAsync.valueOrNull ?? const <TdsRateOption>[];
    
    final tcsRatesAsync = ref.watch(salesQuotationTcsRatesProvider);
    final tcsRates = tcsRatesAsync.valueOrNull ?? const <TcsRateOption>[];
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final tdsRow = RadioGroup<bool>(
          groupValue: _useTds,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _useTds = value;
                _selectedTaxId = null;
              });
              _calculateTotals();
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<bool>(
                    value: true,
                    activeColor: AppTheme.primaryBlue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(
                    'TDS',
                    style: AppTheme.bodyText.copyWith(fontSize: 13),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<bool>(
                    value: false,
                    activeColor: AppTheme.primaryBlue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(
                    'TCS',
                    style: AppTheme.bodyText.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        );

        final taxField = SizedBox(
          width: compact ? double.infinity : 280,
          child: Row(
            children: [
              Expanded(
                child: FormDropdown<String>(
                  value: _useTds
                      ? (tdsRates.any((t) => t.id == _selectedTaxId) ? _selectedTaxId : null)
                      : (tcsRates.any((t) => t.id == _selectedTaxId) ? _selectedTaxId : null),
                  items: _useTds
                      ? tdsRates.map((t) => t.id).toList()
                      : tcsRates.map((t) => t.id).toList(),
                  hint: 'Select a Tax',
                  height: _dateFieldHeight,
                  showSettings: true,
                  settingsLabel: _useTds ? 'Manage TDS' : 'Manage TCS',
                  settingsIcon: Icons.settings,
                  onSettingsTap: () {
                    if (_useTds) {
                      _showManageTdsRatesDialog();
                    } else {
                      _showManageTcsRatesDialog();
                    }
                  },
                  displayStringForValue: (id) {
                    if (_useTds) {
                      for (final rate in tdsRates) {
                        if (rate.id == id) {
                          return '${rate.name} (${rate.rate}%)';
                        }
                      }
                    } else {
                      for (final rate in tcsRates) {
                        if (rate.id == id) {
                          return '${rate.name} (${rate.rate}%)';
                        }
                      }
                    }
                    return id;
                  },
                  onChanged: (value) {
                    setState(() => _selectedTaxId = value);
                    _calculateTotals();
                  },
                ),
              ),
              const SizedBox(width: 10),
              ZTooltip(
                message: _useTds
                    ? 'TDS is calculated on the Total amount after deducting discounts and adjustments.'
                    : 'TCS is calculated on the Total amount which is inclusive of taxes, shipping charges, discounts and adjustments.',
                direction: ZTooltipDirection.top,
                child: const Icon(
                  LucideIcons.helpCircle,
                  size: 14,
                  color: Color(0xFF7C8598),
                ),
              ),
            ],
          ),
        );

        final amountText = Align(
          alignment: compact ? Alignment.centerLeft : Alignment.centerRight,
          child: Text(
            _useTds 
                ? '- ${_tdsTcsAmount.toStringAsFixed(2)}' 
                : _tdsTcsAmount.toStringAsFixed(2),
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tdsRow,
              const SizedBox(height: 10),
              taxField,
              const SizedBox(height: 8),
              amountText,
            ],
          );
        }

        return Row(
          children: [
            SizedBox(
              width: 125,
              child: Align(
                alignment: Alignment.centerLeft,
                child: tdsRow,
              ),
            ),
            const SizedBox(width: 6),
            taxField,
            const Spacer(),
            SizedBox(width: 60, child: amountText),
          ],
        );
      },
    );
  }

  Widget _summaryValueRow(String label, double value, {bool bold = false}) {
    return Row(
      children: [
        Text(
          label,
          style: (bold ? AppTheme.sectionHeader : AppTheme.bodyText).copyWith(
            fontSize: bold ? 13 : 12,
          ),
        ),
        const Spacer(),
        Text(
          value.toStringAsFixed(2),
          style: AppTheme.textPrimaryStyle(
            13,
            bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _summaryInputRow(
    String label, {
    required TextEditingController controller,
    required double amount,
    Widget? labelField,
    double labelWidth = 118,
    Widget? suffixIcon,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final effectiveLabel = labelField ??
            Text(
              label,
              style: AppTheme.bodyText.copyWith(fontSize: 13),
            );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: double.infinity, child: effectiveLabel),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: controller,
                      height: _dateFieldHeight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      contentCase: ContentCase.none,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  if (suffixIcon != null) ...[
                    const SizedBox(width: 10),
                    suffixIcon,
                  ],
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 56,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        amount.toStringAsFixed(2),
                        style: AppTheme.textPrimaryStyle(13, FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: labelWidth, child: effectiveLabel),
            SizedBox(
              width: 114,
              child: CustomTextField(
                controller: controller,
                height: _dateFieldHeight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                allowNegative: controller == _adjustmentCtrl,
                contentCase: ContentCase.none,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 12),
            if (suffixIcon != null) suffixIcon,
            const Spacer(),
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  amount.toStringAsFixed(2),
                  style: AppTheme.textPrimaryStyle(13, FontWeight.w500),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTermsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        border: const Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final terms = Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & Conditions',
                  style: AppTheme.bodyText.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: _termsCtrl,
                  height: 92,
                  maxLines: 4,
                  hintText:
                      'Enter the terms and conditions of your business to be displayed in your transaction',
                  contentCase: ContentCase.sentence,
                ),
              ],
            ),
          );

          final attachments = Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attach File(s) to Quote',
                  style: AppTheme.bodyText.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CompositedTransformTarget(
                      link: _uploadLink,
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _isUploadButtonHovered = true),
                        onExit: (_) => setState(() => _isUploadButtonHovered = false),
                        child: CustomPaint(
                          foregroundPainter: _DashedBorderPainter(
                            color: (_isUploadButtonHovered || _uploadOverlay != null)
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFD1D5DB),
                          ),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: _pickUploadFiles,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    bottomLeft: Radius.circular(4),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          LucideIcons.upload,
                                          size: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Upload File',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const VerticalDivider(
                                  width: 1,
                                  color: Color(0xFFE5E7EB),
                                  thickness: 1,
                                  indent: 6,
                                  endIndent: 6,
                                ),
                                InkWell(
                                  onTap: _toggleUploadOverlay,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(
                                      _uploadOverlay != null
                                          ? LucideIcons.chevronUp
                                          : LucideIcons.chevronDown,
                                      size: 16,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_attachedFiles.isNotEmpty) _buildAttachmentBadge(),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'You can upload a maximum of 5 files, 10MB each',
                  style: AppTheme.metaHelper,
                ),
              ],
            ),
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                terms,
                const Divider(height: 1, color: AppTheme.borderLight),
                attachments,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: terms),
              Container(
                width: 1,
                height: 174,
                color: AppTheme.borderLight,
              ),
              Expanded(flex: 2, child: attachments),
            ],
          );
        },
      ),
    );
  }

  // Future<void> _showBatchSelectionDialog(SalesOrderItemRow row) async {
  //   if (row.itemId.isEmpty || row.warehouseId == null || row.warehouseId!.isEmpty) {
  //     return;
  //   }
  // 
  //   final warehouseList = ref.read(warehousesProvider).valueOrNull ?? <Warehouse>[];
  //   Warehouse? selectedWarehouse;
  //   for (final warehouse in warehouseList) {
  //     if (warehouse.id == row.warehouseId) {
  //       selectedWarehouse = warehouse;
  //       break;
  //     }
  //   }
  //   selectedWarehouse ??=
  //       warehouseList.isNotEmpty
  //           ? warehouseList.first
  //           : Warehouse(id: row.warehouseId!, name: 'Warehouse');
  // 
  //   final result = await showDialog<PicklistBatchDialogResult>(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (_) => PicklistSelectBatchesDialog(
  //       itemName: row.item?.productName ?? '',
  //       productId: row.itemId,
  //       productUnitPack: row.item?.unitPack ?? '',
  //       warehouseName: selectedWarehouse!.name,
  //       warehouseId: selectedWarehouse.id,
  //       branchId: selectedWarehouse.branchId,
  //       totalQuantity: double.tryParse(row.quantityCtrl.text) ?? 1.0,
  //       savedBatchData: row.batchDataList,
  //     ),
  //   );
  // 
  //   if (!mounted || result == null) return;
  // 
  //   setState(() {
  //     row.hasBatchData = (result.batchDataList ?? const <Map<String, String>>[]).isNotEmpty;
  //     row.batchCount = result.batchCount;
  //     row.batchDataList = result.batchDataList ?? [];
  //     row.batchId =
  //         row.batchDataList.isNotEmpty ? row.batchDataList.first['batchId'] : null;
  // 
  //     final totalFoc = row.batchDataList.fold<double>(
  //       0.0,
  //       (sum, batch) => sum + (double.tryParse(batch['foc'] ?? '') ?? 0.0),
  //     );
  //     row.quantityCtrl.text = totalFoc > 0
  //         ? result.totalIncludingFoc.toInt().toString()
  //         : result.appliedQuantity.toInt().toString();
  //     _calculateTotals();
  //   });
  // }

  Widget _buildQuantityColumn(
    SalesOrderItemRow row, {
    required double height,
    BoxBorder? edge,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(border: edge),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _tableNumberInput(
            row.quantityCtrl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            row.itemId.isNotEmpty ? 'pcs' : '',
            style: AppTheme.bodyText.copyWith(
              fontSize: 11,
              color: AppTheme.textPrimary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetainerSection() {
    final customers = ref.watch(salesCustomersProvider).valueOrNull ?? const <SalesCustomer>[];
    final selectedCustomer = _selectedCustomer(customers);
    final effectiveCustomerId = (_selectedCustomerId ?? selectedCustomer?.id)?.trim();
    final hasSelectedCustomer = effectiveCustomerId != null && effectiveCustomerId.isNotEmpty;
    final contactPersonsAsync = ref.watch(
      salesQuotationCustomerContactPersonsProvider(effectiveCustomerId),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: _createRetainerInvoice,
                  activeColor: AppTheme.primaryBlue,
                  side: const BorderSide(color: AppTheme.borderColor),
                  onChanged: (value) {
                    setState(() => _createRetainerInvoice = value ?? false);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Create a retainer invoice for this quote automatically',
                style: AppTheme.bodyText.copyWith(fontSize: 13),
              ),
              const SizedBox(width: 6),
              const ZTooltip(
                message: 'Automatically creates a retainer invoice when the quote gets accepted through the Customer Portal.',
                direction: ZTooltipDirection.top,
              ),
            ],
          ),
          if (_createRetainerInvoice) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: 238,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Percentage to be collected',
                        style: AppTheme.bodyText.copyWith(fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      const ZTooltip(
                        message:
                            'Please enter a percentage to be collected as retainer from the total amount',
                        direction: ZTooltipDirection.top,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _retainerPercentageCtrl,
                    height: _fieldHeight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    contentCase: ContentCase.none,
                    borderRadius: BorderRadius.circular(4),
                    suffixWidget: Container(
                      width: 30,
                      alignment: Alignment.center,
                      child: Text(
                        '%',
                        style: AppTheme.textPrimaryStyle(13, FontWeight.w600),
                      ),
                    ),
                    suffixSeparator: true,
                  ),
                ],
              ),
            ),
          ],
          if (hasSelectedCustomer) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: 700,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Quote With',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  contactPersonsAsync.when(
                    data: (contactPersons) {
                      final effectiveContactPersons = contactPersons
                          .where((contact) => contact.primaryLabel.trim().isNotEmpty)
                          .toList();

                      final validSelectedValues = _selectedShareQuoteWithIds
                          .where(
                            (id) => effectiveContactPersons.any(
                              (contact) => contact.id == id,
                            ),
                          )
                          .toList();
                      final selectedContacts = effectiveContactPersons
                          .where(
                            (contact) => validSelectedValues.contains(contact.id),
                          )
                          .toList();

                      return SizedBox(
                        width: 700,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 390,
                              child: FormDropdown<String>(
                                value: null,
                                items: effectiveContactPersons
                                    .map((contact) => contact.id)
                                    .toList(),
                                hint: '',
                                height: _fieldHeight,
                                menuWidth: 390,
                                emptyStateLabel: 'NO RESULTS FOUND',
                                multiSelect: true,
                                selectedValues: validSelectedValues,
                                hideSelectedItemsInMultiSelect: true,
                                showSettings: true,
                                settingsLabel: 'Add Contact Person',
                                settingsIcon: Icons.add_circle,
                                searchStringForValue: (id) {
                                  for (final contact in effectiveContactPersons) {
                                    if (contact.id == id) {
                                      return contact.searchLabel;
                                    }
                                  }
                                  return id;
                                },
                                displayStringForValue: (id) {
                                  for (final contact in effectiveContactPersons) {
                                    if (contact.id == id) {
                                      return contact.primaryLabel;
                                    }
                                  }
                                  return id;
                                },
                                itemBuilder: (id, isSelected, isHovered) {
                                  QuoteContactPersonOption? contact;
                                  for (final candidate in effectiveContactPersons) {
                                    if (candidate.id == id) {
                                      contact = candidate;
                                      break;
                                    }
                                  }

                                  final primaryText = contact?.primaryLabel ?? id;
                                  final secondaryText =
                                      contact?.email?.trim().isNotEmpty == true
                                      ? contact!.email!.trim()
                                      : (contact?.mobilePhone?.trim().isNotEmpty == true
                                            ? contact!.mobilePhone!.trim()
                                            : (contact?.workPhone?.trim().isNotEmpty == true
                                                  ? contact!.workPhone!.trim()
                                                  : null));

                                  final textColor =
                                      isHovered ? Colors.white : AppTheme.textPrimary;
                                  final subTextColor = isHovered
                                      ? Colors.white
                                      : AppTheme.textSecondary;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          primaryText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: textColor,
                                          ),
                                        ),
                                        if (secondaryText != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            secondaryText,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: subTextColor,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                                onSettingsTap:
                                    () => _showAddContactPersonDialog(
                                      effectiveCustomerId,
                                    ),
                                onChanged: (_) {},
                                onSelectedValuesChanged: (values) {
                                  setState(() {
                                    _selectedShareQuoteWithIds = values;
                                    _syncCommunicationChannelSelections(values);
                                  });
                                },
                              ),
                            ),
                            if (validSelectedValues.isNotEmpty) ...[
                              const SizedBox(width: 14),
                              SizedBox(
                                height: _fieldHeight,
                                child: InkWell(
                                  onTap: () => _showCommunicationChannelsDialog(
                                    selectedContacts,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.settings_outlined,
                                        size: 15,
                                        color: AppTheme.primaryBlue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Configure Communication Channels',
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    loading: () => Skeleton(height: _fieldHeight, width: 390),
                    error: (_, __) => FormDropdown<String>(
                      value: null,
                      items: const <String>[],
                      hint: '',
                      height: _fieldHeight,
                      menuWidth: 390,
                      emptyStateLabel: 'NO RESULTS FOUND',
                      showSettings: true,
                      settingsLabel: 'Add Contact Person',
                      settingsIcon: Icons.add_circle,
                      onSettingsTap:
                          () => _showAddContactPersonDialog(effectiveCustomerId),
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalFieldsNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: RichText(
        text: TextSpan(
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
          children: const [
            TextSpan(
              text: 'Additional Fields: ',
              style: TextStyle(
                color: AppTheme.textBody,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text:
                  'Start adding custom fields for your quotes by going to Settings ',
            ),
            TextSpan(
              text: '->',
              style: TextStyle(color: AppTheme.textBody),
            ),
            TextSpan(text: ' Sales -> Quotes.'),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          ZButton.secondary(
            label: _isEditMode ? 'Save' : 'Save as Draft',
            onPressed: _isSaving ? null : () => _saveQuote('draft'),
          ),
          const SizedBox(width: 12),
          ZButton.primary(
            label: 'Save and Send',
            loading: _isSaving,
            onPressed: _isSaving ? null : () => _saveQuote('confirmed'),
          ),
          const SizedBox(width: 12),
          ZButton.secondary(
            label: 'Cancel',
            onPressed: _isSaving ? null : _handleCancel,
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              style: AppTheme.bodyText.copyWith(fontSize: 13),
              children: const [
                TextSpan(text: "PDF Template: '"),
                TextSpan(
                  text: 'Spreadsheet Template',
                  style: TextStyle(color: Color(0xFF667085)),
                ),
                TextSpan(text: "'  "),
                TextSpan(
                  text: 'Change',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow({
    required String label,
    required Widget child,
    bool required = false,
    Widget? trailingLabelIcon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _labelWidth,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      text: label,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        color: required
                            ? AppTheme.errorRed
                            : AppTheme.textPrimary,
                      ),
                      children: required
                          ? const [
                              TextSpan(
                                text: '*',
                                style: TextStyle(
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                if (trailingLabelIcon != null) ...[
                  const SizedBox(width: 6),
                  trailingLabelIcon,
                ],
              ],
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: Align(
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ],
    );
  }

  // Widget _buildDualDropdownRow({
  //   required String leftLabel,
  //   required bool leftRequired,
  //   required String? leftValue,
  //   required List<String> leftItems,
  //   required ValueChanged<String?> onLeftChanged,
  //   required String rightLabel,
  //   required bool rightRequired,
  //   required String? rightValue,
  //   required List<String> rightItems,
  //   required ValueChanged<String?> onRightChanged,
  // }) {
  //   return Row(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       SizedBox(
  //         width: _labelWidth,
  //         child: Padding(
  //           padding: const EdgeInsets.only(top: 8),
  //           child: RichText(
  //             text: TextSpan(
  //               text: leftLabel,
  //               style: AppTheme.bodyText.copyWith(
  //                 fontSize: 13,
  //                 color: leftRequired ? AppTheme.errorRed : AppTheme.textPrimary,
  //               ),
  //               children: leftRequired
  //                   ? const [
  //                       TextSpan(
  //                         text: '*',
  //                         style: TextStyle(
  //                           color: AppTheme.errorRed,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                     ]
  //                   : null,
  //             ),
  //           ),
  //         ),
  //       ),
  //       SizedBox(
  //         width: _fieldWidth,
  //         child: FormDropdown<String>(
  //           value: leftValue,
  //           items: leftItems,
  //           height: _fieldHeight,
  //           allowClear: true,
  //           alwaysShowClear: true,
  //           showClearDivider: true,
  //           onChanged: onLeftChanged,
  //         ),
  //       ),
  //       const SizedBox(width: 24),
  //       SizedBox(
  //         width: 120,
  //         child: Padding(
  //           padding: const EdgeInsets.only(top: 8),
  //           child: RichText(
  //             text: TextSpan(
  //               text: rightLabel,
  //               style: AppTheme.bodyText.copyWith(
  //                 fontSize: 13,
  //                 color: rightRequired
  //                     ? AppTheme.errorRed
  //                     : AppTheme.textPrimary,
  //               ),
  //               children: rightRequired
  //                   ? const [
  //                       TextSpan(
  //                         text: '*',
  //                         style: TextStyle(
  //                           color: AppTheme.errorRed,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                     ]
  //                   : null,
  //             ),
  //           ),
  //         ),
  //       ),
  //       SizedBox(
  //         width: _fieldWidth,
  //         child: FormDropdown<String>(
  //           value: rightValue,
  //           items: rightItems,
  //           height: _fieldHeight,
  //           onChanged: onRightChanged,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppTheme.borderLight);
  }

  Widget _buildThinRule() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFEEF1F5),
    );
  }

  static const TextStyle _tableHeaderStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Color(0xFF7B8195),
    letterSpacing: 1.1,
  );

  static const Border _tableCellEdge = Border(
    right: BorderSide(color: AppTheme.borderLight),
  );

  void _handleRateCalculation(SalesOrderItemRow row) {
    final text = row.rateCtrl.text.trim();
    if (text.isEmpty) return;

    if (text.contains(RegExp(r'[+\-*/()xX]'))) {
      final double? result = _evaluateExpression(text);
      if (result != null) {
        row.rateCtrl.text = result % 1 == 0
            ? result.toInt().toString()
            : result.toStringAsFixed(2);
        _calculateTotals();
      }
    }
  }

  double? _evaluateExpression(String input) {
    try {
      final sanitized = input.replaceAll(' ', '').replaceAll('x', '*').replaceAll('X', '*');
      return _MathParser(sanitized).parse();
    } catch (_) {
      return null;
    }
  }

  double _getParsedRate(SalesOrderItemRow row) {
    final text = row.rateCtrl.text.trim();
    if (text.isEmpty) return 0.0;
    if (text.contains(RegExp(r'[+\-*/()xX]'))) {
      return _evaluateExpression(text) ?? 0.0;
    }
    return double.tryParse(text) ?? 0.0;
  }

  void _toggleBulkActionsMenu() {
    if (_bulkActionsOverlay != null) {
      _hideBulkActionsMenu();
      return;
    }
    _showBulkActionsMenu();
  }

  void _hideBulkActionsMenu() {
    _bulkActionsOverlay?.remove();
    _bulkActionsOverlay = null;
    _hoveredBulkAction = null;
  }

  void _showBulkActionsMenu() {
    _bulkActionsOverlay = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideBulkActionsMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _bulkActionsLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 4),
              child: StatefulBuilder(
                builder: (context, setOverlayState) {
                  Widget buildMenuItem({
                    required String keyName,
                    required String label,
                    required VoidCallback onTap,
                  }) {
                    final hovered = _hoveredBulkAction == keyName;
                    return MouseRegion(
                      onEnter: (_) {
                        setOverlayState(() {
                          _hoveredBulkAction = keyName;
                        });
                      },
                      onExit: (_) {
                        setOverlayState(() {
                          if (_hoveredBulkAction == keyName) {
                            _hoveredBulkAction = null;
                          }
                        });
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _hideBulkActionsMenu();
                          onTap();
                        },
                        child: Container(
                          height: 32,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: hovered
                                ? AppTheme.primaryBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: hovered
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: hovered
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildMenuItem(
                            keyName: 'toggle-additional',
                            label: _showAllAdditionalInformation
                                ? 'Hide All Additional Information'
                                : 'Show All Additional Information',
                            onTap: () {
                              setState(() {
                                _showAllAdditionalInformation =
                                    !_showAllAdditionalInformation;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_bulkActionsOverlay!);
  }

  void _toggleReportingTagsOverlay(LayerLink targetLink) {
    if (_reportingTagsOverlay != null) {
      _reportingTagsOverlay?.remove();
      _reportingTagsOverlay = null;
      setState(() {});
      return;
    }

    _reportingTagsOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _reportingTagsOverlay?.remove();
                _reportingTagsOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            width: 500,
            child: CompositedTransformFollower(
              link: targetLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 30),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: const Text(
                          'Reporting Tags',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ADGF',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF374151),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FormDropdown<String>(
                                        items: const ['None'],
                                        value: 'None',
                                        onChanged: (_) {},
                                        hint: 'None',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'shedule',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF374151),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FormDropdown<String>(
                                        items: const ['None'],
                                        value: 'None',
                                        onChanged: (_) {},
                                        hint: 'None',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'demo adavced reporting tag',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF374151),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FormDropdown<String>(
                                        items: const ['None'],
                                        value: 'None',
                                        onChanged: (_) {},
                                        hint: 'None',
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _reportingTagsOverlay?.remove();
                                _reportingTagsOverlay = null;
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
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
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {
                                _reportingTagsOverlay?.remove();
                                _reportingTagsOverlay = null;
                                setState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                                foregroundColor: const Color(0xFF374151),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                backgroundColor: const Color(0xFFF9FAFB),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_reportingTagsOverlay!);
    setState(() {});
  }

  void _toggleAddRowOverlay() {
    if (_addRowOverlay != null) {
      _addRowOverlay?.remove();
      _addRowOverlay = null;
      setState(() {});
      return;
    }

    _addRowOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _addRowOverlay?.remove();
                _addRowOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _addRowLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 36),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 140,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: StatefulBuilder(
                  builder: (context, setOverlayState) {
                    return InkWell(
                      onHover: (v) => setOverlayState(() => _isAddHeaderHovered = v),
                      onTap: () {
                        setState(() {
                          _rows.add(
                            SalesOrderItemRow(
                              quantityCtrl: TextEditingController(text: '0'),
                              rateCtrl: TextEditingController(text: '0.00'),
                              discountCtrl: TextEditingController(text: '0'),
                              isHeader: true,
                            ),
                          );
                        });
                        _addRowOverlay?.remove();
                        _addRowOverlay = null;
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: double.infinity,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _isAddHeaderHovered ? const Color(0xFF3B82F6) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Add New Header',
                          style: TextStyle(
                            color: _isAddHeaderHovered ? Colors.white : const Color(0xFF374151),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_addRowOverlay!);
    setState(() {});
  }

  void _openBulkItemsDialog() {
    final products = ref
        .read(salesQuotationProductsProvider)
        .valueOrNull;
    if (products == null) return;
    showDialog(
      context: context,
      builder: (context) => BulkItemsDialog(
        products: products,
        onItemsSelected: (selectedItems) {
          setState(() {
            _rows.removeWhere((r) => r.itemId.isEmpty && !r.isHeader);
            int insertIdx = _rows.length;
            selectedItems.forEach((item, quantity) {
              final newRow = SalesOrderItemRow(
                quantityCtrl: TextEditingController(text: quantity.toString()),
                rateCtrl: TextEditingController(
                  text: (item.sellingPrice ?? 0) == 0
                      ? '0.00'
                      : (item.sellingPrice ?? 0).toStringAsFixed(2),
                ),
                discountCtrl: TextEditingController(text: '0'),
                itemId: item.id ?? '',
                item: item,
              );
              _setupRowListeners(newRow);
              _rows.insert(insertIdx, newRow);
              insertIdx++;
            });
            _calculateTotals();
          });
        },
      ),
    );
  }


  void _toggleHsnOverlay(SalesOrderItemRow row) {
    if (_hsnOverlay != null) {
      _hsnOverlay?.remove();
      _hsnOverlay = null;
      _activeHsnRow = null;
      setState(() {});
      if (_activeHsnRow == row) return;
    }

    final hsnCtrl = TextEditingController(text: row.hsnCode ?? '');
    _activeHsnRow = row;

    _hsnOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _hsnOverlay?.remove();
                _hsnOverlay = null;
                _activeHsnRow = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: row.hsnLink,
            showWhenUnlinked: false,
            offset: const Offset(-20, 24),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: CustomPaint(
                      size: const Size(12, 8),
                      painter: _TrianglePainter(color: Colors.white),
                    ),
                  ),
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (row.item?.type == 'service') ? 'SAC Code' : 'HSN Code',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: hsnCtrl,
                          hintText: 'Enter HSN Code',
                          suffixWidget: InkWell(
                            onTap: () async {
                              final result = await showDialog<HsnSacCode>(
                                context: context,
                                useSafeArea: false,
                                builder: (context) => HsnSacSearchModal(
                                  type: row.item?.type == 'service' ? 'SAC' : 'HSN',
                                  initialQuery: hsnCtrl.text,
                                ),
                              );
                              if (result != null) {
                                hsnCtrl.text = result.code;
                                setState(() {
                                  row.hsnCode = result.code;
                                  if (row.item != null) {
                                    row.item = row.item!.copyWith(
                                      hsnCode: result.code,
                                    );
                                  }
                                });
                                _hsnOverlay?.remove();
                                _hsnOverlay = null;
                                _activeHsnRow = null;
                                setState(() {});
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(
                                LucideIcons.search,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          forceUppercase: false,
                          contentCase: ContentCase.none,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                if (hsnCtrl.text.isEmpty) {
                                  ZerpaiToast.error(
                                    context,
                                    'Please enter HSN Code',
                                  );
                                  return;
                                }
                                setState(() {
                                  row.hsnCode = hsnCtrl.text;
                                  if (row.item != null) {
                                    row.item = row.item!.copyWith(
                                      hsnCode: hsnCtrl.text,
                                    );
                                  }
                                });
                                _hsnOverlay?.remove();
                                _hsnOverlay = null;
                                _activeHsnRow = null;
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                _hsnOverlay?.remove();
                                _hsnOverlay = null;
                                _activeHsnRow = null;
                                setState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text('Close'),
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
      ),
    );
    Overlay.of(context).insert(_hsnOverlay!);
    setState(() {});
  }

  Widget _buildAttachmentBadge() {
    return CompositedTransformTarget(
      link: _attachmentBadgeLink,
      child: InkWell(
        onTap: _toggleAttachmentListOverlay,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.paperclip, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '${_attachedFiles.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleAttachmentListOverlay() {
    if (_attachmentListOverlay != null) {
      _attachmentListOverlay?.remove();
      _attachmentListOverlay = null;
      setState(() {});
      return;
    }
    _attachmentListOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _attachmentListOverlay?.remove();
                _attachmentListOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _attachmentBadgeLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _attachedFiles
                          .map((file) => _buildAttachmentListItem(file))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_attachmentListOverlay!);
    setState(() {});
  }

  Widget _buildAttachmentListItem(PlatformFile file) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setItemState) {
        return MouseRegion(
          onEnter: (_) => setItemState(() => isHovered = true),
          onExit: (_) => setItemState(() => isHovered = false),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.file,
                  size: 16,
                  color: isHovered ? Colors.white : const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHovered ? Colors.white : const Color(0xFF374151),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'File Size: ${(file.size / 1024).toStringAsFixed(2)} KB',
                        style: TextStyle(
                          fontSize: 11,
                          color: isHovered
                              ? Colors.white.withValues(alpha: 0.8)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isHovered)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _attachedFiles.remove(file);
                        if (_attachedFiles.isEmpty) {
                          _attachmentListOverlay?.remove();
                          _attachmentListOverlay = null;
                        }
                      });
                      _attachmentListOverlay?.markNeedsBuild();
                    },
                    child: const Icon(LucideIcons.trash, size: 14, color: Colors.white),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickUploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (!mounted || result == null) return;
      setState(() {
        final totalFiles = _attachedFiles.length + result.files.length;
        if (totalFiles > 5) {
          ZerpaiToast.error(context, 'You can only attach a maximum of 5 files');
          return;
        }
        final oversizedFiles = result.files.where((f) => f.size > 10 * 1024 * 1024).toList();
        if (oversizedFiles.isNotEmpty) {
          ZerpaiToast.error(context, 'File size should be less than or equal to 10MB');
          return;
        }
        _attachedFiles = [..._attachedFiles, ...result.files];
      });
      final count = _attachedFiles.length;
      if (count > 0) {
        ZerpaiToast.success(context, '$count file${count == 1 ? '' : 's'} attached');
      }
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to pick files: $e');
    }
  }

  void _toggleUploadOverlay() {
    if (_uploadOverlay != null) {
      _uploadOverlay?.remove();
      _uploadOverlay = null;
      if (mounted) setState(() {});
      return;
    }
    _uploadOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _uploadOverlay?.remove();
                _uploadOverlay = null;
                if (mounted) setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _uploadLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            offset: const Offset(0, -8),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    _buildUploadItem('Attach From Desktop', false),
                    _buildUploadItem('Attach From Documents', false),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_uploadOverlay!);
    if (mounted) setState(() {});
  }

  Widget _buildUploadItem(String label, bool isSelected) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setOverlayState) {
        return InkWell(
          onHover: (v) => setOverlayState(() => isHovered = v),
          onTap: () async {
            _uploadOverlay?.remove();
            _uploadOverlay = null;
            if (mounted) setState(() {});
            await _pickUploadFiles();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isHovered
                  ? const Color(0xFF3B82F6) // Hover background is blue
                  : (isSelected ? const Color(0xFFE5E7EB) : Colors.transparent), // Selected background is grey (Color 0xFFE5E7EB)
              borderRadius: BorderRadius.circular(6), // Radius 6 is applied
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isHovered
                    ? Colors.white // Hover text is white on blue background
                    : (isSelected ? const Color(0xFF374151) : const Color(0xFF374151)), // Selected/default text is grey/neutral dark
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNewCustomerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 200,
        ).copyWith(top: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SalesCustomerCreateScreen(
            showLayout: false,
            onSaveSuccess: (newCustomer) {
              Navigator.of(dialogContext).pop();
              setState(() {
                _selectedCustomerId = newCustomer.id;
                _selectedCustomerOverride = newCustomer;
                _selectedPlaceOfSupply = _normalizedPlaceOfSupply(
                  newCustomer.placeOfSupply ??
                      newCustomer.shippingAddressStateId ??
                      newCustomer.billingAddressStateId,
                );
                // Refresh customer list to include the new one
                // ignore: unused_result
                ref.refresh(salesCustomersProvider);
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final updatedCustomers = ref.read(salesCustomersProvider).valueOrNull ?? [];
                _syncAllRowRatesFromCustomer(updatedCustomers);
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDropdownItem(
    SalesCustomer customer,
    bool isSelected,
    bool isHovered,
  ) {
    final customerNumber = (customer.customerNumber ?? '').trim();
    final email = (customer.email ?? '').trim();
    final companyName = (customer.companyName ?? '').trim();
    final firstName = (customer.firstName ?? '').trim();

    final topLine = customerNumber.isEmpty
        ? customer.displayName
        : '${customer.displayName} | $customerNumber';

    final List<String> bottomParts = [];
    if (email.isNotEmpty) bottomParts.add(email);
    if (companyName.isNotEmpty) bottomParts.add(companyName);
    final bottomLine = bottomParts.join(' | ');

    final initialSource = firstName.isNotEmpty
        ? firstName
        : (customer.displayName.isNotEmpty ? customer.displayName : '?');
    final initial = initialSource.substring(0, 1).toUpperCase();

    final backgroundColor = isHovered
        ? const Color(0xFF3B82F6)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
    final primaryTextColor = isHovered ? Colors.white : AppTheme.textPrimary;
    final secondaryTextColor = isHovered
        ? Colors.white.withValues(alpha: 0.85)
        : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHovered
                  ? Colors.white.withValues(alpha: 0.25)
                  : const Color(0xFFE5E7EB),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              textAlign: TextAlign.center,
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1,
                color: isHovered ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: primaryTextColor,
                  ),
                ),
                if (bottomLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    bottomLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _ZohoDateField extends StatelessWidget {
  static const double _height = 34;

  final GlobalKey fieldKey;
  final LayerLink layerLink;
  final String text;
  final VoidCallback onTap;
  final bool isPlaceholder;
  final double width;

  const _ZohoDateField({
    required this.fieldKey,
    required this.layerLink,
    required this.text,
    required this.onTap,
    required this.width,
  }) : isPlaceholder = false;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: GestureDetector(
        key: fieldKey,
        onTap: onTap,
        child: Container(
          width: width,
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.borderColor),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isPlaceholder ? AppTheme.textMuted : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData? trailingIcon;
  final VoidCallback onTap;
  final VoidCallback? onTrailingTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.trailingIcon,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(6),
              bottomLeft: const Radius.circular(6),
              topRight: trailingIcon == null ? const Radius.circular(6) : Radius.zero,
              bottomRight: trailingIcon == null ? const Radius.circular(6) : Radius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: AppTheme.primaryBlue),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTheme.bodyText.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (trailingIcon != null) ...[
            Container(
              width: 1,
              height: 20,
              color: const Color(0xFFE5E7EB),
            ),
            InkWell(
              onTap: onTrailingTap,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  trailingIcon,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool isUp;
  final bool hasBorder;

  _TrianglePainter({
    required this.color,
    this.isUp = true,
    this.hasBorder = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (isUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);

    if (hasBorder) {
      final borderPaint = Paint()
        ..color = const Color(0xFFDDDDDD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConfigureTaxPreferencesDialog extends StatefulWidget {
  final String initialGst;
  final String initialGstin;
  final Function(String, String, bool) onUpdate;
  final VoidCallback onCancel;

  const _ConfigureTaxPreferencesDialog({
    required this.initialGst,
    required this.initialGstin,
    required this.onUpdate,
    required this.onCancel,
  });

  @override
  State<_ConfigureTaxPreferencesDialog> createState() =>
      _ConfigureTaxPreferencesDialogState();
}

class _ConfigureTaxPreferencesDialogState
    extends State<_ConfigureTaxPreferencesDialog> {
  late String _selectedTreatment;
  late TextEditingController _gstinCtrl;
  bool _makePermanent = false;

  final List<Map<String, String>> _treatments = [
    {
      'label': 'Registered Business - Regular',
      'desc': 'Business that is registered under GST',
    },
    {
      'label': 'Registered Business - Composition',
      'desc': 'Business that is registered under the Composition Scheme in GST',
    },
    {
      'label': 'Unregistered Business',
      'desc': 'Business that has not been registered under GST',
    },
    {
      'label': 'Consumer',
      'desc':
          'Individual or business that is not registered and consumes goods/services',
    },
    {'label': 'Overseas', 'desc': 'Business located outside India'},
    {
      'label': 'Special Economic Zone (SEZ)',
      'desc': 'Business located in a SEZ unit or developer',
    },
    {
      'label': 'Deemed Export',
      'desc':
          'Business involved in supply of goods to certain notified purposes',
    },
  ];

  bool get _isRegistered {
    return _selectedTreatment == 'Registered Business - Regular' ||
        _selectedTreatment == 'Registered Business - Composition' ||
        _selectedTreatment == 'Special Economic Zone (SEZ)' ||
        _selectedTreatment == 'Deemed Export';
  }

  @override
  void initState() {
    super.initState();
    _selectedTreatment = widget.initialGst;
    _gstinCtrl = TextEditingController(text: widget.initialGstin);
  }

  @override
  void dispose() {
    _gstinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 34),
          child: CustomPaint(
            size: const Size(14, 8),
            painter: _TrianglePainter(
              color: Colors.white,
              isUp: true,
              hasBorder: true,
            ),
          ),
        ),
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDDDDD)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Configure Tax Preferences',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancel,
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GST Treatment',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555555),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormDropdown<Map<String, String>>(
                      height: 32,
                      value: _treatments.firstWhere(
                        (t) => t['label'] == _selectedTreatment,
                        orElse: () => _treatments[2],
                      ),
                      items: _treatments,
                      showSearch: false,
                      fillColor: Colors.white,
                      displayStringForValue: (v) => v['label']!,
                      itemBuilder: (item, isSelected, isHovered) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          color: isHovered
                              ? const Color(0xFF3B82F6)
                              : (isSelected
                                  ? const Color(0xFFF3F4F6)
                                  : Colors.transparent),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isHovered
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['desc']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isHovered
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : const Color(0xFF6B7280),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTreatment = value['label']!;
                          });
                        }
                      },
                    ),
                    if (_isRegistered) ...[
                      const SizedBox(height: 20),
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'GSTIN',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.redAccent,
                                fontFamily: 'Inter',
                              ),
                            ),
                            TextSpan(
                              text: '*',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: CustomTextField(
                          controller: _gstinCtrl,
                          hintText: 'Enter GSTIN',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Get Taxpayer details',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Make it permanent?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555555),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: _makePermanent,
                            onChanged: (value) => setState(
                              () => _makePermanent = value ?? false,
                            ),
                            activeColor: AppTheme.primaryBlue,
                            side: const BorderSide(color: Color(0xFFCCCCCC)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Use these settings for all future transactions of this customer.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => widget.onUpdate(
                        _selectedTreatment,
                        _gstinCtrl.text.trim(),
                        _makePermanent,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF19A05E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Update',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuoteNumberPreferencesDialog extends StatefulWidget {
  final String currentPrefix;
  final String currentNextNumber;
  final bool isAutoGenerate;
  final String locationLabel;

  const _QuoteNumberPreferencesDialog({
    required this.currentPrefix,
    required this.currentNextNumber,
    required this.isAutoGenerate,
    required this.locationLabel,
  });

  @override
  State<_QuoteNumberPreferencesDialog> createState() =>
      _QuoteNumberPreferencesDialogState();
}

class _QuoteNumberPreferencesDialogState
    extends State<_QuoteNumberPreferencesDialog> {
  late bool _isAutoGenerate;
  late final TextEditingController _prefixController;
  late final TextEditingController _nextNumberController;

  @override
  void initState() {
    super.initState();
    _isAutoGenerate = widget.isAutoGenerate;
    _prefixController = TextEditingController(text: widget.currentPrefix);
    _nextNumberController = TextEditingController(text: widget.currentNextNumber);
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _nextNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0, left: 24, right: 24, bottom: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        width: 600,
        height: 428.68,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
              child: Row(
                children: [
                  const Text(
                    'Configure Quote Number Preferences',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 20,
                        color: Color(0xFFFF3B30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.locationLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Default Transaction Series',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Divider(height: 1, color: Color(0xFFE5E7EB)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: RadioGroup<bool>(
                  groupValue: _isAutoGenerate,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _isAutoGenerate = value);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAutoGenerate
                            ? 'Your quote numbers are set on auto-generate mode to save your time.\nAre you sure about changing this setting?'
                            : 'You have selected manual quote numbering. Do you want us to auto-\ngenerate it for you?',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: Radio<bool>(
                              value: true,
                              activeColor: Color(0xFF4F8EF7),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Continue auto-generating quote numbers',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const ZTooltip(
                                      message:
                                          'The edited prefix and next number will be updated in the transaction number series associated with your quote.',
                                      direction: ZTooltipDirection.top,
                                      child: Icon(
                                        LucideIcons.helpCircle,
                                        size: 13,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isAutoGenerate) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Prefix',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            TextField(
                                              controller: _prefixController,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide:
                                                      const BorderSide(
                                                        color: Color(
                                                          0xFFD1D5DB,
                                                        ),
                                                      ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                          ),
                                                    ),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Next Number',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            TextField(
                                              controller:
                                                  _nextNumberController,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide:
                                                      const BorderSide(
                                                        color: Color(
                                                          0xFFD1D5DB,
                                                        ),
                                                      ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                          ),
                                                    ),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Radio<bool>(
                              value: false,
                              activeColor: Color(0xFF4F8EF7),
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Enter quote numbers manually',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(
                children: [
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'isAutoGenerate': _isAutoGenerate,
                          'prefix': _prefixController.text,
                          'nextNumber': _nextNumberController.text,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF24B26B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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

  



class _MathParser {
  _MathParser(this.input);
  final String input;
  int pos = -1, ch = -1;

  void nextChar() {
    ch = (++pos < input.length) ? input.codeUnitAt(pos) : -1;
  }

  bool eat(int charToEat) {
    while (ch == 32) nextChar(); // skip spaces
    if (ch == charToEat) {
      nextChar();
      return true;
    }
    return false;
  }

  double parse() {
    nextChar();
    double x = parseExpression();
    if (pos < input.length) throw Exception("Unexpected: ${input[pos]}");
    return x;
  }

  double parseExpression() {
    double x = parseTerm();
    for (;;) {
      if (eat(43)) {
        x += parseTerm(); // +
      } else if (eat(45)) {
        x -= parseTerm(); // -
      } else {
        return x;
      }
    }
  }

  double parseTerm() {
    double x = parseFactor();
    for (;;) {
      if (eat(42)) {
        x *= parseFactor(); // *
      } else if (eat(47)) {
        x /= parseFactor(); // /
      } else {
        return x;
      }
    }
  }

  double parseFactor() {
    if (eat(43)) return parseFactor(); // +
    if (eat(45)) return -parseFactor(); // -
    double x;
    int startPos = pos;
    if (eat(40)) {
      x = parseExpression();
      eat(41); // )
    } else if ((ch >= 48 && ch <= 57) || ch == 46) {
      while ((ch >= 48 && ch <= 57) || ch == 46) nextChar();
      x = double.parse(input.substring(startPos, pos));
    } else {
      throw Exception(
        "Unexpected: ${ch == -1 ? 'EOF' : String.fromCharCode(ch)}",
      );
    }
    return x;
  }
}

class _QuoteCommunicationChannelsDialog extends StatefulWidget {
  final List<QuoteContactPersonOption> contacts;
  final Map<String, _QuoteCommunicationChannelConfig> initialConfig;

  const _QuoteCommunicationChannelsDialog({
    required this.contacts,
    required this.initialConfig,
  });

  @override
  State<_QuoteCommunicationChannelsDialog> createState() =>
      _QuoteCommunicationChannelsDialogState();
}

class _QuoteCommunicationChannelsDialogState
    extends State<_QuoteCommunicationChannelsDialog> {
  static const String _smsTooltipMessage =
      'SMS has been disabled for this contact person. To send messages to '
      'this contact person via SMS, go to Sales > Customers > respective '
      'customer > enable SMS for this contact person.';

  late Map<String, _QuoteCommunicationChannelConfig> _configByContactId;

  @override
  void initState() {
    super.initState();
    _configByContactId = {
      for (final contact in widget.contacts)
        contact.id:
            widget.initialConfig[contact.id] ??
            const _QuoteCommunicationChannelConfig(),
    };
  }

  void _updateContact(
    String contactId, {
    bool? all,
    bool? email,
    bool? sms,
  }) {
    setState(() {
      final current =
          _configByContactId[contactId] ??
          const _QuoteCommunicationChannelConfig();
      _configByContactId[contactId] = current.copyWith(
        all: all,
        email: email,
        sms: sms,
      );
    });
  }

  Widget _buildHeaderCell(
    String label, {
    bool addSmsTooltip = false,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: textAlign == TextAlign.left
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: textAlign,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7B8190),
            ),
          ),
          if (addSmsTooltip) ...[
            const SizedBox(width: 4),
            const ZTooltip(
              message: _smsTooltipMessage,
              direction: ZTooltipDirection.top,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?>? onChanged,
  }) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: Color(0xFFD7DCE5)),
        activeColor: const Color(0xFF4C8BF5),
        checkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.86;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0, left: 24, right: 24, bottom: 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 700,
          maxWidth: 700,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
              child: Row(
                children: [
                  const Text(
                    'Configure Communication Channels',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE7EAF0)),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE1E6EF)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF7F8FC),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _buildHeaderCell(
                                      'CONTACT PERSON',
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildHeaderCell('ALL'),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildHeaderCell('EMAIL'),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildHeaderCell(
                                      'SMS',
                                      addSmsTooltip: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (int i = 0; i < widget.contacts.length; i++) ...[
                              if (i > 0)
                                const Divider(height: 1, color: Color(0xFFE7EAF0)),
                              SizedBox(
                                height: 58,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: Color(0xFFE7EAF0),
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          widget.contacts[i].primaryLabel,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: _buildCheckbox(
                                          value: _configByContactId[widget.contacts[i].id]?.all ?? false,
                                          onChanged: (value) => _updateContact(
                                            widget.contacts[i].id,
                                            all: value ?? false,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: _buildCheckbox(
                                          value: _configByContactId[widget.contacts[i].id]?.email ?? true,
                                          onChanged: (value) => _updateContact(
                                            widget.contacts[i].id,
                                            email: value ?? false,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: ZTooltip(
                                          message: _smsTooltipMessage,
                                          direction: ZTooltipDirection.top,
                                          child: AbsorbPointer(
                                            child: _buildCheckbox(
                                              value: false,
                                              onChanged: null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 34),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE7EAF0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
              child: Row(
                children: [
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_configByContactId),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF22A95E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        side: const BorderSide(color: Color(0xFFD7DCE5)),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final bool isFocused;
  final bool isHovered;

  const _DashedBorderPainter({
    this.color = const Color(0xFFCBD5E1),
    // ignore: unused_element_parameter
    this.isFocused = false,
    // ignore: unused_element_parameter
    this.isHovered = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    );

    if (isFocused) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(rrect, glowPaint);

      final solidPaint = Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(rrect, solidPaint);
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dash = 4.0;
    const gap = 3.0;

    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isFocused != isFocused ||
      oldDelegate.isHovered != isHovered;
}

class SlidingCustomerDetailsCard extends StatefulWidget {
  final SalesCustomer customer;
  final Widget Function(SalesCustomer) builder;

  const SlidingCustomerDetailsCard({
    super.key,
    required this.customer,
    required this.builder,
  });

  @override
  State<SlidingCustomerDetailsCard> createState() => _SlidingCustomerDetailsCardState();
}

class _SlidingCustomerDetailsCardState extends State<SlidingCustomerDetailsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuint,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SlidingCustomerDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customer.id != widget.customer.id) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.builder(widget.customer),
    );
  }
}

