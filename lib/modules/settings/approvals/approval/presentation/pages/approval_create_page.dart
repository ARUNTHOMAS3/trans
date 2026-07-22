import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/settings/approvals/approval/presentation/providers/approval_provider.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class ApprovalCreatePage extends ConsumerStatefulWidget {
  const ApprovalCreatePage({super.key});

  @override
  ConsumerState<ApprovalCreatePage> createState() =>
      _ApprovalCreatePageState();
}

class _ApprovalCreatePageState
    extends ConsumerState<ApprovalCreatePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _seriesNameController = TextEditingController();

  final List<_SeriesCreateRow> _rows = _seedRows
      .map((row) => row.copy())
      .toList(growable: false);
  bool _didLoadInitialRecord = false;
  int? _editingIndex;
  String? _selectedModule;
  String? _selectedApprovalType;
  bool _sendEmailAndInApp = false;
  bool _notifySubmitter = false;
  int _selectedNotificationReceiver = 1;
  final TextEditingController _specificEmailController = TextEditingController();
  final List<String?> _levels = [null];
  final List<UniqueKey> _levelKeys = [UniqueKey()];

  static const List<String> _modulesList = [
    'Vendor Payment',
    'Retainer Invoice',
    'Purchase Order',
    'Credit Note',
    'Customer Payment',
    'Delivery Challan',
    'Bill Of Supply',
    'Invoice',
    'Sales Order',
    'Self-Invoice',
  ];

  static const List<String> _approvalTypesList = [
    'Simple approval',
    'Multi-level Approval',
  ];

  static const Map<String, String> _approverEmails = {
    'zabnixprivatelimited': 'zabnixprivatelimited@gmail.com',
    'admin@zerpai.com': 'admin@zerpai.com',
    'manager@zerpai.com': 'manager@zerpai.com',
  };

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _seriesNameController.dispose();
    for (final row in _rows) {
      row.prefixController.dispose();
      row.startingController.dispose();
    }
    _specificEmailController.dispose();
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ??
        '6000000000';
    return '/$orgSystemId$route';
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialRecord) return;
    _didLoadInitialRecord = true;

    final editIndexParam = GoRouterState.of(context).uri.queryParameters['editIndex'];
    final editIndex = int.tryParse(editIndexParam ?? '');
    if (editIndex == null) return;

    final records = ref.read(ApprovalProvider);
    if (editIndex < 0 || editIndex >= records.length) return;

    _editingIndex = editIndex;
    _loadRecordForEdit(records[editIndex]);
  }

  void _loadRecordForEdit(ApprovalRecord record) {
    _seriesNameController.text = record.seriesName;
    final parts = record.seriesName.split(' - ');
    if (parts.length >= 2) {
      _selectedModule = parts[0];
      _selectedApprovalType = parts[1];
    } else {
      _selectedModule = record.seriesName;
      _selectedApprovalType = 'Simple approval';
    }

    final moduleValues = <String, String>{
      'Vendor Payment': record.vendorPayment,
      'Retainer Invoice': record.retainerInvoice,
      'Purchase Order': record.purchaseOrder,
      'Credit Note': record.creditNote,
      'Customer Payment': record.customerPayment,
      'Delivery Challan': record.deliveryChallan,
      'Bill Of Supply': record.billOfSupply,
      'Invoice': record.invoice,
      'Sales Order': record.salesOrder,
      'Self-Invoice': record.selfInvoice,
    };

    for (final row in _rows) {
      final rawValue = moduleValues[row.module];
      if (rawValue == null) continue;
      final split = _splitSeriesValue(
        rawValue,
        expectedStartingLength: row.startingNumber.length,
      );
      row.prefixController.text = split.$1;
      row.startingController.text = split.$2;
    }
  }

  (String, String) _splitSeriesValue(
    String value, {
    required int expectedStartingLength,
  }) {
    if (value.isEmpty) return ('', '');
    if (value.length <= expectedStartingLength) return ('', value);
    return (
      value.substring(0, value.length - expectedStartingLength),
      value.substring(value.length - expectedStartingLength),
    );
  }

  String _seriesValueForModule(String moduleName) {
    for (final row in _rows) {
      if (row.module == moduleName) {
        return '${row.prefixController.text}${row.startingController.text}';
      }
    }
    return '';
  }

  void _saveSeries() {
    if (_selectedModule == null || _selectedModule!.isEmpty) {
      ZerpaiToast.error(context, 'Module is required');
      return;
    }
    if (_selectedApprovalType == null || _selectedApprovalType!.isEmpty) {
      ZerpaiToast.error(context, 'Approval Type is required');
      return;
    }
    final seriesName = '$_selectedModule - $_selectedApprovalType';

    final record = ApprovalRecord(
      seriesName: seriesName,
      vendorPayment: _seriesValueForModule('Vendor Payment'),
      retainerInvoice: _seriesValueForModule('Retainer Invoice'),
      purchaseOrder: _seriesValueForModule('Purchase Order'),
      creditNote: _seriesValueForModule('Credit Note'),
      customerPayment: _seriesValueForModule('Customer Payment'),
      deliveryChallan: _seriesValueForModule('Delivery Challan'),
      billOfSupply: _seriesValueForModule('Bill Of Supply'),
      invoice: _seriesValueForModule('Invoice'),
      salesOrder: _seriesValueForModule('Sales Order'),
      selfInvoice: _seriesValueForModule('Self-Invoice'),
      associatedLocations: '--',
    );

    final notifier = ref.read(ApprovalProvider.notifier);
    if (_editingIndex != null) {
      notifier.updateSeries(_editingIndex!, record);
    } else {
      notifier.addSeries(record);
    }

    context.go(_withOrgPrefix(AppRoutes.settingsApproval));
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
                                ? 'Edit Approval'
                                : 'New Approval',
                            onClose: () => context.go(
                              _withOrgPrefix(
                                AppRoutes.settingsApproval,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                28,
                                24,
                                0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FormRow(
                                    label: 'Module*',
                                    labelColor: const Color(0xFFFF2E2E),
                                    child: SizedBox(
                                      width: 490,
                                      child: FormDropdown<String>(
                                        height: 38,
                                        value: _selectedModule,
                                        items: _modulesList,
                                        onChanged: (v) {
                                          if (v != null) {
                                            setState(() => _selectedModule = v);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _FormRow(
                                    label: 'Approval Type*',
                                    labelColor: const Color(0xFFFF2E2E),
                                    child: SizedBox(
                                      width: 490,
                                      child: FormDropdown<String>(
                                        height: 38,
                                        value: _selectedApprovalType,
                                        items: _approvalTypesList,
                                        onChanged: (v) {
                                          if (v != null) {
                                            setState(() => _selectedApprovalType = v);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  if (_selectedApprovalType == 'Simple approval')
                                    _buildSimpleApprovalSection(),
                                  if (_selectedApprovalType == 'Multi-level Approval')
                                    _buildMultiLevelApprovalSection(),
                                ],
                              ),
                            ),
                          ),
                          _CreateFooter(
                            onSave: _saveSeries,
                            onCancel: () => context.go(
                              _withOrgPrefix(
                                AppRoutes.settingsApproval,
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

  Widget _buildSimpleApprovalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 24),
        Text(
          'Approvers',
          style: AppTheme.bodyText.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'zabnixprivatelimited',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'zabnixprivatelimited@gmail.com',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 24),
        Text(
          'Notification Preferences',
          style: AppTheme.bodyText.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        _buildCheckboxRow(
          value: _sendEmailAndInApp,
          label: 'Send email and in-app notifications when transactions are submitted for approval',
          onChanged: (val) {
            if (val != null) {
              setState(() => _sendEmailAndInApp = val);
            }
          },
        ),
        if (_sendEmailAndInApp) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRadioRow(
                  value: 1,
                  label: 'Notify all approvers when a non-approver submits a transaction',
                ),
                const SizedBox(height: 12),
                _buildRadioRow(
                  value: 2,
                  label: 'Notify all approvers when an approver/non-approver submits a transaction',
                ),
                const SizedBox(height: 12),
                _buildRadioRow(
                  value: 3,
                  label: 'Notify a specific email address',
                ),
                if (_selectedNotificationReceiver == 3) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: SizedBox(
                      width: 490,
                      child: CustomTextField(
                        controller: _specificEmailController,
                        height: 38,
                        forceUppercase: false,
                        contentCase: ContentCase.none,
                        fillColor: Colors.white,
                        hintText: 'abc@example.com',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildCheckboxRow(
          value: _notifySubmitter,
          label: 'Notify the submitter when a transaction is approved or rejected',
          onChanged: (val) {
            if (val != null) {
              setState(() => _notifySubmitter = val);
            }
          },
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
      ],
    );
  }

  Widget _buildRadioRow({
    required int value,
    required String label,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Radio<int>(
            value: value,
            groupValue: _selectedNotificationReceiver,
            activeColor: const Color(0xFF3B82F6),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedNotificationReceiver = val);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(
              color: Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiLevelApprovalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 24),
        Text(
          'SET THE APPROVAL HIERARCHY',
          style: AppTheme.captionText.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(
          width: 752,
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 752,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 712,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0)),
                    left: BorderSide(color: Color(0xFFE2E8F0)),
                    right: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'PRIORITY',
                          style: AppTheme.captionText.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'APPROVER NAME',
                          style: AppTheme.captionText.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 712,
                height: 1,
                color: const Color(0xFFE2E8F0),
              ),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _levels.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _levels.removeAt(oldIndex);
                    _levels.insert(newIndex, item);
                    final key = _levelKeys.removeAt(oldIndex);
                    _levelKeys.insert(newIndex, key);
                  });
                },
                itemBuilder: (context, i) {
                  return Column(
                    key: _levelKeys[i],
                    children: [
                      SizedBox(
                        width: 752,
                        height: 52,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 712,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  left: BorderSide(color: Color(0xFFE2E8F0)),
                                  right: BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        children: [
                                          ReorderableDragStartListener(
                                            index: i,
                                            child: const MouseRegion(
                                              cursor: SystemMouseCursors.grab,
                                              child: Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(
                                                  Icons.drag_indicator,
                                                  size: 16,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Level ${i + 1} : Approver',
                                            style: AppTheme.bodyText.copyWith(
                                              fontSize: 13,
                                              color: const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                                  Expanded(
                                    flex: 7,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      child: FormDropdown<String>(
                                        height: 38,
                                        value: _levels[i],
                                        border: Border.all(color: Colors.transparent),
                                        fillColor: Colors.transparent,
                                        activeBorderColor: Colors.transparent,
                                        items: const [
                                          'zabnixprivatelimited',
                                          'admin@zerpai.com',
                                          'manager@zerpai.com',
                                        ],
                                        itemBuilder: (item, isSelected, isHovered) {
                                          final email = _approverEmails[item] ?? item;
                                          final textColor = isHovered ? Colors.white : const Color(0xFF1E293B);
                                          final emailColor = isHovered ? Colors.white70 : const Color(0xFF64748B);
                                          final bg = isHovered ? const Color(0xFF3B82F6) : Colors.transparent;
                                          return Container(
                                            color: bg,
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  item,
                                                  style: AppTheme.bodyText.copyWith(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: textColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '[$email]',
                                                  style: AppTheme.bodyText.copyWith(
                                                    fontSize: 11,
                                                    color: emailColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _levels[i] = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _levels.length <= 1
                                    ? const SizedBox.shrink()
                                    : Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _levels.removeAt(i);
                                              _levelKeys.removeAt(i);
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(999),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Color(0xFFEF4444),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(2),
                                                child: Icon(
                                                  LucideIcons.minus,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 712,
                          height: 1,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  );
                },
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _levels.add(null);
                    _levelKeys.add(UniqueKey());
                  });
                },
                child: Container(
                  width: 712,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      left: BorderSide(color: Color(0xFFE2E8F0)),
                      right: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add New Level',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 752,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOTE:',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1.) The approvers you select here can approve transactions directly from Zoho Inventory if they are approvers in Zoho Inventory as well.',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '2.) Admins can bypass multiple levels of approval and approve transactions once and for all. They can do this by selecting the transaction > More > Final Approve.',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 24),
        Text(
          'Notification Preferences',
          style: AppTheme.bodyText.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        _buildCheckboxRow(
          value: _sendEmailAndInApp,
          label: 'Send email and in-app notifications when transactions are submitted for approval',
          onChanged: (val) {
            if (val != null) {
              setState(() => _sendEmailAndInApp = val);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildCheckboxRow(
          value: _notifySubmitter,
          label: 'Notify the submitter when a transaction is approved or rejected',
          onChanged: (val) {
            if (val != null) {
              setState(() => _notifySubmitter = val);
            }
          },
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
      ],
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
                  const Icon(
                    Icons.close,
                    size: 15,
                    color: Color(0xFFFF5C73),
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

class _CreatePaneHeader extends StatelessWidget {
  const _CreatePaneHeader({
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: AppTheme.pageTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 20,
                color: Color(0xFFFF4A4A),
              ),
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
  });

  final String label;
  final Widget child;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 262,
          child: Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 15,
              color: labelColor ?? Colors.black,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CreateFooter extends StatelessWidget {
  const _CreateFooter({
    required this.onSave,
    required this.onCancel,
  });

  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 36,
            child: ZButton.primary(
              label: 'Save',
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: onSave,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 36,
            child: ZButton.secondary(
              label: 'Cancel',
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: onCancel,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesCreateRow {
  final String module;
  final String prefix;
  final String startingNumber;
  final String preview;
  final TextEditingController prefixController;
  final TextEditingController startingController;
  String restartNumbering;
  String? selectedPlaceholder;
  String? selectedPlaceholderValue;

  _SeriesCreateRow({
    required this.module,
    required this.prefix,
    required this.startingNumber,
    required this.preview,
    this.restartNumbering = 'None',
    this.selectedPlaceholder,
    this.selectedPlaceholderValue,
  })  : prefixController = TextEditingController(text: prefix),
        startingController = TextEditingController(text: startingNumber);

  _SeriesCreateRow copy() => _SeriesCreateRow(
    module: module,
    prefix: prefix,
    startingNumber: startingNumber,
    preview: preview,
    restartNumbering: restartNumbering,
    selectedPlaceholder: selectedPlaceholder,
    selectedPlaceholderValue: selectedPlaceholderValue,
  );

  String get previewText => '${prefixController.text}${startingController.text}';
}

class _SeriesCreateSeed {
  const _SeriesCreateSeed({
    required this.module,
    required this.prefix,
    required this.startingNumber,
    required this.preview,
    this.restartNumbering = 'None',
  });

  final String module;
  final String prefix;
  final String startingNumber;
  final String preview;
  final String restartNumbering;

  _SeriesCreateRow copy() => _SeriesCreateRow(
    module: module,
    prefix: prefix,
    startingNumber: startingNumber,
    preview: preview,
    restartNumbering: restartNumbering,
  );
}

final List<_SeriesCreateSeed> _seedRows = [
  _SeriesCreateSeed(
    module: 'Credit Note',
    prefix: 'CN-',
    startingNumber: '00001',
    preview: 'CN-00001',
  ),
  _SeriesCreateSeed(
    module: 'Customer Payment',
    prefix: '',
    startingNumber: '1',
    preview: '1',
  ),
  _SeriesCreateSeed(
    module: 'Purchase Order',
    prefix: 'PO-',
    startingNumber: '00001',
    preview: 'PO-00001',
  ),
  _SeriesCreateSeed(
    module: 'Sales Order',
    prefix: 'SO-',
    startingNumber: '00001',
    preview: 'SO-00001',
  ),
  _SeriesCreateSeed(
    module: 'Vendor Payment',
    prefix: '',
    startingNumber: '1',
    preview: '1',
  ),
  _SeriesCreateSeed(
    module: 'Retainer Invoice',
    prefix: 'RET-',
    startingNumber: '00001',
    preview: 'RET-00001',
  ),
  _SeriesCreateSeed(
    module: 'Bill Of Supply',
    prefix: 'BOS-',
    startingNumber: '000001',
    preview: 'BOS-000001',
  ),
  _SeriesCreateSeed(
    module: 'Invoice',
    prefix: 'INV-',
    startingNumber: '000001',
    preview: 'INV-000001',
  ),
  _SeriesCreateSeed(
    module: 'Delivery Challan',
    prefix: 'DC-',
    startingNumber: '00001',
    preview: 'DC-00001',
    restartNumbering: 'Yearly',
  ),
  _SeriesCreateSeed(
    module: 'Self-Invoice',
    prefix: '',
    startingNumber: '1',
    preview: '1',
  ),
];
