import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:intl/intl.dart';

import '../models/branch_pricelist_model.dart';
import '../providers/branch_pricelist_provider.dart';
import 'widgets/volume_pricing_help_popover.dart';

final _branchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authUserProvider);
  final orgId = user?.orgId ?? '';
  if (orgId.isEmpty) return [];
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.get('/branches', queryParameters: {'org_id': orgId});
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map((json) => Map<String, dynamic>.from(json)).toList();
    }
  } catch (e) {
    debugPrint('Error fetching branches: $e');
  }
  return [];
});

const double __branchPriceListFieldWidth = 320;
const double _priceListTypeCardWidth = 240;
const double __branchPriceListLabelWidth = 150;
const double __branchPriceListFieldHeight = 34;
const double __branchPriceListRowGap = 14;
const double _pricingSchemeCardGap = 12;
const double _pricingSchemeCardWidth = 162;
const double _pricingSchemeUnitCardWidth = 146;
const double _pricingSchemeCardHeight = 44;
const double _bulkRatesMinWidth = 720;
const double _bulkRatesVolumeMinWidth = 960;
const double _bulkRatesRowHeight = 52;
const double _bulkRatesVolumeLineHeight = 40;
const double _bulkRatesAddRangeHeight = 34;
const double _bulkRatesRemoveWidth = 54;
const double _bulkRatesSelectionWidth = 30;

class BranchPriceListCreateScreen extends ConsumerStatefulWidget {
  final BranchPriceList? template;
  final BranchPriceList? branchPriceList;
  final String? branchPriceListId;

  const BranchPriceListCreateScreen({
    super.key,
    this.template,
    this.branchPriceList,
    this.branchPriceListId,
  });

  @override
  ConsumerState<BranchPriceListCreateScreen> createState() =>
      _BranchPriceListCreateScreenState();
}

class _BranchPriceListCreateScreenState
    extends ConsumerState<BranchPriceListCreateScreen> {
  static const String _listRoute = '/pricelists/branch-price-lists';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _percentageController = TextEditingController();
  final _itemSearchController = TextEditingController();
  final _examplesMenuController = MenuController();
  final Map<String, TextEditingController> _customRateControllers = {};
  final Map<String, TextEditingController> _volumeStartControllers = {};
  final Map<String, TextEditingController> _volumeEndControllers = {};
  final Map<String, TextEditingController> _volumeRateControllers = {};
  final Map<String, TextEditingController> _discountControllers = {};
  final Map<String, int> _volumeRangeCounts = {};
  final Set<String> _selectedBulkItemKeys = {};

  String _transactionType = 'sales';
  String _priceListType = 'all_items';
  String _pricingScheme = 'unit_pricing';
  String _percentageType = 'Markup';
  String _roundOffTo = 'Never mind';
  String _itemSearchQuery = '';
  final List<String> _associatedBranches = [];
  CurrencyOption _currency = defaultCurrencyOptions.first;
  bool _isDiscountEnabled = false;
  bool _isSeasonalEnabled = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isImportBranchPriceListEnabled = false;
  final GlobalKey _startDateKey = GlobalKey();
  final GlobalKey _endDateKey = GlobalKey();
  bool _isItemSearchVisible = false;
  bool _isBulkUpdateMode = false;
  bool _isSaving = false;
  bool _isLoading = false;
  String? _hoveredBulkRateCellKey;
  String? _activeBulkRateCellKey;

  @override
  void initState() {
    super.initState();
    if (widget.branchPriceList != null) {
      _initializeData(widget.branchPriceList!, isEdit: true);
    } else if (widget.branchPriceListId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchBranchPriceList();
      });
    } else if (widget.template != null) {
      _initializeData(widget.template!, isEdit: false);
    }
  }

  Future<void> _fetchBranchPriceList() async {
    setState(() => _isLoading = true);
    try {
      final p = await ref
          .read(branchPriceListNotifierProvider.notifier)
          .fetchBranchPriceListById(widget.branchPriceListId!);
      if (mounted && p != null) {
        setState(() {
          _initializeData(p, isEdit: true);
        });
      }
    } catch (e) {
      debugPrint('Error fetching price list: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeData(BranchPriceList p, {required bool isEdit}) {
    _nameController.text = isEdit ? p.name : 'Copy of ${p.name}';
    _descriptionController.text = p.description ?? '';
    _transactionType = p.transactionType;
    _priceListType = p.priceListType;
    _pricingScheme = p.pricingScheme;
    _roundOffTo = p.roundOffPreference ?? 'Never mind';
    _isDiscountEnabled = p.isDiscountEnabled;
    _isSeasonalEnabled = p.isSeasonalEnabled;
    _startDate = p.startDate;
    _endDate = p.endDate;

    if (p.associatedBranches != null) {
      _associatedBranches.clear();
      _associatedBranches.addAll(p.associatedBranches!);
    }

    if (_priceListType == 'all_items') {
      if (p.percentageValue != null) {
        final val = p.percentageValue!;
        _percentageController.text = val == val.toInt() ? val.toInt().toString() : val.toString();
      }
      if (p.percentageType != null && p.percentageType!.isNotEmpty) {
        _percentageType = p.percentageType!.toLowerCase() == 'markdown' ? 'Markdown' : 'Markup';
      }

      // Fallback details parser
      if (_percentageController.text.isEmpty) {
        final details = p.details ?? '';
        final parts = details.split('% ');
        if (parts.length == 2) {
          _percentageController.text = parts[0];
          _percentageType = parts[1];
        } else {
          final match = RegExp(r'(\d+\.?\d*)').firstMatch(details);
          if (match != null) _percentageController.text = match.group(0)!;
          if (details.contains('Markdown')) _percentageType = 'Markdown';
        }
      }
    } else if (p.itemRates != null) {
      for (final rate in p.itemRates!) {
        final itemId = rate.itemId;
        if (_pricingScheme == 'volume_pricing') {
          final ranges = rate.volumeRanges ?? [];
          _volumeRangeCounts[itemId] = ranges.length;
          for (var i = 0; i < ranges.length; i++) {
            final v = ranges[i];
            _volumeStartControllerFor(itemId, i).text =
                v.startQuantity.toString();
            _volumeEndControllerFor(itemId, i).text =
                v.endQuantity?.toString() ?? '';
            _volumeRateControllerFor(itemId, i).text =
                v.customRate.toString();
            if (_isDiscountEnabled && v.discountPercentage != null) {
              _discountControllerFor(_volumeDiscountKey(itemId, i)).text =
                  v.discountPercentage!.toString();
            }
          }
        } else {
          _customRateControllerFor(itemId).text =
              rate.customRate?.toString() ?? '';
          if (_isDiscountEnabled && rate.discountPercentage != null) {
            _discountControllerFor(itemId).text =
                rate.discountPercentage!.toString();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _percentageController.dispose();
    _itemSearchController.dispose();
    for (final controller in _customRateControllers.values) {
      controller.dispose();
    }
    for (final controller in _volumeStartControllers.values) {
      controller.dispose();
    }
    for (final controller in _volumeEndControllers.values) {
      controller.dispose();
    }
    for (final controller in _volumeRateControllers.values) {
      controller.dispose();
    }
    for (final controller in _discountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider);
    final isRestrictedBranchAdmin =
        user?.role.trim().toLowerCase() == 'branch_admin' &&
        user?.roleIsDefault == true;
    
    final isEdit = widget.branchPriceList != null || widget.branchPriceListId != null;
    final pageTitle = isEdit ? 'Edit Branch Price List' : 'New Branch Price List';

    if (isRestrictedBranchAdmin) {
      return ColoredBox(
        color: Colors.white,
        child: ZerpaiLayout(
          pageTitle: pageTitle,
          enableBodyScroll: true,
          actions: [
            IconButton(
              onPressed: _cancel,
              icon: const Icon(
                LucideIcons.x,
                size: 24,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Branch Admin role cannot create Branch Price Lists.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ZButton.secondary(
                    label: 'Back to Branch Price Lists',
                    onPressed: _cancel,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: Colors.white,
      child: ZerpaiLayout(
        pageTitle: pageTitle,
        enableBodyScroll: true,
        actions: [
          IconButton(
            onPressed: _cancel,
            icon: const Icon(
              LucideIcons.x,
              size: 24,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
        footer: _buildFooter(),
        onSave: _save,
        onCancel: _cancel,
        child: Skeletonizer(
          enabled: _isLoading,
          child: Form(
            key: _formKey,
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameRow(),
                    const SizedBox(height: __branchPriceListRowGap),
                    _buildSeasonalRow(),
                    const SizedBox(height: __branchPriceListRowGap),
                    _buildAssociatedBranchesRow(),
                    const SizedBox(height: __branchPriceListRowGap),
                    _buildTransactionTypeRow(),
                    const SizedBox(height: __branchPriceListRowGap),
                    _buildpriceListTypeRow(),
                    const SizedBox(height: __branchPriceListRowGap),
                    _buildDescriptionRow(),
                    if (_priceListType == 'all_items') ...[
                      const SizedBox(height: __branchPriceListRowGap),
                      _buildPercentageRow(),
                      const SizedBox(height: __branchPriceListRowGap),
                      _buildRoundOffRow(),
                    ] else ...[
                      const SizedBox(height: __branchPriceListRowGap),
                      _buildPricingSchemeRow(),
                      const SizedBox(height: __branchPriceListRowGap),
                      _buildCurrencyRow(),
                      const SizedBox(height: __branchPriceListRowGap),
                      _buildDiscountRow(),
                      const SizedBox(height: 12),
                      _buildBulkRatesSection(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameRow() {
    return _FormRow(
      label: 'Name',
      required: true,
      child: SizedBox(
        width: __branchPriceListFieldWidth,
        child: CustomTextField(
          controller: _nameController,
          autoFocus: true,
          height: __branchPriceListFieldHeight,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildTransactionTypeRow() {
    final isEdit = widget.branchPriceList != null || widget.branchPriceListId != null;
    return _FormRow(
      label: 'Transaction Type',
      child: IgnorePointer(
        ignoring: isEdit,
        child: Opacity(
          opacity: isEdit ? 0.7 : 1.0,
          child: ZerpaiRadioGroup<String>(
            options: const ['sales', 'purchase'],
            current: _transactionType,
            labelBuilder: (value) => value == 'sales' ? 'Sales' : 'Purchase',
            onChanged: (value) => setState(() => _transactionType = value),
            activeColor: AppTheme.primaryBlueDark,
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonalRow() {
    return Column(
      children: [
        _FormRow(
          label: 'Seasonal Price List',
          child: InkWell(
            onTap: () {
              setState(() => _isSeasonalEnabled = !_isSeasonalEnabled);
            },
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: _isSeasonalEnabled,
                    onChanged: (value) {
                      setState(() => _isSeasonalEnabled = value ?? false);
                    },
                    activeColor: AppTheme.primaryBlueDark,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(
                      color: AppTheme.borderMid,
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'I want to enable seasonal price list',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isSeasonalEnabled) ...[
          const SizedBox(height: __branchPriceListRowGap),
          _FormRow(
            label: 'Validity Period',
            required: true,
            child: Row(
              children: [
                SizedBox(
                  width: 180,
                  height: __branchPriceListFieldHeight,
                  child: InkWell(
                    key: _startDateKey,
                    onTap: () async {
                      final picked = await ZerpaiDatePicker.show(
                        context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        targetKey: _startDateKey,
                      );
                      if (picked != null) {
                        setState(() => _startDate = picked);
                      }
                    },
                    child: IgnorePointer(
                      child: CustomTextField(
                        controller: TextEditingController(
                          text: _startDate != null
                              ? DateFormat('dd-MM-yyyy').format(_startDate!)
                              : '',
                        ),
                        hintText: 'Date',
                        height: __branchPriceListFieldHeight,
                        readOnly: true,
                        suffixWidget: _dateFieldSuffix('From'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 180,
                  height: __branchPriceListFieldHeight,
                  child: InkWell(
                    key: _endDateKey,
                    onTap: () async {
                      final picked = await ZerpaiDatePicker.show(
                        context,
                        initialDate: _endDate ?? _startDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime(2020),
                        lastDate: DateTime(2100),
                        targetKey: _endDateKey,
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked);
                      }
                    },
                    child: IgnorePointer(
                      child: CustomTextField(
                        controller: TextEditingController(
                          text: _endDate != null
                              ? DateFormat('dd-MM-yyyy').format(_endDate!)
                              : '',
                        ),
                        hintText: 'Date',
                        height: __branchPriceListFieldHeight,
                        readOnly: true,
                        suffixWidget: _dateFieldSuffix('To'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAssociatedBranchesRow() {
    final branchesAsync = ref.watch(_branchesProvider);
    final branches = branchesAsync.value ?? [];

    if (branches.isNotEmpty) {
      for (var i = 0; i < _associatedBranches.length; i++) {
        final val = _associatedBranches[i];
        if (val.contains('-')) {
          final matched = branches.firstWhere(
            (b) => b['entity_id']?.toString() == val,
            orElse: () => <String, dynamic>{},
          );
          if (matched.isNotEmpty) {
            final name = matched['name'] as String? ?? '';
            if (name.isNotEmpty) {
              _associatedBranches[i] = name;
            }
          }
        }
      }
    }

    // Group branches by branch_type
    final Map<String, List<String>> grouped = {};
    for (final b in branches) {
      final typeVal = b['branch_type']?.toString().trim();
      final type = (typeVal != null && typeVal.isNotEmpty) ? typeVal : 'Other';
      final name = b['name'] as String? ?? '';
      if (name.isNotEmpty) {
        grouped.putIfAbsent(type, () => []).add(name);
      }
    }

    // Build the dropdown options list
    final List<String> dropdownItems = [];
    final Map<String, List<String>> groupChildren = {};

    for (final entry in grouped.entries) {
      final type = entry.key;
      final children = entry.value;
      final headerKey = '__header_$type';
      
      dropdownItems.add(headerKey);
      dropdownItems.addAll(children);
      groupChildren[headerKey] = children;
    }

    bool isHeader(String item) => item.startsWith('__header_');
    String getDisplayLabel(String item) {
      if (isHeader(item)) {
        return item.replaceFirst('__header_', '');
      }
      return item;
    }

    return _FormRow(
      label: 'Associated Branches',
      required: true,
      child: SizedBox(
        width: __branchPriceListFieldWidth,
        child: FormDropdown<String>(
          value: null,
          items: dropdownItems,
          hint: 'Select branch',
          showSearch: false,
          showSearchIcon: false,
          multiSelect: true,
          selectedValues: _associatedBranches,
          onSelectedValuesChanged: (values) {
            final nextBranches = List<String>.from(_associatedBranches);
            
            // Check if any header was clicked/selected
            String? clickedHeader;
            for (final header in groupChildren.keys) {
              if (values.contains(header)) {
                clickedHeader = header;
                break;
              }
            }

            if (clickedHeader != null) {
              final children = groupChildren[clickedHeader] ?? [];
              final allSelected = children.every((child) => nextBranches.contains(child));
              
              setState(() {
                if (allSelected) {
                  nextBranches.removeWhere((item) => children.contains(item));
                } else {
                  for (final child in children) {
                    if (!nextBranches.contains(child)) {
                      nextBranches.add(child);
                    }
                  }
                }
                _associatedBranches
                  ..clear()
                  ..addAll(nextBranches);
              });
              return;
            }

            // Normal non-header item selection change
            setState(() {
              _associatedBranches
                ..clear()
                ..addAll(values.where((item) => !isHeader(item)));
            });
          },
          allowClear: _associatedBranches.isNotEmpty,
          height: __branchPriceListFieldHeight,
          menuWidth: __branchPriceListFieldWidth,
          menuMaxHeight: 240,
          itemHeight: 34,
          itemEstimatedHeight: 34,
          maxVisibleItems: 6,
          isItemEnabled: (item) => true,
          displayStringForValue: getDisplayLabel,
          searchStringForValue: getDisplayLabel,
          onChanged: (_) {},
          itemBuilder: (item, isSelected, isHovered) {
            final itemIsHeader = isHeader(item);
            
            Color textColor = itemIsHeader ? AppTheme.textPrimary : AppTheme.textSecondary;
            if (isHovered) {
              textColor = Colors.white;
            } else if (isSelected) {
              textColor = AppTheme.textPrimary;
            }

            return Container(
              height: 34,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(
                left: itemIsHeader ? 12 : 24,
                right: 12,
              ),
              child: Text(
                getDisplayLabel(item),
                style: TextStyle(
                  fontSize: itemIsHeader ? 13 : 12,
                  color: textColor,
                  fontWeight: itemIsHeader
                      ? FontWeight.w700
                      : (isSelected ? FontWeight.w500 : FontWeight.w400),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _dateFieldSuffix(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.calendar_today, size: 14),
      ],
    );
  }

  Widget _buildpriceListTypeRow() {
    final isEdit = widget.branchPriceList != null || widget.branchPriceListId != null;
    return _FormRow(
      label: 'Price List Type',
      child: IgnorePointer(
        ignoring: isEdit,
        child: Opacity(
          opacity: isEdit ? 0.7 : 1.0,
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _PriceListTypeCard(
                selected: _priceListType == 'all_items',
                title: 'All Items',
                subtitle: 'Mark up or mark down the rates of all items',
                onTap: () => setState(() {
                  _priceListType = 'all_items';
                  _isDiscountEnabled = false;
                }),
              ),
              _PriceListTypeCard(
                selected: _priceListType == 'individual_items',
                title: 'Individual Items',
                subtitle: 'Customize the rate of each item',
                onTap: () => setState(() => _priceListType = 'individual_items'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionRow() {
    return _FormRow(
      label: 'Description',
      child: SizedBox(
        width: __branchPriceListFieldWidth,
        child: CustomTextField(
          controller: _descriptionController,
          hintText: 'Enter the description',
          height: 58,
          maxLines: 2,
          contentCase: ContentCase.sentence,
        ),
      ),
    );
  }

  Widget _buildPercentageRow() {
    return _FormRow(
      label: 'Percentage',
      required: true,
      child: SizedBox(
        width: __branchPriceListFieldWidth,
        child: FormField<String>(
          validator: (_) {
            final trimmed = _percentageController.text.trim();
            final number = double.tryParse(trimmed);
            if (trimmed.isEmpty || number == null || number < 0) {
              return 'Required';
            }
            return null;
          },
          builder: (fieldState) {
            final hasError = fieldState.hasError;
            return Container(
              height: __branchPriceListFieldHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: hasError ? AppTheme.errorRedDark : AppTheme.borderColorDark,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: FormDropdown<String>(
                      value: _percentageType,
                      items: const ['Markup', 'Markdown'],
                      onChanged: (value) {
                        setState(() => _percentageType = value ?? 'Markup');
                      },
                      height: __branchPriceListFieldHeight,
                      showSearch: false,
                      showSearchIcon: false,
                      hideBorderDefault: true,
                      menuWidth: 124,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: __branchPriceListFieldHeight,
                    color: AppTheme.borderColorDark,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _percentageController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      onChanged: (val) {
                        fieldState.didChange(val);
                      },
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        errorStyle: TextStyle(height: 0, fontSize: 0),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: __branchPriceListFieldHeight,
                    color: AppTheme.borderColorDark,
                  ),
                  Container(
                    width: 42,
                    alignment: Alignment.center,
                    color: AppTheme.inputFill,
                    child: const Text(
                      '%',
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPricingSchemeRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: const Text(
                  'Pricing Scheme',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PricingSchemeCard(
                    selected: _pricingScheme == 'unit_pricing',
                    title: 'Unit Pricing',
                    width: _pricingSchemeUnitCardWidth,
                    onTap: () =>
                        setState(() => _pricingScheme = 'unit_pricing'),
                  ),
                  const SizedBox(width: _pricingSchemeCardGap),
                  _PricingSchemeCard(
                    selected: _pricingScheme == 'volume_pricing',
                    title: 'Volume Pricing',
                    onTap: () =>
                        setState(() => _pricingScheme = 'volume_pricing'),
                  ),
                  if (_pricingScheme == 'volume_pricing')
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: VolumePricingHelpButton(),
                    ),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: __branchPriceListLabelWidth),
            Flexible(
              fit: FlexFit.loose,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PricingSchemeCard(
                    selected: _pricingScheme == 'unit_pricing',
                    title: 'Unit Pricing',
                    width: _pricingSchemeUnitCardWidth,
                    onTap: () =>
                        setState(() => _pricingScheme = 'unit_pricing'),
                  ),
                  const SizedBox(width: _pricingSchemeCardGap),
                  _PricingSchemeCard(
                    selected: _pricingScheme == 'volume_pricing',
                    title: 'Volume Pricing',
                    onTap: () =>
                        setState(() => _pricingScheme = 'volume_pricing'),
                  ),
                  if (_pricingScheme == 'volume_pricing')
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: VolumePricingHelpButton(),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrencyRow() {
    return _FormRow(
      label: 'Currency',
      child: SizedBox(
        width: __branchPriceListFieldWidth,
        child: FormDropdown<CurrencyOption>(
          value: _currency,
          items: defaultCurrencyOptions,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _currency = value);
          },
          displayStringForValue: (value) => value.label,
          searchStringForValue: (value) => value.label,
          height: __branchPriceListFieldHeight,
          menuWidth: __branchPriceListFieldWidth,
        ),
      ),
    );
  }

  Widget _buildDiscountRow() {
    return _FormRow(
      label: 'Discount',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() => _isDiscountEnabled = !_isDiscountEnabled);
            },
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: _isDiscountEnabled,
                    onChanged: (value) {
                      setState(() => _isDiscountEnabled = value ?? false);
                    },
                    activeColor: AppTheme.primaryBlueDark,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(
                      color: AppTheme.borderMid,
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'I want to include discount percentage for the items',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ),
                if (_isDiscountEnabled) ...[
                  const SizedBox(width: 8),
                  const ZTooltip(
                    message:
                        'When a price list is applied, the discount percentage will be applied only if discount is enabled at the line-item level.',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkRatesSection() {
    final itemsState = ref.watch(itemsControllerProvider);
    final items = itemsState.items;
    if (itemsState.isLoading || itemsState.isLoadingList) {
      return _buildBulkRatesContent(
        items,
        _filterItems(items),
        isLoading: true,
      );
    }
    if (itemsState.error != null && items.isEmpty) {
      return _buildBulkRatesContent(
        const <Item>[],
        const <Item>[],
        errorMessage: 'Unable to load items for this price list.',
      );
    }
    final filteredItems = _filterItems(items);
    return _buildBulkRatesContent(items, filteredItems);
  }

  Widget _buildBulkRatesContent(
    List<Item> allItems,
    List<Item> visibleItems, {
    bool isLoading = false,
    String? errorMessage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBulkRatesToolbar(visibleItems),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final minWidth = _pricingScheme == 'volume_pricing'
                  ? _bulkRatesVolumeMinWidth
                  : _bulkRatesMinWidth;
              final tableWidth = constraints.maxWidth < minWidth
                  ? minWidth
                  : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: _buildRatesTable(
                    allItems,
                    visibleItems,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBulkRatesToolbar(List<Item> visibleItems) {
    if (_isBulkUpdateMode) {
      return _buildBulkUpdateModeToolbar(visibleItems);
    }

    final titleActions = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customise Rates in Bulk',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: visibleItems.isEmpty ? null : _openBulkUpdateMode,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryBlueDark,
            disabledForegroundColor: AppTheme.textDisabled,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(LucideIcons.settings, size: 16),
          label: const Text(
            'Update Rates in Bulk',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );

    final importToggle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Import Price List for Items',
          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        ),
        const SizedBox(width: 6),
        Transform.scale(
          scale: 0.72,
          child: Switch(
            value: _isImportBranchPriceListEnabled,
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.primaryBlueDark,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppTheme.borderMid,
            trackOutlineColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.primaryBlueDark;
              }
              return AppTheme.borderMid;
            }),
            onChanged: (value) {
              setState(() => _isImportBranchPriceListEnabled = value);
            },
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleActions, const SizedBox(height: 8), importToggle],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleActions),
            const SizedBox(width: 16),
            importToggle,
          ],
        );
      },
    );
  }

  Widget _buildBulkUpdateModeToolbar(List<Item> visibleItems) {
    return Container(
      width: double.infinity,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: visibleItems.isEmpty
                ? null
                : () => _showBulkUpdateDialog(visibleItems),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimary,
              disabledForegroundColor: AppTheme.textDisabled,
              side: const BorderSide(color: AppTheme.borderMid),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Update Rates in Bulk',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _closeBulkUpdateMode,
            icon: const Icon(LucideIcons.x, size: 22),
            color: AppTheme.primaryBlueDark,
          ),
        ],
      ),
    );
  }

  Future<void> _showBulkUpdateDialog(List<Item> visibleItems) async {
    final selectedEntries = _selectedVisibleBulkEntries(visibleItems);
    if (selectedEntries.isEmpty) {
      ZerpaiToast.error(context, 'Select at least one item to update in bulk');
      return;
    }

    final ranges = <_BulkUpdateRangeInput>[_BulkUpdateRangeInput()];
    var bulkRule = 'Markdown';
    var rateBasis = _baseRateRuleLabel;
    var updateUnit = '%';

    try {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                alignment: Alignment.topCenter,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                insetPadding: const EdgeInsets.fromLTRB(280, 0, 24, 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBulkUpdateDialogHeader(dialogContext),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBulkUpdateRuleRow(
                              bulkRule: bulkRule,
                              rateBasis: rateBasis,
                              isUnitPricing: _pricingScheme == 'unit_pricing',
                              range: ranges.first,
                              updateUnit: updateUnit,
                              onRuleChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => bulkRule = value);
                              },
                              onRateBasisChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => rateBasis = value);
                              },
                              onUpdateUnitChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => updateUnit = value);
                              },
                            ),
                            if (_isDiscountEnabled &&
                                _pricingScheme == 'unit_pricing') ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 120,
                                    child: Text(
                                      'Discount (%)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 180,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: CustomTextField(
                                            controller: ranges
                                                .first.discountController,
                                            height: 34,
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                              decimal: true,
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'[0-9.]'),
                                              ),
                                            ],
                                            contentCase: ContentCase.none,
                                            textAlign: TextAlign.right,
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                              left: Radius.circular(4),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 42,
                                          height: 34,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppTheme.inputFill,
                                            border: Border.all(
                                              color: AppTheme.borderColorDark,
                                            ),
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                              right: Radius.circular(4),
                                            ),
                                          ),
                                          child: const Text(
                                            '%',
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
                            ],
                            if (_pricingScheme == 'volume_pricing') ...[
                              const SizedBox(height: 16),
                              for (var index = 0; index < ranges.length; index++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: index == 0 ? 0 : 12,
                                  ),
                                  child: _buildBulkUpdateRangeRow(
                                    range: ranges[index],
                                    updateUnit: updateUnit,
                                    showDiscount: _isDiscountEnabled,
                                    onUpdateUnitChanged: (value) {
                                      if (value == null) return;
                                      setDialogState(() => updateUnit = value);
                                    },
                                    onRemove: ranges.length > 1
                                        ? () => setDialogState(
                                              () => ranges.removeAt(index),
                                            )
                                        : null,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              _buildBulkUpdateAddRangeAction(
                                onTap: () {
                                  setDialogState(
                                    () => ranges.add(_BulkUpdateRangeInput()),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Row(
                          children: [
                            ZButton.primary(
                              label: 'Update',
                              onPressed: () {
                                _applyBulkUpdateDialog(
                                  selectedEntries,
                                  ranges,
                                  bulkRule: bulkRule,
                                  updateUnit: updateUnit,
                                );
                                Navigator.pop(dialogContext);
                              },
                            ),
                            const SizedBox(width: 10),
                            ZButton.secondary(
                              label: 'Cancel',
                              onPressed: () => Navigator.pop(dialogContext),
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
    } finally {
      for (final range in ranges) {
        range.dispose();
      }
    }
  }

  Widget _buildBulkUpdateDialogHeader(BuildContext dialogContext) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 16, right: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFD),
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Update Rates in Bulk',
              style: TextStyle(
                fontSize: 16,
                height: 1,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.pop(dialogContext),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryBlueDark, width: 1.5),
              ),
              child: const Icon(
                LucideIcons.x,
                size: 18,
                color: AppTheme.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkUpdateRuleRow({
    required String bulkRule,
    required String rateBasis,
    required bool isUnitPricing,
    required _BulkUpdateRangeInput range,
    required String updateUnit,
    required ValueChanged<String?> onRuleChanged,
    required ValueChanged<String?> onRateBasisChanged,
    required ValueChanged<String?> onUpdateUnitChanged,
  }) {
    return Row(
      children: [
        const SizedBox(
          width: 120,
          child: Text(
            'Bulk Update Rule',
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
        ),
        SizedBox(
          width: 120,
          child: FormDropdown<String>(
            value: bulkRule,
            items: const ['Markdown', 'Markup'],
            onChanged: onRuleChanged,
            displayStringForValue: (value) => value,
            searchStringForValue: (value) => value,
            height: 34,
            menuWidth: 120,
            showSearch: false,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 140,
          child: FormDropdown<String>(
            value: rateBasis,
            items: [_baseRateRuleLabel],
            onChanged: onRateBasisChanged,
            displayStringForValue: (value) => value,
            searchStringForValue: (value) => value,
            height: 34,
            menuWidth: 140,
            showSearch: false,
          ),
        ),
        if (isUnitPricing) ...[
          const SizedBox(width: 16),
          const Text(
            'by',
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 180,
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: range.updateByController,
                    height: 34,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    contentCase: ContentCase.none,
                    textAlign: TextAlign.right,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                  ),
                ),
                SizedBox(
                  width: 58,
                  child: FormDropdown<String>(
                    value: updateUnit,
                    items: ['%', _currencySymbol],
                    onChanged: onUpdateUnitChanged,
                    displayStringForValue: (value) => value,
                    searchStringForValue: (value) => value,
                    height: 34,
                    menuWidth: 76,
                    showSearch: false,
                    textAlign: TextAlign.center,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBulkUpdateRangeRow({
    required _BulkUpdateRangeInput range,
    required String updateUnit,
    required bool showDiscount,
    required ValueChanged<String?> onUpdateUnitChanged,
    VoidCallback? onRemove,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _buildBulkUpdateDialogField(
            label: 'Start Quantity',
            controller: range.startQuantityController,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBulkUpdateDialogField(
            label: 'End Quantity',
            controller: range.endQuantityController,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBulkUpdateByDialogField(
            controller: range.updateByController,
            updateUnit: updateUnit,
            onUpdateUnitChanged: onUpdateUnitChanged,
          ),
        ),
        if (showDiscount) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _buildBulkUpdateDialogField(
              label: 'Discount (%)',
              controller: range.discountController,
            ),
          ),
        ],
        if (onRemove != null) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppTheme.errorRed,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBulkUpdateDialogField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: controller,
          height: 34,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          contentCase: ContentCase.none,
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildBulkUpdateByDialogField({
    required TextEditingController controller,
    required String updateUnit,
    required ValueChanged<String?> onUpdateUnitChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update By',
          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: controller,
                height: 34,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                contentCase: ContentCase.none,
                textAlign: TextAlign.right,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(4),
                ),
              ),
            ),
            SizedBox(
              width: 58,
              child: FormDropdown<String>(
                value: updateUnit,
                items: ['%', _currencySymbol],
                onChanged: onUpdateUnitChanged,
                displayStringForValue: (value) => value,
                searchStringForValue: (value) => value,
                height: 34,
                menuWidth: 76,
                showSearch: false,
                textAlign: TextAlign.center,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(4),
                ),
                showLeftBorder: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBulkUpdateAddRangeAction({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.plusCircle, size: 16, color: AppTheme.primaryBlue),
          SizedBox(width: 6),
          Text(
            'Add New Range',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.primaryBlueDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatesTable(
    List<Item> allItems,
    List<Item> visibleItems, {
    bool isLoading = false,
    String? errorMessage,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Column(
        children: [
          _buildRatesTableHeader(visibleItems),
          if (isLoading)
            _buildRatesTableMessage('Loading items...')
          else if (errorMessage != null)
            _buildRatesTableMessage(errorMessage)
          else if (allItems.isEmpty)
            _buildRatesTableMessage(
              'No items found. Create items first to add custom rates.',
            )
          else if (visibleItems.isEmpty)
            _buildRatesTableMessage('No items match your search.')
          else
            for (var index = 0; index < visibleItems.length; index++)
              _buildRatesTableRow(
                visibleItems[index],
                index,
                index == visibleItems.length - 1,
              ),
        ],
      ),
    );
  }

  Widget _buildRatesTableHeader(List<Item> visibleItems) {
    final headerHeight =
        _pricingScheme == 'volume_pricing' || _isDiscountEnabled ? 44.0 : 32.0;

    return SizedBox(
      height: headerHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isBulkUpdateMode) _buildBulkSelectionHeader(visibleItems),
          Expanded(flex: 5, child: _buildItemDetailsHeader()),
          _buildTableDivider(),
          Expanded(
            flex: 2,
            child: _buildHeaderCell(_baseRateHeader, alignEnd: true),
          ),
          _buildTableDivider(),
          if (_pricingScheme == 'volume_pricing') ...[
            Expanded(
              flex: 2,
              child: _buildHeaderCell('START\nQUANTITY', alignEnd: true),
            ),
            _buildTableDivider(),
            Expanded(
              flex: 2,
              child: _buildHeaderCell('END\nQUANTITY', alignEnd: true),
            ),
            _buildTableDivider(),
          ],
          Expanded(
            flex: 2,
            child: _buildHeaderCell('CUSTOM RATE', alignEnd: true),
          ),
          if (_isDiscountEnabled) ...[
            _buildTableDivider(),
            Expanded(flex: 2, child: _buildDiscountHeaderCell()),
          ],
          if (_pricingScheme == 'volume_pricing') ...[
            _buildTableDivider(),
            const SizedBox(width: _bulkRatesRemoveWidth),
          ],
        ],
      ),
    );
  }

  Widget _buildBulkSelectionHeader(List<Item> visibleItems) {
    final isAllSelected = _areAllVisibleBulkItemsSelected(visibleItems);
    final isPartiallySelected =
        _hasSelectedVisibleBulkItems(visibleItems) && !isAllSelected;

    return SizedBox(
      width: _bulkRatesSelectionWidth,
      child: Center(
        child: _buildBulkMarkCheckbox(
          value: isPartiallySelected ? null : isAllSelected,
          tristate: true,
          onChanged: visibleItems.isEmpty
              ? null
              : (_) => _setAllVisibleBulkItemsSelected(
                  visibleItems,
                  !isAllSelected,
                ),
        ),
      ),
    );
  }

  Widget _buildBulkSelectionCell(
    Item item,
    int index, {
    bool alignTop = false,
  }) {
    final itemId = _itemKey(item, index);

    return SizedBox(
      width: _bulkRatesSelectionWidth,
      child: Align(
        alignment: alignTop ? Alignment.topCenter : Alignment.center,
        child: Padding(
          padding: EdgeInsets.only(top: alignTop ? 5 : 0),
          child: _buildBulkMarkCheckbox(
            value: _selectedBulkItemKeys.contains(itemId),
            onChanged: (value) => _setBulkItemSelected(itemId, value ?? false),
          ),
        ),
      ),
    );
  }

  Widget _buildBulkMarkCheckbox({
    required bool? value,
    required ValueChanged<bool?>? onChanged,
    bool tristate = false,
  }) {
    return Transform.scale(
      scale: 0.82,
      child: Checkbox(
        value: value,
        tristate: tristate,
        onChanged: onChanged,
        activeColor: AppTheme.primaryBlueDark,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: AppTheme.borderMid, width: 1.4),
      ),
    );
  }

  Widget _buildItemDetailsHeader() {
    if (_isItemSearchVisible) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: SizedBox(
          height: 30,
          child: TextField(
            controller: _itemSearchController,
            autofocus: true,
            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search items...',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.primaryBlueDark),
              ),
              suffixIcon: IconButton(
                onPressed: _clearItemSearch,
                icon: const Icon(LucideIcons.x, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppTheme.textSecondary,
              ),
            ),
            onChanged: (value) => setState(() => _itemSearchQuery = value),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'ITEM DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 18,
              height: 18,
              child: IconButton(
                onPressed: () {
                  setState(() => _isItemSearchVisible = true);
                },
                icon: const Icon(LucideIcons.search, size: 15),
                color: AppTheme.primaryBlueDark,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 18,
                  height: 18,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool alignEnd = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountHeaderCell() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Text(
              'DISCOUNT  (%)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 3),
            Icon(Icons.info, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildRatesTableRow(Item item, int index, bool isLast) {
    if (_pricingScheme == 'volume_pricing') {
      return _buildVolumeRatesTableRow(item, index, isLast);
    }

    final itemId = _itemKey(item, index);
    final baseRate = _baseRateFor(item);

    return Container(
      height: _bulkRatesRowHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: const BorderSide(color: AppTheme.borderLight),
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isBulkUpdateMode) _buildBulkSelectionCell(item, index),
          Expanded(flex: 5, child: _buildItemNameCell(item)),
          _buildTableDivider(),
          Expanded(flex: 2, child: _buildBaseRateCell(baseRate)),
          _buildTableDivider(),
          Expanded(
            flex: 2,
            child: _buildBulkRateHoverCell(
              cellKey: _bulkRateCellKey(itemId, 'custom-rate'),
              child: _buildCustomRateCell(itemId),
            ),
          ),
          if (_isDiscountEnabled) ...[
            _buildTableDivider(),
            Expanded(
              flex: 2,
              child: _buildBulkRateHoverCell(
                cellKey: _bulkRateCellKey(itemId, 'discount'),
                child: _buildDiscountCell(itemId),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVolumeRatesTableRow(Item item, int index, bool isLast) {
    final itemId = _itemKey(item, index);
    final baseRate = _baseRateFor(item);
    final rangeCount = _volumeRangeCountFor(itemId);
    final rangeColumnsFlex = _isDiscountEnabled ? 8 : 6;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: const BorderSide(color: AppTheme.borderLight),
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isBulkUpdateMode)
              _buildBulkSelectionCell(item, index, alignTop: true),
            Expanded(flex: 5, child: _buildItemNameCell(item, alignTop: true)),
            _buildTableDivider(),
            Expanded(
              flex: 2,
              child: _buildBaseRateCell(baseRate, alignTop: true),
            ),
            _buildTableDivider(),
            Expanded(
              flex: rangeColumnsFlex,
              child: Column(
                children: [
                  for (
                    var rangeIndex = 0;
                    rangeIndex < rangeCount;
                    rangeIndex++
                  )
                    _buildVolumeRangeLine(itemId, rangeIndex),
                  _buildAddRangeLine(itemId),
                ],
              ),
            ),
            _buildTableDivider(),
            SizedBox(
              width: _bulkRatesRemoveWidth,
              child: Column(
                children: [
                  for (
                    var rangeIndex = 0;
                    rangeIndex < rangeCount;
                    rangeIndex++
                  )
                    _buildVolumeRangeCloseLine(
                      itemId,
                      rangeIndex,
                      showClose: rangeIndex > 0,
                    ),
                  const SizedBox(height: _bulkRatesAddRangeHeight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bulkRateCellKey(String itemId, String column, [int? rangeIndex]) {
    return rangeIndex == null
        ? '$itemId::$column'
        : '$itemId::$rangeIndex::$column';
  }

  bool _isHoveringVolumeRange(String itemId, int rangeIndex) {
    final hoveredKey = _hoveredBulkRateCellKey;
    return hoveredKey != null &&
        hoveredKey.startsWith(_bulkRateCellKey(itemId, '', rangeIndex));
  }

  void _setHoveredBulkRateCell(String? key) {
    if (_hoveredBulkRateCellKey == key) return;
    setState(() => _hoveredBulkRateCellKey = key);
  }

  void _setActiveBulkRateCell(String key) {
    if (_activeBulkRateCellKey == key) return;
    setState(() => _activeBulkRateCellKey = key);
  }

  Widget _buildBulkRateHoverCell({
    required String cellKey,
    required Widget child,
  }) {
    final isHovered = _hoveredBulkRateCellKey == cellKey;
    final isActive = _activeBulkRateCellKey == cellKey;
    final showOutline = isHovered || isActive;

    return MouseRegion(
      onEnter: (_) => _setHoveredBulkRateCell(cellKey),
      onExit: (_) {
        if (_hoveredBulkRateCellKey == cellKey) {
          _setHoveredBulkRateCell(null);
        }
      },
      child: Listener(
        onPointerDown: (_) => _setActiveBulkRateCell(cellKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: showOutline
                ? Border.all(color: AppTheme.primaryBlue, width: 1)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildVolumeRangeLine(String itemId, int rangeIndex) {
    return Container(
      height: _bulkRatesVolumeLineHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: _buildBulkRateHoverCell(
              cellKey: _bulkRateCellKey(itemId, 'start-quantity', rangeIndex),
              child: _buildPlainNumberCell(
                controller: _volumeStartControllerFor(itemId, rangeIndex),
              ),
            ),
          ),
          _buildTableDivider(),
          Expanded(
            flex: 2,
            child: _buildBulkRateHoverCell(
              cellKey: _bulkRateCellKey(itemId, 'end-quantity', rangeIndex),
              child: _buildPlainNumberCell(
                controller: _volumeEndControllerFor(itemId, rangeIndex),
              ),
            ),
          ),
          _buildTableDivider(),
          Expanded(
            flex: 2,
            child: _buildBulkRateHoverCell(
              cellKey: _bulkRateCellKey(itemId, 'custom-rate', rangeIndex),
              child: _buildCustomRateCell(
                _volumeRateKey(itemId, rangeIndex),
                controller: _volumeRateControllerFor(itemId, rangeIndex),
              ),
            ),
          ),
          if (_isDiscountEnabled) ...[
            _buildTableDivider(),
            Expanded(
              flex: 2,
              child: _buildBulkRateHoverCell(
                cellKey: _bulkRateCellKey(itemId, 'discount', rangeIndex),
                child: _buildDiscountCell(
                  _volumeDiscountKey(itemId, rangeIndex),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddRangeLine(String itemId) {
    return InkWell(
      onTap: () => _addVolumeRange(itemId),
      child: SizedBox(
        height: _bulkRatesAddRangeHeight,
        child: Row(
          children: const [
            SizedBox(width: 14),
            Icon(LucideIcons.plusCircle, size: 18, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text(
              'Add New Range',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeRangeCloseLine(
    String itemId,
    int rangeIndex, {
    required bool showClose,
  }) {
    final closeKey = _bulkRateCellKey(itemId, 'close', rangeIndex);
    final isCloseVisible =
        showClose && _isHoveringVolumeRange(itemId, rangeIndex);

    return MouseRegion(
      onEnter: (_) => _setHoveredBulkRateCell(closeKey),
      onExit: (_) {
        if (_hoveredBulkRateCellKey == closeKey) {
          _setHoveredBulkRateCell(null);
        }
      },
      child: Container(
        height: _bulkRatesVolumeLineHeight,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: IgnorePointer(
          ignoring: !isCloseVisible,
          child: AnimatedOpacity(
            opacity: isCloseVisible ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: IconButton(
              onPressed: showClose
                  ? () => _removeVolumeRange(itemId, rangeIndex)
                  : null,
              icon: const Icon(LucideIcons.x, size: 22),
              color: AppTheme.errorRed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemNameCell(Item item, {bool alignTop = false}) {
    final name = _itemName(item);
    final secondary = (item.sku?.trim().isNotEmpty ?? false)
        ? 'SKU: ${item.sku!.trim()}'
        : item.itemCode.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: alignTop
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (secondary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                secondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBaseRateCell(double rate, {bool alignTop = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, alignTop ? 8 : 0, 14, 0),
      child: Align(
        alignment: alignTop ? Alignment.topRight : Alignment.centerRight,
        child: Text(
          _formatCurrency(rate),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        ),
      ),
    );
  }

  Widget _buildPlainNumberCell({required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty || _parseDecimalInput(trimmed) != null) {
          return null;
        }
        return 'Invalid';
      },
      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
      decoration: const InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorStyle: TextStyle(height: 0, fontSize: 0),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
    );
  }

  Widget _buildCustomRateCell(
    String itemId, {
    TextEditingController? controller,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller ?? _customRateControllerFor(itemId),
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty || _parseDecimalInput(trimmed) != null) {
                return null;
              }
              return 'Invalid';
            },
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorStyle: TextStyle(height: 0, fontSize: 0),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
          ),
        ),
        Container(
          width: 38,
          height: double.infinity,
          alignment: Alignment.center,
          color: AppTheme.inputFill,
          child: Text(
            _currencySymbol,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountCell(String itemId) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _discountControllerFor(itemId),
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty || _parseDecimalInput(trimmed) != null) {
                return null;
              }
              return 'Invalid';
            },
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorStyle: TextStyle(height: 0, fontSize: 0),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
          ),
        ),
        Container(
          width: 32,
          height: double.infinity,
          alignment: Alignment.center,
          color: AppTheme.inputFill,
          child: const Text(
            '%',
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildRatesTableMessage(String message) {
    return Container(
      height: 64,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildTableDivider() {
    return Container(
      width: 1,
      height: double.infinity,
      color: AppTheme.borderLight,
    );
  }

  Widget _buildRoundOffRow() {
    return _FormRow(
      label: 'Round Off To',
      required: true,
      child: SizedBox(
        width: __branchPriceListFieldWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormDropdown<String>(
              value: _roundOffTo,
              items: const [
                'Never mind',
                'Nearest whole number',
                '0.99',
                '0.50',
                '0.25',
              ],
              onChanged: (value) {
                setState(() => _roundOffTo = value ?? 'Never mind');
              },
              height: __branchPriceListFieldHeight,
              showSearch: false,
              showSearchIcon: false,
              menuWidth: __branchPriceListFieldWidth,
            ),
            const SizedBox(height: 8),
            MenuAnchor(
              controller: _examplesMenuController,
              style: MenuStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white),
                surfaceTintColor: WidgetStateProperty.all(Colors.white),
                elevation: WidgetStateProperty.all(4),
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
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      'View Examples',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryBlueDark,
                      ),
                    ),
                  ),
                );
              },
              menuChildren: const [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 260,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ExampleLine(label: 'Never mind', value: '1000.678'),
                        _ExampleLine(label: '0.99', value: '1000.99'),
                        _ExampleLine(label: '0.50', value: '1000.50'),
                        _ExampleLine(label: 'Whole number', value: '1001'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          ZButton.primary(
            label: 'Save',
            loading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
          const SizedBox(width: 12),
          ZButton.secondary(
            label: 'Cancel',
            onPressed: _isSaving ? null : _cancel,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      ZerpaiToast.error(context, 'Enter the required price list details');
      return;
    }

    final actualBranches = _associatedBranches;
    if (actualBranches.isEmpty) {
      ZerpaiToast.error(context, 'Associated branch is required');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final details = _priceListType == 'all_items'
          ? '${_percentageController.text.trim()}% $_percentageType'
          : (_pricingScheme == 'unit_pricing'
                ? 'Fixed Rates'
                : 'Tiered Pricing');
      final itemRates = _priceListType == 'individual_items'
          ? _buildItemRates(
              ref.read(itemsControllerProvider).items,
            )
          : null;

      final isEdit = widget.branchPriceList != null || widget.branchPriceListId != null;
      final existingId = isEdit ? (widget.branchPriceList?.id ?? widget.branchPriceListId ?? '') : '';

      final branchPriceList = BranchPriceList(
        id: existingId,
        name: _nameController.text.trim(),
        description: _emptyToNull(_descriptionController.text),
        currency: _priceListType == 'individual_items'
            ? _currency.code
            : defaultCurrencyOptions.first.code,
        pricingScheme: _priceListType == 'individual_items'
            ? _pricingScheme
            : 'unit_pricing',
        priceListType: _priceListType,
        details: details,
        roundOffPreference: _priceListType == 'all_items' ? _roundOffTo : null,
        status: 'active',
        transactionType: _transactionType,
        isDiscountEnabled: _isDiscountEnabled,
        isSeasonalEnabled: _isSeasonalEnabled,
        startDate: _isSeasonalEnabled ? _startDate : null,
        endDate: _isSeasonalEnabled ? _endDate : null,
        itemRates: itemRates,
        associatedBranches: actualBranches.isEmpty ? null : List<String>.from(actualBranches),
        createdAt: isEdit ? (widget.branchPriceList?.createdAt ?? now) : now,
        updatedAt: now,
      );

      if (isEdit) {
        await ref
            .read(branchPriceListNotifierProvider.notifier)
            .updateBranchPriceList(branchPriceList);
      } else {
        await ref
            .read(branchPriceListNotifierProvider.notifier)
            .createBranchPriceList(branchPriceList);
      }

      if (!mounted) return;
      _finish(created: true);
    } catch (error) {
      if (mounted) {
        ZerpaiToast.error(context, 'Unable to save price list: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancel() => _finish();

  void _finish({bool created = false}) {
    if (context.canPop()) {
      context.pop(created ? true : null);
    } else {
      context.go(_listRoute);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<Item> _filterItems(List<Item> items) {
    final query = _itemSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((item) {
      final searchable = [
        item.productName,
        item.sku,
        item.itemCode,
      ].whereType<String>().join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  void _clearItemSearch() {
    setState(() {
      _isItemSearchVisible = false;
      _itemSearchQuery = '';
      _itemSearchController.clear();
    });
  }

  void _openBulkUpdateMode() {
    setState(() {
      _isBulkUpdateMode = true;
      _selectedBulkItemKeys.clear();
    });
  }

  void _closeBulkUpdateMode() {
    setState(() {
      _isBulkUpdateMode = false;
      _selectedBulkItemKeys.clear();
    });
  }

  void _setBulkItemSelected(String itemId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedBulkItemKeys.add(itemId);
      } else {
        _selectedBulkItemKeys.remove(itemId);
      }
    });
  }

  void _setAllVisibleBulkItemsSelected(
    List<Item> visibleItems,
    bool isSelected,
  ) {
    setState(() {
      for (var index = 0; index < visibleItems.length; index++) {
        final itemId = _itemKey(visibleItems[index], index);
        if (isSelected) {
          _selectedBulkItemKeys.add(itemId);
        } else {
          _selectedBulkItemKeys.remove(itemId);
        }
      }
    });
  }

  bool _areAllVisibleBulkItemsSelected(List<Item> visibleItems) {
    return visibleItems.isNotEmpty &&
        visibleItems.asMap().entries.every(
          (entry) =>
              _selectedBulkItemKeys.contains(_itemKey(entry.value, entry.key)),
        );
  }

  bool _hasSelectedVisibleBulkItems(List<Item> visibleItems) {
    return visibleItems.asMap().entries.any(
      (entry) =>
          _selectedBulkItemKeys.contains(_itemKey(entry.value, entry.key)),
    );
  }

  List<MapEntry<int, Item>> _selectedVisibleBulkEntries(
    List<Item> visibleItems,
  ) {
    return visibleItems.asMap().entries.where((entry) {
      return _selectedBulkItemKeys.contains(_itemKey(entry.value, entry.key));
    }).toList();
  }

  void _applyBulkUpdateDialog(
    List<MapEntry<int, Item>> selectedEntries,
    List<_BulkUpdateRangeInput> ranges, {
    required String bulkRule,
    required String updateUnit,
  }) {
    setState(() {
      for (final entry in selectedEntries) {
        final item = entry.value;
        final itemId = _itemKey(item, entry.key);
        final baseRate = _baseRateFor(item);

        if (_pricingScheme == 'volume_pricing') {
          _volumeRangeCounts[itemId] = ranges.length;
          for (var rangeIndex = 0; rangeIndex < ranges.length; rangeIndex++) {
            final range = ranges[rangeIndex];
            _volumeStartControllerFor(itemId, rangeIndex).text = range
                .startQuantityController
                .text
                .trim();
            _volumeEndControllerFor(itemId, rangeIndex).text = range
                .endQuantityController
                .text
                .trim();
            _volumeRateControllerFor(
              itemId,
              rangeIndex,
            ).text = _formatInputDecimal(
              _bulkUpdatedRate(
                baseRate,
                range.updateByController.text,
                bulkRule: bulkRule,
                updateUnit: updateUnit,
              ),
            );
            if (_isDiscountEnabled) {
              _discountControllerFor(
                _volumeDiscountKey(itemId, rangeIndex),
              ).text = range.discountController.text
                  .trim();
            }
          }
        } else {
          final range = ranges.first;
          _customRateControllerFor(itemId).text = _formatInputDecimal(
            _bulkUpdatedRate(
              baseRate,
              range.updateByController.text,
              bulkRule: bulkRule,
              updateUnit: updateUnit,
            ),
          );
          if (_isDiscountEnabled) {
            _discountControllerFor(itemId).text = range.discountController.text
                .trim();
          }
        }
      }
    });

    ZerpaiToast.success(context, 'Custom rates updated in bulk');
  }

  double _bulkUpdatedRate(
    double baseRate,
    String updateByText, {
    required String bulkRule,
    required String updateUnit,
  }) {
    final updateBy = _parseDecimalInput(updateByText.trim()) ?? 0;
    final change = updateUnit == '%' ? baseRate * updateBy / 100 : updateBy;
    final isMarkdown = bulkRule == 'Markdown';
    final updatedRate = isMarkdown ? baseRate - change : baseRate + change;
    return updatedRate < 0 ? 0 : updatedRate;
  }

  List<BranchPriceListItemRate> _buildItemRates(List<Item> items) {
    if (_pricingScheme == 'volume_pricing') {
      return _buildVolumeItemRates(items);
    }

    final rates = <BranchPriceListItemRate>[];
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final itemId = _itemKey(item, index);
      final customRateText = _customRateControllers[itemId]?.text.trim() ?? '';
      final customRate = _parseDecimalInput(customRateText);
      final discountText = _discountControllers[itemId]?.text.trim() ?? '';
      final discountPercentage = _parseDecimalInput(discountText);
      if (customRateText.isEmpty || customRate == null) continue;

      rates.add(
        BranchPriceListItemRate(
          itemId: itemId,
          itemName: _itemName(item),
          sku: item.sku,
          salesRate: _baseRateFor(item),
          customRate: customRate,
          discountPercentage: _isDiscountEnabled ? discountPercentage : null,
        ),
      );
    }
    return rates;
  }

  List<BranchPriceListItemRate> _buildVolumeItemRates(List<Item> items) {
    final rates = <BranchPriceListItemRate>[];
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final itemId = _itemKey(item, index);
      final ranges = <BranchPriceListVolumeRange>[];
      final rangeCount = _volumeRangeCounts[itemId] ?? 1;

      for (var rangeIndex = 0; rangeIndex < rangeCount; rangeIndex++) {
        final startText =
            _volumeStartControllers[_volumeRangeKey(itemId, rangeIndex)]?.text
                .trim() ??
            '';
        final endText =
            _volumeEndControllers[_volumeRangeKey(itemId, rangeIndex)]?.text
                .trim() ??
            '';
        final rateText =
            _volumeRateControllers[_volumeRangeKey(itemId, rangeIndex)]?.text
                .trim() ??
            '';
        final discountText =
            _discountControllers[_volumeDiscountKey(itemId, rangeIndex)]?.text
                .trim() ??
            '';
        final discountPercentage = _parseDecimalInput(discountText);
        final hasInput =
            startText.isNotEmpty || endText.isNotEmpty || rateText.isNotEmpty || discountText.isNotEmpty;
        if (!hasInput) continue;

        ranges.add(
          BranchPriceListVolumeRange(
            startQuantity: _parseDecimalInput(startText) ?? 0,
            endQuantity: _parseDecimalInput(endText),
            customRate: _parseDecimalInput(rateText) ?? 0,
            discountPercentage: _isDiscountEnabled ? discountPercentage : null,
          ),
        );
      }

      if (ranges.isEmpty) continue;
      rates.add(
        BranchPriceListItemRate(
          itemId: itemId,
          itemName: _itemName(item),
          sku: item.sku,
          salesRate: _baseRateFor(item),
          volumeRanges: ranges,
        ),
      );
    }
    return rates;
  }

  TextEditingController _customRateControllerFor(String itemId) {
    return _customRateControllers.putIfAbsent(
      itemId,
      TextEditingController.new,
    );
  }

  TextEditingController _volumeStartControllerFor(String itemId, int index) {
    return _volumeStartControllers.putIfAbsent(
      _volumeRangeKey(itemId, index),
      TextEditingController.new,
    );
  }

  TextEditingController _volumeEndControllerFor(String itemId, int index) {
    return _volumeEndControllers.putIfAbsent(
      _volumeRangeKey(itemId, index),
      TextEditingController.new,
    );
  }

  TextEditingController _volumeRateControllerFor(String itemId, int index) {
    return _volumeRateControllers.putIfAbsent(
      _volumeRangeKey(itemId, index),
      TextEditingController.new,
    );
  }

  TextEditingController _discountControllerFor(String itemId) {
    return _discountControllers.putIfAbsent(itemId, TextEditingController.new);
  }

  int _volumeRangeCountFor(String itemId) {
    return _volumeRangeCounts.putIfAbsent(itemId, () => 1);
  }

  void _addVolumeRange(String itemId) {
    setState(() {
      _volumeRangeCounts[itemId] = _volumeRangeCountFor(itemId) + 1;
    });
  }

  void _removeVolumeRange(String itemId, int index) {
    final count = _volumeRangeCountFor(itemId);
    if (count <= 1 || index <= 0 || index >= count) return;

    setState(() {
      for (var cursor = index; cursor < count - 1; cursor++) {
        _moveVolumeController(
          _volumeStartControllers,
          from: _volumeRangeKey(itemId, cursor + 1),
          to: _volumeRangeKey(itemId, cursor),
        );
        _moveVolumeController(
          _volumeEndControllers,
          from: _volumeRangeKey(itemId, cursor + 1),
          to: _volumeRangeKey(itemId, cursor),
        );
        _moveVolumeController(
          _volumeRateControllers,
          from: _volumeRangeKey(itemId, cursor + 1),
          to: _volumeRangeKey(itemId, cursor),
        );
      }

      _disposeVolumeRangeControllers(itemId, count - 1);
      _volumeRangeCounts[itemId] = count - 1;
    });
  }

  void _moveVolumeController(
    Map<String, TextEditingController> controllers, {
    required String from,
    required String to,
  }) {
    final replacement = controllers.remove(from);
    final existing = controllers.remove(to);
    existing?.dispose();
    if (replacement != null) {
      controllers[to] = replacement;
    }
  }

  void _disposeVolumeRangeControllers(String itemId, int index) {
    final key = _volumeRangeKey(itemId, index);
    _volumeStartControllers.remove(key)?.dispose();
    _volumeEndControllers.remove(key)?.dispose();
    _volumeRateControllers.remove(key)?.dispose();
  }

  String _volumeRangeKey(String itemId, int index) => '$itemId::$index';

  String _volumeRateKey(String itemId, int index) => '$itemId::rate::$index';

  String _volumeDiscountKey(String itemId, int index) =>
      '$itemId::discount::$index';

  String _itemKey(Item item, int index) {
    final key = item.id ?? item.sku ?? item.itemCode;
    final trimmed = key.trim();
    return trimmed.isEmpty ? 'item-$index' : trimmed;
  }

  String _itemName(Item item) {
    final name = item.productName;
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Unnamed item' : trimmed;
  }

  double _baseRateFor(Item item) {
    if (_transactionType == 'purchase') {
      return item.costPrice ?? 0;
    }
    return item.sellingPrice ?? 0;
  }

  String get _baseRateHeader =>
      _transactionType == 'purchase' ? 'PURCHASE RATE' : 'SALES RATE';

  String get _baseRateRuleLabel =>
      _transactionType == 'purchase' ? 'Purchase Rate' : 'Sales Rate';

  String get _currencySymbol {
    if (_currency.code == 'INR') return '\u20B9';
    if (_currency.code == 'USD') return r'$';
    final symbol = _currency.symbol.trim();
    return symbol.isEmpty || symbol == 'rs' ? _currency.code : symbol;
  }

  String _formatCurrency(double value) =>
      '$_currencySymbol${_formatDecimal(value)}';

  double? _parseDecimalInput(String value) {
    return double.tryParse(value.replaceAll(',', ''));
  }

  String _formatInputDecimal(double value) {
    return value.toStringAsFixed(_currency.decimals);
  }

  String _formatDecimal(double value) {
    return value
        .toStringAsFixed(_currency.decimals)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidget = Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Text(
            required ? '$label*' : label,
            style: TextStyle(
              fontSize: 14,
              color: required ? AppTheme.errorRedDark : AppTheme.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        );

        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelWidget, const SizedBox(height: 8), child],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: __branchPriceListLabelWidth, child: labelWidget),
            Flexible(fit: FlexFit.loose, child: child),
          ],
        );
      },
    );
  }
}

class _PriceListTypeCard extends StatelessWidget {
  const _PriceListTypeCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: _priceListTypeCardWidth,
        height: 74,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF8FAFF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.primaryBlueDark : AppTheme.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 20,
              color: selected
                  ? AppTheme.primaryBlueDark
                  : AppTheme.textDisabled,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
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

class _PricingSchemeCard extends StatelessWidget {
  const _PricingSchemeCard({
    required this.selected,
    required this.title,
    required this.onTap,
    this.width = _pricingSchemeCardWidth,
  });

  final bool selected;
  final String title;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: width,
        height: _pricingSchemeCardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _PricingSchemeIndicator(selected: selected),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingSchemeIndicator extends StatelessWidget {
  const _PricingSchemeIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFB8BDC5), width: 1.5),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFDCEBFF),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppTheme.primaryBlue,
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ExampleLine extends StatelessWidget {
  const _ExampleLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkUpdateRangeInput {
  final TextEditingController startQuantityController = TextEditingController();
  final TextEditingController endQuantityController = TextEditingController();
  final TextEditingController updateByController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  void dispose() {
    startQuantityController.dispose();
    endQuantityController.dispose();
    updateByController.dispose();
    discountController.dispose();
  }
}








