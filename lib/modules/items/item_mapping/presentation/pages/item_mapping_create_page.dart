// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/item_details_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/models/retainer_invoices_model.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/providers/retainer_invoices_provider.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/items/item_mapping/presentation/pages/item_mapping_overview_page.dart';

// ---------------------------------------------------------------------------
// Option models
// ---------------------------------------------------------------------------

class _ProductOption {
  const _ProductOption({required this.id, required this.name});
  final String id;
  final String name;
  @override
  String toString() => name;
}

class _VendorOption {
  const _VendorOption({required this.id, required this.name});
  final String id;
  final String name;
  @override
  String toString() => name;
}

class _CustomerOption {
  const _CustomerOption({required this.id, required this.name, this.category});
  final String id;
  final String name;
  final String? category;
  @override
  String toString() => name;
}

// ---------------------------------------------------------------------------
// Dev/demo fallback data (shown when DB query returns empty)
// ---------------------------------------------------------------------------

const List<_ProductOption> _dummyProductOptions = [
  _ProductOption(id: '1', name: 'Paracetamol 650mg Tablet'),
  _ProductOption(id: '2', name: 'Azithromycin 500mg Tablet'),
  _ProductOption(id: '3', name: 'Amoxicillin 250mg Capsule'),
  _ProductOption(id: '4', name: 'Cetirizine 10mg Tablet'),
  _ProductOption(id: '5', name: 'Pantoprazole 40mg Tablet'),
];

const List<_VendorOption> _dummyVendorOptions = [
  _VendorOption(id: 'demo-vendor-1', name: 'Alpha Distributors'),
  _VendorOption(id: 'demo-vendor-2', name: 'Medisource Traders'),
  _VendorOption(id: 'demo-vendor-3', name: 'CarePlus Wholesale'),
  _VendorOption(id: 'demo-vendor-4', name: 'Nova Pharma Supply'),
  _VendorOption(id: 'demo-vendor-5', name: 'Zenmed Agencies'),
];

const List<_CustomerOption> _dummyCustomerOptions = [
  _CustomerOption(id: 'coco-category', name: 'COCO', category: null),
  _CustomerOption(id: 'demo-customer-1', name: 'City Care Pharmacy', category: 'COCO'),
  _CustomerOption(id: 'demo-customer-2', name: 'Wellness Medicals', category: 'COCO'),
  _CustomerOption(id: 'foco-category', name: 'FOCO', category: null),
  _CustomerOption(id: 'demo-customer-3', name: 'Apollo Drug House', category: 'FOCO'),
  _CustomerOption(id: 'demo-customer-4', name: 'Green Cross Medicals', category: 'FOCO'),
  _CustomerOption(id: 'demo-customer-5', name: 'Prime Wellness Store', category: 'FOCO'),
];

// ---------------------------------------------------------------------------

class _VendorMapping {
  _VendorMapping({
    this.existingId,
    String vendorProductName = '',
    String vendorProductCode = '',
    this.selectedVendor,
  })  : vendorProductNameCtrl = TextEditingController(text: vendorProductName),
        vendorProductCodeCtrl = TextEditingController(text: vendorProductCode);

  final String? existingId;
  final TextEditingController vendorProductNameCtrl;
  final TextEditingController vendorProductCodeCtrl;
  _VendorOption? selectedVendor;
  bool isActive = true;
  bool autoApply = false;
  bool isSaved = false;

  void dispose() {
    vendorProductNameCtrl.dispose();
    vendorProductCodeCtrl.dispose();
  }
}

class _PurchaseOffer {
  _PurchaseOffer({String minQty = '', String offerQty = ''})
      : minQtyCtrl = TextEditingController(text: minQty),
        offerQtyCtrl = TextEditingController(text: offerQty);

  String? existingId;
  List<_VendorOption> selectedVendors = const [];
  final TextEditingController minQtyCtrl;
  final TextEditingController offerQtyCtrl;
  DateTime? validFrom;
  DateTime? validTo;
  bool isActive = true;
  bool autoApply = false;
  bool isSaved = false;

  String get schemePreview {
    final min = minQtyCtrl.text.trim();
    final offer = offerQtyCtrl.text.trim();
    if (min.isEmpty || offer.isEmpty) return '—';
    return 'Buy $min Get $offer Free';
  }

  void dispose() {
    minQtyCtrl.dispose();
    offerQtyCtrl.dispose();
  }
}

class _SalesOffer {
  _SalesOffer({String minQty = '', String offerQty = ''})
      : minQtyCtrl = TextEditingController(text: minQty),
        offerQtyCtrl = TextEditingController(text: offerQty);

  String? existingId;
  List<_CustomerOption> selectedCustomers = const [];
  final TextEditingController minQtyCtrl;
  final TextEditingController offerQtyCtrl;
  DateTime? validFrom;
  DateTime? validTo;
  bool isActive = true;
  bool autoApply = false;
  bool isSaved = false;

  String get schemePreview {
    final min = minQtyCtrl.text.trim();
    final offer = offerQtyCtrl.text.trim();
    if (min.isEmpty || offer.isEmpty) return '—';
    return 'Buy $min Get $offer Free';
  }

  void dispose() {
    minQtyCtrl.dispose();
    offerQtyCtrl.dispose();
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ItemTradeSetupCreatePage extends ConsumerStatefulWidget {
  const ItemTradeSetupCreatePage({super.key, this.editProductId});

  /// When provided the product is pre-selected (edit mode).
  final String? editProductId;

  @override
  ConsumerState<ItemTradeSetupCreatePage> createState() =>
      _ItemTradeSetupCreatePageState();
}

class _ItemTradeSetupCreatePageState
    extends ConsumerState<ItemTradeSetupCreatePage> {
  int _tabIndex = 0;
  _ProductOption? _selectedProduct;

  final List<_VendorMapping> _vendorMappings = [];
  final List<_PurchaseOffer> _purchaseOffers = [];
  final List<_SalesOffer> _salesOffers = [];

  bool _isSaving = false;
  bool _isLoadingData = false;
  bool _showItemDetails = false;
  String _selectedSidebarItemName = '';
  int _itemDetailsSidebarTabIndex = 0;

  // Pre-loaded options shown before the user types
  List<_ProductOption> _initialProducts = [];
  List<_VendorOption> _initialVendors = [];
  List<_CustomerOption> _initialCustomers = [];

  List<_ProductOption> get _allProducts {
    final list = <_ProductOption>[..._initialProducts];
    for (final dummy in _dummyProductOptions) {
      if (!list.any((p) => p.id == dummy.id)) {
        list.add(dummy);
      }
    }
    return list;
  }

  List<_VendorOption> get _allVendors {
    final list = <_VendorOption>[..._initialVendors];
    for (final dummy in _dummyVendorOptions) {
      if (!list.any((v) => v.id == dummy.id)) {
        list.add(dummy);
      }
    }
    return list;
  }

  List<_CustomerOption> get _allCustomers {
    final list = <_CustomerOption>[..._initialCustomers];
    for (final dummy in _dummyCustomerOptions) {
      if (!list.any((c) => c.id == dummy.id)) {
        list.add(dummy);
      }
    }
    return list;
  }

  bool get _isSupabaseInitialized {
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  // Date anchor keys (per row — kept global for the whole tab to avoid key conflicts)
  final _dateKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    if (widget.editProductId != null) {
      _loadProductById(widget.editProductId!);
    } else {
      // Start with one empty row so inputs are immediately visible
      _vendorMappings.add(_VendorMapping());
      _purchaseOffers.add(_PurchaseOffer());
      _salesOffers.add(_SalesOffer());
    }
    _loadInitialOptions();
  }

  @override
  void dispose() {
    for (final m in _vendorMappings) {
      m.dispose();
    }
    for (final o in _purchaseOffers) {
      o.dispose();
    }
    for (final o in _salesOffers) {
      o.dispose();
    }
    super.dispose();
  }

  // ---- Initial options pre-load ----

  Future<void> _loadInitialOptions() async {
    if (!_isSupabaseInitialized) return;
    try {
      final entityId = ref.read(entityProvider).entityId;

      // Products
      final prodRes = await Supabase.instance.client
          .from('products')
          .select('id, product_name')
          .order('product_name')
          .limit(40);
      final products = (prodRes as List<dynamic>).map((r) {
        final m = r as Map<String, dynamic>;
        return _ProductOption(
          id: m['id'] as String,
          name: m['product_name'] as String? ?? '',
        );
      }).toList();

      // Vendors
      var vendorQ = Supabase.instance.client
          .from('vendors')
          .select('id, display_name');
      if (entityId != null) vendorQ = vendorQ.eq('entity_id', entityId);
      final vendorRes = await vendorQ.order('display_name').limit(40);
      final vendors = (vendorRes as List<dynamic>).map((r) {
        final m = r as Map<String, dynamic>;
        return _VendorOption(
          id: m['id'] as String,
          name: m['display_name'] as String? ?? '',
        );
      }).toList();

      // Customers
      var custQ = Supabase.instance.client
          .from('customers')
          .select('id, display_name');
      if (entityId != null) custQ = custQ.eq('entity_id', entityId);
      final custRes = await custQ.order('display_name').limit(40);
      final customers = (custRes as List<dynamic>).map((r) {
        final m = r as Map<String, dynamic>;
        return _CustomerOption(
          id: m['id'] as String,
          name: m['display_name'] as String? ?? '',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _initialProducts = products;
          _initialVendors = vendors;
          _initialCustomers = customers;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load initial options', error: e, module: 'ItemTradeSetup');
    }
  }

  // ---- Data loading ----

  Future<void> _loadProductById(String productId) async {
    setState(() => _isLoadingData = true);
    if (!_isSupabaseInitialized) {
      final dummy = _dummyProductOptions.firstWhere(
        (p) => p.id == productId || p.id == 'demo-product-$productId',
        orElse: () => _ProductOption(id: productId, name: 'Item $productId'),
      );
      if (mounted) {
        setState(() {
          _selectedProduct = dummy;
        });
        await _loadDataForProduct(dummy.id);
      }
      return;
    }
    try {
      final m = await Supabase.instance.client
          .from('products')
          .select('id, product_name')
          .eq('id', productId)
          .single();
      final product = _ProductOption(
        id: m['id'] as String,
        name: m['product_name'] as String? ?? '',
      );
      if (mounted) {
        setState(() => _selectedProduct = product);
        await _loadDataForProduct(product.id);
      }
    } catch (e) {
      AppLogger.error('Failed to load product', error: e, module: 'ItemTradeSetup');
      final dummy = _dummyProductOptions.firstWhere(
        (p) => p.id == productId || p.id == 'demo-product-$productId',
        orElse: () => _ProductOption(id: productId, name: 'Item $productId'),
      );
      if (mounted) {
        setState(() {
          _selectedProduct = dummy;
        });
        await _loadDataForProduct(dummy.id);
      }
    }
  }

  Future<void> _loadDataForProduct(String productId) async {
    setState(() => _isLoadingData = true);
    if (!_isSupabaseInitialized) {
      for (final m in _vendorMappings) {
        m.dispose();
      }
      _vendorMappings.clear();
      _vendorMappings.add(_VendorMapping(
        vendorProductName: 'Vendor Brand of ${_selectedProduct?.name ?? "Item"}',
        vendorProductCode: 'VND-${productId.toUpperCase()}',
        selectedVendor: _dummyVendorOptions[0],
      ));

      _purchaseOffers.clear();
      _purchaseOffers.add(_PurchaseOffer(minQty: '10', offerQty: '1')..selectedVendors = [_dummyVendorOptions[0]]);

      _salesOffers.clear();
      _salesOffers.add(_SalesOffer(minQty: '20', offerQty: '2')..selectedCustomers = [_dummyCustomerOptions[0]]);

      if (mounted) setState(() => _isLoadingData = false);
      return;
    }
    try {
      // Load vendor mappings from product_vendor_mappings
      final mappingRes = await Supabase.instance.client
          .from('product_vendor_mappings')
          .select('id, mapping_name, vendor_product_code, vendor_id, vendors(id, display_name)')
          .eq('item_id', productId);

      for (final m in _vendorMappings) {
        m.dispose();
      }
      _vendorMappings.clear();

      for (final row in (mappingRes as List<dynamic>)) {
        final r = row as Map<String, dynamic>;
        final vendorMap = r['vendors'] as Map<String, dynamic>?;
        _vendorMappings.add(_VendorMapping(
          existingId: r['id'] as String?,
          vendorProductName: r['mapping_name'] as String? ?? '',
          vendorProductCode: r['vendor_product_code'] as String? ?? '',
          selectedVendor: vendorMap != null
              ? _VendorOption(
                  id: vendorMap['id'] as String,
                  name: vendorMap['display_name'] as String? ?? '',
                )
              : null,
        ));
      }

      // Purchase & Sales offers: TODO — wire up when item_purchase_offers and
      // item_sales_offers tables are created in the DB schema.

      if (mounted) setState(() => _isLoadingData = false);
    } catch (e) {
      AppLogger.error('Failed to load trade setup data', error: e, module: 'ItemTradeSetup');
      for (final m in _vendorMappings) {
        m.dispose();
      }
      _vendorMappings.clear();
      _vendorMappings.add(_VendorMapping(
        vendorProductName: 'Vendor Brand of ${_selectedProduct?.name ?? "Item"}',
        vendorProductCode: 'VND-${productId.toUpperCase()}',
        selectedVendor: _dummyVendorOptions[0],
      ));
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // ---- Product search ----

  Future<List<_ProductOption>> _searchProducts(String query) async {
    if (!_isSupabaseInitialized) {
      return _dummyProductOptions
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    try {
      final res = await Supabase.instance.client
          .from('products')
          .select('id, product_name')
          .ilike('product_name', '%$query%')
          .limit(40);
      return (res as List<dynamic>).map((r) {
        final m = r as Map<String, dynamic>;
        return _ProductOption(
          id: m['id'] as String,
          name: m['product_name'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ---- Vendor search ----

  Future<List<_VendorOption>> _searchVendors(String query) async {
    if (!_isSupabaseInitialized) {
      return _dummyVendorOptions
          .where((v) => v.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    try {
      final entityId = ref.read(entityProvider).entityId;
      var q = Supabase.instance.client
          .from('vendors')
          .select('id, display_name');
      if (entityId != null) q = q.eq('entity_id', entityId);
      final res = await q.ilike('display_name', '%$query%').limit(40);
      return (res as List<dynamic>).map((r) {
        final m = r as Map<String, dynamic>;
        return _VendorOption(
          id: m['id'] as String,
          name: m['display_name'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ---- Customer search ----

  Future<List<_CustomerOption>> _searchCustomers(String query) async {
    if (!_isSupabaseInitialized) {
      return _dummyCustomerOptions
          .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    try {
      final entityId = ref.read(entityProvider).entityId;
      var q = Supabase.instance.client
          .from('customers')
          .select('id, display_name');
      if (entityId != null) q = q.eq('entity_id', entityId);
      final res = await q.ilike('display_name', '%$query%').limit(40);
      return (res as List<dynamic>).map((r) {
        final m = r as Map<String, dynamic>;
        return _CustomerOption(
          id: m['id'] as String,
          name: m['display_name'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ---- Save ----

  Future<void> _save() async {
    if (_selectedProduct == null) {
      _showError('Please select a product first.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final productId = _selectedProduct!.id;

      // Check if any dummy option is used, or if Supabase is not initialized. If so, mock save success.
      final isDemoProduct = productId.startsWith('demo-');
      final hasDemoVendor = _vendorMappings.any((m) =>
          m.selectedVendor != null && m.selectedVendor!.id.startsWith('demo-'));

      if (!_isSupabaseInitialized || isDemoProduct || hasDemoVendor) {
        // Save vendor mapping rows
        final mappingsList = _vendorMappings
            .where((m) =>
                m.vendorProductNameCtrl.text.trim().isNotEmpty &&
                m.selectedVendor != null)
            .map((m) => {
                  'vendorName': m.selectedVendor!.name,
                  'vendorProductName': m.vendorProductNameCtrl.text.trim(),
                  'vendorProductCode': m.vendorProductCodeCtrl.text.trim(),
                  'status': m.isActive ? 'Active' : 'Inactive',
                })
            .toList();
        
        ItemTradeSetupOverviewPage.customMappings[productId] = mappingsList;

        // Save purchase offers
        final purchaseOffersList = _purchaseOffers
            .where((o) =>
                o.selectedVendors.isNotEmpty &&
                o.minQtyCtrl.text.trim().isNotEmpty &&
                o.offerQtyCtrl.text.trim().isNotEmpty)
            .map((o) => {
                  'vendorName': o.selectedVendors.map((v) => v.name).join(', '),
                  'offerScheme': o.schemePreview,
                  'validityFrom': o.validFrom != null ? DateFormat('yyyy-MM-dd').format(o.validFrom!) : '',
                  'validityTill': o.validTo != null ? DateFormat('yyyy-MM-dd').format(o.validTo!) : '',
                  'status': o.isActive ? 'Active' : 'Inactive',
                })
            .toList();
        ItemTradeSetupOverviewPage.customPurchaseOffers[productId] = purchaseOffersList;

        // Save sales offers
        final salesOffersList = _salesOffers
            .where((o) =>
                o.selectedCustomers.isNotEmpty &&
                o.minQtyCtrl.text.trim().isNotEmpty &&
                o.offerQtyCtrl.text.trim().isNotEmpty)
            .map((o) => {
                  'customerName': o.selectedCustomers.map((c) => c.name).join(', '),
                  'offerScheme': o.schemePreview,
                  'validityFrom': o.validFrom != null ? DateFormat('yyyy-MM-dd').format(o.validFrom!) : '',
                  'validityTill': o.validTo != null ? DateFormat('yyyy-MM-dd').format(o.validTo!) : '',
                  'status': o.isActive ? 'Active' : 'Inactive',
                })
            .toList();
        ItemTradeSetupOverviewPage.customSalesOffers[productId] = salesOffersList;

        final newInvoiceUI = RecurringInvoiceUI(
          id: productId,
          customerName: _selectedProduct!.name,
          date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
          amount: 0.0,
          balanceDue: 0.0,
          status: 'ACTIVE',
          drawStatus: 'ACTIVE',
          companyName: 'Demo Company',
          companyAddress: const [],
          companyGstin: '',
          companyPhone: '',
          companyEmail: '',
          billToAddress: const [],
          items: const [],
          profileName: '',
          billingFrequency: '',
          nextInvoiceDate: '',
          manuallyCreatedInvoices: 0,
          billingAddress: const [],
          shippingAddress: const [],
          childInvoices: const [],
          startDate: '',
          endDate: '',
          paymentTerms: '',
          salesperson: '',
        );
        if (!ItemTradeSetupOverviewPage.customInvoices.any((inv) => inv.id == productId)) {
          ItemTradeSetupOverviewPage.customInvoices.add(newInvoiceUI);
        }

        // Save to retainerInvoicesProvider so it updates the ItemTradeSetupReportPage list
        final newInvoice = RetainerInvoice(
          id: productId,
          invoiceNo: 'TS-${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          customerId: productId,
          customerName: _selectedProduct!.name,
          taxLabel: '',
          taxRate: 0.0,
          totalAmount: 0.0,
          amountUsed: 0.0,
          status: RetainerStatus.sent,
          notes: '',
          termsAndConditions: '',
        );
        ref.read(retainerInvoicesProvider.notifier).addInvoice(newInvoice);

        // Mark valid rows as saved so they become read-only
        for (final m in _vendorMappings) {
          if (m.vendorProductNameCtrl.text.trim().isNotEmpty && m.selectedVendor != null) {
            m.isSaved = true;
          }
        }
        for (final o in _purchaseOffers) {
          if (o.selectedVendors.isNotEmpty && o.minQtyCtrl.text.trim().isNotEmpty && o.offerQtyCtrl.text.trim().isNotEmpty) {
            o.isSaved = true;
          }
        }
        for (final o in _salesOffers) {
          if (o.selectedCustomers.isNotEmpty && o.minQtyCtrl.text.trim().isNotEmpty && o.offerQtyCtrl.text.trim().isNotEmpty) {
            o.isSaved = true;
          }
        }

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trade setup saved successfully (Demo Mode).'),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {});
        }
        return;
      }

      // Tab 1: persist vendor mappings
      await Supabase.instance.client
          .from('product_vendor_mappings')
          .delete()
          .eq('item_id', productId);

      // Only save rows that have both a vendor product name AND a vendor
      // selected — vendor_id is NOT NULL in the schema.
      final toInsert = _vendorMappings
          .where((m) =>
              m.vendorProductNameCtrl.text.trim().isNotEmpty &&
              m.selectedVendor != null)
          .map((m) => {
                'item_id': productId,
                'vendor_id': m.selectedVendor!.id,
                'mapping_name': m.vendorProductNameCtrl.text.trim(),
                'vendor_product_code':
                    m.vendorProductCodeCtrl.text.trim().isEmpty
                        ? null
                        : m.vendorProductCodeCtrl.text.trim(),
              })
          .toList();

      if (toInsert.isNotEmpty) {
        await Supabase.instance.client
            .from('product_vendor_mappings')
            .insert(toInsert);
      }

      // Mark all valid rows as saved so they become read-only
      for (final m in _vendorMappings) {
        if (m.vendorProductNameCtrl.text.trim().isNotEmpty && m.selectedVendor != null) {
          m.isSaved = true;
        }
      }
      for (final o in _purchaseOffers) {
        if (o.selectedVendors.isNotEmpty && o.minQtyCtrl.text.trim().isNotEmpty && o.offerQtyCtrl.text.trim().isNotEmpty) {
          o.isSaved = true;
        }
      }
      for (final o in _salesOffers) {
        if (o.selectedCustomers.isNotEmpty && o.minQtyCtrl.text.trim().isNotEmpty && o.offerQtyCtrl.text.trim().isNotEmpty) {
          o.isSaved = true;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trade setup saved successfully.'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {});
      }

      // Tab 2 & 3: persist purchase/sales offers when tables are ready.
    } catch (e) {
      AppLogger.error('Failed to save trade setup', error: e, module: 'ItemTradeSetup');
      if (mounted) _showError('Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---- Row helpers ----

  void _addVendorMapping() {
    setState(() => _vendorMappings.add(_VendorMapping()));
  }

  void _removeVendorMapping(int index) {
    final m = _vendorMappings.removeAt(index);
    m.dispose();
    setState(() {});
  }

  void _addPurchaseOffer() {
    setState(() => _purchaseOffers.add(_PurchaseOffer()));
  }

  void _removePurchaseOffer(int index) {
    final o = _purchaseOffers.removeAt(index);
    o.dispose();
    setState(() {});
  }

  void _addSalesOffer() {
    setState(() => _salesOffers.add(_SalesOffer()));
  }

  void _removeSalesOffer(int index) {
    final o = _salesOffers.removeAt(index);
    o.dispose();
    setState(() {});
  }

  Widget _buildRowActions({
    required bool isActive,
    required VoidCallback onToggleActive,
    required VoidCallback onDelete,
    required VoidCallback onEdit,
    VoidCallback? onHistory,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onHistory != null) ...[
          IconButton(
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            padding: EdgeInsets.zero,
            splashRadius: 14,
            icon: const Icon(LucideIcons.history, size: 14, color: AppTheme.textMuted),
            onPressed: onHistory,
          ),
          const SizedBox(width: 4),
        ],
        SizedBox(
          width: 24,
          height: 24,
          child: _SavedRowMenu(
            isActive: isActive,
            onToggleActive: onToggleActive,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
        const SizedBox(width: 28),
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
          padding: EdgeInsets.zero,
          splashRadius: 14,
          icon: const Icon(LucideIcons.trash2, size: 14, color: AppTheme.textMuted),
          onPressed: onDelete,
        ),
      ],
    );
  }

  GlobalKey _dateKey(String tag) =>
      _dateKeys.putIfAbsent(tag, () => GlobalKey());

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          if (!_isSaving) _save();
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_isSaving) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.itemTradeSetup);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: ZerpaiLayout(
          pageTitle: '',
          enableBodyScroll: false,
          useHorizontalPadding: false,
          useTopPadding: false,
          child: _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildItemSearchSection(),
                        _buildTabBar(),
                        Expanded(child: _buildTabContent()),
                        _buildFooter(),
                      ],
                    ),
                    if (_showItemDetails)
                      Positioned(
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: ItemDetailsSidebar(
                          itemName: _selectedSidebarItemName,
                          initialTabIndex: _itemDetailsSidebarTabIndex,
                          onClose: () =>
                              setState(() => _showItemDetails = false),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  // ---- Item search section ----

  Widget _buildItemSearchSection() {
    final isEdit = widget.editProductId != null;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F4),
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            isEdit ? 'Edit Trade Setup' : 'New Trade Setup',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Item Name',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 560,
                child: FormDropdown<_ProductOption>(
                  value: _selectedProduct,
                  items: _selectedProduct != null
                      ? [_selectedProduct!, ..._allProducts.where((p) => p.id != _selectedProduct!.id)]
                      : _allProducts,
                  hint: 'Search or select an item...',
                  displayStringForValue: (p) => p.name,
                  searchStringForValue: (p) => p.name,
                  onSearch: _searchProducts,
                  showSearch: true,
                  enabled: widget.editProductId == null,
                  onChanged: (v) async {
                    setState(() => _selectedProduct = v);
                    if (v != null) await _loadDataForProduct(v.id);
                  },
                ),
              ),
              if (_selectedProduct != null) ...[
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSidebarItemName = _selectedProduct!.name;
                      _itemDetailsSidebarTabIndex = 0;
                      _showItemDetails = !_showItemDetails;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selectedProduct!.name}\'s Details',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
        ),
      ),
    );
  }

  // ---- Tab bar ----

  Widget _buildTabBar() {
    const tabs = ['Item Mapping', 'Purchase Offer', 'Sales Offer'];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _tabIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _tabIndex = i),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 13),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected
                        ? AppTheme.successGreen
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.w400,
                  color: selected
                      ? Colors.black
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---- Tab content dispatcher ----

  Widget _buildTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: switch (_tabIndex) {
        0 => _buildItemMappingTab(),
        1 => _buildPurchaseOfferTab(),
        2 => _buildSalesOfferTab(),
        _ => const SizedBox.shrink(),
      },
    );
  }

  // ---- Tab 1 — Item Mapping ----

  Widget _buildItemMappingTab() {
    return _SectionCard(
      title: 'Vendor Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always-visible column header row — height matches input field height
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text('Vendor Product Name', style: _colHeaderStyle),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 28),
                    child: Text('Vendor Product Code', style: _colHeaderStyle),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 28),
                    child: Text('Vendor Name', style: _colHeaderStyle),
                  ),
                ),
                SizedBox(
                  width: 126,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Text('Actions', style: _colHeaderStyle),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_vendorMappings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Text(
                'No vendor mappings found.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            )
          else
            ...List.generate(_vendorMappings.length, (i) {
              final m = _vendorMappings[i];
              if (m.isSaved) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(m.vendorProductNameCtrl.text, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: Text(m.vendorProductCodeCtrl.text.isEmpty ? '—' : m.vendorProductCodeCtrl.text, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: Text(m.selectedVendor?.name ?? '—', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                          ),
                        ),
                        SizedBox(
                          width: 126,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildRowActions(
                                isActive: m.isActive,
                                onToggleActive: () => setState(() => m.isActive = !m.isActive),
                                onDelete: () => _removeVendorMapping(i),
                                onEdit: () => setState(() => m.isSaved = false),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _rowTextField(
                          m.vendorProductNameCtrl, 'Enter vendor product name'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _rowTextField(
                          m.vendorProductCodeCtrl, 'Enter product code'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: FormDropdown<_VendorOption>(
                        value: m.selectedVendor,
                        items: m.selectedVendor != null
                            ? [m.selectedVendor!, ..._allVendors.where((v) => v.id != m.selectedVendor!.id)]
                            : _allVendors,
                        hint: 'Select a vendor',
                        displayStringForValue: (v) => v.name,
                        searchStringForValue: (v) => v.name,
                        onSearch: _searchVendors,
                        showSearch: true,
                        onChanged: (v) => setState(
                            () => _vendorMappings[i].selectedVendor = v),
                      ),
                    ),
                    SizedBox(
                      width: 126,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _RowMenu(
                            isActive: m.isActive,
                            autoApply: m.autoApply,
                            onToggleActive: () => setState(
                                () => _vendorMappings[i].isActive =
                                    !_vendorMappings[i].isActive),
                            onToggleAutoApply: () => setState(
                                () => _vendorMappings[i].autoApply =
                                    !_vendorMappings[i].autoApply),
                            onDelete: () => _removeVendorMapping(i),
                          ),
                          const SizedBox(width: 28),
                          IconButton(
                            constraints:
                                const BoxConstraints.tightFor(width: 28, height: 28),
                            padding: EdgeInsets.zero,
                            splashRadius: 16,
                            icon: const Icon(LucideIcons.x,
                                size: 15, color: AppTheme.textMuted),
                            tooltip: 'Remove',
                            onPressed: () => _removeVendorMapping(i),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _AddRowButton(label: 'Add New Vendor', onTap: _addVendorMapping),
          ),
        ],
      ),
    );
  }

  // ---- Tab 2 — Purchase Offer ----

  Widget _buildPurchaseOfferTab() {
    return _SectionCard(
      title: 'Purchase Offer Information',
      trailing: OutlinedButton.icon(
        onPressed: _showPurchaseHistoryDialog,
        icon: const Icon(LucideIcons.history, size: 14),
        label: const Text('Purchase History'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textSecondary,
          side: const BorderSide(color: AppTheme.borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always-visible column header row
          _offerColHeader(isVendor: true),

          // Rows or empty state
          if (_purchaseOffers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Text('No purchase offers yet. Click "Add New Offer" to add one.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            )
          else
            ...List.generate(_purchaseOffers.length, (i) {
              final o = _purchaseOffers[i];
              if (o.isSaved) {
                final fromDateStr = o.validFrom != null ? DateFormat('yyyy-MM-dd').format(o.validFrom!) : '—';
                final toDateStr = o.validTo != null ? DateFormat('yyyy-MM-dd').format(o.validTo!) : '—';
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              o.selectedVendors.isEmpty
                                  ? '—'
                                  : o.selectedVendors.map((v) => v.name).join(', '),
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: Text(o.minQtyCtrl.text.isEmpty ? '—' : o.minQtyCtrl.text, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: Text(o.offerQtyCtrl.text.isEmpty ? '—' : o.offerQtyCtrl.text, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9), // Light green
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                o.schemePreview,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)), // Dark green
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 110,
                          child: Text(fromDateStr, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 110,
                          child: Text(toDateStr, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 126,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildRowActions(
                                isActive: o.isActive,
                                onToggleActive: () => setState(() => o.isActive = !o.isActive),
                                onDelete: () => _removePurchaseOffer(i),
                                onEdit: () => setState(() => o.isSaved = false),
                                onHistory: _showPurchaseHistoryDialog,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: FormDropdown<_VendorOption>(
                        value: null,
                        items: _allVendors,
                        hint: 'Select vendor…',
                        displayStringForValue: (v) => v.name,
                        searchStringForValue: (v) => v.name,
                        onSearch: _searchVendors,
                        showSearch: true,
                        multiSelect: true,
                        selectedValues: o.selectedVendors,
                        onSelectedValuesChanged: (list) =>
                            setState(() => _purchaseOffers[i].selectedVendors = list),
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 80,
                      child: _numField(o.minQtyCtrl, '0',
                          onChanged: () => setState(() {})),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 80,
                      child: _numField(o.offerQtyCtrl, '0',
                          onChanged: () => setState(() {})),
                    ),
                    const SizedBox(width: 10),
                    Expanded(flex: 3, child: _SchemePreviewField(o.schemePreview)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: _DateCell(
                        anchorKey: _dateKey('po_from_$i'),
                        date: o.validFrom,
                        placeholder: 'From date',
                        onPick: (d) =>
                            setState(() => _purchaseOffers[i].validFrom = d),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: _DateCell(
                        anchorKey: _dateKey('po_to_$i'),
                        date: o.validTo,
                        placeholder: 'To date',
                        onPick: (d) =>
                            setState(() => _purchaseOffers[i].validTo = d),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 126,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _RowMenu(
                            isActive: o.isActive,
                            autoApply: o.autoApply,
                            onToggleActive: () => setState(
                                () => _purchaseOffers[i].isActive =
                                    !_purchaseOffers[i].isActive),
                            onToggleAutoApply: () => setState(
                                () => _purchaseOffers[i].autoApply =
                                    !_purchaseOffers[i].autoApply),
                            onDelete: () => _removePurchaseOffer(i),
                          ),
                          const SizedBox(width: 28),
                          IconButton(
                            constraints:
                                const BoxConstraints.tightFor(width: 28, height: 28),
                            padding: EdgeInsets.zero,
                            splashRadius: 16,
                            icon: const Icon(LucideIcons.x,
                                size: 15, color: AppTheme.textMuted),
                            tooltip: 'Remove',
                            onPressed: () => _removePurchaseOffer(i),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _AddRowButton(label: 'Add New Offer', onTap: _addPurchaseOffer),
          ),
        ],
      ),
    );
  }

  void _onCustomerSelectionChanged(int index, List<_CustomerOption> newSelection) {
    final oldSelection = _salesOffers[index].selectedCustomers;
    
    // Find exact item toggled
    _CustomerOption? toggledItem;
    bool isAdded = false;
    for (final item in newSelection) {
      if (!oldSelection.contains(item)) {
        toggledItem = item;
        isAdded = true;
        break;
      }
    }
    if (toggledItem == null) {
      for (final item in oldSelection) {
        if (!newSelection.contains(item)) {
          toggledItem = item;
          isAdded = false;
          break;
        }
      }
    }
    
    List<_CustomerOption> result = newSelection.where((c) => c.id != 'coco-category' && c.id != 'foco-category').toList();
    
    if (toggledItem != null) {
      if (toggledItem.id == 'coco-category') {
        final cocoCompanies = _allCustomers.where((c) => c.category == 'COCO');
        if (isAdded) {
          for (final comp in cocoCompanies) {
            if (!result.contains(comp)) {
              result.add(comp);
            }
          }
        } else {
          result.removeWhere((c) => cocoCompanies.contains(c));
        }
      } else if (toggledItem.id == 'foco-category') {
        final focoCompanies = _allCustomers.where((c) => c.category == 'FOCO');
        if (isAdded) {
          for (final comp in focoCompanies) {
            if (!result.contains(comp)) {
              result.add(comp);
            }
          }
        } else {
          result.removeWhere((c) => focoCompanies.contains(c));
        }
      }
    }
    
    setState(() => _salesOffers[index].selectedCustomers = result);
  }

  // ---- Tab 3 — Sales Offer ----

  Widget _buildSalesOfferTab() {
    return _SectionCard(
      title: 'Sales Offer Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always-visible column header row
          _offerColHeader(isVendor: false),

          // Rows or empty state
          if (_salesOffers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Text('No sales offers yet. Click "Add New Offer" to add one.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            )
          else
            ...List.generate(_salesOffers.length, (i) {
              final o = _salesOffers[i];
              if (o.isSaved) {
                final fromDateStr = o.validFrom != null ? DateFormat('yyyy-MM-dd').format(o.validFrom!) : '—';
                final toDateStr = o.validTo != null ? DateFormat('yyyy-MM-dd').format(o.validTo!) : '—';
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              o.selectedCustomers.isEmpty
                                  ? '—'
                                  : o.selectedCustomers.map((c) => c.name).join(', '),
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: Text(o.minQtyCtrl.text.isEmpty ? '—' : o.minQtyCtrl.text, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: Text(o.offerQtyCtrl.text.isEmpty ? '—' : o.offerQtyCtrl.text, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9), // Light green
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                o.schemePreview,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)), // Dark green
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 110,
                          child: Text(fromDateStr, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 110,
                          child: Text(toDateStr, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 126,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildRowActions(
                                isActive: o.isActive,
                                onToggleActive: () => setState(() => o.isActive = !o.isActive),
                                onDelete: () => _removeSalesOffer(i),
                                onEdit: () => setState(() => o.isSaved = false),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: FormDropdown<_CustomerOption>(
                        value: null,
                        items: _allCustomers,
                        hint: 'Select customer…',
                        displayStringForValue: (c) => c.name,
                        searchStringForValue: (c) => c.name,
                        onSearch: _searchCustomers,
                        showSearch: true,
                        multiSelect: true,
                        selectedValues: o.selectedCustomers,
                        onSelectedValuesChanged: (list) =>
                            _onCustomerSelectionChanged(i, list),
                        onChanged: (_) {},
                        itemBuilder: (item, isSelected, isHovered) {
                          final isHeader = item.id == 'coco-category' || item.id == 'foco-category';
                          bool headerSelected = false;
                          if (item.id == 'coco-category') {
                            final cocoCompanies = _allCustomers.where((c) => c.category == 'COCO');
                            headerSelected = cocoCompanies.isNotEmpty && cocoCompanies.every((c) => o.selectedCustomers.contains(c));
                          } else if (item.id == 'foco-category') {
                            final focoCompanies = _allCustomers.where((c) => c.category == 'FOCO');
                            headerSelected = focoCompanies.isNotEmpty && focoCompanies.every((c) => o.selectedCustomers.contains(c));
                          }
                          final effectiveSelected = isHeader ? headerSelected : isSelected;
                          return Container(
                            height: 38,
                            color: isHovered
                                ? const Color(0xFF3B82F6)
                                : (effectiveSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(left: isHeader ? 12.0 : 28.0),
                            child: Row(
                              children: [
                                if (effectiveSelected) ...[
                                  Icon(
                                    LucideIcons.check,
                                    size: 14,
                                    color: isHovered ? Colors.white : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                                    color: isHovered
                                        ? Colors.white
                                        : (effectiveSelected ? AppTheme.textPrimary : (isHeader ? AppTheme.textPrimary : AppTheme.textSecondary)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 80,
                      child: _numField(o.minQtyCtrl, '0',
                          onChanged: () => setState(() {})),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 80,
                      child: _numField(o.offerQtyCtrl, '0',
                          onChanged: () => setState(() {})),
                    ),
                    const SizedBox(width: 10),
                    Expanded(flex: 3, child: _SchemePreviewField(o.schemePreview)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: _DateCell(
                        anchorKey: _dateKey('so_from_$i'),
                        date: o.validFrom,
                        placeholder: 'From date',
                        onPick: (d) =>
                            setState(() => _salesOffers[i].validFrom = d),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: _DateCell(
                        anchorKey: _dateKey('so_to_$i'),
                        date: o.validTo,
                        placeholder: 'To date',
                        onPick: (d) =>
                            setState(() => _salesOffers[i].validTo = d),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 126,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _RowMenu(
                            isActive: o.isActive,
                            autoApply: o.autoApply,
                            onToggleActive: () => setState(
                                () => _salesOffers[i].isActive =
                                    !_salesOffers[i].isActive),
                            onToggleAutoApply: () => setState(
                                () => _salesOffers[i].autoApply =
                                    !_salesOffers[i].autoApply),
                            onDelete: () => _removeSalesOffer(i),
                          ),
                          const SizedBox(width: 28),
                          IconButton(
                            constraints:
                                const BoxConstraints.tightFor(width: 28, height: 28),
                            padding: EdgeInsets.zero,
                            splashRadius: 16,
                            icon: const Icon(LucideIcons.x,
                                size: 15, color: AppTheme.textMuted),
                            tooltip: 'Remove',
                            onPressed: () => _removeSalesOffer(i),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _AddRowButton(label: 'Add New Offer', onTap: _addSalesOffer),
          ),
        ],
      ),
    );
  }

  // ---- Offer column header (shared by Purchase + Sales Offer tabs) ----

  Widget _offerColHeader({required bool isVendor}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                isVendor ? 'Vendor Name' : 'Customer Name',
                style: _colHeaderStyle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const SizedBox(
            width: 80,
            child: Text('Min Qty', style: _colHeaderStyle),
          ),
          const SizedBox(width: 10),
          const SizedBox(
            width: 80,
            child: Text('Offer Qty', style: _colHeaderStyle),
          ),
          const SizedBox(width: 10),
          const Expanded(
            flex: 3,
            child: Text('Scheme Preview', style: _colHeaderStyle),
          ),
          const SizedBox(width: 10),
          const SizedBox(
            width: 110,
            child: Text('Valid From', style: _colHeaderStyle),
          ),
          const SizedBox(width: 10),
          const SizedBox(
            width: 110,
            child: Text('Valid To', style: _colHeaderStyle),
          ),
          const SizedBox(
            width: 126,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('Actions', style: _colHeaderStyle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Footer ----

  Widget _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isSaving
                ? null
                : () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.itemTradeSetup),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textBody,
              side: const BorderSide(color: AppTheme.borderColor),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              textStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppTheme.successGreen.withOpacity(0.6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              elevation: 0,
              textStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseHistoryDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(top: 0, left: 16, right: 16),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            width: 640,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F3F4),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Purchase History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                        padding: EdgeInsets.zero,
                        splashRadius: 16,
                        icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Table Container
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          color: const Color(0xFFF9FAFB),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text('Vendor Name', style: _colHeaderStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Latest Rate', style: _colHeaderStyle),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('Last Purchased Date', style: _colHeaderStyle),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('Offer', style: _colHeaderStyle),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        // Data Rows
                        _buildHistoryRow(
                          vendor: 'Global Supplies Co.',
                          rate: '\$245.00',
                          date: 'Oct 12, 2023',
                          offer: '10% Off Bulk',
                          isOfferGreen: true,
                        ),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        _buildHistoryRow(
                          vendor: 'Metro Distributors',
                          rate: '\$238.50',
                          date: 'Sep 28, 2023',
                          offer: 'N/A',
                          isOfferGreen: false,
                        ),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        _buildHistoryRow(
                          vendor: 'Elite Parts Ltd.',
                          rate: '\$250.00',
                          date: 'Aug 15, 2023',
                          offer: 'Free Shipping',
                          isOfferGreen: true,
                        ),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        _buildHistoryRow(
                          vendor: 'Sunrise Trading',
                          rate: '\$242.00',
                          date: 'Jul 02, 2023',
                          offer: '5% Seasonal',
                          isOfferGreen: false,
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F3F4),
                    border: Border(
                      top: BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007A3E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Close',
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
        );
      },
    );
  }

  Widget _buildHistoryRow({
    required String vendor,
    required String rate,
    required String date,
    required String offer,
    required bool isOfferGreen,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              vendor,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              rate,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              date,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              offer,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isOfferGreen ? FontWeight.w600 : FontWeight.normal,
                color: isOfferGreen ? const Color(0xFF22A95E) : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// Small helper widgets
// ---------------------------------------------------------------------------

const _colHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: Color(0xFF5A607F),
  letterSpacing: 0.4,
);

Widget _rowTextField(TextEditingController ctrl, String hint) =>
    TextFormField(
      controller: ctrl,
      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
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
          borderSide:
              const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
      ),
    );

Widget _numField(TextEditingController ctrl, String hint,
        {VoidCallback? onChanged}) =>
    TextFormField(
      controller: ctrl,
      onChanged: onChanged != null ? (_) => onChanged() : null,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
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
          borderSide:
              const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Vendor row ⋮ menu
// ---------------------------------------------------------------------------

class _RowMenu extends StatefulWidget {
  const _RowMenu({
    required this.isActive,
    required this.autoApply,
    required this.onToggleActive,
    required this.onToggleAutoApply,
    required this.onDelete,
  });

  final bool isActive;
  final bool autoApply;
  final VoidCallback onToggleActive;
  final VoidCallback onToggleAutoApply;
  final VoidCallback onDelete;

  @override
  State<_RowMenu> createState() => _RowMenuState();
}

class _RowMenuState extends State<_RowMenu> {
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(4),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 4)),
      ),
      menuChildren: [
        // Active / Inactive
        MenuItemButton(
          onPressed: () {
            _controller.close();
            widget.onToggleActive();
          },
          leadingIcon: Icon(
            widget.isActive
                ? LucideIcons.toggleRight
                : LucideIcons.toggleLeft,
            size: 16,
            color: widget.isActive
                ? AppTheme.successGreen
                : AppTheme.textMuted,
          ),
          child: Text(
            widget.isActive ? 'Active' : 'Inactive',
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textPrimary),
          ),
        ),
        // Enable Auto-Apply
        MenuItemButton(
          onPressed: () {
            _controller.close();
            widget.onToggleAutoApply();
          },
          leadingIcon: Icon(
            LucideIcons.zap,
            size: 16,
            color: widget.autoApply
                ? AppTheme.primaryBlue
                : AppTheme.textMuted,
          ),
          child: Text(
            widget.autoApply ? 'Auto-Apply On' : 'Enable Auto-Apply',
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textPrimary),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
        // Delete
        MenuItemButton(
          onPressed: () {
            _controller.close();
            widget.onDelete();
          },
          leadingIcon: const Icon(LucideIcons.trash2,
              size: 16, color: AppTheme.errorRed),
          child: const Text(
            'Delete',
            style: TextStyle(fontSize: 13, color: AppTheme.errorRed),
          ),
        ),
      ],
      child: IconButton(
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        padding: EdgeInsets.zero,
        splashRadius: 16,
        icon: const Icon(LucideIcons.moreVertical,
            size: 15, color: AppTheme.textMuted),
        tooltip: 'Options',
        onPressed: () => _controller.open(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saved row ⋮ menu
// ---------------------------------------------------------------------------

class _SavedRowMenu extends StatefulWidget {
  const _SavedRowMenu({
    required this.isActive,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final bool isActive;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_SavedRowMenu> createState() => _SavedRowMenuState();
}

class _SavedRowMenuState extends State<_SavedRowMenu> {
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(4),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 4)),
      ),
      menuChildren: [
        // Edit Record
        MenuItemButton(
          onPressed: () {
            _controller.close();
            widget.onEdit();
          },
          leadingIcon: const Icon(
            LucideIcons.edit2,
            size: 16,
            color: AppTheme.textPrimary,
          ),
          child: const Text(
            'Edit Record',
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
        ),
        // Active/Inactive
        MenuItemButton(
          onPressed: () {
            _controller.close();
            widget.onToggleActive();
          },
          leadingIcon: Icon(
            widget.isActive
                ? LucideIcons.toggleRight
                : LucideIcons.toggleLeft,
            size: 16,
            color: widget.isActive
                ? AppTheme.successGreen
                : AppTheme.textMuted,
          ),
          child: const Text(
            'Active/Inactive',
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
        // Delete
        MenuItemButton(
          onPressed: () {
            _controller.close();
            widget.onDelete();
          },
          leadingIcon: const Icon(LucideIcons.trash2,
              size: 16, color: AppTheme.errorRed),
          child: const Text(
            'Delete',
            style: TextStyle(fontSize: 13, color: AppTheme.errorRed),
          ),
        ),
      ],
      child: IconButton(
        constraints: const BoxConstraints.tightFor(width: 24, height: 24),
        padding: EdgeInsets.zero,
        splashRadius: 14,
        icon: const Icon(LucideIcons.moreVertical,
            size: 14, color: AppTheme.textMuted),
        onPressed: () => _controller.open(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scheme preview field (read-only input-style box)
// ---------------------------------------------------------------------------

class _SchemePreviewField extends StatelessWidget {
  const _SchemePreviewField(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final isEmpty = label == '—';
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        isEmpty ? 'Scheme details...' : label,
        style: TextStyle(
          fontSize: 13,
          color: isEmpty ? AppTheme.textMuted : AppTheme.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date cell
// ---------------------------------------------------------------------------

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.anchorKey,
    required this.date,
    required this.onPick,
    this.placeholder,
  });

  final GlobalKey anchorKey;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    final label = hasDate
        ? '${date!.month.toString().padLeft(2, '0')}/${date!.day.toString().padLeft(2, '0')}/${date!.year.toString().padLeft(4, '0')}'
        : 'mm/dd/yyyy';

    return GestureDetector(
      onTap: () async {
        final picked = await ZerpaiDatePicker.show(
          context,
          initialDate: date ?? DateTime.now(),
          targetKey: anchorKey,
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        key: anchorKey,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: hasDate ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.calendar,
                size: 13, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add row button
// ---------------------------------------------------------------------------

class _AddRowButton extends StatelessWidget {
  const _AddRowButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.plusCircle,
              size: 15, color: AppTheme.successGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.successGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
