import 'package:flutter/material.dart';
import 'package:web/web.dart' as import_web;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_data_table_shell.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_search_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
// 
import '../models/inventory_picklist_model.dart';
import '../providers/inventory_picklists_provider.dart';
import 'package:zerpai_erp/modules/auth/providers/user_provider.dart';

class _ClearPicklistSelectionIntent extends Intent {
  const _ClearPicklistSelectionIntent();
}

/// Performance-optimized List Screen for Inventory Picklists.
/// Supports master-detail view when [id] is provided.
class InventoryPicklistsListScreen extends ConsumerStatefulWidget {
  final String? id;

  const InventoryPicklistsListScreen({super.key, this.id});

  @override
  ConsumerState<InventoryPicklistsListScreen> createState() =>
      _InventoryPicklistsListScreenState();
}

class _InventoryPicklistsListScreenState
    extends ConsumerState<InventoryPicklistsListScreen> {
  String _selectedView = 'All';
  final Set<String> _selectedPicklistIds = {};
  final List<String> _visibleColumns = [
    'date',
    'picklist#',
    'status',
    'assignee',
    'location',
    'notes',
    'customer_name',
    'sales_order_number',
  ];

  bool _showSearchSalesOrder = false;
  bool _showSearchCustomer = false;
  String _salesOrderSearchQuery = '';
  String _customerSearchQuery = '';
  final TextEditingController _salesOrderSearchCtrl = TextEditingController();
  final TextEditingController _customerSearchCtrl = TextEditingController();

  bool _shouldWrapText = false;
  Map<String, double>? _customColumnWidths;

  final Map<String, String> _columnLabels = {
    'date': 'DATE',
    'picklist#': 'PICKLIST#',
    'status': 'STATUS',
    'assignee': 'ASSIGNEE',
    'location': 'LOCATION',
    'notes': 'NOTES',
    'customer_name': 'CUSTOMER NAME',
    'sales_order_number': 'SALES ORDER#',
  };

  void _toggleSelection(String id) {
    if (id.isEmpty) return;
    setState(() {
      if (_selectedPicklistIds.contains(id)) {
        _selectedPicklistIds.remove(id);
      } else {
        _selectedPicklistIds.add(id);
      }
    });
  }

  void _toggleAll(List<Picklist> picklists) {
    setState(() {
      if (_selectedPicklistIds.length == picklists.length) {
        _selectedPicklistIds.clear();
      } else {
        _selectedPicklistIds.clear();
        for (final p in picklists) {
          if (p.id != null) {
            _selectedPicklistIds.add(p.id!);
          }
        }
      }
    });
  }

  void _showCustomizeColumnsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.list,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Customize Columns',
                          style: AppTheme.sectionHeader,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.bgDisabled,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_visibleColumns.length} of ${_columnLabels.length} Selected',
                            style: AppTheme.metaHelper,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            LucideIcons.x,
                            size: 20,
                            color: AppTheme.errorRed,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const ZSearchField(hintText: 'Search columns...'),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: SingleChildScrollView(
                        child: Column(
                          children: _columnLabels.entries.map((entry) {
                            final isVisible = _visibleColumns.contains(
                              entry.key,
                            );
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  if (isVisible) {
                                    if (_visibleColumns.length > 1) {
                                      _visibleColumns.remove(entry.key);
                                    }
                                  } else {
                                    _visibleColumns.add(entry.key);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.gripVertical,
                                      size: 16,
                                      color: AppTheme.borderColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isVisible
                                          ? LucideIcons.checkSquare
                                          : LucideIcons.square,
                                      size: 18,
                                      color: isVisible
                                          ? AppTheme.primaryBlue
                                          : AppTheme.borderColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      entry.value,
                                      style: AppTheme.bodyText.copyWith(
                                        color: isVisible
                                            ? AppTheme.textPrimary
                                            : AppTheme.textSecondary,
                                        fontWeight: isVisible
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        ZButton.primary(
                          label: 'Save',
                          onPressed: () {
                            setState(() {}); // Apply visible columns
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(width: 12),
                        ZButton.secondary(
                          label: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isNewCustomViewOpen = false;

  @override
  Widget build(BuildContext context) {
    final picklistsAsync = ref.watch(picklistsProvider);
    final isDetailOpen = widget.id != null;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape):
            const _ClearPicklistSelectionIntent(),
      },
      child: Actions(
        actions: {
          _ClearPicklistSelectionIntent:
              CallbackAction<_ClearPicklistSelectionIntent>(
                onInvoke: (intent) {
                  _clearSelection();
                  return null;
                },
              ),
        },
        child: Focus(
          autofocus: true,
          child: ZerpaiLayout(
            pageTitle: '',
            enableBodyScroll: false,
            useHorizontalPadding: false,
            useTopPadding: false,
            child: picklistsAsync.when(
              data: (picklists) => Stack(
                children: [
                  if (isDetailOpen)
                    _buildSplitView(picklists)
                  else
                    Column(
                      children: [
                        _buildToolbar(picklists),
                        Expanded(child: _buildVirtualizedTable(picklists)),
                      ],
                    ),
                  if (_selectedPicklistIds.isNotEmpty && !isDetailOpen)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildSelectionActionsPopupBar(),
                    ),
                  // Removed the top Positioned selection bar as it's now integrated into the left panel header
                  if (_isNewCustomViewOpen)
                    Positioned.fill(
                      child: NewCustomViewOverlay(
                        onClose: () =>
                            setState(() => _isNewCustomViewOpen = false),
                      ),
                    ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitView(List<Picklist> picklists) {
    return Row(
      children: [
        // Left Panel (Fixed Width List)
        SizedBox(
          width: 340,
          child: Column(
            children: [
              _buildLeftSplitHeader(),
              const Divider(height: 1, color: AppTheme.borderColor),
              Expanded(child: _buildCompactList(picklists)),
            ],
          ),
        ),
        // Continuous Full-Height Divider
        const VerticalDivider(width: 1, color: AppTheme.borderColor),
        // Right Panel (Expanded Details)
        Expanded(
          child: Column(
            children: [
              _buildRightSplitHeader(picklists),
              const Divider(height: 1, color: AppTheme.borderColor),
              Expanded(
                child: _PicklistDetailPanel(
                  id: widget.id!,
                  onClose: () {
                    final orgId = GoRouterState.of(
                      context,
                    ).pathParameters['orgSystemId']!;
                    context.go('/$orgId/inventory/picklists');
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftSplitHeader() {
    if (_selectedPicklistIds.isNotEmpty) {
      return _buildLeftSelectionHeader();
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: Row(
        children: [
          _buildViewSelector(),
          const Spacer(),
          IconButton(
            onPressed: () {
              final orgId =
                  GoRouterState.of(context).pathParameters['orgSystemId'] ??
                  '0000000000';
              context.push('/$orgId/inventory/picklists/create');
            },
            icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EdgeInsets.zero,
              minimumSize: const Size(28, 28),
              fixedSize: const Size(28, 28),
            ),
          ),
          const SizedBox(width: 8),
          _buildCompactMoreMenu(),
        ],
      ),
    );
  }

  Widget _buildLeftSelectionHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildCheckboxWidget(true, onTap: _clearSelection),
          const SizedBox(width: 12),
          _buildBulkActionsDropdown(),
          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: AppTheme.borderColor),
          const SizedBox(width: 16),
          Text(
            '${_selectedPicklistIds.length} Selected',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _clearSelection,
            icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionsDropdown() {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      builder: (context, controller, child) {
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: InkWell(
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bulk Actions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: [
        _buildBulkMenuItem('Mark as Completed', 'COMPLETED'),
        _buildBulkMenuItem('Mark as On Hold', 'ON_HOLD'),
        _buildBulkMenuItem('Approve', 'APPROVED'),
        _buildBulkMenuItem('Force Complete', 'FORCE_COMPLETE'),
        const Divider(height: 1, color: AppTheme.borderColor),
        _buildBulkMenuItem('Delete', 'DELETE', isDanger: true),
      ],
    );
  }

  Widget _buildBulkMenuItem(
    String label,
    String action, {
    bool isDanger = false,
  }) {
    return MenuItemButton(
      onPressed: () {
        if (action == 'DELETE') {
          _deleteSelectedPicklists();
        } else {
          _applyBulkStatus(action);
        }
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDanger ? AppTheme.errorRed : AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionActionsPopupBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          _buildCheckboxWidget(true, onTap: _clearSelection),
          const SizedBox(width: 16),
          _buildSelectionButton(
            'Mark as Completed',
            () => _applyBulkStatus('COMPLETED'),
          ),
          const SizedBox(width: 12),
          _buildSelectionButton(
            'Mark as On Hold',
            () => _applyBulkStatus('ON_HOLD'),
          ),
          const SizedBox(width: 12),
          _buildSelectionButton('Approve', () => _applyBulkStatus('APPROVED')),
          const SizedBox(width: 12),
          _buildSelectionButton(
            'Force Complete',
            () => _applyBulkStatus('FORCE_COMPLETE'),
          ),
          const SizedBox(width: 12),
          _buildSelectionButton('Delete', _deleteSelectedPicklists),
          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: AppTheme.borderColor),
          const SizedBox(width: 16),
          Text(
            '${_selectedPicklistIds.length} Selected',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            'Esc',
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _clearSelection,
            icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCompactMoreMenu() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 4),
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(
            AppTheme.backgroundColor,
          ),
          surfaceTintColor: const WidgetStatePropertyAll(
            AppTheme.backgroundColor,
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          elevation: const WidgetStatePropertyAll(8),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppTheme.space4)),
            ),
          ),
        ),
        builder: (context, controller, child) {
          return IconButton(
            onPressed: () {
              if (controller.isOpen)
                controller.close();
              else
                controller.open();
            },
            icon: const Icon(
              LucideIcons.moreHorizontal,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          );
        },
        menuChildren: [_buildMoreMenuOptions()],
      ),
    );
  }

  Widget _buildMoreMenuOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SubmenuButton(
          menuStyle: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(
              AppTheme.backgroundColor,
            ),
            surfaceTintColor: const WidgetStatePropertyAll(
              AppTheme.backgroundColor,
            ),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            elevation: const WidgetStatePropertyAll(8),
          ),
          style: _menuItemButtonStyle(isHeader: true),
          menuChildren: [
            _buildSortMenuItem('Date'),
            _buildSortMenuItem('Picklist#'),
            _buildSortMenuItem('Created Time', isActive: true),
            _buildSortMenuItem('Last Modified Time'),
          ],
          child: const Row(
            children: [
              Icon(LucideIcons.arrowUpDown, size: 16),
              SizedBox(width: 12),
              Text(
                'Sort by',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Spacer(),
              Icon(LucideIcons.chevronRight, size: 16),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.bgDisabled),
        MenuItemButton(
          onPressed: () => ref.read(picklistsProvider.notifier).refresh(),
          style: _menuItemButtonStyle(),
          child: const Row(
            children: [
              Icon(LucideIcons.refreshCw, size: 18),
              SizedBox(width: 15),
              Text('Refresh List', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightSplitHeader(List<Picklist> picklists) {
    final picklistAsync = ref.watch(picklistByIdProvider(widget.id!));

    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          picklistAsync.when(
            data: (p) => Text(
              p?.picklistNumber ?? 'Picklist Detail',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            loading: () =>
                const Text('Loading...', style: TextStyle(fontSize: 14)),
            error: (_, __) =>
                const Text('Error', style: TextStyle(fontSize: 14)),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              LucideIcons.messageSquare,
              size: 20,
              color: AppTheme.textSecondary,
            ),
            tooltip: 'Comments',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              final orgId = GoRouterState.of(
                context,
              ).pathParameters['orgSystemId']!;
              context.go('/$orgId/inventory/picklists');
            },
            icon: const Icon(LucideIcons.x, size: 20, color: AppTheme.errorRed),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(List<Picklist> picklists) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _buildViewSelector(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                const Spacer(),
                _buildStatusButtons(picklists),
                const SizedBox(width: 12),
                _buildNewButton(),
                const SizedBox(width: 8),
                _buildMoreMenu(),
                const SizedBox(width: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButtons(List<Picklist> picklists) {
    if (widget.id != null) return const SizedBox.shrink();
    if (_selectedPicklistIds.isNotEmpty) return const SizedBox.shrink();

    int unpicked = 0;

    for (final p in picklists) {
      final s = p.status.toUpperCase().replaceAll(' ', '_');
      if (s == 'YET_TO_PICK' || s == 'YET_TO_START') {
        unpicked++;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderStatusButton(
          'Unpicked',
          unpicked,
          const Color(0xFF6B7280),
          'Yet to Start',
        ),
      ],
    );
  }

  void _clearSelection() {
    if (_selectedPicklistIds.isEmpty) return;
    setState(() => _selectedPicklistIds.clear());
  }

  Future<void> _applyBulkStatus(String status) async {
    final ids = _selectedPicklistIds.toList(growable: false);
    if (ids.isEmpty) return;

    final notifier = ref.read(picklistsProvider.notifier);
    final allPicklists = ref.read(picklistsProvider).value ?? [];

    for (final id in ids) {
      if (status == 'APPROVED') {
        final p = allPicklists.firstWhere((element) => element.id == id);
        final s = p.status.toUpperCase().replaceAll(' ', '_');
        if (s != 'COMPLETED' && s != 'FORCE_COMPLETE') {
          continue; // Only COMPLETED or FORCE_COMPLETE can be APPROVED
        }
      }
      await notifier.updatePicklistStatus(id, status);
    }

    if (!mounted) return;
    _clearSelection();
  }

  Future<void> _deleteSelectedPicklists() async {
    final ids = _selectedPicklistIds.toList(growable: false);
    if (ids.isEmpty) return;

    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Picklists',
      message:
          'Are you sure you want to delete ${ids.length} selected picklist${ids.length == 1 ? '' : 's'}? This action cannot be undone.',
      confirmLabel: 'Delete',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed) return;

    final notifier = ref.read(picklistsProvider.notifier);
    for (final id in ids) {
      await notifier.deletePicklist(id);
    }

    if (!mounted) return;
    _clearSelection();
  }

  Widget _buildHeaderStatusButton(
    String label,
    int count,
    Color color,
    String viewName,
  ) {
    final isSelected = _selectedView == viewName;
    return InkWell(
      onTap: () =>
          setState(() => _selectedView = isSelected ? 'All' : viewName),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(color: isSelected ? color : AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
        surfaceTintColor: const WidgetStatePropertyAll(
          AppTheme.backgroundColor,
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: const WidgetStatePropertyAll(12),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      ),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen)
              controller.close();
            else
              controller.open();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedView == 'All' ? 'All Picklists' : _selectedView,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        );
      },
      menuChildren: [
        _buildViewMenuItem('All'),
        _buildViewMenuItem('Yet to Start'),
        _buildViewMenuItem('In Progress'),
        _buildViewMenuItem('On Hold'),
        _buildViewMenuItem('Completed'),
        _buildViewMenuItem('Force Complete'),
        _buildViewMenuItem('Approved'),
        const Divider(height: 1, color: AppTheme.borderColor),
        MenuItemButton(
          onPressed: () {
            setState(() {
              _isNewCustomViewOpen = true;
            });
          },
          style: _menuItemButtonStyle(),
          child: Row(
            children: [
              const Icon(
                LucideIcons.plusCircle,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 12),
              Text(
                'New Custom View',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewMenuItem(String label) {
    final isActive = _selectedView == label;
    return MenuItemButton(
      onPressed: () => setState(() => _selectedView = label),
      style: _menuItemButtonStyle(isActive: isActive),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Icon(
            LucideIcons.star,
            size: 14,
            color: isActive ? Colors.white70 : AppTheme.borderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNewButton() {
    final orgId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '0000000000';
    return ZButton.primary(
      label: 'New',
      icon: LucideIcons.plus,
      onPressed: () => context.push('/$orgId/inventory/picklists/create'),
    );
  }

  Widget _buildMoreMenu() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 4),
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(
            AppTheme.backgroundColor,
          ),
          surfaceTintColor: const WidgetStatePropertyAll(
            AppTheme.backgroundColor,
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          elevation: const WidgetStatePropertyAll(8),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppTheme.space4)),
            ),
          ),
        ),
        builder: (context, controller, child) {
          return IconButton(
            onPressed: () {
              if (controller.isOpen)
                controller.close();
              else
                controller.open();
            },
            icon: const Icon(
              LucideIcons.moreHorizontal,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          );
        },
        menuChildren: [_buildMoreMenuOptions()],
      ),
    );
  }

  Widget _buildSortMenuItem(String label, {bool isActive = false}) {
    return MenuItemButton(
      onPressed: () {},
      style: _menuItemButtonStyle(isActive: isActive),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          if (isActive) const Icon(LucideIcons.arrowUp, size: 16),
        ],
      ),
    );
  }

  ButtonStyle _menuItemButtonStyle({
    bool isActive = false,
    bool isHeader = false,
  }) {
    return ButtonStyle(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive) return AppTheme.primaryBlue;
        if (states.contains(WidgetState.hovered)) return AppTheme.primaryBlue;
        return isHeader ? Colors.transparent : AppTheme.backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive || states.contains(WidgetState.hovered))
          return Colors.white;
        return AppTheme.textPrimary;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (isActive || states.contains(WidgetState.hovered))
          return Colors.white;
        return AppTheme.primaryBlue;
      }),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(240, 44)),
      alignment: Alignment.centerLeft,
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  Widget _buildVirtualizedTable(List<Picklist> allPicklists) {
    // Filter by selected view status and search queries
    final picklists = allPicklists.where((p) {
      // View Status Filter
      if (_selectedView != 'All') {
        final statusUpper = p.status.toUpperCase().replaceAll(' ', '_');
        bool matchesView = false;
        switch (_selectedView) {
          case 'Yet to Start':
            matchesView =
                statusUpper == 'YET_TO_START' || statusUpper == 'YET_TO_PICK';
            break;
          case 'In Progress':
            matchesView = statusUpper == 'IN_PROGRESS';
            break;
          case 'On Hold':
            matchesView = statusUpper == 'ON_HOLD';
            break;
          case 'Completed':
            matchesView = statusUpper == 'COMPLETED';
            break;
          case 'Force Complete':
            matchesView = statusUpper == 'FORCE_COMPLETE';
            break;
          case 'Approved':
            matchesView = statusUpper == 'APPROVED';
            break;
          default:
            matchesView = true;
        }
        if (!matchesView) return false;
      }

      // Search Filters
      if (_salesOrderSearchQuery.isNotEmpty) {
        final so = p.salesOrderNumber?.toLowerCase() ?? '';
        if (!so.contains(_salesOrderSearchQuery.toLowerCase())) return false;
      }
      if (_customerSearchQuery.isNotEmpty) {
        final cust = p.customerName?.toLowerCase() ?? '';
        if (!cust.contains(_customerSearchQuery.toLowerCase())) return false;
      }

      return true;
    }).toList();
    if (picklists.isEmpty) return _buildEmptyState();

    final isDetailOpen = widget.id != null;
    if (isDetailOpen) {
      return _buildCompactList(picklists);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic widths based on available width
        final screenWidth = math.max(constraints.maxWidth, 1000.0);
        final columnWidths =
            _customColumnWidths ?? _calculateColumnWidths(screenWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: screenWidth,
            child: ZDataTableShell(
              header: _buildTableHeader(columnWidths, picklists),
              body: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: picklists.length,
                itemExtent: 40, // High density Zoho style
                itemBuilder: (context, index) {
                  return _buildVirtualRow(
                    picklists[index],
                    columnWidths,
                    screenWidth,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactList(List<Picklist> picklists) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: picklists.length,
      itemBuilder: (context, index) {
        final picklist = picklists[index];
        final isSelected = _selectedPicklistIds.contains(picklist.id);
        final isActive = widget.id == picklist.id;

        return InkWell(
          onTap: () {
            final orgId = GoRouterState.of(
              context,
            ).pathParameters['orgSystemId']!;
            context.go('/$orgId/inventory/picklists/${picklist.id}');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFF0F7FF) // Light blue background for active
                  : Colors.transparent,
              border: const Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: InkWell(
                    onTap: () => _toggleSelection(picklist.id ?? ''),
                    child: _buildCheckboxWidget(isSelected),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        picklist.picklistNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getFormattedStatus(picklist.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(picklist.status),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  picklist.date != null
                      ? DateFormat('dd-MM-yyyy').format(picklist.date!)
                      : '-',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFormattedStatus(String status) {
    final statusUpper = status.toUpperCase().replaceAll(' ', '_');
    switch (statusUpper) {
      case 'YET_TO_START':
        return 'Yet to Start';
      case 'YET_TO_PICK':
        return 'Yet to Start';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'ON_HOLD':
        return 'On Hold';
      case 'COMPLETED':
        return 'Completed';
      case 'FORCE_COMPLETE':
        return 'Force Complete';
      case 'APPROVED':
        return 'Approved';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    final statusUpper = status.toUpperCase().replaceAll(' ', '_');
    switch (statusUpper) {
      case 'YET_TO_START':
        return const Color(0xFF5F6368);
      case 'YET_TO_PICK':
        return const Color(0xFF5F6368);
      case 'IN_PROGRESS':
        return const Color(0xFFE65100);
      case 'ON_HOLD':
        return const Color(0xFFD93025);
      case 'COMPLETED':
        return const Color(0xFF1E8E3E);
      case 'FORCE_COMPLETE':
        return const Color(0xFF3F51B5);
      case 'APPROVED':
        return const Color(0xFF009688);
      default:
        return const Color(0xFF5F6368);
    }
  }

  void _resizeColumn(String key, double dx) {
    setState(() {
      _customColumnWidths ??= _calculateColumnWidths(
        MediaQuery.of(context).size.width - 64,
      );
      final current = _customColumnWidths![key] ?? 120.0;
      _customColumnWidths![key] = (current + dx).clamp(80.0, 600.0);
    });
  }

  Map<String, double> _calculateColumnWidths(double totalWidth) {
    const staticPrefixWidth = 84.0; // Slider + Checkbox space

    final Map<String, ({double min, double flex})> metrics = {
      'date': (min: 102.0, flex: 1.0),
      'picklist#': (min: 120.0, flex: 2.0),
      'status': (min: 140.0, flex: 2.0),
      'assignee': (min: 160.0, flex: 3.0),
      'location': (min: 200.0, flex: 4.0),
      'notes': (min: 150.0, flex: 2.0),
      'created_time': (min: 160.0, flex: 1.5),
      'modified_time': (min: 160.0, flex: 1.5),
    };

    double totalMinWidth = staticPrefixWidth;
    double totalFlex = 0;

    for (final colId in _visibleColumns) {
      final m = metrics[colId] ?? (min: 150.0, flex: 1.5);
      totalMinWidth += m.min;
      totalFlex += m.flex;
    }

    final extraSpace = math.max(0.0, totalWidth - totalMinWidth);
    final results = <String, double>{};

    for (final colId in _visibleColumns) {
      final m = metrics[colId] ?? (min: 150.0, flex: 1.5);
      results[colId] = m.min + (m.flex / totalFlex) * extraSpace;
    }

    return results;
  }

  Widget _buildTableHeader(
    Map<String, double> columnWidths,
    List<Picklist> picklists,
  ) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _buildHeaderMenuButton(),
          const SizedBox(width: 12),
          _buildSelectAllCheckbox(picklists),
          const SizedBox(width: 12),
          ..._visibleColumns.map((colId) {
            final width = columnWidths[colId]!;

            Widget headerCell;
            if (colId == 'sales_order_number') {
              headerCell = _buildHeaderSearchField(
                label: 'SALES ORDER#',
                controller: _salesOrderSearchCtrl,
                hintText: 'Search SO...',
                onChanged: (val) =>
                    setState(() => _salesOrderSearchQuery = val),
                isSearchVisible: _showSearchSalesOrder,
                onToggle: () => setState(() {
                  _showSearchSalesOrder = !_showSearchSalesOrder;
                  if (!_showSearchSalesOrder) {
                    _salesOrderSearchCtrl.clear();
                    _salesOrderSearchQuery = '';
                  }
                }),
              );
            } else if (colId == 'customer_name') {
              headerCell = _buildHeaderSearchField(
                label: 'CUSTOMER NAME',
                controller: _customerSearchCtrl,
                hintText: 'Search Customer...',
                onChanged: (val) => setState(() => _customerSearchQuery = val),
                isSearchVisible: _showSearchCustomer,
                onToggle: () => setState(() {
                  _showSearchCustomer = !_showSearchCustomer;
                  if (!_showSearchCustomer) {
                    _customerSearchCtrl.clear();
                    _customerSearchQuery = '';
                  }
                }),
              );
            } else {
              headerCell = _buildHeaderCell(
                _columnLabels[colId]!,
                width: width,
              );
            }

            return _ResizableHeaderCell(
              width: width,
              onResize: (dx) => _resizeColumn(colId, dx),
              child: headerCell,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderMenuButton() {
    return _HeaderMenuButton(
      wrapText: _shouldWrapText,
      onWrapChange: (v) => setState(() => _shouldWrapText = v),
      onCustomize: _showCustomizeColumnsDialog,
    );
  }

  Widget _buildVirtualRow(
    Picklist picklist,
    Map<String, double> columnWidths,
    double minWidth,
  ) {
    final isSelected = _selectedPicklistIds.contains(picklist.id);
    final isActive = widget.id == picklist.id;

    return InkWell(
      onTap: () {
        final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
        context.go('/$orgId/inventory/picklists/${picklist.id}');
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.selectionActiveBg
              : (isSelected ? const Color(0xFFF0F7FF) : Colors.transparent),
          border: const Border(bottom: BorderSide(color: AppTheme.bgDisabled)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            const SizedBox(width: 28), // Slider placeholder to match HeaderMenuButton
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _toggleSelection(picklist.id ?? ''),
              child: _buildCheckboxWidget(isSelected),
            ),
            const SizedBox(width: 12),
            ..._visibleColumns.map((colId) {
              return _buildCell(picklist, colId, width: columnWidths[colId]!);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectAllCheckbox(List<Picklist> picklists) {
    final isAllSelected =
        picklists.isNotEmpty && _selectedPicklistIds.length == picklists.length;
    final isPartiallySelected =
        _selectedPicklistIds.isNotEmpty &&
        _selectedPicklistIds.length < picklists.length;

    return InkWell(
      onTap: () => _toggleAll(picklists),
      child: _buildCheckboxWidget(
        isAllSelected,
        isPartially: isPartiallySelected,
      ),
    );
  }

  Widget _buildCheckboxWidget(
    bool isSelected, {
    bool isPartially = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: isSelected || isPartially
          ? Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(
                child: Icon(
                  isPartially ? LucideIcons.minus : LucideIcons.check,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            )
          : Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppTheme.borderColor, width: 1.5),
              ),
            ),
    );
  }

  Widget _buildHeaderCell(String text, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.tableHeader.copyWith(fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildCell(Picklist picklist, String colId, {double? width}) {
    Widget content;
    switch (colId) {
      case 'date':
        content = Text(
          DateFormat('dd-MM-yyyy').format(picklist.date ?? DateTime.now()),
          style: AppTheme.tableCell,
        );
        break;
      case 'picklist#':
        content = Text(
          picklist.picklistNumber,
          style: AppTheme.tableCell.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        );
        break;
      case 'status':
        final textColor = _getStatusColor(picklist.status);
        final displayStatus = _getFormattedStatus(picklist.status);
        content = Text(
          displayStatus,
          style: AppTheme.tableCell.copyWith(
            color: textColor,
            fontWeight: FontWeight.w400,
          ),
        );
        break;
      case 'assignee':
        content = Consumer(
          builder: (context, ref, _) {
            final usersAsync = ref.watch(allUsersProvider);
            final text = usersAsync.maybeWhen(
              data: (users) {
                final found = users
                    .where(
                      (u) =>
                          u.id == picklist.assignee ||
                          u.fullName == picklist.assignee,
                    )
                    .firstOrNull;
                return found?.fullName ?? picklist.assignee ?? 'Unassigned';
              },
              orElse: () => picklist.assignee ?? 'Unassigned',
            );

            return Text(
              text,
              style: AppTheme.tableCell.copyWith(
                fontWeight: text == 'Unassigned'
                    ? FontWeight.w400
                    : FontWeight.w600,
                color: text == 'Unassigned'
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
              ),
            );
          },
        );
        break;
      case 'location':
        content = Text(
          picklist.location ?? '-',
          style: AppTheme.tableCell.copyWith(fontWeight: FontWeight.w600),
        );
        break;
      case 'notes':
        content = Text(picklist.notes ?? '-', style: AppTheme.tableCell);
        break;
      case 'customer_name':
        content = Text(picklist.customerName ?? '-', style: AppTheme.tableCell);
        break;
      case 'sales_order_number':
        content = InkWell(
          onTap: () {
            // Navigate to SO if needed
          },
          child: Text(
            (picklist.salesOrderNumber ?? '-')
                .replaceAll('[', '')
                .replaceAll(']', ''),
            style: AppTheme.tableCell.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w400,
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.primaryBlue.withValues(alpha: 0.3),
            ),
          ),
        );
        break;
      default:
        content = const Text('-');
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: DefaultTextStyle(
        style: AppTheme.tableCell.copyWith(
          fontSize: 13,
          color: AppTheme.textPrimary,
        ),
        child: _shouldWrapText
            ? content
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: content,
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.package, size: 48, color: AppTheme.bgDisabled),
          SizedBox(height: 16),
          Text(
            'No picklists found',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSearchField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
    required bool isSearchVisible,
    required VoidCallback onToggle,
    TextAlign textAlign = TextAlign.start,
  }) {
    if (!isSearchVisible) {
      return Row(
        mainAxisAlignment: textAlign == TextAlign.center
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderCell(label, width: 0),
          const SizedBox(width: 8),
          InkWell(
            onTap: onToggle,
            child: const Icon(
              LucideIcons.search,
              size: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      );
    }

    return Container(
      height: 28,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 12, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: true,
              style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
              textAlign: textAlign,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              controller.clear();
              onChanged('');
              onToggle();
            },
            child: const Icon(
              LucideIcons.x,
              size: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class NewCustomViewOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const NewCustomViewOverlay({super.key, required this.onClose});

  @override
  State<NewCustomViewOverlay> createState() => _NewCustomViewOverlayState();
}

class _NewCustomViewOverlayState extends State<NewCustomViewOverlay> {
  String _logic = 'AND';
  final List<String> _availableColumns = [
    'Date',
    'Status',
    'Assignee',
    'Location',
    'Notes',
    'Customer Name',
    'Sales Order#',
  ];
  final List<String> _selectedColumns = ['Picklist#'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Text(
                  'New Custom View',
                  style: AppTheme.pageTitle.copyWith(fontSize: 18),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Name*',
                    style: TextStyle(
                      color: Color(0xFFD93025),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(
                        width: 400,
                        child: TextField(
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.borderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.borderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        LucideIcons.star,
                        size: 18,
                        color: AppTheme.borderColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Mark as Favorite',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Define the criteria ( if any )',
                    style: AppTheme.sectionHeader.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  _buildCriteriaRow(1),
                  const SizedBox(height: 12),
                  _buildLogicSelector(),
                  const SizedBox(height: 12),
                  _buildCriteriaRow(2),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {},
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.plusCircle,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add Criterion',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Columns Preference:',
                    style: AppTheme.sectionHeader.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _buildColumnsPreferencePanes(),
                  const SizedBox(height: 48),
                  Text(
                    'Visibility Preference',
                    style: AppTheme.sectionHeader.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  _buildVisibilityPreference(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                ZButton.primary(label: 'Save', onPressed: widget.onClose),
                const SizedBox(width: 12),
                ZButton.secondary(label: 'Cancel', onPressed: widget.onClose),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(int index) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            color: Colors.white,
          ),
          child: Text(
            '$index',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
        Container(
          width: 200,
          height: 36,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.borderColor),
              bottom: BorderSide(color: AppTheme.borderColor),
              right: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: const Row(
            children: [
              SizedBox(width: 12),
              Text(
                'Select a field',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              Spacer(),
              Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 200,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            children: [
              SizedBox(width: 12),
              Text(
                'Select a comparator',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              Spacer(),
              Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const SizedBox(
          width: 400,
          height: 36,
          child: TextField(
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              fillColor: Color(0xFFF1F3F4),
              filled: true,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Icon(LucideIcons.plus, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        const Icon(LucideIcons.trash2, size: 18, color: AppTheme.textSecondary),
      ],
    );
  }

  Widget _buildLogicSelector() {
    return Container(
      width: 80,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: PopupMenuButton<String>(
        onSelected: (val) => setState(() => _logic = val),
        offset: const Offset(0, 36),
        child: Row(
          children: [
            Text(
              _logic,
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            const Icon(
              LucideIcons.chevronDown,
              size: 12,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'AND', child: Text('AND')),
          const PopupMenuItem(value: 'OR', child: Text('OR')),
        ],
      ),
    );
  }

  Widget _buildColumnsPreferencePanes() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AVAILABLE COLUMNS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: ZSearchField(hintText: 'Search'),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: _availableColumns.map((col) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.gripVertical,
                                  size: 14,
                                  color: AppTheme.borderColor,
                                ),
                                const SizedBox(width: 12),
                                Text(col, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    LucideIcons.checkCircle,
                    size: 14,
                    color: Color(0xFF1E8E3E),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'SELECTED COLUMNS',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  children: _selectedColumns.map((col) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.gripVertical,
                            size: 14,
                            color: AppTheme.borderColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            col,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(color: Color(0xFFD93025)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityPreference() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share With',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildVisibilityOption('Only Me', LucideIcons.lock, false),
              const SizedBox(width: 16),
              _buildVisibilityOption(
                'Only Selected Users & Roles',
                LucideIcons.user,
                true,
              ),
              const SizedBox(width: 16),
              _buildVisibilityOption('Everyone', LucideIcons.fileText, false),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text('Users', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 8),
                      Icon(LucideIcons.chevronDown, size: 14),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Select Users',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const Spacer(),
                const Icon(
                  LucideIcons.plusCircle,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Add Users',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          const Center(
            child: Text(
              'You haven\'t shared this Custom View with any users yet. Select the users or roles to share it with and provide their access permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityOption(String label, IconData icon, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: selected ? AppTheme.primaryBlue : AppTheme.borderColor,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppTheme.primaryBlue : AppTheme.borderColor,
                width: selected ? 5 : 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Icon(icon, size: 14, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

/// side detail panel for picklists
class _PicklistDetailPanel extends ConsumerStatefulWidget {
  final String id;
  final VoidCallback onClose;

  const _PicklistDetailPanel({required this.id, required this.onClose});

  @override
  ConsumerState<_PicklistDetailPanel> createState() =>
      _PicklistDetailPanelState();
}

class _PicklistDetailPanelState extends ConsumerState<_PicklistDetailPanel> {
  bool _showPdfView = false;
  bool _isAssociatedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final picklistAsync = ref.watch(picklistByIdProvider(widget.id));

    return Column(
      children: [
        // Action Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            color: Color(0xFFF8F9FA),
          ),
          child: Row(
            children: [
              _buildToolbarButton(
                LucideIcons.edit,
                'Edit',
                onPressed: () {
                  final orgId = GoRouterState.of(
                    context,
                  ).pathParameters['orgSystemId']!;
                  context.push(
                    '/$orgId/inventory/picklists/edit/${widget.id}?mode=edit',
                  );
                },
              ),
              _buildToolbarDivider(),
              _buildPdfPrintDropdown(context),
              _buildToolbarDivider(),
              _buildToolbarButton(
                LucideIcons.trash2,
                'Delete',
                onPressed: () => _showDeleteConfirmation(context),
              ),
              _buildToolbarDivider(),
              _buildToolbarButton(
                LucideIcons.refreshCw,
                'Update Picklist',
                onPressed: () {
                  final orgId = GoRouterState.of(
                    context,
                  ).pathParameters['orgSystemId']!;
                  context.push(
                    '/$orgId/inventory/picklists/edit/${widget.id}?mode=update',
                  );
                },
              ),
              _buildToolbarDivider(),
              _buildStatusDropdown(context),
            ],
          ),
        ),

        // Panel Content
        Expanded(
          child: picklistAsync.when(
            data: (p) {
              if (p == null)
                return const Center(child: Text('Picklist not found'));

              return Column(
                children: [
                  Expanded(
                    child: _showPdfView
                        ? Column(
                            children: [
                              _buildToggleRow(),
                              Expanded(child: _PicklistPdfView(picklist: p)),
                            ],
                          )
                        : _buildDetailContent(context, p),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
    bool hasDropdown = false,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 6),
              const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: AppTheme.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPrintDropdown(BuildContext context) {
    final p = ref.watch(picklistByIdProvider(widget.id)).asData?.value;

    return PopupMenuButton<String>(
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      onSelected: (value) {
        if (value == 'pdf') {
          // Trigger PDF download logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Downloading PDF for ${p?.picklistNumber ?? 'Picklist'}...',
              ),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );

          try {
            // Direct download trigger
            final baseUrl = ref.read(apiClientProvider).dio.options.baseUrl;
            final downloadUrl = '${baseUrl}picklists/${p?.id}/export/pdf';

            final anchor =
                import_web.document.createElement('a')
                    as import_web.HTMLAnchorElement;
            anchor.href = downloadUrl;
            anchor.download = 'Picklist_${p?.picklistNumber ?? "doc"}.pdf';
            anchor.target = '_blank';
            anchor.click();
          } catch (e) {
            debugPrint('Download error: $e');
            // Fallback to print if download fails
            import_web.window.print();
          }
        } else if (value == 'print') {
          // Trigger Print logic
          try {
            import_web.window.print();
          } catch (e) {
            debugPrint('Print error: $e');
          }
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem(
          value: 'pdf',
          icon: LucideIcons.fileText,
          label: 'Export as PDF',
        ),
        _buildPopupItem(
          value: 'print',
          icon: LucideIcons.printer,
          label: 'Print',
        ),
      ],
      child: _buildToolbarButton(
        LucideIcons.fileText,
        'PDF/Print',
        hasDropdown: true,
      ),
    );
  }

  Widget _buildToggleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Show PDF View',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _showPdfView,
              onChanged: (val) => setState(() => _showPdfView = val),
              activeTrackColor: AppTheme.primaryBlue,
              activeThumbColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      onSelected: (value) {
        ref
            .read(picklistsProvider.notifier)
            .updatePicklistStatus(widget.id, value)
            .then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Status updated to ${value.replaceAll("_", " ")}',
                  ),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            });
      },
      itemBuilder: (context) => [
        _buildPopupItem(
          value: 'ON_HOLD',
          icon: LucideIcons.pauseCircle,
          label: 'On Hold',
        ),
        _buildPopupItem(
          value: 'COMPLETED',
          icon: LucideIcons.checkCircle,
          label: 'Completed',
        ),
      ],
      child: _buildToolbarButton(
        LucideIcons.settings,
        'Set status',
        hasDropdown: true,
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem({
    required String value,
    required IconData icon,
    required String label,
  }) {
    bool isHovered = false;
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: StatefulBuilder(
        builder: (context, setState) {
          return MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
                borderRadius: isHovered ? BorderRadius.circular(6) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isHovered ? Colors.white : const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isHovered ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Picklist',
      message:
          'Are you sure you want to delete this picklist? This action cannot be undone.',
      confirmLabel: 'Delete',
      variant: ZerpaiConfirmationVariant.danger,
    );

    if (confirmed) {
      await ref.read(picklistsProvider.notifier).deletePicklist(widget.id);
      if (context.mounted) {
        widget.onClose(); // Close the panel after deletion
      }
    }
  }

  Widget _buildToolbarDivider() {
    return Container(
      height: 16,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppTheme.borderColor,
    );
  }

  Widget _buildDetailContent(BuildContext context, Picklist p) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Associated Sales Orders Expandable
          _buildAssociatedSection(p),

          _buildToggleRow(),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assignee Row
                Row(
                  children: [
                    const SizedBox(
                      width: 100,
                      child: Text(
                        'Assignee',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 250,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final usersAsync = ref.watch(allUsersProvider);
                          return Row(
                            children: [
                              Expanded(
                                child: FormDropdown<User>(
                                  height: 32,
                                  hint: 'Unassigned',
                                  value: usersAsync.maybeWhen(
                                    data: (users) => users
                                        .where(
                                          (u) =>
                                              u.id == p.assignee ||
                                              u.fullName == p.assignee,
                                        )
                                        .firstOrNull,
                                    orElse: () => null,
                                  ),
                                  items: usersAsync.maybeWhen(
                                    data: (users) => users,
                                    orElse: () => [],
                                  ),
                                  isLoading: usersAsync.isLoading,
                                  fillColor: Colors.white,
                                  border: Border.all(
                                    color: AppTheme.borderColor,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  onChanged: (val) async {
                                    if (val != null) {
                                      final confirmed =
                                          await showZerpaiConfirmationDialog(
                                            context,
                                            title: 'Update Assignee',
                                            message:
                                                'Should I save the assignee change?',
                                            confirmLabel: 'Yes',
                                            cancelLabel: 'No',
                                          );
                                      if (confirmed) {
                                        ref
                                            .read(picklistsProvider.notifier)
                                            .updatePicklistAssignee(
                                              widget.id,
                                              val.id,
                                            );
                                      }
                                    }
                                  },
                                  displayStringForValue: (user) =>
                                      user.fullName,
                                  searchStringForValue: (user) => user.fullName,
                                ),
                              ),
                              if (p.assignee != null) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    final confirmed =
                                        await showZerpaiConfirmationDialog(
                                          context,
                                          title: 'Remove Assignee',
                                          message:
                                              'Are you sure you want to remove the assignee?',
                                          confirmLabel: 'Yes',
                                          cancelLabel: 'No',
                                          variant:
                                              ZerpaiConfirmationVariant.danger,
                                        );
                                    if (confirmed) {
                                      ref
                                          .read(picklistsProvider.notifier)
                                          .updatePicklistAssignee(
                                            widget.id,
                                            '', // Clear assignee
                                          );
                                    }
                                  },
                                  icon: const Icon(
                                    LucideIcons.x,
                                    size: 14,
                                    color: AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const SizedBox(height: 24),

                // Info Cards Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildInfoBlock('Picklist', p.picklistNumber),
                      _buildInfoBlock(
                        'Expected Date',
                        DateFormat(
                          'dd-MM-yyyy',
                        ).format(p.date ?? DateTime.now()),
                      ),
                      _buildInfoBlock(
                        'Location',
                        p.location ?? 'ZABNIX PRIVATE LIMITED',
                      ),
                      _buildInfoBlock('Group', 'No Grouping'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Items Table
                const Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildItemsTable(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssociatedSection(Picklist p) {
    // Get unique sales orders from items
    final uniqueSOs = <String, String>{};
    for (final item in p.items) {
      if (item.salesOrderNumber != null && item.salesOrderId != null) {
        uniqueSOs[item.salesOrderId!] = item.salesOrderNumber!;
      }
    }
    final soCount = uniqueSOs.length;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _isAssociatedExpanded = !_isAssociatedExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Associated sales orders  $soCount',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 13,
                      fontWeight: _isAssociatedExpanded
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isAssociatedExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_isAssociatedExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: Colors.white,
              child: soCount == 0
                  ? const Text(
                      'No associated sales orders',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    )
                  : Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppTheme.borderColor),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Sales Order#',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Shipment Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Rows
                        ...uniqueSOs.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppTheme.borderColor),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    p.date != null
                                        ? DateFormat(
                                            'dd-MM-yyyy',
                                          ).format(p.date!)
                                        : '23-04-2026',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    e.value,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'CONFIRMED',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  flex: 3,
                                  child: Text(
                                    '',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(Picklist p) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                _buildTableHeaderCell('Items', flex: 4),
                _buildTableHeaderCell('Order#', flex: 2),
                _buildTableHeaderCell('Quantity to pick', flex: 2),
                _buildTableHeaderCell('Quantity Picked', flex: 2),
                _buildTableHeaderCell('Yet To Pick', flex: 2),
                _buildTableHeaderCell('Status', flex: 2),
              ],
            ),
          ),
          // Real rows from items
          if (p.items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: const Center(
                child: Text(
                  'No items in this picklist',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ...p.items.map(
              (item) => Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.borderColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                LucideIcons.image,
                                size: 16,
                                color: AppTheme.borderColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName ?? 'Unknown Item',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildTableCell(
                      item.salesOrderNumber ?? '-',
                      flex: 2,
                      isBlue: item.salesOrderNumber != null,
                    ),
                    _buildTableCell('${item.qtyToPick.toInt()}\npcs', flex: 2),
                    _buildTableCell(
                      '${item.qtyPicked.toInt()}',
                      flex: 2,
                      color: item.qtyPicked > 0 ? Colors.black : null,
                    ),
                    _buildTableCell('${item.yetToPick.toInt()}', flex: 2),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildItemStatusBadge(
                          item.itemStatus,
                          parentStatus: p.status,
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

  Widget _buildItemStatusBadge(String status, {String? parentStatus}) {
    String effectiveStatus = status;

    // If the whole picklist is On Hold, show items as On Hold unless they are already Completed
    // This provides a consistent UX when the parent is paused.
    final ps = parentStatus?.toUpperCase().replaceAll(' ', '_');
    if (ps == 'ON_HOLD' && status != 'Completed' && status != 'Approved') {
      effectiveStatus = 'On Hold';
    }

    Color textColor;
    final s = effectiveStatus.trim().toUpperCase().replaceAll(' ', '_');

    if (s == 'COMPLETED') {
      textColor = const Color(0xFF1E8E3E); // Green
      effectiveStatus = 'Completed';
    } else if (s == 'IN_PROGRESS') {
      textColor = const Color(0xFFE65100); // Orange
      effectiveStatus = 'In Progress';
    } else if (s == 'ON_HOLD') {
      textColor = const Color(0xFFD93025); // Red
      effectiveStatus = 'On Hold';
    } else if (s == 'FORCE_COMPLETE') {
      textColor = const Color(0xFF3F51B5); // Indigo
      effectiveStatus = 'Force Complete';
    } else if (s == 'APPROVED') {
      textColor = const Color(0xFF009688); // Teal
      effectiveStatus = 'Approved';
    } else if (s == 'CANCELLED') {
      textColor = const Color(0xFF5F6368); // Gray
      effectiveStatus = 'Cancelled';
    } else {
      textColor = const Color(0xFF5F6368); // Gray (Yet to Start)
      if (effectiveStatus.isEmpty || effectiveStatus == 'YET_TO_START') {
        effectiveStatus = 'Yet to Start';
      }
    }

    return Text(
      effectiveStatus,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    required int flex,
    bool isBlue = false,
    Color? color,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isBlue
                ? AppTheme.primaryBlue
                : (color ?? AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _PicklistPdfView extends ConsumerWidget {
  final Picklist picklist;

  const _PicklistPdfView({required this.picklist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;

    return Container(
      color: const Color(0xFFF0F0F0),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1.2, // Wider, shorter layout
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRect(
              child: Stack(
                children: [
                  // -- Diagonal Corner Ribbon --
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 100, 48, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -- Header Section --
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPdfLogo(orgSettings),
                                  const SizedBox(height: 14),
                                  Text(
                                    orgSettings?.name.trim().isNotEmpty == true
                                        ? orgSettings!.name.trim().toUpperCase()
                                        : 'YOUR COMPANY NAME',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (orgSettings?.paymentStubAddress
                                          ?.trim()
                                          .isNotEmpty ==
                                      true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _formatAddress(
                                          orgSettings!.paymentStubAddress!
                                              .trim(),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          height: 1.5,
                                        ),
                                      ),
                                    )
                                  else
                                    const Text(
                                      'Address Line 1\nCity, State PIN\nCountry',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        height: 1.5,
                                      ),
                                    ),
                                  if (orgSettings
                                          ?.companyIdentityLine
                                          ?.isNotEmpty ==
                                      true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        orgSettings!.companyIdentityLine!,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'PICKLIST',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Picklist# ${picklist.picklistNumber}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // -- Info Summary Grid --
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppTheme.borderColor),
                              bottom: BorderSide(color: AppTheme.borderColor),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              _buildPdfInfoBlock(
                                'Picklist Date',
                                DateFormat(
                                  'dd-MM-yyyy',
                                ).format(picklist.date ?? DateTime.now()),
                              ),
                              _buildPdfInfoBlock(
                                'Status',
                                _getFormattedStatus(picklist.status),
                              ),
                              _buildPdfInfoBlock(
                                'Location',
                                picklist.location ?? '-',
                              ),
                              _buildPdfInfoBlock(
                                'Assignee',
                                picklist.assignee ?? 'Unassigned',
                              ),
                              _buildPdfTotalBlock(
                                'TOTAL QTY',
                                picklist.items
                                    .fold(
                                      0.0,
                                      (sum, item) => sum + item.qtyToPick,
                                    )
                                    .toStringAsFixed(2),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // -- Document Table --
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF333333),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Row(
                            children: [
                              _buildPdfHeaderCell('#', width: 30),
                              _buildPdfHeaderCell(
                                'ITEM & DESCRIPTION',
                                flex: 4,
                              ),
                              _buildPdfHeaderCell('ORDER #', flex: 2),
                              _buildPdfHeaderCell('STATUS', flex: 2),
                              _buildPdfHeaderCell(
                                'QUANTITY\nTO PICK',
                                flex: 2,
                                align: TextAlign.right,
                              ),
                              _buildPdfHeaderCell(
                                'QUANTITY\nPICKED',
                                flex: 2,
                                align: TextAlign.right,
                              ),
                              _buildPdfHeaderCell(
                                'QUANTITY\nREMAINING',
                                flex: 2,
                                align: TextAlign.right,
                              ),
                            ],
                          ),
                        ),

                        // -- Document Rows (dynamic from picklist items) --
                        ...picklist.items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppTheme.borderColor),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPdfCell('${idx + 1}', width: 30),
                                _buildPdfCell(
                                  item.productName ?? '-',
                                  flex: 4,
                                  fontWeight: FontWeight.bold,
                                ),
                                _buildPdfCell(
                                  item.salesOrderNumber ?? '-',
                                  flex: 2,
                                ),
                                _buildPdfCell(item.itemStatus, flex: 2),
                                _buildPdfCell(
                                  '${item.qtyToPick.toStringAsFixed(2)}\npcs',
                                  flex: 2,
                                  align: TextAlign.right,
                                ),
                                _buildPdfCell(
                                  '${item.qtyPicked.toStringAsFixed(2)}\npcs',
                                  flex: 2,
                                  align: TextAlign.right,
                                ),
                                _buildPdfCell(
                                  '${(item.qtyToPick - item.qtyPicked).toStringAsFixed(2)}\npcs',
                                  flex: 2,
                                  align: TextAlign.right,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // -- Diagonal Corner Ribbon (Rendered on top) --
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _PdfCornerRibbon(
                      label: _getFormattedStatus(picklist.status),
                      color: _getPdfStatusColor(picklist.status),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the organization logo from orgSettingsProvider, falling back to
  /// a dark placeholder if no logo URL is configured.
  Widget _buildPdfLogo(OrgSettings? orgSettings) {
    final logoUrl = orgSettings?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: 140,
        height: 60,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _pdfLogoFallback(),
        ),
      );
    }
    return _pdfLogoFallback();
  }

  Widget _pdfLogoFallback() {
    return Container(
      width: 140,
      height: 60,
      color: const Color(0xFF101820),
      child: const Center(
        child: Text(
          'LOGO',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Color _getPdfStatusColor(String status) {
    switch (status.toUpperCase().replaceAll(' ', '_')) {
      case 'COMPLETED':
        return const Color(0xFF1E8E3E);
      case 'IN_PROGRESS':
        return const Color(0xFF0088FF);
      case 'ON_HOLD':
        return const Color(0xFFD93025);
      case 'APPROVED':
        return const Color(0xFF009688);
      case 'FORCE_COMPLETE':
        return const Color(0xFF3F51B5);
      case 'YET_TO_START':
      case 'YET_TO_PICK':
        return const Color(0xFF78909C);
      default:
        return const Color(0xFFC4C4C4);
    }
  }

  String _getFormattedStatus(String status) {
    return status.replaceAll('_', ' ');
  }

  String _formatAddress(String address) {
    if (address.isEmpty) return address;

    // Attempt to parse as JSON if it looks like one
    if (address.trim().startsWith('{')) {
      try {
        final data = json.decode(address);
        if (data is Map) {
          final List<String> parts = [];

          if (data['attention'] != null &&
              data['attention'].toString().isNotEmpty) {
            parts.add(data['attention'].toString());
          }
          if (data['street1'] != null &&
              data['street1'].toString().isNotEmpty) {
            parts.add(data['street1'].toString());
          }
          if (data['street2'] != null &&
              data['street2'].toString().isNotEmpty) {
            parts.add(data['street2'].toString());
          }

          final cityStateZip =
              [
                    data['city'],
                    data['state_name'] ?? data['state'],
                    data['pincode'] ?? data['zip_code'],
                  ]
                  .where((e) => e != null && e.toString().trim().isNotEmpty)
                  .join(', ');

          if (cityStateZip.isNotEmpty) {
            parts.add(cityStateZip);
          }

          if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
            parts.add('Phone: ${data['phone']}');
          }

          if (parts.isNotEmpty) {
            return parts.join('\n');
          }
        }
      } catch (_) {
        // Fallback to raw string if JSON parsing fails
      }
    }

    return address;
  }

  Widget _buildPdfInfoBlock(String label, String value) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfTotalBlock(String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFF1F3F4),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfHeaderCell(
    String text, {
    int? flex,
    double? width,
    TextAlign align = TextAlign.left,
  }) {
    final child = Text(
      text,
      textAlign: align,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.bold,
      ),
    );
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex!, child: child);
  }

  Widget _buildPdfCell(
    String text, {
    int? flex,
    double? width,
    TextAlign align = TextAlign.left,
    FontWeight? fontWeight,
  }) {
    final child = Text(
      text,
      textAlign: align,
      style: TextStyle(fontSize: 10, fontWeight: fontWeight),
    );
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex!, child: child);
  }
}

/// Corner ribbon widget that draws a diagonal wrap in the top-left corner,
/// matching the style from the reference screenshot. Color changes by status.
class _PdfCornerRibbon extends StatelessWidget {
  final String label;
  final Color color;

  const _PdfCornerRibbon({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    const double size = 110;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Corner Folds (the dark triangles behind the ribbon)
          CustomPaint(
            size: const Size(size, size),
            painter: _CornerFoldPainter(color: color),
          ),
          // Shadow for the ribbon
          Positioned(
            top: 24,
            left: -32,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 170,
                height: 30,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main Ribbon Band
          Positioned(
            top: 22,
            left: -34,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 170,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      HSLColor.fromColor(color)
                          .withLightness(
                            (HSLColor.fromColor(color).lightness * 0.85).clamp(
                              0.0,
                              1.0,
                            ),
                          )
                          .toColor(),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerFoldPainter extends CustomPainter {
  final Color color;
  _CornerFoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final darkColor = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness * 0.45).clamp(0.0, 1.0),
        )
        .toColor();

    final paint = Paint()..color = darkColor;

    // Positioned based on: top 22, height 30.
    // At 45 degrees, the band edges meet the container edges at:
    // Top: x ~ 74, y = 0
    // Left: x = 0, y ~ 74

    final path = Path()
      ..moveTo(72, 0)
      ..lineTo(84, 0)
      ..lineTo(72, 12)
      ..close()
      ..moveTo(0, 72)
      ..lineTo(0, 84)
      ..lineTo(12, 72)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------
// HEADER MENU BUTTON
// -----------------------------------------------------------

class _HeaderMenuButton extends StatelessWidget {
  final bool wrapText;
  final ValueChanged<bool> onWrapChange;
  final VoidCallback onCustomize;

  const _HeaderMenuButton({
    required this.wrapText,
    required this.onWrapChange,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 8),
      elevation: 10,
      color: Colors.white,
      constraints: const BoxConstraints(minWidth: 210),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Container(
        height: 28,
        width: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDE4FF)),
        ),
        alignment: Alignment.center,
        child: const Icon(
          LucideIcons.sliders,
          size: 14,
          color: AppTheme.primaryBlue,
        ),
      ),
      onSelected: (action) {
        if (action == 'customize') {
          onCustomize();
        } else if (action == 'wrap') {
          onWrapChange(!wrapText);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'customize',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: const _MenuActionTile(
            icon: LucideIcons.sliders,
            label: 'Customize Columns',
            selected: false,
            accent: true,
          ),
        ),
        PopupMenuItem<String>(
          value: 'wrap',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: _MenuActionTile(
            icon: Icons.wrap_text,
            label: 'Wrap Text',
            selected: wrapText,
          ),
        ),
      ],
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool accent;

  const _MenuActionTile({
    required this.icon,
    required this.label,
    this.selected = false,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final blue = AppTheme.primaryBlue;
    final dark = AppTheme.textPrimary;
    final textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: selected
          ? Colors.white
          : accent
          ? blue
          : dark,
    );

    final bg = selected ? blue : Colors.transparent;
    final icColor = selected
        ? Colors.white
        : accent
        ? blue
        : AppTheme.textSecondary;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: icColor),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: textStyle)),
          if (selected)
            const Icon(LucideIcons.check, size: 16, color: Colors.white),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// RESIZABLE HEADER CELL
// -----------------------------------------------------------

class _ResizableHeaderCell extends StatefulWidget {
  final double width;
  final Widget child;
  final ValueChanged<double> onResize;

  const _ResizableHeaderCell({
    required this.width,
    required this.child,
    required this.onResize,
  });

  @override
  State<_ResizableHeaderCell> createState() => _ResizableHeaderCellState();
}

class _ResizableHeaderCellState extends State<_ResizableHeaderCell> {
  bool _hover = false;
  static const double _resizeSensitivity = 8.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          SizedBox(width: widget.width, height: 36, child: widget.child),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (d) =>
                  widget.onResize(d.delta.dx * _resizeSensitivity),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _hover ? 1.0 : 0.0,
                child: Container(width: 4, color: AppTheme.primaryBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
