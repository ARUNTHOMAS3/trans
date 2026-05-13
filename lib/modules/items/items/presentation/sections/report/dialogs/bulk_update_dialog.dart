import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/modules/items/items/models/unit_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/category_dropdown.dart'
    show CategoryDropdown, CategoryNode;
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

Future<void> showBulkUpdateDialog(
  BuildContext context, {
  required Set<String> selectedIds,
}) {
  String? selectedField;
  String? selectedCategoryId;
  String hsnSacValue = '';
  String? intraTaxRateId;
  String? interTaxRateId;
  String? selectedUnitId;
  String? salesAccountId;
  String? purchaseAccountId;
  String? inventoryAccountId;
  String? buyingRuleId;
  String? scheduleDrugId;
  String? manufacturerId;
  String? brandId;
  String? vendorId;
  String? storageId;
  String? rackId;
  String? reorderTermId;
  String? inventoryValuationMethod;
  String sellingPriceValue = '';
  String salesDescriptionValue = '';
  String purchaseDescriptionValue = '';
  String reorderPointValue = '';
  bool returnable = false;
  bool ecommerce = false;
  bool lock = false;

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Bulk update',
    barrierColor: Colors.black.withAlpha((0.45 * 255).round()),
    transitionDuration: const Duration(milliseconds: 180),

    // --- MAIN BUILDER ---
    pageBuilder: (ctx, _, __) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter, // TRUE TOP ALIGN
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 32),
              width: 520,
              child: Consumer(
                builder: (context, ref, _) {
                  final itemsState = ref.watch(itemsControllerProvider);
                  final controller = ref.read(itemsControllerProvider.notifier);

                  String? lookupLabel(
                    List<Map<String, dynamic>> items,
                    String? id,
                  ) {
                    if (id == null || id.isEmpty) return null;
                    final match = items.firstWhere(
                      (row) => row['id']?.toString() == id,
                      orElse: () => <String, dynamic>{},
                    );
                    return (match['name'] ??
                            match['system_account_name'] ??
                            match['vendor_name'] ??
                            match['unit_name'] ??
                            '')
                        .toString();
                  }

                  String taxLabel(List<TaxRate> taxRates, String? id) {
                    if (id == null || id.isEmpty) return '';
                    try {
                      final tax = taxRates.firstWhere((t) => t.id == id);
                      return tax.taxName;
                    } catch (_) {
                      return '';
                    }
                  }

                  String unitLabel(List<Unit> units, String? id) {
                    if (id == null || id.isEmpty) return '';
                    try {
                      final unit = units.firstWhere((u) => u.id == id);
                      return unit.unitSymbol?.isNotEmpty == true
                          ? '${unit.unitName} (${unit.unitSymbol})'
                          : unit.unitName;
                    } catch (_) {
                      return '';
                    }
                  }

                  List<String> idsFromMap(List<Map<String, dynamic>> items) {
                    return items
                        .map((row) => row['id']?.toString() ?? '')
                        .where((id) => id.isNotEmpty)
                        .toList();
                  }

                  final accountIds = idsFromMap(itemsState.accounts);
                  final manufacturerIds = idsFromMap(itemsState.manufacturers);
                  final brandIds = idsFromMap(itemsState.brands);
                  final vendorIds = idsFromMap(itemsState.vendors);
                  final storageIds = idsFromMap(itemsState.storageLocations);
                  final rackIds = idsFromMap(itemsState.racks);
                  final reorderTermIds = idsFromMap(itemsState.reorderTerms);
                  final buyingRuleIds = idsFromMap(itemsState.buyingRules);
                  final scheduleIds = idsFromMap(itemsState.drugSchedules);
                  final unitIds = itemsState.units.map((u) => u.id).toList();
                  final taxRateIds = itemsState.taxRates
                      .map((t) => t.id)
                      .toList();

                  return StatefulBuilder(
                    builder: (context, setState) {
                      bool hasValue = true;
                      if (selectedField == 'Category') {
                        hasValue = selectedCategoryId?.isNotEmpty == true;
                      } else if (selectedField == 'HSN/SAC') {
                        hasValue = hsnSacValue.trim().isNotEmpty;
                      } else if (selectedField == 'Tax') {
                        hasValue =
                            intraTaxRateId?.isNotEmpty == true &&
                            interTaxRateId?.isNotEmpty == true;
                      } else if (selectedField == 'Unit') {
                        hasValue = selectedUnitId?.isNotEmpty == true;
                      } else if (selectedField == 'Sales Account') {
                        hasValue = salesAccountId?.isNotEmpty == true;
                      } else if (selectedField == 'Selling Price') {
                        hasValue = sellingPriceValue.trim().isNotEmpty;
                      } else if (selectedField == 'Buying Rules') {
                        hasValue = buyingRuleId?.isNotEmpty == true;
                      } else if (selectedField == 'Sales Description') {
                        hasValue = salesDescriptionValue.trim().isNotEmpty;
                      } else if (selectedField == 'Shedule Of Drug') {
                        hasValue = scheduleDrugId?.isNotEmpty == true;
                      } else if (selectedField == 'Manufacturer/Patent') {
                        hasValue = manufacturerId?.isNotEmpty == true;
                      } else if (selectedField == 'Brand') {
                        hasValue = brandId?.isNotEmpty == true;
                      } else if (selectedField == 'Purchase Account') {
                        hasValue = purchaseAccountId?.isNotEmpty == true;
                      } else if (selectedField == 'Preffered Vendor') {
                        hasValue = vendorId?.isNotEmpty == true;
                      } else if (selectedField == 'Purchase Description') {
                        hasValue = purchaseDescriptionValue.trim().isNotEmpty;
                      } else if (selectedField == 'Inventory Account') {
                        hasValue = inventoryAccountId?.isNotEmpty == true;
                      } else if (selectedField ==
                          'Inventory Valuation Method') {
                        hasValue = inventoryValuationMethod?.isNotEmpty == true;
                      } else if (selectedField == 'Storage') {
                        hasValue = storageId?.isNotEmpty == true;
                      } else if (selectedField == 'Rack') {
                        hasValue = rackId?.isNotEmpty == true;
                      } else if (selectedField == 'Reorder Point') {
                        hasValue = reorderPointValue.trim().isNotEmpty;
                      } else if (selectedField == 'Reorder Rule') {
                        hasValue = reorderTermId?.isNotEmpty == true;
                      }

                      final bool canSubmit = selectedField != null && hasValue;

                      Widget buildFormattedDropdown({
                        required String? value,
                        required String hint,
                        required List<String> items,
                        required ValueChanged<String?> onChanged,
                        required String Function(String id) labelFor,
                        bool allowClear = false,
                      }) {
                        return FormDropdown<String>(
                          value: value,
                          hint: hint,
                          items: items,
                          allowClear: allowClear,
                          onChanged: onChanged,
                          displayStringForValue: (id) {
                            final label = labelFor(id);
                            return label.isEmpty ? id : label;
                          },
                          searchStringForValue: (id) {
                            final label = labelFor(id);
                            return label.isEmpty ? id : label;
                          },
                          itemBuilder: (id, isSelected, isHovered) {
                            final label = labelFor(id);
                            return Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? AppTheme.primaryBlueDark
                                    : isSelected
                                    ? AppTheme.infoBg
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      label.isEmpty ? id : label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isHovered
                                            ? Colors.white
                                            : isSelected
                                            ? AppTheme.primaryBlueDark
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: isHovered
                                          ? Colors.white
                                          : AppTheme.primaryBlueDark,
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      }

                      Map<String, dynamic> buildChanges() {
                        switch (selectedField) {
                          case 'Category':
                            return {'category_id': selectedCategoryId};
                          case 'HSN/SAC':
                            return {'hsn_code': hsnSacValue.trim()};
                          case 'Tax':
                            return {
                              'intra_state_tax_id': intraTaxRateId,
                              'inter_state_tax_id': interTaxRateId,
                            };
                          case 'Unit':
                            return {'unit_id': selectedUnitId};
                          case 'Sales Account':
                            return {'sales_account_id': salesAccountId};
                          case 'Selling Price':
                            return {
                              'selling_price': double.tryParse(
                                sellingPriceValue.trim(),
                              ),
                            };
                          case 'Buying Rules':
                            return {'buying_rule_id': buyingRuleId};
                          case 'Sales Description':
                            return {
                              'sales_description': salesDescriptionValue.trim(),
                            };
                          case 'Shedule Of Drug':
                            return {'schedule_of_drug_id': scheduleDrugId};
                          case 'Manufacturer/Patent':
                            return {'manufacturer_id': manufacturerId};
                          case 'Brand':
                            return {'brand_id': brandId};
                          case 'Purchase Account':
                            return {'purchase_account_id': purchaseAccountId};
                          case 'Preffered Vendor':
                            return {'preferred_vendor_id': vendorId};
                          case 'Purchase Description':
                            return {
                              'purchase_description': purchaseDescriptionValue
                                  .trim(),
                            };
                          case 'Inventory Account':
                            return {'inventory_account_id': inventoryAccountId};
                          case 'Inventory Valuation Method':
                            return {
                              'inventory_valuation_method':
                                  inventoryValuationMethod,
                            };
                          case 'Storage':
                            return {'storage_id': storageId};
                          case 'Rack':
                            return {'rack_id': rackId};
                          case 'Reorder Point':
                            return {
                              'reorder_point':
                                  int.tryParse(reorderPointValue.trim()) ?? 0,
                            };
                          case 'Reorder Rule':
                            return {'reorder_term_id': reorderTermId};
                          case 'Returnable':
                            return {'is_returnable': returnable};
                          case 'Ecommerce':
                            return {'push_to_ecommerce': ecommerce};
                          case 'Lock':
                            return {'is_lock': lock};
                        }
                        return {};
                      }

                      Future<int> applyBulkUpdate() async {
                        final changes = buildChanges();
                        changes.removeWhere((key, value) => value == null);
                        if (changes.isEmpty) return 0;
                        return controller.updateItemsBulk(selectedIds, changes);
                      }

                      return Dialog(
                        alignment: Alignment.topCenter,
                        insetPadding: EdgeInsets.zero,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 600, // prevents overflow
                          ),

                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ---------------- HEADER ----------------
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Bulk Update Items',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),

                                    // STYLED CLOSE BUTTON
                                    InkWell(
                                      onTap: () => Navigator.pop(ctx),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppTheme.primaryBlueDark,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: AppTheme.primaryBlueDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ---------------- CONTENT ----------------
                              Flexible(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    18,
                                    20,
                                    12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Choose a field from the dropdown and update with new information.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSubtle,
                                        ),
                                      ),
                                      const SizedBox(height: 18),

                                      const Text(
                                        'Select a field*',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.errorRed,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      buildFormattedDropdown(
                                        value: selectedField,
                                        hint: 'Select a field',
                                        items: const [
                                          'Category',
                                          'HSN/SAC',
                                          'Tax',
                                          'Unit',
                                          'Sales Account',
                                          'Selling Price',
                                          'Buying Rules',
                                          'Sales Description',
                                          'Shedule Of Drug',
                                          'Manufacturer/Patent',
                                          'Brand',
                                          'Purchase Account',
                                          'Preffered Vendor',
                                          'Purchase Description',
                                          'Inventory Account',
                                          'Inventory Valuation Method',
                                          'Storage',
                                          'Rack',
                                          'Reorder Point',
                                          'Reorder Rule',
                                          'Returnable',
                                          'Ecommerce',
                                          'Lock',
                                        ],
                                        labelFor: (id) => id,
                                        onChanged: (value) => setState(
                                          () => selectedField = value,
                                        ),
                                      ),

                                      const SizedBox(height: 14),

                                      const Text.rich(
                                        TextSpan(
                                          text: 'Note: ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          children: [
                                            TextSpan(
                                              text:
                                                  'All the selected items will be updated with the new information and you cannot undo this action.',
                                              style: TextStyle(
                                                height: 1.5,
                                                fontWeight: FontWeight.w400,
                                                color: AppTheme.textSubtle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (selectedField == 'Category') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Select category*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRedDark,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        CategoryDropdown(
                                          nodes: CategoryNode.fromFlatList(
                                            itemsState.categories,
                                          ),
                                          value: selectedCategoryId,
                                          onChanged: (val) => setState(
                                            () => selectedCategoryId = val,
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'HSN/SAC') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'HSN or SAC*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          onChanged: (val) =>
                                              setState(() => hsnSacValue = val),
                                          decoration: InputDecoration(
                                            hintText: 'Enter HSN or SAC',
                                            hintStyle: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textMuted,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: AppTheme.primaryBlueDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ] else if (selectedField == 'Tax') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Intra State Tax Rate*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: intraTaxRateId,
                                          hint: 'Select tax rate',
                                          items: taxRateIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              taxLabel(itemsState.taxRates, id),
                                          onChanged: (val) => setState(
                                            () => intraTaxRateId = val,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Inter State Tax Rate*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: interTaxRateId,
                                          hint: 'Select tax rate',
                                          items: taxRateIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              taxLabel(itemsState.taxRates, id),
                                          onChanged: (val) => setState(
                                            () => interTaxRateId = val,
                                          ),
                                        ),
                                      ] else if (selectedField == 'Unit') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Unit*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: selectedUnitId,
                                          hint: 'Select Unit',
                                          items: unitIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              unitLabel(itemsState.units, id),
                                          onChanged: (val) => setState(
                                            () => selectedUnitId = val,
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'Sales Account') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Sales Account*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: salesAccountId,
                                          hint: 'Select Account',
                                          items: accountIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              lookupLabel(
                                                itemsState.accounts,
                                                id,
                                              ) ??
                                              id,
                                          onChanged: (val) => setState(
                                            () => salesAccountId = val,
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'Selling Price') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Selling Price*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) => setState(
                                            () => sellingPriceValue = val,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter Selling Price',
                                            hintStyle: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textMuted,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: AppTheme.primaryBlueDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'Buying Rules') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Buying Rules*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: buyingRuleId,
                                          hint: 'Select Buying Rule',
                                          items: buyingRuleIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              lookupLabel(
                                                itemsState.buyingRules,
                                                id,
                                              ) ??
                                              id,
                                          onChanged: (val) => setState(
                                            () => buyingRuleId = val,
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'Sales Description') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Sales Description*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          onChanged: (val) => setState(
                                            () => salesDescriptionValue = val,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter Sales Description',
                                            hintStyle: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textMuted,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: AppTheme.primaryBlueDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'Shedule Of Drug') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Schedule Of Drug*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: scheduleDrugId,
                                          hint: 'Select Schedule',
                                          items: scheduleIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              lookupLabel(
                                                itemsState.drugSchedules,
                                                id,
                                              ) ??
                                              id,
                                          onChanged: (val) => setState(
                                            () => scheduleDrugId = val,
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'Manufacturer/Patent') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Manufacturer/Patent*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: manufacturerId,
                                          hint: 'Select Manufacturer/Patent',
                                          items: manufacturerIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              lookupLabel(
                                                itemsState.manufacturers,
                                                id,
                                              ) ??
                                              id,
                                          onChanged: (val) => setState(
                                            () => manufacturerId = val,
                                          ),
                                        ),
                                      ] else if (selectedField == 'Brand') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Brand*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: brandId,
                                          hint: 'Select Brand',
                                          items: brandIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              lookupLabel(
                                                itemsState.brands,
                                                id,
                                              ) ??
                                              id,
                                          onChanged: (val) =>
                                              setState(() => brandId = val),
                                        ),
                                      ] else if (selectedField ==
                                          'Purchase Account') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Purchase Account*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: purchaseAccountId,
                                          hint: 'Select Purchase Account',
                                          items: accountIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              lookupLabel(
                                                itemsState.accounts,
                                                id,
                                              ) ??
                                              id,
                                          onChanged: (val) => setState(
                                            () => purchaseAccountId = val,
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'Preffered Vendor') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Preffered Vendor*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: vendorId,
                                          hint: 'Select Preffered Vendor',
                                          items: vendorIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              lookupLabel(
                                                itemsState.vendors,
                                                id,
                                              ) ??
                                              id,
                                          onChanged: (val) =>
                                              setState(() => vendorId = val),
                                        ),
                                      ] else if (selectedField ==
                                          'Purchase Description') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Purchase Description*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          onChanged: (val) => setState(
                                            () =>
                                                purchaseDescriptionValue = val,
                                          ),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Enter Purchase Description',
                                            hintStyle: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textMuted,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: AppTheme.primaryBlueDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'Inventory Account') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Inventory Account*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: inventoryAccountId,
                                          hint: 'Select Inventory Account',
                                          items: accountIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              lookupLabel(
                                                itemsState.accounts,
                                                id,
                                              ) ??
                                              id,
                                          onChanged: (val) => setState(
                                            () => inventoryAccountId = val,
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'Inventory Valuation Method') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Inventory Valuation Method*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: inventoryValuationMethod,
                                          hint: 'Select Valuation Method',
                                          items: [
                                            'FIFO',
                                            'LIFO',
                                            'Weighted Average',
                                          ],
                                          allowClear: false,
                                          labelFor: (id) => id,
                                          onChanged: (val) => setState(
                                            () =>
                                                inventoryValuationMethod = val,
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'Storage') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Storage*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: storageId,
                                          hint: 'Select Storage',
                                          items: storageIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              lookupLabel(
                                                itemsState.storageLocations,
                                                id,
                                              ) ??
                                              id,
                                          onChanged: (val) =>
                                              setState(() => storageId = val),
                                        ),
                                      ] else if (selectedField == 'Rack') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Rack*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: rackId,
                                          hint: 'Select Rack',
                                          items: rackIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              lookupLabel(
                                                itemsState.racks,
                                                id,
                                              ) ??
                                              id,
                                          onChanged: (val) =>
                                              setState(() => rackId = val),
                                        ),
                                      ] else if (selectedField ==
                                          'Reorder Point') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Reorder Point*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) => setState(
                                            () => reorderPointValue = val,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter Reorder Point',
                                            hintStyle: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textMuted,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: AppTheme.primaryBlueDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'Reorder Rule') ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Reorder Rule*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRedDark,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        buildFormattedDropdown(
                                          value: reorderTermId,
                                          hint: 'Select reorder rule',
                                          items: reorderTermIds,
                                          allowClear: false,
                                          labelFor: (id) =>
                                              lookupLabel(
                                                itemsState.reorderTerms,
                                                id,
                                              ) ??
                                              id,
                                          onChanged: (val) => setState(
                                            () => reorderTermId = val,
                                          ),
                                        ),
                                      ] else if (selectedField ==
                                          'Returnable') ...[
                                        const SizedBox(height: 18),
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: returnable,
                                              onChanged: (val) => setState(
                                                () => returnable = val ?? false,
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            const Text(
                                              'Returnable',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textBody,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else if (selectedField ==
                                          'Ecommerce') ...[
                                        const SizedBox(height: 18),
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: ecommerce,
                                              onChanged: (val) => setState(
                                                () => ecommerce = val ?? false,
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            const Text(
                                              'Ecommerce',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textBody,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else if (selectedField == 'Lock') ...[
                                        const SizedBox(height: 18),
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: lock,
                                              onChanged: (val) => setState(
                                                () => lock = val ?? false,
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            const Text(
                                              'Lock',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textBody,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              const Divider(
                                height: 1,
                                color: AppTheme.borderColor,
                              ),

                              // ---------------- ACTION BUTTONS ----------------
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  14,
                                  20,
                                  16,
                                ),
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: canSubmit
                                          ? () async {
                                              if (selectedIds.isEmpty) {
                                                if (!context.mounted) return;
                                                ZerpaiToast.info(context, 'No items selected');
                                                return;
                                              }
                                              final updated =
                                                  await applyBulkUpdate();
                                              if (!context.mounted) return;
                                              ZerpaiToast.success(context, '$updated item(s) updated successfully');
                                              Navigator.pop(ctx);
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Update',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    OutlinedButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: AppTheme.borderColor,
                                        ),
                                        foregroundColor: AppTheme.textBody,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(fontSize: 13),
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
              ),
            ),
          ),
        ),
      );
    },

    // ---------------- ANIMATION ----------------
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: Offset(0, -0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
