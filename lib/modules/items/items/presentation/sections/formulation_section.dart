import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

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
            color: Color(0xFF111827),
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
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                      if (required)
                        const Text(
                          ' *',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
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
                            color: Color(0xFF9CA3AF),
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
                        color: Color(0xFF6B7280),
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
    return Row(
      children: [
        Expanded(child: _dimInput(dimXCtrl, 'L')),
        const SizedBox(width: 8),
        Expanded(child: _dimInput(dimYCtrl, 'W')),
        const SizedBox(width: 8),
        Expanded(child: _dimInput(dimZCtrl, 'H')),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: zerpaiDropdown<String>(
            value: dimUnit,
            items: const ['cm', 'mm', 'm'],
            onChanged: onDimUnitChange,
            showSearch: false,
            itemBuilder: (id, isSelected, isHovered) {
              return Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: isHovered
                      ? const Color(0xFF2563EB)
                      : isSelected
                      ? const Color(0xFFEFF6FF)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        id,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHovered
                              ? Colors.white
                              : isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: isHovered
                            ? Colors.white
                            : const Color(0xFF2563EB),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _dimInput(TextEditingController ctrl, String hint) {
    return zerpaiTextField(
      controller: ctrl,
      hint: hint,
      keyboardType: TextInputType.number,
      height: 44,
    );
  }

  // ---------------- WEIGHT ----------------

  Widget _weightField(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: zerpaiTextField(
            controller: weightCtrl,
            hint: 'Enter…',
            keyboardType: TextInputType.number,
            height: 44,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: zerpaiDropdown<String>(
            value: weightUnit,
            items: const ['kg', 'g', 'mg'],
            onChanged: onWeightUnitChange,
            showSearch: false,
            itemBuilder: (id, isSelected, isHovered) {
              return Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: isHovered
                      ? const Color(0xFF2563EB)
                      : isSelected
                      ? const Color(0xFFEFF6FF)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        id,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHovered
                              ? Colors.white
                              : isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: isHovered
                            ? Colors.white
                            : const Color(0xFF2563EB),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
              ? const Color(0xFF2563EB)
              : isSelected
              ? const Color(0xFFEFF6FF)
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
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF111827),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: isHovered ? Colors.white : const Color(0xFF2563EB),
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
              ? const Color(0xFF2563EB)
              : isSelected
              ? const Color(0xFFEFF6FF)
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
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF111827),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: isHovered ? Colors.white : const Color(0xFF2563EB),
              ),
          ],
        ),
      );
    },
  );
}
