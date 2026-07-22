import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/radio_group.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_page_header.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_data_table_shell.dart';

enum _ItemsSettingsTab {
  preferences('Preferences'),
  fields('Fields'),
  validationRules('Validation Rules'),
  recordLocking('Record Locking'),
  buttons('Buttons'),
  relatedLists('Related Lists');

  const _ItemsSettingsTab(this.label);

  final String label;
}

class _ItemCustomFieldRow {
  const _ItemCustomFieldRow({
    required this.fieldName,
    required this.dataType,
    required this.mandatory,
    required this.showInAllPdfs,
    required this.status,
    this.showSelectionBadge = false,
  });

  final String fieldName;
  final String dataType;
  final String mandatory;
  final String showInAllPdfs;
  final String status;
  final bool showSelectionBadge;

  _ItemCustomFieldRow copyWith({
    String? fieldName,
    String? dataType,
    String? mandatory,
    String? showInAllPdfs,
    String? status,
    bool? showSelectionBadge,
  }) {
    return _ItemCustomFieldRow(
      fieldName: fieldName ?? this.fieldName,
      dataType: dataType ?? this.dataType,
      mandatory: mandatory ?? this.mandatory,
      showInAllPdfs: showInAllPdfs ?? this.showInAllPdfs,
      status: status ?? this.status,
      showSelectionBadge: showSelectionBadge ?? this.showSelectionBadge,
    );
  }
}

class SettingsItemsPage extends ConsumerStatefulWidget {
  const SettingsItemsPage({super.key});

  @override
  ConsumerState<SettingsItemsPage> createState() => _SettingsItemsPageState();
}

class _SettingsItemsPageState extends ConsumerState<SettingsItemsPage> {
  static const double _compactContentBreakpoint = 720;
  static const double _compactDialogBreakpoint = 560;
  static const double _fieldsTableMinWidth = 922;
  static const double _fieldsActionLeftShift = 240;
  static const double _itemsDropdownScrollbarThickness = 8;
  static const double _itemsDropdownScrollHintWidth = 18;
  static const double _itemsDropdownScrollbarGutterWidth = 18;
  static const double _itemsDropdownScrollHintIconSize = 22;
  static const Color _itemsDropdownScrollbarThumbColor = Color(0xFFA4A1AE);
  static const Color _itemsDropdownScrollHintColor = Color(0xFFC3C8D3);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _fieldSearchController = TextEditingController();
  final GlobalKey _inventoryStartDateKey = GlobalKey();

  _ItemsSettingsTab _activeTab = _ItemsSettingsTab.preferences;
  int? _hoveredFieldRowIndex;
  int? _openFieldActionRowIndex;
  String _fieldFilterBy = 'Item';
  String _decimalRate = '2';
  String _dimensionUnit = 'cm';
  String _weightUnit = 'kg';
  String _barcodeSelection = 'UPC';
  String _valuationMethod = 'FIFO (First In, First Out)';
  bool _allowDuplicateItemNames = false;
  bool _enableEnhancedItemSearch = true;
  bool _enableHsnSac = false;
  String _hsnSacPreference = '6-digit HSN Code or SAC';
  bool _enablePriceLists = false;
  bool _applyPriceListAtLineItemLevel = true;
  bool _enableCompositeItems = true;
  DateTime _inventoryStartDate = DateTime(2024, 4, 1);
  bool _enableSerialNumberTracking = false;
  bool _allowReturnsOnlyForSoldSerialNumbers = false;
  bool _enableBatchTracking = false;
  bool _allowDuplicateBatchNumbers = false;
  bool _allowReturnsOnlyToSoldBatch = false;
  bool _allowDifferentSellingPricePerBatch = false;
  bool _preventStockBelowZero = false;
  String _stockLevel = 'Location level';
  bool _showOutOfStockWarning = false;
  bool _notifyReorderPoint = false;
  String _notifyTo = 'zabnixprivatelimited@gmail.com';
  bool _trackLandedCostOnItems = false;
  String _trackingPreference = 'Packages, Purchase Receives & Return Receipts';
  bool _trackingMandatory = true;

  static const List<String> _decimalRateOptions = <String>[
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
  ];

  static const List<String> _dimensionOptions = <String>['cm', 'in'];

  static const List<String> _weightOptions = <String>['kg', 'g', 'lb', 'oz'];

  static const List<String> _barcodeOptions = <String>[
    'UPC',
    'SKU',
    'ISBN',
    'EAN',
  ];

  static const List<String> _valuationOptions = <String>[
    'FIFO (First In, First Out)',
    'FEFO (First Expired, First Out)',
    'Weighted Average Cost',
  ];

  static const List<String> _notifyToOptions = <String>[
    'zabnixprivatelimited@gmail.com',
    'malayanakathalthaf@gmail.com',
    'accounts@zabnix.com',
    'inventory@zabnix.com',
  ];

  static const List<String> _trackingPreferenceOptions = <String>[
    'Invoices, Bills & Credit Notes',
    'Packages, Purchase Receives & Return Receipts',
  ];

  static const List<String> _fieldFilterOptions = <String>['Item', 'Batch'];

  static const List<_ItemCustomFieldRow> _itemCustomFieldRows =
      <_ItemCustomFieldRow>[
        _ItemCustomFieldRow(
          fieldName: 'Selling Price',
          dataType: 'Decimal',
          mandatory: 'No',
          showInAllPdfs: 'No',
          status: 'Active',
        ),
        _ItemCustomFieldRow(
          fieldName: 'Purchase Price',
          dataType: 'Decimal',
          mandatory: 'No',
          showInAllPdfs: 'No',
          status: 'Active',
          showSelectionBadge: true,
        ),
        _ItemCustomFieldRow(
          fieldName: 'SKU',
          dataType: 'Text Box (Single Line)',
          mandatory: 'No',
          showInAllPdfs: 'No',
          status: 'Active',
        ),
        _ItemCustomFieldRow(
          fieldName: 'Image',
          dataType: 'Text Box (Single Line)',
          mandatory: 'No',
          showInAllPdfs: 'No',
          status: 'Active',
        ),
        _ItemCustomFieldRow(
          fieldName: 'Category',
          dataType: 'Text Box (Single Line)',
          mandatory: 'No',
          showInAllPdfs: 'No',
          status: 'Active',
        ),
        _ItemCustomFieldRow(
          fieldName: 'MRP',
          dataType: 'Decimal',
          mandatory: 'No',
          showInAllPdfs: 'No',
          status: 'Inactive',
        ),
        _ItemCustomFieldRow(
          fieldName: 'Alias Name',
          dataType: 'Text Box (Single Line)',
          mandatory: 'No',
          showInAllPdfs: 'No',
          status: 'Inactive',
        ),
      ];

  static const List<_ItemCustomFieldRow> _batchCustomFieldRows =
      <_ItemCustomFieldRow>[
        _ItemCustomFieldRow(
          fieldName: 'Manufactured Date',
          dataType: 'Date',
          mandatory: 'No',
          showInAllPdfs: 'No',
          status: 'Active',
        ),
        _ItemCustomFieldRow(
          fieldName: 'Manufacturer Batch #',
          dataType: 'Text Box (Single Line)',
          mandatory: 'No',
          showInAllPdfs: 'No',
          status: 'Active',
        ),
        _ItemCustomFieldRow(
          fieldName: 'Batch Reference#',
          dataType: 'Text Box (Single Line)',
          mandatory: 'No',
          showInAllPdfs: 'No',
          status: 'Active',
        ),
        _ItemCustomFieldRow(
          fieldName: 'Expiry Date',
          dataType: 'Date',
          mandatory: 'No',
          showInAllPdfs: 'No',
          status: 'Active',
        ),
      ];

  late final List<_ItemCustomFieldRow> _itemFieldRows;
  late final List<_ItemCustomFieldRow> _batchFieldRows;

  @override
  void initState() {
    super.initState();
    _itemFieldRows = List<_ItemCustomFieldRow>.of(_itemCustomFieldRows);
    _batchFieldRows = List<_ItemCustomFieldRow>.of(_batchCustomFieldRows);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fieldSearchController.dispose();
    super.dispose();
  }

  List<_ItemCustomFieldRow> get _filteredFieldRows {
    final sourceRows = _fieldFilterBy == 'Batch'
        ? _batchFieldRows
        : _itemFieldRows;
    final query = _fieldSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return sourceRows;
    }

    return sourceRows
        .where((row) {
          return row.fieldName.toLowerCase().contains(query) ||
              row.dataType.toLowerCase().contains(query) ||
              row.status.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  List<SettingsSearchItem> _buildSearchItems(BuildContext context) {
    return kSettingsNavigationSections
        .expand(
          (section) => section.blocks.expand(
            (block) => block.items.map(
              (entry) => SettingsSearchItem(
                group: block.title,
                label: entry.label,
                subtitle: section.title,
                keywords: <String>[section.title, block.title, entry.label],
                onSelected: () => _handleEntryTap(context, entry),
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  void _handleEntryTap(BuildContext context, SettingsNavigationEntry entry) {
    if (entry.route == null) {
      return;
    }
    context.go(_orgScopedRoute(context, entry.route!));
  }

  String _orgScopedRoute(BuildContext context, String route) {
    final path = GoRouterState.of(context).uri.path;
    final match = RegExp(r'^/(\d{10,20})(?:/|$)').firstMatch(path);
    final orgSystemId = match?.group(1);
    if (orgSystemId == null || orgSystemId.isEmpty) {
      return route;
    }
    return '/$orgSystemId$route';
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(
      context,
    ).uri.path.replaceFirst(RegExp(r'^/\d{10,20}'), '');
    ref.watch(orgSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SettingsPageHeader(
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            searchItems: _buildSearchItems(context),
            showBackButton: true,
            onBack: () =>
                context.go(_orgScopedRoute(context, AppRoutes.settings)),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsNavigationSidebar(currentPath: currentPath),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTitleBar(),
                      _buildTabBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: _activeTab == _ItemsSettingsTab.fields
                              ? const EdgeInsets.only(bottom: 24)
                              : const EdgeInsets.fromLTRB(20, 18, 28, 24),
                          child: _buildActiveTabContent(),
                        ),
                      ),
                      _buildFooter(),
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

  Widget _buildTitleBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = _isCompactContentWidth(constraints.maxWidth);
        final actions = _activeTab == _ItemsSettingsTab.fields
            ? _buildFieldsTopActions(isCompact: isCompact)
            : null;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items',
                      style: AppTheme.pageTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (actions != null) ...[
                      const SizedBox(height: 12),
                      actions,
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Items',
                        style: AppTheme.pageTitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (actions != null) actions,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in _ItemsSettingsTab.values) _buildTabChip(tab),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(_ItemsSettingsTab tab) {
    final isActive = _activeTab == tab;
    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 11),
        margin: const EdgeInsets.only(right: 28),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          tab.label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppTheme.primaryBlue : const Color(0xFF667085),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    if (_activeTab == _ItemsSettingsTab.fields) {
      return _buildFieldsTab();
    }

    if (_activeTab == _ItemsSettingsTab.preferences) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 810),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreferenceRow(
              label: 'Set a decimal rate for your item quantity',
              child: _buildDropdown(
                value: _decimalRate,
                items: _decimalRateOptions,
                showSearch: true,
                placeholder: 'Search',
                paintSelectionBackground: false,
                itemBuilder: _buildTrackingPreferenceDropdownItem,
                searchIcon: const Icon(
                  LucideIcons.search,
                  size: 15,
                  color: Color(0xFFC1C7D0),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _decimalRate = value);
                  }
                },
              ),
            ),
            _buildPreferenceRow(
              label: 'Measure item dimensions in:',
              child: _buildDropdown(
                value: _dimensionUnit,
                items: _dimensionOptions,
                showSearch: true,
                placeholder: 'Search',
                paintSelectionBackground: false,
                itemBuilder: _buildTrackingPreferenceDropdownItem,
                searchIcon: const Icon(
                  LucideIcons.search,
                  size: 15,
                  color: Color(0xFFC1C7D0),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _dimensionUnit = value);
                  }
                },
              ),
            ),
            _buildPreferenceRow(
              label: 'Measure item weights in:',
              child: _buildDropdown(
                value: _weightUnit,
                items: _weightOptions,
                paintSelectionBackground: false,
                itemBuilder: _buildTrackingPreferenceDropdownItem,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _weightUnit = value);
                  }
                },
              ),
            ),
            _buildPreferenceRow(
              label: 'Select items when barcodes are scanned using:',
              trailing: ZTooltip(
                message:
                    'Every time you scan a barcode, only the selected field\'s value will be used for identifying an item. However, when you search for an item from the Item Table of a transaction, you can search for it using the Item Name, SKU or UPC.',
                direction: ZTooltipDirection.top,
                child: const Icon(
                  LucideIcons.helpCircle,
                  size: 14,
                  color: Color(0xFF98A2B3),
                ),
              ),
              child: _buildDropdown(
                value: _barcodeSelection,
                items: _barcodeOptions,
                showSearch: true,
                placeholder: 'Search',
                paintSelectionBackground: false,
                itemBuilder: _buildTrackingPreferenceDropdownItem,
                searchIcon: const Icon(
                  LucideIcons.search,
                  size: 15,
                  color: Color(0xFFC1C7D0),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _barcodeSelection = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 17),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            const SizedBox(height: 20),
            Text(
              'Default Inventory Valuation Method',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This valuation method will be used by default when creating items, variants and composite items.',
              style: AppTheme.bodyText.copyWith(
                fontSize: 12.5,
                color: const Color(0xFF98A2B3),
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            _buildPreferenceRow(
              label: 'Inventory Valuation Method',
              labelWidth: 265,
              fieldWidth: 252,
              child: _buildDropdown(
                value: _valuationMethod,
                items: _valuationOptions,
                showSearch: true,
                placeholder: 'Search',
                paintSelectionBackground: false,
                itemBuilder: _buildValuationDropdownItem,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _valuationMethod = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 17),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            const SizedBox(height: 19),
            _buildSectionHeader('Duplicate Item Name'),
            const SizedBox(height: 10),
            _buildCheckboxLine(
              value: _allowDuplicateItemNames,
              label: 'Allow duplicate item names',
              onChanged: (value) =>
                  setState(() => _allowDuplicateItemNames = value),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'If you allow duplicate item names, all imports involving items will use SKU as the primary field for mapping.',
                style: _helperTextStyle(),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: _buildHintBanner(
                icon: Icons.warning_amber_rounded,
                leading: const Icon(
                  LucideIcons.alertTriangle,
                  size: 16,
                  color: Color(0xFFFB923C),
                ),
                text:
                    'Before you enable this option, make the SKU field active and mandatory.',
                showPointer: true,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            const SizedBox(height: 20),
            _buildSectionHeader('Enhanced Item Search'),
            const SizedBox(height: 10),
            _buildCheckboxLine(
              value: _enableEnhancedItemSearch,
              label: 'Enable Enhanced Item Search',
              onChanged: (value) =>
                  setState(() => _enableEnhancedItemSearch = value),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: _buildHintBanner(
                icon: Icons.info_rounded,
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFB923C),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.info,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
                text:
                    'Enabling this option makes it easier to find any item using relevant keywords in any order.',
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            const SizedBox(height: 20),
            _buildSectionHeader('HSN Code or SAC'),
            const SizedBox(height: 10),
            _buildCheckboxLine(
              value: _enableHsnSac,
              label: 'Enable the HSN Code or SAC field',
              onChanged: (value) => setState(() => _enableHsnSac = value),
            ),
            if (_enableHsnSac) ...[
              const SizedBox(height: 14),
              RichText(
                text: TextSpan(
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 15.5,
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: 'Mandatory ',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 15.5,
                        color: const Color(0xFFFE5D5D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: 'HSN Code or SAC Preference'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'The Central Board of Indirect Taxes and Customs (CBIC) has mandated HSN Code or SAC for items effective from 1 April 2021.',
                style: _helperTextStyle(),
              ),
              const SizedBox(height: 16),
              _buildRadioPreferenceCard(
                title: '4-digit HSN Code or SAC',
                description:
                    'Select this option if your business’s annual turnover was less than ₹5 crores in the previous year. The 4-digit HSN Code or SAC is mandatory for B2B, SEZ, Export, or Deemed Export tax invoices and optional for B2C tax invoices.',
                isSelected: _hsnSacPreference == '4-digit HSN Code or SAC',
                onTap: () => setState(
                  () => _hsnSacPreference = '4-digit HSN Code or SAC',
                ),
              ),
              const SizedBox(height: 10),
              _buildRadioPreferenceCard(
                title: '6-digit HSN Code or SAC',
                description:
                    'Select this option if your business’s annual turnover was more than ₹5 crores in the previous year. The 6-digit HSN Code or SAC is mandatory for all tax invoices.',
                isSelected: _hsnSacPreference == '6-digit HSN Code or SAC',
                onTap: () => setState(
                  () => _hsnSacPreference = '6-digit HSN Code or SAC',
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildSectionHeader('Price Lists'),
                const SizedBox(width: 4),
                ZTooltip(
                  message:
                      'Enable multiple price lists for item-based sales and purchase transactions.',
                  direction: ZTooltipDirection.top,
                  child: const Icon(
                    LucideIcons.helpCircle,
                    size: 14,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildCheckboxLine(
              value: _enablePriceLists,
              label: 'Enable Price Lists',
              onChanged: (value) => setState(() => _enablePriceLists = value),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'Price Lists enables you to customise the rates of the items in your sales and purchase transactions.',
                style: _helperTextStyle(),
              ),
            ),
            if (_enablePriceLists) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: _buildNestedCheckboxLine(
                  value: _applyPriceListAtLineItemLevel,
                  label: 'Apply price list at line item level',
                  helper:
                      'Select this option if you want to apply different price lists for each line item.',
                  onChanged: (value) =>
                      setState(() => _applyPriceListAtLineItemLevel = value),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            const SizedBox(height: 20),
            _buildSectionHeader('Composite Items'),
            const SizedBox(height: 10),
            _buildCheckboxLine(
              value: _enableCompositeItems,
              label: 'Enable Composite Items',
              onChanged: (value) =>
                  setState(() => _enableCompositeItems = value),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: SizedBox(width: 258, child: _buildDateField()),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            const SizedBox(height: 20),
            _buildSectionHeader('Advanced Inventory Tracking'),
            const SizedBox(height: 10),
            _buildCheckboxLine(
              value: _enableSerialNumberTracking,
              label: 'Enable Serial Number Tracking',
              onChanged: (value) =>
                  setState(() => _enableSerialNumberTracking = value),
            ),
            if (_enableSerialNumberTracking) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: _buildNestedCheckboxLine(
                  value: _allowReturnsOnlyForSoldSerialNumbers,
                  label: 'Allow returns only for sold serial numbers',
                  onChanged: (value) => setState(
                    () => _allowReturnsOnlyForSoldSerialNumbers = value,
                  ),
                  checkedColor: Colors.white,
                  fillWhenChecked: const Color(0xFFE5E7EB),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _buildCheckboxLine(
              value: _enableBatchTracking,
              label: 'Enable Batch Tracking',
              onChanged: (value) =>
                  setState(() => _enableBatchTracking = value),
            ),
            if (_enableBatchTracking) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  children: [
                    _buildNestedCheckboxLine(
                      value: _allowDuplicateBatchNumbers,
                      label: 'Allow duplicate batch numbers',
                      onChanged: (value) =>
                          setState(() => _allowDuplicateBatchNumbers = value),
                    ),
                    const SizedBox(height: 10),
                    _buildNestedCheckboxLine(
                      value: _allowReturnsOnlyToSoldBatch,
                      label: 'Allow returns only to the sold batch',
                      onChanged: (value) =>
                          setState(() => _allowReturnsOnlyToSoldBatch = value),
                    ),
                    const SizedBox(height: 10),
                    _buildNestedCheckboxLine(
                      value: _allowDifferentSellingPricePerBatch,
                      label:
                          'Allow different Selling price for each Batch Tracked Items',
                      onChanged: (value) => setState(
                        () => _allowDifferentSellingPricePerBatch = value,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_enableSerialNumberTracking || _enableBatchTracking) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _buildTrackingInfoCard(),
              ),
            ],
            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            const SizedBox(height: 14),
            _buildCheckboxLine(
              value: _preventStockBelowZero,
              label: 'Prevent stock from going below zero',
              onChanged: (value) =>
                  setState(() => _preventStockBelowZero = value),
            ),
            if (_preventStockBelowZero) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRadioLine(
                      value: 'Organization level',
                      label: 'Organization level',
                      tooltip:
                          'If you select this option, you cannot create any transaction that will result in your accounting stock to fall below zero in your organisation.',
                      useInfoBadge: true,
                    ),
                    const SizedBox(height: 8),
                    _buildRadioLine(
                      value: 'Location level',
                      label: 'Location level',
                      tooltip:
                          'If you select this option, you cannot create any transaction that will result in your accounting stock to fall below zero in the respective location.',
                      useInfoBadge: true,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _buildCheckboxLine(
              value: _showOutOfStockWarning,
              label:
                  'Show an Out of Stock warning when an item\'s stock drops below zero',
              onChanged: (value) =>
                  setState(() => _showOutOfStockWarning = value),
              tooltip:
                  'If you select this, a warning will be shown whenever a transaction results in the stock level dropping below zero.',
              useInfoBadge: true,
            ),
            const SizedBox(height: 8),
            _buildCheckboxLine(
              value: _notifyReorderPoint,
              label:
                  'Notify me if an item\'s quantity reaches the reorder point',
              onChanged: (value) => setState(() => _notifyReorderPoint = value),
              tooltip:
                  'Send a reminder when an item reaches its configured reorder level.',
              useInfoBadge: true,
            ),
            if (_notifyReorderPoint) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: SizedBox(width: 258, child: _buildNotifyDropdown()),
              ),
            ],
            const SizedBox(height: 14),
            _buildCheckboxLine(
              value: _trackLandedCostOnItems,
              label: 'Track landed cost on items',
              onChanged: (value) =>
                  setState(() => _trackLandedCostOnItems = value),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '${_activeTab.label} settings will appear here.',
          style: AppTheme.bodyText.copyWith(
            fontSize: 13.5,
            color: const Color(0xFF667085),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldsTab() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFFAFAFA),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Filter By :',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF334155),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(
                    width: 98,
                    child: FormDropdown<String>(
                      value: _fieldFilterBy,
                      items: _fieldFilterOptions,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _fieldFilterBy = value);
                        }
                      },
                      height: 32,
                      showSearch: false,
                      paintSelectionBackground: false,
                      boldSelected: false,
                      borderRadius: BorderRadius.circular(4),
                      iconSize: 16,
                      scrollbarThickness: _itemsDropdownScrollbarThickness,
                      scrollHintWidth: _itemsDropdownScrollHintWidth,
                      scrollbarGutterWidth: _itemsDropdownScrollbarGutterWidth,
                      scrollHintIconSize: _itemsDropdownScrollHintIconSize,
                      scrollbarThumbColor: _itemsDropdownScrollbarThumbColor,
                      scrollHintColor: _itemsDropdownScrollHintColor,
                      itemBuilder: _buildFieldFilterDropdownItem,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 286,
                    height: 32,
                    child: TextField(
                      controller: _fieldSearchController,
                      onChanged: (_) => setState(() {}),
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF475467),
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search Field Name',
                        hintStyle: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF98A2B3),
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          size: 15,
                          color: Color(0xFF98A2B3),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.borderLight,
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
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth > _fieldsTableMinWidth
                  ? constraints.maxWidth
                  : _fieldsTableMinWidth;
              final trailingWidth = tableWidth > _fieldsTableMinWidth
                  ? tableWidth - _fieldsTableMinWidth
                  : 0.0;
              final actionShift = trailingWidth > _fieldsActionLeftShift
                  ? _fieldsActionLeftShift
                  : trailingWidth;
              final trailingGapWidth = trailingWidth - actionShift;
              final actionSlotWidth = 32.0 + actionShift;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: tableWidth),
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFFFAFAFA),
                        child: ZTableHeader(
                          horizontalPadding: 0,
                          children: [
                            _buildFieldsHeaderCell(
                              'FIELD NAME',
                              width: 210,
                              leftPad: 24,
                            ),
                            _buildFieldsHeaderCell('DATA TYPE', width: 205),
                            _buildFieldsHeaderCell('MANDATORY', width: 140),
                            _buildFieldsHeaderCell(
                              'SHOW IN ALL PDFS',
                              width: 205,
                            ),
                            _buildFieldsHeaderCell('STATUS', width: 130),
                            SizedBox(width: trailingGapWidth),
                            SizedBox(width: actionSlotWidth),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.borderLight,
                      ),
                      for (
                        int index = 0;
                        index < _filteredFieldRows.length;
                        index++
                      )
                        _buildFieldsDataRow(
                          _filteredFieldRows[index],
                          index,
                          trailingWidth: trailingGapWidth,
                          actionSlotWidth: actionSlotWidth,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_filteredFieldRows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Text(
                'No fields found.',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldsTopActions({bool isCompact = false}) {
    final usageText = Text(
      'Custom Fields Usage: 0/135',
      style: AppTheme.bodyText.copyWith(
        fontSize: 12.5,
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w500,
      ),
    );

    final button = SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () => context.go(
          _orgScopedRoute(context, AppRoutes.settingsItemsNewField),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 18, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'New Field',
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    if (isCompact) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [usageText, button],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [usageText, const SizedBox(width: 12), button],
    );
  }

  Widget _buildFieldsHeaderCell(
    String label, {
    required double width,
    double leftPad = 0,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.only(left: leftPad, right: 12),
        child: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 11,
            color: const Color(0xFF667085),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldsDataRow(
    _ItemCustomFieldRow row,
    int index, {
    double trailingWidth = 0,
    double actionSlotWidth = 32,
  }) {
    final statusColor = row.status == 'Active'
        ? const Color(0xFF3FB885)
        : const Color(0xFF111827);
    final isHovered = _hoveredFieldRowIndex == index;
    final isMenuOpen = _openFieldActionRowIndex == index;
    final isHighlighted = isHovered || isMenuOpen;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredFieldRowIndex = index),
      onExit: (_) {
        if (_hoveredFieldRowIndex == index) {
          setState(() => _hoveredFieldRowIndex = null);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: isHighlighted ? const Color(0xFFF3F4F6) : Colors.white,
        child: Column(
          children: [
            SizedBox(
              height: 33,
              child: Row(
                children: [
                  SizedBox(
                    width: 210,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.lock,
                            size: 14,
                            color: Color(0xFF111827),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              row.fieldName,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dotted,
                                decorationColor: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildFieldsValueCell(row.dataType, width: 205),
                  _buildFieldsValueCell(row.mandatory, width: 140),
                  _buildFieldsValueCell(row.showInAllPdfs, width: 205),
                  _buildFieldsValueCell(
                    row.status,
                    width: 130,
                    color: statusColor,
                  ),
                  SizedBox(width: trailingWidth),
                  SizedBox(
                    width: actionSlotWidth,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: isHighlighted
                          ? _buildFieldActionMenu(row, index)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldActionMenu(_ItemCustomFieldRow row, int index) {
    return MenuAnchor(
      alignmentOffset: const Offset(-120, 10),
      onOpen: () => setState(() => _openFieldActionRowIndex = index),
      onClose: () {
        if (_openFieldActionRowIndex == index) {
          setState(() => _openFieldActionRowIndex = null);
        }
      },
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.white),
        padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
        elevation: WidgetStateProperty.all(10),
        shadowColor: WidgetStateProperty.all(const Color(0x260F172A)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF3FB885),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x29000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.chevronDown,
              size: 13,
              color: Colors.white,
            ),
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          style: _fieldActionMenuItemStyle(highlighted: true),
          onPressed: () => _toggleFieldStatus(row),
          child: Text(_fieldStatusActionLabel(row)),
        ),
        MenuItemButton(
          style: _fieldActionMenuItemStyle(),
          onPressed: () => _toggleFieldPdfVisibility(row),
          child: Text(_fieldPdfActionLabel(row)),
        ),
      ],
    );
  }

  ButtonStyle _fieldActionMenuItemStyle({bool highlighted = false}) {
    return ButtonStyle(
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return AppTheme.primaryBlue;
        }
        return Colors.white;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return Colors.white;
        }
        return const Color(0xFF475467);
      }),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      ),
      minimumSize: WidgetStateProperty.all(const Size(148, 36)),
      alignment: Alignment.centerLeft,
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      textStyle: WidgetStateProperty.all(
        AppTheme.bodyText.copyWith(fontSize: 13, fontWeight: FontWeight.w400),
      ),
    );
  }

  String _fieldStatusActionLabel(_ItemCustomFieldRow row) {
    return row.status == 'Active' ? 'Mark as Inactive' : 'Mark as Active';
  }

  String _fieldPdfActionLabel(_ItemCustomFieldRow row) {
    return row.showInAllPdfs == 'Yes'
        ? 'Hide from All PDFs'
        : 'Show in All PDFs';
  }

  void _toggleFieldStatus(_ItemCustomFieldRow row) {
    final nextStatus = row.status == 'Active' ? 'Inactive' : 'Active';
    _updateFieldRow(row.fieldName, row.copyWith(status: nextStatus));
  }

  void _toggleFieldPdfVisibility(_ItemCustomFieldRow row) {
    final nextValue = row.showInAllPdfs == 'Yes' ? 'No' : 'Yes';
    _updateFieldRow(row.fieldName, row.copyWith(showInAllPdfs: nextValue));
  }

  void _updateFieldRow(String fieldName, _ItemCustomFieldRow nextRow) {
    final rows = _fieldFilterBy == 'Batch' ? _batchFieldRows : _itemFieldRows;
    final rowIndex = rows.indexWhere((row) => row.fieldName == fieldName);
    if (rowIndex == -1) {
      return;
    }

    setState(() {
      rows[rowIndex] = nextRow;
      _openFieldActionRowIndex = null;
    });
  }

  Widget _buildFieldsValueCell(
    String value, {
    required double width,
    Color? color,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: color ?? const Color(0xFF111827),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceRow({
    required String label,
    required Widget child,
    Widget? trailing,
    double labelWidth = 418,
    double fieldWidth = 112,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = _isCompactContentWidth(constraints.maxWidth);
        final labelWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF202124),
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 4), trailing],
          ],
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    labelWidget,
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: child,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: labelWidth, child: labelWidget),
                    const SizedBox(width: 16),
                    SizedBox(width: fieldWidth, child: child),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool showSearch = false,
    String? placeholder,
    bool paintSelectionBackground = true,
    bool boldSelected = true,
    Widget? searchIcon,
    Widget Function(String item, bool isSelected, bool isHovered)? itemBuilder,
  }) {
    return FormDropdown<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      height: 32,
      showSearch: showSearch,
      searchIcon: searchIcon,
      placeholder: placeholder,
      paintSelectionBackground: paintSelectionBackground,
      boldSelected: false,
      itemBuilder: itemBuilder,
      iconSize: 18,
      scrollbarThickness: _itemsDropdownScrollbarThickness,
      scrollHintWidth: _itemsDropdownScrollHintWidth,
      scrollbarGutterWidth: _itemsDropdownScrollbarGutterWidth,
      scrollHintIconSize: _itemsDropdownScrollHintIconSize,
      scrollbarThumbColor: _itemsDropdownScrollbarThumbColor,
      scrollHintColor: _itemsDropdownScrollHintColor,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      textStyle: AppTheme.bodyText.copyWith(
        fontSize: 13,
        color: const Color(0xFF475467),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildValuationDropdownItem(
    String item,
    bool isSelected,
    bool isHovered,
  ) {
    final backgroundColor = isHovered
        ? const Color(0xFF3B82F6)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent);
    final textColor = isHovered ? Colors.white : const Color(0xFF475467);
    final tickColor = isHovered ? Colors.white : const Color(0xFF98A2B3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item == 'Weighted Average Cost'
                    ? 'WAC (Weighted Average Costing)'
                    : item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check, size: 16, color: tickColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.pageTitle.copyWith(
        fontSize: 15.5,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1F2937),
      ),
    );
  }

  TextStyle _helperTextStyle() {
    return AppTheme.bodyText.copyWith(
      fontSize: 12,
      color: const Color(0xFF98A2B3),
      height: 1.55,
      fontWeight: FontWeight.w400,
    );
  }

  Widget _buildCheckboxLine({
    required bool value,
    required String label,
    required ValueChanged<bool> onChanged,
    String? tooltip,
    bool useInfoBadge = false,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: _buildCheckbox(value: value, onChanged: onChanged),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF344054),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (tooltip != null)
                    ZTooltip(
                      message: tooltip,
                      direction: ZTooltipDirection.top,
                      child: useInfoBadge
                          ? const _InlineInfoBadge()
                          : const Icon(
                              LucideIcons.helpCircle,
                              size: 14,
                              color: Color(0xFF98A2B3),
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

  Widget _buildNestedCheckboxLine({
    required bool value,
    required String label,
    required ValueChanged<bool> onChanged,
    String? helper,
    Color checkedColor = Colors.white,
    Color fillWhenChecked = AppTheme.primaryBlue,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: const _NestedCheckboxConnector(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: _buildCheckbox(
                        value: value,
                        onChanged: onChanged,
                        checkedColor: checkedColor,
                        fillWhenChecked: fillWhenChecked,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF344054),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                if (helper != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(helper, style: _helperTextStyle()),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color checkedColor = Colors.white,
    Color fillWhenChecked = AppTheme.primaryBlue,
  }) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Checkbox(
        value: value,
        onChanged: (next) => onChanged(next ?? false),
        activeColor: fillWhenChecked,
        checkColor: checkedColor,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
    );
  }

  Widget _buildHintBanner({
    required IconData icon,
    required String text,
    bool showPointer = false,
    Widget? leading,
  }) {
    final banner = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child:
                leading ?? Icon(icon, size: 18, color: const Color(0xFFFB923C)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: _buildBannerTextSpans(text)),
              style: AppTheme.bodyText.copyWith(
                fontSize: 12.5,
                color: const Color(0xFF475467),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );

    if (!showPointer) {
      return banner;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        banner,
        const Positioned(left: 32, bottom: -7, child: _HintBannerPointer()),
      ],
    );
  }

  List<TextSpan> _buildBannerTextSpans(String text) {
    const highlight = 'SKU field active and mandatory';
    if (!text.contains(highlight)) {
      return [TextSpan(text: text)];
    }
    final parts = text.split(highlight);
    return [
      TextSpan(text: parts.first),
      TextSpan(
        text: highlight,
        style: AppTheme.bodyText.copyWith(
          fontSize: 12.5,
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
      ),
      if (parts.length > 1) TextSpan(text: parts.last),
    ];
  }

  Widget _buildRadioPreferenceCard({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : const Color(0xFFD9DEE7),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: RadioScope<String>(
                value: _hsnSacPreference,
                onChanged: (_) => onTap(),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: RadioGroupItem<String>(
                    value: title,
                    activeColor: AppTheme.primaryBlue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF344054),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(description, style: _helperTextStyle()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Inventory Start Date*',
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: const Color(0xFFFE5D5D),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            ZTooltip(
              message:
                  'The date on which you: migrated to Zerpai Inventory (or) started using Zerpai Inventory.',
              direction: ZTooltipDirection.top,
              child: const Icon(
                LucideIcons.helpCircle,
                size: 14,
                color: Color(0xFF98A2B3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          key: _inventoryStartDateKey,
          onTap: _pickInventoryStartDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              _formatDate(_inventoryStartDate),
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: const Color(0xFF475467),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingInfoCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = _isCompactContentWidth(constraints.maxWidth);
        final configureAction = InkWell(
          onTap: _showTrackingPreferencesDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.settings,
                size: 14,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 4),
              Text(
                'Configure',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );

        final trackedIn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracked in:',
              style: AppTheme.bodyText.copyWith(
                fontSize: 12.5,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _trackingPreference,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: const Color(0xFF344054),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        final mandatory = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mandatory?',
              style: AppTheme.bodyText.copyWith(
                fontSize: 12.5,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _trackingMandatory ? 'Yes' : 'No',
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: const Color(0xFF344054),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    trackedIn,
                    const SizedBox(height: 14),
                    mandatory,
                    const SizedBox(height: 14),
                    configureAction,
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 5, child: trackedIn),
                    Expanded(flex: 3, child: mandatory),
                    configureAction,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildRadioLine({
    required String value,
    required String label,
    String? tooltip,
    bool useInfoBadge = false,
  }) {
    return InkWell(
      onTap: () => setState(() => _stockLevel = value),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: RadioScope<String>(
              value: _stockLevel,
              onChanged: (next) => setState(() => _stockLevel = next),
              child: SizedBox(
                width: 16,
                height: 16,
                child: RadioGroupItem<String>(
                  value: value,
                  activeColor: AppTheme.primaryBlue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF344054),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (tooltip != null)
                  ZTooltip(
                    message: tooltip,
                    direction: ZTooltipDirection.top,
                    child: useInfoBadge
                        ? const _InlineInfoBadge()
                        : const Icon(
                            LucideIcons.helpCircle,
                            size: 14,
                            color: Color(0xFF98A2B3),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isCompactContentWidth(double maxWidth) {
    return maxWidth < _compactContentBreakpoint;
  }

  Widget _buildNotifyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notify to*',
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: const Color(0xFFFE5D5D),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _notifyTo,
          items: _notifyToOptions,
          showSearch: true,
          placeholder: 'Search',
          paintSelectionBackground: false,
          boldSelected: false,
          itemBuilder: _buildTrackingPreferenceDropdownItem,
          onChanged: (value) {
            if (value != null) {
              setState(() => _notifyTo = value);
            }
          },
        ),
      ],
    );
  }

  Future<void> _pickInventoryStartDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _inventoryStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      targetKey: _inventoryStartDateKey,
    );
    if (picked != null) {
      setState(() => _inventoryStartDate = picked);
    }
  }

  Future<void> _showTrackingPreferencesDialog() async {
    String selectedPreference = _trackingPreference;
    bool mandatory = _trackingMandatory;

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x8A111827),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isCompact =
                    constraints.maxWidth < _compactDialogBreakpoint;
                final dialogWidth = isCompact ? constraints.maxWidth : 516.0;

                return Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: dialogWidth,
                          margin: EdgeInsets.zero,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x2E000000),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  14,
                                  18,
                                  14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Inventory Tracking Preferences',
                                        style: AppTheme.pageTitle.copyWith(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          Navigator.of(dialogContext).pop(),
                                      child: const Icon(
                                        LucideIcons.x,
                                        size: 17,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: AppTheme.borderLight,
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  16,
                                  18,
                                  20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 404,
                                      ),
                                      child: Text(
                                        'Choose the transactions in which you prefer to track your inventory:',
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                          height: 1.5,
                                          color: const Color(0xFF667085),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 376,
                                      ),
                                      child: FormDropdown<String>(
                                        value: selectedPreference,
                                        items: _trackingPreferenceOptions,
                                        onChanged: (value) {
                                          if (value != null) {
                                            setDialogState(
                                              () => selectedPreference = value,
                                            );
                                          }
                                        },
                                        height: 34,
                                        showSearch: true,
                                        placeholder: 'Search',
                                        paintSelectionBackground: false,
                                        boldSelected: false,
                                        itemBuilder:
                                            _buildTrackingPreferenceDropdownItem,
                                        iconSize: 18,
                                        scrollbarThickness:
                                            _itemsDropdownScrollbarThickness,
                                        scrollHintWidth:
                                            _itemsDropdownScrollHintWidth,
                                        scrollbarGutterWidth:
                                            _itemsDropdownScrollbarGutterWidth,
                                        scrollHintIconSize:
                                            _itemsDropdownScrollHintIconSize,
                                        scrollbarThumbColor:
                                            _itemsDropdownScrollbarThumbColor,
                                        scrollHintColor:
                                            _itemsDropdownScrollHintColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        textStyle: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                          color: const Color(0xFF475467),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'You can add the serial and batch details while:',
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 13,
                                        color: const Color(0xFF98A2B3),
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildDialogBullet('Creating a package'),
                                    const SizedBox(height: 14),
                                    _buildDialogBullet(
                                      'Recording a purchase receive',
                                    ),
                                    const SizedBox(height: 14),
                                    _buildDialogBullet(
                                      'Recording a return receipt',
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: AppTheme.borderLight,
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  14,
                                  18,
                                  14,
                                ),
                                child: InkWell(
                                  onTap: () => setDialogState(
                                    () => mandatory = !mandatory,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Row(
                                    children: [
                                      _buildCheckbox(
                                        value: mandatory,
                                        onChanged: (value) => setDialogState(
                                          () => mandatory = value,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Mandate serial number or batch tracking in transactions.',
                                          style: AppTheme.bodyText.copyWith(
                                            fontSize: 13,
                                            color: const Color(0xFF475467),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: AppTheme.borderLight,
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  22,
                                  18,
                                  24,
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    SizedBox(
                                      height: 30,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _trackingPreference =
                                                selectedPreference;
                                            _trackingMandatory = mandatory;
                                          });
                                          Navigator.of(dialogContext).pop();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF22B378,
                                          ),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          textStyle: AppTheme.bodyText.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                        child: const Text('Update'),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 30,
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.of(dialogContext).pop(),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFF3F4F6,
                                          ),
                                          foregroundColor: const Color(
                                            0xFF475467,
                                          ),
                                          side: const BorderSide(
                                            color: AppTheme.borderColor,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          textStyle: AppTheme.bodyText.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        child: const Text('Cancel'),
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
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDialogBullet(String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFF22B378),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.check, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: const Color(0xFF475467),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingPreferenceDropdownItem(
    String item,
    bool isSelected,
    bool isHovered,
  ) {
    final backgroundColor = isHovered
        ? const Color(0xFF3B82F6)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent);
    final textColor = isHovered ? Colors.white : const Color(0xFF475467);
    final tickColor = isHovered ? Colors.white : const Color(0xFF98A2B3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check, size: 16, color: tickColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFieldFilterDropdownItem(
    String item,
    bool isSelected,
    bool isHovered,
  ) {
    final isBlue = isHovered;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isBlue ? const Color(0xFF3B82F6) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SizedBox(
        height: 34,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              item,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: isBlue ? Colors.white : const Color(0xFF475467),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day-$month-$year';
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 30,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                textStyle: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintBannerPointer extends StatelessWidget {
  const _HintBannerPointer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 8),
      painter: _HintBannerPointerPainter(),
    );
  }
}

class _HintBannerPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFF7ED);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InlineInfoBadge extends StatelessWidget {
  const _InlineInfoBadge();

  @override
  Widget build(BuildContext context) {
    return const Icon(LucideIcons.info, size: 14, color: Color(0xFFB6B4C7));
  }
}

class _NestedCheckboxConnector extends StatelessWidget {
  const _NestedCheckboxConnector();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 14),
      painter: _NestedCheckboxConnectorPainter(),
    );
  }
}

class _NestedCheckboxConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(3, 1)
      ..lineTo(3, 9)
      ..quadraticBezierTo(3, 12, 6, 12)
      ..lineTo(13, 12);

    canvas.drawPath(path, paint);
    canvas.drawLine(const Offset(13, 12), const Offset(10.5, 9.8), paint);
    canvas.drawLine(const Offset(13, 12), const Offset(10.5, 13.4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
