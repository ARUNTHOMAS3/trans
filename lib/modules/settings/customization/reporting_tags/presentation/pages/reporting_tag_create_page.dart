import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';

class ReportingTagCreatePage extends ConsumerStatefulWidget {
  const ReportingTagCreatePage({super.key, this.isCreateMode = false});

  final bool isCreateMode;

  @override
  ConsumerState<ReportingTagCreatePage> createState() =>
      _ReportingTagCreatePageState();
}

enum _ReportingTagLevel { transaction, lineItem }

enum _ReportingTagWizardStep { createTag, configureOptions }

enum _ReportingTagExportFormat { csv, xls, xlsx }

class _ReportingTagCreatePageState
    extends ConsumerState<ReportingTagCreatePage> {
  static const String _itemsLockTooltipMessage =
      'Items can have a reporting tag only if the tag is associated at the Line Item level in Sales, Purchases, or Inventory.';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  final List<_OptionDraft> _optionDrafts = <_OptionDraft>[
    _OptionDraft(controller: TextEditingController()),
  ];

  static List<_ReportingTagRow> _storedRows = <_ReportingTagRow>[];
  static String? _pendingOpenedRowName;
  static _ReportingTagEditDraft? _pendingEditDraft;

  late List<_ReportingTagRow> _rows;
  List<_ReportingTagRow> _draftRows = <_ReportingTagRow>[];
  int? _selectedRowIndex;
  bool _isReorderMode = false;
  bool _isLoading = true;
  bool _showNameError = false;
  bool _hasAppliedPendingSelection = false;

  bool _salesSelected = false;
  bool _purchasesSelected = false;
  bool _inventorySelected = false;
  bool _customersSelected = false;
  bool _vendorsSelected = false;
  bool _itemsSelected = false;
  bool _mandatorySelected = false;
  _ReportingTagLevel? _reportingTagLevel;
  _ReportingTagWizardStep _wizardStep = _ReportingTagWizardStep.createTag;
  bool _showOptionsHelpSidebar = false;
  String? _editingRowName;
  String? _editingRowId;

  bool get _hasTransactionScopedModuleSelection =>
      _salesSelected || _purchasesSelected || _inventorySelected;

  bool get _shouldLockItems =>
      _hasTransactionScopedModuleSelection &&
      _reportingTagLevel == _ReportingTagLevel.transaction;

  @override
  void initState() {
    super.initState();
    _rows = List<_ReportingTagRow>.from(_storedRows);
    _loadReportingTags();
    _restorePendingEditDraftIfNeeded();
  }

  Future<void> _loadReportingTags() async {
    try {
      final response = await _apiClient.get(
        'settings-customization/reporting-tags',
        useCache: false,
      );
      final rows = response.data is List ? response.data as List : const [];
      if (!mounted) return;
      setState(() {
        _setRows(
          rows
              .whereType<Map>()
              .map((row) {
                final json = Map<String, dynamic>.from(row);
                return _ReportingTagRow(
                  id: json['id']?.toString(),
                  name: json['tag_name']?.toString() ?? '',
                  description: '',
                  mandatory: 'No',
                  isInactive: json['is_active'] == false,
                );
              })
              .toList(growable: false),
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ZerpaiToast.error(context, 'Failed to load reporting tags');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasAppliedPendingSelection || widget.isCreateMode) {
      return;
    }
    _hasAppliedPendingSelection = true;
    final pendingRowName = _pendingOpenedRowName;
    if (pendingRowName == null) {
      return;
    }
    _pendingOpenedRowName = null;
    final rowIndex = _indexOfRowByName(pendingRowName);
    if (rowIndex == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _selectedRowIndex = rowIndex);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    for (final draft in _optionDrafts) {
      draft.controller.dispose();
    }
    super.dispose();
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
      ZerpaiToast.info(context, '${entry.label} is not available yet');
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

  void _navigateToCreateMode() {
    _pendingEditDraft = null;
    context.go(_orgScopedRoute(context, AppRoutes.settingsReportingTagsCreate));
  }

  void _navigateToEditMode(_ReportingTagRow row) {
    _pendingEditDraft = _ReportingTagEditDraft(row: row);
    context.go(_orgScopedRoute(context, AppRoutes.settingsReportingTagsCreate));
  }

  int? _indexOfRowByName(String name) {
    final index = _rows.indexWhere((row) => row.name == name);
    return index == -1 ? null : index;
  }

  void _setRows(List<_ReportingTagRow> rows) {
    _rows = rows;
    _storedRows = List<_ReportingTagRow>.from(rows);
  }

  void _restorePendingEditDraftIfNeeded() {
    if (!widget.isCreateMode) {
      return;
    }
    final draft = _pendingEditDraft;
    if (draft == null) {
      return;
    }
    _pendingEditDraft = null;
    _loadRowIntoForm(draft.row);
  }

  void _replaceOptionDrafts(List<_ReportingTagOption> options) {
    for (final draft in _optionDrafts) {
      draft.controller.dispose();
    }
    _optionDrafts.clear();
    final sourceOptions = options.isEmpty
        ? <_ReportingTagOption>[
            _ReportingTagOption(label: _nameController.text.trim()),
          ]
        : options;
    for (final option in sourceOptions) {
      _optionDrafts.add(
        _OptionDraft(
          controller: TextEditingController(text: option.label),
          level: option.level,
        ),
      );
    }
  }

  void _loadRowIntoForm(_ReportingTagRow row) {
    final inferredLevel =
        row.reportingTagLevel ??
        (row.lineItemModules.isNotEmpty ? _ReportingTagLevel.lineItem : null);
    _editingRowName = row.name;
    _editingRowId = row.id;
    _nameController.text = row.name;
    _descriptionController.text = row.description;
    _salesSelected = row.lineItemModules.contains('Sales');
    _purchasesSelected = row.lineItemModules.contains('Purchases');
    _inventorySelected = row.lineItemModules.contains('Inventory');
    _customersSelected = row.otherModules.contains('Customers');
    _vendorsSelected = row.otherModules.contains('Vendors');
    _itemsSelected = row.otherModules.contains('Items');
    _mandatorySelected = row.mandatory == 'Yes';
    _reportingTagLevel = inferredLevel;
    _wizardStep = _ReportingTagWizardStep.createTag;
    _showNameError = false;
    _replaceOptionDrafts(row.options);
    _syncAssociationLocks();
  }

  List<_ReportingTagOption> _buildDraftOptions() {
    final options = _optionDrafts
        .map(
          (draft) => _ReportingTagOption(
            label: draft.controller.text.trim(),
            level: draft.level,
          ),
        )
        .where((option) => option.label.isNotEmpty)
        .toList(growable: false);
    if (options.isNotEmpty) {
      return options;
    }
    return <_ReportingTagOption>[
      _ReportingTagOption(label: _nameController.text.trim()),
    ];
  }

  List<String> _buildTransactionModules() {
    final modules = <String>[];
    if (_salesSelected) {
      modules.add('Sales');
    }
    if (_purchasesSelected) {
      modules.add('Purchases');
    }
    if (_inventorySelected) {
      modules.add('Inventory');
    }
    return modules;
  }

  List<String> _buildOtherModules() {
    final modules = <String>[];
    if (_customersSelected) {
      modules.add('Customers');
    }
    if (_vendorsSelected) {
      modules.add('Vendors');
    }
    if (_itemsSelected) {
      modules.add('Items');
    }
    return modules;
  }

  void _navigateToListMode({String? openRowName}) {
    if (!widget.isCreateMode) {
      setState(
        () => _selectedRowIndex = openRowName == null
            ? null
            : _indexOfRowByName(openRowName),
      );
      return;
    }
    _pendingOpenedRowName = openRowName;
    context.go(_orgScopedRoute(context, AppRoutes.settingsReportingTags));
  }

  void _enterReorderMode() {
    setState(() {
      _draftRows = List<_ReportingTagRow>.from(_rows);
      _isReorderMode = true;
    });
  }

  void _cancelReorderMode() {
    setState(() {
      _draftRows = <_ReportingTagRow>[];
      _isReorderMode = false;
    });
  }

  void _saveReorderMode() {
    setState(() {
      _setRows(List<_ReportingTagRow>.from(_draftRows));
      _draftRows = <_ReportingTagRow>[];
      _isReorderMode = false;
    });
  }

  void _reorderDraftRows(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final _ReportingTagRow movedRow = _draftRows.removeAt(oldIndex);
      _draftRows.insert(newIndex, movedRow);
    });
  }

  void _saveAndContinue() {
    final name = _nameController.text.trim();
    setState(() {
      _showNameError = name.isEmpty;
    });
    if (name.isEmpty) {
      ZerpaiToast.error(context, 'Reporting Tag Name is required');
      return;
    }
    setState(() {
      _wizardStep = _ReportingTagWizardStep.configureOptions;
      if (_optionDrafts.isEmpty) {
        _optionDrafts.add(_OptionDraft(controller: TextEditingController()));
      }
    });
  }

  void _syncAssociationLocks() {
    if (!_hasTransactionScopedModuleSelection &&
        _reportingTagLevel == _ReportingTagLevel.transaction) {
      _reportingTagLevel = null;
    }
    if (_shouldLockItems) {
      _itemsSelected = false;
    }
  }

  void _addOptionField() {
    setState(() {
      _optionDrafts.add(_OptionDraft(controller: TextEditingController()));
    });
  }

  int _subtreeEndIndex(int index) {
    final currentLevel = _optionDrafts[index].level;
    var nextIndex = index + 1;
    while (nextIndex < _optionDrafts.length &&
        _optionDrafts[nextIndex].level > currentLevel) {
      nextIndex += 1;
    }
    return nextIndex;
  }

  void _insertOptionFieldAt(int insertIndex, {required int level}) {
    setState(() {
      _optionDrafts.insert(
        insertIndex,
        _OptionDraft(controller: TextEditingController(), level: level),
      );
    });
  }

  void _insertOptionFieldAbove(int index) {
    _insertOptionFieldAt(index, level: _optionDrafts[index].level);
  }

  void _insertOptionField(int index) {
    _insertOptionFieldAt(index + 1, level: _optionDrafts[index].level);
  }

  void _insertChildOptionField(int index) {
    _insertOptionFieldAt(
      _subtreeEndIndex(index),
      level: _optionDrafts[index].level + 1,
    );
  }

  void _removeOptionField(int index) {
    if (_optionDrafts.length <= 1) {
      return;
    }
    setState(() {
      final removeUntil = _subtreeEndIndex(index);
      final removedDrafts = _optionDrafts.sublist(index, removeUntil);
      _optionDrafts.removeRange(index, removeUntil);
      for (final draft in removedDrafts) {
        draft.controller.dispose();
      }
      if (_optionDrafts.isEmpty) {
        _optionDrafts.add(_OptionDraft(controller: TextEditingController()));
      }
    });
  }

  void _reorderOptionFields(int oldIndex, int newIndex) {
    setState(() {
      final oldEndIndex = _subtreeEndIndex(oldIndex);
      final movingBlock = _optionDrafts.sublist(oldIndex, oldEndIndex);
      _optionDrafts.removeRange(oldIndex, oldEndIndex);

      if (newIndex > oldIndex) {
        newIndex -= movingBlock.length;
      }

      if (newIndex < 0) {
        newIndex = 0;
      }
      if (newIndex > _optionDrafts.length) {
        newIndex = _optionDrafts.length;
      }

      _optionDrafts.insertAll(newIndex, movingBlock);
    });
  }

  Future<void> _saveReportingTag() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ZerpaiToast.error(context, 'Reporting Tag Name is required');
      setState(() {
        _wizardStep = _ReportingTagWizardStep.createTag;
        _showNameError = true;
      });
      return;
    }

    final row = _ReportingTagRow(
      id: _editingRowId,
      name: name,
      description: _descriptionController.text.trim(),
      mandatory: _mandatorySelected ? 'Yes' : 'No',
      options: _buildDraftOptions(),
      lineItemModules: _buildTransactionModules(),
      otherModules: _buildOtherModules(),
      reportingTagLevel: _reportingTagLevel,
    );

    try {
      if (row.id != null && row.id!.isNotEmpty) {
        await _apiClient.patch(
          'settings-customization/reporting-tags/${row.id}',
          data: {'tag_name': row.name, 'is_active': !row.isInactive},
        );
      } else {
        await _apiClient.post(
          'settings-customization/reporting-tags',
          data: {'tag_name': row.name, 'is_active': true},
        );
      }
      if (!mounted) return;
      await _loadReportingTags();
      _editingRowName = null;
      _editingRowId = null;
      ZerpaiToast.success(context, 'Reporting tag saved');
      _navigateToListMode(openRowName: row.name);
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to save reporting tag');
    }
  }

  Future<void> _toggleRowInactive(int index) async {
    final row = _rows[index];
    if (row.id == null || row.id!.isEmpty) return;
    final nextInactive = !row.isInactive;
    try {
      await _apiClient.patch(
        'settings-customization/reporting-tags/${row.id}',
        data: {'is_active': !nextInactive},
      );
      if (!mounted) return;
      setState(() {
        final nextRows = List<_ReportingTagRow>.from(_rows);
        nextRows[index] = row.copyWith(isInactive: nextInactive);
        _setRows(nextRows);
      });
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to update reporting tag');
    }
  }

  void _openRowDetails(int index) {
    setState(() => _selectedRowIndex = index);
  }

  void _closeRowDetails() {
    setState(() => _selectedRowIndex = null);
  }

  void _toggleDetailOptionInactive(int rowIndex, int optionIndex) {
    setState(() {
      final row = _rows[rowIndex];
      final nextOptions = List<_ReportingTagOption>.from(row.options);
      final option = nextOptions[optionIndex];
      if (option.isDefault) {
        return;
      }
      nextOptions[optionIndex] = option.copyWith(
        isInactive: !option.isInactive,
      );
      final nextRows = List<_ReportingTagRow>.from(_rows);
      nextRows[rowIndex] = row.copyWith(options: nextOptions);
      _setRows(nextRows);
    });
  }

  void _toggleDetailOptionDefault(int rowIndex, int optionIndex) {
    setState(() {
      final row = _rows[rowIndex];
      final nextOptions = List<_ReportingTagOption>.from(row.options);
      final option = nextOptions[optionIndex];
      if (option.isInactive) {
        return;
      }
      nextOptions[optionIndex] = option.copyWith(isDefault: !option.isDefault);
      final nextRows = List<_ReportingTagRow>.from(_rows);
      nextRows[rowIndex] = row.copyWith(options: nextOptions);
      _setRows(nextRows);
    });
  }

  void _markSelectedRowReady() {
    final selectedRowIndex = _selectedRowIndex;
    if (selectedRowIndex == null) {
      return;
    }
    final row = _rows[selectedRowIndex];
    if (row.isReady) {
      ZerpaiToast.info(context, 'Reporting tag is already ready');
      return;
    }
    setState(() {
      final nextRows = List<_ReportingTagRow>.from(_rows);
      nextRows[selectedRowIndex] = row.copyWith(isReady: true);
      _setRows(nextRows);
    });
    ZerpaiToast.success(context, '${row.name} marked as ready');
  }

  void _openOptionsHelpSidebar() {
    setState(() => _showOptionsHelpSidebar = true);
  }

  void _closeOptionsHelpSidebar() {
    setState(() => _showOptionsHelpSidebar = false);
  }

  Future<void> _openExportOptionsDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => _ExportOptionsDialog(
        onExport: (format, password) {
          Navigator.of(dialogContext).pop();
          ZerpaiToast.success(
            context,
            'Export started in ${format.name.toUpperCase()} format',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(
      context,
    ).uri.path.replaceFirst(RegExp(r'^/\d{10,20}'), '');
    final orgName = ref
        .watch(orgSettingsProvider)
        .maybeWhen(
          data: (settings) {
            final name = settings?.name.trim() ?? '';
            return name.isEmpty ? 'ZABNIX PRIVATE LIMITED' : name;
          },
          orElse: () => 'ZABNIX PRIVATE LIMITED',
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context, orgName),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsNavigationSidebar(currentPath: currentPath),
                    Expanded(
                      child: ColoredBox(
                        color: const Color(0xFFF5F5F5),
                        child: widget.isCreateMode
                            ? _buildCreateWindow()
                            : (_selectedRowIndex != null
                                  ? _buildDetailWindow(
                                      _rows[_selectedRowIndex!],
                                    )
                                  : _buildListWindow()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showOptionsHelpSidebar)
            _OptionsHelpSidebar(onClose: _closeOptionsHelpSidebar),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String orgName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompactHeader = constraints.maxWidth < 1180;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.warningBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: const Icon(
                      LucideIcons.settings2,
                      size: 16,
                      color: AppTheme.warningOrange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.go(
                      _orgScopedRoute(context, AppRoutes.settings),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        size: 18,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'All Settings',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.pageTitle.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          orgName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF667085),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCompactHeader) ...[
                    const SizedBox(width: 22),
                    SizedBox(
                      width: 320,
                      child: SettingsSearchField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        items: _buildSearchItems(context),
                      ),
                    ),
                    const SizedBox(width: 22),
                    _buildCloseSettingsButton(context),
                  ],
                ],
              ),
              if (isCompactHeader) ...[
                const SizedBox(height: 12),
                SettingsSearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  items: _buildSearchItems(context),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildCloseSettingsButton(context),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCloseSettingsButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => context.go(_orgScopedRoute(context, AppRoutes.home)),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: AppTheme.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Close Settings',
            style: AppTheme.bodyText.copyWith(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(LucideIcons.x, size: 14, color: AppTheme.errorRed),
        ],
      ),
    );
  }

  Widget _buildListWindow() {
    return Container(
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minTableWidth = constraints.maxWidth < 760
              ? 760.0
              : constraints.maxWidth;
          final isCompactHeader = constraints.maxWidth < 940;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
                child: isCompactHeader
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPanelTitle(),
                          const SizedBox(height: 12),
                          _isReorderMode
                              ? _buildReorderHeaderActions(
                                  alignment: WrapAlignment.start,
                                )
                              : _buildHeaderActions(
                                  alignment: WrapAlignment.start,
                                ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildPanelTitle()),
                          const SizedBox(width: 12),
                          _isReorderMode
                              ? _buildReorderHeaderActions()
                              : _buildHeaderActions(),
                        ],
                      ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: minTableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTableHeader(),
                        Expanded(
                          child: _isReorderMode
                              ? ReorderableListView.builder(
                                  buildDefaultDragHandles: false,
                                  padding: EdgeInsets.zero,
                                  itemCount: _draftRows.length,
                                  onReorder: _reorderDraftRows,
                                  itemBuilder: (context, index) {
                                    final row = _draftRows[index];
                                    return _ReportingTagReorderRow(
                                      key: ValueKey<String>(
                                        '${row.name}-${row.description}-$index',
                                      ),
                                      row: row,
                                      index: index,
                                      isLast: index == _draftRows.length - 1,
                                    );
                                  },
                                )
                              : _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _rows.isEmpty
                              ? Center(
                                  child: Text(
                                    'No reporting tags found',
                                    style: AppTheme.bodyText.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                )
                              : ListView(
                                  children: [
                                    for (
                                      var index = 0;
                                      index < _rows.length;
                                      index++
                                    ) ...[
                                      _ReportingTagDataRow(
                                        row: _rows[index],
                                        onEdit: () =>
                                            _navigateToEditMode(_rows[index]),
                                        onOpenDetails: () =>
                                            _openRowDetails(index),
                                        onToggleInactive: () =>
                                            _toggleRowInactive(index),
                                      ),
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreateWindow() {
    return Container(
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildStepHeader(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: _wizardStep == _ReportingTagWizardStep.createTag
                ? _buildCreateTagStep()
                : _buildConfigureOptionsStep(),
          ),
          _buildCreateFooter(),
        ],
      ),
    );
  }

  Widget _buildDetailWindow(_ReportingTagRow row) {
    final selectedRowIndex = _selectedRowIndex;

    return Container(
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            padding: const EdgeInsets.fromLTRB(18, 0, 12, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        row.name,
                        style: AppTheme.pageTitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: row.isReady
                              ? const Color(0xFFE8F8F0)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          row.isReady ? 'Ready' : 'Not Ready',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: row.isReady
                                ? const Color(0xFF15803D)
                                : const Color(0xFF6B7280),
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!row.isReady) ...[
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: _markSelectedRowReady,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.check, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            'Mark as Ready',
                            style: AppTheme.buttonText.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    onPressed: () => _navigateToEditMode(row),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFDDE3ED)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.pencil,
                          size: 14,
                          color: Color(0xFF374151),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Edit',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _closeRowDetails,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDDE3ED)),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8F9FC),
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                            child: Text(
                              'Options',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                          for (
                            var index = 0;
                            index < row.options.length;
                            index++
                          )
                            _ReportingTagDetailOptionRow(
                              option: row.options[index],
                              isFirst: index == 0,
                              isLast: index == row.options.length - 1,
                              onToggleDefault: selectedRowIndex == null
                                  ? null
                                  : () => _toggleDetailOptionDefault(
                                      selectedRowIndex,
                                      index,
                                    ),
                              onToggleInactive: selectedRowIndex == null
                                  ? null
                                  : () => _toggleDetailOptionInactive(
                                      selectedRowIndex,
                                      index,
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, color: const Color(0xFFE5E7EB)),
                SizedBox(
                  width: 320,
                  child: ColoredBox(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.sparkles,
                                size: 14,
                                color: Color(0xFF8B5CF6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'REPORTING TAG CONFIGURATIONS',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: const Color(0xFF7C87A0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _buildConfigSectionTitle(
                            'Modules where this tag can be associated at line-item level',
                          ),
                          const SizedBox(height: 10),
                          for (final module in row.lineItemModules)
                            _buildConfigCheckItem(module),
                          const SizedBox(height: 22),
                          _buildConfigSectionTitle(
                            'Other modules where this tag can be associated',
                          ),
                          const SizedBox(height: 10),
                          for (final module in row.otherModules)
                            _buildConfigCheckItem(module),
                          const SizedBox(height: 22),
                          Text(
                            'Configurations',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(
                                  LucideIcons.minusCircle,
                                  size: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row.mandatory == 'Yes'
                                          ? 'Mandatory'
                                          : 'Optional',
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      row.mandatory == 'Yes'
                                          ? 'Input for this reporting tag is required in transactions or records.'
                                          : 'Providing an input for this reporting tag in transactions or records is optional.',
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 13.5,
                                        color: const Color(0xFF374151),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    LucideIcons.info,
                                    size: 15,
                                    color: Color(0xFFC58A17),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'These configurations cannot be changed once a transaction is created with this reporting tag.',
                                    style: AppTheme.bodyText.copyWith(
                                      fontSize: 13,
                                      color: const Color(0xFF8A6A1F),
                                      height: 1.45,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTagStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8EBF0)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 18),
              _buildAssociateSection(),
              const SizedBox(height: 26),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 14),
              _buildConfigurationSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigureOptionsStep() {
    final tagName = _nameController.text.trim();
    final cardTitle = tagName.isEmpty
        ? 'REPORTING TAG OPTIONS'
        : '${tagName.toUpperCase()} OPTIONS';

    return ColoredBox(
      color: const Color(0xFFF5F7FC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tagName,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  _buildInlineActionLink(
                    icon: LucideIcons.download,
                    label: 'Import Options',
                    onTap: () {
                      ZerpaiToast.info(
                        context,
                        'Import Options is not available yet',
                      );
                    },
                  ),
                  const SizedBox(width: 18),
                  _buildInlineActionLink(
                    icon: LucideIcons.upload,
                    label: 'Export Options',
                    onTap: _openExportOptionsDialog,
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            cardTitle,
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: const Color(0xFF7B8190),
                            ),
                          ),
                        ),
                        _buildInlineActionLink(
                          icon: LucideIcons.lightbulb,
                          label: 'How Options Work',
                          color: const Color(0xFFF59E0B),
                          labelColor: const Color(0xFF111827),
                          showDottedUnderline: true,
                          iconSize: 13,
                          onTap: _openOptionsHelpSidebar,
                        ),
                      ],
                    ),
                  ),
                  ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _optionDrafts.length,
                    onReorder: _reorderOptionFields,
                    itemBuilder: (context, index) {
                      return _buildOptionRow(
                        key: ObjectKey(_optionDrafts[index].controller),
                        index: index,
                        controller: _optionDrafts[index].controller,
                        level: _optionDrafts[index].level,
                        isLast: index == _optionDrafts.length - 1,
                        canDelete: _optionDrafts.length > 1,
                        onInsertAbove: () => _insertOptionFieldAbove(index),
                        onInsertBelow: () => _insertOptionField(index),
                        onInsertChild: () => _insertChildOptionField(index),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _addOptionField,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.plusCircle,
                    size: 15,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add Option',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
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

  Widget _buildPanelTitle() {
    return Text(
      _isReorderMode ? 'Reorder Reporting Tags' : 'Reporting Tags',
      style: AppTheme.pageTitle.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildHeaderActions({WrapAlignment alignment = WrapAlignment.end}) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          height: 38,
          child: ElevatedButton(
            onPressed: _navigateToCreateMode,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 38),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              '+ New Reporting Tag',
              style: AppTheme.buttonText.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
        _ChangeOrderButton(onPressed: _enterReorderMode),
      ],
    );
  }

  Widget _buildReorderHeaderActions({
    WrapAlignment alignment = WrapAlignment.end,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: _saveReorderMode,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'Save',
              style: AppTheme.buttonText.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
        InkWell(
          onTap: _cancelReorderMode,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(
              LucideIcons.x,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 42,
      padding: EdgeInsets.only(
        left: _isReorderMode ? 20 : 22,
        right: _isReorderMode ? 20 : 22,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F7),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Expanded(flex: 5, child: _HeaderText('REPORTING TAG NAME')),
          Expanded(flex: 6, child: _HeaderText('DESCRIPTION')),
          Expanded(flex: 4, child: _HeaderText('MANDATORY')),
          SizedBox(width: 170),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    final isConfigureStep =
        _wizardStep == _ReportingTagWizardStep.configureOptions;
    final stepOneTitle = _editingRowName == null
        ? 'Create Reporting Tag'
        : 'Edit Reporting Tag';
    return SizedBox(
      height: 58,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepBubble(
              number: '1',
              isActive: !isConfigureStep,
              isCompleted: isConfigureStep,
            ),
            const SizedBox(width: 10),
            Text(
              stepOneTitle,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            Container(
              width: 34,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: const Color(0xFFE5E7EB),
            ),
            _buildStepBubble(number: '2', isActive: isConfigureStep),
            const SizedBox(width: 10),
            Text(
              'Configure Options',
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                fontWeight: isConfigureStep ? FontWeight.w700 : FontWeight.w500,
                color: isConfigureStep
                    ? const Color(0xFF111827)
                    : const Color(0xFFD1D5DB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBubble({
    required String number,
    required bool isActive,
    bool isCompleted = false,
  }) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF22B378)
            : (isActive ? const Color(0xFF3B82F6) : Colors.white),
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF22B378)
              : (isActive ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB)),
        ),
      ),
      child: isCompleted
          ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
          : Text(
              number,
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : const Color(0xFFD1D5DB),
              ),
            ),
    );
  }

  Widget _buildInlineActionLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF3B82F6),
    Color? labelColor,
    bool showDottedUnderline = false,
    double iconSize = 15,
  }) {
    final resolvedLabelColor = labelColor ?? color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 5),
            Container(
              padding: showDottedUnderline
                  ? const EdgeInsets.only(bottom: 2)
                  : EdgeInsets.zero,
              decoration: showDottedUnderline
                  ? const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFFD1D5DB),
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                      ),
                    )
                  : null,
              child: Text(
                label,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: resolvedLabelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSectionTitle(String text) {
    return SizedBox(
      width: 220,
      child: Text(
        text,
        style: AppTheme.bodyText.copyWith(
          fontSize: 14,
          color: const Color(0xFF7180A4),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildConfigCheckItem(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(LucideIcons.check, size: 15, color: Color(0xFF22B378)),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 14,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow({
    required Key key,
    required int index,
    required TextEditingController controller,
    required int level,
    required bool isLast,
    required bool canDelete,
    required VoidCallback onInsertAbove,
    required VoidCallback onInsertBelow,
    required VoidCallback onInsertChild,
  }) {
    return _OptionRow(
      key: key,
      index: index,
      controller: controller,
      level: level,
      isLast: isLast,
      canDelete: canDelete,
      onDelete: () => _removeOptionField(index),
      onInsertAbove: onInsertAbove,
      onInsertBelow: onInsertBelow,
      onInsertChild: onInsertChild,
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 480,
          child: _buildLabeledField(
            label: 'Reporting Tag Name*',
            labelColor: AppTheme.errorRed,
            child: CustomTextField(
              controller: _nameController,
              height: 32,
              forceUppercase: false,
              contentCase: ContentCase.none,
              errorText: _showNameError
                  ? 'Reporting Tag Name is required'
                  : null,
              onChanged: (_) {
                if (_showNameError && _nameController.text.trim().isNotEmpty) {
                  setState(() => _showNameError = false);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 480,
          child: _buildLabeledField(
            label: 'Description',
            child: CustomTextField(
              controller: _descriptionController,
              height: 86,
              minHeight: 86,
              maxLines: null,
              forceUppercase: false,
              contentCase: ContentCase.none,
              resizable: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssociateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Associate This Reporting Tag To',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'You can select the modules for which you want to associate reporting tags.',
          style: AppTheme.bodyText.copyWith(
            fontSize: 13.5,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 790),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModuleCheckbox(
                          label: 'Sales',
                          value: _salesSelected,
                          onChanged: (value) {
                            setState(() {
                              _salesSelected = value;
                              _syncAssociationLocks();
                            });
                          },
                        ),
                        _buildModuleCheckbox(
                          label: 'Purchases',
                          value: _purchasesSelected,
                          onChanged: (value) {
                            setState(() {
                              _purchasesSelected = value;
                              _syncAssociationLocks();
                            });
                          },
                        ),
                        _buildModuleCheckbox(
                          label: 'Inventory',
                          value: _inventorySelected,
                          onChanged: (value) {
                            setState(() {
                              _inventorySelected = value;
                              _syncAssociationLocks();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, color: const Color(0xFFE5E7EB)),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLevelOption(
                          title: 'At Transaction Level',
                          subtitle:
                              'The reporting tag is applied to the entire transaction.',
                          value: _ReportingTagLevel.transaction,
                        ),
                        const SizedBox(height: 18),
                        _buildLevelOption(
                          title: 'At Line Item Level',
                          subtitle:
                              'The reporting tag is applied to individual line items within a transaction.',
                          value: _ReportingTagLevel.lineItem,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          direction: Axis.vertical,
          spacing: 10,
          children: [
            _buildModuleCheckbox(
              label: 'Customers',
              value: _customersSelected,
              onChanged: (value) {
                setState(() => _customersSelected = value);
              },
            ),
            _buildModuleCheckbox(
              label: 'Vendors',
              value: _vendorsSelected,
              onChanged: (value) {
                setState(() => _vendorsSelected = value);
              },
            ),
            _buildModuleCheckbox(
              label: 'Items',
              value: _itemsSelected,
              enabled: !_shouldLockItems,
              trailing: _shouldLockItems
                  ? const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: ZTooltip(
                        message: _itemsLockTooltipMessage,
                        direction: ZTooltipDirection.top,
                        maxWidth: 280,
                        child: Icon(
                          LucideIcons.lock,
                          size: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  : null,
              onChanged: (value) {
                setState(() => _itemsSelected = value);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfigurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurations',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        _buildModuleCheckbox(
          label: 'Make this reporting tag as mandatory',
          value: _mandatorySelected,
          onChanged: (value) {
            setState(() => _mandatorySelected = value);
          },
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            'Requires you to provide input for the reporting tag field. However, it will be skipped for auto-created transactions and in certain apps where this field is not present.',
            style: AppTheme.bodyText.copyWith(
              fontSize: 13.5,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: _wizardStep == _ReportingTagWizardStep.createTag
                  ? _saveAndContinue
                  : _saveReportingTag,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                _wizardStep == _ReportingTagWizardStep.createTag
                    ? 'Save and Continue'
                    : 'Save',
                style: AppTheme.buttonText.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: _navigateToListMode,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    Color? labelColor,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: labelColor ?? const Color(0xFF111827),
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildModuleCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF3B82F6);
                  }
                  return Colors.white;
                }),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            child: Checkbox(
              value: value,
              onChanged: enabled
                  ? (checked) => onChanged(checked ?? false)
                  : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 14,
              color: const Color(0xFF111827),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildLevelOption({
    required String title,
    required String subtitle,
    required _ReportingTagLevel value,
  }) {
    final isSelected = _reportingTagLevel == value;
    return InkWell(
      onTap: () => setState(() {
        _reportingTagLevel = value;
        _syncAssociationLocks();
      }),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              radioTheme: RadioThemeData(
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF3B82F6);
                  }
                  return const Color(0xFFD1D5DB);
                }),
              ),
            ),
            child: RadioGroup<_ReportingTagLevel>(
              groupValue: _reportingTagLevel,
              onChanged: (next) {
                if (next != null) {
                  setState(() {
                    _reportingTagLevel = next;
                    _syncAssociationLocks();
                  });
                }
              },
              child: Radio<_ReportingTagLevel>(
                value: value,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    title,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13.5,
                    color: isSelected
                        ? const Color(0xFF64748B)
                        : const Color(0xFF7C8AA5),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeOrderButton extends StatefulWidget {
  const _ChangeOrderButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ChangeOrderButton> createState() => _ChangeOrderButtonState();
}

class _ChangeOrderButtonState extends State<_ChangeOrderButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFFEDEDED)
                : const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _SixDotIcon(),
              const SizedBox(width: 6),
              Text(
                'Change Order',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SixDotIcon extends StatelessWidget {
  const _SixDotIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 12,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_SixDotPoint(), _SixDotPoint()],
          ),
          SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_SixDotPoint(), _SixDotPoint()],
          ),
          SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_SixDotPoint(), _SixDotPoint()],
          ),
        ],
      ),
    );
  }
}

class _SixDotPoint extends StatelessWidget {
  const _SixDotPoint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Color(0xFF6B7280),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTheme.bodyText.copyWith(
        fontSize: 11.4,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF7B8190),
        letterSpacing: 0.3,
        height: 1,
      ),
    );
  }
}

class _ReportingTagReorderRow extends StatelessWidget {
  const _ReportingTagReorderRow({
    super.key,
    required this.row,
    required this.index,
    required this.isLast,
  });

  final _ReportingTagRow row;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: _SixDotIcon(),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.name,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              row.description,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              row.mandatory,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportingTagDataRow extends StatefulWidget {
  const _ReportingTagDataRow({
    required this.row,
    required this.onEdit,
    required this.onOpenDetails,
    required this.onToggleInactive,
  });

  final _ReportingTagRow row;
  final VoidCallback onEdit;
  final VoidCallback onOpenDetails;
  final VoidCallback onToggleInactive;

  @override
  State<_ReportingTagDataRow> createState() => _ReportingTagDataRowState();
}

class _ReportingTagDataRowState extends State<_ReportingTagDataRow> {
  bool _isHovered = false;
  final MenuController _menuController = MenuController();
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final showActions = _isHovered || _isMenuOpen;
    final backgroundColor = showActions
        ? const Color(0xFFF7F8FB)
        : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: backgroundColor,
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: InkWell(
                onTap: widget.onOpenDetails,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: widget.row.name,
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: widget.row.isInactive
                                    ? const Color(0xFF7C879D)
                                    : const Color(0xFF333333),
                              ),
                            ),
                            if (widget.row.isInactive)
                              TextSpan(
                                text: '  (Inactive)',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF7C879D),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        widget.row.description,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        widget.row.mandatory,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 170,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: showActions ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !showActions,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: widget.onEdit,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: Text(
                            'Edit',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '|',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      MenuAnchor(
                        controller: _menuController,
                        consumeOutsideTap: true,
                        alignmentOffset: const Offset(-86, 8),
                        style: MenuStyle(
                          backgroundColor: const WidgetStatePropertyAll<Color>(
                            Colors.white,
                          ),
                          surfaceTintColor: const WidgetStatePropertyAll<Color>(
                            Colors.white,
                          ),
                          padding:
                              const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                                EdgeInsets.all(6),
                              ),
                          elevation: const WidgetStatePropertyAll<double>(8),
                          side: const WidgetStatePropertyAll<BorderSide>(
                            BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          shape: WidgetStatePropertyAll<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        menuChildren: [
                          _buildRowMenuItem(
                            label: widget.row.isInactive
                                ? 'Mark as Active'
                                : 'Mark as Inactive',
                            onPressed: () {
                              _menuController.close();
                              widget.onToggleInactive();
                            },
                          ),
                          _buildRowMenuItem(
                            label: 'Delete',
                            onPressed: () {
                              _menuController.close();
                              ZerpaiToast.info(
                                context,
                                'Delete is not available yet',
                              );
                            },
                          ),
                        ],
                        builder: (context, controller, child) {
                          if (_isMenuOpen != controller.isOpen) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) {
                                return;
                              }
                              setState(() => _isMenuOpen = controller.isOpen);
                            });
                          }
                          return InkWell(
                            onTap: () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.moreVertical,
                                size: 14,
                                color: Color(0xFF111827),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowMenuItem({
    required String label,
    required VoidCallback onPressed,
  }) {
    return _ReportingTagRowMenuItem(label: label, onPressed: onPressed);
  }
}

class _ReportingTagRow {
  const _ReportingTagRow({
    this.id,
    required this.name,
    required this.description,
    required this.mandatory,
    this.options = const <_ReportingTagOption>[],
    this.lineItemModules = const <String>[],
    this.otherModules = const <String>[],
    this.reportingTagLevel,
    this.isInactive = false,
    this.isReady = false,
  });

  final String? id;
  final String name;
  final String description;
  final String mandatory;
  final List<_ReportingTagOption> options;
  final List<String> lineItemModules;
  final List<String> otherModules;
  final _ReportingTagLevel? reportingTagLevel;
  final bool isInactive;
  final bool isReady;

  _ReportingTagRow copyWith({
    String? id,
    String? name,
    String? description,
    String? mandatory,
    List<_ReportingTagOption>? options,
    List<String>? lineItemModules,
    List<String>? otherModules,
    _ReportingTagLevel? reportingTagLevel,
    bool? isInactive,
    bool? isReady,
  }) {
    return _ReportingTagRow(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      mandatory: mandatory ?? this.mandatory,
      options: options ?? this.options,
      lineItemModules: lineItemModules ?? this.lineItemModules,
      otherModules: otherModules ?? this.otherModules,
      reportingTagLevel: reportingTagLevel ?? this.reportingTagLevel,
      isInactive: isInactive ?? this.isInactive,
      isReady: isReady ?? this.isReady,
    );
  }
}

class _ReportingTagEditDraft {
  const _ReportingTagEditDraft({required this.row});

  final _ReportingTagRow row;
}

class _ReportingTagOption {
  const _ReportingTagOption({
    required this.label,
    this.level = 0,
    this.isDefault = false,
    this.isInactive = false,
  });

  final String label;
  final int level;
  final bool isDefault;
  final bool isInactive;

  _ReportingTagOption copyWith({
    String? label,
    int? level,
    bool? isDefault,
    bool? isInactive,
  }) {
    return _ReportingTagOption(
      label: label ?? this.label,
      level: level ?? this.level,
      isDefault: isDefault ?? this.isDefault,
      isInactive: isInactive ?? this.isInactive,
    );
  }
}

class _ReportingTagRowMenuItem extends StatefulWidget {
  const _ReportingTagRowMenuItem({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_ReportingTagRowMenuItem> createState() =>
      _ReportingTagRowMenuItemState();
}

class _ReportingTagRowMenuItemState extends State<_ReportingTagRowMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    return MouseRegion(
      onEnter: (_) {
        if (isEnabled) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 132,
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered && isEnabled
                ? const Color(0xFF268DDD)
                : Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: AppTheme.bodyText.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: !isEnabled
                  ? const Color(0xFF9CA3AF)
                  : (_isHovered ? Colors.white : const Color(0xFF4B5563)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportingTagDetailOptionRow extends StatefulWidget {
  const _ReportingTagDetailOptionRow({
    required this.option,
    required this.isFirst,
    required this.isLast,
    required this.onToggleDefault,
    required this.onToggleInactive,
  });

  final _ReportingTagOption option;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onToggleDefault;
  final VoidCallback? onToggleInactive;

  @override
  State<_ReportingTagDetailOptionRow> createState() =>
      _ReportingTagDetailOptionRowState();
}

class _ReportingTagDetailOptionRowState
    extends State<_ReportingTagDetailOptionRow> {
  bool _isHovered = false;
  final MenuController _menuController = MenuController();
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final showActions = _isHovered || _isMenuOpen;
    final isInactive = widget.option.isInactive;
    final rowBackgroundColor = isInactive
        ? const Color(0xFFF3F4F6)
        : Colors.white;
    final optionTextColor = isInactive
        ? const Color(0xFF9CA3AF)
        : (widget.isFirst ? const Color(0xFF6C718A) : const Color(0xFF111827));
    final bulletColor = isInactive
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF111827);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: rowBackgroundColor,
          border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: widget.option.level * 28),
                  if (widget.option.level > 0) ...[
                    Text(
                      '•',
                      style: TextStyle(fontSize: 15, color: bulletColor),
                    ),
                    const SizedBox(width: 8),
                  ],
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.option.label,
                          style: AppTheme.bodyText.copyWith(
                            fontSize: widget.isFirst ? 12.5 : 14,
                            fontWeight: widget.isFirst
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: optionTextColor,
                          ),
                        ),
                        if (widget.option.isInactive)
                          TextSpan(
                            text: ' (Inactive)',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF7C879D),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.option.isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF388A10),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Default',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: showActions ? 1 : 0,
              child: IgnorePointer(
                ignoring: !showActions,
                child: MenuAnchor(
                  controller: _menuController,
                  consumeOutsideTap: true,
                  alignmentOffset: const Offset(-104, 8),
                  style: MenuStyle(
                    backgroundColor: const WidgetStatePropertyAll<Color>(
                      Colors.white,
                    ),
                    surfaceTintColor: const WidgetStatePropertyAll<Color>(
                      Colors.white,
                    ),
                    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                      EdgeInsets.all(6),
                    ),
                    elevation: const WidgetStatePropertyAll<double>(8),
                    side: const WidgetStatePropertyAll<BorderSide>(
                      BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    shape: WidgetStatePropertyAll<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  menuChildren: [
                    _ReportingTagRowMenuItem(
                      label: widget.option.isInactive
                          ? 'Mark as Default'
                          : (widget.option.isDefault
                                ? 'Clear Default'
                                : 'Mark as Default'),
                      onPressed: widget.option.isInactive
                          ? null
                          : () {
                              _menuController.close();
                              widget.onToggleDefault?.call();
                            },
                    ),
                    _ReportingTagRowMenuItem(
                      label: widget.option.isInactive
                          ? 'Mark as Active'
                          : 'Mark as Inactive',
                      onPressed: widget.option.isDefault
                          ? null
                          : () {
                              _menuController.close();
                              widget.onToggleInactive?.call();
                            },
                    ),
                  ],
                  builder: (context, controller, child) {
                    if (_isMenuOpen != controller.isOpen) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) {
                          return;
                        }
                        setState(() => _isMenuOpen = controller.isOpen);
                      });
                    }
                    return InkWell(
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(
                          LucideIcons.moreVertical,
                          size: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsHelpSidebar extends StatefulWidget {
  const _OptionsHelpSidebar({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_OptionsHelpSidebar> createState() => _OptionsHelpSidebarState();
}

class _OptionsHelpSidebarState extends State<_OptionsHelpSidebar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _handleClose,
            child: Container(color: Colors.black.withValues(alpha: 0.12)),
          ),
        ),
        SlideTransition(
          position: _offsetAnimation,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 380,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  left: BorderSide(color: AppTheme.borderLight),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(-3, 0),
                  ),
                ],
              ),
              child: Material(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: const Color(0xFFF5F6FB),
                      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'How Options Work',
                              style: AppTheme.pageTitle.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _handleClose,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                LucideIcons.x,
                                size: 20,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE5E7EB),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(26, 34, 26, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHelpPreviewCard(),
                            const SizedBox(height: 28),
                            _buildHelpBullet(
                              'Options in reporting tags represent specific '
                              'values associated with a tag. They help you '
                              'define precise terms that suit your business '
                              'needs and allow you to segment your financial '
                              'data more efficiently.',
                            ),
                            const SizedBox(height: 14),
                            _buildHelpBullet(
                              'You can also assign hierarchical relationships '
                              'to options, organizing them in a parent-child '
                              'format. This allows for multi-level '
                              'classification of financial transactions.',
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
    );
  }

  Widget _buildHelpPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FE),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE3E8F3)),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Text(
                  'Selected Options',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFA0ABC0),
                  ),
                ),
                const Spacer(),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 12,
                  color: Color(0xFFB2BCD0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8ECF7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreviewLabel('Department (DEP - 01)'),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 18,
                      child: Column(
                        children: [
                          Container(
                            width: 10,
                            height: 20,
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(color: Color(0xFFE1E6F1)),
                                top: BorderSide(color: Color(0xFFE1E6F1)),
                              ),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 54,
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(color: Color(0xFFE1E6F1)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPreviewLabel('HR (DEPT - 02)'),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 18,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: Color(0xFFE1E6F1),
                                          ),
                                          top: BorderSide(
                                            color: Color(0xFFE1E6F1),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPreviewLabel('Finance (DEPT - 03)'),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECEFFF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Engineering (DEPT - 04)',
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF7381A0),
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
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  child: Column(
                    children: [
                      Container(
                        width: 112,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCED6EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 54,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E6F3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 34,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E6F3),
                              borderRadius: BorderRadius.circular(999),
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
        ],
      ),
    );
  }

  Widget _buildPreviewLabel(String text) {
    return Text(
      text,
      style: AppTheme.bodyText.copyWith(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF8A95AD),
      ),
    );
  }

  Widget _buildHelpBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(LucideIcons.sparkles, size: 12, color: Color(0xFFFF8A3D)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodyText.copyWith(
              fontSize: 15,
              height: 1.55,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportOptionsDialog extends StatefulWidget {
  const _ExportOptionsDialog({required this.onExport});

  final void Function(_ReportingTagExportFormat format, String password)
  onExport;

  @override
  State<_ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<_ExportOptionsDialog> {
  final TextEditingController _passwordController = TextEditingController();
  _ReportingTagExportFormat _selectedFormat = _ReportingTagExportFormat.csv;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 668),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Export',
                        style: AppTheme.pageTitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD5E4FF)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              LucideIcons.info,
                              size: 16,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You can export your data from Zoho Inventory in CSV, XLS or XLSX format.',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 14,
                                color: const Color(0xFF4B5563),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0F2F6),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Export File Format*',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.errorRed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFormatOption(
                      value: _ReportingTagExportFormat.csv,
                      label: 'CSV (Comma Separated Value)',
                    ),
                    const SizedBox(height: 6),
                    _buildFormatOption(
                      value: _ReportingTagExportFormat.xls,
                      label: 'XLS (Microsoft Excel 1997-2004 Compatible)',
                    ),
                    const SizedBox(height: 6),
                    _buildFormatOption(
                      value: _ReportingTagExportFormat.xlsx,
                      label: 'XLSX (Microsoft Excel)',
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'File Protection Password',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 300,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          CustomTextField(
                            controller: _passwordController,
                            height: 34,
                            obscureText: _obscurePassword,
                            forceUppercase: false,
                            contentCase: ContentCase.none,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          Positioned(
                            right: 8,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  _obscurePassword
                                      ? LucideIcons.eye
                                      : LucideIcons.eyeOff,
                                  size: 16,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 318,
                      child: Text(
                        'Your password must be at least 12 characters and include one uppercase letter, lowercase letter, number, and special character.',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 12.5,
                          color: const Color(0xFF7C87A0),
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Row(
                  children: [
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => widget.onExport(
                          _selectedFormat,
                          _passwordController.text,
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text(
                          'Export',
                          style: AppTheme.buttonText.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8FAFC),
                          side: const BorderSide(color: Color(0xFFDDE3ED)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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

  Widget _buildFormatOption({
    required _ReportingTagExportFormat value,
    required String label,
  }) {
    final isSelected = _selectedFormat == value;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = value),
      child: Row(
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFC7D0E0),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: isSelected
                ? Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF3B82F6),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatefulWidget {
  const _OptionRow({
    super.key,
    required this.index,
    required this.controller,
    required this.level,
    required this.isLast,
    required this.canDelete,
    required this.onDelete,
    required this.onInsertAbove,
    required this.onInsertBelow,
    required this.onInsertChild,
  });

  final int index;
  final TextEditingController controller;
  final int level;
  final bool isLast;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onInsertAbove;
  final VoidCallback onInsertBelow;
  final VoidCallback onInsertChild;

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  static const Color _optionFocusBorderColor = Color(0xFFBFDBFE);
  bool _isHovered = false;
  final MenuController _insertMenuController = MenuController();
  late final FocusNode _optionFocusNode;

  void _runDeferredInsertAction(VoidCallback action) {
    _insertMenuController.close();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        action();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _optionFocusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _optionFocusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double rowHorizontalPadding = 16;
    const double connectorHeight = 20;
    const double connectorButtonSize = 20;
    final double levelIndent = widget.level * 36;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: SizedBox(
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: rowHorizontalPadding,
              ),
              decoration: BoxDecoration(
                border: widget.isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: _isHovered
                              ? Colors.transparent
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
              ),
              child: Row(
                children: [
                  SizedBox(width: levelIndent),
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Icon(
                        LucideIcons.gripVertical,
                        size: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 290,
                        child: CustomTextField(
                          controller: widget.controller,
                          focusNode: _optionFocusNode,
                          height: 40,
                          hintText: 'Enter the option name',
                          forceUppercase: false,
                          contentCase: ContentCase.none,
                          hideBorderDefault: true,
                          border: Border(
                            top: BorderSide(
                              color: _optionFocusNode.hasFocus
                                  ? _optionFocusBorderColor
                                  : Colors.transparent,
                            ),
                            bottom: BorderSide(
                              color: _optionFocusNode.hasFocus
                                  ? _optionFocusBorderColor
                                  : Colors.transparent,
                            ),
                            left: BorderSide(
                              color: _optionFocusNode.hasFocus
                                  ? _optionFocusBorderColor
                                  : Colors.transparent,
                            ),
                            right: BorderSide(
                              color: _optionFocusNode.hasFocus
                                  ? _optionFocusBorderColor
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.canDelete) ...[
                    const SizedBox(width: 12),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: _isHovered ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !_isHovered,
                        child: InkWell(
                          onTap: widget.onDelete,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 34,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFD9DEE8),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.trash2,
                              size: 15,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: rowHorizontalPadding,
              right: rowHorizontalPadding,
              bottom: -1,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _isHovered ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !_isHovered,
                  child: SizedBox(
                    height: connectorHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: 1,
                              width: double.infinity,
                              child: ColoredBox(color: AppTheme.infoBlue),
                            ),
                          ),
                        ),
                        MenuAnchor(
                          controller: _insertMenuController,
                          consumeOutsideTap: true,
                          style: MenuStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.white,
                            ),
                            surfaceTintColor: WidgetStateProperty.all(
                              Colors.white,
                            ),
                            padding: WidgetStateProperty.all(EdgeInsets.zero),
                            elevation: WidgetStateProperty.all(6),
                            side: WidgetStateProperty.all(
                              const BorderSide(color: Color(0xFFD9DEE8)),
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          menuChildren: [
                            SizedBox(
                              width: 160,
                              child: _OptionInsertMenu(
                                onInsertAbove: () {
                                  _runDeferredInsertAction(
                                    widget.onInsertAbove,
                                  );
                                },
                                onInsertBelow: () {
                                  _runDeferredInsertAction(
                                    widget.onInsertBelow,
                                  );
                                },
                                onInsertChild: () {
                                  _runDeferredInsertAction(
                                    widget.onInsertChild,
                                  );
                                },
                              ),
                            ),
                          ],
                          builder: (context, controller, child) {
                            return InkWell(
                              onTap: () {
                                if (controller.isOpen) {
                                  controller.close();
                                } else {
                                  controller.open();
                                }
                              },
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: connectorButtonSize,
                                height: connectorButtonSize,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.infoBlue,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.infoBlue.withValues(
                                        alpha: 0.26,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  LucideIcons.plus,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
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
    );
  }
}

class _OptionInsertMenu extends StatelessWidget {
  const _OptionInsertMenu({
    required this.onInsertAbove,
    required this.onInsertBelow,
    required this.onInsertChild,
  });

  final VoidCallback onInsertAbove;
  final VoidCallback onInsertBelow;
  final VoidCallback onInsertChild;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OptionInsertMenuItem(label: 'Add Option Above', onTap: onInsertAbove),
        _OptionInsertMenuItem(label: 'Add Option Below', onTap: onInsertBelow),
        _OptionInsertMenuItem(label: 'Add Child Option', onTap: onInsertChild),
      ],
    );
  }
}

class _OptionInsertMenuItem extends StatefulWidget {
  const _OptionInsertMenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_OptionInsertMenuItem> createState() => _OptionInsertMenuItemState();
}

class _OptionInsertMenuItemState extends State<_OptionInsertMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: _isHovered ? const Color(0xFF3B82F6) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            widget.label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _isHovered ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionDraft {
  _OptionDraft({required this.controller, this.level = 0});

  final TextEditingController controller;
  final int level;
}
