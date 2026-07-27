import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/settings/shared/data/repositories/settings_preferences_repository.dart';

enum ExpensesSettingsTab { preferences, vehicle, categories, fields }

enum _DistanceUnit { km, mile }

enum _VehicleDialogMode { create, edit }

enum _CategoryDialogMode { create, edit }

class _CategoryRow {
  _CategoryRow({
    required this.name,
    required this.description,
    this.isActive = true,
  });

  String name;
  String description;
  bool isActive;
}

class _MileageRateRow {
  const _MileageRateRow({
    required this.startDate,
    required this.vehicle,
    required this.rate,
  });

  final String startDate;
  final String vehicle;
  final String rate;
}

class _VehicleRow {
  const _VehicleRow({required this.name, required this.hint});

  final String name;
  final String hint;
}

class _VehicleDialogDraft {
  _VehicleDialogDraft({String? name, String? hint})
    : nameController = TextEditingController(text: name ?? ''),
      hintController = TextEditingController(text: hint ?? '');

  final TextEditingController nameController;
  final TextEditingController hintController;

  void dispose() {
    nameController.dispose();
    hintController.dispose();
  }
}

class _DraftMileageRateRowModel {
  _DraftMileageRateRowModel({
    String? startDate,
    String? rate,
    this.selectedVehicle,
  }) : startDateController = TextEditingController(text: startDate ?? ''),
       rateController = TextEditingController(text: rate ?? '');

  final TextEditingController startDateController;
  final TextEditingController rateController;
  String? selectedVehicle;

  void dispose() {
    startDateController.dispose();
    rateController.dispose();
  }
}

class ExpensesSettingsPage extends ConsumerStatefulWidget {
  const ExpensesSettingsPage({
    super.key,
    this.initialTab = ExpensesSettingsTab.preferences,
  });

  final ExpensesSettingsTab initialTab;

  @override
  ConsumerState<ExpensesSettingsPage> createState() =>
      _ExpensesSettingsPageState();
}

class _ExpensesSettingsPageState extends ConsumerState<ExpensesSettingsPage> {
  final ApiClient _apiClient = ApiClient();
  final SettingsPreferencesRepository _preferencesRepository =
      SettingsPreferencesRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late ExpensesSettingsTab _activeTab;
  final List<String> _accountOptions = [];
  String _selectedAccount = '';
  _DistanceUnit _distanceUnit = _DistanceUnit.km;
  final List<_MileageRateRow> _mileageRates = <_MileageRateRow>[];
  late final List<_DraftMileageRateRowModel> _draftMileageRows;
  int? _editingMileageRowIndex;
  _DraftMileageRateRowModel? _editingMileageRow;
  final List<_VehicleRow> _vehicleRows = <_VehicleRow>[];
  _VehicleDialogDraft? _vehicleDialogDraft;
  _VehicleDialogMode? _vehicleDialogDraftMode;
  int? _vehicleDialogDraftIndex;

  // Categories State
  final List<_CategoryRow> _categoryRows = <_CategoryRow>[];
  final Set<int> _selectedCategoryIndices = <int>{};
  String _categoryFilter = 'All';
  bool _categorySortAscending = true;

  // Category Dialog State
  _CategoryDialogMode? _categoryDialogMode;
  int? _categoryDialogIndex;
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _draftMileageRows = <_DraftMileageRateRowModel>[
      _DraftMileageRateRowModel(),
    ];
    _loadExpenseSettings();
  }

  Future<void> _loadExpenseSettings() async {
    try {
      final accountResponse = await _apiClient.get(
        'accountant',
        useCache: false,
      );
      final preferences = await _preferencesRepository.loadSection(
        'charges_preferences',
        const ['expenses'],
      );
      final accountNames = <String>[];
      void collect(dynamic rows) {
        if (rows is! List) return;
        for (final raw in rows.whereType<Map>()) {
          final row = Map<String, dynamic>.from(raw);
          final name =
              row['user_account_name'] ??
              row['system_account_name'] ??
              row['name'];
          if (name != null && name.toString().trim().isNotEmpty)
            accountNames.add(name.toString().trim());
          collect(row['children']);
        }
      }

      collect(accountResponse.data);
      if (!mounted) return;
      setState(() {
        _accountOptions
          ..clear()
          ..addAll(accountNames.toSet()..toList());
        _accountOptions.sort();
        _selectedAccount =
            preferences['default_mileage_account']?.toString() ??
            (_accountOptions.firstOrNull ?? '');
        _distanceUnit =
            _DistanceUnit.values
                .where((value) => value.name == preferences['distance_unit'])
                .firstOrNull ??
            _distanceUnit;
        _mileageRates
          ..clear()
          ..addAll(
            (preferences['mileage_rates'] as List? ?? const [])
                .whereType<Map>()
                .map(
                  (row) => _MileageRateRow(
                    startDate: row['start_date']?.toString() ?? '',
                    vehicle: row['vehicle']?.toString() ?? '',
                    rate: row['rate']?.toString() ?? '',
                  ),
                ),
          );
        _vehicleRows
          ..clear()
          ..addAll(
            (preferences['vehicles'] as List? ?? const []).whereType<Map>().map(
              (row) => _VehicleRow(
                name: row['name']?.toString() ?? '',
                hint: row['hint']?.toString() ?? '',
              ),
            ),
          );
        _categoryRows
          ..clear()
          ..addAll(
            (preferences['categories'] as List? ?? const [])
                .whereType<Map>()
                .map(
                  (row) => _CategoryRow(
                    name: row['name']?.toString() ?? '',
                    description: row['description']?.toString() ?? '',
                    isActive: row['is_active'] != false,
                  ),
                ),
          );
      });
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(context, 'Failed to load expense settings');
    }
  }

  Future<void> _persistExpenseSettings() => _preferencesRepository.saveSection(
    'charges_preferences',
    {
      'default_mileage_account': _selectedAccount,
      'distance_unit': _distanceUnit.name,
      'mileage_rates': _mileageRates
          .map(
            (row) => {
              'start_date': row.startDate,
              'vehicle': row.vehicle,
              'rate': row.rate,
            },
          )
          .toList(),
      'vehicles': _vehicleRows
          .map((row) => {'name': row.name, 'hint': row.hint})
          .toList(),
      'categories': _categoryRows
          .map(
            (row) => {
              'name': row.name,
              'description': row.description,
              'is_active': row.isActive,
            },
          )
          .toList(),
    },
    const ['expenses'],
  );

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    for (final row in _draftMileageRows) {
      row.dispose();
    }
    _editingMileageRow?.dispose();
    _vehicleDialogDraft?.dispose();
    _categoryNameController.dispose();
    _categoryDescController.dispose();
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    return '/$orgSystemId$route';
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  void _openTab(ExpensesSettingsTab tab) {
    final String route = switch (tab) {
      ExpensesSettingsTab.preferences => AppRoutes.settingsExpenses,
      ExpensesSettingsTab.vehicle => AppRoutes.settingsExpensesVehicle,
      ExpensesSettingsTab.categories => AppRoutes.settingsExpensesCategories,
      ExpensesSettingsTab.fields => AppRoutes.settingsExpensesFields,
    };

    if (_activeTab != tab) {
      setState(() => _activeTab = tab);
    }

    context.go(_withOrgPrefix(route));
  }

  _VehicleDialogMode? _currentVehicleDialogMode() {
    final String? rawMode = GoRouterState.of(
      context,
    ).uri.queryParameters['vehicleDialog'];
    return switch (rawMode) {
      'new' => _VehicleDialogMode.create,
      'edit' => _VehicleDialogMode.edit,
      _ => null,
    };
  }

  int? _currentVehicleDialogIndex() {
    final rawIndex = GoRouterState.of(
      context,
    ).uri.queryParameters['vehicleIndex'];
    return int.tryParse(rawIndex ?? '');
  }

  void _setVehicleDialogRoute({_VehicleDialogMode? mode, int? index}) {
    final Uri currentUri = GoRouterState.of(context).uri;
    final Map<String, String> queryParameters =
        Map<String, String>.from(currentUri.queryParameters)
          ..remove('vehicleDialog')
          ..remove('vehicleIndex');

    if (mode != null) {
      queryParameters['vehicleDialog'] = mode == _VehicleDialogMode.create
          ? 'new'
          : 'edit';
    }

    if (mode == _VehicleDialogMode.edit && index != null) {
      queryParameters['vehicleIndex'] = index.toString();
    }

    context.go(
      Uri(
        path: currentUri.path,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      ).toString(),
    );
  }

  _VehicleDialogDraft _ensureVehicleDialogDraft(
    _VehicleDialogMode mode,
    int? index,
  ) {
    if (_vehicleDialogDraft != null &&
        _vehicleDialogDraftMode == mode &&
        _vehicleDialogDraftIndex == index) {
      return _vehicleDialogDraft!;
    }

    _vehicleDialogDraft?.dispose();

    if (mode == _VehicleDialogMode.edit &&
        index != null &&
        index >= 0 &&
        index < _vehicleRows.length) {
      final vehicle = _vehicleRows[index];
      _vehicleDialogDraft = _VehicleDialogDraft(
        name: vehicle.name,
        hint: vehicle.hint,
      );
    } else {
      _vehicleDialogDraft = _VehicleDialogDraft();
    }

    _vehicleDialogDraftMode = mode;
    _vehicleDialogDraftIndex = index;
    return _vehicleDialogDraft!;
  }

  void _disposeVehicleDialogDraft() {
    _vehicleDialogDraft?.dispose();
    _vehicleDialogDraft = null;
    _vehicleDialogDraftMode = null;
    _vehicleDialogDraftIndex = null;
  }

  void _openNewVehicleDialog() {
    _disposeVehicleDialogDraft();
    _setVehicleDialogRoute(mode: _VehicleDialogMode.create);
  }

  void _openEditVehicleDialog(int index) {
    if (index < 0 || index >= _vehicleRows.length) return;
    _disposeVehicleDialogDraft();
    _setVehicleDialogRoute(mode: _VehicleDialogMode.edit, index: index);
  }

  void _closeVehicleDialog() {
    _disposeVehicleDialogDraft();
    _setVehicleDialogRoute();
  }

  void _saveVehicleDialog() {
    final _VehicleDialogMode? mode = _currentVehicleDialogMode();
    final _VehicleDialogDraft? draft = _vehicleDialogDraft;
    if (mode == null || draft == null) return;

    final String name = draft.nameController.text.trim();
    final String hint = draft.hintController.text.trim();

    if (name.isEmpty) {
      ZerpaiToast.info(context, 'Enter vehicle name before saving');
      return;
    }

    setState(() {
      if (mode == _VehicleDialogMode.edit) {
        final int? index = _currentVehicleDialogIndex();
        if (index != null && index >= 0 && index < _vehicleRows.length) {
          _vehicleRows[index] = _VehicleRow(name: name, hint: hint);
        }
      } else {
        _vehicleRows.add(_VehicleRow(name: name, hint: hint));
      }
    });

    _closeVehicleDialog();
    ZerpaiToast.success(
      context,
      mode == _VehicleDialogMode.edit
          ? 'Vehicle updated successfully'
          : 'Vehicle created successfully',
    );
    _persistExpenseSettings();
  }

  Future<void> _deleteVehicle(int index) async {
    if (index < 0 || index >= _vehicleRows.length) return;

    final bool confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Vehicle',
      message: 'This vehicle will be removed from the list.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );

    if (!confirmed || !mounted) return;

    final int? dialogIndex = _currentVehicleDialogIndex();
    final _VehicleDialogMode? dialogMode = _currentVehicleDialogMode();

    setState(() {
      _vehicleRows.removeAt(index);
    });

    if (dialogMode == _VehicleDialogMode.edit && dialogIndex == index) {
      _closeVehicleDialog();
    } else if (dialogMode == _VehicleDialogMode.edit &&
        dialogIndex != null &&
        dialogIndex > index) {
      _disposeVehicleDialogDraft();
      _setVehicleDialogRoute(
        mode: _VehicleDialogMode.edit,
        index: dialogIndex - 1,
      );
    }

    ZerpaiToast.success(context, 'Vehicle deleted successfully');
    await _persistExpenseSettings();
  }

  void _openNewCategoryDialog() {
    _categoryNameController.clear();
    _categoryDescController.clear();
    setState(() {
      _categoryDialogMode = _CategoryDialogMode.create;
      _categoryDialogIndex = null;
    });
  }

  void _openEditCategoryDialog(int index) {
    if (index < 0 || index >= _categoryRows.length) return;
    final cat = _categoryRows[index];
    _categoryNameController.text = cat.name;
    _categoryDescController.text = cat.description;
    setState(() {
      _categoryDialogMode = _CategoryDialogMode.edit;
      _categoryDialogIndex = index;
    });
  }

  void _closeCategoryDialog() {
    setState(() {
      _categoryDialogMode = null;
      _categoryDialogIndex = null;
    });
  }

  void _saveCategoryDialog() {
    final String name = _categoryNameController.text.trim();
    final String desc = _categoryDescController.text.trim();

    if (name.isEmpty) {
      ZerpaiToast.info(context, 'Enter category name before saving');
      return;
    }

    setState(() {
      if (_categoryDialogMode == _CategoryDialogMode.edit &&
          _categoryDialogIndex != null) {
        final idx = _categoryDialogIndex!;
        if (idx >= 0 && idx < _categoryRows.length) {
          _categoryRows[idx].name = name;
          _categoryRows[idx].description = desc;
        }
      } else {
        _categoryRows.add(_CategoryRow(name: name, description: desc));
      }
      _categoryDialogMode = null;
      _categoryDialogIndex = null;
    });

    ZerpaiToast.success(context, 'Category saved successfully');
    _persistExpenseSettings();
  }

  void _deleteCategory(int index) async {
    if (index < 0 || index >= _categoryRows.length) return;
    final bool confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Category',
      message: 'Are you sure you want to delete this category?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _categoryRows.removeAt(index);
      _selectedCategoryIndices.remove(index);
    });
    ZerpaiToast.success(context, 'Category deleted successfully');
    await _persistExpenseSettings();
  }

  void _toggleCategoryActive(int index) {
    if (index < 0 || index >= _categoryRows.length) return;
    setState(() {
      _categoryRows[index].isActive = !_categoryRows[index].isActive;
    });
    ZerpaiToast.success(
      context,
      _categoryRows[index].isActive
          ? 'Category marked as active'
          : 'Category marked as inactive',
    );
    _persistExpenseSettings();
  }

  void _toggleSelectAllCategories(bool? val) {
    setState(() {
      if (val == true) {
        for (int i = 0; i < _categoryRows.length; i++) {
          final cat = _categoryRows[i];
          if (_categoryFilter == 'All') {
            _selectedCategoryIndices.add(i);
          } else if (_categoryFilter == 'Active' && cat.isActive) {
            _selectedCategoryIndices.add(i);
          } else if (_categoryFilter == 'Inactive' && !cat.isActive) {
            _selectedCategoryIndices.add(i);
          }
        }
      } else {
        _selectedCategoryIndices.clear();
      }
    });
  }

  void _toggleSelectCategoryRow(int index, bool? val) {
    setState(() {
      if (val == true) {
        _selectedCategoryIndices.add(index);
      } else {
        _selectedCategoryIndices.remove(index);
      }
    });
  }

  void _bulkMarkActive() {
    setState(() {
      for (final idx in _selectedCategoryIndices) {
        if (idx >= 0 && idx < _categoryRows.length) {
          _categoryRows[idx].isActive = true;
        }
      }
      _selectedCategoryIndices.clear();
    });
    ZerpaiToast.success(context, 'Selected categories marked as active');
    _persistExpenseSettings();
  }

  void _bulkMarkInactive() {
    setState(() {
      for (final idx in _selectedCategoryIndices) {
        if (idx >= 0 && idx < _categoryRows.length) {
          _categoryRows[idx].isActive = false;
        }
      }
      _selectedCategoryIndices.clear();
    });
    ZerpaiToast.success(context, 'Selected categories marked as inactive');
    _persistExpenseSettings();
  }

  void _bulkDelete() async {
    final bool confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Categories',
      message: 'Are you sure you want to delete the selected categories?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      final sortedList = _selectedCategoryIndices.toList()
        ..sort((a, b) => b.compareTo(a));
      for (final idx in sortedList) {
        if (idx >= 0 && idx < _categoryRows.length) {
          _categoryRows.removeAt(idx);
        }
      }
      _selectedCategoryIndices.clear();
    });
    ZerpaiToast.success(context, 'Selected categories deleted');
    await _persistExpenseSettings();
  }

  void _sortCategories() {
    setState(() {
      _categorySortAscending = !_categorySortAscending;
      if (_categorySortAscending) {
        _categoryRows.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      } else {
        _categoryRows.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
      }
      _selectedCategoryIndices.clear();
    });
  }

  Future<void> _savePreferences() async {
    if (_editingMileageRowIndex != null && _editingMileageRow != null) {
      final String startDate = _editingMileageRow!.startDateController.text
          .trim();
      final String rate = _editingMileageRow!.rateController.text.trim();

      if (startDate.isEmpty || rate.isEmpty) {
        ZerpaiToast.info(
          context,
          'Complete start date and mileage rate before saving',
        );
        return;
      }
    }

    final List<_DraftMileageRateRowModel> completedRows =
        <_DraftMileageRateRowModel>[];

    for (final row in _draftMileageRows) {
      final String startDate = row.startDateController.text.trim();
      final String rate = row.rateController.text.trim();
      final String vehicle = row.selectedVehicle?.trim() ?? '';
      final bool isEmpty = startDate.isEmpty && rate.isEmpty && vehicle.isEmpty;

      if (isEmpty) {
        continue;
      }

      if (startDate.isEmpty || rate.isEmpty) {
        ZerpaiToast.info(
          context,
          'Complete start date and mileage rate before saving',
        );
        return;
      }

      completedRows.add(row);
    }

    if (completedRows.isEmpty) {
      try {
        await _persistExpenseSettings();
        if (mounted) ZerpaiToast.success(context, 'Expenses preferences saved');
      } catch (_) {
        if (mounted)
          ZerpaiToast.error(context, 'Failed to save expense settings');
      }
      return;
    }

    setState(() {
      if (_editingMileageRowIndex != null && _editingMileageRow != null) {
        final String normalizedRate = _editingMileageRow!.rateController.text
            .trim();
        _mileageRates[_editingMileageRowIndex!] = _MileageRateRow(
          startDate: _editingMileageRow!.startDateController.text.trim(),
          vehicle: _editingMileageRow!.selectedVehicle ?? '',
          rate: normalizedRate.startsWith('\u20B9')
              ? normalizedRate
              : '\u20B9$normalizedRate',
        );
        _editingMileageRow!.dispose();
        _editingMileageRow = null;
        _editingMileageRowIndex = null;
      }

      for (final row in completedRows) {
        final String normalizedRate = row.rateController.text.trim();
        _mileageRates.add(
          _MileageRateRow(
            startDate: row.startDateController.text.trim(),
            vehicle: row.selectedVehicle ?? '',
            rate: normalizedRate.startsWith('\u20B9')
                ? normalizedRate
                : '\u20B9$normalizedRate',
          ),
        );
      }

      for (final row in _draftMileageRows) {
        row.dispose();
      }
      _draftMileageRows
        ..clear()
        ..add(_DraftMileageRateRowModel());
    });

    try {
      await _persistExpenseSettings();
      if (mounted) ZerpaiToast.success(context, 'Expenses preferences saved');
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(context, 'Failed to save expense settings');
    }
  }

  void _clearDraftMileageRate(int index) {
    if (index < 0 || index >= _draftMileageRows.length) return;
    setState(() {
      if (_draftMileageRows.length == 1) {
        _draftMileageRows[index].startDateController.clear();
        _draftMileageRows[index].rateController.clear();
        _draftMileageRows[index].selectedVehicle = null;
      } else {
        final row = _draftMileageRows.removeAt(index);
        row.dispose();
      }
    });
  }

  void _updateDraftVehicle(int index, String? value) {
    if (index < 0 || index >= _draftMileageRows.length) return;
    setState(() {
      _draftMileageRows[index].selectedVehicle = value;
    });
  }

  void _startEditingMileageRow(int index) {
    if (index < 0 || index >= _mileageRates.length) return;

    final row = _mileageRates[index];
    setState(() {
      _editingMileageRow?.dispose();
      _editingMileageRowIndex = index;
      _editingMileageRow = _DraftMileageRateRowModel(
        startDate: row.startDate,
        rate: row.rate.replaceFirst('\u20B9', ''),
        selectedVehicle: row.vehicle.isEmpty ? null : row.vehicle,
      );
    });
  }

  void _updateEditingVehicle(String? value) {
    if (_editingMileageRow == null) return;
    setState(() {
      _editingMileageRow!.selectedVehicle = value;
    });
  }

  void _cancelEditingMileageRow() {
    setState(() {
      _editingMileageRow?.dispose();
      _editingMileageRow = null;
      _editingMileageRowIndex = null;
    });
  }

  void _deleteMileageRow(int index) {
    if (index < 0 || index >= _mileageRates.length) return;
    setState(() {
      _mileageRates.removeAt(index);
      if (_editingMileageRowIndex == index) {
        _editingMileageRow?.dispose();
        _editingMileageRow = null;
        _editingMileageRowIndex = null;
      } else if (_editingMileageRowIndex != null &&
          _editingMileageRowIndex! > index) {
        _editingMileageRowIndex = _editingMileageRowIndex! - 1;
      }
    });
  }

  void _addMileageRate() {
    setState(() {
      _draftMileageRows.add(_DraftMileageRateRowModel());
    });
  }

  Future<void> _openCreateAccountDialog() async {
    final TextEditingController accountNameController = TextEditingController();

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Create Account',
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 500,
              height: 218.64,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1F101828),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: _CreateAccountDialog(
                controller: accountNameController,
                onCancel: () => Navigator.of(dialogContext).pop(),
                onSave: () {
                  final String accountName = accountNameController.text.trim();
                  if (accountName.isEmpty) {
                    ZerpaiToast.info(
                      dialogContext,
                      'Enter account name before saving',
                    );
                    return;
                  }

                  setState(() {
                    if (!_accountOptions.contains(accountName)) {
                      _accountOptions.add(accountName);
                    }
                    _selectedAccount = accountName;
                  });

                  Navigator.of(dialogContext).pop();
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    accountNameController.dispose();
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return <SettingsSearchItem>[
      SettingsSearchItem(
        group: 'Purchase',
        label: 'Expenses',
        subtitle: 'Preferences',
        keywords: const <String>['mileage', 'default unit', 'account'],
        onSelected: () => _openTab(ExpensesSettingsTab.preferences),
      ),
      SettingsSearchItem(
        group: 'Purchase',
        label: 'Vehicle',
        subtitle: 'Expenses',
        keywords: const <String>['vehicle', 'mileage'],
        onSelected: () => _openTab(ExpensesSettingsTab.vehicle),
      ),
      SettingsSearchItem(
        group: 'Purchase',
        label: 'Categories',
        subtitle: 'Expenses',
        keywords: const <String>['categories', 'expenses'],
        onSelected: () => _openTab(ExpensesSettingsTab.categories),
      ),
      SettingsSearchItem(
        group: 'Purchase',
        label: 'Fields',
        subtitle: 'Expenses',
        keywords: const <String>['custom fields', 'expenses'],
        onSelected: () => _openTab(ExpensesSettingsTab.fields),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final String orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'ZERPAI ERP';
    final String currentPath = GoRouterState.of(context).uri.path;
    final _VehicleDialogMode? vehicleDialogMode = _currentVehicleDialogMode();
    final int? vehicleDialogIndex = _currentVehicleDialogIndex();
    _VehicleDialogDraft? vehicleDialogDraft;

    if (_activeTab == ExpensesSettingsTab.vehicle &&
        vehicleDialogMode != null) {
      if (vehicleDialogMode == _VehicleDialogMode.edit &&
          (vehicleDialogIndex == null ||
              vehicleDialogIndex < 0 ||
              vehicleDialogIndex >= _vehicleRows.length)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _closeVehicleDialog();
          }
        });
      } else {
        vehicleDialogDraft = _ensureVehicleDialogDraft(
          vehicleDialogMode,
          vehicleDialogIndex,
        );
      }
    } else if (_vehicleDialogDraft != null) {
      _disposeVehicleDialogDraft();
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): _focusSearch,
      },
      child: Stack(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                  child: _ExpensesSettingsHeader(
                    orgName: orgName,
                    searchController: _searchController,
                    searchFocusNode: _searchFocusNode,
                    searchItems: _buildSearchItems(),
                    onClose: () => context.go(_withOrgPrefix(AppRoutes.home)),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingsNavigationSidebar(currentPath: currentPath),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              left: BorderSide(color: AppTheme.borderLight),
                              top: BorderSide(color: AppTheme.borderLight),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    8,
                                    18,
                                    0,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Expenses',
                                        style: AppTheme.pageTitle.copyWith(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      _buildHeaderActionBtn(),
                                    ],
                                  ),
                                ),
                                _ExpensesTabBar(
                                  activeTab: _activeTab,
                                  onTabSelected: _openTab,
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: AppTheme.borderLight,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      (_activeTab ==
                                                  ExpensesSettingsTab
                                                      .categories ||
                                              _activeTab ==
                                                  ExpensesSettingsTab.vehicle)
                                          ? 0
                                          : 18,
                                      (_activeTab ==
                                                  ExpensesSettingsTab
                                                      .categories ||
                                              _activeTab ==
                                                  ExpensesSettingsTab.vehicle)
                                          ? 0
                                          : 18,
                                      (_activeTab ==
                                                  ExpensesSettingsTab
                                                      .categories ||
                                              _activeTab ==
                                                  ExpensesSettingsTab.vehicle)
                                          ? 0
                                          : 18,
                                      24,
                                    ),
                                    child: _buildActiveTabContent(),
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
              ],
            ),
          ),
          if (_activeTab == ExpensesSettingsTab.vehicle &&
              vehicleDialogMode != null &&
              vehicleDialogDraft != null)
            Positioned.fill(
              child: _VehicleDialogOverlay(
                mode: vehicleDialogMode,
                draft: vehicleDialogDraft,
                onSave: _saveVehicleDialog,
                onCancel: _closeVehicleDialog,
              ),
            ),
          if (_activeTab == ExpensesSettingsTab.categories &&
              _categoryDialogMode != null)
            Positioned.fill(
              child: _CategoryDialogOverlay(
                mode: _categoryDialogMode!,
                nameController: _categoryNameController,
                descriptionController: _categoryDescController,
                onSave: _saveCategoryDialog,
                onCancel: _closeCategoryDialog,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionBtn() {
    return switch (_activeTab) {
      ExpensesSettingsTab.preferences => const SizedBox.shrink(),
      ExpensesSettingsTab.fields => const SizedBox.shrink(),
      ExpensesSettingsTab.vehicle => SizedBox(
        height: 28,
        child: ElevatedButton(
          onPressed: _openNewVehicleDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                'New Vehicle',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      ExpensesSettingsTab.categories =>
        _selectedCategoryIndices.isNotEmpty
            ? const SizedBox.shrink()
            : SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: _openNewCategoryDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'New Category',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    };
  }

  Widget _buildActiveTabContent() {
    return switch (_activeTab) {
      ExpensesSettingsTab.preferences => _ExpensesPreferencesContent(
        accountOptions: _accountOptions,
        selectedAccount: _selectedAccount,
        onAccountChanged: (String? value) {
          if (value == null) return;
          setState(() => _selectedAccount = value);
        },
        onCreateAccount: _openCreateAccountDialog,
        distanceUnit: _distanceUnit,
        onUnitChanged: (_DistanceUnit? value) {
          if (value == null) return;
          setState(() => _distanceUnit = value);
        },
        mileageRates: _mileageRates,
        vehicleOptions: _vehicleRows.map((row) => row.name).toList(),
        editingMileageRowIndex: _editingMileageRowIndex,
        editingMileageRow: _editingMileageRow,
        onEditMileageRow: _startEditingMileageRow,
        onDeleteMileageRow: _deleteMileageRow,
        onEditingVehicleChanged: _updateEditingVehicle,
        onCancelEditingMileageRow: _cancelEditingMileageRow,
        draftMileageRows: _draftMileageRows,
        onDraftVehicleChanged: _updateDraftVehicle,
        onClearDraftRow: _clearDraftMileageRate,
        onAddMileageRate: _addMileageRate,
        onSave: _savePreferences,
      ),
      ExpensesSettingsTab.vehicle => _ExpensesVehicleContent(
        vehicles: _vehicleRows,
        onCreate: _openNewVehicleDialog,
        onEdit: _openEditVehicleDialog,
        onDelete: _deleteVehicle,
      ),
      ExpensesSettingsTab.categories => _ExpensesCategoriesContent(
        categories: _categoryRows,
        selectedIndices: _selectedCategoryIndices,
        onToggleSelectAll: _toggleSelectAllCategories,
        onToggleSelectRow: _toggleSelectCategoryRow,
        onToggleActive: _toggleCategoryActive,
        onEdit: _openEditCategoryDialog,
        onDelete: _deleteCategory,
        onCreate: _openNewCategoryDialog,
        onBulkMarkActive: _bulkMarkActive,
        onBulkMarkInactive: _bulkMarkInactive,
        onBulkDelete: _bulkDelete,
        sortAscending: _categorySortAscending,
        onSort: _sortCategories,
        filter: _categoryFilter,
        onFilterChanged: (String val) {
          setState(() {
            _categoryFilter = val;
            _selectedCategoryIndices.clear();
          });
        },
      ),
      ExpensesSettingsTab.fields => const _ExpensesEmptyState(
        title: 'Fields',
        message: 'Custom fields are not configured yet.',
      ),
    };
  }
}

class _ExpensesSettingsHeader extends StatelessWidget {
  const _ExpensesSettingsHeader({
    required this.orgName,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchItems,
    required this.onClose,
  });

  final String orgName;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<SettingsSearchItem> searchItems;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SettingsHeaderIdentity(orgName: orgName),
        const Spacer(),
        SizedBox(
          width: 320,
          child: SettingsSearchField(
            controller: searchController,
            focusNode: searchFocusNode,
            items: searchItems,
            onNoMatch: (String query) {
              ZerpaiToast.info(context, 'No settings matched "$query"');
            },
          ),
        ),
        const SizedBox(width: 14),
        _CloseSettingsButton(onTap: onClose),
      ],
    );
  }
}

class _SettingsHeaderIdentity extends StatelessWidget {
  const _SettingsHeaderIdentity({required this.orgName});

  final String orgName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4F3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.menu_book_outlined,
            size: 20,
            color: Color(0xFFFF5C5C),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Settings',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              orgName,
              style: AppTheme.bodyText.copyWith(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CloseSettingsButton extends StatelessWidget {
  const _CloseSettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Close Settings',
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.close, size: 15, color: Color(0xFFFF5C73)),
          ],
        ),
      ),
    );
  }
}

class _ExpensesTabBar extends StatelessWidget {
  const _ExpensesTabBar({required this.activeTab, required this.onTabSelected});

  final ExpensesSettingsTab activeTab;
  final ValueChanged<ExpensesSettingsTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    const List<(String, ExpensesSettingsTab)> tabs =
        <(String, ExpensesSettingsTab)>[
          ('Preferences', ExpensesSettingsTab.preferences),
          ('Vehicle', ExpensesSettingsTab.vehicle),
          ('Categories', ExpensesSettingsTab.categories),
          ('Fields', ExpensesSettingsTab.fields),
        ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: Row(
        children: [
          for (final (String label, ExpensesSettingsTab tab) in tabs)
            _ExpensesTabButton(
              label: label,
              isActive: activeTab == tab,
              onTap: () => onTabSelected(tab),
            ),
        ],
      ),
    );
  }
}

class _ExpensesTabButton extends StatelessWidget {
  const _ExpensesTabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        margin: const EdgeInsets.only(right: 26),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 15,
            color: isActive ? AppTheme.textPrimary : const Color(0xFF667085),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ExpensesPreferencesContent extends StatelessWidget {
  const _ExpensesPreferencesContent({
    required this.accountOptions,
    required this.selectedAccount,
    required this.onAccountChanged,
    required this.onCreateAccount,
    required this.distanceUnit,
    required this.onUnitChanged,
    required this.mileageRates,
    required this.vehicleOptions,
    required this.editingMileageRowIndex,
    required this.editingMileageRow,
    required this.onEditMileageRow,
    required this.onDeleteMileageRow,
    required this.onEditingVehicleChanged,
    required this.onCancelEditingMileageRow,
    required this.draftMileageRows,
    required this.onDraftVehicleChanged,
    required this.onClearDraftRow,
    required this.onAddMileageRate,
    required this.onSave,
  });

  final List<String> accountOptions;
  final String selectedAccount;
  final ValueChanged<String?> onAccountChanged;
  final VoidCallback onCreateAccount;
  final _DistanceUnit distanceUnit;
  final ValueChanged<_DistanceUnit?> onUnitChanged;
  final List<_MileageRateRow> mileageRates;
  final List<String> vehicleOptions;
  final int? editingMileageRowIndex;
  final _DraftMileageRateRowModel? editingMileageRow;
  final ValueChanged<int> onEditMileageRow;
  final ValueChanged<int> onDeleteMileageRow;
  final ValueChanged<String?> onEditingVehicleChanged;
  final VoidCallback onCancelEditingMileageRow;
  final List<_DraftMileageRateRowModel> draftMileageRows;
  final void Function(int index, String? value) onDraftVehicleChanged;
  final ValueChanged<int> onClearDraftRow;
  final VoidCallback onAddMileageRate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsFormRow(
          label: 'Default Mileage Account',
          child: SizedBox(
            width: 206,
            child: FormDropdown<String>(
              value: selectedAccount,
              items: accountOptions,
              onChanged: onAccountChanged,
              displayStringForValue: (String value) => value,
              showSearch: true,
              menuMaxHeight: 280,
              showSettings: true,
              settingsLabel: 'New Account',
              settingsLeading: const _BlueFilledPlusIcon(),
              onSettingsTap: onCreateAccount,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsFormRow(
          label: 'Default Unit',
          child: Row(
            children: [
              _UnitRadio(
                value: _DistanceUnit.km,
                groupValue: distanceUnit,
                label: 'Km',
                onChanged: onUnitChanged,
              ),
              const SizedBox(width: 14),
              _UnitRadio(
                value: _DistanceUnit.mile,
                groupValue: distanceUnit,
                label: 'Mile',
                onChanged: onUnitChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'MILEAGE RATES',
          style: AppTheme.bodyText.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 820,
          child: Text(
            'Any mileage expense recorded on or after the start date will '
            'have the corresponding mileage rate. You can create a default '
            'rate (created without specifying a date), which will be '
            'applicable for mileage expenses recorded before the initial '
            'start date.',
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF707A94),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _MileageRatesTable(
          rows: mileageRates,
          vehicleOptions: vehicleOptions,
          editingRowIndex: editingMileageRowIndex,
          editingRow: editingMileageRow,
          onEdit: onEditMileageRow,
          onDelete: onDeleteMileageRow,
          onEditingVehicleChanged: onEditingVehicleChanged,
          onCancelEditing: onCancelEditingMileageRow,
        ),
        const SizedBox(height: 16),
        for (int index = 0; index < draftMileageRows.length; index++) ...[
          _MileageRateDraftRow(
            vehicleOptions: vehicleOptions,
            startDateController: draftMileageRows[index].startDateController,
            selectedVehicle: draftMileageRows[index].selectedVehicle,
            onVehicleChanged: (String? value) =>
                onDraftVehicleChanged(index, value),
            rateController: draftMileageRows[index].rateController,
            onClear: () => onClearDraftRow(index),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppTheme.borderLight),
        const SizedBox(height: 10),
        InkWell(
          onTap: onAddMileageRate,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BlueFilledPlusIcon(),
                const SizedBox(width: 6),
                Text(
                  'Add Mileage Rate',
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.primaryBlue,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Divider(height: 1, color: AppTheme.borderLight),
        const SizedBox(height: 18),
        SizedBox(
          height: 34,
          child: ZButton.primary(
            label: 'Save',
            onPressed: onSave,
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
        ),
      ],
    );
  }
}

class _BlueFilledPlusIcon extends StatelessWidget {
  const _BlueFilledPlusIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlueDark,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add, size: 12, color: Colors.white),
    );
  }
}

class _CreateAccountDialog extends StatelessWidget {
  const _CreateAccountDialog({
    required this.controller,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Row(
            children: [
              Text(
                'Create Account',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onCancel,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 20, color: Color(0xFFFF4D4F)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 162,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Account Name*',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        color: const Color(0xFFFF3B30),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: CustomTextField(
                      controller: controller,
                      autoFocus: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            children: [
              SizedBox(
                height: 36,
                child: ZButton.primary(
                  label: 'Save and Select',
                  onPressed: onSave,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 36,
                child: ZButton.secondary(
                  label: 'Cancel',
                  onPressed: onCancel,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsFormRow extends StatelessWidget {
  const _SettingsFormRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 226,
          child: Text(label, style: AppTheme.bodyText.copyWith(fontSize: 14)),
        ),
        child,
      ],
    );
  }
}

class _UnitRadio extends StatelessWidget {
  const _UnitRadio({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
  });

  final _DistanceUnit value;
  final _DistanceUnit groupValue;
  final String label;
  final ValueChanged<_DistanceUnit?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 1,
            child: Radio<_DistanceUnit>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primaryBlue;
                }
                return const Color(0xFF4B5563);
              }),
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
          ),
          Text(label, style: AppTheme.bodyText.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}

class _MileageRatesTable extends StatefulWidget {
  const _MileageRatesTable({
    required this.rows,
    required this.vehicleOptions,
    required this.editingRowIndex,
    required this.editingRow,
    required this.onEdit,
    required this.onDelete,
    required this.onEditingVehicleChanged,
    required this.onCancelEditing,
  });

  final List<_MileageRateRow> rows;
  final List<String> vehicleOptions;
  final int? editingRowIndex;
  final _DraftMileageRateRowModel? editingRow;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final ValueChanged<String?> onEditingVehicleChanged;
  final VoidCallback onCancelEditing;

  @override
  State<_MileageRatesTable> createState() => _MileageRatesTableState();
}

class _MileageRatesTableState extends State<_MileageRatesTable> {
  int? _hoveredRowIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 900,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF5F7FB),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: const Row(
              children: [
                _TableHeaderCell(width: 170, label: 'START DATE'),
                _TableHeaderCell(width: 170, label: 'VEHICLE'),
                _TableHeaderCell(width: 170, label: 'MILEAGE RATE'),
              ],
            ),
          ),
          for (int index = 0; index < widget.rows.length; index++)
            widget.editingRowIndex == index && widget.editingRow != null
                ? Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    child: _MileageRateDraftRow(
                      vehicleOptions: widget.vehicleOptions,
                      startDateController:
                          widget.editingRow!.startDateController,
                      selectedVehicle: widget.editingRow!.selectedVehicle,
                      onVehicleChanged: widget.onEditingVehicleChanged,
                      rateController: widget.editingRow!.rateController,
                      onClear: widget.onCancelEditing,
                    ),
                  )
                : MouseRegion(
                    onEnter: (_) => setState(() => _hoveredRowIndex = index),
                    onExit: (_) => setState(() => _hoveredRowIndex = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _hoveredRowIndex == index
                            ? const Color(0xFFF7F8FC)
                            : Colors.transparent,
                        border: const Border(
                          bottom: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          _TableValueCell(
                            width: 170,
                            value: widget.rows[index].startDate,
                          ),
                          _TableValueCell(
                            width: 170,
                            value: widget.rows[index].vehicle,
                          ),
                          _TableValueCell(
                            width: 170,
                            value: widget.rows[index].rate,
                          ),
                          Expanded(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 120),
                              opacity: _hoveredRowIndex == index ? 1 : 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                    onTap: () => widget.onEdit(index),
                                    hoverColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    child: Text(
                                      'Edit',
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 14,
                                        color: const Color(0xFF1E2432),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => widget.onDelete(index),
                                    hoverColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    child: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Color(0xFF1E2432),
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
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell({required this.width, required this.label});

  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: AppTheme.captionText.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF697694),
        ),
      ),
    );
  }
}

class _TableValueCell extends StatelessWidget {
  const _TableValueCell({required this.width, required this.value});

  final double width;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: AppTheme.bodyText.copyWith(
          fontSize: 15,
          color: const Color(0xFF1E2432),
        ),
      ),
    );
  }
}

class _CurrencyInputField extends StatelessWidget {
  const _CurrencyInputField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      child: CustomTextField(
        controller: controller,
        hintText: '',
        height: 36,
        forceUppercase: false,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          NumericOnlyFormatter(allowDecimal: true),
        ],
        prefixWidget: Container(
          width: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Text(
            'INR',
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: const Color(0xFF384152),
            ),
          ),
        ),
        prefixBox: true,
      ),
    );
  }
}

class _MileageRateDraftRow extends StatefulWidget {
  const _MileageRateDraftRow({
    required this.startDateController,
    required this.vehicleOptions,
    required this.selectedVehicle,
    required this.onVehicleChanged,
    required this.rateController,
    required this.onClear,
  });

  final TextEditingController startDateController;
  final List<String> vehicleOptions;
  final String? selectedVehicle;
  final ValueChanged<String?> onVehicleChanged;
  final TextEditingController rateController;
  final VoidCallback onClear;

  @override
  State<_MileageRateDraftRow> createState() => _MileageRateDraftRowState();
}

class _MileageRateDraftRowState extends State<_MileageRateDraftRow> {
  bool _isHovered = false;
  final GlobalKey _dateFieldKey = GlobalKey();

  Future<void> _pickDate() async {
    final String raw = widget.startDateController.text.trim();
    final DateTime now = DateTime.now();
    DateTime initialDate = now;

    final parts = raw.split('-');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        initialDate = DateTime(year, month, day);
      }
    }

    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      targetKey: _dateFieldKey,
    );

    if (!mounted || picked == null) return;

    final dd = picked.day.toString().padLeft(2, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    final yyyy = picked.year.toString();
    widget.startDateController.text = '$dd-$mm-$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 900,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        color: Colors.transparent,
        child: Row(
          children: [
            SizedBox(
              width: 124,
              child: Container(
                key: _dateFieldKey,
                child: CustomTextField(
                  controller: widget.startDateController,
                  hintText: 'dd-MM-yyyy',
                  height: 36,
                  fillColor: Colors.white,
                  forceUppercase: false,
                  readOnly: true,
                  onTap: _pickDate,
                  suffixWidget: InkWell(
                    onTap: _pickDate,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Color(0xFF7C859A),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 44),
            SizedBox(
              width: 124,
              child: FormDropdown<String>(
                value: widget.selectedVehicle,
                items: widget.vehicleOptions,
                hint: '',
                onChanged: widget.onVehicleChanged,
                displayStringForValue: (String value) => value,
                menuMaxHeight: 220,
              ),
            ),
            const SizedBox(width: 44),
            _CurrencyInputField(controller: widget.rateController),
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _isHovered ? 1 : 0,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: widget.onClear,
                    borderRadius: BorderRadius.circular(10),
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF9AA3B8)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: Color(0xFF7C859A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesEmptyState extends StatelessWidget {
  const _ExpensesEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.pageTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensesVehicleContent extends StatefulWidget {
  const _ExpensesVehicleContent({
    required this.vehicles,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final List<_VehicleRow> vehicles;
  final VoidCallback onCreate;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  State<_ExpensesVehicleContent> createState() =>
      _ExpensesVehicleContentState();
}

class _ExpensesVehicleContentState extends State<_ExpensesVehicleContent> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.borderLight),
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: Column(
            children: [
              Container(
                color: const Color(0xFFF7F8FC),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: _VehicleHeaderText(label: 'VEHICLE NAME'),
                    ),
                    Expanded(flex: 5, child: _VehicleHeaderText(label: 'HINT')),
                    SizedBox(width: 80),
                  ],
                ),
              ),
              for (int index = 0; index < widget.vehicles.length; index++)
                MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = index),
                  onExit: (_) {
                    if (_hoveredIndex == index) {
                      setState(() => _hoveredIndex = null);
                    }
                  },
                  child: Material(
                    color: _hoveredIndex == index
                        ? const Color(0xFFF8FAFF)
                        : Colors.white,
                    child: InkWell(
                      onTap: () => widget.onEdit(index),
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.borderLight),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: Text(
                                widget.vehicles[index].name,
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF2563EB),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text(
                                widget.vehicles[index].hint,
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 120),
                                opacity: _hoveredIndex == index ? 1 : 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () => widget.onEdit(index),
                                      hoverColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      child: Text(
                                        'Edit',
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                          color: const Color(0xFF475467),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 1,
                                      height: 12,
                                      color: const Color(0xFFD0D5DD),
                                    ),
                                    const SizedBox(width: 4),
                                    _VehicleActionIcon(
                                      icon: Icons.delete_outline,
                                      onTap: () => widget.onDelete(index),
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
      ],
    );
  }
}

class _VehicleHeaderText extends StatelessWidget {
  const _VehicleHeaderText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTheme.captionText.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF67728A),
      ),
    );
  }
}

class _VehicleActionIcon extends StatelessWidget {
  const _VehicleActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: const Color(0x112563EB),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(icon, size: 15, color: const Color(0xFF475467)),
        ),
      ),
    );
  }
}

class _VehicleDialogOverlay extends StatelessWidget {
  const _VehicleDialogOverlay({
    required this.mode,
    required this.draft,
    required this.onSave,
    required this.onCancel,
  });

  final _VehicleDialogMode mode;
  final _VehicleDialogDraft draft;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final String title = mode == _VehicleDialogMode.create
        ? 'New Vehicle'
        : 'Edit Vehicle';

    return Material(
      color: const Color(0x73000000),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 560,
          height: 245,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x1F101828),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: AppTheme.pageTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onCancel,
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 18, 40, 14),
                  child: Column(
                    children: [
                      _VehicleDialogFieldRow(
                        label: 'Vehicle Name*',
                        labelColor: const Color(0xFFE53935),
                        field: SizedBox(
                          width: 300,
                          child: CustomTextField(
                            controller: draft.nameController,
                            height: 34,
                            fillColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _VehicleDialogFieldRow(
                        label: 'Hint\n(Max 50 chars)',
                        labelColor: const Color(0xFF667085),
                        field: SizedBox(
                          width: 300,
                          child: CustomTextField(
                            controller: draft.hintController,
                            height: 52,
                            maxLines: 2,
                            fillColor: Colors.white,
                            forceUppercase: false,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            inputFormatters: <TextInputFormatter>[
                              LengthLimitingTextInputFormatter(50),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Row(
                  children: [
                    SizedBox(
                      height: 32,
                      child: ZButton.primary(
                        label: 'Save',
                        onPressed: onSave,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 32,
                      child: ZButton.secondary(
                        label: 'Cancel',
                        onPressed: onCancel,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
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

class _VehicleDialogFieldRow extends StatelessWidget {
  const _VehicleDialogFieldRow({
    required this.label,
    required this.labelColor,
    required this.field,
  });

  final String label;
  final Color labelColor;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: labelColor,
                height: 1.45,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        field,
      ],
    );
  }
}

class _ExpensesCategoriesContent extends StatefulWidget {
  const _ExpensesCategoriesContent({
    required this.categories,
    required this.selectedIndices,
    required this.onToggleSelectAll,
    required this.onToggleSelectRow,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
    required this.onCreate,
    required this.onBulkMarkActive,
    required this.onBulkMarkInactive,
    required this.onBulkDelete,
    required this.sortAscending,
    required this.onSort,
    required this.filter,
    required this.onFilterChanged,
  });

  final List<_CategoryRow> categories;
  final Set<int> selectedIndices;
  final ValueChanged<bool?> onToggleSelectAll;
  final void Function(int index, bool? selected) onToggleSelectRow;
  final ValueChanged<int> onToggleActive;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final VoidCallback onCreate;
  final VoidCallback onBulkMarkActive;
  final VoidCallback onBulkMarkInactive;
  final VoidCallback onBulkDelete;
  final bool sortAscending;
  final VoidCallback onSort;
  final String filter;
  final ValueChanged<String> onFilterChanged;

  @override
  State<_ExpensesCategoriesContent> createState() =>
      _ExpensesCategoriesContentState();
}

class _ExpensesCategoriesContentState
    extends State<_ExpensesCategoriesContent> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final List<(int, _CategoryRow)> displayedCategories = [];
    for (int i = 0; i < widget.categories.length; i++) {
      final cat = widget.categories[i];
      if (widget.filter == 'All') {
        displayedCategories.add((i, cat));
      } else if (widget.filter == 'Active' && cat.isActive) {
        displayedCategories.add((i, cat));
      } else if (widget.filter == 'Inactive' && !cat.isActive) {
        displayedCategories.add((i, cat));
      }
    }

    final bool isAllSelected =
        displayedCategories.isNotEmpty &&
        displayedCategories.every(
          (item) => widget.selectedIndices.contains(item.$1),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: widget.selectedIndices.isNotEmpty
              ? Row(
                  children: [
                    SizedBox(
                      height: 28,
                      child: OutlinedButton(
                        onPressed: widget.onBulkMarkActive,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(
                          'Mark as Active',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 28,
                      child: OutlinedButton(
                        onPressed: widget.onBulkMarkInactive,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(
                          'Mark as Inactive',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 28,
                      width: 28,
                      child: OutlinedButton(
                        onPressed: widget.onBulkDelete,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 15,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _CategoryFilterDropdown(
                      currentFilter: widget.filter,
                      onFilterChanged: widget.onFilterChanged,
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.borderLight),
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: Column(
            children: [
              Container(
                color: const Color(0xFFF7F8FC),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Transform.scale(
                        scale: 0.85,
                        child: Checkbox(
                          value: isAllSelected,
                          onChanged: widget.onToggleSelectAll,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                          side: const BorderSide(
                            color: Color(0xFFD1D5DB),
                            width: 1.5,
                          ),
                          fillColor: WidgetStateProperty.resolveWith<Color>((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return AppTheme.primaryBlue;
                            }
                            return Colors.white;
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: InkWell(
                        onTap: widget.onSort,
                        child: Row(
                          children: [
                            Text(
                              'CATEGORY NAME',
                              style: AppTheme.captionText.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF67728A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 10,
                                  color: widget.sortAscending
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF9CA3AF),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -4),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 10,
                                    color: !widget.sortAscending
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: Text(
                        'DESCRIPTION',
                        style: AppTheme.captionText.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF67728A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 160),
                  ],
                ),
              ),
              if (displayedCategories.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: Text(
                    'No categories found.',
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                for (final (int actualIndex, _CategoryRow category)
                    in displayedCategories)
                  MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = actualIndex),
                    onExit: (_) {
                      if (_hoveredIndex == actualIndex) {
                        setState(() => _hoveredIndex = null);
                      }
                    },
                    child: Material(
                      color: _hoveredIndex == actualIndex
                          ? const Color(0xFFF8FAFF)
                          : Colors.white,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.borderLight),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Transform.scale(
                                scale: 0.85,
                                child: Checkbox(
                                  value: widget.selectedIndices.contains(
                                    actualIndex,
                                  ),
                                  onChanged: (bool? val) => widget
                                      .onToggleSelectRow(actualIndex, val),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                    width: 1.5,
                                  ),
                                  fillColor:
                                      WidgetStateProperty.resolveWith<Color>((
                                        states,
                                      ) {
                                        if (states.contains(
                                          WidgetState.selected,
                                        )) {
                                          return AppTheme.primaryBlue;
                                        }
                                        return Colors.white;
                                      }),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: InkWell(
                                onTap: () => widget.onEdit(actualIndex),
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                child: Text(
                                  category.name,
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                    color: category.isActive
                                        ? const Color(0xFF1F2937)
                                        : const Color(0xFF9CA3AF),
                                    decoration: TextDecoration.none,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 8,
                              child: InkWell(
                                onTap: () => widget.onEdit(actualIndex),
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                child: Text(
                                  category.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                    color: category.isActive
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 160,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 120),
                                opacity: _hoveredIndex == actualIndex ? 1 : 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          widget.onToggleActive(actualIndex),
                                      hoverColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      child: Text(
                                        category.isActive
                                            ? 'Mark as Inactive'
                                            : 'Mark as Active',
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 12,
                                          color: const Color(0xFF1F2937),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 1,
                                      height: 10,
                                      color: const Color(0xFFD0D5DD),
                                    ),
                                    const SizedBox(width: 4),
                                    _VehicleActionIcon(
                                      icon: Icons.delete_outline,
                                      onTap: () => widget.onDelete(actualIndex),
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
            ],
          ),
        ),
      ],
    );
  }
}

class _DropdownItemWidget extends StatefulWidget {
  const _DropdownItemWidget({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  State<_DropdownItemWidget> createState() => _DropdownItemWidgetState();
}

class _DropdownItemWidgetState extends State<_DropdownItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (_isHovered) {
      backgroundColor = const Color(0xFF3B82F6); // Blue hover
      textColor = Colors.white;
    } else if (widget.isSelected) {
      backgroundColor = const Color(0xFFF3F4F6); // Grey selected
      textColor = const Color(0xFF1F2937);
    } else {
      backgroundColor = Colors.white;
      textColor = const Color(0xFF374151);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: double.infinity,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterDropdown extends StatelessWidget {
  const _CategoryFilterDropdown({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onFilterChanged,
      offset: const Offset(0, 28),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'All',
          padding: EdgeInsets.zero,
          height: 36,
          child: _DropdownItemWidget(
            label: 'All',
            isSelected: currentFilter == 'All',
          ),
        ),
        PopupMenuItem<String>(
          value: 'Active',
          padding: EdgeInsets.zero,
          height: 36,
          child: _DropdownItemWidget(
            label: 'Active',
            isSelected: currentFilter == 'Active',
          ),
        ),
        PopupMenuItem<String>(
          value: 'Inactive',
          padding: EdgeInsets.zero,
          height: 36,
          child: _DropdownItemWidget(
            label: 'Inactive',
            isSelected: currentFilter == 'Inactive',
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentFilter,
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Color(0xFF2563EB),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDialogOverlay extends StatelessWidget {
  const _CategoryDialogOverlay({
    required this.mode,
    required this.nameController,
    required this.descriptionController,
    required this.onSave,
    required this.onCancel,
  });

  final _CategoryDialogMode mode;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final String title = mode == _CategoryDialogMode.create
        ? 'New Category'
        : 'Edit Category';

    return Material(
      color: const Color(0x73000000),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 600,
          height: 370.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x1F101828),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: AppTheme.pageTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onCancel,
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFFFF3B30),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Name*',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFFE53935),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CustomTextField(
                        controller: nameController,
                        height: 36,
                        fillColor: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          CustomTextField(
                            controller: descriptionController,
                            hintText: 'Max. 500 characters',
                            maxLines: 5,
                            height: 100,
                            fillColor: Colors.white,
                            forceUppercase: false,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(500),
                            ],
                          ),
                          const Positioned(
                            right: 6,
                            bottom: 6,
                            child: Icon(
                              Icons.filter_list,
                              size: 10,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 32,
                      width: 70,
                      child: ElevatedButton(
                        onPressed: onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Save',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 32,
                      width: 70,
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF374151),
                          ),
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
