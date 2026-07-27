import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/theme/app_text_styles.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_page_header.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

class UnitOfMeasurement {
  final String? id;
  final String name;
  final String symbol;
  final String uqc;
  final String? uqcId;
  final String precision;

  const UnitOfMeasurement({
    this.id,
    required this.name,
    required this.symbol,
    required this.uqc,
    this.uqcId,
    this.precision = '',
  });
}

class UnitConversion {
  final UnitOfMeasurement targetUnit;
  final double rate;

  const UnitConversion({required this.targetUnit, required this.rate});
}

class UnitGroup {
  final String? id;
  final String name;
  final UnitOfMeasurement baseUnit;
  final List<UnitConversion> conversions;

  const UnitGroup({
    this.id,
    required this.name,
    required this.baseUnit,
    required this.conversions,
  });
}

class SettingsUnitsOfMeasurementPage extends ConsumerStatefulWidget {
  const SettingsUnitsOfMeasurementPage({super.key});

  @override
  ConsumerState<SettingsUnitsOfMeasurementPage> createState() =>
      _SettingsUnitsOfMeasurementPageState();
}

class _SettingsUnitsOfMeasurementPageState
    extends ConsumerState<SettingsUnitsOfMeasurementPage> {
  final ApiClient _apiClient = ApiClient();
  final List<UnitOfMeasurement> _units = [];

  final List<UnitGroup> _unitGroups = [];

  final List<String> _uqcOptions = [];
  final Map<String, String> _uqcIdByOption = {};

  int? _hoveredIndex;
  int? _hoveredEditIndex;
  int? _activeDropdownIndex;
  bool _isLoading = true;
  bool _unitConversionEnabled = false;
  String _activeTab = 'Units';

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiClient.get('products/lookups/uqc', useCache: false),
        _apiClient.get('products/lookups/units', useCache: false),
        _apiClient.get('settings-setup/unit-groups', useCache: false),
      ]);
      final uqcs = results[0].data is List ? results[0].data as List : const [];
      final units = results[1].data is List
          ? results[1].data as List
          : const [];
      final groups = results[2].data is List
          ? results[2].data as List
          : const [];
      final uqcLabelById = <String, String>{};
      final nextUqcOptions = <String>[];
      final nextUqcIds = <String, String>{};

      for (final row in uqcs.whereType<Map>()) {
        final json = Map<String, dynamic>.from(row);
        final id = json['id']?.toString();
        final code = json['uqc_code']?.toString() ?? '';
        final description = json['description']?.toString() ?? '';
        if (id == null || code.isEmpty) continue;
        final label = description.isEmpty ? code : '$code ($description)';
        uqcLabelById[id] = label;
        nextUqcOptions.add(label);
        nextUqcIds[label] = id;
      }

      final nextUnits = units.whereType<Map>().map((row) {
        final json = Map<String, dynamic>.from(row);
        final uqcId = json['uqc_id']?.toString();
        return UnitOfMeasurement(
          id: json['id']?.toString(),
          name: json['unit_name']?.toString() ?? '',
          symbol: json['unit_symbol']?.toString() ?? '',
          uqc: uqcId == null ? '' : (uqcLabelById[uqcId] ?? ''),
          uqcId: uqcId,
        );
      }).toList();
      final unitsById = <String, UnitOfMeasurement>{
        for (final unit in nextUnits)
          if (unit.id != null) unit.id!: unit,
      };
      final nextGroups = <UnitGroup>[];
      for (final row in groups.whereType<Map>()) {
        final json = Map<String, dynamic>.from(row);
        final baseUnit = unitsById[json['base_unit_id']?.toString()];
        if (baseUnit == null) continue;
        final conversions = json['conversions'] is List
            ? json['conversions'] as List
            : const [];
        nextGroups.add(
          UnitGroup(
            id: json['id']?.toString(),
            name: json['name']?.toString() ?? '',
            baseUnit: baseUnit,
            conversions: conversions
                .whereType<Map>()
                .map((row) {
                  final conversion = Map<String, dynamic>.from(row);
                  final target =
                      unitsById[conversion['target_unit_id']?.toString()];
                  return target == null
                      ? null
                      : UnitConversion(
                          targetUnit: target,
                          rate:
                              double.tryParse(
                                conversion['conversion_rate']?.toString() ?? '',
                              ) ??
                              0,
                        );
                })
                .whereType<UnitConversion>()
                .toList(),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _uqcOptions
          ..clear()
          ..addAll(nextUqcOptions);
        _uqcIdByOption
          ..clear()
          ..addAll(nextUqcIds);
        _units
          ..clear()
          ..addAll(nextUnits);
        _unitGroups
          ..clear()
          ..addAll(nextGroups);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ZerpaiToast.error(context, 'Failed to load units');
    }
  }

  Future<void> _saveUnit({
    String? id,
    required String name,
    required String symbol,
    required String? uqcOption,
  }) async {
    await _apiClient.post(
      'products/lookups/units/sync',
      data: [
        {
          if (id != null && id.isNotEmpty) 'id': id,
          'unit_name': name,
          'unit_symbol': symbol,
          'uqc_id': uqcOption == null ? null : _uqcIdByOption[uqcOption],
          'is_active': true,
        },
      ],
    );
    await _loadUnits();
  }

  Future<void> _deleteUnit(int index) async {
    if (index < 0 || index >= _units.length) return;
    final unit = _units[index];
    await _apiClient.post(
      'products/lookups/units/sync',
      data: [
        {
          'id': unit.id,
          'unit_name': unit.name,
          'unit_symbol': unit.symbol,
          'uqc_id': unit.uqcId,
          'is_active': false,
        },
      ],
    );
    await _loadUnits();
  }

  Future<void> _saveUnitGroup({
    String? id,
    required String name,
    required UnitOfMeasurement baseUnit,
    required List<UnitConversion> conversions,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'base_unit_id': baseUnit.id,
      'is_active': true,
      'conversions': conversions
          .map(
            (conversion) => <String, dynamic>{
              'target_unit_id': conversion.targetUnit.id,
              'conversion_rate': conversion.rate,
            },
          )
          .toList(),
    };
    if (id == null || id.isEmpty) {
      await _apiClient.post('settings-setup/unit-groups', data: payload);
    } else {
      await _apiClient.patch('settings-setup/unit-groups/$id', data: payload);
    }
    await _loadUnits();
  }

  Future<void> _deleteUnitGroup(UnitGroup group) async {
    if (group.id == null || group.id!.isEmpty) return;
    await _apiClient.delete('settings-setup/unit-groups/${group.id}');
    await _loadUnits();
  }

  void _showEditUnitDialog(int index) {
    final unit = _units[index];
    final nameController = TextEditingController(text: unit.name);
    final symbolController = TextEditingController(text: unit.symbol);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final List<String> dialogErrors = [];
        bool nameHasError = false;
        bool symbolHasError = false;
        bool precisionHasError = false;
        String? selectedUqc = _uqcOptions.firstWhere(
          (opt) => opt.startsWith(unit.uqc),
          orElse: () => '',
        );
        if (selectedUqc.isEmpty) selectedUqc = null;

        String? selectedPrecision = unit.precision.isEmpty
            ? null
            : unit.precision;
        final int initialPrecision = int.tryParse(unit.precision) ?? 0;
        final precisionOptions = [
          '0',
          '1',
          '2',
          '3',
          '4',
          '5',
          '6',
        ].where((val) => (int.tryParse(val) ?? 0) >= initialPrecision).toList();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.only(
                top: 0,
                left: 40,
                right: 40,
                bottom: 40,
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Edit Unit',
                              style: AppTextStyles.title.copyWith(fontSize: 18),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 20),
                              onPressed: () => Navigator.pop(context),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      // Body Container
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildErrorBanner(
                              dialogErrors,
                              () => setStateDialog(() => dialogErrors.clear()),
                            ),
                            // Row 1: Name
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 150,
                                  child: Text(
                                    'Name*',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                Focus(
                                  onFocusChange: (hasFocus) {
                                    setStateDialog(() {});
                                  },
                                  child: Builder(
                                    builder: (context) {
                                      final hasFocus = Focus.of(
                                        context,
                                      ).hasFocus;
                                      return Container(
                                        height: 34,
                                        width: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: nameHasError
                                                ? AppTheme.errorRed
                                                : (hasFocus
                                                      ? const Color(0xFF1E61D5)
                                                      : AppTheme.borderLight),
                                            width: (hasFocus || nameHasError)
                                                ? 1.5
                                                : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: nameController,
                                          style: AppTextStyles.input,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            hintText: 'Enter Unit Name',
                                            hintStyle: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                            errorStyle: TextStyle(
                                              height: 0,
                                              fontSize: 0,
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? ''
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Row 2: Symbol
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 150,
                                  child: Text(
                                    'Symbol*',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                Focus(
                                  onFocusChange: (hasFocus) {
                                    setStateDialog(() {});
                                  },
                                  child: Builder(
                                    builder: (context) {
                                      final hasFocus = Focus.of(
                                        context,
                                      ).hasFocus;
                                      return Container(
                                        height: 34,
                                        width: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: symbolHasError
                                                ? AppTheme.errorRed
                                                : (hasFocus
                                                      ? const Color(0xFF1E61D5)
                                                      : AppTheme.borderLight),
                                            width: (hasFocus || symbolHasError)
                                                ? 1.5
                                                : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: symbolController,
                                          style: AppTextStyles.input,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            hintText: 'Enter Symbol',
                                            hintStyle: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                            errorStyle: TextStyle(
                                              height: 0,
                                              fontSize: 0,
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? ''
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Row 3: UQC
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 150,
                                  child: Text(
                                    'Unique Quantity Code (UQC)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 200,
                                  height: 34,
                                  child: FormDropdown<String>(
                                    value: selectedUqc,
                                    items: _uqcOptions,
                                    hint: 'Select UQC',
                                    allowClear: true,
                                    showSearch: true,
                                    height: 34,
                                    boldSelected: false,
                                    textStyle: AppTextStyles.input.copyWith(
                                      color: selectedUqc == null
                                          ? Colors.grey
                                          : AppTheme.textPrimary,
                                    ),
                                    displayStringForValue: (val) => val,
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        selectedUqc = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (_unitConversionEnabled) ...[
                              const SizedBox(height: 16),
                              // Row 4: Precision
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 150,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Unit Precision*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        ZTooltip(
                                          message:
                                              "If this unit is used for an item in a transaction, it's quantity will be rounded off to the selected unit precision.",
                                          child: const Icon(
                                            LucideIcons.helpCircle,
                                            size: 14,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 200,
                                    height: 34,
                                    child: FormDropdown<String>(
                                      value: selectedPrecision,
                                      items: precisionOptions,
                                      hint: 'Select Precision',
                                      allowClear: true,
                                      showSearch: false,
                                      height: 34,
                                      boldSelected: false,
                                      errorText: precisionHasError ? '' : null,
                                      textStyle: AppTextStyles.input.copyWith(
                                        color: selectedPrecision == null
                                            ? Colors.grey
                                            : AppTheme.textPrimary,
                                      ),
                                      displayStringForValue: (val) => val,
                                      itemBuilder:
                                          (value, isSelected, isHovered) {
                                            final labelColor = isHovered
                                                ? Colors.white
                                                : (isSelected
                                                      ? const Color(0xFF1E61D5)
                                                      : AppTheme.textPrimary);
                                            final checkColor = isHovered
                                                ? Colors.white
                                                : const Color(0xFF3B82F6);
                                            return Container(
                                              height: 38,
                                              alignment: Alignment.centerLeft,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      value,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: labelColor,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w500
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isSelected) ...[
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      Icons.check,
                                                      size: 16,
                                                      color: checkColor,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          },
                                      onChanged: (val) {
                                        setStateDialog(() {
                                          selectedPrecision = val;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Note : Once you\'ve selected a unit precision, you will only be able to increase the value the next time you edit it.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 16),
                            // Warning Banner Container
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                border: Border.all(
                                  color: const Color(0xFFFFEDD5),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    LucideIcons.alertTriangle,
                                    color: Color(0xFFF97316),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "As per e-Invoice System's API standards, UQC is required for all units. If you don't enter an UQC, we will use 'OTH (Others)' as the UQC while e-invoicing transactions.",
                                      style: AppTextStyles.helper.copyWith(
                                        color: const Color(0xFF374151),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      // Footer Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                dialogErrors.clear();
                                nameHasError = false;
                                symbolHasError = false;
                                precisionHasError = false;

                                if (nameController.text.trim().isEmpty) {
                                  dialogErrors.add('Unit Name is required.');
                                }
                                if (symbolController.text.trim().isEmpty) {
                                  dialogErrors.add('Symbol is required.');
                                }
                                if (_unitConversionEnabled &&
                                    selectedPrecision == null) {
                                  precisionHasError = true;
                                  dialogErrors.add(
                                    'Unit Precision is required.',
                                  );
                                }

                                if (dialogErrors.isNotEmpty) {
                                  setStateDialog(() {});
                                  formKey.currentState!.validate();
                                  return;
                                }

                                try {
                                  await _saveUnit(
                                    id: unit.id,
                                    name: nameController.text.trim(),
                                    symbol: symbolController.text.trim(),
                                    uqcOption: selectedUqc,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ZerpaiToast.success(
                                    context,
                                    'Unit updated successfully.',
                                  );
                                } catch (_) {
                                  if (context.mounted) {
                                    ZerpaiToast.error(
                                      context,
                                      'Failed to update unit.',
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: const BorderSide(
                                  color: AppTheme.borderLight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                backgroundColor: const Color(0xFFF3F4F6),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorBanner(List<String> errors, VoidCallback onClose) {
    if (errors.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors
                  .map(
                    (err) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              err,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onClose,
            child: const Icon(
              LucideIcons.x,
              color: Color(0xFFB91C1C),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUnitDialog() {
    final nameController = TextEditingController();
    final symbolController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final List<String> dialogErrors = [];
        bool nameHasError = false;
        bool symbolHasError = false;
        bool precisionHasError = false;
        String? selectedUqc;
        String? selectedPrecision;
        const precisionOptions = ['0', '1', '2', '3', '4', '5', '6'];

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.only(
                top: 0,
                left: 40,
                right: 40,
                bottom: 40,
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Create Unit',
                              style: AppTextStyles.title.copyWith(fontSize: 18),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 20),
                              onPressed: () => Navigator.pop(context),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      // Body Container
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildErrorBanner(
                              dialogErrors,
                              () => setStateDialog(() => dialogErrors.clear()),
                            ),
                            // Row 1: Name
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 150,
                                  child: Text(
                                    'Name*',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                Focus(
                                  onFocusChange: (hasFocus) {
                                    setStateDialog(() {});
                                  },
                                  child: Builder(
                                    builder: (context) {
                                      final hasFocus = Focus.of(
                                        context,
                                      ).hasFocus;
                                      return Container(
                                        height: 34,
                                        width: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: nameHasError
                                                ? AppTheme.errorRed
                                                : (hasFocus
                                                      ? const Color(0xFF1E61D5)
                                                      : AppTheme.borderLight),
                                            width: (hasFocus || nameHasError)
                                                ? 1.5
                                                : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: nameController,
                                          style: AppTextStyles.input,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            hintText: 'Enter Unit Name',
                                            hintStyle: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                            errorStyle: TextStyle(
                                              height: 0,
                                              fontSize: 0,
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? ''
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Row 2: Symbol
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 150,
                                  child: Text(
                                    'Symbol*',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                Focus(
                                  onFocusChange: (hasFocus) {
                                    setStateDialog(() {});
                                  },
                                  child: Builder(
                                    builder: (context) {
                                      final hasFocus = Focus.of(
                                        context,
                                      ).hasFocus;
                                      return Container(
                                        height: 34,
                                        width: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: symbolHasError
                                                ? AppTheme.errorRed
                                                : (hasFocus
                                                      ? const Color(0xFF1E61D5)
                                                      : AppTheme.borderLight),
                                            width: (hasFocus || symbolHasError)
                                                ? 1.5
                                                : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: symbolController,
                                          style: AppTextStyles.input,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            hintText: 'Enter Symbol',
                                            hintStyle: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                            errorStyle: TextStyle(
                                              height: 0,
                                              fontSize: 0,
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? ''
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Row 3: UQC
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 150,
                                  child: Text(
                                    'Unique Quantity Code (UQC)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 200,
                                  height: 34,
                                  child: FormDropdown<String>(
                                    value: selectedUqc,
                                    items: _uqcOptions,
                                    hint: 'Select UQC',
                                    allowClear: true,
                                    showSearch: true,
                                    height: 34,
                                    boldSelected: false,
                                    textStyle: AppTextStyles.input.copyWith(
                                      color: selectedUqc == null
                                          ? Colors.grey
                                          : AppTheme.textPrimary,
                                    ),
                                    displayStringForValue: (val) => val,
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        selectedUqc = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (_unitConversionEnabled) ...[
                              const SizedBox(height: 16),
                              // Row 4: Precision
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 150,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Unit Precision*',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        ZTooltip(
                                          message:
                                              "If this unit is used for an item in a transaction, it's quantity will be rounded off to the selected unit precision.",
                                          child: const Icon(
                                            LucideIcons.helpCircle,
                                            size: 14,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 200,
                                    height: 34,
                                    child: FormDropdown<String>(
                                      value: selectedPrecision,
                                      items: precisionOptions,
                                      hint: 'Select Precision',
                                      allowClear: true,
                                      showSearch: false,
                                      height: 34,
                                      boldSelected: false,
                                      errorText: precisionHasError ? '' : null,
                                      textStyle: AppTextStyles.input.copyWith(
                                        color: selectedPrecision == null
                                            ? Colors.grey
                                            : AppTheme.textPrimary,
                                      ),
                                      displayStringForValue: (val) => val,
                                      itemBuilder:
                                          (value, isSelected, isHovered) {
                                            final labelColor = isHovered
                                                ? Colors.white
                                                : (isSelected
                                                      ? const Color(0xFF1E61D5)
                                                      : AppTheme.textPrimary);
                                            final checkColor = isHovered
                                                ? Colors.white
                                                : const Color(0xFF3B82F6);
                                            return Container(
                                              height: 38,
                                              alignment: Alignment.centerLeft,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      value,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: labelColor,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w500
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isSelected) ...[
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      Icons.check,
                                                      size: 16,
                                                      color: checkColor,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          },
                                      onChanged: (val) {
                                        setStateDialog(() {
                                          selectedPrecision = val;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Note : Once you\'ve selected a unit precision, you will only be able to increase the value the next time you edit it.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 16),
                            // Warning Banner Container
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                border: Border.all(
                                  color: const Color(0xFFFFEDD5),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    LucideIcons.alertTriangle,
                                    color: Color(0xFFF97316),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "As per e-Invoice System's API standards, UQC is required for all units. If you don't enter an UQC, we will use 'OTH (Others)' as the UQC while e-invoicing transactions.",
                                      style: AppTextStyles.helper.copyWith(
                                        color: const Color(0xFF374151),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      // Footer Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                dialogErrors.clear();
                                nameHasError = false;
                                symbolHasError = false;
                                precisionHasError = false;

                                if (nameController.text.trim().isEmpty) {
                                  nameHasError = true;
                                  dialogErrors.add('Unit Name is required.');
                                }
                                if (symbolController.text.trim().isEmpty) {
                                  symbolHasError = true;
                                  dialogErrors.add('Symbol is required.');
                                }
                                if (_unitConversionEnabled &&
                                    selectedPrecision == null) {
                                  precisionHasError = true;
                                  dialogErrors.add(
                                    'Unit Precision is required.',
                                  );
                                }

                                if (dialogErrors.isNotEmpty) {
                                  setStateDialog(() {});
                                  formKey.currentState!.validate();
                                  return;
                                }

                                try {
                                  await _saveUnit(
                                    name: nameController.text.trim(),
                                    symbol: symbolController.text.trim(),
                                    uqcOption: selectedUqc,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ZerpaiToast.success(
                                    context,
                                    'Unit created successfully.',
                                  );
                                } catch (_) {
                                  if (context.mounted) {
                                    ZerpaiToast.error(
                                      context,
                                      'Failed to create unit.',
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: const BorderSide(
                                  color: AppTheme.borderLight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                backgroundColor: const Color(0xFFF3F4F6),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddUnitGroupDialog() {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final List<String> dialogErrors = [];
        bool nameHasError = false;
        bool baseUnitHasError = false;
        final Set<int> conversionRowsWithTargetUnitError = {};
        final Set<int> conversionRowsWithRateError = {};
        UnitOfMeasurement? selectedBaseUnit;
        final List<Map<String, dynamic>> conversions = [
          {'targetUnit': null, 'rateController': TextEditingController()},
        ];

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Widget buildDropdownItem(
              UnitOfMeasurement unit,
              bool isSelected,
              bool isHovered,
            ) {
              final labelColor = isHovered
                  ? Colors.white
                  : (isSelected
                        ? const Color(0xFF1E61D5)
                        : AppTheme.textPrimary);
              final checkColor = isHovered
                  ? Colors.white
                  : const Color(0xFF3B82F6);
              return Container(
                height: 38,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${unit.name}(${unit.symbol})",
                        style: TextStyle(
                          fontSize: 13,
                          color: labelColor,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check, size: 16, color: checkColor),
                    ],
                  ],
                ),
              );
            }

            List<UnitOfMeasurement> getAvailableTargetUnits(int currentIndex) {
              return _units.where((unit) {
                if (unit == selectedBaseUnit) return false;
                for (int i = 0; i < conversions.length; i++) {
                  if (i != currentIndex &&
                      conversions[i]['targetUnit'] == unit) {
                    return false;
                  }
                }
                return true;
              }).toList();
            }

            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.only(
                top: 0,
                left: 40,
                right: 40,
                bottom: 40,
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Create Unit Group',
                              style: AppTextStyles.title.copyWith(fontSize: 18),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 20),
                              onPressed: () => Navigator.pop(context),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      // Body Container
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildErrorBanner(
                              dialogErrors,
                              () => setStateDialog(() => dialogErrors.clear()),
                            ),
                            // Row 1: Name
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 150,
                                  child: Text(
                                    'Name*',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                Focus(
                                  onFocusChange: (hasFocus) {
                                    setStateDialog(() {});
                                  },
                                  child: Builder(
                                    builder: (context) {
                                      final hasFocus = Focus.of(
                                        context,
                                      ).hasFocus;
                                      return Container(
                                        height: 34,
                                        width: 350,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: nameHasError
                                                ? AppTheme.errorRed
                                                : (hasFocus
                                                      ? const Color(0xFF1E61D5)
                                                      : AppTheme.borderLight),
                                            width: (hasFocus || nameHasError)
                                                ? 1.5
                                                : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: nameController,
                                          style: AppTextStyles.input,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            hintText: 'Enter Unit Group Name',
                                            hintStyle: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                            errorStyle: TextStyle(
                                              height: 0,
                                              fontSize: 0,
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? ''
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Row 2: Base Unit
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 150,
                                  child: Text(
                                    'Base Unit*',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 350,
                                  height: 34,
                                  child: FormDropdown<UnitOfMeasurement>(
                                    value: selectedBaseUnit,
                                    items: _units,
                                    hint: 'Select Base Unit',
                                    allowClear: true,
                                    showSearch: true,
                                    height: 34,
                                    boldSelected: false,
                                    errorText: baseUnitHasError ? '' : null,
                                    textStyle: AppTextStyles.input.copyWith(
                                      color: selectedBaseUnit == null
                                          ? Colors.grey
                                          : AppTheme.textPrimary,
                                    ),
                                    displayStringForValue: (val) => val.symbol,
                                    searchStringForValue: (val) =>
                                        "${val.name}(${val.symbol})",
                                    itemBuilder: buildDropdownItem,
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        selectedBaseUnit = val;
                                        for (var conv in conversions) {
                                          if (conv['targetUnit'] == val) {
                                            conv['targetUnit'] = null;
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (selectedBaseUnit != null) ...[
                              const SizedBox(height: 16),
                              const Divider(
                                height: 1,
                                color: AppTheme.borderLight,
                              ),
                              const SizedBox(height: 16),
                              // Unit Conversions Header
                              const Text(
                                'Unit Conversions',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Conversions List
                              ...conversions.map((conv) {
                                final int idx = conversions.indexOf(conv);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Prefix '1' + Target Unit Dropdown
                                      Container(
                                        width: 36,
                                        height: 34,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF9FAFB),
                                          border: Border(
                                            top: BorderSide(
                                              color: AppTheme.borderLight,
                                            ),
                                            bottom: BorderSide(
                                              color: AppTheme.borderLight,
                                            ),
                                            left: BorderSide(
                                              color: AppTheme.borderLight,
                                            ),
                                            right: BorderSide(
                                              color: AppTheme.borderLight,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(4),
                                            bottomLeft: Radius.circular(4),
                                          ),
                                        ),
                                        child: const Text(
                                          '1',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 180,
                                        height: 34,
                                        child: FormDropdown<UnitOfMeasurement>(
                                          value:
                                              conv['targetUnit']
                                                  as UnitOfMeasurement?,
                                          items: getAvailableTargetUnits(idx),
                                          hint: 'Select Target Unit',
                                          allowClear: true,
                                          showSearch: true,
                                          height: 34,
                                          boldSelected: false,
                                          errorText:
                                              conversionRowsWithTargetUnitError
                                                  .contains(idx)
                                              ? ''
                                              : null,
                                          textStyle: AppTextStyles.input
                                              .copyWith(
                                                color:
                                                    conv['targetUnit'] == null
                                                    ? Colors.grey
                                                    : AppTheme.textPrimary,
                                              ),
                                          showLeftBorder: false,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(4),
                                            bottomRight: Radius.circular(4),
                                          ),
                                          displayStringForValue: (val) =>
                                              val.symbol,
                                          searchStringForValue: (val) =>
                                              "${val.name}(${val.symbol})",
                                          itemBuilder: buildDropdownItem,
                                          onChanged: (val) {
                                            setStateDialog(() {
                                              conv['targetUnit'] = val;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        '=',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Rate input + Base Unit Symbol Suffix combined group
                                      Focus(
                                        onFocusChange: (hasFocus) {
                                          setStateDialog(() {});
                                        },
                                        child: Builder(
                                          builder: (context) {
                                            final hasFocus = Focus.of(
                                              context,
                                            ).hasFocus;
                                            return Container(
                                              height: 34,
                                              width: 216,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                  color: hasFocus
                                                      ? const Color(0xFF1E61D5)
                                                      : AppTheme.borderLight,
                                                  width: hasFocus ? 1.5 : 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          conv['rateController']
                                                              as TextEditingController,
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.allow(
                                                          RegExp(r'[0-9.]'),
                                                        ),
                                                      ],
                                                      style:
                                                          AppTextStyles.input,
                                                      decoration:
                                                          const InputDecoration(
                                                            isDense: true,
                                                            contentPadding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 8,
                                                                ),
                                                            hintText:
                                                                'Conversion Rate',
                                                            hintStyle:
                                                                TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                            border: InputBorder
                                                                .none,
                                                            enabledBorder:
                                                                InputBorder
                                                                    .none,
                                                            focusedBorder:
                                                                InputBorder
                                                                    .none,
                                                          ),
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 34,
                                                    width: 36,
                                                    alignment: Alignment.center,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFFF9FAFB,
                                                          ),
                                                          border: Border(
                                                            left: BorderSide(
                                                              color: AppTheme
                                                                  .borderLight,
                                                            ),
                                                          ),
                                                        ),
                                                    child: Text(
                                                      selectedBaseUnit
                                                              ?.symbol ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: AppTheme
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      if (conversions.length > 1) ...[
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {
                                            setStateDialog(() {
                                              conversions.removeAt(idx);
                                            });
                                          },
                                          child: const Icon(
                                            LucideIcons.x,
                                            size: 16,
                                            color: Color(0xFFF87171),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                              // Add Conversion button
                              InkWell(
                                onTap: () {
                                  setStateDialog(() {
                                    conversions.add({
                                      'targetUnit': null,
                                      'rateController': TextEditingController(),
                                    });
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.plus,
                                        size: 16,
                                        color: Color(0xFF1E61D5),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Add Conversion',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1E61D5),
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
                      const Divider(height: 1, color: AppTheme.borderLight),
                      // Footer Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                dialogErrors.clear();
                                nameHasError = false;
                                baseUnitHasError = false;
                                conversionRowsWithTargetUnitError.clear();
                                conversionRowsWithRateError.clear();

                                if (nameController.text.trim().isEmpty) {
                                  dialogErrors.add(
                                    'Unit Group Name is required.',
                                  );
                                  nameHasError = true;
                                }
                                if (selectedBaseUnit == null) {
                                  baseUnitHasError = true;
                                  dialogErrors.add('Base Unit is required.');
                                }

                                bool conversionErrorAdded = false;
                                for (int i = 0; i < conversions.length; i++) {
                                  final conv = conversions[i];
                                  final targetUnit = conv['targetUnit'];
                                  final rateStr = conv['rateController'].text
                                      .trim();
                                  final rateVal = double.tryParse(rateStr);

                                  bool rowHasError = false;
                                  if (targetUnit == null) {
                                    conversionRowsWithTargetUnitError.add(i);
                                    rowHasError = true;
                                  }
                                  if (rateStr.isEmpty ||
                                      rateVal == null ||
                                      rateVal <= 0) {
                                    conversionRowsWithRateError.add(i);
                                    rowHasError = true;
                                  }

                                  if (rowHasError && !conversionErrorAdded) {
                                    dialogErrors.add(
                                      'Both target unit and conversion rate are required for unit conversions.',
                                    );
                                    conversionErrorAdded = true;
                                  }
                                }

                                if (dialogErrors.isNotEmpty) {
                                  setStateDialog(() {});
                                  formKey.currentState!.validate();
                                  return;
                                }

                                final newConversions = conversions
                                    .map(
                                      (c) => UnitConversion(
                                        targetUnit:
                                            c['targetUnit']
                                                as UnitOfMeasurement,
                                        rate: double.parse(
                                          c['rateController'].text.trim(),
                                        ),
                                      ),
                                    )
                                    .toList();
                                try {
                                  await _saveUnitGroup(
                                    name: nameController.text.trim(),
                                    baseUnit: selectedBaseUnit!,
                                    conversions: newConversions,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ZerpaiToast.success(
                                    this.context,
                                    'Unit Group created successfully.',
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ZerpaiToast.error(
                                    context,
                                    'Failed to create unit group',
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: const BorderSide(
                                  color: AppTheme.borderLight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                backgroundColor: const Color(0xFFF3F4F6),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditUnitGroupDialog(int index) {
    final group = _unitGroups[index];
    final nameController = TextEditingController(text: group.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final List<String> dialogErrors = [];
        bool nameHasError = false;
        final Set<int> conversionRowsWithTargetUnitError = {};
        final Set<int> conversionRowsWithRateError = {};
        final selectedBaseUnit = group.baseUnit;
        final List<Map<String, dynamic>> conversions = group.conversions.map((
          c,
        ) {
          return {
            'targetUnit': c.targetUnit,
            'rateController': TextEditingController(text: c.rate.toString()),
            'isNew': false,
          };
        }).toList();

        if (conversions.isEmpty) {
          conversions.add({
            'targetUnit': null,
            'rateController': TextEditingController(),
          });
        }

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Widget buildDropdownItem(
              UnitOfMeasurement unit,
              bool isSelected,
              bool isHovered,
            ) {
              final labelColor = isHovered
                  ? Colors.white
                  : (isSelected
                        ? const Color(0xFF1E61D5)
                        : AppTheme.textPrimary);
              final checkColor = isHovered
                  ? Colors.white
                  : const Color(0xFF3B82F6);
              return Container(
                height: 38,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${unit.name}(${unit.symbol})",
                        style: TextStyle(
                          fontSize: 13,
                          color: labelColor,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check, size: 16, color: checkColor),
                    ],
                  ],
                ),
              );
            }

            List<UnitOfMeasurement> getAvailableTargetUnits(int currentIndex) {
              return _units.where((unit) {
                if (unit == selectedBaseUnit) return false;
                for (int i = 0; i < conversions.length; i++) {
                  if (i != currentIndex &&
                      conversions[i]['targetUnit'] == unit) {
                    return false;
                  }
                }
                return true;
              }).toList();
            }

            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.only(
                top: 0,
                left: 40,
                right: 40,
                bottom: 40,
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Edit Unit Group',
                              style: AppTextStyles.title.copyWith(fontSize: 18),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 20),
                              onPressed: () => Navigator.pop(context),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildErrorBanner(
                              dialogErrors,
                              () => setStateDialog(() => dialogErrors.clear()),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 150,
                                  child: Text(
                                    'Name*',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                Focus(
                                  onFocusChange: (hasFocus) {
                                    setStateDialog(() {});
                                  },
                                  child: Builder(
                                    builder: (context) {
                                      final hasFocus = Focus.of(
                                        context,
                                      ).hasFocus;
                                      return Container(
                                        height: 34,
                                        width: 350,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: nameHasError
                                                ? AppTheme.errorRed
                                                : (hasFocus
                                                      ? const Color(0xFF1E61D5)
                                                      : AppTheme.borderLight),
                                            width: (hasFocus || nameHasError)
                                                ? 1.5
                                                : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: nameController,
                                          style: AppTextStyles.input,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            hintText: 'Enter Unit Group Name',
                                            hintStyle: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                            errorStyle: TextStyle(
                                              height: 0,
                                              fontSize: 0,
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? ''
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 150,
                                  child: Text(
                                    'Base Unit*',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 350,
                                  height: 34,
                                  child: FormDropdown<UnitOfMeasurement>(
                                    value: selectedBaseUnit,
                                    items: _units,
                                    hint: 'Select Base Unit',
                                    allowClear: false,
                                    showSearch: true,
                                    height: 34,
                                    boldSelected: false,
                                    enabled: false,
                                    fillColor: const Color(0xFFF3F4F6),
                                    textStyle: AppTextStyles.input.copyWith(
                                      color: AppTheme.textPrimary,
                                    ),
                                    displayStringForValue: (val) => val.symbol,
                                    searchStringForValue: (val) =>
                                        "${val.name}(${val.symbol})",
                                    itemBuilder: buildDropdownItem,
                                    onChanged: (val) {},
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Unit Conversions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...conversions.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final conv = entry.value;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 34,
                                      width: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        border: Border.all(
                                          color: AppTheme.borderLight,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          bottomLeft: Radius.circular(4),
                                        ),
                                      ),
                                      child: const Text(
                                        '1',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 180,
                                      height: 34,
                                      child: FormDropdown<UnitOfMeasurement>(
                                        value:
                                            conv['targetUnit']
                                                as UnitOfMeasurement?,
                                        items: getAvailableTargetUnits(idx),
                                        hint: 'Select Target Unit',
                                        allowClear: false,
                                        showSearch: true,
                                        height: 34,
                                        boldSelected: false,
                                        enabled: conv['isNew'] == true,
                                        fillColor: conv['isNew'] == true
                                            ? Colors.white
                                            : const Color(0xFFF3F4F6),
                                        errorText:
                                            conversionRowsWithTargetUnitError
                                                .contains(idx)
                                            ? ''
                                            : null,
                                        textStyle: AppTextStyles.input.copyWith(
                                          color: conv['targetUnit'] == null
                                              ? Colors.grey
                                              : AppTheme.textPrimary,
                                        ),
                                        showLeftBorder: false,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(4),
                                          bottomRight: Radius.circular(4),
                                        ),
                                        displayStringForValue: (val) =>
                                            val.symbol,
                                        searchStringForValue: (val) =>
                                            "${val.name}(${val.symbol})",
                                        itemBuilder: buildDropdownItem,
                                        onChanged: (val) {
                                          if (conv['isNew'] == true) {
                                            setStateDialog(() {
                                              conv['targetUnit'] = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      '=',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Focus(
                                      onFocusChange: (hasFocus) {
                                        setStateDialog(() {});
                                      },
                                      child: Builder(
                                        builder: (context) {
                                          final hasFocus = Focus.of(
                                            context,
                                          ).hasFocus;
                                          return Container(
                                            height: 34,
                                            width: 216,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color:
                                                    conversionRowsWithRateError
                                                        .contains(idx)
                                                    ? AppTheme.errorRed
                                                    : (hasFocus
                                                          ? const Color(
                                                              0xFF1E61D5,
                                                            )
                                                          : AppTheme
                                                                .borderLight),
                                                width:
                                                    (hasFocus ||
                                                        conversionRowsWithRateError
                                                            .contains(idx))
                                                    ? 1.5
                                                    : 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextFormField(
                                                    controller:
                                                        conv['rateController']
                                                            as TextEditingController,
                                                    keyboardType:
                                                        const TextInputType.numberWithOptions(
                                                          decimal: true,
                                                        ),
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.allow(
                                                        RegExp(r'[0-9.]'),
                                                      ),
                                                    ],
                                                    style: AppTextStyles.input,
                                                    decoration:
                                                        const InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                          hintText:
                                                              'Conversion Rate',
                                                          hintStyle: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey,
                                                          ),
                                                          border:
                                                              InputBorder.none,
                                                          enabledBorder:
                                                              InputBorder.none,
                                                          focusedBorder:
                                                              InputBorder.none,
                                                        ),
                                                    validator: (v) =>
                                                        conversionRowsWithRateError
                                                            .contains(idx)
                                                        ? ''
                                                        : null,
                                                  ),
                                                ),
                                                Container(
                                                  height: 34,
                                                  width: 36,
                                                  alignment: Alignment.center,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFFF9FAFB,
                                                        ),
                                                        border: Border(
                                                          left: BorderSide(
                                                            color: AppTheme
                                                                .borderLight,
                                                          ),
                                                        ),
                                                      ),
                                                  child: Text(
                                                    selectedBaseUnit.symbol,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    if (conversions.length > 1) ...[
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () {
                                          setStateDialog(() {
                                            conversions.removeAt(idx);
                                          });
                                        },
                                        child: const Icon(
                                          LucideIcons.x,
                                          size: 16,
                                          color: Color(0xFFF87171),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                setStateDialog(() {
                                  conversions.add({
                                    'targetUnit': null,
                                    'rateController': TextEditingController(),
                                    'isNew': true,
                                  });
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.plus,
                                      size: 16,
                                      color: Color(0xFF1E61D5),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add Conversion',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E61D5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                dialogErrors.clear();
                                nameHasError = false;

                                conversionRowsWithTargetUnitError.clear();
                                conversionRowsWithRateError.clear();

                                if (nameController.text.trim().isEmpty) {
                                  nameHasError = true;
                                  dialogErrors.add(
                                    'Unit Group Name is required.',
                                  );
                                }

                                bool conversionErrorAdded = false;
                                for (int i = 0; i < conversions.length; i++) {
                                  final conv = conversions[i];
                                  final targetUnit = conv['targetUnit'];
                                  final rateStr = conv['rateController'].text
                                      .trim();
                                  final rateVal = double.tryParse(rateStr);

                                  bool rowHasError = false;
                                  if (targetUnit == null) {
                                    conversionRowsWithTargetUnitError.add(i);
                                    rowHasError = true;
                                  }
                                  if (rateStr.isEmpty ||
                                      rateVal == null ||
                                      rateVal <= 0) {
                                    conversionRowsWithRateError.add(i);
                                    rowHasError = true;
                                  }

                                  if (rowHasError && !conversionErrorAdded) {
                                    dialogErrors.add(
                                      'Both target unit and conversion rate are required for unit conversions.',
                                    );
                                    conversionErrorAdded = true;
                                  }
                                }

                                if (dialogErrors.isNotEmpty) {
                                  setStateDialog(() {});
                                  formKey.currentState!.validate();
                                  return;
                                }

                                final nextConversions = conversions
                                    .map(
                                      (c) => UnitConversion(
                                        targetUnit:
                                            c['targetUnit']
                                                as UnitOfMeasurement,
                                        rate: double.parse(
                                          c['rateController'].text.trim(),
                                        ),
                                      ),
                                    )
                                    .toList();
                                try {
                                  await _saveUnitGroup(
                                    id: group.id,
                                    name: nameController.text.trim(),
                                    baseUnit: selectedBaseUnit,
                                    conversions: nextConversions,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ZerpaiToast.success(
                                    this.context,
                                    'Unit Group updated successfully.',
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ZerpaiToast.error(
                                    context,
                                    'Failed to update unit group',
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: const BorderSide(
                                  color: AppTheme.borderLight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                backgroundColor: const Color(0xFFF3F4F6),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabItem({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF1E61D5) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF1E61D5) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    final orgName =
        ref.watch(authUserProvider)?.orgName.trim() ?? 'Your Organization';

    final searchItems = <SettingsSearchItem>[
      SettingsSearchItem(
        group: 'Organization',
        label: 'Profile',
        subtitle: 'Company details and contact info',
        onSelected: () =>
            context.go('/$orgSystemId${AppRoutes.settingsOrgProfile}'),
      ),
      SettingsSearchItem(
        group: 'Organization',
        label: 'Branding',
        subtitle: 'Company logos, colors and themes',
        onSelected: () =>
            context.go('/$orgSystemId${AppRoutes.settingsOrgBranding}'),
      ),
      SettingsSearchItem(
        group: 'Organization',
        label: 'Locations',
        subtitle: 'Manage branches and business locations',
        onSelected: () =>
            context.go('/$orgSystemId${AppRoutes.settingsLocations}'),
      ),
      SettingsSearchItem(
        group: 'Setup & Configurations',
        label: 'General',
        subtitle: 'Global parameters and inventory options',
        onSelected: () =>
            context.go('/$orgSystemId${AppRoutes.settingsGeneral}'),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showSettingsSidebar = constraints.maxWidth >= 980;
          return Column(
            children: [
              SettingsPageHeader(orgName: orgName, searchItems: searchItems),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showSettingsSidebar)
                      SettingsNavigationSidebar(currentPath: currentPath),
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header bar with Title and buttons
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Units of Measurement',
                                    style: AppTextStyles.title.copyWith(
                                      fontSize: 22,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (!_unitConversionEnabled) ...[
                                        OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              _unitConversionEnabled = true;
                                            });
                                            ZerpaiToast.success(
                                              context,
                                              'Unit conversion enabled successfully.',
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.textPrimary,
                                            side: const BorderSide(
                                              color: AppTheme.borderLight,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          child: const Text(
                                            'Enable Unit Conversion',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ] else ...[
                                        OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              _unitConversionEnabled = false;
                                              _activeTab = 'Units';
                                            });
                                            ZerpaiToast.success(
                                              context,
                                              'Unit conversion disabled successfully.',
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.textPrimary,
                                            side: const BorderSide(
                                              color: AppTheme.borderLight,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          child: const Text(
                                            'Disable Unit Conversion',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      ElevatedButton(
                                        onPressed:
                                            _unitConversionEnabled &&
                                                _activeTab == 'Unit Groups'
                                            ? _showAddUnitGroupDialog
                                            : _showAddUnitDialog,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          _unitConversionEnabled &&
                                                  _activeTab == 'Unit Groups'
                                              ? '+ New Unit Group'
                                              : '+ New Unit',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Tab Bar (if enabled)
                            if (_unitConversionEnabled)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppTheme.borderLight,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildTabItem(
                                      label: 'Units',
                                      isActive: _activeTab == 'Units',
                                      onTap: () {
                                        setState(() {
                                          _activeTab = 'Units';
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 24),
                                    _buildTabItem(
                                      label: 'Unit Groups',
                                      isActive: _activeTab == 'Unit Groups',
                                      onTap: () {
                                        setState(() {
                                          _activeTab = 'Unit Groups';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            // Table Headers
                            if (!_unitConversionEnabled)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF9FAFB),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppTheme.borderLight,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 18,
                                      child: Text(
                                        'UNIT NAME',
                                        style: AppTextStyles.helper.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 10,
                                      child: Text(
                                        'SYMBOL',
                                        style: AppTextStyles.helper.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 52,
                                      child: Text(
                                        'UNIQUE QUANTITY CODE (UQC)',
                                        style: AppTextStyles.helper.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (_activeTab == 'Units')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF9FAFB),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppTheme.borderLight,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 18,
                                      child: Text(
                                        'UNIT NAME',
                                        style: AppTextStyles.helper.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 10,
                                      child: Text(
                                        'SYMBOL',
                                        style: AppTextStyles.helper.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 18,
                                      child: Text(
                                        'UNIQUE QUANTITY CODE (UQC)',
                                        style: AppTextStyles.helper.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 34,
                                      child: Text(
                                        'UNIT PRECISION',
                                        style: AppTextStyles.helper.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF9FAFB),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppTheme.borderLight,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Row(
                                        children: [
                                          Text(
                                            'GROUP NAME',
                                            style: AppTextStyles.helper
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textMuted,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            LucideIcons.chevronsUpDown,
                                            size: 14,
                                            color: AppTheme.textMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'BASE UNIT',
                                        style: AppTextStyles.helper.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        'CONVERSIONS',
                                        style: AppTextStyles.helper.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Table Rows list or Placeholder
                            if (_isLoading)
                              const Expanded(
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            else if ((!_unitConversionEnabled ||
                                    _activeTab == 'Units') &&
                                _units.isEmpty)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'No Units Available',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              )
                            else if (!_unitConversionEnabled ||
                                _activeTab == 'Units')
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _units.length,
                                  itemBuilder: (context, index) {
                                    final unit = _units[index];
                                    final isHovered = _hoveredIndex == index;
                                    return MouseRegion(
                                      onEnter: (_) =>
                                          setState(() => _hoveredIndex = index),
                                      onExit: (_) =>
                                          setState(() => _hoveredIndex = null),
                                      child: Container(
                                        height: 42,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isHovered
                                              ? const Color(0xFFF3F4F6)
                                              : Colors.white,
                                          border: const Border(
                                            bottom: BorderSide(
                                              color: AppTheme.borderLight,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 18,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: InkWell(
                                                  onTap: () =>
                                                      _showEditUnitDialog(
                                                        index,
                                                      ),
                                                  child: Text(
                                                    unit.name,
                                                    style: AppTextStyles.body
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: const Color(
                                                            0xFF1E61D5,
                                                          ), // Link color
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 10,
                                              child: Text(
                                                unit.symbol,
                                                style: AppTextStyles.body,
                                              ),
                                            ),
                                            if (!_unitConversionEnabled) ...[
                                              Expanded(
                                                flex: 52,
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      unit.uqc.isEmpty
                                                          ? '-'
                                                          : unit.uqc,
                                                      style: AppTextStyles.body,
                                                    ),
                                                    const SizedBox(width: 260),
                                                    if (isHovered ||
                                                        _activeDropdownIndex ==
                                                            index)
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          InkWell(
                                                            onTap: () =>
                                                                _showEditUnitDialog(
                                                                  index,
                                                                ),
                                                            onHover: (hovering) {
                                                              setState(() {
                                                                _hoveredEditIndex =
                                                                    hovering
                                                                    ? index
                                                                    : null;
                                                              });
                                                            },
                                                            child: Text(
                                                              'Edit',
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color:
                                                                    _hoveredEditIndex ==
                                                                        index
                                                                    ? const Color(
                                                                        0xFF1E61D5,
                                                                      )
                                                                    : AppTheme
                                                                          .textPrimary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Container(
                                                            height: 14,
                                                            width: 1,
                                                            color: AppTheme
                                                                .borderLight,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          SizedBox(
                                                            width: 24,
                                                            height: 24,
                                                            child: PopupMenuButton<String>(
                                                              onOpened: () {
                                                                setState(() {
                                                                  _activeDropdownIndex =
                                                                      index;
                                                                });
                                                              },
                                                              onCanceled: () {
                                                                setState(() {
                                                                  _activeDropdownIndex =
                                                                      null;
                                                                });
                                                              },
                                                              onSelected: (value) {
                                                                setState(() {
                                                                  _activeDropdownIndex =
                                                                      null;
                                                                });
                                                                if (value ==
                                                                    'delete') {
                                                                  _showDeleteConfirmationDialog(
                                                                    context,
                                                                    message:
                                                                        'Once you delete this Unit, you cannot retrieve it.',
                                                                    onDelete: () async {
                                                                      try {
                                                                        await _deleteUnit(
                                                                          index,
                                                                        );
                                                                        if (context
                                                                            .mounted) {
                                                                          ZerpaiToast.success(
                                                                            context,
                                                                            'Unit deleted successfully.',
                                                                          );
                                                                        }
                                                                      } catch (
                                                                        _
                                                                      ) {
                                                                        if (context
                                                                            .mounted) {
                                                                          ZerpaiToast.error(
                                                                            context,
                                                                            'Failed to delete unit.',
                                                                          );
                                                                        }
                                                                      }
                                                                    },
                                                                  );
                                                                }
                                                              },
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    30,
                                                                  ),
                                                              color: const Color(
                                                                0xFF3B82F6,
                                                              ), // Blue background
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4,
                                                                    ),
                                                                side: const BorderSide(
                                                                  color: Colors
                                                                      .white,
                                                                  width: 2,
                                                                ), // White outline border
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(
                                                                    minWidth:
                                                                        68,
                                                                    maxWidth:
                                                                        68,
                                                                  ),
                                                              icon: Container(
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      2,
                                                                    ),
                                                                decoration: const BoxDecoration(
                                                                  color: Color(
                                                                    0xFF10B981,
                                                                  ), // Green circle
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child: const Icon(
                                                                  LucideIcons
                                                                      .chevronDown,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 12,
                                                                ),
                                                              ),
                                                              itemBuilder: (context) => [
                                                                PopupMenuItem<
                                                                  String
                                                                >(
                                                                  value:
                                                                      'delete',
                                                                  height: 28,
                                                                  child: Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: const Text(
                                                                      'Delete',
                                                                      style: TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight.w500,
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
                                                ),
                                              ),
                                            ] else ...[
                                              Expanded(
                                                flex: 18,
                                                child: Text(
                                                  unit.uqc.isEmpty
                                                      ? '-'
                                                      : unit.uqc,
                                                  style: AppTextStyles.body,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 34,
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      unit.precision,
                                                      style: AppTextStyles.body,
                                                    ),
                                                    const Spacer(),
                                                    if (isHovered ||
                                                        _activeDropdownIndex ==
                                                            index)
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          InkWell(
                                                            onTap: () =>
                                                                _showEditUnitDialog(
                                                                  index,
                                                                ),
                                                            onHover: (hovering) {
                                                              setState(() {
                                                                _hoveredEditIndex =
                                                                    hovering
                                                                    ? index
                                                                    : null;
                                                              });
                                                            },
                                                            child: Text(
                                                              'Edit',
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color:
                                                                    _hoveredEditIndex ==
                                                                        index
                                                                    ? const Color(
                                                                        0xFF1E61D5,
                                                                      )
                                                                    : AppTheme
                                                                          .textPrimary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Container(
                                                            height: 14,
                                                            width: 1,
                                                            color: AppTheme
                                                                .borderLight,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          SizedBox(
                                                            width: 24,
                                                            height: 24,
                                                            child: PopupMenuButton<String>(
                                                              onOpened: () {
                                                                setState(() {
                                                                  _activeDropdownIndex =
                                                                      index;
                                                                });
                                                              },
                                                              onCanceled: () {
                                                                setState(() {
                                                                  _activeDropdownIndex =
                                                                      null;
                                                                });
                                                              },
                                                              onSelected: (value) {
                                                                setState(() {
                                                                  _activeDropdownIndex =
                                                                      null;
                                                                });
                                                                if (value ==
                                                                    'delete') {
                                                                  _showDeleteConfirmationDialog(
                                                                    context,
                                                                    message:
                                                                        'Once you delete this Unit, you cannot retrieve it.',
                                                                    onDelete: () async {
                                                                      try {
                                                                        await _deleteUnit(
                                                                          index,
                                                                        );
                                                                        if (context
                                                                            .mounted) {
                                                                          ZerpaiToast.success(
                                                                            context,
                                                                            'Unit deleted successfully.',
                                                                          );
                                                                        }
                                                                      } catch (
                                                                        _
                                                                      ) {
                                                                        if (context
                                                                            .mounted) {
                                                                          ZerpaiToast.error(
                                                                            context,
                                                                            'Failed to delete unit.',
                                                                          );
                                                                        }
                                                                      }
                                                                    },
                                                                  );
                                                                }
                                                              },
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    30,
                                                                  ),
                                                              color: const Color(
                                                                0xFF3B82F6,
                                                              ), // Blue background
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4,
                                                                    ),
                                                                side: const BorderSide(
                                                                  color: Colors
                                                                      .white,
                                                                  width: 2,
                                                                ), // White outline border
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(
                                                                    minWidth:
                                                                        68,
                                                                    maxWidth:
                                                                        68,
                                                                  ),
                                                              icon: Container(
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      2,
                                                                    ),
                                                                decoration: const BoxDecoration(
                                                                  color: Color(
                                                                    0xFF10B981,
                                                                  ), // Green circle
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child: const Icon(
                                                                  LucideIcons
                                                                      .chevronDown,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 12,
                                                                ),
                                                              ),
                                                              itemBuilder: (context) => [
                                                                PopupMenuItem<
                                                                  String
                                                                >(
                                                                  value:
                                                                      'delete',
                                                                  height: 28,
                                                                  child: Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: const Text(
                                                                      'Delete',
                                                                      style: TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    const SizedBox(width: 48),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            else if (_unitGroups.isNotEmpty)
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _unitGroups.length,
                                  itemBuilder: (context, index) {
                                    final group = _unitGroups[index];
                                    final isHovered =
                                        _hoveredIndex == (index + 1000);

                                    return MouseRegion(
                                      onEnter: (_) => setState(
                                        () => _hoveredIndex = index + 1000,
                                      ),
                                      onExit: (_) =>
                                          setState(() => _hoveredIndex = null),
                                      child: Container(
                                        height: 42,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isHovered
                                              ? const Color(0xFFF3F4F6)
                                              : Colors.white,
                                          border: const Border(
                                            bottom: BorderSide(
                                              color: AppTheme.borderLight,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 4,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: InkWell(
                                                  onTap: () =>
                                                      _showEditUnitGroupDialog(
                                                        index,
                                                      ),
                                                  child: Text(
                                                    group.name,
                                                    style: AppTextStyles.body
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: const Color(
                                                            0xFF1E61D5,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                group.baseUnit.symbol,
                                                style: AppTextStyles.body,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 5,
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      group.conversions.length
                                                          .toString(),
                                                      style: AppTextStyles.body,
                                                    ),
                                                  ),
                                                  if (isHovered)
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        InkWell(
                                                          onTap: () =>
                                                              _showEditUnitGroupDialog(
                                                                index,
                                                              ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                LucideIcons
                                                                    .pencil,
                                                                size: 13,
                                                                color: Color(
                                                                  0xFF1E61D5,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                'Edit',
                                                                style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: const Color(
                                                                    0xFF1E61D5,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Container(
                                                          height: 14,
                                                          width: 1,
                                                          color: AppTheme
                                                              .borderLight,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        InkWell(
                                                          onTap: () {
                                                            _showDeleteConfirmationDialog(
                                                              context,
                                                              message:
                                                                  'Once you delete this Unit Group, you cannot retrieve it.',
                                                              onDelete: () async {
                                                                try {
                                                                  await _deleteUnitGroup(
                                                                    group,
                                                                  );
                                                                  if (!mounted)
                                                                    return;
                                                                  ZerpaiToast.success(
                                                                    context,
                                                                    'Unit Group deleted successfully.',
                                                                  );
                                                                } catch (_) {
                                                                  if (!mounted)
                                                                    return;
                                                                  ZerpaiToast.error(
                                                                    context,
                                                                    'Failed to delete unit group',
                                                                  );
                                                                }
                                                              },
                                                            );
                                                          },
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                LucideIcons
                                                                    .trash2,
                                                                size: 13,
                                                                color: Color(
                                                                  0xFF4B5563,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              const Text(
                                                                'Delete',
                                                                style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: Color(
                                                                    0xFF4B5563,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
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
                                    );
                                  },
                                ),
                              )
                            else
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'No Unit Groups Available',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context, {
    required String message,
    required VoidCallback onDelete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(top: 0, left: 40, right: 40),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          LucideIcons.alertTriangle,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.red,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text('Delete'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.borderLight),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          backgroundColor: const Color(0xFFF3F4F6),
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
  }
}
