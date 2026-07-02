import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/workflow/transaction_status_transition_guard.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/inventory/adjustments/providers/inventory_adjustments_provider.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_model.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';

class InventoryAdjustmentsListPanel extends ConsumerStatefulWidget {
  final bool compact;
  final String? selectedAdjustmentId;
  final ValueChanged<String> onSelectAdjustment;

  const InventoryAdjustmentsListPanel({
    super.key,
    this.compact = false,
    this.selectedAdjustmentId,
    required this.onSelectAdjustment,
  });

  @override
  ConsumerState<InventoryAdjustmentsListPanel> createState() =>
      _InventoryAdjustmentsListPanelState();
}

class _InventoryAdjustmentsListPanelState
    extends ConsumerState<InventoryAdjustmentsListPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _periodFilter = 'all';
  Set<String>? _selectedIds;
  String _sortField = 'date';
  bool _sortAscending = false;

  static const List<String> _typeOptions = ['all', 'quantity', 'value'];
  static const List<String> _periodOptions = [
    'all',
    'today',
    'this_week',
    'this_month',
    'this_quarter',
    'this_year',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _orgId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';

  void _goToCreate() => context.go('/$_orgId/inventory/adjustments/create');

  Future<void> _approve(InventoryAdjustment row) async {
    final user = ref.read(authUserProvider);
    final entity = ref.read(entityProvider);
    final decision = TransactionStatusTransitionGuard.canTransition(
      user: user,
      transactionType: 'inventory.adjustment',
      fromStatus: row.status,
      toStatus: 'approved',
      branchId: entity.branchId,
      warehouseId: row.warehouseId,
      requiredPermission: 'inventory.adjustment.edit',
    );
    if (!decision.allowed) {
      if (mounted) ZerpaiToast.error(context, decision.reason);
      return;
    }
    try {
      await ref.read(inventoryAdjustmentsActionsProvider).approve(row.id);
      if (user != null) {
        final auditEvent = TransactionStatusTransitionGuard.buildAuditEvent(
          transactionType: 'inventory.adjustment',
          transactionId: row.id,
          beforeStatus: row.status,
          afterStatus: 'approved',
          actor: user,
          reason: 'Approved from adjustments list',
          permissionUsed: decision.requiredPermission,
          branchId: entity.branchId,
          warehouseId: row.warehouseId,
          metadata: <String, dynamic>{
            'entity_context': entity.entityId,
            'branch_context': entity.branchId,
            'warehouse_context': row.warehouseId,
          },
        );
        AppLogger.info(
          'Inventory adjustment status transition',
          module: 'inventory_adjustments',
          userId: user.id,
          orgId: user.orgId,
          data: auditEvent.toJson(),
        );
      }
      if (mounted) ZerpaiToast.success(context, 'Adjustment approved');
    } catch (e) {
      if (mounted)
        ZerpaiToast.error(context, ErrorHandler.getFriendlyMessage(e));
    }
  }

  Future<void> _reject(String id) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Reject Adjustment',
      message: 'Reject this inventory adjustment?',
      confirmLabel: 'Reject',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(inventoryAdjustmentsActionsProvider)
          .reject(id, 'Rejected');
      if (mounted) ZerpaiToast.info(context, 'Adjustment rejected');
    } catch (e) {
      if (mounted)
        ZerpaiToast.error(context, ErrorHandler.getFriendlyMessage(e));
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Adjustment',
      message: 'This cannot be undone. Delete this draft adjustment?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (confirmed != true) return;
    try {
      await ref.read(inventoryAdjustmentsActionsProvider).delete(id);
      if (mounted) ZerpaiToast.deleted(context, 'Adjustment');
    } catch (e) {
      if (mounted)
        ZerpaiToast.error(context, ErrorHandler.getFriendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(inventoryAdjustmentsFiltersProvider);
    final rowsAsync = ref.watch(inventoryAdjustmentsListProvider);

    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(filters),
          const Divider(height: 1, color: AppTheme.borderColor),
          Expanded(
            child: rowsAsync.when(
              data: (rows) {
                final filtered = rows.where(_matchesPeriod).toList();
                _applySort(filtered);
                return _buildList(filtered);
              },
              loading: () => _buildLoadingSkeleton(),
              error: (e, _) => _errorState(e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(InventoryAdjustmentsFilters filters) {
    if (widget.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.only(left: 24, right: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Inventory Adjustments',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                _compactIconButton(
                  icon: LucideIcons.plus,
                  isPrimary: true,
                  onTap: _goToCreate,
                ),
                const SizedBox(width: 8),
                _buildCompactMoreActionsMenu(),
              ],
            ),
          ),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFFF8F9FB),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: FormDropdown<String>(
                    value: filters.adjustmentType,
                    items: _typeOptions,
                    hint: 'Type',
                    height: 30,
                    showSearch: false,
                    menuWidth: 200,
                    onChanged: (v) {
                      if (v == null) return;
                      ref.read(inventoryAdjustmentsFiltersProvider.notifier).state =
                          filters.copyWith(adjustmentType: v);
                    },
                    displayStringForValue: (value) {
                      switch (value) {
                        case 'quantity':
                          return 'Type: By Quantity';
                        case 'value':
                          return 'Type: By Value';
                        default:
                          return 'Type: All';
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 140,
                  child: FormDropdown<String>(
                    value: _periodFilter,
                    items: _periodOptions,
                    hint: 'Period',
                    height: 30,
                    showSearch: false,
                    menuWidth: 200,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _periodFilter = v);
                    },
                    displayStringForValue: (value) {
                      switch (value) {
                        case 'today':
                          return 'Period: Today';
                        case 'this_week':
                          return 'Period: This Week';
                        case 'this_month':
                          return 'Period: This Month';
                        case 'this_quarter':
                          return 'Period: This Quarter';
                        case 'this_year':
                          return 'Period: This Year';
                        default:
                          return 'Period: All';
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Inventory Adjustments',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.0,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.barChart3, size: 15),
                  label: const Text(
                    'FIFO Cost Lot Tracking Report',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ZButton.primary(
                  label: 'New',
                  icon: LucideIcons.plus,
                  onPressed: _goToCreate,
                ),
                const SizedBox(width: 8),
                _buildMoreActionsMenu(),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          Container(
            height: 42,
            color: const Color(0xFFFAFAFA),
            padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
            child: Row(
              children: [
                const Text(
                  'Filter By :',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 134,
                  child: FormDropdown<String>(
                    value: filters.adjustmentType,
                    items: _typeOptions,
                    hint: 'Type',
                    height: 30,
                    menuWidth: 220,
                    showSearch: false,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    borderRadius: BorderRadius.circular(6),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixWidget: const Text(
                      'Type: ',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      ref
                          .read(inventoryAdjustmentsFiltersProvider.notifier)
                          .state = filters.copyWith(
                        adjustmentType: v,
                      );
                    },
                    displayStringForValue: (value) {
                      switch (value) {
                        case 'quantity':
                          return 'By Quantity';
                        case 'value':
                          return 'By Value';
                        default:
                          return 'All';
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 142,
                  child: FormDropdown<String>(
                    value: _periodFilter,
                    items: _periodOptions,
                    hint: 'Period',
                    height: 30,
                    menuWidth: 220,
                    showSearch: false,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    borderRadius: BorderRadius.circular(6),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixWidget: const Text(
                      'Period: ',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _periodFilter = v);
                    },
                    displayStringForValue: (value) {
                      switch (value) {
                        case 'today':
                          return 'Today';
                        case 'this_week':
                          return 'This Week';
                        case 'this_month':
                          return 'This Month';
                        case 'this_quarter':
                          return 'This Quarter';
                        case 'this_year':
                          return 'This Year';
                        default:
                          return 'All';
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<InventoryAdjustment> rows) {
    if (widget.compact) {
      return ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppTheme.borderLight),
        itemBuilder: (_, index) => _compactRow(rows[index]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedCountInRows(rows) > 0) _buildBulkActionBar(rows),
        if (_selectedCountInRows(rows) > 0)
          const Divider(height: 1, color: AppTheme.borderColor),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.borderColor),
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Column(
              children: [
                _tableHeader(rows),
                const Divider(height: 1, color: AppTheme.borderColor),
                Expanded(
                  child: rows.isEmpty
                      ? const Center(
                          child: Text(
                            'No inventory adjustments found.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppTheme.borderLight,
                          ),
                          itemBuilder: (_, index) => _tableRow(rows[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    if (widget.compact) {
      return Skeletonizer(
        enabled: true,
        ignoreContainers: true,
        child: ListView.separated(
          itemCount: 8,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppTheme.borderLight),
          itemBuilder: (_, __) => const ListTile(
            title: Text('Adjustment reason placeholder'),
            subtitle: Text('02-05-2026'),
            trailing: Text('DRAFT'),
          ),
        ),
      );
    }

    return Skeletonizer(
      enabled: true,
      ignoreContainers: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppTheme.borderColor),
                  bottom: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: Column(
                children: [
                  _tableHeader(const []),
                  const Divider(height: 1, color: AppTheme.borderColor),
                  Expanded(
                    child: ListView.separated(
                      itemCount: 8,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppTheme.borderLight),
                      itemBuilder: (_, __) => _skeletonTableRow(),
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

  Widget _skeletonTableRow() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 0, 8),
      child: Row(
        children: [
          SizedBox(width: 26, child: Checkbox(value: false, onChanged: null)),
          Expanded(flex: 2, child: _CellText('02-05-2026')),
          Expanded(flex: 2, child: _CellText('Stock correction')),
          Expanded(flex: 2, child: _CellText('Adjustment note')),
          Expanded(flex: 2, child: _CellText('ADJUSTED')),
          Expanded(flex: 2, child: _CellText('REF-00001')),
          Expanded(flex: 1, child: _CellText('Quantity')),
          Expanded(flex: 2, child: _CellText('zabnix')),
          Expanded(flex: 2, child: _CellText('02-05-2026 05:35 AM')),
          Expanded(flex: 2, child: _CellText('zabnix')),
          Expanded(flex: 2, child: _CellText('02-05-2026 09:38 AM')),
          SizedBox(
            width: 28,
            child: Icon(
              LucideIcons.moreHorizontal,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    final bg = isPrimary ? AppTheme.accentGreen : Colors.transparent;
    final fg = isPrimary ? Colors.white : AppTheme.textSecondary;
    return SizedBox(
      width: 32,
      height: 32,
      child: TextButton(
        onPressed: onTap,
        style: ButtonStyle(
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (isPrimary) {
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFF218838);
              }
              return bg;
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0x0D000000);
            }
            return Colors.transparent;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        child: Icon(icon, size: 20, color: fg),
      ),
    );
  }

  void _applySort(List<InventoryAdjustment> rows) {
    rows.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case 'reason':
          cmp = a.reason.toLowerCase().compareTo(b.reason.toLowerCase());
          break;
        case 'created_time':
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        case 'last_modified_time':
          cmp = a.updatedAt.compareTo(b.updatedAt);
          break;
        case 'date':
        default:
          cmp = a.adjustmentDate.compareTo(b.adjustmentDate);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  void _setSortField(String field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  ButtonStyle _menuItemStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return AppTheme.primaryBlue;
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return Colors.white;
        }
        return AppTheme.textPrimary;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return Colors.white;
        }
        return AppTheme.primaryBlue;
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _buildMoreActionsMenu() {
    final menuStyle = _menuItemStyle();
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        side: WidgetStatePropertyAll(
          BorderSide(color: AppTheme.borderColor),
        ),
      ),
      menuChildren: [
        SubmenuButton(
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            surfaceTintColor: WidgetStatePropertyAll(Colors.white),
          ),
          style: menuStyle,
          child: const Text('Sort by'),
          menuChildren: [
            MenuItemButton(
              style: menuStyle,
              onPressed: () => _setSortField('date'),
              trailingIcon: _sortField == 'date'
                  ? Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                    )
                  : null,
              child: const Text('Date'),
            ),
            MenuItemButton(
              style: menuStyle,
              onPressed: () => _setSortField('reason'),
              trailingIcon: _sortField == 'reason'
                  ? Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                    )
                  : null,
              child: const Text('Reason'),
            ),
            MenuItemButton(
              style: menuStyle,
              onPressed: () => _setSortField('created_time'),
              trailingIcon: _sortField == 'created_time'
                  ? Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                    )
                  : null,
              child: const Text('Created Time'),
            ),
            MenuItemButton(
              style: menuStyle,
              onPressed: () => _setSortField('last_modified_time'),
              trailingIcon: _sortField == 'last_modified_time'
                  ? Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                    )
                  : null,
              child: const Text('Last Modified Time'),
            ),
          ],
        ),
        SubmenuButton(
          style: menuStyle,
          child: const Text('Import'),
          menuChildren: [
            MenuItemButton(
              style: menuStyle,
              onPressed: () => ZerpaiToast.info(
                context,
                'Import quantity adjustments not wired yet',
              ),
              child: const Text('Import Quantity Adjustments'),
            ),
            MenuItemButton(
              style: menuStyle,
              onPressed: () => ZerpaiToast.info(
                context,
                'Import value adjustments not wired yet',
              ),
              child: const Text('Import Value Adjustments'),
            ),
          ],
        ),
        MenuItemButton(
          style: menuStyle,
          onPressed: () => ZerpaiToast.info(
            context,
            'Export inventory adjustments not wired yet',
          ),
          child: const Text('Export Inventory Adjustments'),
        ),
        MenuItemButton(
          style: menuStyle,
          onPressed: () {
            ref.invalidate(inventoryAdjustmentsListProvider);
            ZerpaiToast.info(context, 'List refreshed');
          },
          child: const Text('Refresh List'),
        ),
      ],
      builder: (context, controller, child) {
        return SizedBox(
          width: 40,
          height: 40,
          child: TextButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: const Color(0xFFF3F4F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: Color(0xFFD8DEE8)),
              ),
            ),
            child: const Icon(
              LucideIcons.moreHorizontal,
              size: 15,
              color: AppTheme.textSecondary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactMoreActionsMenu() {
    final menuStyle = _menuItemStyle();
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        side: WidgetStatePropertyAll(BorderSide(color: AppTheme.borderColor)),
      ),
      menuChildren: [
        SubmenuButton(
          style: menuStyle,
          child: const Text('Sort by'),
          menuChildren: [
            MenuItemButton(
              style: menuStyle,
              onPressed: () => _setSortField('date'),
              child: const Text('Date'),
            ),
            MenuItemButton(
              style: menuStyle,
              onPressed: () => _setSortField('reason'),
              child: const Text('Reason'),
            ),
            MenuItemButton(
              style: menuStyle,
              onPressed: () => _setSortField('created_time'),
              child: const Text('Created Time'),
            ),
            MenuItemButton(
              style: menuStyle,
              onPressed: () => _setSortField('last_modified_time'),
              child: const Text('Last Modified Time'),
            ),
          ],
        ),
        MenuItemButton(
          style: menuStyle,
          onPressed: () => ZerpaiToast.info(
            context,
            'Import not wired yet',
          ),
          child: const Text('Import'),
        ),
        MenuItemButton(
          style: menuStyle,
          onPressed: () => ZerpaiToast.info(
            context,
            'Export not wired yet',
          ),
          child: const Text('Export Inventory Adjustments'),
        ),
        MenuItemButton(
          style: menuStyle,
          onPressed: () {
            ref.invalidate(inventoryAdjustmentsListProvider);
            ZerpaiToast.info(context, 'List refreshed');
          },
          child: const Text('Refresh List'),
        ),
      ],
      builder: (context, controller, child) {
        return SizedBox(
          width: 32,
          height: 32,
          child: TextButton(
            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
            style: ButtonStyle(
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return const Color(0x0D000000);
                }
                return Colors.transparent;
              }),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            child: const Icon(
              LucideIcons.moreHorizontal,
              size: 20,
              color: AppTheme.textSecondary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulkActionBar(List<InventoryAdjustment> rows) {
    final count = _selectedCountInRows(rows);
    return Container(
      height: 56,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        border: Border.all(color: const Color(0xFFD8DEE8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'approve') {
                await _approveSelected(rows);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'approve',
                child: Text('Approve'),
              ),
            ],
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD0D7E2)),
                borderRadius: BorderRadius.circular(6.5),
              ),
              child: const Row(
                children: [
                  Text(
                    'Submit for Approval',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: () => _approveSelected(rows),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: Color(0xFFD0D7E2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Convert to Adjusted'),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: () => _deleteSelected(rows),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: Color(0xFFD0D7E2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Delete'),
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 24, color: AppTheme.borderColor),
          const SizedBox(width: 14),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE6EEF9),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Selected',
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => (_selectedIds ??= <String>{}).clear()),
            child: const Text(
              'Esc',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => (_selectedIds ??= <String>{}).clear()),
            icon: const Icon(Icons.close, color: AppTheme.errorRed, size: 18),
            tooltip: 'Clear selection',
          ),
        ],
      ),
    );
  }

  bool _isSelected(String id) => (_selectedIds ??= <String>{}).contains(id);

  bool _allRowsSelected(List<InventoryAdjustment> rows) {
    if (rows.isEmpty) return false;
    final selectedIds = (_selectedIds ??= <String>{});
    return rows.every((row) => selectedIds.contains(row.id));
  }

  int _selectedCountInRows(List<InventoryAdjustment> rows) {
    final selectedIds = (_selectedIds ??= <String>{});
    return rows.where((row) => selectedIds.contains(row.id)).length;
  }

  void _toggleRowSelection(String id, bool selected) {
    setState(() {
      if (selected) {
        (_selectedIds ??= <String>{}).add(id);
      } else {
        (_selectedIds ??= <String>{}).remove(id);
      }
    });
  }

  void _toggleSelectAll(List<InventoryAdjustment> rows, bool selected) {
    setState(() {
      if (selected) {
        (_selectedIds ??= <String>{}).addAll(rows.map((row) => row.id));
      } else {
        for (final row in rows) {
          (_selectedIds ??= <String>{}).remove(row.id);
        }
      }
    });
  }

  Future<void> _approveSelected(List<InventoryAdjustment> rows) async {
    final selectedIds = (_selectedIds ??= <String>{});
    final selectedRows = rows.where((row) => selectedIds.contains(row.id)).toList();
    if (selectedRows.isEmpty) return;

    int successCount = 0;
    int errorCount = 0;
    final Map<String, int> alreadyByStatus = <String, int>{};
    final List<String> errorMessages = <String>[];

    for (final row in selectedRows) {
      final status = row.status.toLowerCase();
      if (status != 'draft') {
        alreadyByStatus[status] = (alreadyByStatus[status] ?? 0) + 1;
        continue;
      }
      try {
        await ref.read(inventoryAdjustmentsActionsProvider).approve(row.id);
        successCount++;
      } catch (e) {
        errorCount++;
        errorMessages.add(ErrorHandler.getFriendlyMessage(e));
      }
    }

    if (!mounted) return;
    setState(() => (_selectedIds ??= <String>{}).clear());

    final total = selectedRows.length;
    final alreadyTotal = alreadyByStatus.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );

    String _statusLabelForMessage(String status) {
      switch (status) {
        case 'approved':
          return 'adjusted';
        case 'submitted':
          return 'submitted';
        case 'rejected':
          return 'rejected';
        case 'cancelled':
          return 'cancelled';
        default:
          return status;
      }
    }

    if (total == 1 && successCount == 0 && errorCount == 0 && alreadyTotal == 1) {
      final status = alreadyByStatus.keys.first;
      ZerpaiToast.error(
        context,
        'This adjustment is already ${_statusLabelForMessage(status)}.',
      );
      return;
    }

    final List<String> parts = <String>[];
    if (successCount > 0) {
      parts.add('$successCount approved');
    }
    if (alreadyTotal > 0) {
      final alreadyParts = alreadyByStatus.entries
          .map((entry) => '${entry.value} already ${_statusLabelForMessage(entry.key)}')
          .join(', ');
      parts.add(alreadyParts);
    }
    if (errorCount > 0) {
      parts.add('$errorCount errored');
    }

    if (parts.isEmpty) {
      ZerpaiToast.info(context, 'No adjustments were processed.');
      return;
    }

    final summary = '${parts.join(' | ')} out of $total selected';
    if (errorCount > 0) {
      final suffix = errorMessages.isNotEmpty ? ' (${errorMessages.first})' : '';
      ZerpaiToast.error(context, '$summary$suffix');
      return;
    }

    if (successCount > 0) {
      ZerpaiToast.success(context, summary);
    } else {
      ZerpaiToast.info(context, summary);
    }
  }

  Future<void> _deleteSelected(List<InventoryAdjustment> rows) async {
    final selectedIds = (_selectedIds ??= <String>{});
    final selectedRows = rows.where((row) => selectedIds.contains(row.id));
    if (selectedRows.isEmpty) return;
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Selected Adjustments',
      message: 'This cannot be undone. Delete selected draft adjustments?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (confirmed != true) return;
    try {
      for (final row in selectedRows) {
        if (row.status.toLowerCase() == 'draft') {
          await ref.read(inventoryAdjustmentsActionsProvider).delete(row.id);
        }
      }
      if (!mounted) return;
      setState(() => (_selectedIds ??= <String>{}).clear());
      ZerpaiToast.deleted(context, 'Selected adjustments');
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, ErrorHandler.getFriendlyMessage(e));
      }
    }
  }

  Widget _compactRow(InventoryAdjustment row) {
    final isSelected = row.id == widget.selectedAdjustmentId;
    final dateLabel = DateFormat('dd-MM-yyyy').format(row.adjustmentDate);

    return Material(
      color: isSelected ? const Color(0xFFE0EFFF) : Colors.white,
      child: InkWell(
        hoverColor: const Color(0xFFF8F9FA),
        onTap: () => widget.onSelectAdjustment(row.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _toLabel(row.reason),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                _statusLabel(row.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(row.status),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF0D6EFD);
      case 'submitted':
        return const Color(0xFFF4A100);
      case 'rejected':
        return AppTheme.errorRed;
      case 'cancelled':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _tableHeader(List<InventoryAdjustment> rows) {
    return Container(
      color: const Color(0xFFF4F5F8),
      padding: const EdgeInsets.fromLTRB(12, 6, 0, 6),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Checkbox(
              value: _allRowsSelected(rows),
              onChanged: rows.isEmpty
                  ? null
                  : (value) => _toggleSelectAll(rows, value ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Expanded(flex: 2, child: _HeaderText('Date')),
          Expanded(flex: 2, child: _HeaderText('Reason')),
          Expanded(flex: 2, child: _HeaderText('Description')),
          Expanded(flex: 2, child: _HeaderText('Status')),
          Expanded(flex: 2, child: _HeaderText('Reference Number')),
          Expanded(flex: 1, child: _HeaderText('Type')),
          Expanded(flex: 2, child: _HeaderText('Created By')),
          Expanded(flex: 2, child: _HeaderText('Created Time')),
          Expanded(flex: 2, child: _HeaderText('Last Modified By')),
          Expanded(flex: 2, child: _HeaderText('Last Modified Time')),
          SizedBox(
            width: 28,
            child: Icon(
              LucideIcons.search,
              size: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(InventoryAdjustment row) {
    final isSelected = row.id == widget.selectedAdjustmentId;
    final dateLabel = DateFormat('dd-MM-yyyy').format(row.adjustmentDate);
    final isDraft = row.status.toLowerCase() == 'draft';
    final isChecked = _isSelected(row.id);

    return Material(
      color: isSelected ? const Color(0xFFEEF4FF) : Colors.white,
      child: InkWell(
        onTap: () => widget.onSelectAdjustment(row.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Checkbox(
                  value: isChecked,
                  onChanged: (value) =>
                      _toggleRowSelection(row.id, value ?? false),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Expanded(flex: 2, child: _CellText(dateLabel)),
              Expanded(flex: 2, child: _CellText(_toLabel(row.reason))),
              Expanded(
                flex: 2,
                child: _CellText(
                  (row.notes ?? '').trim().isEmpty ? '-' : row.notes!.trim(),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _statusLabel(row.status),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryBlue,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _CellText(
                  (row.referenceNumber ?? '').trim().isEmpty
                      ? '-'
                      : row.referenceNumber!.trim(),
                ),
              ),
              Expanded(flex: 1, child: _CellText(_toLabel(row.adjustmentType))),
              Expanded(flex: 2, child: _CellText(_actorLabel(row))),
              Expanded(
                flex: 2,
                child: _CellText(
                  DateFormat('dd-MM-yyyy hh:mm a').format(row.createdAt.toLocal()),
                ),
              ),
              Expanded(flex: 2, child: _CellText(_actorLabel(row))),
              Expanded(
                flex: 2,
                child: _CellText(
                  DateFormat('dd-MM-yyyy hh:mm a').format(row.updatedAt.toLocal()),
                ),
              ),
              SizedBox(
                width: 28,
                child: _RowMenu(
                  onApprove: isDraft ? () => _approve(row) : null,
                  onReject: isDraft ? () => _reject(row.id) : null,
                  onDelete: isDraft ? () => _delete(row.id) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.alertTriangle,
            color: AppTheme.warningOrange,
            size: 22,
          ),
          const SizedBox(height: 10),
          const Text(
            'Unable to load inventory adjustments.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  bool _matchesPeriod(InventoryAdjustment row) {
    final now = DateTime.now();
    final d = row.adjustmentDate;
    switch (_periodFilter) {
      case 'today':
        return d.year == now.year && d.month == now.month && d.day == now.day;
      case 'this_week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return !d.isBefore(DateTime(start.year, start.month, start.day)) &&
            d.isBefore(DateTime(end.year, end.month, end.day));
      case 'this_month':
        return d.year == now.year && d.month == now.month;
      default:
        return true;
    }
  }

  String _toLabel(String value) {
    if (value.trim().isEmpty) return value;
    return value
        .split('_')
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  String _actorLabel(InventoryAdjustment row) {
    final preferred = (row.adjustedByName ?? '').trim();
    if (preferred.isNotEmpty) return preferred;
    final fallback = (row.adjustedBy ?? '').trim();
    if (fallback.isEmpty || _isUuid(fallback)) return '-';
    return fallback;
  }

  bool _isUuid(String v) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(v);

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'ADJUSTED';
      case 'submitted':
        return 'SUBMITTED';
      case 'rejected':
        return 'REJECTED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return 'DRAFT';
    }
  }

}

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
      letterSpacing: 0.1,
    ),
  );
}

class _CellText extends StatelessWidget {
  final String text;
  const _CellText(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppTheme.textPrimary,
    ),
  );
}

class _RowMenu extends StatelessWidget {
  final Future<void> Function()? onApprove;
  final Future<void> Function()? onReject;
  final Future<void> Function()? onDelete;

  const _RowMenu({this.onApprove, this.onReject, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final items = <PopupMenuEntry<String>>[];
    if (onApprove != null) {
      items.add(const PopupMenuItem(value: 'approve', child: Text('Approve')));
    }
    if (onReject != null) {
      items.add(const PopupMenuItem(value: 'reject', child: Text('Reject')));
    }
    if (onDelete != null) {
      items.add(
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Actions',
      offset: const Offset(-100, 24),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) async {
        if (value == 'approve') await onApprove?.call();
        if (value == 'reject') await onReject?.call();
        if (value == 'delete') await onDelete?.call();
      },
      itemBuilder: (_) => items,
      icon: const Icon(
        LucideIcons.moreHorizontal,
        size: 16,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
