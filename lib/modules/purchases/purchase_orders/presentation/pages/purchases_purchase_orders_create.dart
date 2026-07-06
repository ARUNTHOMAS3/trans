// ignore_for_file: unused_element_parameter
import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/z_adaptive_menu.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/providers/purchases_purchase_orders_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/widgets/vendor_sidebar.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/po_item_details_sidebar_widget.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/repositories/vendor_repository_impl.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/purchases_vendors_vendor_create.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';

import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/shared/widgets/hsn_sac_search_modal.dart';
import 'package:zerpai_erp/modules/sales/models/hsn_sac_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/sales_item_quick_edit_dialog.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/providers/pricelist_provider.dart';
import 'package:zerpai_erp/modules/pricelists/branch_pricelist/providers/branch_pricelist_provider.dart';
import 'package:zerpai_erp/modules/pricelists/branch_pricelist/models/branch_pricelist_model.dart';
import 'package:hive/hive.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';

import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/advanced_vendor_search_dialog.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/advanced_customer_search_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/address_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/warehouse_popover.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_payment_terms_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_list_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';

import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import '../../notifiers/purchase_order_notifier.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/manage_tds_tcs_rates_dialog.dart';
import 'package:zerpai_erp/modules/inventory/providers/stock_provider.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'dart:convert';

import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/purchase_requests_items_dialog.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/items_stock_providers.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';

// ── Zoho-style Colors ────────────────────────────────────────────────────────
const _bgWhite = Color(0xFFFFFFFF);
const _borderCol = Color(0xFFE5E7EB);
const _fieldBorder = Color(0xFFD1D5DB);
const _labelColor = Color(0xFF6B7280);
const _requiredLabel = Color(0xFFEF4444);
const _hintColor = Color(0xFF6B7280);
const _textPrimary = Color(0xFF111827);
const _linkBlue = Color(0xFF0088FF);
const _greenBtn = Color(0xFF10B981);
const _dangerRed = Color(0xFFEF4444);

// ── Extension ────────────────────────────────────────────────────────────────

// ── Row Controller ───────────────────────────────────────────────────────────
class _ItemRowController {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();
  final TextEditingController discountCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final FocusNode rateFocus = FocusNode();
  final FocusNode qtyFocus = FocusNode();
  final FocusNode discountFocus = FocusNode();
  Map<String, String> reportingTags = {
    'adgf': 'None',
    'schedule': 'None',
    'demo_tag': 'None',
  };
  final LayerLink nameLink = LayerLink();
  final LayerLink taxLink = LayerLink();
  final LayerLink accountLink = LayerLink();
  final LayerLink discountLink = LayerLink();
  final LayerLink discountTypeLink = LayerLink();
  final LayerLink itemDiscountAccountLink = LayerLink();
  final LayerLink warehouseSelectionLink = LayerLink();
  final LayerLink hsnLink = LayerLink();
  final LayerLink itemDetailsMenuLink = LayerLink();
  final LayerLink rowActionsMenuLink = LayerLink();
  final LayerLink priceListLink = LayerLink();
  final LayerLink reportingTagsLink = LayerLink();

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    rateCtrl.dispose();
    discountCtrl.dispose();
    descCtrl.dispose();
    rateFocus.dispose();
    qtyFocus.dispose();
    discountFocus.dispose();
  }
}

// ── Address line helper ───────────────────────────────────────────────────────
class _AddrLine {
  final String text;
  final bool isBold;
  final bool isCity; // shown in reddish color inside the popover
  final bool isPhone; // shown in dark/label color
  const _AddrLine(
    this.text, {
    this.isBold = false,
    this.isCity = false,
    this.isPhone = false,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═════════════════════════════════════════════════════════════════════════════
class PurchaseOrderCreateScreen extends ConsumerStatefulWidget {
  final PurchaseOrder? initialOrder;
  final String? initialOrderId;
  final bool isClone;

  const PurchaseOrderCreateScreen({
    super.key,
    this.initialOrder,
    this.initialOrderId,
    this.isClone = false,
  });

  @override
  ConsumerState<PurchaseOrderCreateScreen> createState() => _POCreateState();
}

class _POCreateState extends ConsumerState<PurchaseOrderCreateScreen> {
  final _poNumberCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _orderDateCtrl = TextEditingController();
  final _deliveryDateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _adjustmentCtrl = TextEditingController();
  final _adjustmentLabelCtrl = TextEditingController();
  final FocusNode _adjustmentLabelFocusNode = FocusNode();
  final _deliveryNameCtrl = TextEditingController(); // Editable warehouse name
  final GlobalKey _orderDateFieldKey = GlobalKey();
  final GlobalKey _deliveryDateFieldKey = GlobalKey();

  OverlayEntry? _gstOverlay;
  OverlayEntry? _gstinOverlay;
  OverlayEntry? _poOverlay;
  OverlayEntry? _vendorSidebarOverlay;
  OverlayEntry? _deliveryOverlay; // "Change destination" popover
  OverlayEntry? _taxOverlay;
  OverlayEntry? _accountOverlay;
  OverlayEntry? _discountOverlay;
  int? _activeDiscountRowIndex;
  int? _activeTaxRowIndex;
  int? _activeAccountRowIndex;
  int? _activeMenuRowIndex;
  OverlayEntry? _hsnOverlay;
  OverlayEntry? _addRowDropdownOverlay;
  final LayerLink _addRowDropdownLink = LayerLink();
  OverlayEntry? _uploadOverlay;
  final LayerLink _uploadLink = LayerLink();
  OverlayEntry? _itemMenuOverlay;
  final LayerLink _gstLink = LayerLink();
  final LayerLink _gstinLink = LayerLink();
  final LayerLink _poLink = LayerLink();
  final LayerLink _deliveryChangeLink = LayerLink();
  final LayerLink _totalTaxAmountLink = LayerLink();
  final LayerLink _discountTypeLink = LayerLink();
  final LayerLink _attachmentBadgeLink = LayerLink();
  final LayerLink _billingAddressLink = LayerLink();
  final LayerLink _shippingAddressLink = LayerLink();
  OverlayEntry? _addressDropdownOverlay;
  OverlayEntry? _taxAmountOverlay;
  OverlayEntry? _attachmentListOverlay;
  List<PlatformFile> _attachedFiles = [];
  List<Map<String, dynamic>> _tdsRatesList = [];
  bool _isLoadingTdsRates = false;
  Future<void>? _loadTdsFuture;
  List<Map<String, dynamic>> _tdsSectionsList = [];
  List<Map<String, dynamic>> _tdsGroupsList = [];
  List<Map<String, dynamic>> _tcsRatesList = [];
  List<Map<String, dynamic>> _tcsNaturesList = [];
  OverlayEntry? _tdsOverlay;
  bool _isTdsOpen = false;
  final LayerLink _tdsLink = LayerLink();
  final List<_ItemRowController> _rowControllers = [];
  final Set<int> _hiddenDetails = {};
  final Set<int> _hoveredRows = {};
  final Map<int, TextEditingController> _headerTextControllers = {};
  bool _bulkMode = false;
  final Set<int> _selectedRows = {};
  String _stockView = 'availableForSale'; // 'stockOnHand' | 'availableForSale'
  String _stockType = 'Physical'; // 'Physical' | 'Accounting'
  bool _showStockInfo = true;
  bool _showRecentTransactions = true;
  bool _showPriceList = true;
  String? _selectedPriceListId;
  bool _isUploadButtonHovered = false;
  bool _isVendorSidebarLoading = false;
  OverlayEntry? _valueTooltipOverlay;
  OverlayEntry? _reportingTagsOverlay;
  final LayerLink _priceListTooltipLink = LayerLink();
  bool _isAdjustmentLabelHovered = false;
  bool _isSavingDraft = false;
  bool _isSavingOpen = false;
  // Item table search
  bool _showSearchItemDetails = false;
  String _itemDetailsSearchQuery = '';
  final TextEditingController _itemDetailsSearchCtrl = TextEditingController();

  AccountNode? _selectedPopupAccount;

  String _getCurrencyLabel(String code) {
    final option = defaultCurrencyOptions.firstWhere(
      (c) => c.code == code,
      orElse: () => defaultCurrencyOptions.first,
    );
    return option.label;
  }

  Widget _buildBulkButton(String label, {required VoidCallback onTap}) {
    return Container(
      height: 28,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: Colors.white,
          foregroundColor: _linkBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildUpdateAccountDialog(List<AccountNode> availableAccounts) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
      child: StatefulBuilder(
        builder: (context, dialogSetState) {
          return Container(
            width: 600,
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                  child: Row(
                    children: [
                      const Text(
                        'Select Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: AppTheme.errorRed,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderColor),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        const Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FormDropdown<AccountNode>(
                            height: 32,
                            value: _selectedPopupAccount,
                            items: _buildNestedAccountsList(availableAccounts),
                            isItemEnabled: (v) => !v.id.startsWith('header_'),
                            displayStringForValue: (v) => v.id.startsWith('header_') ? v.accountType : v.name,
                            hint: 'Select an account',
                            onChanged: (v) {
                              if (v != null && v.id.startsWith('header_')) return;
                              dialogSetState(() {
                                _selectedPopupAccount = v;
                              });
                              setState(() {
                                _selectedPopupAccount = v;
                              });
                            },
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _fieldBorder),
                            itemBuilder: (account, isSelected, isHovered) {
                              if (account.id.startsWith('header_')) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    account.accountType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                );
                              }
                              final depth = _getAccountDepth(account, availableAccounts);
                              final name = depth == 0
                                  ? (account.systemAccountName.isNotEmpty
                                      ? account.systemAccountName
                                      : account.name)
                                  : account.name;
                              return _buildStandardLookupRow(
                                name,
                                isSelected,
                                isHovered,
                                indentation: 20.0 + (depth * 16.0),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: AppTheme.borderColor),

                // Footer
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final notifier = ref.read(
                            purchaseOrderFormNotifierProvider.notifier,
                          );
                          final poState = ref.read(
                            purchaseOrderFormNotifierProvider,
                          );
                          for (int i = 0; i < poState.items.length; i++) {
                            final item = poState.items[i];
                            if (item.productId.isNotEmpty && !item.isHeader) {
                              notifier.updateItem(
                                i,
                                item.copyWith(
                                  accountId: _selectedPopupAccount?.id,
                                  accountName: _selectedPopupAccount?.name,
                                ),
                              );
                            }
                          }
                          context.pop();
                          setState(() {
                            _bulkMode = false;
                            _selectedRows.clear();
                            _selectedPopupAccount = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745), // Success Green
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
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
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNewVendorDialog() async {
    final newVendor = await showDialog<Vendor>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.only(
          top: 0,
          bottom: 24,
          left: 40,
          right: 40,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const PurchasesVendorsVendorCreateScreen(isDialog: true),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (newVendor != null) {
      _selectVendor(newVendor, ref.read(purchaseOrderFormNotifierProvider.notifier));
    }
  }

  // Lookup lists
  List<Map<String, dynamic>> _paymentTermsList = [];
  String? _defaultPaymentTermId;
  List<Map<String, dynamic>> _shipmentPreferencesList = [];
  List<String> _sourceOfSupplyList = [];
  // ignore: unused_field
  List<String> _phoneCodesList = [];
  // ignore: unused_field
  Map<String, String> _phoneCodeToLabel = {};
  Map<String, String> _stateIdToName = {};
  Map<String, String> _countryIdToName = {};

  Future<void> _loadPaymentTerms() async {
    try {
      final lookupsService = LookupsApiService();
      final terms = await lookupsService.getPaymentTerms();
      final dbDefaultId = await lookupsService.getDefaultPaymentTermId();
      if (mounted) {
        setState(() {
          _paymentTermsList = terms;
          _defaultPaymentTermId = dbDefaultId;
          
          final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
          final poState = ref.read(purchaseOrderFormNotifierProvider);
          if (poState.paymentTerms == null && terms.isNotEmpty) {
            final hasDefault = terms.any((t) => t['id']?.toString() == dbDefaultId);
            if (hasDefault) {
              notifier.updateField(paymentTerms: dbDefaultId);
            } else {
              final net30 = terms.firstWhere(
                (t) => t['term_name'] == 'Net 30',
                orElse: () => terms.first,
              );
              notifier.updateField(paymentTerms: net30['id']?.toString());
            }
          }
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error loading payment terms',
        error: e,
        module: 'purchases',
      );
    }
  }

  Future<void> _loadShipmentPreferences() async {
    try {
      final lookupsService = LookupsApiService();
      final preferences = await lookupsService.getShipmentPreferences();
      if (mounted) {
        setState(() {
          _shipmentPreferencesList = preferences;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error loading shipment preferences',
        error: e,
        module: 'purchases',
      );
    }
  }

  Future<void> _loadTdsRates() async {
    if (_isLoadingTdsRates) {
      await _loadTdsFuture;
      return;
    }
    _isLoadingTdsRates = true;
    _loadTdsFuture = _performLoadTdsRates();
    await _loadTdsFuture;
    _isLoadingTdsRates = false;
  }

  Future<void> _performLoadTdsRates() async {
    try {
      final lookupsService = LookupsApiService();
      final rates = await lookupsService.getTdsRates();
      final sections = await lookupsService.getTdsSections();
      final tcsRates = await lookupsService.getTcsRates();
      final tcsNatures = await lookupsService.getTcsNatures();
      final groups = await lookupsService.getTdsGroups();
      if (mounted) {
        setState(() {
          _tdsRatesList = rates;
          _tdsSectionsList = sections;
          _tcsRatesList = tcsRates;
          _tcsNaturesList = tcsNatures;
          _tdsGroupsList = groups;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error loading TDS/TCS rates',
        error: e,
        module: 'purchases',
      );
    }
  }

  Future<void> _handleSave(
    PurchaseOrderState poState, {
    String status = 'Draft',
  }) async {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

    // Basic validation
    if (poState.vendorId == null || poState.vendorId!.isEmpty) {
      ZerpaiToast.error(context, 'Please select a vendor');
      return;
    }

    final vendorsState = ref.read(vendorProvider);
    final vendor = vendorsState.vendors.firstWhere(
      (v) => v.id == poState.vendorId,
      orElse: () => Vendor(id: '', displayName: ''),
    );

    String? billingAddressId;
    final currentAddr = vendor.billingAddress;
    if (currentAddr != null) {
      if (currentAddr['id'] != null) {
        billingAddressId = currentAddr['id'].toString();
      } else if (vendor.vendorAddresses != null) {
        for (final addr in vendor.vendorAddresses!) {
          if (_areAddressesEqual(addr, currentAddr)) {
            billingAddressId = addr['id']?.toString();
            break;
          }
        }
      }
    }

    if (billingAddressId == null || billingAddressId.isEmpty) {
      ZerpaiToast.error(context, 'Billing address is mandatory');
      return;
    }

    final validItems = poState.items
        .where((i) => (i.productId.isNotEmpty && i.productId != '__header__') || i.isHeader)
        .toList();
    if (validItems.isEmpty) {
      ZerpaiToast.error(context, 'Please add at least one item');
      return;
    }

    // New validations for HSN Code, Account, and Quantity
    for (int i = 0; i < validItems.length; i++) {
      final item = validItems[i];
      if (item.isHeader) {
        if (item.headerText == null || item.headerText!.trim().isEmpty) {
          ZerpaiToast.error(context, 'Please enter a value for header at row ${i + 1}');
          return;
        }
        continue;
      }
      if (item.quantity <= 0) {
        ZerpaiToast.error(context, 'Please enter a valid quantity for item ${i + 1}');
        return;
      }
      if (item.hsnCode == null || item.hsnCode!.isEmpty) {
        ZerpaiToast.error(context, 'Please select HSN Code for item ${i + 1}');
        return;
      }
      if (item.accountId == null || item.accountId!.isEmpty) {
        ZerpaiToast.error(
          context,
          'Please select Account for item ${i + 1} (${item.productName ?? 'Product'})',
        );
        return;
      }
    }

    if (!poState.isNumberingAuto && poState.orderNumber.trim().isEmpty) {
      ZerpaiToast.error(context, 'Purchase Order# is required in manual mode');
      return;
    }

    setState(() {
      if (status == 'Draft') {
        _isSavingDraft = true;
      } else {
        _isSavingOpen = true;
      }
    });
    notifier.updateField(isSaving: true);

    // Save to repository and get the saved object with its ID
    PurchaseOrder? savedPo;

    try {
      final lookupsService = LookupsApiService();

      // 1. Sync Shipment Preference if it's new
      final isExistingId = _shipmentPreferencesList.any(
        (p) => p['id']?.toString() == poState.shipmentPreference,
      );

      if (!isExistingId &&
          poState.shipmentPreference != null &&
          poState.shipmentPreference!.isNotEmpty) {
        final exists = _shipmentPreferencesList.any(
          (p) =>
              p['name']?.toString().toLowerCase() ==
              poState.shipmentPreference!.toLowerCase(),
        );

        if (!exists) {
          AppLogger.info(
            'Saving new global shipment preference',
            data: {'value': poState.shipmentPreference},
            module: 'purchases',
          );
          await lookupsService.syncShipmentPreferences([
            {'name': poState.shipmentPreference, 'is_active': true},
          ]);
          await _loadShipmentPreferences();
        }
      }

      // 2. Prepare PO Model
      // Find shipment preference ID if it's a name
      String? shipmentPreferenceId = poState.shipmentPreference;
      if (!isExistingId &&
          poState.shipmentPreference != null &&
          poState.shipmentPreference!.isNotEmpty) {
        final selectedPref = _shipmentPreferencesList.firstWhere(
          (p) => p['name'] == poState.shipmentPreference,
          orElse: () => <String, dynamic>{},
        );
        if (selectedPref.containsKey('id')) {
          shipmentPreferenceId = selectedPref['id'] as String?;
        }
      }

      final activePriceLists = _getCombinedPriceLists();

      final updatedItems = poState.items
          .where((i) => i.productId.isNotEmpty && !i.isHeader)
          .map((item) {
            final pl = activePriceLists
                .where((p) => p.id == item.priceListId)
                .firstOrNull;
            return item.copyWith(pricelist: pl?.name);
          })
          .toList();

      final double totalQty = updatedItems.fold<double>(0.0, (sum, item) => sum + item.quantity);
      final double calculatedTdsTcsAmount = poState.tdsTcsAmount;

      final vendorsState = ref.read(vendorProvider);
      final vendor = vendorsState.vendors.firstWhere(
        (v) => v.id == poState.vendorId,
        orElse: () => Vendor(id: '', displayName: ''),
      );

      String? findAddressId(Map<String, dynamic>? currentAddr) {
        if (currentAddr == null) return null;
        if (currentAddr['id'] != null) return currentAddr['id'].toString();
        if (vendor.vendorAddresses != null) {
          for (final addr in vendor.vendorAddresses!) {
            if (_areAddressesEqual(addr, currentAddr)) {
              return addr['id']?.toString();
            }
          }
        }
        return null;
      }

      final billingAddressId = findAddressId(vendor.billingAddress);
      final shippingAddressId = findAddressId(vendor.shippingAddress);

      final po = PurchaseOrder(
        id: _editingOrderId,
        orderNumber: poState.orderNumber,
        orderDate: poState.orderDate,
        expectedDeliveryDate: poState.expectedDeliveryDate,
        referenceNumber: poState.referenceNumber,
        vendorId: poState.vendorId!,
        paymentTerms: poState.paymentTerms,
        shipmentPreference: shipmentPreferenceId,
        deliveryType: poState.deliveryType,
        deliveryWarehouseId: poState.deliveryWarehouseId,
        deliveryCustomerId: poState.deliveryCustomerId,
        warehouseId: poState.warehouseId,
        subTotal: poState.subTotal,
        taxAmount: poState.taxAmount,
        discount: poState.discount,
        discountType: poState.discountType,
        tdsTcsType: poState.tdsTcsType ?? 'none',
        tdsTcsId: poState.tdsTcsId,
        tdsTcsAmount: calculatedTdsTcsAmount,
        adjustment: poState.adjustment,
        total: poState.total,
        status: status,
        notes: _notesCtrl.text,
        termsAndConditions: _termsCtrl.text,
        isReverseCharge: poState.isReverseCharge,
        discountLevel: poState.discountLevel,
        discountAccountId: poState.discountAccountId,
        taxType: poState.taxType,
        isDelete: false,
        totalQuantity: totalQty,
        items: updatedItems,
        sourceOfSupply: vendor.sourceOfSupply,
        destinationToSupply: poState.destinationOfSupply.isNotEmpty ? poState.destinationOfSupply : '[KL] - Kerala',
        shippingAddressId: shippingAddressId,
        billingAddressId: billingAddressId,
      );

      // 3. Save to Backend
      final repository = ref.read(purchaseOrderRepositoryProvider);
      if (_isEditMode && _editingOrderId != null) {
        savedPo = await repository.updatePurchaseOrder(_editingOrderId!, po);
      } else {
        savedPo = await repository.createPurchaseOrder(po);
      }

      // 4. Save Attachments if any
      if (savedPo != null && savedPo.id != null && _attachedFiles.isNotEmpty) {
        await _saveAttachments(savedPo.id!);
      }

      if (mounted) {
        final targetId = savedPo?.id ?? _editingOrderId;
        if (targetId != null) {
          ref.invalidate(purchaseOrderProvider(targetId));
        }
        ref.invalidate(purchaseOrdersProvider);
        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));

        ZerpaiToast.success(
          context,
          _isEditMode
              ? 'Purchase Order updated successfully'
              : 'Purchase Order saved successfully',
        );
        if (_isEditMode) {
          final id = savedPo?.id ?? _editingOrderId;
          if (status == 'Draft') {
            context.go('/purchases/purchase-orders/$id');
          } else if (savedPo != null && savedPo.id != null) {
            context.go('/purchases/purchase-orders/${savedPo.id}/email');
          } else {
            context.go('/purchases/purchase-orders/$id');
          }
        } else {
          if (status == 'Draft') {
            context.go('/purchases/purchase-orders');
          } else if (savedPo != null && savedPo.id != null) {
            context.go('/purchases/purchase-orders/${savedPo.id}/email');
          } else {
            context.go('/purchases/purchase-orders');
          }
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error saving purchase order',
        error: e,
        module: 'purchases',
      );
      if (mounted) {
        ZerpaiToast.error(context, 'Error saving PO: $e');
      }
    } finally {
      notifier.updateField(isSaving: false);
      if (mounted) {
        setState(() {
          _isSavingDraft = false;
          _isSavingOpen = false;
        });
      }
    }
  }

  Future<void> _saveAttachments(String poId) async {
    try {
      final supabase = Supabase.instance.client;
      final apiClient = ApiClient();
      var entityId = ref.read(entityProvider).entityId;
      if (entityId == null) {
        final user = ref.read(authUserProvider);
        entityId = user?.orgEntityId;
      }
      if (entityId == null) return;

      for (var file in _attachedFiles) {
        if (file.bytes == null) {
          AppLogger.warning(
            'Skipping file ${file.name} because bytes are null',
            module: 'purchases',
          );
          continue;
        }

        final base64Data = base64Encode(file.bytes!);

        // Upload to Cloudflare R2 via backend
        final response = await apiClient.post(
          '/lookups/uploads',
          data: {
            'fileName': file.name,
            'fileData': base64Data,
            'mimeType': 'application/octet-stream',
            'prefix': 'purchase_orders',
          },
        );

        final fileKey =
            response.data['fileKey'] ?? 'purchase_orders/${file.name}';

        final double sizeInKb = file.size / 1024;
        final String formattedSize = sizeInKb >= 1024
            ? '${(sizeInKb / 1024).toStringAsFixed(2)} MB'
            : '${sizeInKb.toStringAsFixed(2)} KB';

        await supabase.from('purchase_order_attachments').insert({
          'purchase_order_id': poId,
          'file_name': file.name,
          'file_path': fileKey,
          'file_size': formattedSize,
          'file_type': file.extension,
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error saving attachments',
        error: e,
        module: 'purchases',
      );
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to save attachments: $e');
      }
    }
  }

  void _showManageShipmentPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => ManageListDialog(
        title: 'Manage Carriers',
        singularLabel: 'Carrier',
        headerLabel: 'Carrier',
        items: _shipmentPreferencesList,
        selectedId: ref.read(purchaseOrderFormNotifierProvider).shipmentPreference,
        onSelect: (value) {
          final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
          if (value is Map<String, dynamic>) {
            notifier.updateField(shipmentPreference: value['id']);
          } else {
            notifier.updateField(shipmentPreference: value.toString());
          }
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncShipmentPreferences(items);
          if (mounted) {
            setState(() {
              _shipmentPreferencesList = updated;
            });
          }
          return updated;
        },
        onDeleteCheck: (item) async {
          if (item['id'] == null || item['id'].toString().startsWith('new_')) {
            return null;
          }
          try {
            final lookupsService = LookupsApiService();
            final usage = await lookupsService.checkLookupUsage(
              'shipment-preferences',
              item['id'].toString(),
            );
            if (usage['inUse'] == true) {
              return usage['message'] ??
                  'This carrier is in use and cannot be deleted.';
            }
          } catch (e) {
            AppLogger.error(
              'Error checking carrier usage',
              error: e,
              module: 'purchases',
            );
          }
          return null;
        },
      ),
    );
  }

  void _showManageTdsRatesDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ManageTdsTcsRatesDialog(
        title: 'Manage TDS Rates',
        isTcs: false,
        items: _tdsRatesList,
        sections: _tdsSectionsList,
        selectedId: ref.read(purchaseOrderFormNotifierProvider).tdsTcsId,
        onSelect: (value) {
          final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
          notifier.updateField(
            tdsTcsId: value['id']?.toString() ?? '',
            tdsTcsRate: double.tryParse(value['base_rate']?.toString() ?? '0') ?? 0.0,
          );
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncTdsRates(items);
          if (mounted) {
            setState(() {
              _tdsRatesList = updated;
            });
          }
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
              module: 'purchases',
            );
          }
          return null;
        },
      ),
    );
    await _performLoadTdsRates();
  }

  void _showManageTcsRatesDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ManageTdsTcsRatesDialog(
        title: 'Manage TCS Rates',
        isTcs: true,
        items: _tcsRatesList,
        sections: _tcsNaturesList,
        selectedId: ref.read(purchaseOrderFormNotifierProvider).tdsTcsId,
        onSelect: (value) {
          final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
          notifier.updateField(
            tdsTcsId: value['id']?.toString() ?? '',
            tdsTcsRate: double.tryParse(value['rate']?.toString() ?? '0') ?? 0.0,
          );
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncTdsRates(items);
          if (mounted) {
            setState(() {
              _tcsRatesList = updated;
            });
          }
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
              module: 'purchases',
            );
          }
          return null;
        },
      ),
    );
    await _performLoadTdsRates();
  }

  Future<void> _showConfigurePaymentTermsDialog(
    PurchaseOrderState poState,
    PurchaseOrderNotifier notifier,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => ManagePaymentTermsDialog(
        items: _paymentTermsList,
        selectedId: poState.paymentTerms,
        onSelect: (term) {
          notifier.updateField(paymentTerms: term['id']);
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncPaymentTerms(items);

          if (mounted) {
            setState(() {
              _paymentTermsList = updated;
            });
          }
          return updated;
        },
        onDeleteCheck: (item) async {
          if (item['id'] == null || item['id'].toString().startsWith('new_')) {
            return null;
          }

          try {
            final lookupsService = LookupsApiService();
            final usage = await lookupsService.checkLookupUsage(
              'payment-terms',
              item['id'].toString(),
            );

            if (usage['inUse'] == true) {
              return usage['message'] ??
                  'This payment term is in use and cannot be deleted.';
            }
          } catch (e) {
            AppLogger.error(
              'Error checking payment term usage',
              error: e,
              module: 'purchases',
            );
          }
          return null;
        },
      ),
    );
  }

  bool _isHydratingInitialOrder = false;

  bool get _isEditMode =>
      !widget.isClone &&
      (widget.initialOrder != null ||
       (widget.initialOrderId != null && widget.initialOrderId!.isNotEmpty));

  String? get _editingOrderId {
    if (widget.isClone) return null;
    final directId = widget.initialOrder?.id;
    if (directId != null && directId.isNotEmpty) {
      return directId;
    }
    final routeId = widget.initialOrderId;
    if (routeId != null && routeId.isNotEmpty) {
      return routeId;
    }
    return null;
  }

  void _hydrateFromInitialOrder(PurchaseOrder order, {bool isClone = false}) {
    ref.read(purchaseOrderFormNotifierProvider.notifier).hydrate(order, isClone: isClone);
    final firstItemWithPriceList = order.items.firstWhere(
      (item) => item.priceListId != null && item.priceListId!.isNotEmpty,
      orElse: () => PurchaseOrderItem(productId: '', quantity: 0, rate: 0, amount: 0),
    );
    if (firstItemWithPriceList.priceListId != null) {
      _selectedPriceListId = firstItemWithPriceList.priceListId;
    }
    // Hydrate row controllers
    _rowControllers.clear();
    _headerTextControllers.clear();
    for (final item in order.items) {
      _addRowController(
        initialName: item.productName,
        initialQty: item.quantity,
        initialRate: item.rate,
        initialDiscount: item.discount,
        initialDesc: item.description,
      );
    }
    // Hydrate controllers
    if (isClone) {
      _poNumberCtrl.text = '';
      _refCtrl.text = '';
      _orderDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
      _deliveryDateCtrl.text = '';
    } else {
      _poNumberCtrl.text = order.orderNumber;
      _refCtrl.text = order.referenceNumber ?? '';
      _orderDateCtrl.text = DateFormat('dd-MM-yyyy').format(order.orderDate);
      if (order.expectedDeliveryDate != null) {
        _deliveryDateCtrl.text = DateFormat(
          'dd-MM-yyyy',
        ).format(order.expectedDeliveryDate!);
      }
    }
    _notesCtrl.text = order.notes ?? '';
    _termsCtrl.text = order.termsAndConditions ?? '';
    _discountCtrl.text = order.discount.toStringAsFixed(2);
    _adjustmentCtrl.text = order.adjustment.toStringAsFixed(2);
    _adjustmentLabelCtrl.text = 'Adjustment';
  }

  Future<void> _loadInitialOrder(String orderId) async {
    setState(() => _isHydratingInitialOrder = true);
    try {
      final repository = ref.read(purchaseOrderRepositoryProvider);
      final order = await repository.getPurchaseOrder(orderId);

      // Load attachments
      final supabase = Supabase.instance.client;
      final attachmentsData = await supabase
          .from('purchase_order_attachments')
          .select()
          .eq('purchase_order_id', orderId);

      if (order != null && mounted) {
        _hydrateFromInitialOrder(order, isClone: widget.isClone);
        setState(() {
          _attachedFiles = (attachmentsData as List).map<PlatformFile>((row) {
            final sizeVal = row['file_size'];
            int parsedSize = 0;
            if (sizeVal is int) {
              parsedSize = sizeVal;
            } else if (sizeVal is String) {
              parsedSize =
                  int.tryParse(sizeVal.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            }
            return PlatformFile(name: row['file_name'] ?? '', size: parsedSize);
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to load purchase order: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isHydratingInitialOrder = false);
      }
    }
  }

  Future<void> _loadAttachmentsForOrder(String orderId) async {
    try {
      final supabase = Supabase.instance.client;
      final attachmentsData = await supabase
          .from('purchase_order_attachments')
          .select()
          .eq('purchase_order_id', orderId);
      if (mounted) {
        setState(() {
          _attachedFiles = (attachmentsData as List).map<PlatformFile>((row) {
            final sizeVal = row['file_size'];
            int parsedSize = 0;
            if (sizeVal is int) {
              parsedSize = sizeVal;
            } else if (sizeVal is String) {
              parsedSize =
                  int.tryParse(sizeVal.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            }
            return PlatformFile(name: row['file_name'] ?? '', size: parsedSize);
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading attachments: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _adjustmentLabelFocusNode.addListener(_onAdjustmentLabelFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(warehousesProvider);
      ref.invalidate(vendorProvider);
      ref.invalidate(priceListNotifierProvider);
      ref.invalidate(branchPriceListNotifierProvider);
      // Load vendors on init
      ref.read(vendorProvider.notifier).loadVendors();
      ref.read(itemsControllerProvider.notifier).loadLookupData();
      _loadCountries();
      _loadPhoneCodes();
      _loadSourceOfSupply();
      _loadPaymentTerms();
      _loadShipmentPreferences();
      _loadTdsRates();

      if (widget.initialOrder != null) {
        _hydrateFromInitialOrder(widget.initialOrder!, isClone: widget.isClone);
        if (widget.initialOrder!.id != null && !widget.isClone) {
          _loadAttachmentsForOrder(widget.initialOrder!.id!);
        }
      } else if (widget.initialOrderId != null &&
          widget.initialOrderId!.isNotEmpty) {
        _loadInitialOrder(widget.initialOrderId!);
      } else {
        ref.read(purchaseOrderFormNotifierProvider.notifier).reset();
        setState(() => _selectedPriceListId = null);
        final s = ref.read(purchaseOrderFormNotifierProvider);
        _rowControllers.clear();
        for (int i = 0; i < s.items.length; i++) {
          final item = s.items[i];
          _addRowController(
            initialName: item.productName,
            initialQty: item.quantity,
            initialRate: item.rate,
            initialDiscount: item.discount,
            initialDesc: item.description,
          );
        }
        _orderDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
        _discountCtrl.text = '0';
        _adjustmentCtrl.text = '0';
        _adjustmentLabelCtrl.text = 'Adjustment';
      }
    });
  }

  void _onAdjustmentLabelFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  _ItemRowController _makeRowController({
    String? initialName,
    double? initialQty,
    double? initialRate,
    double? initialDiscount,
    String? initialDesc,
  }) {
    final ctrl = _ItemRowController();
    if (initialName != null) ctrl.nameCtrl.text = initialName;
    if (initialDesc != null) ctrl.descCtrl.text = initialDesc;
    if (initialQty != null && initialQty != 0) {
      ctrl.qtyCtrl.text = initialQty.toStringAsFixed(
        initialQty % 1 == 0 ? 0 : 2,
      );
    } else {
      ctrl.qtyCtrl.text = '';
    }
    if (initialRate != null && initialRate != 0) {
      ctrl.rateCtrl.text = initialRate % 1 == 0
          ? initialRate.toInt().toString()
          : initialRate.toStringAsFixed(2);
    }
    if (initialDiscount != null) {
      ctrl.discountCtrl.text = initialDiscount.toStringAsFixed(2);
    }
    ctrl.rateFocus.addListener(() {
      if (!ctrl.rateFocus.hasFocus) {
        _handleRateCalculation(ctrl);
      }
    });
    return ctrl;
  }

  void _addRowController({
    int? index,
    String? initialName,
    double? initialQty,
    double? initialRate,
    double? initialDiscount,
    String? initialDesc,
  }) {
    final ctrl = _makeRowController(
      initialName: initialName,
      initialQty: initialQty,
      initialRate: initialRate,
      initialDiscount: initialDiscount,
      initialDesc: initialDesc,
    );
    if (index != null && index <= _rowControllers.length) {
      setState(() => _rowControllers.insert(index, ctrl));
    } else {
      setState(() => _rowControllers.add(ctrl));
    }
  }

  void _handleRateCalculation(_ItemRowController ctrl) {
    final text = ctrl.rateCtrl.text.trim();
    if (text.isEmpty) return;

    // Only try to parse if it contains operators
    if (text.contains(RegExp(r'[+\-*/()]'))) {
      final double? result = _evaluateExpression(text);
      if (result != null) {
        ctrl.rateCtrl.text = result % 1 == 0
            ? result.toInt().toString()
            : result.toStringAsFixed(2);
        // Find index to update notifier
        final index = _rowControllers.indexOf(ctrl);
        if (index != -1) {
          final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
          final poState = ref.read(purchaseOrderFormNotifierProvider);
          if (index < poState.items.length) {
            notifier.updateItem(
              index,
              poState.items[index].copyWith(rate: result),
            );
          }
        }
      }
    }
  }

  double? _evaluateExpression(String input) {
    try {
      return _MathParser(input.replaceAll(' ', '')).parse();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _poNumberCtrl.dispose();
    _refCtrl.dispose();
    _orderDateCtrl.dispose();
    _deliveryDateCtrl.dispose();
    _notesCtrl.dispose();
    _termsCtrl.dispose();
    _discountCtrl.dispose();
    _adjustmentCtrl.dispose();
    _adjustmentLabelCtrl.dispose();
    _adjustmentLabelFocusNode.dispose();
    _deliveryNameCtrl.dispose();
    _itemDetailsSearchCtrl.dispose();
    for (var c in _rowControllers) {
      c.dispose();
    }
    _closeGstOverlay();
    _closePoOverlay();
    _closeVendorSidebar();
    _closeDeliveryOverlay();
    _closeAddressDropdownOverlay();
    _uploadOverlay?.remove();
    POItemDetailsSidebar.hide();
    super.dispose();
  }

  void _toggleAddRowDropdown(dynamic notifier) {
    if (_addRowDropdownOverlay != null) {
      _addRowDropdownOverlay!.remove();
      _addRowDropdownOverlay = null;
      return;
    }
    _addRowDropdownOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _addRowDropdownOverlay?.remove();
                _addRowDropdownOverlay = null;
              },
              behavior: HitTestBehavior.translucent,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _addRowDropdownLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    notifier.addHeaderRow();
                    setState(() => _rowControllers.add(_makeRowController()));
                    _addRowDropdownOverlay?.remove();
                    _addRowDropdownOverlay = null;
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 14,
                          color: _linkBlue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add New Header',
                          style: TextStyle(
                            fontSize: 13,
                            color: _linkBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_addRowDropdownOverlay!);
  }

  void _closeItemMenu() {
    _itemMenuOverlay?.remove();
    _itemMenuOverlay = null;
    if (mounted) {
      setState(() {
        _activeMenuRowIndex = null;
      });
    }
  }

  void _showItemMenu(
    BuildContext context,
    int index,
    PurchaseOrderItem item,
    LayerLink link,
    List<Item> allItems,
  ) {
    _closeItemMenu();

    if (mounted) {
      setState(() {
        _activeMenuRowIndex = index;
      });
    }

    _itemMenuOverlay = ZAdaptiveMenu.show(
      context: context,
      link: link,
      onClose: _closeItemMenu,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            String? hoveredItem;
            final isHidden = _hiddenDetails.contains(index);
            final notifier = ref.read(
              purchaseOrderFormNotifierProvider.notifier,
            );
            return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSettingsOverlayItem(
                              label: isHidden
                                  ? 'Show Additional Information'
                                  : 'Hide Additional Information',
                              showHighlight: hoveredItem == 'toggle_info',
                              onHover: (v) => setOverlayState(
                                () => hoveredItem = v ? 'toggle_info' : null,
                              ),
                              onTap: () {
                                setState(() {
                                  if (_hiddenDetails.contains(index)) {
                                    _hiddenDetails.remove(index);
                                  } else {
                                    _hiddenDetails.add(index);
                                  }
                                });
                                _closeItemMenu();
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
                                notifier.addItemRow(
                                  index: index + 1,
                                  item: item.copyWith(),
                                );
                                _closeItemMenu();
                              },
                            ),
                            const SizedBox(height: 4),
                            _buildSettingsOverlayItem(
                              label: 'Insert New Row',
                              showHighlight: hoveredItem == 'insert_row',
                              onHover: (v) => setOverlayState(
                                () => hoveredItem = v ? 'insert_row' : null,
                              ),
                              onTap: () {
                                notifier.addItemRow(index: index + 1);
                                _closeItemMenu();
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
                                _closeItemMenu();
                                showDialog(
                                  context: context,
                                  builder: (context) => BulkItemsDialog(
                                    products: allItems,
                                    onItemsSelected: (selectedItems) {
                                      final List<PurchaseOrderItem> newItems =
                                          [];
                                      PriceList? pl;
                                      if (_selectedPriceListId != null) {
                                        try {
                                          final activePriceLists = _getCombinedPriceLists();
                                          pl = activePriceLists.firstWhere((p) => p.id == _selectedPriceListId);
                                        } catch (_) {}
                                      }
                                      selectedItems.forEach((item, quantity) {
                                        double rate = item.costPrice ?? 0.0;
                                        double discountVal = 0.0;
                                        String? plId;

                                        if (pl != null) {
                                          rate = pl.calculatePrice(
                                            item.id ?? '',
                                            item.costPrice ?? 0.0,
                                            quantity: quantity.toDouble(),
                                          );
                                          plId = pl.id;
                                          
                                          final override = pl.itemRates?.firstWhere(
                                            (r) => r.itemId == item.id,
                                            orElse: () => const PriceListItemRate(itemId: ''),
                                          );
                                          if (override != null && override.itemId.isNotEmpty) {
                                            if (override.discountPercentage != null) {
                                              discountVal = override.discountPercentage!;
                                            }
                                          }
                                        }
                                        newItems.add(
                                          PurchaseOrderItem(
                                            productId: item.id ?? '',
                                            productName: item.productName,
                                            quantity: quantity.toDouble(),
                                            rate: rate,
                                            discount: discountVal,
                                            discountType: 'percentage',
                                            priceListId: plId,
                                            amount: rate * quantity,
                                          ),
                                        );
                                      });
                                      notifier.addItemsInBulk(newItems);
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            _buildSettingsOverlayItem(
                              label: 'Insert New Header',
                              showHighlight: hoveredItem == 'insert_header',
                              onHover: (v) => setOverlayState(
                                () => hoveredItem = v ? 'insert_header' : null,
                              ),
                              onTap: () {
                                notifier.addHeaderRow(index: index + 1);
                                _closeItemMenu();
                              },
                            ),
                            const SizedBox(height: 4),
                            _buildSettingsOverlayItem(
                              label: 'Insert Items From Purchase Requests',
                              showHighlight: hoveredItem == 'insert_pr_items',
                              onHover: (v) => setOverlayState(
                                () => hoveredItem = v ? 'insert_pr_items' : null,
                              ),
                              onTap: () {
                                _closeItemMenu();
                                showDialog(
                                  context: context,
                                  builder: (context) => PurchaseRequestsItemsDialog(
                                    onItemsSelected: (selectedPrItems) {
                                      final List<PurchaseOrderItem> newItems = [];
                                      PriceList? pl;
                                      if (_selectedPriceListId != null) {
                                        try {
                                          final activePriceLists = _getCombinedPriceLists();
                                          pl = activePriceLists.firstWhere((p) => p.id == _selectedPriceListId);
                                        } catch (_) {}
                                      }
                                      for (var prItem in selectedPrItems) {
                                        double rate = prItem.rate;
                                        double discountVal = 0.0;
                                        String? plId;

                                        if (pl != null) {
                                          rate = pl.calculatePrice(
                                            prItem.productId,
                                            prItem.rate,
                                            quantity: prItem.quantity,
                                          );
                                          plId = pl.id;

                                          final override = pl.itemRates?.firstWhere(
                                            (r) => r.itemId == prItem.productId,
                                            orElse: () => const PriceListItemRate(itemId: ''),
                                          );
                                          if (override != null && override.itemId.isNotEmpty) {
                                            if (override.discountPercentage != null) {
                                              discountVal = override.discountPercentage!;
                                            }
                                          }
                                        }
                                        newItems.add(
                                          PurchaseOrderItem(
                                            productId: prItem.productId,
                                            productName: prItem.productName,
                                            quantity: prItem.quantity,
                                            rate: rate,
                                            discount: discountVal,
                                            discountType: 'percentage',
                                            priceListId: plId,
                                            amount: prItem.quantity * rate,
                                          ),
                                        );
                                      }
                                      notifier.addItemsInBulk(newItems);
                                    },
                                  ),
                                );
                               },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
  }

  void _closeGstOverlay() {
    _gstOverlay?.remove();
    _gstOverlay = null;
    _closeGstinOverlay();
  }

  void _closePoOverlay() {
    _poOverlay?.remove();
    _poOverlay = null;
  }

  void _closeVendorSidebar() {
    _vendorSidebarOverlay?.remove();
    _vendorSidebarOverlay = null;
  }

  void _showItemDetailsSidebar(
    PurchaseOrderItem row, {
    int initialTabIndex = 0,
  }) {
    final poState = ref.read(purchaseOrderFormNotifierProvider);
    final vendorState = ref.read(vendorProvider);
    final selectedVendor = vendorState.vendors.firstWhere(
      (v) => v.id == poState.vendorId,
      orElse: () => Vendor(id: '', displayName: ''),
    );

    POItemDetailsSidebar.show(
      context,
      row,
      initialTabIndex: initialTabIndex,
      vendorName: selectedVendor.id.isNotEmpty
          ? selectedVendor.displayName
          : null,
    );
  }

  void _closeDeliveryOverlay() {
    _deliveryOverlay?.remove();
    _deliveryOverlay = null;
  }

  Future<void> _loadPhoneCodes() async {
    // Basic codes - in a real app, load from countries list
    setState(() {
      _phoneCodesList = ['+91', '+1', '+44', '+971', '+65'];
      _phoneCodeToLabel = {
        '+91': 'India',
        '+1': 'USA',
        '+44': 'UK',
        '+971': 'UAE',
        '+65': 'Singapore',
      };
    });
  }

  Future<void> _loadCountries() async {
    try {
      final lookupsService = LookupsApiService();
      final countries = await lookupsService.getCountries();
      if (mounted) {
        setState(() {
          countries.sort((a, b) {
            if (a['name'] == 'India') return -1;
            if (b['name'] == 'India') return 1;
            return (a['name'] as String).compareTo(b['name'] as String);
          });
          final codes = countries
              .map((c) => c['phone_code']?.toString())
              .where((c) => c != null && c.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();

          if (codes.isNotEmpty) {
            codes.sort((a, b) {
              if (a == '+91') return -1;
              if (b == '+91') return 1;
              return a.compareTo(b);
            });
            _phoneCodesList = codes;
          }

          final labels = <String, String>{};
          for (var c in countries) {
            final code = c['phone_code']?.toString();
            final name = c['name']?.toString();
            if (code != null && name != null) {
              labels[code] = name;
            }
          }
          _phoneCodeToLabel = labels;
          for (var c in countries) {
            final id = c['id']?.toString();
            final name = c['name']?.toString();
            if (id != null && name != null) {
              _countryIdToName[id] = name;
            }
          }
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error loading countries/phone codes',
        error: e,
        module: 'purchases',
      );
    }
  }

  Future<void> _loadSourceOfSupply() async {
    try {
      final lookupsService = LookupsApiService();
      final states = await lookupsService.getStates('IN'); // India
      if (mounted && states.isNotEmpty) {
        setState(() {
          _sourceOfSupplyList = states.map((s) {
            final code = s['code']?.toString() ?? '';
            final name = s['name']?.toString() ?? '';
            return '[$code] - $name';
          }).toList();
          for (var s in states) {
            final id = s['id']?.toString();
            final name = s['name']?.toString();
            if (id != null && name != null) {
              _stateIdToName[id] = name;
            }
          }
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error loading source of supply states',
        error: e,
        module: 'purchases',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          const Icon(LucideIcons.fileText, size: 24, color: _textPrimary),
          const SizedBox(width: 12),
          Text(
            _isEditMode ? 'Edit Purchase Order' : 'New Purchase Order',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              final orderId = _editingOrderId;
              if (_isEditMode && orderId != null && orderId.isNotEmpty) {
                context.go('/purchases/purchase-orders/$orderId');
                return;
              }
              context.go('/purchases/purchase-orders');
            },
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 20, color: _hintColor),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  List<PriceList> _getCombinedPriceListsForBranch(String selectedBranchId) {
    final globalPriceLists = ref.read(activePriceListsProvider);
    final branchPriceLists = ref.read(branchPriceListNotifierProvider).valueOrNull ?? <BranchPriceList>[];

    final globalPurchaseLists = globalPriceLists
        .where((pl) => pl.transactionType.toLowerCase() == 'purchase')
        .toList();

    final filteredBranchLists = branchPriceLists
        .where((pl) =>
            pl.status == 'active' &&
            pl.transactionType.toLowerCase() == 'purchase' &&
            (pl.associatedBranches?.contains(selectedBranchId) ?? false))
        .map((b) => PriceList(
              id: b.id,
              name: b.name,
              description: b.description,
              currency: b.currency,
              pricingScheme: b.pricingScheme,
              priceListType: b.priceListType,
              details: b.details,
              roundOffPreference: b.roundOffPreference,
              status: b.status,
              transactionType: b.transactionType,
              isDiscountEnabled: b.isDiscountEnabled,
              percentageType: b.percentageType,
              percentageValue: b.percentageValue,
              itemRates: b.itemRates
                  ?.map((r) => PriceListItemRate(
                        itemId: r.itemId,
                        itemName: r.itemName,
                        sku: r.sku,
                        salesRate: r.salesRate,
                        customRate: r.customRate,
                        discountPercentage: r.discountPercentage,
                        volumeRanges: r.volumeRanges
                            ?.map((vr) => PriceListVolumeRange(
                                  startQuantity: vr.startQuantity,
                                  endQuantity: vr.endQuantity,
                                  customRate: vr.customRate,
                                  discountPercentage: vr.discountPercentage,
                                ))
                            .toList(),
                      ))
                  .toList(),
              createdAt: b.createdAt,
              updatedAt: b.updatedAt,
            ))
        .toList();

    return <PriceList>[
      ...globalPurchaseLists,
      ...filteredBranchLists,
    ];
  }

  List<PriceList> _getCombinedPriceLists() {
    final warehouseList = ref.read(warehousesProvider).valueOrNull ?? <WarehouseModel>[];
    final poState = ref.read(purchaseOrderFormNotifierProvider);
    final selectedWh = warehouseList.firstWhere(
      (w) => w.id == poState.deliveryWarehouseId,
      orElse: () => warehouseList.isNotEmpty ? warehouseList.first : WarehouseModel(id: '', name: '', countryRegion: ''),
    );
    final activeEntityId = (Hive.box('config').get('selected_entity_id') as String?)?.trim();
    final selectedBranchId = selectedWh.entityId ?? selectedWh.parentBranchId ?? activeEntityId ?? '';
    return _getCombinedPriceListsForBranch(selectedBranchId);
  }

  List<PriceList> _watchCombinedPriceLists() {
    final globalPriceLists = ref.watch(activePriceListsProvider)
        .where((pl) => pl.transactionType.toLowerCase() == 'purchase')
        .toList();
    final branchPriceListsAsync = ref.watch(branchPriceListNotifierProvider);
    final branchPriceLists = branchPriceListsAsync.valueOrNull ?? <BranchPriceList>[];

    final warehouseList = ref.watch(warehousesProvider).valueOrNull ?? <WarehouseModel>[];
    final poState = ref.watch(purchaseOrderFormNotifierProvider);
    final selectedWh = warehouseList.firstWhere(
      (w) => w.id == poState.deliveryWarehouseId,
      orElse: () => warehouseList.isNotEmpty ? warehouseList.first : WarehouseModel(id: '', name: '', countryRegion: ''),
    );
    final activeEntityId = (Hive.box('config').get('selected_entity_id') as String?)?.trim();
    final selectedBranchId = selectedWh.entityId ?? selectedWh.parentBranchId ?? activeEntityId ?? '';

    final filteredBranchLists = branchPriceLists
        .where((pl) =>
            pl.status == 'active' &&
            pl.transactionType.toLowerCase() == 'purchase' &&
            (pl.associatedBranches?.contains(selectedBranchId) ?? false))
        .map((b) => PriceList(
              id: b.id,
              name: b.name,
              description: b.description,
              currency: b.currency,
              pricingScheme: b.pricingScheme,
              priceListType: b.priceListType,
              details: b.details,
              roundOffPreference: b.roundOffPreference,
              status: b.status,
              transactionType: b.transactionType,
              isDiscountEnabled: b.isDiscountEnabled,
              percentageType: b.percentageType,
              percentageValue: b.percentageValue,
              itemRates: b.itemRates
                  ?.map((r) => PriceListItemRate(
                        itemId: r.itemId,
                        itemName: r.itemName,
                        sku: r.sku,
                        salesRate: r.salesRate,
                        customRate: r.customRate,
                        discountPercentage: r.discountPercentage,
                        volumeRanges: r.volumeRanges
                            ?.map((vr) => PriceListVolumeRange(
                                  startQuantity: vr.startQuantity,
                                  endQuantity: vr.endQuantity,
                                  customRate: vr.customRate,
                                  discountPercentage: vr.discountPercentage,
                                ))
                            .toList(),
                      ))
                  .toList(),
              createdAt: b.createdAt,
              updatedAt: b.updatedAt,
            ))
        .toList();

    return <PriceList>[
      ...globalPriceLists,
      ...filteredBranchLists,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final poState = ref.watch(purchaseOrderFormNotifierProvider);
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    final vendorState = ref.watch(vendorProvider);
    final vendors = vendorState.vendors;
    final selectedVendor = vendors.firstWhere(
      (v) => v.id == poState.vendorId,
      orElse: () => Vendor(id: '', displayName: ''),
    );
    final isUnregistered = selectedVendor.id.isNotEmpty &&
        (selectedVendor.gstTreatment == null ||
            selectedVendor.gstTreatment!.toLowerCase().contains('unregistered') ||
            selectedVendor.gstTreatment! == 'Unregistered Business');
    final customers = ref.watch(salesCustomersProvider).value ?? [];
    final warehouses = ref.watch(warehousesProvider).valueOrNull ?? [];
    final itemsState = ref.watch(itemsControllerProvider);
    final allItems = itemsState.items;

    final activePriceLists = _watchCombinedPriceLists();

    final accountsState = ref.watch(chartOfAccountsProvider);
    final List<AccountNode> availableAccounts = [];
    void collect(List<AccountNode> nodes) {
      for (final node in nodes) {
        availableAccounts.add(node);
        collect(node.children);
      }
    }

    collect(accountsState.roots);

    final orderDateText = DateFormat('dd-MM-yyyy').format(poState.orderDate);
    if (_orderDateCtrl.text != orderDateText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _orderDateCtrl.text = orderDateText;
      });
    }

    final deliveryDateText = poState.expectedDeliveryDate != null
        ? DateFormat('dd-MM-yyyy').format(poState.expectedDeliveryDate!)
        : '';
    if (_deliveryDateCtrl.text != deliveryDateText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _deliveryDateCtrl.text = deliveryDateText;
      });
    }

    // Initial load sync for Order Number controller
    if (_poNumberCtrl.text != poState.orderNumber) {
      // Use post frame to avoid build loops
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _poNumberCtrl.text = poState.orderNumber;
      });
    }

    // Set default warehouse when data is loaded
    ref.listen<AsyncValue<List<WarehouseModel>>>(warehousesProvider, (
      prev,
      next,
    ) {
      if (next.hasValue && next.valueOrNull!.isNotEmpty) {
        final currentPoState = ref.read(purchaseOrderFormNotifierProvider);
        final defaultWh = next.valueOrNull!.firstWhere(
          (w) => w.isDefaultForBranch,
          orElse: () => next.valueOrNull!.first,
        );
        
        final hasCurrentWh = next.valueOrNull!.any((w) => w.id == currentPoState.warehouseId);
        final hasCurrentDeliveryWh = next.valueOrNull!.any((w) => w.id == currentPoState.deliveryWarehouseId);

        String? updatedWhId;
        String? updatedDelWhId;
        String? updatedDelWhName;
        bool shouldUpdate = false;

        if (currentPoState.warehouseId == null ||
            currentPoState.warehouseId!.isEmpty ||
            !hasCurrentWh) {
          updatedWhId = defaultWh.id;
          shouldUpdate = true;
        }

        if (currentPoState.deliveryType == 'warehouse' &&
            (currentPoState.deliveryWarehouseId == null ||
                currentPoState.deliveryWarehouseId!.isEmpty ||
                !hasCurrentDeliveryWh)) {
          updatedDelWhId = defaultWh.id;
          updatedDelWhName = defaultWh.name;
          shouldUpdate = true;
        }

        if (shouldUpdate) {
          ref.read(purchaseOrderFormNotifierProvider.notifier).updateField(
            warehouseId: updatedWhId ?? currentPoState.warehouseId,
            deliveryWarehouseId: updatedDelWhId ?? currentPoState.deliveryWarehouseId,
            deliveryAddressName: updatedDelWhName ?? currentPoState.deliveryAddressName,
          );
          if (updatedDelWhName != null) {
            Future.microtask(() {
              _deliveryNameCtrl.text = updatedDelWhName ?? '';
            });
          }
        }
      }
    });

    // Also check for already loaded state
    final warehouseState = ref.watch(warehousesProvider);
    if (!warehouseState.isLoading &&
        !warehouseState.hasError &&
        warehouseState.valueOrNull != null &&
        warehouseState.valueOrNull!.isNotEmpty) {
      final currentPoState = ref.read(purchaseOrderFormNotifierProvider);
      final defaultWh = warehouseState.valueOrNull!.firstWhere(
        (w) => w.isDefaultForBranch,
        orElse: () => warehouseState.valueOrNull!.first,
      );
      
      final hasCurrentWh = warehouseState.valueOrNull!.any((w) => w.id == currentPoState.warehouseId);
      final hasCurrentDeliveryWh = warehouseState.valueOrNull!.any((w) => w.id == currentPoState.deliveryWarehouseId);

      bool needsUpdate = false;
      String? newWarehouseId;
      String? newDeliveryWarehouseId;
      String? newDeliveryAddressName;
      
      if (currentPoState.warehouseId == null ||
          currentPoState.warehouseId!.isEmpty ||
          !hasCurrentWh) {
        needsUpdate = true;
        newWarehouseId = defaultWh.id;
      }
      
      if (currentPoState.deliveryType == 'warehouse' &&
          (currentPoState.deliveryWarehouseId == null ||
              currentPoState.deliveryWarehouseId!.isEmpty ||
              !hasCurrentDeliveryWh)) {
        needsUpdate = true;
        newDeliveryWarehouseId = defaultWh.id;
        newDeliveryAddressName = defaultWh.name;
      }
      
      if (needsUpdate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(purchaseOrderFormNotifierProvider.notifier).updateField(
              warehouseId: newWarehouseId ?? currentPoState.warehouseId,
              deliveryWarehouseId: newDeliveryWarehouseId ?? currentPoState.deliveryWarehouseId,
              deliveryAddressName: newDeliveryAddressName ?? currentPoState.deliveryAddressName,
            );
            if (newDeliveryAddressName != null) {
              _deliveryNameCtrl.text = newDeliveryAddressName;
            }
          }
        });
      }
    }

    if (_isHydratingInitialOrder) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: FormSkeleton(),
      );
    }

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      footer: _stickyFooter(poState),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          // ── FORM SECTION ──
          _buildFormSection(vendors, customers, warehouses, poState),
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 32, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),
                // ── WAREHOUSE  ──
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Warehouse',
                              style: TextStyle(
                                fontSize: 13,
                                color: _labelColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Warehouse
                              SizedBox(
                                width: 240,
                                child: FormDropdown<String>(
                                  height: 36,
                                  value: poState.warehouseId,
                                  textStyle: TextStyle(
                                    fontSize: 13,
                                    fontWeight: poState.warehouseId != null && poState.warehouseId!.isNotEmpty
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: poState.warehouseId != null && poState.warehouseId!.isNotEmpty
                                        ? _textPrimary
                                        : _hintColor,
                                  ),
                                  items: warehouses.map((w) => w.id).toList(),
                                  displayStringForValue: (id) => warehouses
                                      .firstWhere(
                                        (w) => w.id == id,
                                        orElse: () => WarehouseModel(
                                          id: '',
                                          name: 'Not selected',
                                          countryRegion: '',
                                        ),
                                      )
                                      .name,
                                  hint: 'Select Warehouse',
                                  onChanged: (id) =>
                                      notifier.updateField(warehouseId: id),
                                  borderRadius: BorderRadius.circular(6),
                                  hideBorderDefault: true,
                                  itemBuilder: (id, isSelected, isHovered) =>
                                      _buildStandardLookupRow(
                                        warehouses
                                            .firstWhere(
                                              (w) => w.id == id,
                                              orElse: () => WarehouseModel(
                                                id: '',
                                                name: '',
                                                countryRegion: '',
                                              ),
                                            )
                                            .name,
                                        isSelected,
                                        isHovered,
                                      ),
                                ),
                              ),

                              // 2. Tax Preference (only if not unregistered)
                              if (!isUnregistered) ...[
                                const SizedBox(width: 8),
                                Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 180,
                                  child: FormDropdown<String>(
                                    height: 36,
                                    itemHeight: 44,
                                    value: poState.taxType == 'inclusive'
                                        ? 'Tax Inclusive'
                                        : 'Tax Exclusive',
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _textPrimary,
                                    ),
                                    items: const ['Tax Exclusive', 'Tax Inclusive'],
                                    onChanged: (v) {
                                      if (v != null) {
                                        notifier.updateField(
                                          taxType: v == 'Tax Inclusive'
                                              ? 'inclusive'
                                              : 'exclusive',
                                        );
                                      }
                                    },
                                    displayStringForValue: (v) => v,
                                    borderRadius: BorderRadius.circular(6),
                                    hideBorderDefault: true,
                                    prefixWidget: const Icon(
                                      LucideIcons.shoppingBag,
                                      size: 16,
                                      color: Color(0xFF6B7280),
                                    ),
                                    itemBuilder: (item, isSelected, isHovered) {
                                      Color bgColor = Colors.white;
                                      Color textColor = _textPrimary;

                                      if (isHovered) {
                                        bgColor = _linkBlue;
                                        textColor = Colors.white;
                                      } else if (isSelected) {
                                        bgColor = Colors.transparent;
                                        textColor = _textPrimary; // black text
                                      }

                                      return Container(
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        alignment: Alignment.centerLeft,
                                        color: bgColor,
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: textColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],

                              const SizedBox(width: 8),
                              Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                              const SizedBox(width: 8),
                              // 3. Discount Level
                              SizedBox(
                                width: 220,
                                child: FormDropdown<String>(
                                  height: 36,
                                  value: poState.discountLevel,
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _textPrimary,
                                  ),
                                  items: const ['transaction', 'item'],
                                  displayStringForValue: (v) => v == 'transaction'
                                      ? 'At Transaction Level'
                                      : 'At Line Item Level',
                                  onChanged: (v) =>
                                      notifier.updateField(discountLevel: v),
                                  borderRadius: BorderRadius.circular(6),
                                  hideBorderDefault: true,
                                  prefixWidget: const Icon(
                                    LucideIcons.percent,
                                    size: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                  itemBuilder: (id, isSelected, isHovered) =>
                                      _buildStandardLookupRow(
                                        id == 'transaction'
                                            ? 'At Transaction Level'
                                            : 'At Line Item Level',
                                        isSelected,
                                        isHovered,
                                      ),
                                ),
                              ),

                              // 5. Price List
                              const SizedBox(width: 8),
                              Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 200,
                                child: CompositedTransformTarget(
                                  link: _priceListTooltipLink,
                                  child: MouseRegion(
                                    onEnter: (_) {
                                      final pl = activePriceLists
                                          .where((pl) => pl.id == _selectedPriceListId)
                                          .firstOrNull;
                                      if (pl != null) {
                                        _showValueTooltip(
                                          context,
                                          pl.name,
                                          _priceListTooltipLink,
                                        );
                                      }
                                    },
                                    onExit: (_) => _hideValueTooltip(),
                                    child: FormDropdown<PriceList>(
                                      height: 36,
                                      hint: 'Select Price List',
                                      value: activePriceLists
                                          .where((pl) => pl.id == _selectedPriceListId)
                                          .firstOrNull,
                                      textStyle: TextStyle(
                                        fontSize: 13,
                                        fontWeight: _selectedPriceListId != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _selectedPriceListId != null
                                            ? _textPrimary
                                            : _hintColor,
                                      ),
                                      items: activePriceLists,
                                      displayStringForValue: (pl) => pl.name,
                                      onChanged: (pl) {
                                        if (pl != null) {
                                          setState(() => _selectedPriceListId = pl.id);
                                          final notifier = ref.read(
                                            purchaseOrderFormNotifierProvider.notifier,
                                          );
                                          final state = ref.read(
                                            purchaseOrderFormNotifierProvider,
                                          );
                                          final itemsState = ref.read(itemsControllerProvider);
                                          for (int i = 0; i < state.items.length; i++) {
                                            final item = state.items[i];
                                            if (!item.isHeader && item.productId.isNotEmpty) {
                                              double baseRate = item.rate;
                                              try {
                                                final prod = itemsState.items.firstWhere((p) => p.id == item.productId);
                                                baseRate = prod.costPrice ?? 0.0;
                                              } catch (_) {}
                                              final newRate = pl.calculatePrice(
                                                item.productId,
                                                baseRate,
                                                quantity: item.quantity,
                                              );
                                              
                                              double discountVal = 0.0;
                                              final override = pl.itemRates?.firstWhere(
                                                (r) => r.itemId == item.productId,
                                                orElse: () => const PriceListItemRate(itemId: ''),
                                              );
                                              if (override != null && override.itemId.isNotEmpty) {
                                                if (override.discountPercentage != null) {
                                                  discountVal = override.discountPercentage!;
                                                }
                                              }
                                              
                                              if (state.discountLevel == 'item' && i < _rowControllers.length) {
                                                _rowControllers[i].discountCtrl.text = discountVal.toStringAsFixed(2);
                                              }
                                              
                                              notifier.updateItem(
                                                i,
                                                item.copyWith(
                                                  rate: newRate,
                                                  priceListId: pl.id,
                                                  discount: discountVal,
                                                  discountType: 'percentage',
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      hideBorderDefault: true,
                                      prefixWidget: const Icon(
                                        LucideIcons.clipboard,
                                        size: 16,
                                        color: Color(0xFF6B7280),
                                      ),
                                itemBuilder: (pl, isSelected, isHovered) =>
                                    _buildStandardLookupRow(
                                      pl.name,
                                      isSelected,
                                      isHovered,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
                // ── ITEM TABLE ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: poState.discountLevel == 'item'
                            ? 1400.0
                            : 1270.0,
                        child: _itemTableSection(
                          allItems,
                          availableAccounts,
                          poState,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── NOTES & TOTALS (Side-by-side, just above the banner) ──
                _notesAndTotals(allItems, poState),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── SHADED BLUE BANNER (Full-width Terms & Files) ──
          _footerBanner(poState),

          // ── ADDITIONAL FIELDS INFO (In padded area) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  'Additional Fields: Start adding custom fields for your purchase orders by going to Settings ⇒ Purchases ⇒ Purchase Orders.',
                  style: TextStyle(fontSize: 12, color: _hintColor),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM SECTION (Zoho-style flat layout)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFormSection(
    List<Vendor> vendors,
    List<SalesCustomer> customers,
    List<WarehouseModel> warehouses,
    PurchaseOrderState poState,
  ) {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    final selectedVendor = vendors.firstWhere(
      (v) => v.id == poState.vendorId,
      orElse: () => Vendor(id: '', displayName: ''),
    );
    final hasVendor = selectedVendor.id.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            border: Border.symmetric(
              horizontal: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildVendorSelectionRow(
                  selectedVendor,
                  vendors,
                  hasVendor,
                  notifier,
                ),
              ),
              if (hasVendor)
                _vendorInfoSection(selectedVendor, poState, notifier),
            ],
          ),
        ),
        if (!hasVendor) const SizedBox(height: 20),
        // ── Rest of the top form fields ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Delivery Address ──
              const SizedBox(height: 12),
              _zFormRow(
                label: 'Delivery Address',
                isRequired: true,
                crossStart: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _zRadio(
                          'Warehouses',
                          'warehouse',
                          poState.deliveryType,
                          (v) => notifier.updateField(deliveryType: v),
                        ),
                        const SizedBox(width: 16),
                        _zRadio(
                          'Customer',
                          'customer',
                          poState.deliveryType,
                          (v) => notifier.updateField(deliveryType: v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _deliverySection(warehouses, customers, poState),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Purchase Order# ──
              _zFormRow(
                label: 'Purchase Order#',
                isRequired: true,
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: FormDropdown<String>(
                        height: 32,
                        enabled: !_isEditMode,
                        value: 'Default Transaction Series',
                        items: const ['Default Transaction Series'],
                        onChanged: (v) {},
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _fieldBorder),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _zField(
                        _poNumberCtrl,
                        hint: poState.isNumberingAuto ? 'PO-00001' : '',
                        readOnly: poState.isNumberingAuto || _isEditMode,
                        onChanged: (poState.isNumberingAuto || _isEditMode)
                            ? null
                            : (value) =>
                                  notifier.updateField(orderNumber: value),
                        suffixIcon: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _isEditMode
                                ? null
                                : () => _showNumberingPreferences(
                                      poState,
                                      notifier,
                                    ),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(
                                Icons.settings_outlined,
                                size: 16,
                                color: _isEditMode ? _hintColor : _linkBlue,
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
              // ── Reference ──
              _zFormRow(label: 'Reference#', child: _zField(_refCtrl)),
              const SizedBox(height: 16),
              // ── Date ──
              _zFormRow(
                label: 'Date',
                isRequired: true,
                child: _zDateField(
                  controller: _orderDateCtrl,
                  targetKey: _orderDateFieldKey,
                  value: poState.orderDate,
                  onSelected: (date) => notifier.updateField(orderDate: date),
                  firstDate: DateTime(2000),
                ),
              ),
              const SizedBox(height: 16),
              // ── Delivery Date + Payment Terms ──
              _zFormRow(
                label: 'Delivery Date',
                child: _zDateField(
                  controller: _deliveryDateCtrl,
                  targetKey: _deliveryDateFieldKey,
                  value: poState.expectedDeliveryDate,
                  hint: 'dd-MM-yyyy',
                  onSelected: (date) =>
                      notifier.updateField(expectedDeliveryDate: date),
                  firstDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                ),
              ),
              const SizedBox(height: 16),
              // ── Payment Terms ──
              _zFormRow(
                label: 'Payment Terms',
                child: FormDropdown<String>(
                  height: 32,
                  value: poState.paymentTerms,
                  items: _paymentTermsList
                      .map((t) => t['id'] as String)
                      .toList(),
                  hint: 'Select Terms',
                  showSettings: true,
                  settingsLabel: 'Configure Terms',
                  onSettingsTap: () =>
                      _showConfigurePaymentTermsDialog(poState, notifier),
                  displayStringForValue: (id) {
                    final term = _paymentTermsList.firstWhere(
                      (t) => t['id'] == id,
                      orElse: () => {'term_name': ''},
                    );
                    return term['term_name'] ?? '';
                  },
                  searchStringForValue: (id) {
                    final term = _paymentTermsList.firstWhere(
                      (t) => t['id'] == id,
                      orElse: () => {'term_name': ''},
                    );
                    return term['term_name'] ?? '';
                  },
                  itemBuilder: (id, isSelected, isHovered) {
                    final term = _paymentTermsList.firstWhere(
                      (t) => t['id'] == id,
                      orElse: () => {'term_name': ''},
                    );
                    return _buildStandardLookupRow(
                      term['term_name'] ?? '',
                      isSelected,
                      isHovered,
                    );
                  },
                  onChanged: (v) => notifier.updateField(paymentTerms: v),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _fieldBorder),
                ),
              ),
              const SizedBox(height: 16),
              // ── Shipment Preference ──
              _zFormRow(
                label: 'Shipment Preference',
                child: FormDropdown<String>(
                  height: 32,
                  value: poState.shipmentPreference,
                  items: _shipmentPreferencesList
                      .map((p) => p['id']?.toString() ?? '')
                      .where((id) => id.isNotEmpty)
                      .toList(),
                  hint: 'Choose the shipment preference',
                  allowCustomValue: true,
                  showSettings: true,
                  settingsLabel: 'New Carrier',
                  settingsIcon: Icons.add,
                  onSettingsTap: _showManageShipmentPreferencesDialog,
                  displayStringForValue: (v) {
                    final pref = _shipmentPreferencesList.firstWhere(
                      (p) => p['id'] == v,
                      orElse: () => <String, dynamic>{},
                    );
                    if (pref.containsKey('name')) {
                      return pref['name'] as String;
                    }
                    return v;
                  },
                  searchStringForValue: (v) {
                    final pref = _shipmentPreferencesList.firstWhere(
                      (p) => p['id'] == v,
                      orElse: () => <String, dynamic>{},
                    );
                    if (pref.containsKey('name')) {
                      return pref['name'] as String;
                    }
                    return v;
                  },
                  onChanged: (v) => notifier.updateField(shipmentPreference: v),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _fieldBorder),
                  itemBuilder: (id, isSelected, isHovered) {
                    final pref = _shipmentPreferencesList.firstWhere(
                      (p) => p['id'] == id,
                      orElse: () => <String, dynamic>{},
                    );
                    return _buildStandardLookupRow(
                      pref['name'] ?? '',
                      isSelected,
                      isHovered,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _reverseChargeCheckbox(poState, notifier),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  void _showNumberingPreferences(
    PurchaseOrderState poState,
    PurchaseOrderNotifier notifier,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isAuto = poState.isNumberingAuto;
        final prefixCtrl = TextEditingController(text: poState.poPrefix);
        int displayNextNumber = poState.poNextNumber;
        if (poState.orderNumber.startsWith(poState.poPrefix)) {
          final suffixStr = poState.orderNumber.substring(poState.poPrefix.length);
          final parsed = int.tryParse(suffixStr);
          if (parsed != null) {
            displayNextNumber = parsed;
          }
        }
        final nextNumCtrl = TextEditingController(
          text: displayNextNumber.toString().padLeft(poState.poPadding, '0'),
        );
        bool restartMonthly = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Container(
                width: 700,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Configure Purchase Order# Preferences',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: _linkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Associated Series
                          const Text(
                            'Associated Series',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Default Transaction Series',
                            style: TextStyle(fontSize: 13, color: _textPrimary),
                          ),
                          const SizedBox(height: 24),

                          // Description
                          Text(
                            isAuto
                                ? 'Your purchase order numbers are set on auto-generate mode to save your time. Are you sure about changing this setting?'
                                : 'You have selected manual purchase order numbering. Do you want us to auto-generate it for you?',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _labelColor,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Options
                          Row(
                            children: [
                              _zRadio(
                                'Continue auto-generating purchase order numbers',
                                'auto',
                                isAuto ? 'auto' : 'manual',
                                (v) => setState(() => isAuto = true),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: _hintColor,
                              ),
                            ],
                          ),
                          if (isAuto) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Prefix',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _hintColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 160,
                                        child: _zField(
                                          prefixCtrl,
                                          suffixIcon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 16,
                                            color: _linkBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Next Number',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _hintColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 280,
                                        child: _zField(nextNumCtrl),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Checkbox(
                                      value: restartMonthly,
                                      onChanged: (v) =>
                                          setState(() => restartMonthly = v!),
                                      side: const BorderSide(
                                        color: Color(0xFFCCCCCC),
                                      ),
                                      activeColor: _greenBtn,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Restart numbering for purchase orders at the start of each fiscal year.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _labelColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _zRadio(
                            'Enter purchase order numbers manually',
                            'manual',
                            isAuto ? 'auto' : 'manual',
                            (v) => setState(() => isAuto = false),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              final rawNextNum = nextNumCtrl.text;
                              final parsedNum = int.tryParse(rawNextNum) ?? 1;
                              final padding = rawNextNum.length;

                              notifier.saveSettings(
                                isAuto: isAuto,
                                prefix: prefixCtrl.text,
                                nextNumber: parsedNum,
                                padding: padding,
                              );
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _greenBtn,
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
                            child: const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFDDDDDD)),
                              foregroundColor: _textPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Cancel'),
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

  Widget _buildVendorSelectionRow(
    Vendor selectedVendor,
    List<Vendor> vendors,
    bool hasVendor,
    PurchaseOrderNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _zFormRow(
            label: 'Vendor Name',
            isRequired: true,
            maxWidth: 850,
            gap: 12,
            child: Row(
              children: [
                SizedBox(
                  width: 550,
                  child: FormDropdown<Vendor>(
                    height: 32,
                    enabled: !_isEditMode,
                    value: selectedVendor.id.isEmpty ? null : selectedVendor,
                    textStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: selectedVendor.id.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                      color: selectedVendor.id.isNotEmpty ? _textPrimary : _hintColor,
                    ),
                    items: vendors,
                    hint: 'Select a Vendor',
                    showSearch: true,
                    allowClear: hasVendor && !_isEditMode,
                    menuWidth: 550,
                    onChanged: (v) => _selectVendor(v, notifier),
                    showSettings: !_isEditMode,
                    settingsLabel: 'New Vendor',
                    settingsIcon: LucideIcons.plus,
                    onSettingsTap: _showNewVendorDialog,
                    displayStringForValue: (v) => v.displayName,
                    itemBuilder: (v, isSelected, isHovered) =>
                        _buildVendorDropdownItem(v, isSelected, isHovered),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                    showRightBorder: false,
                    border: Border.all(color: _fieldBorder),
                  ),
                ),
                Container(
                  height: 32,
                  width: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      LucideIcons.search,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => _showAdvancedSearch(vendors, notifier),
                  ),
                ),
                if (hasVendor) ...[
                  const SizedBox(width: 8),
                  // INR badge
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.circleDollarSign,
                          size: 14,
                          color: Color(0xFF374151),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getCurrencyLabel(selectedVendor.currency ?? 'INR'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Vendor card button on the right
        if (hasVendor)
          GestureDetector(
            onTap: () => _showVendorSidebar(selectedVendor),
            child: Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedVendor.displayName.length > 20
                        ? '${selectedVendor.displayName.substring(0, 20)}...'
                        : selectedVendor.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showAdvancedSearch(
    List<Vendor> vendors,
    PurchaseOrderNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AdvancedVendorSearchDialog(
        vendors: vendors,
        onSelect: (v) => _selectVendor(v, notifier),
      ),
    );
  }

  void _selectVendor(Vendor? v, PurchaseOrderNotifier notifier) {
    double rateVal = 0.0;
    if (v?.tdsRateId != null && v!.tdsRateId!.isNotEmpty) {
      final matchedRate = _tdsRatesList.firstWhere(
        (r) => r['id']?.toString() == v.tdsRateId,
        orElse: () => <String, dynamic>{},
      );
      if (matchedRate.isNotEmpty) {
        rateVal = double.tryParse(matchedRate['base_rate']?.toString() ?? '0') ?? 0.0;
      }
    }

    String? resolvedPaymentTerms = _defaultPaymentTermId;
    if (v?.paymentTerms != null && v!.paymentTerms!.isNotEmpty) {
      final matchingTerm = _paymentTermsList.firstWhere(
        (t) => t['term_name'] == v.paymentTerms || t['id'] == v.paymentTerms,
        orElse: () => <String, dynamic>{},
      );
      if (matchingTerm.isNotEmpty) {
        resolvedPaymentTerms = matchingTerm['id']?.toString();
      }
    }
    if (resolvedPaymentTerms == null && _paymentTermsList.isNotEmpty) {
      final net30 = _paymentTermsList.firstWhere(
        (t) => t['term_name'] == 'Net 30',
        orElse: () => _paymentTermsList.first,
      );
      resolvedPaymentTerms = net30['id']?.toString();
    }

    notifier.updateField(
      vendorId: v?.id ?? '',
      destinationOfSupply: (v?.sourceOfSupply != null && v!.sourceOfSupply!.isNotEmpty)
          ? v.sourceOfSupply!
          : '',
      tdsTcsType: (v?.tdsRateId != null && v!.tdsRateId!.isNotEmpty) ? 'tds' : 'none',
      tdsTcsId: (v?.tdsRateId != null && v!.tdsRateId!.isNotEmpty) ? v.tdsRateId : '',
      tdsTcsRate: rateVal,
      paymentTerms: resolvedPaymentTerms,
    );
  }

  void _toggleGstinOverlay(Vendor vendor, String activeGstin) {
    if (_gstinOverlay != null) {
      _closeGstinOverlay();
      return;
    }

    final overlay = Overlay.of(context);
    _gstinOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeGstinOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _gstinLink,
            showWhenUnlinked: false,
            offset: const Offset(-30, 20), // Align properly above/below the GSTIN pencil
            child: Material(
              color: Colors.transparent,
              child: _GstinPopover(
                gstin: activeGstin,
                onUpdate: (newGstin) {
                  final updatedVendor = vendor.copyWith(gstin: newGstin);
                  ref
                      .read(vendorProvider.notifier)
                      .updateVendor(vendor.id, updatedVendor);
                  _closeGstinOverlay();
                },
                onCancel: _closeGstinOverlay,
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_gstinOverlay!);
  }

  void _closeGstinOverlay() {
    _gstinOverlay?.remove();
    _gstinOverlay = null;
  }

  void _showTaxPreferencesDialog(Vendor vendor) {
    _closeGstOverlay();
    final overlay = Overlay.of(context);
    _gstOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeGstOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _gstLink,
            showWhenUnlinked: false,
            offset: const Offset(-360, 18), // Adjust to align arrow with pencil
            child: Material(
              color: Colors.transparent,
              child: _ConfigureTaxPreferencesDialog(
                initialTreatment:
                    vendor.gstTreatment ?? 'Unregistered Business',
                initialGstin: vendor.gstin ?? '',
                onUpdate: (val, gstinVal, isPermanent) async {
                  final updatedVendor = vendor.copyWith(
                    gstTreatment: val,
                    gstin: gstinVal,
                  );
                  // Always save to database vendors table
                  await ref
                      .read(vendorProvider.notifier)
                      .updateVendor(vendor.id, updatedVendor);
                  ref
                      .read(purchaseOrderFormNotifierProvider.notifier)
                      .updateField(forceRecalculateTaxes: true);
                  _closeGstOverlay();
                },
                onCancel: _closeGstOverlay,
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_gstOverlay!);
  }

  void _showOpenPurchaseOrdersPopover(BuildContext context) {
    _closePoOverlay();
    final overlay = Overlay.of(context);
    _poOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closePoOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _poLink,
            showWhenUnlinked: false,
            offset: const Offset(-20, 20),
            child: Material(
              color: Colors.transparent,
              child: Consumer(
                builder: (context, ref, child) {
                  final poState = ref.read(purchaseOrderFormNotifierProvider);
                  if (poState.vendorId == null || poState.vendorId!.isEmpty) {
                    return const _OpenPurchaseOrdersPopover(orders: []);
                  }
                  final purchaseOrdersAsync = ref.watch(
                    purchaseOrdersProvider(
                      PurchaseOrderFilter(vendorId: poState.vendorId),
                    ),
                  );
                  return purchaseOrdersAsync.when(
                    data: (ordersList) {
                      final mappedOrders = ordersList.map((po) {
                        return {
                          'po': po.orderNumber,
                          'date': DateFormat('dd-MM-yyyy').format(po.orderDate),
                          'amount': NumberFormat.currency(
                            locale: 'en_IN',
                            symbol: '₹',
                          ).format(po.total),
                          'status': po.status,
                        };
                      }).toList();
                      return _OpenPurchaseOrdersPopover(orders: mappedOrders);
                    },
                    loading: () => const _OpenPurchaseOrdersPopover(orders: []),
                    error: (err, stack) => const _OpenPurchaseOrdersPopover(orders: []),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_poOverlay!);
  }

  void _showVendorSidebar(Vendor vendor) async {
    if (_isVendorSidebarLoading) return;
    if (_vendorSidebarOverlay != null) {
      _closeVendorSidebar();
      return;
    }
    _isVendorSidebarLoading = true;
    _closeVendorSidebar();
    
    Vendor displayVendor = vendor;
    try {
      final repo = ref.read(vendorRepositoryProvider);
      final fetched = await repo.getVendorById(vendor.id);
      if (fetched != null) {
        displayVendor = fetched;
      }
    } catch (e) {
      debugPrint('Error fetching full vendor details: $e');
    } finally {
      _isVendorSidebarLoading = false;
    }

    if (!mounted) return;

    final overlay = Overlay.of(context);
    _vendorSidebarOverlay = OverlayEntry(
      builder: (ctx) => VendorSidebar(
        vendor: displayVendor,
        onClose: _closeVendorSidebar,
        paymentTermsList: _paymentTermsList,
      ),
    );
    overlay.insert(_vendorSidebarOverlay!);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VENDOR INFO SECTION (Billing/Shipping, GST, Supply)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _vendorInfoSection(
    Vendor vendor,
    PurchaseOrderState poState,
    PurchaseOrderNotifier notifier,
  ) {
    final hasAddressesInDb = (vendor.billingAddress != null && vendor.billingAddress!.isNotEmpty) ||
        (vendor.shippingAddress != null && vendor.shippingAddress!.isNotEmpty) ||
        (vendor.vendorAddresses != null && vendor.vendorAddresses!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Indented section for addresses and GST
        Padding(
          padding: const EdgeInsets.only(
            left: 32 + 180 + 24,
          ), // Align with input fields
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Open Purchase Orders link
              CompositedTransformTarget(
                link: _poLink,
                child: GestureDetector(
                  onTap: () => _showOpenPurchaseOrdersPopover(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.fileWarning,
                        color: Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Open Purchase Orders',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF555555),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Billing & Shipping Address side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddressBlock(
                    title: 'BILLING ADDRESS',
                    address: vendor.billingAddress,
                    showPencil: hasAddressesInDb,
                    link: _billingAddressLink,
                    onEdit: () => _showAddressDropdownList(
                      vendor: vendor,
                      isBilling: true,
                      link: _billingAddressLink,
                    ),
                    onNewAddress: () => _showAddressModal(
                      vendor: vendor,
                      isBilling: true,
                      customTitle: hasAddressesInDb ? 'Additional Address' : 'New Billing Address',
                      isNewAddress: true,
                    ),
                  ),
                  const SizedBox(width: 64),
                  _buildAddressBlock(
                    title: 'SHIPPING ADDRESS',
                    address: vendor.shippingAddress,
                    showPencil: hasAddressesInDb,
                    link: _shippingAddressLink,
                    onEdit: () => _showAddressDropdownList(
                      vendor: vendor,
                      isBilling: false,
                      link: _shippingAddressLink,
                    ),
                    onNewAddress: () => _showAddressModal(
                      vendor: vendor,
                      isBilling: false,
                      customTitle: hasAddressesInDb ? 'Additional Address' : 'New Shipping Address',
                      isNewAddress: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // GST Treatment
              _buildGstRow(vendor),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Supply Details aligned with general form
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Column(
            children: [
              _zFormRow(
                label: 'Source of Supply',
                isRequired: true,
                child: SizedBox(
                  width: 320,
                  child: FormDropdown<String>(
                    height: 36,
                    value:
                        vendor.sourceOfSupply != null &&
                            vendor.sourceOfSupply!.isNotEmpty
                        ? vendor.sourceOfSupply!
                        : (_sourceOfSupplyList.isNotEmpty
                              ? _sourceOfSupplyList.first
                              : ''),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                    items: _sourceOfSupplyList,
                    showSearch: true,
                    onChanged: (val) {
                      if (val == null) return;
                      final updatedVendor = vendor.copyWith(
                        sourceOfSupply: val,
                      );
                      ref
                          .read(vendorProvider.notifier)
                          .updateVendor(vendor.id, updatedVendor);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _zFormRow(
                label: 'Destination of Supply',
                isRequired: true,
                child: SizedBox(
                  width: 320,
                  child: FormDropdown<String>(
                    height: 36,
                    value: poState.destinationOfSupply.isNotEmpty
                        ? poState.destinationOfSupply
                        : '[KL] - Kerala',
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                    items: _sourceOfSupplyList,
                    showSearch: true,
                    onChanged: (val) =>
                        notifier.updateField(destinationOfSupply: val ?? ''),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _fieldBorder),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressBlock({
    required String title,
    required Map<String, dynamic>? address,
    required VoidCallback onEdit,
    required VoidCallback onNewAddress,
    required bool showPencil,
    required LayerLink link,
  }) {
    final hasAddress = address != null && address.isNotEmpty;
    final lines = <String>[];
    if (hasAddress) {
      final attention = address['attention'] as String? ?? '';
      final street1 = address['street1'] as String? ?? 
                      address['street'] as String? ?? 
                      address['address_street'] as String? ?? 
                      address['addressStreet'] as String? ?? '';
      final street2 = address['street2'] as String? ?? 
                      address['place'] as String? ?? 
                      address['address_place'] as String? ?? 
                      address['addressPlace'] as String? ?? '';
      final city = address['city'] as String? ?? '';
      final state = address['state'] as String? ?? '';
      final zip = address['zip'] as String? ?? 
                  address['pincode'] as String? ?? 
                  address['zipCode'] as String? ?? '';
      final country = address['country'] as String? ?? 
                      address['countryRegion'] as String? ?? 
                      address['country_region'] as String? ?? '';
      final phone = address['phone'] as String? ?? '';
      final fax = address['fax'] as String? ?? '';

      if (attention.isNotEmpty) lines.add(attention);
      if (street1.isNotEmpty) lines.add(street1);
      if (street2.isNotEmpty) lines.add(street2);
      if (city.isNotEmpty) lines.add(city);
      final stateZip = [
        state,
        zip,
      ].where((s) => s.isNotEmpty).join(' ');
      if (stateZip.isNotEmpty) lines.add(stateZip);
      if (country.isNotEmpty) lines.add(country);
      if (phone.isNotEmpty) lines.add('Phone: $phone');
      if (fax.isNotEmpty) lines.add('Fax Number: $fax');
    }

    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              if (showPencil) ...[
                const SizedBox(width: 4),
                CompositedTransformTarget(
                  link: link,
                  child: InkWell(
                    onTap: onEdit,
                    child: const Icon(
                      LucideIcons.pencil,
                      size: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (hasAddress)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address['attention'] != null &&
                    (address['attention'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      address['attention'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ...lines
                    .where(
                      (l) => l != address['attention'],
                    ) // Skip attention if already added
                    .map(
                      (l) => Text(
                        l,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4B5563),
                          height: 1.5,
                        ),
                      ),
                    ),
              ],
            )
          else
            GestureDetector(
              onTap: onNewAddress,
              child: const Text(
                'New Address',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddressDropdownList({
    required Vendor vendor,
    required bool isBilling,
    required LayerLink link,
  }) {
    _closeAddressDropdownOverlay();
    final allAddresses = _getAllVendorAddresses(vendor);
    
    _addressDropdownOverlay = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeAddressDropdownOverlay,
          child: Stack(
            children: [
              const Positioned.fill(
                child: SizedBox.expand(),
              ),
              CompositedTransformFollower(
                link: link,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 4),
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                    child: Container(
                      width: 340,
                      constraints: const BoxConstraints(maxHeight: 320),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(8),
                              itemCount: allAddresses.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final addr = allAddresses[i];
                                return _buildAddressDropdownItem(
                                  vendor: vendor,
                                  address: addr,
                                  isBilling: isBilling,
                                );
                              },
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          InkWell(
                            onTap: () {
                              _closeAddressDropdownOverlay();
                              _showAddressModal(
                                vendor: vendor,
                                isBilling: isBilling,
                                customTitle: isBilling ? 'Billing Address' : 'Shipping Address',
                                isNewAddress: true,
                              );
                            },
                            child: Container(
                              height: 40,
                              alignment: Alignment.center,
                              color: Colors.white,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.plus, size: 14, color: Color(0xFF2563EB)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Add New Address',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2563EB),
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
        );
      },
    );
    Overlay.of(context).insert(_addressDropdownOverlay!);
  }

  void _closeAddressDropdownOverlay() {
    _addressDropdownOverlay?.remove();
    _addressDropdownOverlay = null;
  }

  Map<String, dynamic> _normalizeAddress(Map<String, dynamic> address) {
    return {
      'attention': address['attention']?.toString() ?? '',
      'street1': (address['street1'] ?? address['street'] ?? address['address_street'] ?? address['addressStreet'] ?? '').toString(),
      'street2': (address['street2'] ?? address['place'] ?? address['address_place'] ?? address['addressPlace'] ?? '').toString(),
      'city': address['city']?.toString() ?? '',
      'state': address['state']?.toString() ?? '',
      'zip': (address['zip'] ?? address['pincode'] ?? address['zipCode'] ?? '').toString(),
      'country': (address['country'] ?? address['countryRegion'] ?? address['country_region'] ?? '').toString(),
      'phone': address['phone']?.toString() ?? '',
      'fax': address['fax']?.toString() ?? '',
      if (address['id'] != null) 'id': address['id'].toString(),
    };
  }

  bool _areAddressesEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    String norm(dynamic val) => (val?.toString() ?? '').trim().toLowerCase();
    
    final streetA = norm(a['street1'] ?? a['street'] ?? a['address_street']);
    final streetB = norm(b['street1'] ?? b['street'] ?? b['address_street']);
    if (streetA != streetB) return false;
    
    final placeA = norm(a['street2'] ?? a['place'] ?? a['address_place'] ?? a['street_2']);
    final placeB = norm(b['street2'] ?? b['place'] ?? b['address_place'] ?? b['street_2']);
    if (placeA != placeB) return false;
    
    if (norm(a['city']) != norm(b['city'])) return false;
    if (norm(a['state']) != norm(b['state'])) return false;
    
    final zipA = norm(a['zip'] ?? a['pincode']);
    final zipB = norm(b['zip'] ?? b['pincode']);
    if (zipA != zipB) return false;
    
    final countryA = norm(a['country'] ?? a['countryRegion'] ?? a['country_region']);
    final countryB = norm(b['country'] ?? b['countryRegion'] ?? b['country_region']);
    if (countryA != countryB) return false;
    
    if (norm(a['phone']) != norm(b['phone'])) return false;
    if (norm(a['attention']) != norm(b['attention'])) return false;
    
    return true;
  }

  Widget _buildAddressDropdownItem({
    required Vendor vendor,
    required Map<String, dynamic> address,
    required bool isBilling,
  }) {
    final attention = address['attention'] as String? ?? '';
    final street1 = address['street1'] as String? ?? 
                    address['street'] as String? ?? 
                    address['address_street'] as String? ?? 
                    address['addressStreet'] as String? ?? '';
    final street2 = address['street2'] as String? ?? 
                    address['place'] as String? ?? 
                    address['address_place'] as String? ?? 
                    address['addressPlace'] as String? ?? '';
    final city = address['city'] as String? ?? '';
    final state = address['state'] as String? ?? '';
    final zip = address['zip'] as String? ?? 
                address['pincode'] as String? ?? 
                address['zipCode'] as String? ?? '';
    final country = address['country'] as String? ?? 
                    address['countryRegion'] as String? ?? 
                    address['country_region'] as String? ?? '';
    final phone = address['phone'] as String? ?? '';

    final activeAddress = isBilling ? vendor.billingAddress : vendor.shippingAddress;
    final isSelected = activeAddress != null && _areAddressesEqual(activeAddress, address);

    final lines = <String>[
      if (street1.isNotEmpty) street1,
      if (street2.isNotEmpty) street2,
      [city, state, zip].where((s) => s.isNotEmpty).join(', '),
      if (country.isNotEmpty) country,
      if (phone.isNotEmpty) 'Phone: $phone',
    ];

    final bool isAddrBilling = address['is_default_billing'] == true ||
        address['isDefaultBilling'] == true ||
        address['address_type'] == 'billing' ||
        address['addressType'] == 'billing';
    final bool isAddrShipping = address['is_default_shipping'] == true ||
        address['isDefaultShipping'] == true ||
        address['address_type'] == 'shipping' ||
        address['addressType'] == 'shipping';

    bool canEdit = true;
    if (isBilling) {
      if (isAddrShipping && !isAddrBilling) {
        canEdit = false;
      }
    } else {
      if (isAddrBilling && !isAddrShipping) {
        canEdit = false;
      }
    }

    bool isHovered = false;
    return StatefulBuilder(
      builder: (ctx, setSt) {
        return MouseRegion(
          onEnter: (_) => setSt(() => isHovered = true),
          onExit: (_) => setSt(() => isHovered = false),
          child: GestureDetector(
            onTap: () async {
              _closeAddressDropdownOverlay();
              final updatedAddresses = _updateVendorAddressesDefaultFlags(
                vendor: vendor,
                selectedAddr: address,
                isBilling: isBilling,
              );
              final normalizedAddr = _normalizeAddress(address);
              final updated = isBilling
                  ? vendor.copyWith(
                      billingAddress: normalizedAddr,
                      vendorAddresses: updatedAddresses,
                    )
                  : vendor.copyWith(
                      shippingAddress: normalizedAddr,
                      vendorAddresses: updatedAddresses,
                    );
              try {
                ref
                    .read(vendorProvider.notifier)
                    .updateVendorLocally(vendor.id, updated);
                await ref
                    .read(vendorProvider.notifier)
                    .updateVendor(vendor.id, updated);
                if (mounted) {
                  ZerpaiToast.success(context, 'Vendor address updated');
                }
              } catch (e) {
                ref
                    .read(vendorProvider.notifier)
                    .updateVendorLocally(vendor.id, vendor);
                if (mounted) {
                  ZerpaiToast.error(context, 'Failed to update address: $e');
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHovered
                    ? const Color(0xFF3B82F6)
                    : (isSelected ? const Color(0xFFEFF6FF) : Colors.white),
                border: Border.all(
                  color: isHovered
                      ? const Color(0xFF3B82F6)
                      : (isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB)),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          attention.isNotEmpty
                              ? attention
                              : (isBilling ? 'Billing Address' : 'Shipping Address'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isHovered ? Colors.white : (isSelected ? const Color(0xFF2563EB) : const Color(0xFF1F2937)),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isHovered && canEdit)
                            GestureDetector(
                              onTap: () {
                                _closeAddressDropdownOverlay();
                                _showAddressModal(
                                  vendor: vendor,
                                  isBilling: isBilling,
                                  initialAddress: address,
                                  customTitle: isBilling ? 'Billing Address' : 'Shipping Address',
                                );
                              },
                              child: Icon(
                                LucideIcons.pencil,
                                size: 13,
                                color: isHovered ? Colors.white : const Color(0xFF6B7280),
                              ),
                            ),
                            // Selection indicator checkCircle removed per user request
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...lines.map(
                    (l) => Text(
                      l,
                      style: TextStyle(
                        fontSize: 11,
                        color: isHovered ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _updateVendorAddressesDefaultFlags({
    required Vendor vendor,
    required Map<String, dynamic> selectedAddr,
    required bool isBilling,
  }) {
    final currentList = vendor.vendorAddresses ?? [];
    bool found = false;
    final newList = currentList.map((addr) {
      final isMatch = _areAddressesEqual(addr, selectedAddr);
      final updatedAddr = Map<String, dynamic>.from(addr);
      
      // 1. Update default flags
      if (isMatch) {
        found = true;
        if (isBilling) {
          updatedAddr['is_default_billing'] = true;
          updatedAddr['isDefaultBilling'] = true;
        } else {
          updatedAddr['is_default_shipping'] = true;
          updatedAddr['isDefaultShipping'] = true;
        }
      } else {
        if (isBilling) {
          updatedAddr['is_default_billing'] = false;
          updatedAddr['isDefaultBilling'] = false;
        } else {
          updatedAddr['is_default_shipping'] = false;
          updatedAddr['isDefaultShipping'] = false;
        }
      }

      // 2. Resolve address_type based on the final default flags
      final billingFlag = updatedAddr['is_default_billing'] == true || updatedAddr['isDefaultBilling'] == true;
      final shippingFlag = updatedAddr['is_default_shipping'] == true || updatedAddr['isDefaultShipping'] == true;
      if (billingFlag && shippingFlag) {
        updatedAddr['address_type'] = isBilling ? 'billing' : 'shipping';
        updatedAddr['addressType'] = isBilling ? 'billing' : 'shipping';
      } else if (billingFlag) {
        updatedAddr['address_type'] = 'billing';
        updatedAddr['addressType'] = 'billing';
      } else if (shippingFlag) {
        updatedAddr['address_type'] = 'shipping';
        updatedAddr['addressType'] = 'shipping';
      } else {
        updatedAddr['address_type'] = 'additional';
        updatedAddr['addressType'] = 'additional';
      }

      return updatedAddr;
    }).toList();

    if (!found) {
      final newAddr = {
        ...selectedAddr,
        'is_default_billing': isBilling,
        'isDefaultBilling': isBilling,
        'is_default_shipping': !isBilling,
        'isDefaultShipping': !isBilling,
        'address_type': isBilling ? 'billing' : 'shipping',
        'addressType': isBilling ? 'billing' : 'shipping',
      };
      newList.add(newAddr);
    }
    return newList;
  }

  List<AccountNode> _buildNestedAccountsList(List<AccountNode> accounts) {
    final List<AccountNode> nested = [];
    final Map<String, List<AccountNode>> grouped = {};
    for (var acc in accounts) {
      grouped.putIfAbsent(acc.accountType, () => []).add(acc);
    }

    for (var entry in grouped.entries) {
      final type = entry.key;
      final typeAccounts = entry.value;
      nested.add(AccountNode(
        id: 'header_$type',
        systemAccountName: type,
        userAccountName: type,
        name: type,
        accountGroup: 'Expenses',
        accountType: type,
        isSystem: false,
        isDeletable: false,
        isActive: false,
        parentId: null,
      ));

      final accountMap = {for (var a in typeAccounts) a.id: a};
      final rootNodes = typeAccounts
          .where((a) => a.parentId == null || !accountMap.containsKey(a.parentId))
          .toList();

      void addNode(AccountNode node) {
        nested.add(node);
        final children = typeAccounts.where((a) => a.parentId == node.id).toList();
        for (var child in children) {
          addNode(child);
        }
      }

      for (var root in rootNodes) {
        addNode(root);
      }
    }
    return nested;
  }

  int _getAccountDepth(AccountNode node, List<AccountNode> accounts) {
    int depth = 0;
    AccountNode? current = node;
    final accountMap = {for (var a in accounts) a.id: a};
    while (current?.parentId != null && accountMap.containsKey(current!.parentId)) {
      depth++;
      current = accountMap[current.parentId];
    }
    return depth;
  }

  List<Map<String, dynamic>> _getAllVendorAddresses(Vendor vendor) {
    final list = <Map<String, dynamic>>[];
    if (vendor.vendorAddresses != null && vendor.vendorAddresses!.isNotEmpty) {
      for (final addr in vendor.vendorAddresses!) {
        final mapped = Map<String, dynamic>.from(addr);
        if (mapped['is_default_billing'] == null && mapped['isDefaultBilling'] != null) {
          mapped['is_default_billing'] = mapped['isDefaultBilling'];
        }
        if (mapped['is_default_shipping'] == null && mapped['isDefaultShipping'] != null) {
          mapped['is_default_shipping'] = mapped['isDefaultShipping'];
        }
        if (mapped['isDefaultBilling'] == null && mapped['is_default_billing'] != null) {
          mapped['isDefaultBilling'] = mapped['is_default_billing'];
        }
        if (mapped['isDefaultShipping'] == null && mapped['is_default_shipping'] != null) {
          mapped['isDefaultShipping'] = mapped['is_default_shipping'];
        }
        list.add(mapped);
      }
    } else {
      if (vendor.billingAddress != null && vendor.billingAddress!.isNotEmpty) {
        final Map<String, dynamic> billing = Map<String, dynamic>.from(vendor.billingAddress!);
        billing['is_default_billing'] = true;
        billing['isDefaultBilling'] = true;
        billing['address_type'] = 'billing';
        list.add(billing);
      }
      if (vendor.shippingAddress != null && vendor.shippingAddress!.isNotEmpty) {
        final Map<String, dynamic> shipping = Map<String, dynamic>.from(vendor.shippingAddress!);
        shipping['is_default_shipping'] = true;
        shipping['isDefaultShipping'] = true;
        shipping['address_type'] = 'shipping';
        list.add(shipping);
      }
    }

    final uniqueList = <Map<String, dynamic>>[];
    for (final addr in list) {
      bool exists = false;
      for (final existing in uniqueList) {
        if (_areAddressesEqual(addr, existing)) {
          exists = true;
          if (addr['is_default_billing'] == true || addr['isDefaultBilling'] == true) {
            existing['is_default_billing'] = true;
            existing['isDefaultBilling'] = true;
          }
          if (addr['is_default_shipping'] == true || addr['isDefaultShipping'] == true) {
            existing['is_default_shipping'] = true;
            existing['isDefaultShipping'] = true;
          }
          break;
        }
      }
      if (!exists) {
        uniqueList.add(addr);
      }
    }
    return uniqueList;
  }

  Widget _buildGstRow(Vendor vendor) {
    final gstTreatment = vendor.gstTreatment ?? 'Unregistered Business';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'GST Treatment: ',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            Text(
              gstTreatment,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 6),
            CompositedTransformTarget(
              link: _gstLink,
              child: InkWell(
                onTap: () => _showTaxPreferencesDialog(vendor),
                child: const Icon(
                  LucideIcons.pencil,
                  size: 11,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        if (vendor.gstin != null && vendor.gstin!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'GSTIN: ',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                vendor.gstin!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 6),
              CompositedTransformTarget(
                link: _gstinLink,
                child: InkWell(
                  onTap: () => _toggleGstinOverlay(vendor, vendor.gstin!),
                  child: const Icon(
                    LucideIcons.pencil,
                    size: 11,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELIVERY ADDRESS SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _deliverySection(
    List<WarehouseModel> warehouses,
    List<SalesCustomer> customers,
    PurchaseOrderState poState,
  ) {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    final warehouseAsync = ref.watch(warehousesProvider);
    final liveWarehouses = warehouseAsync.value ?? warehouses;

    if (poState.deliveryType == 'warehouse') {
      final wh = liveWarehouses.firstWhere(
        (w) => w.id == poState.deliveryWarehouseId,
        orElse: () => WarehouseModel(id: '', name: '', countryRegion: ''),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          warehouseAsync.isLoading
              ? Container(
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: _fieldBorder),
                    borderRadius: BorderRadius.circular(3),
                    color: _bgWhite,
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: const Text(
                    'Loading warehouses...',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                )
              : warehouseAsync.hasError
              ? Container(
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.red.withValues(alpha: 0.05),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Error loading data: ${warehouseAsync.error}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : FormDropdown<WarehouseModel>(
                  height: 32,
                  itemHeight: 56.0,
                  itemEstimatedHeight: 56.0,
                  value: wh.id.isEmpty ? null : wh,
                  items: liveWarehouses,
                  hint: liveWarehouses.isEmpty
                      ? 'No warehouses found'
                      : 'Select Warehouse',
                  showSearch: true,
                  displayStringForValue: (w) => w.name,
                  searchStringForValue: (w) =>
                      '${w.name} ${w.city ?? ''} ${w.state ?? ''} ${w.addressStreet1 ?? ''}',
                  itemBuilder: (w, isSelected, isHovered) =>
                      _buildWarehouseDropdownItem(w, isSelected, isHovered),
                  onChanged: (w) {
                    notifier.updateField(
                      deliveryWarehouseId: w?.id ?? '',
                      deliveryAddressName: w?.name ?? '',
                    );
                    _deliveryNameCtrl.text = w?.name ?? '';
                  },
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _fieldBorder),
                ),
          if (wh.id.isNotEmpty) ...[
            const SizedBox(height: 14),
            _warehouseAddressCard(wh, notifier, liveWarehouses, poState),
          ],
        ],
      );
    } else {
      final cust = customers.firstWhere(
        (c) => c.id == poState.deliveryCustomerId,
        orElse: () => SalesCustomer(id: '', displayName: ''),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 320,
                child: FormDropdown<SalesCustomer>(
                  height: 32,
                  value: cust.id.isEmpty ? null : cust,
                  items: customers,
                  hint: 'Select Customer',
                  showSearch: true,
                  displayStringForValue: (c) => c.displayName,
                  onChanged: (c) =>
                      notifier.updateField(deliveryCustomerId: c?.id ?? ''),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                  showRightBorder: false,
                  border: Border.all(color: _fieldBorder),
                ),
              ),
              Container(
                height: 32,
                width: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    LucideIcons.search,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => _showAdvancedCustomerSearch(customers),
                ),
              ),
            ],
          ),
          if (cust.id.isNotEmpty) ...[
            const SizedBox(height: 10),
            _customerAddressCard(cust, notifier, liveWarehouses, poState),
          ],
          const SizedBox(height: 16),
          const Text(
            'Stock on Hand will not be affected only in case of dropshipments. Selecting the Customer option in the Deliver To field of a normal purchase order will have an effect on your stock level',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280), // grey-500
              height: 1.4,
            ),
          ),
        ],
      );
    }
  }

  // ─── Warehouse address card (Image 1 style) ────────────────────────────────
  Widget _warehouseAddressCard(
    WarehouseModel wh,
    PurchaseOrderNotifier notifier,
    List<WarehouseModel> allWarehouses,
    PurchaseOrderState poState,
  ) {
    const addrColor = Color(0xFF1A73C8); // blue for city / country lines
    const addrDark = Color(0xFF1A3A5C); // darker for bold city

    final displayName = poState.deliveryAddressName ?? wh.name;
    if (_deliveryNameCtrl.text != displayName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _deliveryNameCtrl.text = displayName;
      });
    }

    final lines = <_AddrLine>[
      if (wh.city != null && wh.city!.isNotEmpty)
        _AddrLine(wh.city!, isBold: false),
      if ((wh.addressStreet1 ?? '').isNotEmpty || (wh.state ?? '').isNotEmpty)
        _AddrLine(
          [
            wh.addressStreet1,
            wh.state,
          ].where((s) => s != null && s.isNotEmpty).join(', '),
        ),
      if (wh.countryRegion.isNotEmpty || (wh.zipCode ?? '').isNotEmpty)
        _AddrLine(
          '${wh.countryRegion}'
          '${(wh.zipCode ?? '').isNotEmpty ? " , ${wh.zipCode}" : ""}',
        ),
      if ((wh.phone ?? '').isNotEmpty) _AddrLine(wh.phone!, isPhone: true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editable bold name field
        _HoverableField(
          builder: (isHovered) => TextFormField(
            controller: _deliveryNameCtrl,
            onChanged: (v) => notifier.updateField(deliveryAddressName: v),
            style: const TextStyle(
              fontSize: 13,
              color: _textPrimary,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide(
                  color: isHovered ? _linkBlue : _fieldBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: const BorderSide(color: _linkBlue, width: 1.5),
              ),
              fillColor: _bgWhite,
              filled: true,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Styled address lines
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              line.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: line.isPhone
                    ? _labelColor
                    : (line.isBold ? addrDark : addrColor),
                fontWeight: line.isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // "Change destination" link → opens popover
        CompositedTransformTarget(
          link: _deliveryChangeLink,
          child: GestureDetector(
            onTap: () => _showDeliveryPopover(allWarehouses, poState, notifier),
            child: const Text(
              'Change destination to deliver',
              style: TextStyle(
                color: _linkBlue,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
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
        onSelect: (c) {
          final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
          notifier.updateField(deliveryCustomerId: c.id);
        },
      ),
    );
  }

  // ─── Customer address card ──────────────────────────────────────────────────
  Widget _customerAddressCard(
    SalesCustomer cust,
    PurchaseOrderNotifier notifier,
    List<WarehouseModel> allWarehouses,
    PurchaseOrderState poState,
  ) {
    final countries = ref.watch(countriesProvider(null)).valueOrNull ?? [];

    // Resolve shipping country
    final shippingCountryMap = countries.firstWhere(
      (item) =>
          item['id'] == cust.shippingAddressCountryId ||
          item['shortCode'] == cust.shippingAddressCountryId,
      orElse: () => <String, String>{},
    );
    final shippingCountryName =
        shippingCountryMap['name'] ?? cust.shippingAddressCountryId;

    // Resolve shipping state
    final shippingStates =
        (cust.shippingAddressCountryId != null &&
            cust.shippingAddressCountryId!.isNotEmpty)
        ? (ref.watch(statesProvider(cust.shippingAddressCountryId!)).valueOrNull ?? [])
        : [];
    final shippingStateMap = shippingStates
        .where(
          (item) =>
              item['id'] == cust.shippingAddressStateId ||
              item['code'] == cust.shippingAddressStateId,
        )
        .firstOrNull;
    final shippingStateName = shippingStateMap != null
        ? shippingStateMap['name']
        : cust.shippingAddressStateId;

    final lines = <_AddrLine>[
      if ((cust.displayName).isNotEmpty)
        _AddrLine(cust.displayName, isBold: true),
      if ((cust.shippingAddressStreet1 ?? '').isNotEmpty)
        _AddrLine(cust.shippingAddressStreet1!),
      if ((cust.shippingAddressStreet2 ?? '').isNotEmpty)
        _AddrLine(cust.shippingAddressStreet2!),
      if ((cust.shippingAddressCity ?? '').isNotEmpty)
        _AddrLine(cust.shippingAddressCity!),
      if ((shippingStateName ?? '').isNotEmpty)
        _AddrLine(shippingStateName!),
      if ((cust.shippingAddressZip ?? '').isNotEmpty)
        _AddrLine(cust.shippingAddressZip!),
      if ((shippingCountryName ?? '').isNotEmpty)
        _AddrLine(shippingCountryName!),
      if ((cust.phone ?? '').isNotEmpty)
        _AddrLine('Phone: ${cust.phone!}', isPhone: true),
    ];

    // Find the currently selected warehouse location in the dropdown
    final selectedWh = allWarehouses.firstWhere(
      (w) => w.id == poState.deliveryWarehouseId,
      orElse: () => allWarehouses.isNotEmpty
          ? allWarehouses.first
          : WarehouseModel(id: '', name: 'Not selected', countryRegion: ''),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'SHIPPING ADDRESS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563), // grey-600
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                _showAddressModal(cust: cust, isBilling: false);
              },
              child: const Icon(
                Icons.edit_outlined,
                size: 14,
                color: Color(0xFF6B7280), // grey-500
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: line.isBold ? const Color(0xFF111827) : const Color(0xFF374151),
                fontWeight: line.isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Select the location to be updated',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 320,
          child: FormDropdown<WarehouseModel>(
            height: 32,
            value: selectedWh.id.isEmpty ? null : selectedWh,
            items: allWarehouses,
            hint: 'Select the location to be updated',
            displayStringForValue: (w) => '${w.name} (warehouse)',
            menuWidth: 320,
            itemBuilder: (w, isSelected, isHovered) {
              Color bg = Colors.transparent;
              Color textColor = const Color(0xFF111827); // black text
              if (isHovered) {
                bg = const Color(0xFF0052CC); // blue background
                textColor = Colors.white; // white text
              } else if (isSelected) {
                bg = Colors.transparent;
                textColor = const Color(0xFF111827); // black text
              }
              return Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: bg,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${w.name} (warehouse)',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
            onChanged: (w) {
              notifier.updateField(
                deliveryWarehouseId: w?.id ?? '',
              );
            },
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _fieldBorder),
          ),
        ),
      ],
    );
  }

  // ─── "Change destination" popover ──────────────────────────────────────────
  void _showDeliveryPopover(
    List<WarehouseModel> warehouses,
    PurchaseOrderState poState,
    PurchaseOrderNotifier notifier,
  ) {
    _closeDeliveryOverlay();
    final searchCtrl = TextEditingController();
    final searchNotifier = ValueNotifier<String>('');
    searchCtrl.addListener(
      () => searchNotifier.value = searchCtrl.text.toLowerCase(),
    );

    _deliveryOverlay = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeDeliveryOverlay,
          child: Stack(
            children: [
              const SizedBox.expand(),
              CompositedTransformFollower(
                link: _deliveryChangeLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 4),
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(6),
                    color: _bgWhite,
                    child: Container(
                      width: 320,
                      constraints: const BoxConstraints(maxHeight: 400),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              controller: searchCtrl,
                              autofocus: true,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search',
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFAAAAAA),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 16,
                                  color: Color(0xFFAAAAAA),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 32,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCCCCCC),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(
                                    color: _linkBlue,
                                    width: 1.5,
                                  ),
                                ),
                                fillColor: _bgWhite,
                                filled: true,
                              ),
                            ),
                          ),
                          // List
                          Flexible(
                            child: ValueListenableBuilder<String>(
                              valueListenable: searchNotifier,
                              builder: (_, query, __) {
                                final filtered = query.isEmpty
                                    ? warehouses
                                    : warehouses
                                          .where(
                                            (w) =>
                                                w.name.toLowerCase().contains(
                                                  query,
                                                ) ||
                                                (w.city ?? '')
                                                    .toLowerCase()
                                                    .contains(query) ||
                                                (w.state ?? '')
                                                    .toLowerCase()
                                                    .contains(query),
                                          )
                                          .toList();
                                if (filtered.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No warehouses found',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) {
                                    final w = filtered[i];
                                    return _deliveryPopoverItem(
                                      w,
                                      w.id == poState.deliveryWarehouseId,
                                      notifier,
                                    );
                                  },
                                );
                              },
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
      },
    );
    Overlay.of(context).insert(_deliveryOverlay!);
  }

  // ─── Single item in delivery popover ───────────────────────────────────────
  Widget _deliveryPopoverItem(
    WarehouseModel w,
    bool isSelected,
    PurchaseOrderNotifier notifier,
  ) {
    const primaryCol = Color(0xFF111827);
    const secondaryCol = Color(0xFF4B5563);

    final lines = <_AddrLine>[
      if (w.attention != null && w.attention!.isNotEmpty)
        _AddrLine(w.attention!, isBold: true),
      if (w.city != null && w.city!.isNotEmpty)
        _AddrLine(w.city!, isCity: true),
      if ((w.addressStreet1 ?? '').isNotEmpty || (w.state ?? '').isNotEmpty)
        _AddrLine(
          [
            w.addressStreet1,
            w.state,
          ].where((s) => s != null && s.isNotEmpty).join(', '),
        ),
      if (w.countryRegion.isNotEmpty || (w.zipCode ?? '').isNotEmpty)
        _AddrLine(
          '${w.countryRegion}${(w.zipCode ?? '').isNotEmpty ? " , ${w.zipCode}" : ""}',
          isCity: true,
        ),
      if ((w.phone ?? '').isNotEmpty) _AddrLine(w.phone!),
    ];

    bool hov = false;
    return StatefulBuilder(
      builder: (ctx, setSt) {
        return MouseRegion(
          onEnter: (_) => setSt(() => hov = true),
          onExit: (_) => setSt(() => hov = false),
          child: GestureDetector(
            onTap: () {
              notifier.updateField(
                deliveryWarehouseId: w.id,
                deliveryAddressName: w.name,
              );
              _deliveryNameCtrl.text = w.name;
              _closeDeliveryOverlay();
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hov
                    ? const Color(0xFF0088FF)
                    : (isSelected ? const Color(0xFFEEEEEE) : Colors.white),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines
                          .map(
                            (line) => Text(
                              line.text,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: hov
                                    ? Colors.white
                                    : (isSelected
                                          ? Colors.black
                                          : (line.isBold
                                                ? primaryCol
                                                : secondaryCol)),
                                fontWeight: line.isBold
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  // Edit and delete icons removed
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REVERSE CHARGE CHECKBOX
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _reverseChargeCheckbox(
    PurchaseOrderState poState,
    PurchaseOrderNotifier notifier,
  ) {
    return _zFormRow(
      label: '',
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Checkbox(
              value: poState.isReverseCharge,
              onChanged: (v) => notifier.updateField(isReverseCharge: v),
              activeColor: _linkBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'This transaction is applicable for reverse charge',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF374151), // Gray-700
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ITEM TABLE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _itemTableSection(
    List<Item> allItems,
    List<AccountNode> availableAccounts,
    PurchaseOrderState poState,
  ) {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Table Title Row (outside the border) ──
        if (!_bulkMode)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                    border: Border.all(color: _borderCol),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Item Table',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // Bulk Actions button
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _bulkMode = true;
                            _selectedRows.clear();
                          });
                        },
                        icon: const Icon(
                          LucideIcons.checkCircle,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        label: const Text(
                          'Bulk Actions',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Settings popup
                      Theme(
                        data: Theme.of(context).copyWith(
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 250),
                          offset: const Offset(0, 32),
                          elevation: 8,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val == 'stock')
                                _showStockInfo = !_showStockInfo;
                              if (val == 'recent')
                                _showRecentTransactions =
                                    !_showRecentTransactions;
                              if (val == 'pricelist')
                                _showPriceList = !_showPriceList;
                              if (val == 'hide_all') {
                                final allHidden = poState.items
                                    .asMap()
                                    .keys
                                    .every((i) => _hiddenDetails.contains(i));
                                if (allHidden) {
                                  _hiddenDetails.clear();
                                } else {
                                  for (
                                    int i = 0;
                                    i < poState.items.length;
                                    i++
                                  ) {
                                    _hiddenDetails.add(i);
                                  }
                                }
                              }
                            });
                          },
                          itemBuilder: (_) {
                            final allHidden = poState.items.asMap().keys.every(
                              (i) => _hiddenDetails.contains(i),
                            );
                            return [
                              PopupMenuItem(
                                value: 'stock',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _HoverableToggleMenuItem(
                                  _showStockInfo
                                      ? 'Hide Available Stock'
                                      : 'Show Available Stock',
                                  _showStockInfo,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'recent',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _HoverableToggleMenuItem(
                                  _showRecentTransactions
                                      ? 'Hide Recent Transactions'
                                      : 'Show Recent Transactions',
                                  _showRecentTransactions,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'pricelist',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _HoverableToggleMenuItem(
                                  _showPriceList
                                      ? 'Hide Price List'
                                      : 'Show Price List',
                                  _showPriceList,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'hide_all',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _HoverableToggleMenuItem(
                                  allHidden
                                      ? 'Show All Additional Information'
                                      : 'Hide All Additional Information',
                                  !allHidden,
                                ),
                              ),
                            ];
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _borderCol),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.settings,
                                  size: 16,
                                  color: Color(0xFF4B5563),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: Color(0xFF4B5563),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 60), // Align with action column
            ],
          )
        else
          // ── Bulk Update Toolbar ──
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withValues(alpha: 0.4),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                    border: Border.all(color: _borderCol),
                  ),
                  child: Row(
                    children: [
                      _buildBulkButton('Update Reporting Tags', onTap: () {}),
                      const SizedBox(width: 10),
                      _buildBulkButton(
                        'Update Account',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                _buildUpdateAccountDialog(availableAccounts),
                          );
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: Colors.blue.shade600,
                        onPressed: () {
                          setState(() {
                            _bulkMode = false;
                            _selectedRows.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),

        // ── Column Headers ──
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: _borderCol),
                    right: BorderSide(color: _borderCol),
                    bottom: BorderSide(color: _borderCol),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      if (_bulkMode)
                        SizedBox(
                          width: 40,
                          child: Center(
                            child: Transform.scale(
                              scale: 0.85,
                              child: Checkbox(
                                value:
                                    _selectedRows.length ==
                                        poState.items.length &&
                                    poState.items.isNotEmpty,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      for (
                                        int i = 0;
                                        i < poState.items.length;
                                        i++
                                      ) {
                                        _selectedRows.add(i);
                                      }
                                    } else {
                                      _selectedRows.clear();
                                    }
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                activeColor: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 40),
                      Expanded(
                        flex: 10,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: _buildHeaderSearchField(
                            label: 'ITEM DETAILS',
                            controller: _itemDetailsSearchCtrl,
                            hintText: 'Search items...',
                            onChanged: (val) {
                              setState(() => _itemDetailsSearchQuery = val);
                            },
                            isSearchVisible: _showSearchItemDetails,
                            onToggle: () {
                              setState(() {
                                _showSearchItemDetails =
                                    !_showSearchItemDetails;
                                if (!_showSearchItemDetails) {
                                  _itemDetailsSearchCtrl.clear();
                                  _itemDetailsSearchQuery = '';
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      _vLine(),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: const Text(
                            'ACCOUNT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      _vLine(),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: const Text(
                            'QUANTITY',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      _vLine(),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                'RATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(width: 4),
                              ZTooltip(
                                message:
                                    'You can perform basic calculations directly in this field using parentheses ( ) and arithmetic operators: + - / *',
                                child: SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="16" height="20" x="4" y="2" rx="2"/><line x1="8" x2="16" y1="6" y2="6"/><line x1="16" x2="16" y1="14" y2="18"/><path d="M16 10h.01"/><path d="M12 10h.01"/><path d="M8 10h.01"/><path d="M12 14h.01"/><path d="M8 14h.01"/><path d="M12 18h.01"/><path d="M8 18h.01"/></svg>',
                                  width: 13,
                                  height: 13,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF0088FF),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (poState.discountLevel == 'item') ...[
                        _vLine(),
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'DISCOUNT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      _vLine(),
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  poState.isReverseCharge
                                      ? 'TAX ( REVERSE CHARGE )'
                                      : 'TAX',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              ZTooltip(
                                message:
                                    'Applicable tax for the items. You can select a tax rate from the list.',
                                child: const Icon(
                                  LucideIcons.helpCircle,
                                  size: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _vLine(),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: const Text(
                            'AMOUNT',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),

        // ── Item Rows ──
        Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: poState.items.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              notifier.reorderItems(oldIndex, newIndex);
              setState(() {
                if (oldIndex < _rowControllers.length &&
                    newIndex <= _rowControllers.length) {
                  final ctrl = _rowControllers.removeAt(oldIndex);
                  _rowControllers.insert(newIndex, ctrl);
                }
              });
            },
            itemBuilder: (ctx, i) {
              final rowItem = poState.items[i];
              if (_itemDetailsSearchQuery.isNotEmpty) {
                final name = (rowItem.productName ?? '').toLowerCase();
                if (!name.contains(_itemDetailsSearchQuery.toLowerCase())) {
                  return SizedBox(key: ValueKey('po_row_$i'));
                }
              }
              return _buildItemRow(
                i,
                allItems,
                availableAccounts,
                poState,
                rowItem,
              );
            },
          ),
        ),

        // ── Table Bottom Border ──
        Row(
          children: [
            Expanded(
              child: Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  border: Border(
                    left: BorderSide(color: _borderCol),
                    right: BorderSide(color: _borderCol),
                    bottom: BorderSide(color: _borderCol),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),

        const SizedBox(height: 16),
        // ── Add Row Buttons (Below Table) ──
        Row(
          children: [
            CompositedTransformTarget(
              link: _addRowDropdownLink,
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _addRowController(
                          initialQty: 1.0,
                          initialRate: 0.0,
                          initialDiscount: 0.0,
                        );
                        notifier.addItemRow();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Add New Row',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: const Color(0xFFE5E7EB),
                    ),
                    GestureDetector(
                      onTap: () => _toggleAddRowDropdown(notifier),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _tableActionBtn(
              icon: Icons.add_circle_outline,
              label: 'Add Items in Bulk',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => BulkItemsDialog(
                    products: allItems,
                    onItemsSelected: (selectedItems) {
                      final List<PurchaseOrderItem> newItems = [];
                      PriceList? pl;
                      if (_selectedPriceListId != null) {
                        try {
                          final activePriceLists = _getCombinedPriceLists();
                          pl = activePriceLists.firstWhere((p) => p.id == _selectedPriceListId);
                        } catch (_) {}
                      }

                      selectedItems.forEach((item, quantity) {
                        double rate = item.costPrice ?? 0.0;
                        double discountVal = 0.0;
                        String? plId;

                        if (pl != null) {
                          rate = pl.calculatePrice(
                            item.id ?? '',
                            item.costPrice ?? 0.0,
                            quantity: quantity.toDouble(),
                          );
                          plId = pl.id;
                          
                          final override = pl.itemRates?.firstWhere(
                            (r) => r.itemId == item.id,
                            orElse: () => const PriceListItemRate(itemId: ''),
                          );
                          if (override != null && override.itemId.isNotEmpty) {
                            if (override.discountPercentage != null) {
                              discountVal = override.discountPercentage!;
                            }
                          }
                        }

                        bool isInterstate = false;
                        if (poState.vendorId != null && poState.vendorId!.isNotEmpty) {
                          try {
                            final vendorsState = ref.read(vendorProvider);
                            final selectedVendor = vendorsState.vendors.firstWhere(
                              (v) => v.id == poState.vendorId,
                              orElse: () => Vendor(id: '', displayName: ''),
                            );
                            if (selectedVendor.id.isNotEmpty &&
                                selectedVendor.sourceOfSupply != null &&
                                selectedVendor.sourceOfSupply!.isNotEmpty &&
                                poState.destinationOfSupply.isNotEmpty) {
                              final srcKL = selectedVendor.sourceOfSupply!.toLowerCase().contains('kerala');
                              final destKL = poState.destinationOfSupply.toLowerCase().contains('kerala');
                              isInterstate = !srcKL && !destKL;
                            }
                          } catch (_) {}
                        }

                        final taxId = isInterstate ? item.interStateTaxId : item.intraStateTaxId;
                        String? taxName = isInterstate ? item.interStateTaxName : item.intraStateTaxName;
                        double taxRate = 0.0;
                        if (taxId != null && taxId.isNotEmpty) {
                          try {
                            final itemsState = ref.read(itemsControllerProvider);
                            final matchingTax = itemsState.taxRates.firstWhere(
                              (t) => t.id == taxId,
                              orElse: () => itemsState.taxGroups.firstWhere(
                                (tg) => tg.id == taxId,
                                orElse: () => TaxRate(id: '', taxName: '', taxRate: 0.0),
                              ),
                            );
                            if (matchingTax.id.isNotEmpty) {
                              taxName = matchingTax.taxName;
                              taxRate = matchingTax.taxRate;
                            }
                          } catch (_) {}
                        }

                        newItems.add(
                          PurchaseOrderItem(
                            productId: item.id ?? '',
                            productName: item.productName,
                            quantity: quantity.toDouble(),
                            rate: rate,
                            discount: discountVal,
                            discountType: 'percentage',
                            priceListId: plId,
                            amount: rate * quantity,
                            hsnCode: item.hsnCode,
                            taxId: taxId,
                            taxName: taxName,
                            taxRate: taxRate,
                            taxAmount: (rate * quantity - discountVal) * taxRate / 100,
                          ),
                        );
                      });
                      notifier.addItemsInBulk(newItems);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildItemRow(
    int index,
    List<Item> allItems,
    List<AccountNode> availableAccounts,
    PurchaseOrderState poState,
    PurchaseOrderItem item,
  ) {
    // Ensure controller exists for this index (no setState during build)
    while (_rowControllers.length <= index) {
      _rowControllers.add(
        _makeRowController(
          initialQty: item.quantity,
          initialRate: item.rate,
          initialDiscount: item.discount,
        ),
      );
    }

    final ctrl = _rowControllers[index];
    if (!ctrl.qtyFocus.hasFocus) {
      final String stateQtyStr = item.quantity == 0 ? '' : (item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString());
      if (ctrl.qtyCtrl.text != stateQtyStr) {
        ctrl.qtyCtrl.text = stateQtyStr;
      }
    }
    if (!ctrl.rateFocus.hasFocus) {
      final String stateRateStr = item.rate == 0 ? '' : (item.rate % 1 == 0 ? item.rate.toInt().toString() : item.rate.toStringAsFixed(2));
      if (ctrl.rateCtrl.text != stateRateStr) {
        ctrl.rateCtrl.text = stateRateStr;
      }
    }
    if (!ctrl.discountFocus.hasFocus) {
      final String stateDiscountStr = item.discount == 0 ? '' : item.discount.toStringAsFixed(2);
      if (ctrl.discountCtrl.text != stateDiscountStr) {
        ctrl.discountCtrl.text = stateDiscountStr;
      }
    }

    final vendors = ref.watch(vendorProvider).vendors;
    final selectedVendor = vendors.firstWhere(
      (v) => v.id == poState.vendorId,
      orElse: () => Vendor(id: '', displayName: ''),
    );
    final isUnregistered = selectedVendor.id.isNotEmpty &&
        (selectedVendor.gstTreatment == null ||
            selectedVendor.gstTreatment!.toLowerCase().contains('unregistered') ||
            selectedVendor.gstTreatment! == 'Unregistered Business');
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    final activePriceLists = ref
        .watch(activePriceListsProvider)
        .where((pl) => pl.transactionType.toLowerCase() == 'purchase')
        .toList();

    final currentPriceListId = item.priceListId;
    final currentPriceList = activePriceLists
        .where((pl) => pl.id == currentPriceListId)
        .firstOrNull;
    bool notIncluded = false;
    if (currentPriceList != null && item.productId.isNotEmpty) {
      if (currentPriceList.priceListType == 'individual_items') {
        notIncluded =
            !(currentPriceList.itemRates?.any(
                  (r) => r.itemId == item.productId,
                ) ??
                false);
      }
    } else if (currentPriceListId != null && item.productId.isNotEmpty) {
      notIncluded = true;
    }

    // Header row — outside-border pattern with 60px sibling
    if (item.isHeader) {
      _headerTextControllers.putIfAbsent(
        index,
        () => TextEditingController(text: item.headerText ?? ''),
      );
      return Row(
        key: ValueKey('po_header_$index'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4FF),
                border: Border(
                  left: BorderSide(color: _borderCol),
                  right: BorderSide(color: _borderCol),
                  bottom: BorderSide(color: _borderCol),
                ),
              ),
              child: Row(
                children: [
                  // Drag handle area
                  SizedBox(
                    width: 40,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Align(
                        alignment: Alignment.center,
                        child: ReorderableDragStartListener(
                          index: index,
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Icon(
                              LucideIcons.gripVertical,
                              size: 16,
                              color: Color(0xFFD1D5DB),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: TextField(
                        controller: _headerTextControllers[index],
                        onChanged: (v) => notifier.updateHeaderText(index, v),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add New Header',
                          hintStyle: const TextStyle(
                            color: _hintColor,
                            fontSize: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(3),
                            borderSide: const BorderSide(color: _fieldBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(3),
                            borderSide: const BorderSide(color: _fieldBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(3),
                            borderSide: const BorderSide(
                              color: Color(0xFF0088FF),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 60px actions column — outside border
          SizedBox(
            width: 60,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  _rowControllers[index].dispose();
                  _headerTextControllers.remove(index);
                  setState(() {
                    _rowControllers.removeAt(index);
                  });
                  notifier.removeItemRow(index);
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: _dangerRed),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return StatefulBuilder(
      key: ValueKey('po_item_row_sb_$index'),
      builder: (context, localState) {
        final bool isRowHovered = _hoveredRows.contains(index) || _activeMenuRowIndex == index;

        // ── Non-header row — outside-border pattern ──
        return MouseRegion(
          key: ValueKey('po_item_row_$index'),
          onEnter: (_) => localState(() => _hoveredRows.add(index)),
          onExit: (_) => localState(() => _hoveredRows.remove(index)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bordered content ──
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _bgWhite,
                  border: Border(
                    left: const BorderSide(color: _borderCol),
                    right: const BorderSide(color: _borderCol),
                    bottom: _hiddenDetails.contains(index)
                        ? const BorderSide(color: _borderCol)
                        : BorderSide.none,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 40px left: checkbox (bulk mode) or drag handle (normal)
                      if (_bulkMode)
                        SizedBox(
                          width: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.scale(
                              scale: 0.85,
                              child: Checkbox(
                                value: _selectedRows.contains(index),
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _selectedRows.add(index);
                                  } else {
                                    _selectedRows.remove(index);
                                  }
                                }),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                activeColor: const Color(0xFF2563EB),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ReorderableDragStartListener(
                                index: index,
                                child: const MouseRegion(
                                  cursor: SystemMouseCursors.grab,
                                  child: Icon(
                                    LucideIcons.gripVertical,
                                    size: 16,
                                    color: Color(0xFFD1D5DB),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // ── ITEM DETAILS (flex:10) ──
                      Expanded(
                        flex: 10,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: item.productId.isEmpty
                              // Empty state: search dropdown
                              ? Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        border: Border.all(color: _borderCol),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        LucideIcons.image,
                                        size: 20,
                                        color: _hintColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FormDropdown<Item>(
                                        value: null,
                                        height: 32,
                                        hint:
                                            'Type or click to select an item.',
                                        hideBorderDefault: true,
                                        itemEstimatedHeight: 48,
                                        maxVisibleItems: 5,
                                        menuWidth: 420,
                                        items: allItems.take(20).toList(),
                                        displayStringForValue: (i) =>
                                            i.productName,
                                        onSearch: (query) async {
                                          if (query.length < 2) return [];
                                          return await ref
                                              .read(
                                                itemsControllerProvider
                                                    .notifier,
                                              )
                                              .searchProductsNoState(query);
                                        },
                                        itemBuilder:
                                            (
                                              i,
                                              isSelected,
                                              isHovered,
                                            ) => Container(
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: isHovered || isSelected
                                                        ? Colors.transparent
                                                        : const Color(0xFFE5E7EB),
                                                    width: 1.0,
                                                  ),
                                                ),
                                              ),
                                              child: _buildStandardLookupRow(
                                                i.productName,
                                                isSelected,
                                                isHovered,
                                                sublabel: i.costPrice != null
                                                    ? 'Purchase Rate: ₹${i.costPrice!.toStringAsFixed(2)}'
                                                    : null,
                                              ),
                                            ),
                                        onChanged: (i) async {
                                          if (i == null) return;

                                          final dupIdx = poState.items.indexWhere((r) => r.productId == i.id);
                                          if (dupIdx != -1) {
                                            ZerpaiToast.error(
                                              context,
                                              "Item '${i.productName}' is already selected in row ${dupIdx + 1}.",
                                            );
                                            return;
                                          }

                                          int targetIndex = index;
                                          if (index > 0 &&
                                              poState
                                                  .items[index - 1]
                                                  .productId
                                                  .isEmpty) {
                                            _rowControllers[index - 1]
                                                .dispose();
                                            _rowControllers.removeAt(index - 1);
                                            notifier.removeItemRow(index - 1);
                                            targetIndex = index - 1;
                                          }

                                          final targetCtrl =
                                               _rowControllers[targetIndex];
                                           targetCtrl.nameCtrl.text =
                                               i.productName;
                                           targetCtrl.qtyCtrl.text = '';
                                           double discountVal = 0.0;
                                           double? priceListRate;
                                           if (_selectedPriceListId != null) {
                                             try {
                                               final activePriceLists = _getCombinedPriceLists();
                                               final pl = activePriceLists.firstWhere((p) => p.id == _selectedPriceListId);
                                               final override = pl.itemRates?.firstWhere(
                                                 (r) => r.itemId == i.id,
                                                 orElse: () => const PriceListItemRate(itemId: ''),
                                               );
                                               if (override != null && override.itemId.isNotEmpty) {
                                                 if (override.discountPercentage != null) {
                                                   discountVal = override.discountPercentage!;
                                                 }
                                               }
                                               priceListRate = pl.calculatePrice(
                                                 i.id ?? '',
                                                 i.costPrice ?? 0.0,
                                               );
                                             } catch (_) {}
                                           }
                                           final finalRate = priceListRate ?? (i.costPrice ?? 0.0);
                                           targetCtrl.rateCtrl.text =
                                               finalRate % 1 == 0
                                               ? finalRate.toInt().toString()
                                               : finalRate.toStringAsFixed(2);
                                           targetCtrl.discountCtrl.text = discountVal.toStringAsFixed(2);
                                           targetCtrl.descCtrl.text =
                                               i.purchaseDescription ?? '';

                                           await notifier.selectProductForItem(
                                             targetIndex,
                                             i,
                                             item.warehouseId ?? poState.warehouseId ?? '',
                                           );

                                           if (_selectedPriceListId != null) {
                                             try {
                                               final activePriceLists = _getCombinedPriceLists();
                                               final pl = activePriceLists.firstWhere((p) => p.id == _selectedPriceListId);
                                               final currentItems = ref.read(purchaseOrderFormNotifierProvider).items;
                                               if (targetIndex >= 0 && targetIndex < currentItems.length) {
                                                 notifier.updateItem(
                                                   targetIndex,
                                                   currentItems[targetIndex].copyWith(
                                                     rate: finalRate,
                                                     priceListId: pl.id,
                                                     discount: discountVal,
                                                     discountType: 'percentage',
                                                   ),
                                                 );
                                               }
                                             } catch (_) {}
                                           }
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              // Selected state: rich display
                              : Builder(
                                  builder: (context) {
                                    final selectedItem = allItems.firstWhere(
                                      (i) => i.id == item.productId,
                                      orElse: () => Item(
                                        productName: item.productName ?? '',
                                        itemCode: item.itemCode ?? '',
                                        type: item.productType ?? 'goods',
                                        unitId: '',
                                      ),
                                    );
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Top row: image + name + ⋯ + ×
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Image thumbnail (32×32)
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF3F4F6),
                                                border: Border.all(
                                                  color: _borderCol,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child:
                                                  selectedItem.primaryImageUrl !=
                                                          null &&
                                                      selectedItem
                                                          .primaryImageUrl!
                                                          .isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      child: Image.network(
                                                        selectedItem
                                                            .primaryImageUrl!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => const Icon(
                                                              LucideIcons.image,
                                                              size: 16,
                                                              color: _hintColor,
                                                            ),
                                                      ),
                                                    )
                                                  : const Icon(
                                                      LucideIcons.image,
                                                      size: 16,
                                                      color: _hintColor,
                                                    ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Name row
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          item.productName ??
                                                              '',
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: _textPrimary,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      // ⋯ menu
                                                      Theme(
                                                        data: Theme.of(context)
                                                            .copyWith(
                                                              hoverColor: Colors
                                                                  .transparent,
                                                            ),
                                                        child: PopupMenuButton<String>(
                                                          onOpened: () => setState(() => _activeMenuRowIndex = index),
                                                          onCanceled: () => setState(() => _activeMenuRowIndex = null),
                                                          tooltip:
                                                              'Show more actions',
                                                          padding:
                                                              EdgeInsets.zero,
                                                          offset: const Offset(
                                                            0,
                                                            30,
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          onSelected: (v) {
                                                            setState(() => _activeMenuRowIndex = null);
                                                            if (v == 'edit') {
                                                              final selectedItem = allItems.firstWhere(
                                                                (i) =>
                                                                    i.id ==
                                                                    item.productId,
                                                                orElse: () => Item(
                                                                  productName:
                                                                      item.productName ??
                                                                      '',
                                                                  itemCode:
                                                                      item.itemCode ??
                                                                      '',
                                                                  type:
                                                                      item.productType ??
                                                                      'goods',
                                                                  unitId: '',
                                                                ),
                                                              );
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder: (ctx) => SalesItemQuickEditDialog(
                                                                  item:
                                                                      selectedItem,
                                                                  onUpdated: (newItem) async {
                                                                     await notifier.selectProductForItem(
                                                                       index,
                                                                       newItem,
                                                                       item.warehouseId ??
                                                                           poState.warehouseId ??
                                                                           '',
                                                                     );
                                                                     double discountVal = 0.0;
                                                                     double? priceListRate;
                                                                     if (_selectedPriceListId != null) {
                                                                       try {
                                                                         final activePriceLists = _getCombinedPriceLists();
                                                                         final pl = activePriceLists.firstWhere((p) => p.id == _selectedPriceListId);
                                                                         final override = pl.itemRates?.firstWhere(
                                                                           (r) => r.itemId == newItem.id,
                                                                           orElse: () => const PriceListItemRate(itemId: ''),
                                                                         );
                                                                         if (override != null && override.itemId.isNotEmpty) {
                                                                           if (override.discountPercentage != null) {
                                                                             discountVal = override.discountPercentage!;
                                                                           }
                                                                         }
                                                                         priceListRate = pl.calculatePrice(
                                                                           newItem.id ?? '',
                                                                           newItem.costPrice ?? 0.0,
                                                                         );
                                                                       } catch (_) {}
                                                                     }
                                                                     final finalRate = priceListRate ?? (newItem.costPrice ?? 0.0);
                                                                     setState(() {
                                                                       ctrl.rateCtrl.text = finalRate % 1 == 0
                                                                           ? finalRate.toInt().toString()
                                                                           : finalRate.toStringAsFixed(2);
                                                                       if (poState.discountLevel == 'item') {
                                                                         ctrl.discountCtrl.text = discountVal.toStringAsFixed(2);
                                                                       }
                                                                     });
                                                                     if (_selectedPriceListId != null) {
                                                                       try {
                                                                         final activePriceLists = _getCombinedPriceLists();
                                                                         final pl = activePriceLists.firstWhere((p) => p.id == _selectedPriceListId);
                                                                         final currentItems = ref.read(purchaseOrderFormNotifierProvider).items;
                                                                         if (index >= 0 && index < currentItems.length) {
                                                                           notifier.updateItem(
                                                                             index,
                                                                             currentItems[index].copyWith(
                                                                               rate: finalRate,
                                                                               priceListId: pl.id,
                                                                               discount: discountVal,
                                                                               discountType: 'percentage',
                                                                             ),
                                                                           );
                                                                         }
                                                                       } catch (_) {}
                                                                     }
                                                                   },
                                                                ),
                                                              );
                                                            }
                                                            if (v ==
                                                                'details') {
                                                              _showItemDetailsSidebar(
                                                                item,
                                                                initialTabIndex:
                                                                    0,
                                                              );
                                                            }
                                                          },
                                                          itemBuilder: (ctx) {
                                                            return [
                                                              PopupMenuItem<
                                                                String
                                                              >(
                                                                value: 'edit',
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                height: 40,
                                                                child: _MenuHoverItem(
                                                                  icon: LucideIcons
                                                                      .pencil,
                                                                  label:
                                                                      'Edit Item',
                                                                ),
                                                              ),
                                                              PopupMenuItem<
                                                                String
                                                              >(
                                                                value:
                                                                    'details',
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                height: 40,
                                                                child: _MenuHoverItem(
                                                                  icon: LucideIcons
                                                                      .shoppingBag,
                                                                  label:
                                                                      'View Item Details',
                                                                ),
                                                              ),
                                                            ];
                                                          },
                                                          child: _buildIconAction(
                                                            LucideIcons
                                                                .moreHorizontal,
                                                            size: 10,
                                                            onTap: null,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      // × close (clears selection)
                                                      _buildIconAction(
                                                        LucideIcons.x,
                                                        size: 10,
                                                        onTap: () {
                                                          notifier.clearItemRow(
                                                            index,
                                                          );
                                                          ctrl.nameCtrl.clear();
                                                          ctrl.qtyCtrl.text =
                                                              '';
                                                          ctrl.rateCtrl.text =
                                                              '0';
                                                          ctrl
                                                                  .discountCtrl
                                                                  .text =
                                                              '0';
                                                          ctrl.descCtrl.clear();
                                                          setState(() {});
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  // Description (if not hidden)
                                                  if (!_hiddenDetails.contains(
                                                    index,
                                                  )) ...[
                                                    const SizedBox(height: 4),
                                                    _HoverableField(
                                                      builder: (isDescHovered) {
                                                        return Focus(
                                                          onFocusChange: (_) => setState(() {}),
                                                          child: Builder(
                                                            builder: (focusCtx) {
                                                              final isDescActive = isDescHovered || Focus.of(focusCtx).hasFocus;
                                                              return AnimatedContainer(
                                                                duration: const Duration(milliseconds: 120),
                                                                height: 72,
                                                                decoration: BoxDecoration(
                                                                  border: Border.all(
                                                                    color: isDescActive
                                                                        ? const Color(0xFF0088FF)
                                                                        : _borderCol,
                                                                    width: 1,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        4,
                                                                      ),
                                                                ),
                                                                child: TextField(
                                                                  controller:
                                                                      ctrl.descCtrl,
                                                                  maxLines: null,
                                                                  expands: true,
                                                                  textAlignVertical:
                                                                      TextAlignVertical
                                                                          .top,
                                                                  style: const TextStyle(
                                                                    fontSize: 12,
                                                                    color: _textPrimary,
                                                                  ),
                                                                  decoration: const InputDecoration(
                                                                    isDense: true,
                                                                    contentPadding:
                                                                        EdgeInsets.symmetric(
                                                                          horizontal: 8,
                                                                          vertical: 6,
                                               ),
                                                                    border:
                                                                        InputBorder.none,
                                                                    hintText:
                                                                        'Add a description to your item',
                                                                    hintStyle: TextStyle(
                                                                      fontSize: 12,
                                                                      color: _hintColor,
                                                                    ),
                                                                  ),
                                                                  onChanged: (v) =>
                                                                      notifier.updateItem(
                                                                        index,
                                                                        item.copyWith(
                                                                          description: v,
                                                                        ),
                                                                      ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                  const SizedBox(height: 6),
                                                  // Type badge + HSN code
                                                  Row(
                                                    children: [
                                                      _infoChip(
                                                        (item.productType ??
                                                                'goods')
                                                            .toUpperCase(),
                                                        item.productType ==
                                                                'service'
                                                            ? const Color(
                                                                0xFFF97316,
                                                              )
                                                            : const Color(
                                                                0xFF0088FF,
                                                              ),
                                                        Colors.white,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        item.productType == 'service'
                                                            ? 'SAC Code: '
                                                            : 'HSN Code: ',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: _hintColor,
                                                        ),
                                                      ),
                                                      CompositedTransformTarget(
                                                        link:
                                                            _rowControllers[index]
                                                                .hsnLink,
                                                        child: GestureDetector(
                                                          onTap: () =>
                                                              _showHsnEditDialog(
                                                                context,
                                                                index,
                                                                item,
                                                                _rowControllers[index]
                                                                    .hsnLink,
                                                              ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .edit_outlined,
                                                                size: 12,
                                                                color: Color(
                                                                  0xFF0088FF,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 3,
                                                              ),
                                                              Text(
                                                                (item.hsnCode !=
                                                                            null &&
                                                                        item
                                                                            .hsnCode!
                                                                            .isNotEmpty)
                                                                    ? item.hsnCode!
                                                                    : 'Update',
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Color(
                                                                    0xFF0088FF,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
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
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ),

                      _vLine(),

                      // ── ACCOUNT (flex:5) ──
                      Expanded(
                        flex: 5,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: CompositedTransformTarget(
                              link: ctrl.accountLink,
                              child: Builder(
                                builder: (btnContext) {
                                  return GestureDetector(
                                    onTap: () {
                                      final renderBox = btnContext.findRenderObject() as RenderBox?;
                                      final offset = renderBox?.localToGlobal(Offset.zero);
                                      _showAccountMenu(
                                        context,
                                        index,
                                        item,
                                        availableAccounts,
                                        link: ctrl.accountLink,
                                        buttonOffset: offset,
                                      );
                                    },
                                    child: () {
                                      bool isHovered = false;
                                      return StatefulBuilder(
                                        builder: (context, setOverlayState) {
                                          return MouseRegion(
                                            onEnter: (_) => setOverlayState(() => isHovered = true),
                                            onExit: (_) => setOverlayState(() => isHovered = false),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: (isHovered || _activeAccountRowIndex == index)
                                                      ? const Color(0xFF0088FF)
                                                      : Colors.transparent,
                                                  width: 1,
                                                ),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: () {
                                                      final displayAccountName =
                                                          (item.accountName != null &&
                                                              item.accountName!.isNotEmpty)
                                                          ? item.accountName!
                                                          : (item.accountId != null &&
                                                                        item
                                                                            .accountId!
                                                                            .isNotEmpty
                                                                    ? availableAccounts
                                                                          .where(
                                                                            (a) =>
                                                                                a.id ==
                                                                                item.accountId,
                                                                          )
                                                                          .firstOrNull
                                                                          ?.name
                                                                    : null) ??
                                                                'Select Account';
                                                      final isPlaceholder =
                                                          displayAccountName ==
                                                          'Select Account';
                                                      return Text(
                                                        displayAccountName,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: isPlaceholder
                                                              ? _hintColor
                                                              : _textPrimary,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      );
                                                    }(),
                                                  ),
                                                  const Icon(
                                                    Icons.arrow_drop_down,
                                                    size: 16,
                                                    color: _hintColor,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }(),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),





                      _vLine(),

                      // ── QUANTITY (flex:5) ──
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _gridField(
                                ctrl.qtyCtrl,
                                focusNode: ctrl.qtyFocus,
                                hint: '0',
                                textAlign: TextAlign.right,
                                valueFontWeight: FontWeight.w400,
                                onChanged: (v) {
                                  final q = double.tryParse(v) ?? 0;
                                  notifier.updateItem(

                                    index,
                                    item.copyWith(quantity: q),
                                  );
                                },
                              ),
                              if (item.productId.isNotEmpty &&
                                  _showStockInfo) ...[
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (context) {
                                    final warehouses =
                                        ref.watch(warehousesProvider).valueOrNull ??
                                        [];
                                    final itemWhId = item.warehouseId ?? poState.warehouseId ?? '';
                                    final wh = warehouses.firstWhere(
                                      (w) =>
                                          w.id == itemWhId,
                                      orElse: () => warehouses.isNotEmpty
                                          ? warehouses.first
                                          : WarehouseModel(
                                              id: '',
                                              name: '',
                                              countryRegion: '',
                                            ),
                                    );
                                    final isSOH = _stockView == 'stockOnHand';
                                    final stocksAsync = ref.watch(itemWarehouseStocksProvider(item.productId));
                                    final double stockValue = stocksAsync.maybeWhen(
                                      data: (stocks) {
                                         final wStock = stocks.firstWhere(
                                           (s) => s.name.toLowerCase() == wh.name.toLowerCase() || s.id == itemWhId,
                                          orElse: () => WarehouseStockRow(
                                            id: itemWhId,
                                             name: wh.name,
                                            accounting: const StockNumbers(onHand: 0, committed: 0),
                                            physical: const StockNumbers(onHand: 0, committed: 0),
                                          ),
                                        );
                                        final numbers = _stockType == 'Accounting'
                                            ? wStock.accounting
                                            : wStock.physical;
                                        return isSOH ? numbers.onHand : numbers.available;
                                      },
                                      orElse: () => 0.0,
                                    );

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${isSOH ? 'Stock on Hand:' : 'Available for Sale:'} ${stockValue.toStringAsFixed(0)} pcs',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: _textPrimary,
                                          ),
                                        ),
                                        if (wh.name.isNotEmpty)
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                LucideIcons.home,
                                                size: 12,
                                                color: Color(0xFF2563EB),
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: WarehouseHoverPopover(
                                                  productId: item.productId,
                                                  warehouseName: wh.name,
                                                  selectedView:
                                                      _stockView == 'stockOnHand'
                                                          ? 'Stock on Hand'
                                                          : 'Available for Sale',
                                                  selectedStockType: _stockType,
                                                  onViewChanged: (v) {
                                                    setState(() {
                                                      _stockView = v == 'Stock on Hand'
                                                          ? 'stockOnHand'
                                                          : 'availableForSale';
                                                    });
                                                  },
                                                  onStockTypeChanged: (t) {
                                                    setState(() {
                                                      _stockType = t;
                                                    });
                                                  },
                                                  onWarehouseChanged: (newName) {
                                                    final selectedWh =
                                                        warehouses.firstWhere(
                                                          (w) =>
                                                              w.name == newName,
                                                        );
                                                    ref
                                                        .read(
                                                          purchaseOrderFormNotifierProvider
                                                              .notifier,
                                                        )
                                                        .updateItemWarehouse(
                                                          index,
                                                          selectedWh.id,
                                                          selectedWh.name,
                                                        );
                                                  },
                                                  child: Text(
                                                    wh.name.toUpperCase(),
                                                    textAlign: TextAlign.left,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF2563EB),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      _vLine(),

                      // ── RATE (flex:5) ──
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _gridField(
                                ctrl.rateCtrl,
                                focusNode: ctrl.rateFocus,
                                onSubmitted: (_) =>
                                    _handleRateCalculation(ctrl),
                                hint: '0',
                                textAlign: TextAlign.right,
                                valueFontWeight: FontWeight.w400,
                                onChanged: (v) {
                                  final r = double.tryParse(v) ?? 0;
                                  notifier.updateItem(
                                    index,
                                    item.copyWith(rate: r),
                                  );
                                },
                              ),
                              if (item.productId.isNotEmpty) ...[
                                if (_showPriceList || _showRecentTransactions)
                                  const SizedBox(height: 4),
                                if (_showPriceList &&
                                    activePriceLists.isNotEmpty)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      if (notIncluded) ...[
                                        ZTooltip(
                                          message:
                                              "This item has not been included in the selected price list. So, the item's default rate has been used.",
                                          direction: ZTooltipDirection.bottom,
                                          child: const Icon(
                                            LucideIcons.alertCircle,
                                            size: 16,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: CompositedTransformTarget(
                                            link: ctrl.priceListLink,
                                            child: MouseRegion(
                                              onEnter: (_) {
                                                if (item.priceListId != null) {
                                                  final pl = activePriceLists
                                                      .where(
                                                        (pl) =>
                                                            pl.id ==
                                                            item.priceListId,
                                                      )
                                                      .firstOrNull;
                                                  if (pl != null) {
                                                    _showValueTooltip(
                                                      context,
                                                      pl.name,
                                                      ctrl.priceListLink,
                                                    );
                                                  }
                                                }
                                              },
                                              onExit: (_) => _hideValueTooltip(),
                                              child: FormDropdown<PriceList>(
                                                height: 32,
                                                value: activePriceLists
                                                    .where((pl) => pl.id == item.priceListId)
                                                    .firstOrNull,
                                                items: activePriceLists
                                                    .where((pl) =>
                                                        pl.transactionType.toLowerCase() == 'purchase' &&
                                                        (pl.priceListType == 'all_items' ||
                                                            (pl.priceListType == 'individual_items' &&
                                                                pl.itemRates != null &&
                                                                pl.itemRates!.any((r) => r.itemId == item.productId))))
                                                    .toList(),
                                                hint: 'Apply Price List',
                                                allowClear: true,
                                                displayStringForValue: (pl) => pl.name,
                                                onChanged: (pl) {
                                                   if (pl != null) {
                                                     final newRate = pl.calculatePrice(
                                                       item.productId,
                                                       item.rate,
                                                       quantity: item.quantity,
                                                     );
                                                     ctrl.rateCtrl.text = newRate.toStringAsFixed(2);
                                                     
                                                     double discountVal = 0.0;
                                                     final override = pl.itemRates?.firstWhere(
                                                       (r) => r.itemId == item.productId,
                                                       orElse: () => const PriceListItemRate(itemId: ''),
                                                     );
                                                     if (override != null && override.itemId.isNotEmpty) {
                                                       if (override.discountPercentage != null) {
                                                         discountVal = override.discountPercentage!;
                                                       }
                                                     }
                                                     
                                                     if (poState.discountLevel == 'item') {
                                                       ctrl.discountCtrl.text = discountVal.toStringAsFixed(2);
                                                     }

                                                     notifier.updateItem(
                                                       index,
                                                       item.copyWith(
                                                         rate: newRate,
                                                         priceListId: pl.id,
                                                         discount: discountVal,
                                                         discountType: 'percentage',
                                                       ),
                                                     );
                                                   } else {
                                                     final originalItem = allItems.firstWhere(
                                                       (i) => i.id == item.productId,
                                                       orElse: () => Item(
                                                         productName: item.productName ?? '',
                                                         itemCode: item.itemCode ?? '',
                                                         type: item.productType ?? 'goods',
                                                         unitId: '',
                                                         costPrice: 0.0,
                                                       ),
                                                     );
                                                     final defaultRate = originalItem.costPrice ?? 0.0;
                                                     ctrl.rateCtrl.text = defaultRate % 1 == 0
                                                         ? defaultRate.toInt().toString()
                                                         : defaultRate.toStringAsFixed(2);
                                                     
                                                     if (poState.discountLevel == 'item') {
                                                       ctrl.discountCtrl.text = '0.00';
                                                     }
                                                     
                                                     notifier.updateItem(
                                                       index,
                                                       item.clearPriceList().copyWith(
                                                         rate: defaultRate,
                                                         discount: 0.0,
                                                       ),
                                                     );
                                                   }
                                                 },
                                                textStyle: const TextStyle(
                                                  fontSize: 11,
                                                  color: _textPrimary,
                                                  fontFamily: 'Inter',
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: _borderCol),
                                              ),
                                            ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (_showRecentTransactions)
                                  Builder(
                                    builder: (innerContext) => GestureDetector(
                                      onTap: () {
                                        _showItemDetailsSidebar(
                                          item,
                                          initialTabIndex: 2,
                                        );
                                      },
                                      child: const Text(
                                        'Recent Transactions',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF0088FF),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                            ),
                          ),
                        ),

                      if (poState.discountLevel == 'item') ...[
                        _vLine(),
                        // ── DISCOUNT (flex:5) ──
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _HoverableField(
                                  builder: (isHovered) {
                                    final fn = ctrl.discountFocus;
                                    return ListenableBuilder(
                                      listenable: fn,
                                      builder: (context, _) {
                                        final isActive = isHovered || fn.hasFocus || (_activeDiscountRowIndex == index);
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 120),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: isActive
                                                  ? const Color(0xFF3B82F6)
                                                  : Colors.transparent,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: ctrl.discountCtrl,
                                                  focusNode: fn,
                                                  onChanged: (v) {
                                                    final d = double.tryParse(v) ?? 0;
                                                    notifier.updateItem(
                                                      index,
                                                      item.copyWith(discount: d),
                                                    );
                                                  },
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: _textPrimary,
                                                  ),
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 12,
                                                    ),
                                                    border: InputBorder.none,
                                                    hintText: '0',
                                                    hintStyle: TextStyle(
                                                      color: _hintColor,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.normal,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              CompositedTransformTarget(
                                                link: ctrl.discountTypeLink,
                                                child: GestureDetector(
                                                  onTap: () => _showDiscountMenu(
                                                    context,
                                                    index,
                                                    item,
                                                  ),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                    color: Colors.transparent,
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          item.discountType == 'percentage'
                                                              ? '%'
                                                              : '₹',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: _textPrimary,
                                                            fontWeight: FontWeight.normal,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 2),
                                                        const Icon(
                                                          Icons.arrow_drop_down,
                                                          size: 14,
                                                          color: _hintColor,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      _vLine(),

                      // ── TAX (flex:6) ──
                      Expanded(
                        flex: 6,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: CompositedTransformTarget(
                              link: ctrl.taxLink,
                              child: GestureDetector(
                                onTap: isUnregistered
                                    ? null
                                    : () {
                                        final itemsState = ref.read(
                                          itemsControllerProvider,
                                        );
                                        _showTaxPopover(
                                          context,
                                          index,
                                          item,
                                          itemsState.taxGroups,
                                        );
                                      },
                                child: () {
                                  bool isHovered = false;
                                  return StatefulBuilder(
                                    builder: (context, setOverlayState) {
                                      return MouseRegion(
                                        onEnter: (_) => setOverlayState(() => isHovered = true),
                                        onExit: (_) => setOverlayState(() => isHovered = false),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: (!isUnregistered && (isHovered || _activeTaxRowIndex == index))
                                                  ? const Color(0xFF0088FF)
                                                  : Colors.transparent,
                                              width: 1,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  (isUnregistered || item.taxId == null)
                                                      ? 'Select Tax'
                                                      : '${item.taxName} [${item.taxRate}%]',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: (isUnregistered || item.taxId == null)
                                                        ? _hintColor
                                                        : _textPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (item.taxId != null && !isUnregistered && isHovered)
                                                GestureDetector(
                                                  onTap: () {
                                                    notifier.updateItem(
                                                      index,
                                                      item.clearTax(),
                                                    );
                                                  },
                                                  child: const Padding(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 14,
                                                      color: _dangerRed,
                                                    ),
                                                  ),
                                                ),
                                              const Icon(
                                                Icons.arrow_drop_down,
                                                size: 16,
                                                color: _hintColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }(),
                              ),
                            ),
                          ),
                        ),
                      ),

                      _vLine(),

                      // ── AMOUNT (flex:4) ──
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                item.amount.toStringAsFixed(2),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
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

             // ── 60px Actions column (outside border) ──
             SizedBox(
               width: 60,
               child: Padding(
                 padding: const EdgeInsets.only(top: 8),
                 child: isRowHovered
                     ? Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           CompositedTransformTarget(
                             link: _rowControllers[index].rowActionsMenuLink,
                             child: GestureDetector(
                               onTap: () => _showItemMenu(
                                 context,
                                 index,
                                 item,
                                 _rowControllers[index].rowActionsMenuLink,
                                 allItems,
                               ),
                               child: const Padding(
                                 padding: EdgeInsets.all(4),
                                 child: Icon(
                                   LucideIcons.moreVertical,
                                   size: 16,
                                   color: _hintColor,
                                 ),
                               ),
                             ),
                           ),
                           GestureDetector(
                             onTap: () {
                               if (poState.items.length > 1) {
                                 _rowControllers[index].dispose();
                                 setState(() {
                                   _rowControllers.removeAt(index);
                                   _hoveredRows.clear();
                                 });
                                 notifier.removeItemRow(index);
                               }
                             },
                             child: const Padding(
                               padding: EdgeInsets.all(4),
                               child: Icon(LucideIcons.x, size: 14, color: _dangerRed),
                             ),
                           ),
                         ],
                       )
                     : const SizedBox.shrink(),
               ),
             ),
          ],
        ),

        // ── Expanded properties grey bar (account + reporting tags) ──
        if (!_hiddenDetails.contains(index))
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    border: Border(
                      left: BorderSide(color: _borderCol),
                      right: BorderSide(color: _borderCol),
                      top: BorderSide(color: _borderCol),
                    ),
                  ),
                  child: _itemExpandedProperties(
                    index,
                    item,
                    availableAccounts,
                    poState,
                  ),
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),
        ],
      ),
    );
      },
    );
  }
  void _closeTaxOverlay() {
    if (_taxOverlay != null) {
      _taxOverlay!.remove();
      _taxOverlay = null;
      setState(() {
        _activeTaxRowIndex = null;
      });
    }
  }

  void _closeHsnOverlay() {
    _hsnOverlay?.remove();
    _hsnOverlay = null;
  }

  void _showDiscountMenu(
    BuildContext context,
    int index,
    PurchaseOrderItem item, {
    LayerLink? link,
  }) {
    _closeDiscountOverlay();
    setState(() {
      _activeDiscountRowIndex = index;
    });
    final ctrl = _rowControllers[index];
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

    _discountOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeDiscountOverlay,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: link ?? ctrl.discountTypeLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 42),
            child: Material(
              color: Colors.transparent,
              child: TapRegion(
                onTapOutside: (_) => _closeDiscountOverlay(),
                child: _DiscountTypePopover(
                  selectedType: item.discountType,
                  onSelected: (type) {
                    notifier.updateItem(
                      index,
                      item.copyWith(discountType: type),
                    );
                    _closeDiscountOverlay();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_discountOverlay!);
  }

  void _closeDiscountOverlay() {
    if (_discountOverlay != null) {
      _discountOverlay!.remove();
      _discountOverlay = null;
      setState(() {
        _activeDiscountRowIndex = null;
      });
    }
  }

  void _showTaxPopover(
    BuildContext context,
    int index,
    PurchaseOrderItem item,
    List<TaxRate> taxes,
  ) {
    _closeTaxOverlay();
    setState(() {
      _activeTaxRowIndex = index;
    });
    final ctrl = _rowControllers[index];
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

    _taxOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeTaxOverlay,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: ctrl.taxLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 42),
            child: Material(
              color: Colors.transparent,
              child: TapRegion(
                onTapOutside: (_) => _closeTaxOverlay(),
                child: _TaxSelectionPopover(
                  selectedTaxId: item.taxId,
                  onTaxSelected: (tax) {
                    notifier.updateItem(
                      index,
                      item.copyWith(
                        taxId: tax.id,
                        taxName: tax.taxName,
                        taxRate: tax.taxRate,
                      ),
                    );
                    _closeTaxOverlay();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_taxOverlay!);
  }

  // ── HSN Edit Dialog ──────────────────────────────────────────────────────────
  void _showHsnEditDialog(
    BuildContext context,
    int index,
    PurchaseOrderItem item,
    LayerLink link,
  ) {
    _closeHsnOverlay();
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

    _hsnOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeHsnOverlay,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            width: 320,
            child: CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
              offset: const Offset(-100, 2),
              child: Material(
                color: Colors.transparent,
                child: TapRegion(
                  onTapOutside: (_) => _closeHsnOverlay(),
                  child: _HSNCodeEditPopover(
                    initialHsnCode: item.hsnCode ?? '',
                    isService: item.productType == 'service',
                    onCancel: _closeHsnOverlay,
                    onSave: (hsn) {
                      notifier.updateItem(index, item.copyWith(hsnCode: hsn));
                      _closeHsnOverlay();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_hsnOverlay!);
  }

  // ── Totals Section ──────────────────────────────────────────────────────────
  Widget _infoChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _gridField(
    TextEditingController ctrl, {
    String hint = '',
    TextAlign textAlign = TextAlign.start,
    FontWeight valueFontWeight = FontWeight.w600,
    required Function(String) onChanged,
    Function(String)? onSubmitted,
    FocusNode? focusNode,
  }) {
    final fn = focusNode ?? FocusNode();
    return _HoverableField(
      builder: (isHovered) {
        return ListenableBuilder(
          listenable: fn,
          builder: (context, _) {
            final isActive = isHovered || fn.hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF3B82F6)
                      : Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: ctrl,
                focusNode: fn,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: valueFontWeight,
                  color: _textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: _hintColor.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _vLine() =>
      const VerticalDivider(width: 1, color: _borderCol, thickness: 1);

  // ═══════════════════════════════════════════════════════════════════════════
  // REPORTING TAGS
  // ═══════════════════════════════════════════════════════════════════════════

  void _closeReportingTagsOverlay() {
    _reportingTagsOverlay?.remove();
    _reportingTagsOverlay = null;
  }

  void _toggleReportingTagsOverlay(BuildContext context, dynamic row, LayerLink link) {
    if (_reportingTagsOverlay != null) {
      _closeReportingTagsOverlay();
      return;
    }

    final Map<String, String> localTags = Map<String, String>.from(row.reportingTags);

    _reportingTagsOverlay = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeReportingTagsOverlay,
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.transparent)),
              CompositedTransformFollower(
                link: link,
                showWhenUnlinked: false,
                offset: const Offset(0, 32),
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      return Container(
                        width: 320,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Reporting Tags',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                InkWell(
                                  onTap: _closeReportingTagsOverlay,
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'ADGF',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 6),
                            FormDropdown<String>(
                              value: localTags['adgf'],
                              items: const ['None', 'Option 1', 'Option 2'],
                              hint: 'None',
                              height: 32,
                              onChanged: (val) {
                                if (val != null) {
                                  setOverlayState(() {
                                    localTags['adgf'] = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Schedule',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 6),
                            FormDropdown<String>(
                              value: localTags['schedule'],
                              items: const ['None', 'Option 1', 'Option 2'],
                              hint: 'None',
                              height: 32,
                              onChanged: (val) {
                                if (val != null) {
                                  setOverlayState(() {
                                    localTags['schedule'] = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Demo advanced reporting tag',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 6),
                            FormDropdown<String>(
                              value: localTags['demo_tag'],
                              items: const ['None', 'Option 1', 'Option 2'],
                              hint: 'None',
                              height: 32,
                              onChanged: (val) {
                                if (val != null) {
                                  setOverlayState(() {
                                    localTags['demo_tag'] = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ZButton.secondary(
                                  label: 'Cancel',
                                  onPressed: _closeReportingTagsOverlay,
                                ),
                                const SizedBox(width: 8),
                                ZButton.primary(
                                  label: 'Update',
                                  onPressed: () {
                                    setState(() {
                                      row.reportingTags['adgf'] = localTags['adgf']!;
                                      row.reportingTags['schedule'] = localTags['schedule']!;
                                      row.reportingTags['demo_tag'] = localTags['demo_tag']!;
                                    });
                                    _closeReportingTagsOverlay();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_reportingTagsOverlay!);
  }

  String? _getDefaultDiscountAccountId(List<AccountNode> availableAccounts) {
    try {
      final match = availableAccounts.firstWhere(
        (a) {
          final name = a.userAccountName.isNotEmpty ? a.userAccountName : a.systemAccountName;
          return name.toLowerCase().contains('purchase discount') || name.toLowerCase().contains('purchase discounts');
        },
      );
      return match.id;
    } catch (_) {
      return null;
    }
  }

  List<AccountNode> _getExpenseAccountsForDropdown(List<AccountNode> availableAccounts) {
    final expenseAccounts = availableAccounts.where((node) {
      final group = node.accountGroup.toLowerCase();
      return group.contains('expense');
    }).toList();

    final Map<String, List<AccountNode>> grouped = {};
    for (final acc in expenseAccounts) {
      grouped.putIfAbsent(acc.accountType, () => []).add(acc);
    }

    final List<AccountNode> flattened = [];
    grouped.forEach((type, list) {
      flattened.add(
        AccountNode(
          id: 'header_$type',
          systemAccountName: type,
          userAccountName: type,
          name: type,
          accountGroup: 'Expenses',
          accountType: type,
          isSystem: false,
          isDeletable: false,
          isActive: false,
        ),
      );
      flattened.addAll(list);
    });
    return flattened;
  }

  Widget _buildDiscountAccountDropdown(
    List<AccountNode> availableAccounts,
    PurchaseOrderState poState,
    PurchaseOrderNotifier notifier,
  ) {
    final currentId = poState.discountAccountId;
    String? targetId = currentId;
    if (currentId == null || currentId.isEmpty) {
      final defId = _getDefaultDiscountAccountId(availableAccounts);
      if (defId != null) {
        targetId = defId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifier.updateField(discountAccountId: defId);
        });
      }
    }

    final selectedAcc = availableAccounts.firstWhere(
      (a) => a.id == targetId,
      orElse: () => const AccountNode(
        id: '',
        systemAccountName: '',
        userAccountName: '',
        name: '',
        accountGroup: '',
        accountType: '',
        isSystem: false,
        isDeletable: true,
        isActive: true,
      ),
    );

    final dropdownItems = _getExpenseAccountsForDropdown(availableAccounts);

    return FormDropdown<AccountNode>(
      height: 36,
      value: selectedAcc,
      items: dropdownItems,
      displayStringForValue: (a) => a.name.isEmpty
          ? 'Discount Account'
          : (a.id.startsWith('header_')
              ? a.accountType
              : a.name),
      onChanged: (v) {
        if (v != null && !v.id.startsWith('header_')) {
          notifier.updateField(discountAccountId: v.id);
        }
      },
      borderRadius: BorderRadius.circular(6),
      hideBorderDefault: true,
      prefixWidget: const Icon(
        LucideIcons.shoppingBag,
        size: 16,
        color: Color(0xFF6B7280),
      ),
      isItemEnabled: (account) => !account.id.startsWith('header_'),
      itemBuilder: (account, isSelected, isHovered) {
        if (account.id.startsWith('header_')) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Text(
              account.accountType,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
          );
        }
        final name = account.userAccountName.isNotEmpty
            ? account.userAccountName
            : account.systemAccountName;
        return _buildStandardLookupRow(
          name,
          isSelected,
          isHovered,
          indentation: 16,
        );
      },
    );
  }

  Widget _buildRowDiscountAccountDropdown(
    int index,
    PurchaseOrderItem item,
    List<AccountNode> availableAccounts,
    PurchaseOrderNotifier notifier,
  ) {
    final currentId = item.discountAccountId;
    String? targetId = currentId;
    if (currentId == null || currentId.isEmpty) {
      final defId = _getDefaultDiscountAccountId(availableAccounts);
      if (defId != null) {
        targetId = defId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifier.updateItem(
            index,
            item.copyWith(discountAccountId: defId),
          );
        });
      }
    }

    final selectedAcc = availableAccounts.firstWhere(
      (a) => a.id == targetId,
      orElse: () => const AccountNode(
        id: '',
        systemAccountName: '',
        userAccountName: '',
        name: '',
        accountGroup: '',
        accountType: '',
        isSystem: false,
        isDeletable: true,
        isActive: true,
      ),
    );

    final dropdownItems = _getExpenseAccountsForDropdown(availableAccounts);

    return FormDropdown<AccountNode>(
      height: 32,
      value: selectedAcc,
      textStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: selectedAcc.id.isNotEmpty ? _textPrimary : _hintColor,
      ),
      items: dropdownItems,
      displayStringForValue: (a) => a.name.isEmpty
          ? 'Discount Account'
          : (a.id.startsWith('header_')
              ? a.accountType
              : a.name),
      onChanged: (v) {
        if (v != null && !v.id.startsWith('header_')) {
          notifier.updateItem(
            index,
            item.copyWith(discountAccountId: v.id),
          );
        }
      },
      borderRadius: BorderRadius.circular(4),
      hideBorderDefault: true,
      fillColor: Colors.transparent,
      border: Border.all(color: Colors.transparent),
      prefixWidget: const Icon(
        LucideIcons.shoppingBag,
        size: 16,
        color: Color(0xFF6B7280),
      ),
      isItemEnabled: (account) => !account.id.startsWith('header_'),
      itemBuilder: (account, isSelected, isHovered) {
        if (account.id.startsWith('header_')) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Text(
              account.accountType,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
          );
        }
        final name = account.userAccountName.isNotEmpty
            ? account.userAccountName
            : account.systemAccountName;
        return _buildStandardLookupRow(
          name,
          isSelected,
          isHovered,
          indentation: 16,
        );
      },
    );
  }

  Widget _buildTransactionDiscountAccountField(
    List<AccountNode> availableAccounts,
    PurchaseOrderState poState,
    PurchaseOrderNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Discount Account*',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: _fieldBorder),
                    borderRadius: BorderRadius.circular(4),
                    color: _bgWhite,
                  ),
                  child: _buildDiscountAccountDropdown(availableAccounts, poState, notifier),
                ),
                const SizedBox(height: 4),
                const SizedBox(
                  width: 200,
                  child: Text(
                    'You can create a new account with type as Expense or Other Expense.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _itemExpandedProperties(
    int index,
    PurchaseOrderItem item,
    List<AccountNode> accounts,
    PurchaseOrderState poState,
  ) {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (poState.discountLevel == 'item') ...[
          SizedBox(
            width: 200,
            child: _buildRowDiscountAccountDropdown(index, item, accounts, notifier),
          ),
          const SizedBox(width: 16),
        ],
        // Reporting Tags
        _propertyButton(
          link: _rowControllers[index].reportingTagsLink,
          iconWidget: SvgPicture.string(
            '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#22C55E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13.172 2a2 2 0 0 1 1.414.586l6.71 6.71a2.4 2.4 0 0 1 0 3.408l-4.592 4.592a2.4 2.4 0 0 1-3.408 0l-6.71-6.71A2 2 0 0 1 6 9.172V3a1 1 0 0 1 1-1z"/><path d="M2 7v6.172a2 2 0 0 0 .586 1.414l6.71 6.71a2.4 2.4 0 0 0 3.191.193"/><circle cx="10.5" cy="6.5" r=".5" fill="#22C55E"/></svg>',
            width: 16,
            height: 16,
          ),
          label: 'Reporting Tags',
          onTap: () => _toggleReportingTagsOverlay(context, _rowControllers[index], _rowControllers[index].reportingTagsLink),
        ),
      ],
    );
  }

  Widget _propertyButton({
    LayerLink? link,
    IconData? icon,
    Widget? iconWidget,
    required String label,
    String? value,
    Color color = const Color(0xFF6B7280),
    required VoidCallback onTap,
  }) {
    Widget content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null)
              iconWidget
            else if (icon != null)
              Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _textPrimary.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 4),
              Text(
                '($value)',
                style: const TextStyle(
                  fontSize: 12,
                  color: _linkBlue,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: _hintColor),
          ],
        ),
      ),
    );

    if (link != null) {
      return CompositedTransformTarget(link: link, child: content);
    }
    return content;
  }

  void _closeAccountOverlay() {
    if (_accountOverlay != null) {
      _accountOverlay!.remove();
      _accountOverlay = null;
      setState(() {
        _activeAccountRowIndex = null;
      });
    }
  }

  void _showAccountMenu(
    BuildContext context,
    int index,
    PurchaseOrderItem item,
    List<AccountNode> accounts, {
    LayerLink? link,
    Offset? buttonOffset,
  }) {
    _closeAccountOverlay();
    setState(() {
      _activeAccountRowIndex = index;
    });

    final overlay = Overlay.of(context);
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

    final screenHeight = MediaQuery.of(context).size.height;
    bool showAbove = false;
    if (buttonOffset != null) {
      if (buttonOffset.dy + 400 > screenHeight && buttonOffset.dy > 400) {
        showAbove = true;
      }
    }

    _accountOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeAccountOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: link ?? _rowControllers[index].accountLink,
            showWhenUnlinked: false,
            targetAnchor: showAbove ? Alignment.topLeft : Alignment.bottomLeft,
            followerAnchor: showAbove ? Alignment.bottomLeft : Alignment.topLeft,
            offset: Offset.zero,
            child: Material(
              color: Colors.transparent,
              child: TapRegion(
                onTapOutside: (_) => _closeAccountOverlay(),
                child: _AccountSelectionPopover(
                  accounts: accounts,
                  selectedAccountId: item.accountId,
                  onSelected: (acc) {
                    notifier.updateItem(
                      index,
                      item.copyWith(accountId: acc.id, accountName: acc.name),
                    );
                    _closeAccountOverlay();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_accountOverlay!);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES (left) + TOTALS (right) — Zoho style
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _notesAndTotals(List<Item> allItems, PurchaseOrderState poState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // LEFT — Notes
        _notesSection(),
        const SizedBox(width: 64), // Fixed gap for "immediate" placement
        // Totals panel (Appearing immediately to the right of notes)
        SizedBox(width: 420, child: _buildTotalsPanel(poState)),
      ],
    );
  }

  Widget _buildTotalsPanel(PurchaseOrderState poState) {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    final accountsState = ref.watch(chartOfAccountsProvider);
    final List<AccountNode> availableAccounts = [];
    void collect(List<AccountNode> nodes) {
      for (final node in nodes) {
        availableAccounts.add(node);
        collect(node.children);
      }
    }
    collect(accountsState.roots);

    final totalQty = poState.items
        .where((i) => !i.isHeader)
        .fold(0.0, (sum, i) => sum + i.quantity);
    final qtyStr = totalQty % 1 == 0
        ? totalQty.toInt().toString()
        : totalQty.toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        border: Border.all(color: _borderCol),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sub Total + Total Quantity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sub Total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _labelColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total Quantity : $qtyStr',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _labelColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                poState.subTotal.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Per-tax breakdown rows
          ..._buildTaxBreakdownRows(poState),
          // Total Tax Amount with editable field + pencil
          if (poState.items.any((i) => !i.isHeader && i.productId.isNotEmpty))
            _buildTotalTaxRow(poState),
          if (poState.discountLevel == 'transaction') ...[
            const SizedBox(height: 12),
            _discountRow(poState),
            if (poState.discount > 0)
              _buildTransactionDiscountAccountField(availableAccounts, poState, notifier),
          ],
          const SizedBox(height: 12),
          // TDS / TCS dynamically swapped with Adjustment based on selected type
          if (poState.tdsTcsType != 'tcs') ...[
            _tdsTcsRow(poState),
            const SizedBox(height: 12),
            _adjustmentRow(),
          ] else ...[
            _adjustmentRow(),
            const SizedBox(height: 12),
            _tdsTcsRow(poState),
          ],
          const Divider(height: 32),
          // Total
          _totalLine(
            'Total',
            poState.total.toStringAsFixed(2),
            isBold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaxBreakdownRows(PurchaseOrderState poState) {
    if (poState.vendorId == null || poState.vendorId!.isEmpty) {
      return [];
    }

    final Map<String, ({String name, double rate, double amount})> groups = {};
    for (final item in poState.items.where(
      (i) => !i.isHeader && i.taxAmount > 0,
    )) {
      final key = item.taxId ?? item.taxName ?? '';
      if (key.isEmpty) continue;
      if (groups.containsKey(key)) {
        final e = groups[key]!;
        groups[key] = (
          name: e.name,
          rate: e.rate,
          amount: e.amount + item.taxAmount,
        );
      } else {
        groups[key] = (
          name: item.taxName ?? 'Tax',
          rate: item.taxRate,
          amount: item.taxAmount,
        );
      }
    }

    final vendorsState = ref.read(vendorProvider);
    final vendor = vendorsState.vendors.firstWhere(
      (v) => v.id == poState.vendorId,
      orElse: () => Vendor(id: '', displayName: ''),
    );
    final source = (vendor.sourceOfSupply ?? '').toLowerCase();
    final destination = poState.destinationOfSupply.toLowerCase();
    final isKerala = source.contains('kerala') && destination.contains('kerala');

    final widgets = <Widget>[];
    for (final tax in groups.values) {
      if (isKerala) {
        final half = tax.rate / 2;
        final halfAmt = tax.amount / 2;
        final halfStr = half % 1 == 0
            ? half.toInt().toString()
            : half.toStringAsFixed(1);

        widgets.add(
          Row(
            children: [
              Text(
                'CGST$halfStr [$halfStr%]',
                style: const TextStyle(fontSize: 13, color: _labelColor),
              ),
              const Spacer(),
              Text(
                halfAmt.toStringAsFixed(2),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          Row(
            children: [
              Text(
                'SGST$halfStr [$halfStr%]',
                style: const TextStyle(fontSize: 13, color: _labelColor),
              ),
              const Spacer(),
              Text(
                halfAmt.toStringAsFixed(2),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 12));
      } else {
        final rateStr = tax.rate % 1 == 0
            ? tax.rate.toInt().toString()
            : tax.rate.toStringAsFixed(1);

        widgets.add(
          Row(
            children: [
              Text(
                'IGST$rateStr [$rateStr%]',
                style: const TextStyle(fontSize: 13, color: _labelColor),
              ),
              const Spacer(),
              Text(
                tax.amount.toStringAsFixed(2),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  Widget _buildTotalTaxRow(PurchaseOrderState poState) {
    return Row(
      children: [
        const Text(
          'Total Tax Amount',
          style: TextStyle(fontSize: 13, color: _labelColor),
        ),
        const Spacer(),
        StatefulBuilder(
          builder: (context, setStateTax) {
            return _TaxAmountField(
              value: poState.taxAmount.toStringAsFixed(2),
            );
          },
        ),
        const SizedBox(width: 6),
        CompositedTransformTarget(
          link: _totalTaxAmountLink,
          child: GestureDetector(
            onTap: () => _showTaxAmountEditPopover(context, poState),
            child: const Icon(
              Icons.edit_outlined,
              size: 14,
              color: Color(0xFF0088FF),
            ),
          ),
        ),
      ],
    );
  }

  void _showTaxAmountEditPopover(
    BuildContext context,
    PurchaseOrderState poState,
  ) {
    _closeTaxAmountOverlay();

    final vendorsState = ref.read(vendorProvider);
    final vendor = vendorsState.vendors.firstWhere(
      (v) => v.id == poState.vendorId,
      orElse: () => Vendor(id: '', displayName: ''),
    );
    final source = (vendor.sourceOfSupply ?? '').toLowerCase();
    final destination = poState.destinationOfSupply.toLowerCase();
    final isKerala = source.contains('kerala') && destination.contains('kerala');

    final Map<String, ({String name, double rate, double amount})>
    initialTaxes = {};
    for (final item in poState.items.where(
      (i) => !i.isHeader && i.taxAmount > 0,
    )) {
      final key = item.taxId ?? item.taxName ?? '';
      if (key.isEmpty) continue;

      if (isKerala) {
        final half = item.taxRate / 2;
        final halfAmt = item.taxAmount / 2;
        final halfStr = half % 1 == 0
            ? half.toInt().toString()
            : half.toStringAsFixed(1);

        // Add CGST
        final cgstKey = '${key}_CGST';
        if (initialTaxes.containsKey(cgstKey)) {
          final e = initialTaxes[cgstKey]!;
          initialTaxes[cgstKey] = (
            name: e.name,
            rate: e.rate,
            amount: e.amount + halfAmt,
          );
        } else {
          initialTaxes[cgstKey] = (
            name: 'CGST$halfStr',
            rate: half,
            amount: halfAmt,
          );
        }

        // Add SGST
        final sgstKey = '${key}_SGST';
        if (initialTaxes.containsKey(sgstKey)) {
          final e = initialTaxes[sgstKey]!;
          initialTaxes[sgstKey] = (
            name: e.name,
            rate: e.rate,
            amount: e.amount + halfAmt,
          );
        } else {
          initialTaxes[sgstKey] = (
            name: 'SGST$halfStr',
            rate: half,
            amount: halfAmt,
          );
        }
      } else {
        final rateStr = item.taxRate % 1 == 0
            ? item.taxRate.toInt().toString()
            : item.taxRate.toStringAsFixed(1);

        if (initialTaxes.containsKey(key)) {
          final e = initialTaxes[key]!;
          initialTaxes[key] = (
            name: e.name,
            rate: e.rate,
            amount: e.amount + item.taxAmount,
          );
        } else {
          initialTaxes[key] = (
            name: 'IGST$rateStr',
            rate: item.taxRate,
            amount: item.taxAmount,
          );
        }
      }
    }

    _taxAmountOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeTaxAmountOverlay,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: _totalTaxAmountLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: const Offset(-150, 10),
            child: Material(
              color: Colors.transparent,
              child: _TaxAmountEditPopover(
                initialTaxes: initialTaxes,
                onCancel: _closeTaxAmountOverlay,
                onSave: (editedAmounts) {
                  _closeTaxAmountOverlay();
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_taxAmountOverlay!);
  }

  void _closeTaxAmountOverlay() {
    _taxAmountOverlay?.remove();
    _taxAmountOverlay = null;
  }

  Widget _discountRow(PurchaseOrderState s) {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    return Row(
      children: [
        const Text(
          'Discount',
          style: TextStyle(fontSize: 13, color: _labelColor),
        ),
        const Spacer(),
        (() {
          bool isHovered = false;
          bool isFocused = false;
          return StatefulBuilder(
            builder: (context, setStateLocal) {
              return Focus(
                onFocusChange: (focus) => setStateLocal(() => isFocused = focus),
                child: MouseRegion(
                  onEnter: (_) => setStateLocal(() => isHovered = true),
                  onExit: (_) => setStateLocal(() => isHovered = false),
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: (isHovered || isFocused) ? const Color(0xFF3B82F6) : _fieldBorder,
                        width: (isHovered || isFocused) ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: _bgWhite,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: _discountCtrl,
                            onChanged: (v) =>
                                notifier.updateField(discount: double.tryParse(v) ?? 0),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: _fieldBorder,
                        ),
                        CompositedTransformTarget(
                          link: _discountTypeLink,
                          child: GestureDetector(
                            onTap: _showDiscountTypePopover,
                            child: SizedBox(
                              width: 45,
                              height: 32,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    s.discountType == 'percentage' ? '%' : '₹',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                    color: Color(0xFF1F2937),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        })(),
        const SizedBox(width: 16),
        Text(
          s.discountValue.toStringAsFixed(2),
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  OverlayEntry? _discountTypeOverlay;

  void _showDiscountTypePopover() {
    _closeDiscountTypeOverlay();

    final poState = ref.read(purchaseOrderFormNotifierProvider);
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

    _discountTypeOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeDiscountTypeOverlay,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: _discountTypeLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DiscountTypeItem(
                      text: '%',
                      isSelected: poState.discountType == 'percentage',
                      onTap: () {
                        notifier.updateField(discountType: 'percentage');
                        _closeDiscountTypeOverlay();
                      },
                    ),
                    _DiscountTypeItem(
                      text: '₹',
                      isSelected: poState.discountType == 'fixed',
                      onTap: () {
                        notifier.updateField(discountType: 'fixed');
                        _closeDiscountTypeOverlay();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_discountTypeOverlay!);
  }

  void _closeDiscountTypeOverlay() {
    _discountTypeOverlay?.remove();
    _discountTypeOverlay = null;
  }

  Widget _tdsTcsRow(PurchaseOrderState s) {
    final isTcs = s.tdsTcsType == 'tcs';
    final selectedRate = isTcs
        ? _tcsRatesList.firstWhere(
            (r) => r['id'] == s.tdsTcsId,
            orElse: () => <String, dynamic>{},
          )
        : _tdsRatesList.firstWhere(
            (r) => r['id'] == s.tdsTcsId,
            orElse: () => <String, dynamic>{},
          );
    String displayText = 'Select a Tax';
    double ratePercent = 0.0;
    if (selectedRate.isNotEmpty) {
      final taxName = selectedRate['tax_name'] ?? '';
      final d = double.tryParse(
        (isTcs ? selectedRate['rate'] : selectedRate['base_rate'])?.toString() ?? '0',
      );
      ratePercent = d ?? 0.0;
      final baseRateStr = (d == null) 
          ? '' 
          : (d == d.toInt() ? '${d.toInt()}%' : '$d%');
      displayText = "$taxName [$baseRateStr]";
    }

    final double calculatedAmount = (s.subTotal - s.discountValue) * (ratePercent / 100);
    final displayAmount = calculatedAmount.toStringAsFixed(2);

    return RadioGroup<String>(
      groupValue: s.tdsTcsType ?? 'none',
      onChanged: (val) {
        if (val != null) {
          ref
              .read(purchaseOrderFormNotifierProvider.notifier)
              .updateField(
                tdsTcsType: val,
                tdsTcsId: '',
                tdsTcsRate: 0.0,
              );
        }
      },
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: Radio<String>(value: 'tds', activeColor: _linkBlue),
              ),
              const SizedBox(width: 8),
              const Text('TDS', style: TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: Radio<String>(value: 'tcs', activeColor: _linkBlue),
              ),
              const SizedBox(width: 8),
              const Text('TCS', style: TextStyle(fontSize: 13)),
            ],
          ),
          const Spacer(),
          if (s.tdsTcsType != 'none' && s.tdsTcsType != null) ...[
            SizedBox(
              width: 160,
              child: CompositedTransformTarget(
                link: _tdsLink,
                child: Builder(
                  builder: (btnContext) {
                    return GestureDetector(
                      onTap: () async {
                        if (s.tdsTcsType == 'tcs' ? _tcsRatesList.isEmpty : _tdsRatesList.isEmpty) {
                          await _loadTdsRates();
                        }
                        if (!context.mounted) return;
                        final renderBox = btnContext.findRenderObject() as RenderBox?;
                        final offset = renderBox?.localToGlobal(Offset.zero);
                        _showTdsMenu(context, s, offset);
                      },
                      child: () {
                        bool isHovered = false;
                        return StatefulBuilder(
                          builder: (context, setStateDropdown) {
                            return MouseRegion(
                              onEnter: (_) => setStateDropdown(() => isHovered = true),
                              onExit: (_) => setStateDropdown(() => isHovered = false),
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: (isHovered || _isTdsOpen)
                                        ? const Color(0xFF0088FF)
                                        : const Color(0xFFD1D5DB),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayText,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: selectedRate.isNotEmpty
                                              ? const Color(0xFF111827)
                                              : _hintColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (selectedRate.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          ref
                                              .read(purchaseOrderFormNotifierProvider.notifier)
                                              .updateField(
                                                tdsTcsId: '',
                                                tdsTcsRate: 0.0,
                                              );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: _hintColor,
                                          ),
                                        ),
                                      ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      size: 16,
                                      color: _hintColor,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }(),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: Text(
                calculatedAmount > 0
                    ? (s.tdsTcsType == 'tds' ? '-$displayAmount' : displayAmount)
                    : displayAmount,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ] else
            const SizedBox(width: 252),
        ],
      ),
    );
  }

  void _showTdsMenu(
    BuildContext context,
    PurchaseOrderState s,
    Offset? buttonOffset,
  ) {
    _closeTdsOverlay();
    setState(() {
      _isTdsOpen = true;
    });

    final overlay = Overlay.of(context);
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

    final screenHeight = MediaQuery.of(context).size.height;
    bool showAbove = false;
    if (buttonOffset != null) {
      const double popoverHeight = 360.0;
      final double spaceBelow = screenHeight - (buttonOffset.dy + 32) - 16;
      final double spaceAbove = buttonOffset.dy - 16;
      if (spaceBelow < popoverHeight && spaceAbove > spaceBelow) {
        showAbove = true;
      }
    }

    _tdsOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeTdsOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _tdsLink,
            showWhenUnlinked: false,
            targetAnchor: showAbove ? Alignment.topLeft : Alignment.bottomLeft,
            followerAnchor: showAbove ? Alignment.bottomLeft : Alignment.topLeft,
            offset: Offset.zero,
            child: Material(
              color: Colors.transparent,
              child: TapRegion(
                onTapOutside: (_) => _closeTdsOverlay(),
                child: _TdsSelectionPopover(
                  isTcs: s.tdsTcsType == 'tcs',
                  tdsRates: s.tdsTcsType == 'tcs' ? _tcsRatesList : _tdsRatesList,
                  tdsSections: s.tdsTcsType == 'tcs' ? _tcsNaturesList : _tdsSectionsList,
                  tdsGroups: _tdsGroupsList,
                  selectedTdsId: s.tdsTcsId,
                  onSelected: (rate) {
                    final isTcs = s.tdsTcsType == 'tcs';
                    notifier.updateField(
                      tdsTcsId: rate['id']?.toString() ?? '',
                      tdsTcsRate: double.tryParse((isTcs ? rate['rate'] : rate['base_rate'])?.toString() ?? '0') ?? 0.0,
                    );
                    _closeTdsOverlay();
                  },
                  onManageTds: () {
                    _closeTdsOverlay();
                    if (s.tdsTcsType == 'tcs') {
                      _showManageTcsRatesDialog();
                    } else {
                      _showManageTdsRatesDialog();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_tdsOverlay!);
  }

  void _closeTdsOverlay() {
    if (_tdsOverlay != null) {
      _tdsOverlay!.remove();
      _tdsOverlay = null;
      setState(() {
        _isTdsOpen = false;
      });
    }
  }

  Widget _adjustmentRow() {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    return Row(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isAdjustmentLabelHovered = true),
          onExit: (_) => setState(() => _isAdjustmentLabelHovered = false),
          child: CustomPaint(
            foregroundPainter: _DashedBorderPainter(
              color:
                  (_adjustmentLabelFocusNode.hasFocus ||
                      _isAdjustmentLabelHovered)
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFCBD5E1),
              isFocused: _adjustmentLabelFocusNode.hasFocus,
              isHovered: _isAdjustmentLabelHovered,
            ),
            child: Container(
              width: 140,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                controller: _adjustmentLabelCtrl,
                focusNode: _adjustmentLabelFocusNode,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  filled: false,
                  contentPadding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        (() {
          bool isHovered = false;
          bool isFocused = false;
          return StatefulBuilder(
            builder: (context, setStateAdj) {
              return Focus(
                onFocusChange: (focus) => setStateAdj(() => isFocused = focus),
                child: MouseRegion(
                  onEnter: (_) => setStateAdj(() => isHovered = true),
                  onExit: (_) => setStateAdj(() => isHovered = false),
                  child: Container(
                    width: 100,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isFocused
                            ? const Color(0xFF3B82F6)
                            : (isHovered ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB)),
                        width: isFocused ? 1.5 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: _adjustmentCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textAlign: TextAlign.start,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                      ),
                      onChanged: (v) {
                        notifier.updateField(adjustment: double.tryParse(v) ?? 0);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        })(),
        const SizedBox(width: 6),
        const ZTooltip(
          message: "Add any other +ve or -ve charges that need to be applied to adjust the total amount of the transaction Eg. +10 or -10.",
          direction: ZTooltipDirection.bottom,
          child: Icon(LucideIcons.helpCircle, size: 14, color: _hintColor),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 50,
          child: Text(
            (double.tryParse(_adjustmentCtrl.text) ?? 0.0).toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _totalLine(
    String label,
    String val, {
    bool isBold = false,
    double fontSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: _labelColor,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _notesSection() {
    return SizedBox(
      width: 450,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _labelColor,
            ),
          ),
          const SizedBox(height: 8),
          _HoverableField(
            builder: (isHovered) => TextField(
              controller: _notesCtrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Will be displayed on purchase order',
                hintStyle: TextStyle(color: _hintColor),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isHovered ? _linkBlue : _fieldBorder,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: _linkBlue, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerBanner(PurchaseOrderState poState) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6), // Soft Blue Banner background
        border: Border(
          top: BorderSide(color: Color(0xFFDBEAFE)),
          bottom: BorderSide(color: Color(0xFFDBEAFE)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: _termsAndFileRow(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TERMS & CONDITIONS + FILE UPLOAD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _termsAndFileRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Terms
          SizedBox(
            width: 650, // Wider Terms box
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                _HoverableField(
                  builder: (isHovered) => TextField(
                    controller: _termsCtrl,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Enter the terms and conditions of your business to be displayed in your transaction',
                      hintStyle: TextStyle(color: _hintColor),
                      contentPadding: const EdgeInsets.all(12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isHovered ? _linkBlue : _fieldBorder,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: _linkBlue,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          // Vertical Partition
          Container(
            width: 1,
            color: const Color(0xFFDBEAFE),
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          const SizedBox(width: 40),
          // File Upload
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attach File(s) to Purchase Order',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _labelColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFileUploadSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        const SizedBox(height: 8),
        const Text(
          'You can upload a maximum of 10 files, 5MB each',
          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
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
                          color: isHovered
                              ? Colors.white
                              : const Color(0xFF374151),
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
                    child: const Icon(
                      LucideIcons.trash,
                      size: 14,
                      color: Colors.white,
                    ),
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
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
      );
      if (!mounted || result == null) return;

      setState(() {
        final totalFiles = _attachedFiles.length + result.files.length;
        if (totalFiles > 10) {
          ZerpaiToast.error(
            context,
            'You can only attach a maximum of 10 files',
          );
          return;
        }

        // Check file size (5MB = 5 * 1024 * 1024 bytes)
        final oversizedFiles = result.files
            .where((f) => f.size > 5 * 1024 * 1024)
            .toList();
        if (oversizedFiles.isNotEmpty) {
          ZerpaiToast.error(
            context,
            'File size should be less than or equal to 5MB',
          );
          return;
        }

        _attachedFiles = [..._attachedFiles, ...result.files];
      });

      final count = _attachedFiles.length;
      if (count > 0) {
        ZerpaiToast.success(
          context,
          '$count file${count == 1 ? '' : 's'} attached',
        );
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
        return MouseRegion(
          onEnter: (_) => setOverlayState(() => isHovered = true),
          onExit: (_) => setOverlayState(() => isHovered = false),
          child: GestureDetector(
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
                    ? const Color(0xFF3B82F6)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isHovered ? FontWeight.w600 : FontWeight.w500,
                  color: isHovered
                      ? Colors.white
                      : const Color(0xFF374151),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STICKY FOOTER (Zoho style)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _stickyFooter(PurchaseOrderState poState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      decoration: BoxDecoration(
        color: _bgWhite,
        border: Border(top: BorderSide(color: _borderCol)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: (_isSavingDraft || _isSavingOpen)
                ? null
                : () => _handleSave(poState, status: 'Draft'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPrimary,
              side: BorderSide(color: _borderCol),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: _isSavingDraft
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _textPrimary,
                    ),
                  )
                : const Text(
                    'Save as Draft',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: (_isSavingDraft || _isSavingOpen)
                ? null
                : () => _handleSave(poState, status: 'Issued'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenBtn,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: _isSavingOpen
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save and Send',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.go('/purchases/purchase-orders'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPrimary,
              side: BorderSide(color: _borderCol),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          // Right side — Inventory Tracking + PDF template
          Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: _greenBtn),
              const SizedBox(width: 4),
              Text(
                'Inventory Tracking',
                style: TextStyle(fontSize: 12, color: _linkBlue),
              ),
              const SizedBox(width: 16),
              Text(
                "| PDF Template: 'Standard Template'",
                style: TextStyle(fontSize: 12, color: _hintColor),
              ),
              const SizedBox(width: 4),
              Text('Change', style: TextStyle(fontSize: 12, color: _linkBlue)),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OVERLAYS

  // ═══════════════════════════════════════════════════════════════════════════
  // UNIFIED ADDRESS MODAL
  // ═══════════════════════════════════════════════════════════════════════════
  void _showAddressModal({
    WarehouseModel? wh,
    SalesCustomer? cust,
    Vendor? vendor,
    bool isBilling = true,
    String? customTitle,
    Map<String, dynamic>? initialAddress,
    bool isNewAddress = false,
  }) {
    // Determine the source address data
    Map<String, dynamic> existingAddress = {};
    if (initialAddress != null) {
      existingAddress = initialAddress;
    } else if (isNewAddress) {
      existingAddress = {};
    } else if (wh != null) {
      existingAddress = {
        'attention': wh.attention ?? '',
        'street1': wh.addressStreet1 ?? '',
        'street2': wh.addressStreet2 ?? '',
        'city': wh.city ?? '',
        'state': wh.state ?? '',
        'zip': wh.zipCode ?? '',
        'country': wh.countryRegion,
        'phone': wh.phone ?? '',
      };
    } else if (cust != null) {
      existingAddress = {
        'street1': cust.shippingAddressStreet1 ?? '',
        'street2': cust.shippingAddressStreet2 ?? '',
        'city': cust.shippingAddressCity ?? '',
        'state': cust.shippingAddressStateId ?? '',
        'zip': cust.shippingAddressZip ?? '',
        'phone': cust.phone ?? '',
      };
    } else if (vendor != null) {
      existingAddress = isBilling
          ? (vendor.billingAddress ?? {})
          : (vendor.shippingAddress ?? {});
    }

    String dialogTitle = customTitle ?? 'New address';
    if (customTitle == null) {
      if (wh != null)
        dialogTitle = 'Edit Warehouse Address';
      else if (cust != null)
        dialogTitle = 'Edit Shipping Address';
      else if (vendor != null)
        dialogTitle = isBilling ? 'Billing Address' : 'Shipping Address';
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Address Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) {
        return AddressDialog(
          title: dialogTitle,
          initialAddress: existingAddress,
          onSave: (val) async {
            final notifier = ref.read(
              purchaseOrderFormNotifierProvider.notifier,
            );
            
            final isFirstBilling = vendor != null && isBilling && 
                (vendor.billingAddress == null || vendor.billingAddress!.isEmpty);
            final isFirstShipping = vendor != null && !isBilling && 
                (vendor.shippingAddress == null || vendor.shippingAddress!.isEmpty);

            final data = <String, dynamic>{
              'attention': val['attention'] ?? '',
              'street1': val['street1'] ?? '',
              'street2': val['street2'] ?? '',
              'city': val['city'] ?? '',
              'state': val['stateName'] ?? val['state'] ?? '', // Use Name if available
              'zip': val['zip'] ?? '',
              'country': val['countryName'] ?? val['country'] ?? '', // Use Name if available
              'phone': val['phone'] ?? '',
              'phoneCode': val['phoneCode'] ?? '+91',
              'fax': val['fax'] ?? '',
              'is_default_billing': isFirstBilling,
              'isDefaultBilling': isFirstBilling,
              'is_default_shipping': isFirstShipping,
              'isDefaultShipping': isFirstShipping,
            };

            if (vendor != null) {
              Vendor updated;
              if (isNewAddress) {
                final Map<String, dynamic> newAddr = {
                  ...data,
                  'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
                };
                final currentList = vendor.vendorAddresses ?? [];
                final newList = [...currentList, newAddr];
                final tempVendor = vendor.copyWith(vendorAddresses: newList);
                
                final updatedAddresses = _updateVendorAddressesDefaultFlags(
                  vendor: tempVendor,
                  selectedAddr: newAddr,
                  isBilling: isBilling,
                );
                
                updated = isBilling
                    ? tempVendor.copyWith(
                        billingAddress: _normalizeAddress(newAddr),
                        vendorAddresses: updatedAddresses,
                      )
                    : tempVendor.copyWith(
                        shippingAddress: _normalizeAddress(newAddr),
                        vendorAddresses: updatedAddresses,
                      );
              } else if (initialAddress != null) {
                final currentList = vendor.vendorAddresses ?? [];
                final newList = currentList.map((addr) {
                  if (_areAddressesEqual(addr, initialAddress)) {
                    return {
                      ...addr,
                      ...data,
                    };
                  }
                  return addr;
                }).toList();
                
                final tempVendor = vendor.copyWith(vendorAddresses: newList);
                final updatedAddresses = _updateVendorAddressesDefaultFlags(
                  vendor: tempVendor,
                  selectedAddr: data,
                  isBilling: isBilling,
                );
                
                updated = isBilling
                    ? tempVendor.copyWith(
                        billingAddress: _normalizeAddress(data),
                        vendorAddresses: updatedAddresses,
                      )
                    : tempVendor.copyWith(
                        shippingAddress: _normalizeAddress(data),
                        vendorAddresses: updatedAddresses,
                      );
              } else {
                final updatedAddresses = _updateVendorAddressesDefaultFlags(
                  vendor: vendor,
                  selectedAddr: data,
                  isBilling: isBilling,
                );
                updated = isBilling
                    ? vendor.copyWith(
                        billingAddress: _normalizeAddress(data),
                        vendorAddresses: updatedAddresses,
                      )
                    : vendor.copyWith(
                        shippingAddress: _normalizeAddress(data),
                        vendorAddresses: updatedAddresses,
                      );
              }

              try {
                ref
                    .read(vendorProvider.notifier)
                    .updateVendorLocally(vendor.id, updated);
                await ref
                    .read(vendorProvider.notifier)
                    .updateVendor(vendor.id, updated);
                if (context.mounted) {
                  ZerpaiToast.success(context, 'Vendor address updated in database');
                }
              } catch (e) {
                ref
                    .read(vendorProvider.notifier)
                    .updateVendorLocally(vendor.id, vendor);
                if (context.mounted) {
                  ZerpaiToast.error(context, 'Failed to update address in database: $e');
                }
              }
            } else if (wh != null) {
              // Update warehouse
            } else if (cust != null) {
              // Update customer
            } else {
              // New Address - Update the current PO state delivery address
              notifier.updateField(
                deliveryAddressName:
                    (val['attention'] as String?)?.trim().isNotEmpty == true
                    ? (val['attention'] as String).trim()
                    : 'New Address',
              );
              _deliveryNameCtrl.text = (val['attention'] as String?)?.trim() ?? '';
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

  Widget _buildHeaderSearchField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
    required bool isSearchVisible,
    required VoidCallback onToggle,
    TextAlign textAlign = TextAlign.start,
  }) {
    if (!isSearchVisible) {
      return Row(
        mainAxisAlignment: textAlign == TextAlign.center
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onToggle,
            child: const Icon(
              LucideIcons.search,
              size: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      );
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderCol),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 12, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: true,
              style: const TextStyle(fontSize: 11, color: _textPrimary),
              textAlign: textAlign,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              controller.clear();
              onChanged('');
              onToggle();
            },
            child: const Icon(
              LucideIcons.x,
              size: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardLookupRow(
    String label,
    bool isSelected,
    bool isHovered, {
    String? sublabel,
    double indentation = 0.0,
  }) {
    Color text = const Color(0xFF111827);
    Color subtext = const Color(0xFF6B7280);

    if (isHovered) {
      text = Colors.white;
      subtext = Colors.white70;
    } else if (isSelected) {
      text = const Color(0xFF111827);
      subtext = const Color(0xFF6B7280);
    }

    return Container(
      padding: EdgeInsets.only(
        left: 12 + indentation,
        right: 12,
        top: 8,
        bottom: 8,
      ),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(fontSize: 12, color: subtext),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showValueTooltip(BuildContext context, String message, LayerLink link) {
    if (_valueTooltipOverlay != null) {
      _valueTooltipOverlay?.remove();
      _valueTooltipOverlay = null;
    }

    _valueTooltipOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned(
            child: CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_valueTooltipOverlay!);
    setState(() {});
  }

  void _hideValueTooltip() {
    if (_valueTooltipOverlay != null) {
      _valueTooltipOverlay?.remove();
      _valueTooltipOverlay = null;
      setState(() {});
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM PRIMITIVES (Zoho-style)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _zFormRow({
    required String label,
    required Widget child,
    bool isRequired = false,
    bool crossStart = false,
    double maxWidth = 600,
    double gap = 24,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        crossAxisAlignment: crossStart
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isRequired ? _requiredLabel : _labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isRequired)
                    const TextSpan(
                      text: '*',
                      style: TextStyle(
                        color: _requiredLabel,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: gap),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _zField(
    TextEditingController ctrl, {
    String hint = '',
    Function(String)? onChanged,
    VoidCallback? onTap,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    TextAlign textAlign = TextAlign.start,
  }) {
    return _HoverableField(
      builder: (isHovered) => SizedBox(
        height: 32,
        child: TextField(
          controller: ctrl,
          onChanged: onChanged,
          onTap: onTap,
          keyboardType: keyboardType,
          textAlign: textAlign,
          textAlignVertical: TextAlignVertical.center,
          readOnly: readOnly || (onTap != null && onChanged == null),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(color: _hintColor),
            contentPadding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isHovered ? _linkBlue : _fieldBorder,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _linkBlue, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            suffixIcon: suffixIcon,
            suffixIconConstraints: suffixIcon != null
                ? const BoxConstraints(
                    maxHeight: 32,
                    minHeight: 32,
                    maxWidth: 32,
                    minWidth: 16,
                  )
                : null,
            filled: true,
            fillColor: _bgWhite,
          ),
        ),
      ),
    );
  }

  Widget _zDateField({
    required TextEditingController controller,
    required GlobalKey targetKey,
    required DateTime? value,
    required ValueChanged<DateTime> onSelected,
    String hint = 'dd-MM-yyyy',
    DateTime? firstDate,
  }) {
    return KeyedSubtree(
      key: targetKey,
      child: _zField(
        controller,
        hint: hint,
        readOnly: true,
        onTap: () async {
          final today = DateTime.now();
          final startOfToday = DateTime(today.year, today.month, today.day);
          final limitFirstDate = firstDate ?? startOfToday;
          final selected = await ZerpaiDatePicker.show(
            context,
            initialDate: (value != null && !value.isBefore(limitFirstDate))
                ? value
                : limitFirstDate,
            firstDate: limitFirstDate,
            lastDate: DateTime(2100),
            targetKey: targetKey,
          );
          if (selected != null) {
            controller.text = DateFormat('dd-MM-yyyy').format(selected);
            onSelected(selected);
          }
        },
        suffixIcon: const Icon(
          Icons.calendar_today_outlined,
          size: 16,
          color: _hintColor,
        ),
      ),
    );
  }

  Widget _zRadio(
    String label,
    String value,
    String groupValue,
    Function(String) onChanged,
  ) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _linkBlue : const Color(0xFFAAAAAA),
                width: 1.5,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: _linkBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: _labelColor)),
        ],
      ),
    );
  }

  Widget _tableActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool hasDropdown = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF2563EB)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 16, color: _linkBlue),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // WAREHOUSE DROPDOWN HELPER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWarehouseDropdownItem(
    WarehouseModel w,
    bool isSelected,
    bool isHovered,
  ) {
    final subtitle = [
      w.city,
      w.state,
      w.countryRegion,
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: isHovered
          ? const Color(0xFF0088FF)
          : Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${w.name} (warehouse)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isHovered
                        ? Colors.white
                        : _textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isHovered
                          ? Colors.white.withValues(alpha: 0.8)
                          : _hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VENDOR DROPDOWN HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildVendorDropdownItem(Vendor v, bool isSelected, bool isHovered) {
    final firstName = (v.firstName ?? '').trim();
    final initialSource = firstName.isNotEmpty
        ? firstName
        : (v.displayName.isNotEmpty ? v.displayName : '?');
    final initial = initialSource.substring(0, 1).toUpperCase();

    final backgroundColor = isHovered
        ? const Color(0xFF3B82F6)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
    final primaryTextColor = isHovered ? Colors.white : _textPrimary;
    final secondaryTextColor = isHovered
        ? Colors.white.withValues(alpha: 0.85)
        : _hintColor;

    final topLine = v.vendorNumber != null && v.vendorNumber!.isNotEmpty
        ? '${v.displayName} | ${v.vendorNumber}'
        : v.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isHovered ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
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
                if (v.companyName != null && v.companyName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    v.companyName!,
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





class _ConfigureTaxPreferencesDialog extends StatefulWidget {
  final String initialTreatment;
  final String initialGstin;
  final Function(String, String, bool) onUpdate;
  final VoidCallback onCancel;

  const _ConfigureTaxPreferencesDialog({
    required this.initialTreatment,
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
    _selectedTreatment = widget.initialTreatment;
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
          padding: const EdgeInsets.only(right: 14),
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
                      style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
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
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTreatment = val['label']!;
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
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Get Taxpayer details',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Make it permanent?',
                      style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: _makePermanent,
                            onChanged: (val) =>
                                setState(() => _makePermanent = val!),
                            activeColor: const Color(0xFF22C55E),
                            side: const BorderSide(color: Color(0xFFCCCCCC)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Use these settings for all future transactions of this vendor.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
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
                      onPressed: () =>
                          widget.onUpdate(_selectedTreatment, _gstinCtrl.text.trim(), _makePermanent),
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
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                        style: TextStyle(color: Color(0xFF333333)),
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

class _OpenPurchaseOrdersPopover extends StatelessWidget {
  final List<Map<String, String>> orders;

  const _OpenPurchaseOrdersPopover({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30),
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
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDDDDD), width: 1.0),
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
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Recent Orders',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              if (orders.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: const Text(
                    'There are no Purchase Orders',
                    style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (ctx, idx) {
                    final o = orders[idx];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: idx < orders.length - 1
                            ? const Border(
                                bottom: BorderSide(color: Color(0xFFEEEEEE)),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o['po']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                o['date']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                o['amount']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                o['status']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF3481F4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool isUp;
  final bool hasBorder;
  _TrianglePainter({
    required this.color,
    this.isUp = false,
    this.hasBorder = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (isUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width / 2, size.height);
      path.lineTo(0, 0);
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

// ── Dashed Border Painter ─────────────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final bool isFocused;
  final bool isHovered;

  const _DashedBorderPainter({
    this.color = const Color(0xFFCBD5E1),
    this.isFocused = false,
    this.isHovered = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      const Radius.circular(6),
    );

    if (isFocused) {
      // Draw glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(rrect, glowPaint);

      // Draw solid border
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
      // (
      x = parseExpression();
      eat(41); // )
    } else if ((ch >= 48 && ch <= 57) || ch == 46) {
      // numbers
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

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height); // Bottom left
    path.lineTo(size.width / 2, 0); // Top center
    path.lineTo(size.width, size.height); // Bottom right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ─── Hover-aware field wrapper ───────────────────────────────────────────────
// Tracks mouse hover and exposes `isActive` to the builder so fields can
// switch their border/fill color on hover (in addition to Flutter's native
// focus handling inside InputDecoration.focusedBorder).
class _HoverableField extends StatefulWidget {
  final Widget Function(bool isActive) builder;
  const _HoverableField({required this.builder});
  @override
  State<_HoverableField> createState() => _HoverableFieldState();
}

class _HoverableFieldState extends State<_HoverableField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.builder(_isHovered),
    );
  }
}

// ── Warehouse Stock Dialog ────────────────────────────────────────────────────

class _WarehouseStockDialog extends ConsumerStatefulWidget {
  final PurchaseOrderItem item;
  final List<WarehouseModel> warehouses;
  final String? selectedWarehouseId;
  final String initialStockView; // 'stockOnHand' | 'availableForSale'
  final void Function(String warehouseId) onWarehouseSelected;
  final void Function(String view) onViewChanged;
  final VoidCallback onClose;

  const _WarehouseStockDialog({
    required this.item,
    required this.warehouses,
    required this.selectedWarehouseId,
    required this.initialStockView,
    required this.onWarehouseSelected,
    required this.onViewChanged,
    required this.onClose,
  });

  @override
  ConsumerState<_WarehouseStockDialog> createState() =>
      _WarehouseStockDialogState();
}

class _WarehouseStockDialogState extends ConsumerState<_WarehouseStockDialog> {
  String _viewMode = 'physical'; // 'physical' | 'accounting'
  late String _stockView; // 'stockOnHand' | 'availableForSale'
  String? _selectedWarehouseId;

  static const _blue = Color(0xFF0088FF);
  static const _textDark = Color(0xFF1F2937);
  static const _textGrey = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _headerBg = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _selectedWarehouseId = widget.selectedWarehouseId;
    _stockView = widget.initialStockView;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Text(
                  'Warehouse',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                const Text(
                  'View: ',
                  style: TextStyle(fontSize: 12, color: _textGrey),
                ),
                // View dropdown
                SizedBox(
                  width: 160,
                  child: FormDropdown<String>(
                    height: 32,
                    value: _stockView,
                    items: const ['stockOnHand', 'availableForSale'],
                    displayStringForValue: (v) => v == 'stockOnHand'
                        ? 'Stock on Hand'
                        : 'Available for Sale',
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _stockView = v);
                      widget.onViewChanged(v);
                    },
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _blue),
                    itemBuilder: (val, isSelected, isHovered) =>
                        _buildStandardLookupRow(
                          val == 'stockOnHand'
                              ? 'Stock on Hand'
                              : 'Available for Sale',
                          isSelected,
                          isHovered,
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                // Toggle buttons
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _blue),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      _buildToggle('Accounting Stock', 'accounting'),
                      _buildToggle('Physical Stock', 'physical', isRight: true),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: widget.onClose,
                  child: const Icon(
                    Icons.close,
                    size: 22,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),

          // ── Table ───────────────────────────────────────────────────────
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Table header
                Container(
                  decoration: const BoxDecoration(
                    color: _headerBg,
                    border: Border(bottom: BorderSide(color: _border)),
                  ),
                  child: Column(
                    children: [
                      // Spanning sub-header
                      Row(
                        children: [
                          const SizedBox(width: 260),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: _border),
                                  bottom: BorderSide(color: _border),
                                ),
                              ),
                              child: Text(
                                _viewMode == 'physical'
                                    ? 'Physical Stock'
                                    : 'Accounting Stock',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _textGrey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Column labels
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 244,
                              child: Row(
                                children: [
                                  const Text(
                                    'Warehouse Name',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _textGrey,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.search,
                                    size: 14,
                                    color: _textGrey,
                                  ),
                                ],
                              ),
                            ),
                            _headerCell('Stock on Hand'),
                            _headerCell('Committed Stock'),
                            _headerCell(
                              'Available for Sale',
                              icon: Icons.visibility_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Warehouse rows
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.warehouses.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _border),
                    itemBuilder: (_, idx) {
                      final wh = widget.warehouses[idx];
                      return _WarehouseStockRow(
                        warehouse: wh,
                        productId: widget.item.productId,
                        isSelected: _selectedWarehouseId == wh.id,
                        onSelect: () {
                          setState(() => _selectedWarehouseId = wh.id);
                          widget.onWarehouseSelected(wh.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Footer legend ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendRow(
                  'Stock on Hand',
                  ': This is calculated based on Receives and Shipments.',
                ),
                const SizedBox(height: 4),
                _legendRow(
                  'Committed Stock',
                  ': Stock that is committed to sales order(s) but not yet shipped',
                ),
                const SizedBox(height: 4),
                _legendRow(
                  'Available for Sale',
                  ': Stock on Hand – Committed Stock',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, String mode, {bool isRight = false}) {
    final selected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _blue : Colors.white,
          borderRadius: isRight
              ? const BorderRadius.horizontal(right: Radius.circular(3))
              : const BorderRadius.horizontal(left: Radius.circular(3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _blue,
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String label, {IconData? icon}) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textGrey,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 3),
            Icon(icon, size: 12, color: _textGrey),
          ],
        ],
      ),
    );
  }

  Widget _legendRow(String bold, String normal) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, color: _textGrey),
        children: [
          TextSpan(
            text: bold,
            style: const TextStyle(color: _blue, fontWeight: FontWeight.w500),
          ),
          TextSpan(text: normal),
        ],
      ),
    );
  }

  Widget _buildStandardLookupRow(
    String label,
    bool isSelected,
    bool isHovered, {
    String? sublabel,
  }) {
    Color text = const Color(0xFF111827);
    Color subtext = const Color(0xFF6B7280);

    if (isHovered) {
      text = Colors.white;
      subtext = Colors.white70;
    } else if (isSelected) {
      text = const Color(0xFF111827);
      subtext = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sublabel != null && sublabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(fontSize: 11, color: subtext),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ── Warehouse Stock Row ───────────────────────────────────────────────────────

class _WarehouseStockRow extends ConsumerWidget {
  final WarehouseModel warehouse;
  final String productId;
  final bool isSelected;
  final VoidCallback onSelect;

  const _WarehouseStockRow({
    required this.warehouse,
    required this.productId,
    required this.isSelected,
    required this.onSelect,
  });

  static const _blue = Color(0xFF0088FF);
  static const _textDark = Color(0xFF1F2937);
  static const _textGrey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockByWarehouseProvider(warehouse.id));
    final stock = stockAsync.valueOrNull
        ?.where((s) => s.productId == productId)
        .firstOrNull;

    String fmt(double? v) => v != null ? v.toStringAsFixed(2) : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Radio + name
          GestureDetector(
            onTap: onSelect,
            child: SizedBox(
              width: 244,
              child: Row(
                children: [
                  // Custom radio circle
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _blue : const Color(0xFFD1D5DB),
                        width: isSelected ? 5 : 1,
                      ),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      warehouse.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? _blue : _textDark,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.star,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Stock values
          if (stockAsync.isLoading)
            const Expanded(
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
            )
          else ...[
            _valueCell(fmt(stock?.quantityOnHand)),
            _valueCell(fmt(null)),
            _valueCell(
              fmt(stock?.availableQuantity),
              bold: true,
              color: (stock?.availableQuantity ?? 0) > 0
                  ? _textDark
                  : _textGrey,
            ),
          ],
        ],
      ),
    );
  }

  Widget _valueCell(String text, {bool bold = false, Color? color}) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: color ?? _textDark,
        ),
      ),
    );
  }
}

class _TaxSelectionPopover extends ConsumerWidget {
  final String? selectedTaxId;
  final ValueChanged<TaxRate> onTaxSelected;

  const _TaxSelectionPopover({this.selectedTaxId, required this.onTaxSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(itemsControllerProvider);
    final taxes = itemsState.taxGroups;

    // Create dummy objects for special options
    final nonTaxable = TaxRate(
      id: 'non_taxable',
      taxName: 'Non-Taxable',
      taxRate: 0,
    );
    final outOfScope = TaxRate(
      id: 'out_of_scope',
      taxName: 'Out of Scope',
      taxRate: 0,
    );
    final nonGst = TaxRate(
      id: 'non_gst',
      taxName: 'Non-GST Supply',
      taxRate: 0,
    );

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _SpecialPopoverListItem(
                    title: "Non-Taxable",
                    isSelected: selectedTaxId == 'non_taxable',
                    onTap: () => onTaxSelected(nonTaxable),
                  ),
                  _SpecialPopoverListItem(
                    title: "Out of Scope",
                    description:
                        "Supplies on which you don't charge any GST or include them in the returns.",
                    isSelected: selectedTaxId == 'out_of_scope',
                    onTap: () => onTaxSelected(outOfScope),
                  ),
                  _SpecialPopoverListItem(
                    title: "Non-GST Supply",
                    description:
                        "Supplies which do not come under GST such as petroleum products and liquor.",
                    isSelected: selectedTaxId == 'non_gst',
                    onTap: () => onTaxSelected(nonGst),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Tax Group',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _labelColor,
                      ),
                    ),
                  ),
                  ...taxes.map((tax) {
                    final isSelected = tax.id == selectedTaxId;
                    final displayLabel = '${tax.taxName} [${tax.taxRate}%]';

                    return _PopoverListItem(
                      label: displayLabel,
                      isSelected: isSelected,
                      onTap: () => onTaxSelected(tax),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _SpecialPopoverListItem extends StatefulWidget {
  final String title;
  final String? description;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpecialPopoverListItem({
    required this.title,
    this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SpecialPopoverListItem> createState() =>
      _SpecialPopoverListItemState();
}

class _SpecialPopoverListItemState extends State<_SpecialPopoverListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected || _hover
        ? const Color(0xFF3B82F6)
        : Colors.transparent;
    final text = widget.isSelected || _hover
        ? Colors.white
        : const Color(0xFF333333);
    final descColor = widget.isSelected || _hover
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFF666666);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 13,
                  color: text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.description!,
                  style: TextStyle(fontSize: 11, color: descColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSelectionPopover extends StatefulWidget {
  final List<AccountNode> accounts;
  final String? selectedAccountId;
  final ValueChanged<AccountNode> onSelected;

  const _AccountSelectionPopover({
    required this.accounts,
    this.selectedAccountId,
    required this.onSelected,
  });

  @override
  State<_AccountSelectionPopover> createState() =>
      _AccountSelectionPopoverState();
}

class _AccountSelectionPopoverState extends State<_AccountSelectionPopover> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  Map<String, List<AccountNode>> get _grouped {
    final Map<String, List<AccountNode>> grouped = {};
    for (var acc in widget.accounts) {
      if (_search.isNotEmpty &&
          !acc.name.toLowerCase().contains(_search.toLowerCase())) {
        continue;
      }
      final type = acc.accountType;
      grouped.putIfAbsent(type, () => []).add(acc);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    return Container(
      width: 480,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Select an account',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: _hintColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                GestureDetector(
                  onTap: () {}, // Handle close from outside usually
                  child: const Icon(Icons.close, size: 14, color: _hintColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: groups.entries.expand((entry) {
                  return [
                    // Group Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Items
                    ...() {
                      final List<Widget> items = [];
                      final groupAccounts = entry.value;
                      final accountMap = {for (var a in groupAccounts) a.id: a};
                      
                      // Find root nodes (either parentId is null, or parent is not in this group)
                      final rootNodes = groupAccounts.where((a) => a.parentId == null || !accountMap.containsKey(a.parentId)).toList();
                      
                      void addNode(AccountNode node, int depth) {
                        final isSelected = node.id == widget.selectedAccountId;
                        items.add(
                          _PopoverListItem(
                            label: depth == 0 ? node.systemAccountName : node.name,
                            indent: depth,
                            isSelected: isSelected,
                            onTap: () => widget.onSelected(node),
                          )
                        );
                        
                        // Add children
                        final children = groupAccounts.where((a) => a.parentId == node.id).toList();
                        for (var child in children) {
                          addNode(child, depth + 1);
                        }
                      }
                      
                      for (var root in rootNodes) {
                        addNode(root, 0);
                      }
                      
                      return items;
                    }(),
                  ];
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _TdsSelectionPopover extends StatefulWidget {
  final bool isTcs;
  final List<Map<String, dynamic>> tdsRates;
  final List<Map<String, dynamic>> tdsSections;
  final List<Map<String, dynamic>> tdsGroups;
  final String? selectedTdsId;
  final ValueChanged<Map<String, dynamic>> onSelected;
  final VoidCallback onManageTds;

  const _TdsSelectionPopover({
    this.isTcs = false,
    required this.tdsRates,
    required this.tdsSections,
    required this.tdsGroups,
    this.selectedTdsId,
    required this.onSelected,
    required this.onManageTds,
  });

  @override
  State<_TdsSelectionPopover> createState() => _TdsSelectionPopoverState();
}

class _TdsSelectionPopoverState extends State<_TdsSelectionPopover> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    if (widget.isTcs) {
      return grouped;
    } else {
      final Set<String> groupedRateIds = {};
      for (var group in widget.tdsGroups) {
        final groupName = group['group_name']?.toString() ?? 'Others';
        final itemsList = group['tds_group_items'] as List<dynamic>? ?? [];
        final List<Map<String, dynamic>> ratesInGroup = [];

        for (var item in itemsList) {
          final rateId = item['tds_rate_id']?.toString();
          if (rateId != null) {
            final match = widget.tdsRates.firstWhere(
              (r) => r['id']?.toString() == rateId,
              orElse: () => <String, dynamic>{},
            );
            if (match.isNotEmpty) {
              final taxName = match['tax_name']?.toString() ?? '';
              if (_search.isEmpty || taxName.toLowerCase().contains(_search.toLowerCase())) {
                ratesInGroup.add(match);
              }
              groupedRateIds.add(rateId);
            }
          }
        }
        if (ratesInGroup.isNotEmpty) {
          grouped[groupName] = ratesInGroup;
        }
      }

      // Add remaining individual rates that are not in any group
      final List<Map<String, dynamic>> individualRates = [];
      for (var rate in widget.tdsRates) {
        final rateId = rate['id']?.toString();
        if (rateId != null && !groupedRateIds.contains(rateId)) {
          final taxName = rate['tax_name']?.toString() ?? '';
          if (_search.isEmpty || taxName.toLowerCase().contains(_search.toLowerCase())) {
            individualRates.add(rate);
          }
        }
      }
      if (individualRates.isNotEmpty) {
        grouped['Individual Rates'] = individualRates;
      }
    }
    return grouped;
  }

  String _formatBaseRate(dynamic rate) {
    if (rate == null) return '';
    final d = double.tryParse(rate.toString());
    if (d == null) return rate.toString();
    if (d == d.toInt()) return '${d.toInt()}%';
    return '$d%';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.isTcs ? 'Search TCS Rate' : 'Search TDS Rate',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: _hintColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: widget.isTcs
                    ? widget.tdsRates.where((rate) {
                        final taxName = rate['tax_name']?.toString() ?? '';
                        return _search.isEmpty || taxName.toLowerCase().contains(_search.toLowerCase());
                      }).map((rate) {
                        final isSelected = rate['id'] == widget.selectedTdsId;
                        final baseRateStr = _formatBaseRate(rate['rate']);
                        final displayLabel = "${rate['tax_name']} [$baseRateStr]";
                        return _PopoverListItem(
                          label: displayLabel,
                          indent: 0,
                          isSelected: isSelected,
                          onTap: () => widget.onSelected(rate),
                        );
                      }).toList()
                    : groups.entries.expand((entry) {
                        return [
                          // Group Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Items
                          ...entry.value.map((rate) {
                            final isSelected = rate['id'] == widget.selectedTdsId;
                            final baseRateStr = _formatBaseRate(rate['base_rate']);
                            final displayLabel = "${rate['tax_name']} [$baseRateStr]";
                            return _PopoverListItem(
                              label: displayLabel,
                              indent: 1,
                              isSelected: isSelected,
                              onTap: () => widget.onSelected(rate),
                            );
                          }),
                        ];
                      }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: widget.onManageTds,
            hoverColor: const Color(0xFFF3F4F6),
            child: SizedBox(
              height: 36,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings,
                      size: 14,
                      color: Color(0xFF0088FF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isTcs ? 'Manage TCS' : 'Manage TDS',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0088FF),
                          fontWeight: FontWeight.w500,
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
    );
  }
}

class _DiscountTypePopover extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onSelected;

  const _DiscountTypePopover({
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DiscountPopoverListItem(
            label: '%',
            isSelected: selectedType == 'percentage',
            onTap: () => onSelected('percentage'),
          ),
          _DiscountPopoverListItem(
            label: '₹',
            isSelected: selectedType == 'fixed',
            onTap: () => onSelected('fixed'),
          ),
        ],
      ),
    );
  }
}

class _DiscountPopoverListItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DiscountPopoverListItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DiscountPopoverListItem> createState() => _DiscountPopoverListItemState();
}

class _DiscountPopoverListItemState extends State<_DiscountPopoverListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hover
        ? const Color(0xFF3B82F6)
        : widget.isSelected
            ? const Color(0xFFF3F4F6)
            : Colors.transparent;
    final text = _hover
        ? Colors.white
        : const Color(0xFF111827);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  color: text,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopoverListItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int indent;

  const _PopoverListItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.indent = 0,
  });

  @override
  State<_PopoverListItem> createState() => _PopoverListItemState();
}

class _PopoverListItemState extends State<_PopoverListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hover
        ? const Color(0xFF3B82F6)
        : widget.isSelected
            ? const Color(0xFFF3F4F6)
            : Colors.transparent;
    final text = _hover ? Colors.white : const Color(0xFF111827);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: EdgeInsets.only(
            left: 32.0 + (widget.indent * 16.0),
            right: 12,
            top: 8,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(fontSize: 13, color: text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverableMenuItem extends StatefulWidget {
  final String label;
  const _HoverableMenuItem(this.label);

  @override
  State<_HoverableMenuItem> createState() => _HoverableMenuItemState();
}

class _HoverableMenuItemState extends State<_HoverableMenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _hover ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: _hover ? FontWeight.w600 : FontWeight.w500,
            color: _hover ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

class _HoverableToggleMenuItem extends StatefulWidget {
  final String label;
  final bool value;
  const _HoverableToggleMenuItem(this.label, this.value);

  @override
  State<_HoverableToggleMenuItem> createState() =>
      _HoverableToggleMenuItemState();
}

class _HoverableToggleMenuItemState extends State<_HoverableToggleMenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _hover ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: _hover ? FontWeight.w600 : FontWeight.w500,
            color: _hover ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

class _HSNCodeEditPopover extends StatefulWidget {
  final String initialHsnCode;
  final bool isService;
  final VoidCallback onCancel;
  final Function(String) onSave;

  const _HSNCodeEditPopover({
    required this.initialHsnCode,
    this.isService = false,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<_HSNCodeEditPopover> createState() => _HSNCodeEditPopoverState();
}

class _HSNCodeEditPopoverState extends State<_HSNCodeEditPopover> {
  late TextEditingController _ctrl;

  static const _hintColor = Color(0xFF8E8E93);
  static const _textPrimary = Color(0xFF1C1C1E);

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialHsnCode);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openHsnSearch() async {
    final result = await showDialog<HsnSacCode>(
      context: context,
      useSafeArea: false,
      builder: (context) =>
          HsnSacSearchModal(type: widget.isService ? 'SAC' : 'HSN', initialQuery: _ctrl.text),
    );

    if (result != null) {
      setState(() {
        _ctrl.text = result.code;
        widget.onSave(result.code);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Triangle/Caret
        Padding(
          padding: const EdgeInsets.only(left: 252),
          child: CustomPaint(
            size: const Size(16, 8),
            painter: _TrianglePainter(color: Colors.white, isUp: true),
          ),
        ),
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  widget.isService ? 'SAC Code' : 'HSN Code',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    hintText: widget.isService ? 'Enter SAC Code' : 'Enter HSN Code',
                    hintStyle: const TextStyle(color: _hintColor, fontSize: 13),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      onPressed: _openHsnSearch,
                      splashRadius: 16,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (v) => widget.onSave(v.trim()),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF28A745),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => widget.onSave(_ctrl.text.trim()),
                      child: const Text('Save', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        foregroundColor: _textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 13),
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

Widget _buildIconAction(
  IconData icon, {
  double size = 16,
  VoidCallback? onTap,
  Color? color,
}) {
  final content = Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      border: Border.all(
        color: color?.withValues(alpha: 0.3) ?? const Color(0xFFD3D3D3),
      ),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: size, color: color ?? const Color(0xFF808080)),
  );

  if (onTap == null) return content;

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: content,
  );
}

Widget _buildSettingsOverlayItem({
  required String label,
  required bool showHighlight,
  required ValueChanged<bool> onHover,
  required VoidCallback onTap,
}) {
  return InkWell(
    onHover: onHover,
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: showHighlight ? const Color(0xFF3B82F6) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: showHighlight
              ? Colors.white
              : const Color(0xFF1F2937).withValues(alpha: 0.8),
        ),
      ),
    ),
  );
}

class _MenuHoverItem extends StatefulWidget {
  final IconData icon;
  final String label;

  const _MenuHoverItem({required this.icon, required this.label});

  @override
  State<_MenuHoverItem> createState() => _MenuHoverItemState();
}

class _MenuHoverItemState extends State<_MenuHoverItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF0088FF) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 16,
              color: _isHovered ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                color: _isHovered ? Colors.white : const Color(0xFF1F2937),
                fontWeight: _isHovered ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuHoverItemNoIcon extends StatefulWidget {
  final String label;
  const _MenuHoverItemNoIcon({required this.label});

  @override
  State<_MenuHoverItemNoIcon> createState() => _MenuHoverItemNoIconState();
}

class _MenuHoverItemNoIconState extends State<_MenuHoverItemNoIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            color: _isHovered ? Colors.white : const Color(0xFF1F2937),
            fontWeight: _isHovered ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _TaxAmountEditPopover extends StatefulWidget {
  final Map<String, ({String name, double rate, double amount})> initialTaxes;
  final Function(Map<String, double>) onSave;
  final VoidCallback onCancel;

  const _TaxAmountEditPopover({
    required this.initialTaxes,
    required this.onSave,
    required this.onCancel,
  });

  @override
  _TaxAmountEditPopoverState createState() => _TaxAmountEditPopoverState();
}

class _TaxAmountEditPopoverState extends State<_TaxAmountEditPopover> {
  late Map<String, double> _editedAmounts;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _editedAmounts = {};
    widget.initialTaxes.forEach((key, value) {
      _editedAmounts[key] = value.amount;
    });
    _calculateTotal();
  }

  void _calculateTotal() {
    double sum = 0;
    _editedAmounts.forEach((key, value) {
      sum += value;
    });
    setState(() {
      _total = sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Update Taxes Amount ( in )',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              GestureDetector(
                onTap: widget.onCancel,
                child: const Icon(Icons.close, size: 18, color: Colors.red),
              ),
            ],
          ),
          const Divider(height: 24),
          ...widget.initialTaxes.entries.map((entry) {
            final key = entry.key;
            final tax = entry.value;
            final ctrl = TextEditingController(
              text: _editedAmounts[key]?.toStringAsFixed(2) ?? '0.00',
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${tax.name} [${tax.rate % 1 == 0 ? tax.rate.toInt().toString() : tax.rate.toStringAsFixed(1)}%]',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 32,
                    child: TextFormField(
                      controller: ctrl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (v) {
                        final amt = double.tryParse(v) ?? 0;
                        _editedAmounts[key] = amt;
                        _calculateTotal();
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFF0088FF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Tax Amount',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                _total.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSave(_editedAmounts),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Update',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountTypeItem extends StatefulWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  const _DiscountTypeItem({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  _DiscountTypeItemState createState() => _DiscountTypeItemState();
}

class _DiscountTypeItemState extends State<_DiscountTypeItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          alignment: Alignment.center,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF0088FF) : Colors.transparent,
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 13,
              color: _isHovered ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ),
      ),
    );
  }
}


class _GstinPopover extends StatefulWidget {
  final String gstin;
  final ValueChanged<String> onUpdate;
  final VoidCallback onCancel;

  const _GstinPopover({
    required this.gstin,
    required this.onUpdate,
    required this.onCancel,
  });

  @override
  State<_GstinPopover> createState() => _GstinPopoverState();
}

class _GstinPopoverState extends State<_GstinPopover> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.gstin);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30),
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
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDDDDD)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.alertTriangle,
                          color: Color(0xFFEAB308),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Update GSTIN / UIN',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 24),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4B5563),
                                fontFamily: 'Inter',
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(text: 'Updating the GSTIN will '),
                                TextSpan(
                                  text: 'overwrite the existing GSTIN ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: 'for this vendor in the database.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 24),
                        const Text(
                          'Primary GSTIN',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'GSTIN / UIN',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 32,
                      child: CustomTextField(
                        controller: _ctrl,
                        hintText: 'Enter GSTIN',
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF333333), fontSize: 12, fontFamily: 'Inter'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => widget.onUpdate(_ctrl.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF19A05E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Inter'),
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

class _HoverBorderContainer extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  const _HoverBorderContainer({required this.child, this.isSelected = false});

  @override
  State<_HoverBorderContainer> createState() => _HoverBorderContainerState();
}

class _HoverBorderContainerState extends State<_HoverBorderContainer> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: (_hovered || widget.isSelected) ? const Color(0xFF3B82F6) : Colors.transparent,
            width: 1,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class _TaxAmountField extends StatefulWidget {
  final String value;
  const _TaxAmountField({required this.value});

  @override
  State<_TaxAmountField> createState() => _TaxAmountFieldState();
}

class _TaxAmountFieldState extends State<_TaxAmountField> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focus) => setState(() => _isFocused = focus),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          width: 100,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isFocused
                  ? const Color(0xFF3B82F6)
                  : (_isHovered ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB)),
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: TextEditingController(text: widget.value),
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              isDense: true,
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.fromLTRB(10, 8, 10, 8),
            ),
          ),
        ),
      ),
    );
  }
}
