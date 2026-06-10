import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

class FormulationSection extends StatelessWidget {
  const FormulationSection({
    super.key,
    required this.dimXCtrl,
    required this.dimYCtrl,
    required this.dimZCtrl,
    required this.dimUnit,
    required this.onDimUnitChange,
    required this.weightCtrl,
    required this.weightUnit,
    required this.onWeightUnitChange,
    required this.manufacturer,
    required this.onManufacturerChange,
    required this.manufacturerOptions,
    this.onManageManufacturersTap,
    required this.brand,
    required this.onBrandChange,
    required this.brandOptions,
    this.onManageBrandsTap,
    required this.packSizeValue,
    required this.onPackSizeChanged,
    required this.packSizeOptions,
    this.onManagePackSizesTap,
    required this.lockUnitPackValue,
    required this.onLockUnitPackChanged,
    required this.lockUnitPackCtrl,
    required this.upcCtrl,
    required this.eanCtrl,
    required this.mpnCtrl,
    required this.isbnCtrl,
    required this.zerpaiField,
    required this.zerpaiTextField,
    required this.zerpaiDropdown,
    this.manufacturerError,
    this.brandError,
    this.onManufacturerSearch,
    this.onBrandSearch,
    this.lookupCache = const {},
  });

  final Map<String, String> lookupCache;

  final String? manufacturerError;
  final String? brandError;
  final Future<List<String>> Function(String query)? onManufacturerSearch;
  final Future<List<String>> Function(String query)? onBrandSearch;

  final TextEditingController dimXCtrl;
  final TextEditingController dimYCtrl;
  final TextEditingController dimZCtrl;
  final String dimUnit;
  final ValueChanged<String?> onDimUnitChange;

  final TextEditingController weightCtrl;
  final String weightUnit;
  final ValueChanged<String?> onWeightUnitChange;

  final String? manufacturer;
  final ValueChanged<String?> onManufacturerChange;
  final List<dynamic> manufacturerOptions;
  final VoidCallback? onManageManufacturersTap;

  final String? brand;
  final ValueChanged<String?> onBrandChange;
  final List<dynamic> brandOptions;
  final VoidCallback? onManageBrandsTap;

  final String? packSizeValue;
  final ValueChanged<String?> onPackSizeChanged;
  final List<String> packSizeOptions;
  final VoidCallback? onManagePackSizesTap;
  final String? lockUnitPackValue;
  final ValueChanged<String?> onLockUnitPackChanged;
  final TextEditingController lockUnitPackCtrl;

  final TextEditingController upcCtrl;
  final TextEditingController eanCtrl;
  final TextEditingController mpnCtrl;
  final TextEditingController isbnCtrl;

  final ZerpaiFieldBuilder zerpaiField;
  final ZerpaiTextFieldBuilder zerpaiTextField;
  final ZerpaiDropdownBuilder zerpaiDropdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Formulation Information',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),

        _twoFieldRow(
          _labeledField(
            label: 'Dimensions',
            subLabel: '(Length X Width X Height)',
            child: _dimensionsField(context),
          ),
          _labeledField(label: 'Weight', child: _weightField(context)),
        ),

        _twoFieldRow(
          _labeledField(
            label: 'Manufacturer/Patent',
            required: true,
            child: _manufacturerDropdown(),
          ),
          _labeledField(label: 'Brand/Division', child: _brandDropdown()),
        ),

        _twoFieldRow(
          _labeledField(
            label: 'UPC',
            tooltip:
                'Twelve digit unique number associated with the bar code (Universal Product Code)',
            child: zerpaiTextField(controller: upcCtrl, hint: 'Enter UPC'),
          ),
          _labeledField(
            label: 'MPN',
            tooltip:
                'Manufacturing Part Number uniquely identifies a part design',
            child: zerpaiTextField(controller: mpnCtrl, hint: 'Enter MPN'),
          ),
        ),

        _twoFieldRow(
          _labeledField(
            label: 'EAN',
            tooltip:
                'Thirteen digit unique number (International Article Number)',
            child: zerpaiTextField(controller: eanCtrl, hint: 'Enter EAN'),
          ),
          _labeledField(
            label: 'ISBN',
            tooltip:
                'International Standard Book Number used to identify books',
            child: zerpaiTextField(controller: isbnCtrl, hint: 'Enter ISBN'),
          ),
        ),

        _twoFieldRow(
          _labeledField(label: 'Pack Size', child: _packSizeDropdown()),
          _labeledField(
            label: 'Lock Unit Pack',
            tooltip:
                'Sets a fixed unit pack for purchase and opening stock, making those fields read-only in transactions. Example: If set to 10, purchases will be fixed at 10 units per pack and cannot be edited.',
            child: _lockUnitPackDropdown(),
          ),
        ),
      ],
    );
  }

  Widget _twoFieldRow(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [left, const SizedBox(width: 64), right],
      ),
    );
  }

  Widget _packSizeDropdown() {
    return _packStyleDropdown(
      value: packSizeValue,
      hint: 'Select or add pack size',
      onChanged: onPackSizeChanged,
    );
  }

  Widget _lockUnitPackDropdown() {
    return _packStyleDropdown(
      value: lockUnitPackValue,
      hint: 'Select or add lock unit pack',
      onChanged: onLockUnitPackChanged,
    );
  }

  Widget _packStyleDropdown({
    required String? value,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return FormDropdown<String>(
      value: value,
      items: packSizeOptions,
      hint: hint,
      onChanged: onChanged,
      boldSelected: false,
      showSettings: true,
      settingsLabel: 'Manage Pack Sizes',
      onSettingsTap: onManagePackSizesTap,
      displayStringForValue: (value) => value,
      searchStringForValue: (value) => value.toLowerCase(),
      itemBuilder: (value, isSelected, isHovered) {
        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: isHovered
                        ? Colors.white
                        : isSelected
                        ? AppTheme.primaryBlueDark
                        : AppTheme.textPrimary,
                    fontWeight: FontWeight.normal,
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

  Widget _labeledField({
    required String label,
    required Widget child,
    bool required = false,
    String? tooltip,
    String? subLabel,
  }) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: required
                                ? AppTheme.errorRed
                                : AppTheme.textSubtle,
                          ),
                        ),
                      ),
                      if (required)
                        const Text(
                          ' *',
                          style: TextStyle(
                            color: AppTheme.errorRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (tooltip != null) ...[
                        const SizedBox(width: 8),
                        ZTooltip(
                          message: tooltip,
                          child: const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subLabel != null)
                    Text(
                      subLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.2,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- DIMENSIONS ----------------

  Widget _dimensionsField(BuildContext context) {
    return Container(
      height: 32,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dimXCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        hintText: 'L',
                      ),
                    ),
                  ),
                  const Text(
                    '×',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  Expanded(
                    child: TextField(
                      controller: dimYCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        hintText: 'W',
                      ),
                    ),
                  ),
                  const Text(
                    '×',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  Expanded(
                    child: TextField(
                      controller: dimZCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        hintText: 'H',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 30,
            width: 70,
            decoration: const BoxDecoration(
              color: AppTheme.bgDisabled,
              border: Border(left: BorderSide(color: AppTheme.borderColor)),
            ),
            child: FormDropdown<String>(
              height: 30,
              fillColor: AppTheme.bgDisabled,
              border: Border.all(color: Colors.transparent),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              hideBorderDefault: true,
              showSearch: false,
              value: dimUnit,
              items: const ['cm', 'mm', 'm'],
              textAlign: TextAlign.center,
              maxVisibleItems: 3,
              displayStringForValue: (s) => s,
              searchStringForValue: (s) => s,
              onChanged: onDimUnitChange,
            ),
          ),
        ],
      ),
    );
  }



  // ---------------- WEIGHT ----------------

  Widget _weightField(BuildContext context) {
    return Container(
      height: 32,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: weightCtrl,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                hintText: 'Enter…',
              ),
            ),
          ),
          Container(
            height: 30,
            width: 60,
            decoration: const BoxDecoration(
              color: AppTheme.bgDisabled,
              border: Border(left: BorderSide(color: AppTheme.borderColor)),
            ),
            child: FormDropdown<String>(
              height: 30,
              fillColor: AppTheme.bgDisabled,
              border: Border.all(color: Colors.transparent),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              hideBorderDefault: true,
              showSearch: false,
              value: weightUnit,
              items: const ['kg', 'g', 'mg'],
              textAlign: TextAlign.center,
              maxVisibleItems: 3,
              displayStringForValue: (s) => s,
              searchStringForValue: (s) => s,
              onChanged: onWeightUnitChange,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- MANUFACTURER + BRAND ----------------

  Widget _manufacturerDropdown() => zerpaiDropdown<String>(
    value: manufacturer,
    items: manufacturerOptions.map((m) => m['id'] as String).toList(),
    hint: 'Select or Add Manufacturer/Patent',
    showSettings: true,
    settingsLabel: 'Manage Manufacturer/Patents',
    onSettingsTap: onManageManufacturersTap,
    onChanged: onManufacturerChange,
    errorText: manufacturerError,
    onSearch: onManufacturerSearch,
    displayStringForValue: (id) {
      if (lookupCache.containsKey(id)) {
        return lookupCache[id]!;
      }
      final m = manufacturerOptions.firstWhere(
        (man) => man['id'] == id,
        orElse: () => {'id': id, 'name': 'Unknown'},
      );
      return m['name'] ?? id;
    },
    itemBuilder: (id, isSelected, isHovered) {
      final m = manufacturerOptions.firstWhere(
        (man) => man['id'] == id,
        orElse: () => {'id': id, 'name': 'Unknown'},
      );
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                m['name'] ?? '',
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
                color: isHovered ? Colors.white : AppTheme.primaryBlueDark,
              ),
          ],
        ),
      );
    },
  );

  Widget _brandDropdown() => zerpaiDropdown<String>(
    value: brand,
    items: brandOptions.map((b) => b['id'] as String).toList(),
    hint: 'Select or Add Brand',
    showSettings: true,
    settingsLabel: 'Manage Brands',
    onSettingsTap: onManageBrandsTap,
    onChanged: onBrandChange,
    errorText: brandError,
    onSearch: onBrandSearch,
    displayStringForValue: (id) {
      if (lookupCache.containsKey(id)) {
        return lookupCache[id]!;
      }
      final b = brandOptions.firstWhere(
        (br) => br['id'] == id,
        orElse: () => {'id': id, 'name': 'Unknown'},
      );
      return b['name'] ?? id;
    },
    itemBuilder: (id, isSelected, isHovered) {
      final b = brandOptions.firstWhere(
        (br) => br['id'] == id,
        orElse: () => {'id': id, 'name': 'Unknown'},
      );
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                b['name'] ?? '',
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
                color: isHovered ? Colors.white : AppTheme.primaryBlueDark,
              ),
          ],
        ),
      );
    },
  );
}
