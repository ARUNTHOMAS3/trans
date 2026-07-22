import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

import 'package:zerpai_erp/modules/settings/record_locking/lock_configuration/presentation/providers/lock_configuration_provider.dart';

class LockConfigurationCreatePage extends ConsumerStatefulWidget {
  const LockConfigurationCreatePage({super.key});

  @override
  ConsumerState<LockConfigurationCreatePage> createState() =>
      _LockConfigurationCreatePageState();
}

class _LockConfigurationCreatePageState
    extends ConsumerState<LockConfigurationCreatePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _didLoadInitialRecord = false;
  int? _editingIndex;
  String _currentStatus = 'Active';
  String? _selectedModule;
  String? _selectedAction;
  String? _selectedFieldAction;
  String? _selectedLockRecordsFor;
  List<String> _selectedRestrictedActions = <String>[];
  List<String> _selectedFields = <String>[];
  List<String> _selectedRoles = <String>[];

  static const List<String> _moduleOptions = [
    'Invoice',
    'Sales Order',
    'Purchase Order',
    'Vendor Payment',
    'Customer Payment',
    'Credit Note',
    'Retainer Invoice',
    'Delivery Challan',
    'Bill Of Supply',
    'Self-Invoice',
  ];

  static const List<String> _allowOrRestrictActionOptions = [
    'Restrict All Actions',
    'Restrict Selected Actions',
    'Allow Selected Actions',
    'Allow All Actions',
  ];

  static const List<String> _lockRecordsForOptions = [
    'All Roles',
    'All Roles Except',
  ];

  static const List<String> _allowOrRestrictFieldOptions = [
    'Restrict All Fields',
    'Restrict Selected Fields',
    'Allow Selected Fields',
    'Allow All Fields',
  ];

  static const List<String> _restrictedActionOptions = [
    'Default',
    'Edit',
    'Delete',
    'Void',
    'Send Mail',
    'Write Off',
    'Cancel Write Off',
  ];

  static const List<String> _fieldSelectionOptions = [
    'Customer Name',
    'Status',
    'Reference Number',
    'Amount',
    'Due Date',
    'Notes',
  ];

  static const String _zohoBooksRolesHeading = 'Zoho Books - Roles';
  static const String _zohoBillingRolesHeading = 'Zoho Billing - Roles';

  @override
  void initState() {
    super.initState();
    _selectedModule = _moduleOptions.first;
    _selectedAction = 'Restrict All Actions';
    _selectedFieldAction = _allowOrRestrictFieldOptions.first;
    _selectedLockRecordsFor = _lockRecordsForOptions.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
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

  List<String> _availableItems(
    List<String> items,
    List<String> selectedValues,
  ) {
    return items.where((item) => !selectedValues.contains(item)).toList();
  }

  List<String> _availableRoleItems() {
    final zohoBooksRoles = <String>[
      'Zoho Books - Admin',
      'Zoho Books - Staff',
      'Zoho Books - Staff (Assigned Customers Only)',
      'Zoho Books - TimesheetStaff',
    ].where((item) => !_selectedRoles.contains(item)).toList();

    final zohoBillingRoles = <String>[
      'Zoho Billing - Admin',
    ].where((item) => !_selectedRoles.contains(item)).toList();

    return <String>[
      if (zohoBooksRoles.isNotEmpty) _zohoBooksRolesHeading,
      ...zohoBooksRoles,
      if (zohoBillingRoles.isNotEmpty) _zohoBillingRolesHeading,
      ...zohoBillingRoles,
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialRecord) return;
    _didLoadInitialRecord = true;

    final editIndexParam = GoRouterState.of(
      context,
    ).uri.queryParameters['editIndex'];
    final editIndex = int.tryParse(editIndexParam ?? '');
    if (editIndex == null) return;

    final records = ref.read(lockConfigurationProvider);
    if (editIndex < 0 || editIndex >= records.length) return;

    _editingIndex = editIndex;
    _loadRecordForEdit(records[editIndex]);
  }

  void _loadRecordForEdit(LockConfigurationRecord record) {
    _currentStatus = record.status;
    _selectedModule = _moduleOptions.contains(record.module)
        ? record.module
        : _moduleOptions.first;
    _nameController.text = record.lockConfigurationName;
    _descriptionController.text = record.description;
    _selectedAction =
        _allowOrRestrictActionOptions.contains(record.allowOrRestrictActions)
        ? record.allowOrRestrictActions
        : _allowOrRestrictActionOptions.first;
    _selectedLockRecordsFor =
        _lockRecordsForOptions.contains(record.lockRecordsFor)
        ? record.lockRecordsFor
        : _lockRecordsForOptions.first;

    if (record.allowOrRestrictActions.startsWith('Restricted Actions: ')) {
      _selectedAction = 'Restrict Selected Actions';
      _selectedRestrictedActions = record.allowOrRestrictActions
          .replaceFirst('Restricted Actions: ', '')
          .split(', ')
          .where((value) => value.trim().isNotEmpty)
          .toList();
    } else if (record.allowOrRestrictActions == 'Allow All Actions') {
      _selectedAction = 'Allow All Actions';
      _selectedRestrictedActions = <String>[];
    } else if (record.allowOrRestrictActions.startsWith('Allowed Actions: ')) {
      _selectedAction = 'Allow Selected Actions';
      _selectedRestrictedActions = record.allowOrRestrictActions
          .replaceFirst('Allowed Actions: ', '')
          .split(', ')
          .where((value) => value.trim().isNotEmpty)
          .toList();
    }

    if (record.allowOrRestrictFields == 'Restrict All Fields') {
      _selectedFieldAction = 'Restrict All Fields';
      _selectedFields = <String>[];
    } else if (record.allowOrRestrictFields == 'Allow All Fields' ||
        record.allowOrRestrictFields == 'Allowed Fields: All') {
      _selectedFieldAction = 'Allow All Fields';
      _selectedFields = <String>[];
    } else if (record.allowOrRestrictFields.startsWith('Restricted Fields: ')) {
      _selectedFieldAction = 'Restrict Selected Fields';
      _selectedFields = record.allowOrRestrictFields
          .replaceFirst('Restricted Fields: ', '')
          .split(', ')
          .where((value) => value.trim().isNotEmpty)
          .toList();
    } else if (record.allowOrRestrictFields.startsWith('Allowed Fields: ')) {
      _selectedFieldAction = 'Allow Selected Fields';
      _selectedFields = record.allowOrRestrictFields
          .replaceFirst('Allowed Fields: ', '')
          .split(', ')
          .where((value) => value.trim().isNotEmpty)
          .toList();
    }

    if (record.lockRecordsFor.startsWith('All Roles Except: ')) {
      _selectedLockRecordsFor = 'All Roles Except';
      _selectedRoles = record.lockRecordsFor
          .replaceFirst('All Roles Except: ', '')
          .split(', ')
          .where((value) => value.trim().isNotEmpty)
          .toList();
    }
  }

  void _saveLockConfiguration() {
    if (_selectedModule == null || _selectedModule!.isEmpty) {
      ZerpaiToast.error(context, 'Module is required');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ZerpaiToast.error(context, 'Lock Configuration Name is required');
      return;
    }
    if (_selectedAction == null || _selectedAction!.isEmpty) {
      ZerpaiToast.error(context, 'Allow or Restrict Actions is required');
      return;
    }
    if (_selectedLockRecordsFor == null || _selectedLockRecordsFor!.isEmpty) {
      ZerpaiToast.error(context, 'Lock Records For is required');
      return;
    }

    if (_selectedAction != 'Restrict All Actions' &&
        _selectedAction != 'Allow All Actions' &&
        _selectedRestrictedActions.isEmpty) {
      ZerpaiToast.error(
        context,
        _selectedAction == 'Allow Selected Actions'
            ? 'Select allowed actions'
            : 'Select restricted actions',
      );
      return;
    }

    if (_selectedAction != 'Restrict All Actions' &&
        _selectedFieldAction != 'Restrict All Fields' &&
        _selectedFieldAction != 'Allow All Fields' &&
        _selectedFields.isEmpty) {
      ZerpaiToast.error(
        context,
        _selectedFieldAction == 'Allow Selected Fields'
            ? 'Select allowed fields'
            : 'Select restricted fields',
      );
      return;
    }

    if (_selectedLockRecordsFor == 'All Roles Except' &&
        _selectedRoles.isEmpty) {
      ZerpaiToast.error(context, 'Select Roles');
      return;
    }

    final allowOrRestrictActions = _selectedAction == 'Restrict All Actions'
        ? 'Restrict All Actions'
        : _selectedAction == 'Allow All Actions'
        ? 'Allow All Actions'
        : _selectedAction == 'Allow Selected Actions'
        ? 'Allowed Actions: ${_selectedRestrictedActions.join(', ')}'
        : 'Restricted Actions: ${_selectedRestrictedActions.join(', ')}';

    final allowOrRestrictFields = _selectedAction == 'Restrict All Actions'
        ? 'Restrict All Fields'
        : _selectedFieldAction == 'Restrict All Fields'
        ? 'Restrict All Fields'
        : _selectedFieldAction == 'Allow All Fields'
        ? 'Allowed Fields: All'
        : _selectedFieldAction == 'Allow Selected Fields'
        ? 'Allowed Fields: ${_selectedFields.join(', ')}'
        : 'Restricted Fields: ${_selectedFields.join(', ')}';

    final lockRecordsFor = _selectedLockRecordsFor == 'All Roles Except'
        ? 'All Roles Except: ${_selectedRoles.join(', ')}'
        : (_selectedLockRecordsFor ?? 'All Roles');

    final record = LockConfigurationRecord(
      module: _selectedModule ?? 'Invoice',
      lockConfigurationName: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      allowOrRestrictActions: allowOrRestrictActions,
      allowOrRestrictFields: allowOrRestrictFields,
      lockRecordsFor: lockRecordsFor,
      status: _editingIndex != null ? _currentStatus : 'Active',
    );

    final notifier = ref.read(lockConfigurationProvider.notifier);
    final request = _editingIndex != null
        ? notifier.updateSeries(_editingIndex!, record)
        : notifier.addSeries(record);

    request
        .then((_) {
          if (!mounted) return;
          context.go(_withOrgPrefix(AppRoutes.settingsLockConfiguration));
        })
        .catchError((error) {
          if (!mounted) return;
          ZerpaiToast.error(context, error.toString());
        });
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return kSettingsNavigationSections
        .expand(
          (section) => section.blocks.expand(
            (block) => block.items.map(
              (entry) => SettingsSearchItem(
                group: block.title,
                label: entry.label,
                subtitle: section.title,
                keywords: <String>[section.title, block.title],
                onSelected: () {
                  if (entry.route == null) return;
                  context.go(_withOrgPrefix(entry.route!));
                },
              ),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'ZERPAI ERP';
    final currentPath = GoRouterState.of(context).uri.path;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): _focusSearch,
      },
      child: ColoredBox(
        color: const Color(0xFFF7F8FC),
        child: Column(
          children: [
            _CreateHeader(
              orgName: orgName,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchItems: _buildSearchItems(),
              onBack: () => context.go(_withOrgPrefix(AppRoutes.settings)),
              onClose: () => context.go(_withOrgPrefix(AppRoutes.home)),
            ),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsNavigationSidebar(currentPath: currentPath),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CreatePaneHeader(
                            title: _editingIndex != null
                                ? 'Edit Lock Configuration'
                                : 'New Lock Configuration',
                            onClose: () => context.go(
                              _withOrgPrefix(
                                AppRoutes.settingsLockConfiguration,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FormRow(
                                    label: 'Module*',
                                    labelColor: const Color(0xFFFF3B3B),
                                    child: SizedBox(
                                      width: 395,
                                      child: FormDropdown<String>(
                                        key: const ValueKey(
                                          'lock_config_module',
                                        ),
                                        height: 32,
                                        value: _selectedModule,
                                        items: _moduleOptions,
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(
                                              () => _selectedModule = value,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _FormRow(
                                    label: 'Lock Configuration Name*',
                                    labelColor: const Color(0xFFFF3B3B),
                                    child: SizedBox(
                                      width: 395,
                                      child: CustomTextField(
                                        controller: _nameController,
                                        height: 32,
                                        forceUppercase: false,
                                        contentCase: ContentCase.none,
                                        textStyle: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _FormRow(
                                    label: 'Description',
                                    child: SizedBox(
                                      width: 395,
                                      child: CustomTextField(
                                        controller: _descriptionController,
                                        height: 64,
                                        maxLines: 4,
                                        forceUppercase: false,
                                        contentCase: ContentCase.none,
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          10,
                                          12,
                                          10,
                                        ),
                                        textStyle: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFE6EBF5),
                                  ),
                                  const SizedBox(height: 18),
                                  _FormRow(
                                    label: 'Allow or Restrict Actions*',
                                    labelColor: const Color(0xFFFF3B3B),
                                    suffix: const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: ZTooltip(
                                        message:
                                            'Allow or restrict the actions that users in your organization can or cannot perform after the records are locked.',
                                        direction: ZTooltipDirection.bottom,
                                      ),
                                    ),
                                    child: SizedBox(
                                      width: 395,
                                      child: FormDropdown<String>(
                                        key: const ValueKey(
                                          'lock_config_allow_restrict_action',
                                        ),
                                        height: 32,
                                        value: _selectedAction,
                                        items: _allowOrRestrictActionOptions,
                                        placeholder: 'Select actions',
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedAction = value;
                                              _selectedRestrictedActions =
                                                  <String>[];
                                              _selectedFieldAction =
                                                  _allowOrRestrictFieldOptions
                                                      .first;
                                              _selectedFields = <String>[];
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  if (_selectedAction !=
                                          'Restrict All Actions' &&
                                      _selectedAction !=
                                          'Allow All Actions') ...[
                                    const SizedBox(height: 10),
                                    _FormRow(
                                      label: '',
                                      child: SizedBox(
                                        width: 395,
                                        child: FormDropdown<String>(
                                          key: const ValueKey(
                                            'lock_config_restricted_actions',
                                          ),
                                          height: 32,
                                          value: null,
                                          items: _availableItems(
                                            _restrictedActionOptions,
                                            _selectedRestrictedActions,
                                          ),
                                          multiSelect: true,
                                          selectedValues:
                                              _selectedRestrictedActions,
                                          onSelectedValuesChanged: (values) {
                                            setState(() {
                                              _selectedRestrictedActions =
                                                  values;
                                            });
                                          },
                                          forceDownward: true,
                                          hint:
                                              _selectedAction ==
                                                  'Allow Selected Actions'
                                              ? 'Select allowed actions'
                                              : 'Select restricted actions',
                                          placeholder:
                                              _selectedAction ==
                                                  'Allow Selected Actions'
                                              ? 'Select allowed actions'
                                              : 'Select restricted actions',
                                          itemBuilder:
                                              (item, isSelected, isHovered) {
                                                final background = isHovered
                                                    ? const Color(0xFF3B82F6)
                                                    : (isSelected
                                                          ? const Color(
                                                              0xFFF1F2F6,
                                                            )
                                                          : Colors.white);
                                                final foreground = isHovered
                                                    ? Colors.white
                                                    : const Color(0xFF4B556B);
                                                return Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                  height: 40,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  decoration: BoxDecoration(
                                                    color: background,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    item,
                                                    style: AppTheme.bodyText
                                                        .copyWith(
                                                          fontSize: 13,
                                                          color: foreground,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w500
                                                              : FontWeight.w400,
                                                        ),
                                                  ),
                                                );
                                              },
                                          onChanged: (_) {},
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (_selectedAction !=
                                      'Restrict All Actions') ...[
                                    const SizedBox(height: 10),
                                    _FormRow(
                                      label: 'Allow or Restrict Fields*',
                                      labelColor: const Color(0xFFFF3B3B),
                                      suffix: const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: ZTooltip(
                                          message:
                                              'Allow or restrict the fields that users in your organization can or cannot update after the records are locked.',
                                          direction: ZTooltipDirection.bottom,
                                        ),
                                      ),
                                      child: SizedBox(
                                        width: 395,
                                        child: FormDropdown<String>(
                                          key: const ValueKey(
                                            'lock_config_allow_restrict_fields',
                                          ),
                                          height: 32,
                                          value: _selectedFieldAction,
                                          items: _allowOrRestrictFieldOptions,
                                          placeholder: 'Select fields rule',
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                _selectedFieldAction = value;
                                                _selectedFields = <String>[];
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    if (_selectedFieldAction ==
                                            'Allow Selected Fields' ||
                                        _selectedFieldAction ==
                                            'Restrict Selected Fields') ...[
                                      const SizedBox(height: 10),
                                      _FormRow(
                                        label: '',
                                        child: SizedBox(
                                          width: 395,
                                          child: FormDropdown<String>(
                                            key: const ValueKey(
                                              'lock_config_selected_fields',
                                            ),
                                            height: 32,
                                            value: null,
                                            items: _availableItems(
                                              _fieldSelectionOptions,
                                              _selectedFields,
                                            ),
                                            multiSelect: true,
                                            selectedValues: _selectedFields,
                                            onSelectedValuesChanged: (values) {
                                              setState(() {
                                                _selectedFields = values;
                                              });
                                            },
                                            forceDownward: true,
                                            hint:
                                                _selectedFieldAction ==
                                                    'Allow Selected Fields'
                                                ? 'Select allowed fields'
                                                : 'Select restricted fields',
                                            placeholder:
                                                _selectedFieldAction ==
                                                    'Allow Selected Fields'
                                                ? 'Select allowed fields'
                                                : 'Select restricted fields',
                                            itemBuilder:
                                                (item, isSelected, isHovered) {
                                                  final background = isHovered
                                                      ? const Color(0xFF3B82F6)
                                                      : (isSelected
                                                            ? const Color(
                                                                0xFFF1F2F6,
                                                              )
                                                            : Colors.white);
                                                  final foreground = isHovered
                                                      ? Colors.white
                                                      : const Color(0xFF4B556B);
                                                  return Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                    height: 40,
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    decoration: BoxDecoration(
                                                      color: background,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      item,
                                                      style: AppTheme.bodyText
                                                          .copyWith(
                                                            fontSize: 13,
                                                            color: foreground,
                                                            fontWeight:
                                                                isSelected
                                                                ? FontWeight
                                                                      .w500
                                                                : FontWeight
                                                                      .w400,
                                                          ),
                                                    ),
                                                  );
                                                },
                                            onChanged: (_) {},
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 12),
                                  _FormRow(
                                    label: 'Lock Records For*',
                                    labelColor: const Color(0xFFFF3B3B),
                                    child: SizedBox(
                                      width: 395,
                                      child: FormDropdown<String>(
                                        key: const ValueKey(
                                          'lock_config_lock_records_for',
                                        ),
                                        height: 32,
                                        value: _selectedLockRecordsFor,
                                        items: _lockRecordsForOptions,
                                        placeholder: 'Select lock scope',
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedLockRecordsFor = value;
                                              _selectedRoles = <String>[];
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  if (_selectedLockRecordsFor ==
                                      'All Roles Except') ...[
                                    const SizedBox(height: 10),
                                    _FormRow(
                                      label: '',
                                      child: SizedBox(
                                        width: 395,
                                        child: FormDropdown<String>(
                                          key: const ValueKey(
                                            'lock_config_roles',
                                          ),
                                          height: 32,
                                          value: null,
                                          items: _availableRoleItems(),
                                          multiSelect: true,
                                          selectedValues: _selectedRoles,
                                          onSelectedValuesChanged: (values) {
                                            setState(() {
                                              _selectedRoles = values;
                                            });
                                          },
                                          forceDownward: true,
                                          hint: 'Select Roles',
                                          placeholder: 'Select Roles',
                                          isItemEnabled: (item) =>
                                              item != _zohoBooksRolesHeading &&
                                              item != _zohoBillingRolesHeading,
                                          itemBuilder:
                                              (item, isSelected, isHovered) {
                                                final isHeading =
                                                    item ==
                                                        _zohoBooksRolesHeading ||
                                                    item ==
                                                        _zohoBillingRolesHeading;
                                                if (isHeading) {
                                                  return Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                          12,
                                                          8,
                                                          12,
                                                          6,
                                                        ),
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      item,
                                                      style: AppTheme.bodyText
                                                          .copyWith(
                                                            fontSize: 13,
                                                            color: const Color(
                                                              0xFF8E96A8,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  );
                                                }

                                                final background = isHovered
                                                    ? const Color(0xFF3B82F6)
                                                    : (isSelected
                                                          ? const Color(
                                                              0xFFF1F2F6,
                                                            )
                                                          : Colors.white);
                                                final foreground = isHovered
                                                    ? Colors.white
                                                    : const Color(0xFF4B556B);
                                                return Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                  height: 40,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  decoration: BoxDecoration(
                                                    color: background,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    item,
                                                    style: AppTheme.bodyText
                                                        .copyWith(
                                                          fontSize: 13,
                                                          color: foreground,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w500
                                                              : FontWeight.w400,
                                                        ),
                                                  ),
                                                );
                                              },
                                          onChanged: (_) {},
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFE6EBF5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _CreateFooter(
                            onSave: _saveLockConfiguration,
                            onCancel: () => context.go(
                              _withOrgPrefix(
                                AppRoutes.settingsLockConfiguration,
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
        ),
      ),
    );
  }
}

class _CreateHeader extends StatelessWidget {
  const _CreateHeader({
    required this.orgName,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchItems,
    required this.onBack,
    required this.onClose,
  });

  final String orgName;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<SettingsSearchItem> searchItems;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_outlined,
              color: Color(0xFFFF5D5D),
              size: 28,
            ),
          ),
          Container(
            width: 1,
            height: 46,
            margin: const EdgeInsets.only(right: 14),
            color: AppTheme.borderLight,
          ),
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD8DDF0)),
              ),
              child: const Icon(
                LucideIcons.chevronLeft,
                size: 20,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Settings',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                orgName,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 340,
            child: SettingsSearchField(
              controller: searchController,
              focusNode: searchFocusNode,
              items: searchItems,
            ),
          ),
          const SizedBox(width: 18),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Text(
                    'Close Settings',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.close, size: 15, color: Color(0xFFFF5C73)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePaneHeader extends StatelessWidget {
  const _CreatePaneHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: AppTheme.pageTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, color: Color(0xFFFF4A4A), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.label,
    required this.child,
    this.labelColor,
    this.suffix,
  });

  final String label;
  final Widget child;
  final Color? labelColor;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 206,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: labelColor ?? const Color(0xFF4B556B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (suffix != null) suffix!,
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CreateFooter extends StatelessWidget {
  const _CreateFooter({required this.onSave, required this.onCancel});

  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          SizedBox(
            height: 30,
            child: ZButton.primary(
              label: 'Save',
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: onSave,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            height: 30,
            child: ZButton.secondary(
              label: 'Cancel',
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: onCancel,
            ),
          ),
        ],
      ),
    );
  }
}
