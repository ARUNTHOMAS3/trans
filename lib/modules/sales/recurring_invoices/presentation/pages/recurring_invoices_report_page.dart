import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/modules/sales/recurring_invoices/models/recurring_invoices_model.dart';
import 'package:zerpai_erp/modules/sales/recurring_invoices/providers/recurring_invoices_provider.dart';

class RecurringInvoicesReportPage extends ConsumerStatefulWidget {
  const RecurringInvoicesReportPage({super.key});

  @override
  ConsumerState<RecurringInvoicesReportPage> createState() =>
      _RecurringInvoicesReportPageState();
}

class _RecurringInvoicesReportPageState
    extends ConsumerState<RecurringInvoicesReportPage> {
  late final ScrollController _rightController;
  final _searchCtrl = TextEditingController();

  OverlayEntry? _filterOverlayEntry;
  LayerLink? __filterLayerLink;
  LayerLink get _filterLayerLink => __filterLayerLink ??= LayerLink();
  bool _isFilterOpen = false;
  String _selectedFilterLabel = 'All';
  Set<String>? _favorites = <String>{};

  String _sortByField = 'Customer Name';
  bool _sortAscending = true;

  // ── Row selection ──────────────────────────────────────────
  final Set<String> _selectedIds = {};
  bool get _hasSelection => _selectedIds.isNotEmpty;

  // Settings overlay
  OverlayEntry? _settingsOverlayEntry;
  LayerLink? __settingsLayerLink;
  LayerLink get _settingsLayerLink => __settingsLayerLink ??= LayerLink();
  bool _isSettingsOpen = false;
  bool _clipText = false;

  List<ColumnConfig> _columns = [
    ColumnConfig(
      id: 'CUSTOMER NAME',
      label: 'Customer Name',
      isLocked: true,
      orderIndex: 0,
    ),
    ColumnConfig(
      id: 'PROFILE NAME',
      label: 'Profile Name',
      isLocked: true,
      orderIndex: 1,
    ),
    ColumnConfig(
      id: 'FREQUENCY',
      label: 'Frequency',
      isLocked: true,
      orderIndex: 2,
    ),
    ColumnConfig(
      id: 'NEXT INVOICE DATE',
      label: 'Next Invoice Date',
      isLocked: true,
      orderIndex: 3,
    ),
    ColumnConfig(id: 'STATUS', label: 'Status', isLocked: true, orderIndex: 4),
    ColumnConfig(id: 'AMOUNT', label: 'Amount', isLocked: true, orderIndex: 5),
    ColumnConfig(
      id: 'LOCATION',
      label: 'Location',
      isVisible: false,
      orderIndex: 6,
    ),
    ColumnConfig(
      id: 'LAST INVOICE DATE',
      label: 'Last Invoice Date',
      isVisible: false,
      orderIndex: 7,
    ),
    ColumnConfig(
      id: 'END DATE',
      label: 'End Date',
      isVisible: false,
      orderIndex: 8,
    ),
    ColumnConfig(
      id: 'SALES PERSON',
      label: 'Sales person',
      isVisible: false,
      orderIndex: 9,
    ),
  ];

  Map<String, double>? __columnWidths;
  Map<String, double> get _columnWidths => __columnWidths ??= {
    'CUSTOMER NAME': 250.0,
    'PROFILE NAME': 220.0,
    'FREQUENCY': 180.0,
    'NEXT INVOICE DATE': 200.0,
    'STATUS': 150.0,
    'AMOUNT': 150.0,
    'LOCATION': 150.0,
    'LAST INVOICE DATE': 150.0,
    'END DATE': 150.0,
    'SALES PERSON': 150.0,
  };

  @override
  void initState() {
    super.initState();
    _rightController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(recurringInvoicesProvider.notifier).loadInvoices();
    });
  }

  @override
  void deactivate() {
    _closeFilterOverlay();
    _closeSettingsOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _closeFilterOverlay();
    _closeSettingsOverlay();
    _rightController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleFilterOverlay() {
    if (_isFilterOpen) {
      _closeFilterOverlay();
    } else {
      _showFilterOverlay();
    }
  }

  void _showFilterOverlay() {
    if (_filterOverlayEntry != null) return;
    _showFilterOverlayInternal();
  }

  void _showFilterOverlayInternal() {
    _filterOverlayEntry = OverlayEntry(
      builder: (context) {
        final currentFavs = _favorites ?? <String>{};
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeFilterOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _filterLayerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 8),
              child: Material(
                color: Colors.transparent,
                child: _FilterDropdownMenu(
                  selectedFilter: _selectedFilterLabel,
                  favorites: currentFavs,
                  onFilterSelected: (label, status) {
                    setState(() {
                      _selectedFilterLabel = label;
                    });
                    ref
                        .read(recurringInvoicesProvider.notifier)
                        .setFilter(status);
                    _closeFilterOverlay();
                  },
                  onFavoriteToggled: (label) {
                    setState(() {
                      final favs = _favorites ??= <String>{};
                      if (favs.contains(label)) {
                        favs.remove(label);
                      } else {
                        favs.add(label);
                      }
                    });
                    _filterOverlayEntry?.markNeedsBuild();
                  },
                  onClose: _closeFilterOverlay,
                ),
              ),
            ),
          ],
        );
      },
    );

    setState(() => _isFilterOpen = true);
    Overlay.of(context).insert(_filterOverlayEntry!);
  }

  void _closeFilterOverlay() {
    if (_filterOverlayEntry != null) {
      _filterOverlayEntry!.remove();
      _filterOverlayEntry = null;
      if (mounted) setState(() => _isFilterOpen = false);
    }
  }

  void _toggleSettingsOverlay() {
    if (_isSettingsOpen) {
      _closeSettingsOverlay();
    } else {
      _showSettingsOverlay();
    }
  }

  void _showSettingsOverlay() {
    if (_settingsOverlayEntry != null) return;
    _settingsOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeSettingsOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _settingsLayerLink,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 8),
            child: Material(
              color: Colors.transparent,
              child: _TableSettingsMenu(
                onClose: _closeSettingsOverlay,
                onCustomizeColumns: _showCustomizeColumnsDialog,
                clipText: _clipText,
                onClipTextToggled: () {
                  setState(() {
                    _clipText = !_clipText;
                  });
                  _settingsOverlayEntry?.markNeedsBuild();
                },
              ),
            ),
          ),
        ],
      ),
    );
    if (mounted) setState(() => _isSettingsOpen = true);
    Overlay.of(context).insert(_settingsOverlayEntry!);
  }

  void _closeSettingsOverlay() {
    if (_settingsOverlayEntry != null) {
      _settingsOverlayEntry!.remove();
      _settingsOverlayEntry = null;
      if (mounted) setState(() => _isSettingsOpen = false);
    }
  }

  void _showCustomizeColumnsDialog() {
    _closeSettingsOverlay();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => ColumnCustomizerDialog(
        columns: _columns
            .map((c) => ColumnConfig.fromJson(c.toJson()))
            .toList(),
        onSave: (newColumns) {
          Navigator.pop(ctx, newColumns);
        },
      ),
    ).then((dynamic result) {
      if (result != null && result is List<ColumnConfig> && mounted) {
        setState(() => _columns = result);
      }
    });
  }

  Future<void> _deleteRecurringInvoice(String id) async {
    await ref.read(recurringInvoicesProvider.notifier).deleteInvoicePermanently(id);
  }

  String get _orgId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

  @override
  Widget build(BuildContext context) {
    if ((_favorites as dynamic) == null) {
      _favorites = <String>{};
    }
    final state = ref.watch(recurringInvoicesProvider);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateF = DateFormat('dd-MM-yyyy');

    final filtered = List<RecurringInvoice>.from(state.filteredInvoices);
    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortByField) {
        case 'Customer Name':
          cmp = a.customerName.toLowerCase().compareTo(
            b.customerName.toLowerCase(),
          );
          break;
        case 'Profile Name':
          cmp = a.profileName.toLowerCase().compareTo(
            b.profileName.toLowerCase(),
          );
          break;
        case 'Frequency':
          cmp = a.billingFrequency.toLowerCase().compareTo(
            b.billingFrequency.toLowerCase(),
          );
          break;
        case 'Next Invoice Date':
          if (a.nextInvoiceDate == null && b.nextInvoiceDate == null)
            cmp = 0;
          else if (a.nextInvoiceDate == null)
            cmp = -1;
          else if (b.nextInvoiceDate == null)
            cmp = 1;
          else
            cmp = a.nextInvoiceDate!.compareTo(b.nextInvoiceDate!);
          break;
        case 'Status':
          cmp = a.status.label.compareTo(b.status.label);
          break;
        case 'Amount':
          cmp = a.amount.compareTo(b.amount);
          break;
        default:
          cmp = a.customerName.compareTo(b.customerName);
      }
      return _sortAscending ? cmp : -cmp;
    });

    final activeCols = _columns.where((c) => c.isVisible).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final rightSideWidth =
        activeCols.fold<double>(
          0.0,
          (sum, col) => sum + (_columnWidths[col.id] ?? 120.0),
        ) +
        60.0;

    return ZerpaiLayout(
      pageTitle: '',
      useTopPadding: false,
      useHorizontalPadding: false,
      enableBodyScroll: false,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Custom Header or Selection Ribbon ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _hasSelection
                  ? _SelectionRibbon(
                      selectedCount: _selectedIds.length,
                      onClear: () => setState(() => _selectedIds.clear()),
                      onResume: () {
                        for (final id in _selectedIds) {
                          final inv = ref
                              .read(recurringInvoicesProvider)
                              .invoices
                              .firstWhere((e) => e.id == id);
                          ref
                              .read(recurringInvoicesProvider.notifier)
                              .updateInvoice(
                                inv.copyWith(status: RecurringStatus.active),
                              );
                        }
                        setState(() => _selectedIds.clear());
                        ZerpaiToast.success(
                          context,
                          'Activated selected invoices',
                        );
                      },
                      onStop: () {
                        for (final id in _selectedIds) {
                          final inv = ref
                              .read(recurringInvoicesProvider)
                              .invoices
                              .firstWhere((e) => e.id == id);
                          ref
                              .read(recurringInvoicesProvider.notifier)
                              .updateInvoice(
                                inv.copyWith(status: RecurringStatus.stopped),
                              );
                        }
                        setState(() => _selectedIds.clear());
                        ZerpaiToast.success(
                          context,
                          'Stopped selected invoices',
                        );
                      },
                      onDelete: () async {
                        final ok = await showZerpaiConfirmationDialog(
                          context,
                          title: 'Delete Selected',
                          message:
                              'Delete ${_selectedIds.length} selected recurring invoice(s)? This cannot be undone.',
                          confirmLabel: 'Delete',
                          variant: ZerpaiConfirmationVariant.danger,
                        );
                        if (ok && mounted) {
                          for (final id in _selectedIds.toList()) {
                            await _deleteRecurringInvoice(id);
                          }
                          setState(() => _selectedIds.clear());
                          ZerpaiToast.deleted(
                            context,
                            'Selected recurring invoices',
                          );
                        }
                      },
                      onBulkUpdate: () async {
                        final selectedInvs = ref
                            .read(recurringInvoicesProvider)
                            .invoices
                            .where((inv) => _selectedIds.contains(inv.id))
                            .toList();
                        final result = await showDialog<Map<String, String>>(
                          context: context,
                          barrierColor: Colors.black54,
                          builder: (ctx) =>
                              _BulkUpdateDialog(selectedInvoices: selectedInvs),
                        );
                        if (result != null && mounted) {
                          final field = result['field'];
                          final value = result['value']!;
                          for (final id in _selectedIds) {
                            final inv = ref
                                .read(recurringInvoicesProvider)
                                .invoices
                                .firstWhere((e) => e.id == id);
                            if (field == 'Billing Frequency') {
                              ref
                                  .read(recurringInvoicesProvider.notifier)
                                  .updateInvoice(
                                    inv.copyWith(billingFrequency: value),
                                  );
                            } else if (field == 'Status') {
                              final status = RecurringStatus.values.firstWhere(
                                (s) =>
                                    s.label.toLowerCase() ==
                                    value.toLowerCase(),
                                orElse: () => RecurringStatus.active,
                              );
                              ref
                                  .read(recurringInvoicesProvider.notifier)
                                  .updateInvoice(inv.copyWith(status: status));
                            }
                          }
                          setState(() => _selectedIds.clear());
                          ZerpaiToast.success(
                            context,
                            'Updated selected invoices',
                          );
                        }
                      },
                    )
                  : Row(
                      children: [
                        CompositedTransformTarget(
                          link: _filterLayerLink,
                          child: InkWell(
                            onTap: _toggleFilterOverlay,
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedFilterLabel == 'All'
                                      ? 'All Recurring Invoices'
                                      : _selectedFilterLabel,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _isFilterOpen
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isFilterOpen
                                      ? LucideIcons.chevronUp
                                      : LucideIcons.chevronDown,
                                  size: 14,
                                  color: AppTheme.primaryBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Green "+ New" Button
                        ElevatedButton.icon(
                          onPressed: () => context.go(
                            '/$_orgId${AppRoutes.salesRecurringInvoicesCreate}',
                          ),
                          icon: const Icon(
                            LucideIcons.plus,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'New',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22A95E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ── 3-dot Options Menu ────────────────────────────
                        _TableOptionsMenu(
                          sortByField: _sortByField,
                          sortAscending: _sortAscending,
                          onSortChanged: (field, asc) {
                            setState(() {
                              _sortByField = field;
                              _sortAscending = asc;
                            });
                          },
                          onRefresh: () {
                            ref
                                .read(recurringInvoicesProvider.notifier)
                                .loadInvoices();
                          },
                          onResetColumnWidths: () {
                            setState(() => __columnWidths = null);
                          },
                          onCustomizeColumns: _showCustomizeColumnsDialog,
                        ),
                      ],
                    ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // ── Unified Table Layout ──────────────────────────────────
            Expanded(
              child: state.isLoading && state.invoices.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF22A95E),
                      ),
                    )
                  : filtered.isEmpty
                  ? _EmptyState(
                      hasFilter:
                          state.activeFilter != null ||
                          state.searchQuery.isNotEmpty,
                      onNewTap: () => context.go(
                        '/$_orgId${AppRoutes.salesRecurringInvoicesCreate}',
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final tableWidth = constraints.maxWidth > rightSideWidth
                            ? constraints.maxWidth
                            : rightSideWidth;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Header Row
                                    Container(
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF9FAFB),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Color(0xFFE5E7EB),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          ...activeCols.map((col) {
                                            if (col.id == 'CUSTOMER NAME') {
                                              return _customerNameThHeader(
                                                filtered,
                                              );
                                            }
                                            return _thHeader(
                                              col.label.toUpperCase(),
                                              col.id,
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                    // Rows
                                    Expanded(
                                      child: ListView.separated(
                                        controller: _rightController,
                                        padding: EdgeInsets.zero,
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                              height: 1,
                                              color: Color(0xFFE5E7EB),
                                            ),
                                        itemBuilder: (_, idx) {
                                          final inv = filtered[idx];
                                          return Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              hoverColor: const Color(
                                                0xFFF3F4F6,
                                              ),
                                              onTap: () {
                                                final detailPath = AppRoutes
                                                    .salesRecurringInvoicesDetail
                                                    .replaceAll(':id', inv.id);
                                                context.go(
                                                  '/$_orgId$detailPath',
                                                );
                                              },
                                              child: Container(
                                                height: 60,
                                                child: Row(
                                                  children: [
                                                    ...activeCols.map((col) {
                                                      switch (col.id) {
                                                        case 'CUSTOMER NAME':
                                                          return _customerNameTdCell(
                                                            inv,
                                                          );
                                                        case 'PROFILE NAME':
                                                          return _tdCell(
                                                            Text(
                                                              inv.profileName,
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Color(
                                                                  0xFF2563EB,
                                                                ),
                                                              ),
                                                              maxLines:
                                                                  _clipText
                                                                  ? 1
                                                                  : null,
                                                              overflow:
                                                                  _clipText
                                                                  ? TextOverflow
                                                                        .ellipsis
                                                                  : TextOverflow
                                                                        .clip,
                                                            ),
                                                            'PROFILE NAME',
                                                          );
                                                        case 'FREQUENCY':
                                                          return _tdCell(
                                                            Text(
                                                              inv.billingFrequency,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Color(
                                                                      0xFF1F2937,
                                                                    ),
                                                                  ),
                                                              maxLines:
                                                                  _clipText
                                                                  ? 1
                                                                  : null,
                                                              overflow:
                                                                  _clipText
                                                                  ? TextOverflow
                                                                        .ellipsis
                                                                  : TextOverflow
                                                                        .clip,
                                                            ),
                                                            'FREQUENCY',
                                                          );
                                                        case 'NEXT INVOICE DATE':
                                                          final dateStr =
                                                              inv.nextInvoiceDate !=
                                                                  null
                                                              ? dateF.format(
                                                                  inv.nextInvoiceDate!,
                                                                )
                                                              : '--';
                                                          return _tdCell(
                                                            Text(
                                                              dateStr,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Color(
                                                                      0xFF1F2937,
                                                                    ),
                                                                  ),
                                                              maxLines:
                                                                  _clipText
                                                                  ? 1
                                                                  : null,
                                                              overflow:
                                                                  _clipText
                                                                  ? TextOverflow
                                                                        .ellipsis
                                                                  : TextOverflow
                                                                        .clip,
                                                            ),
                                                            'NEXT INVOICE DATE',
                                                          );
                                                        case 'STATUS':
                                                          final isDraft =
                                                              inv.status ==
                                                              RecurringStatus
                                                                  .draft;
                                                          final isActive =
                                                              inv.status ==
                                                              RecurringStatus
                                                                  .active;
                                                          final isStopped =
                                                              inv.status ==
                                                              RecurringStatus
                                                                  .stopped;
                                                          return _tdCell(
                                                            Text(
                                                              inv.status.label
                                                                  .toUpperCase(),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: isDraft
                                                                    ? const Color(
                                                                        0xFF6B7280,
                                                                      )
                                                                    : (isActive
                                                                          ? const Color(
                                                                              0xFF22A95E,
                                                                            )
                                                                          : (isStopped
                                                                                ? const Color(
                                                                                    0xFFEF4444,
                                                                                  )
                                                                                : const Color(0xFFF59E0B))),
                                                              ),
                                                              maxLines:
                                                                  _clipText
                                                                  ? 1
                                                                  : null,
                                                              overflow:
                                                                  _clipText
                                                                  ? TextOverflow
                                                                        .ellipsis
                                                                  : TextOverflow
                                                                        .clip,
                                                            ),
                                                            'STATUS',
                                                          );
                                                        case 'AMOUNT':
                                                          return _tdCell(
                                                            Text(
                                                              currency.format(
                                                                inv.amount,
                                                              ),
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Color(
                                                                  0xFF1F2937,
                                                                ),
                                                              ),
                                                              maxLines:
                                                                  _clipText
                                                                  ? 1
                                                                  : null,
                                                              overflow:
                                                                  _clipText
                                                                  ? TextOverflow
                                                                        .ellipsis
                                                                  : TextOverflow
                                                                        .clip,
                                                            ),
                                                            'AMOUNT',
                                                          );
                                                        case 'LOCATION':
                                                          return _tdCell(
                                                            Text(
                                                              inv.location.trim().isEmpty
                                                                  ? '--'
                                                                  : inv.location,
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(0xFF1F2937),
                                                              ),
                                                              maxLines:
                                                                  _clipText ? 1 : null,
                                                              overflow:
                                                                  _clipText
                                                                      ? TextOverflow.ellipsis
                                                                      : TextOverflow.clip,
                                                            ),
                                                            'LOCATION',
                                                          );
                                                        case 'LAST INVOICE DATE':
                                                          final lastInvoiceDate =
                                                              inv.lastInvoiceDate !=
                                                                      null
                                                                  ? dateF.format(
                                                                      inv.lastInvoiceDate!,
                                                                    )
                                                                  : '--';
                                                          return _tdCell(
                                                            Text(
                                                              lastInvoiceDate,
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(0xFF1F2937),
                                                              ),
                                                              maxLines:
                                                                  _clipText ? 1 : null,
                                                              overflow:
                                                                  _clipText
                                                                      ? TextOverflow.ellipsis
                                                                      : TextOverflow.clip,
                                                            ),
                                                            'LAST INVOICE DATE',
                                                          );
                                                        case 'END DATE':
                                                          final endDate = inv.endDate != null
                                                              ? dateF.format(
                                                                  inv.endDate!,
                                                                )
                                                              : '--';
                                                          return _tdCell(
                                                            Text(
                                                              endDate,
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(0xFF1F2937),
                                                              ),
                                                              maxLines:
                                                                  _clipText ? 1 : null,
                                                              overflow:
                                                                  _clipText
                                                                      ? TextOverflow.ellipsis
                                                                      : TextOverflow.clip,
                                                            ),
                                                            'END DATE',
                                                          );
                                                        case 'SALES PERSON':
                                                          return _tdCell(
                                                            Text(
                                                              inv.salespersonName
                                                                      .trim()
                                                                      .isEmpty
                                                                  ? '--'
                                                                  : inv.salespersonName,
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(0xFF1F2937),
                                                              ),
                                                              maxLines:
                                                                  _clipText ? 1 : null,
                                                              overflow:
                                                                  _clipText
                                                                      ? TextOverflow.ellipsis
                                                                      : TextOverflow.clip,
                                                            ),
                                                            'SALES PERSON',
                                                          );
                                                        default:
                                                          return _tdCell(
                                                            const Text(
                                                              '--',
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color: Color(
                                                                  0xFF9CA3AF,
                                                                ),
                                                              ),
                                                            ),
                                                            col.id,
                                                          );
                                                      }
                                                    }),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customerNameThHeader(List<RecurringInvoice> allInvoices) {
    final width = _columnWidths['CUSTOMER NAME'] ?? 250.0;
    final allSelected =
        allInvoices.isNotEmpty && _selectedIds.length == allInvoices.length;
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            padding: const EdgeInsets.only(left: 16, right: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                CompositedTransformTarget(
                  link: _settingsLayerLink,
                  child: InkWell(
                    onTap: _toggleSettingsOverlay,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        LucideIcons.settings2,
                        size: 14,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 16,
                  width: 16,
                  child: Checkbox(
                    tristate: false,
                    value: _hasSelection,
                    activeColor: const Color(0xFF2563EB),
                    checkColor: Colors.white,
                    onChanged: (_) {
                      setState(() {
                        if (allSelected) {
                          _selectedIds.clear();
                        } else {
                          _selectedIds
                            ..clear()
                            ..addAll(allInvoices.map((e) => e.id));
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'CUSTOMER NAME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A94A6),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -12,
            top: 0,
            bottom: 0,
            child: _ColumnResizer(
              width: width,
              onDragStart: () {},
              onDragEnd: () {},
              onResize: (newWidth) {
                setState(() {
                  _columnWidths['CUSTOMER NAME'] = newWidth;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerNameTdCell(RecurringInvoice inv) {
    final width = _columnWidths['CUSTOMER NAME'] ?? 250.0;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const SizedBox(width: 26),
          SizedBox(
            height: 16,
            width: 16,
            child: Checkbox(
              value: _selectedIds.contains(inv.id),
              activeColor: const Color(0xFF2563EB),
              checkColor: Colors.white,
              onChanged: (_) {
                setState(() {
                  if (_selectedIds.contains(inv.id)) {
                    _selectedIds.remove(inv.id);
                  } else {
                    _selectedIds.add(inv.id);
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              inv.customerName,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _thHeader(String label, String key) {
    final width = _columnWidths[key] ?? 120.0;
    final isRightAlign = key == 'AMOUNT' || key == 'BALANCE';
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            padding: const EdgeInsets.only(left: 12, right: 16),
            alignment: isRightAlign
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8A94A6),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Positioned(
            right: -12,
            top: 0,
            bottom: 0,
            child: _ColumnResizer(
              width: width,
              onDragStart: () {},
              onDragEnd: () {},
              onResize: (newWidth) {
                setState(() {
                  _columnWidths[key] = newWidth;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tdCell(Widget child, String key) {
    final width = _columnWidths[key] ?? 120.0;
    final isRightAlign = key == 'AMOUNT' || key == 'BALANCE';
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: isRightAlign ? Alignment.centerRight : Alignment.centerLeft,
      child: child,
    );
  }
}

class _ColumnResizer extends StatefulWidget {
  final double width;
  final ValueChanged<double> onResize;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const _ColumnResizer({
    required this.width,
    required this.onResize,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<_ColumnResizer> createState() => _ColumnResizerState();
}

class _ColumnResizerState extends State<_ColumnResizer> {
  bool _isHovered = false;
  bool _isDragging = false;
  static const double _minWidth = 80.0;

  void _setHovered(bool v) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isHovered = v);
    });
  }

  void _setDragging(bool v) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isDragging = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) {
        _setDragging(true);
        widget.onDragStart?.call();
      },
      onHorizontalDragUpdate: (details) {
        final newWidth = widget.width + details.delta.dx;
        if (newWidth >= _minWidth && mounted) widget.onResize(newWidth);
      },
      onHorizontalDragEnd: (_) {
        _setDragging(false);
        widget.onDragEnd?.call();
      },
      onHorizontalDragCancel: () {
        _setDragging(false);
        widget.onDragEnd?.call();
      },
      child: MouseRegion(
        cursor: _isDragging
            ? SystemMouseCursors.none
            : SystemMouseCursors.resizeLeftRight,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: Container(
          width: 24,
          height: double.infinity,
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (_isHovered || _isDragging)
                Positioned(
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          size: 11,
                          color: Color(0xFF1F2937),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 4,
                          height: 15,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFCF8E3),
                            border: Border(
                              left: BorderSide(
                                color: Color(0xFF1F2937),
                                width: 1.5,
                              ),
                              right: BorderSide(
                                color: Color(0xFFD1D5DB),
                                width: 0.5,
                              ),
                              top: BorderSide(
                                color: Color(0xFFD1D5DB),
                                width: 0.5,
                              ),
                              bottom: BorderSide(
                                color: Color(0xFFD1D5DB),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward,
                          size: 11,
                          color: Color(0xFF1F2937),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onNewTap;

  const _EmptyState({required this.hasFilter, required this.onNewTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.infoBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.fileText,
              size: 30,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? 'No profiles match your filters'
                : 'No Recurring Invoices yet',
            style: AppTheme.sectionHeader,
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Try clearing the active filter or search.'
                : 'Create and manage recurring invoice schedules.',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!hasFilter)
            ZButton.primary(
              label: 'New Recurring Invoice',
              icon: LucideIcons.plus,
              onPressed: onNewTap,
            ),
        ],
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final RecurringStatus? status;
  const _FilterOption(this.label, this.status);
}

class _FilterDropdownMenu extends StatefulWidget {
  final String selectedFilter;
  final Set<String>? favorites;
  final void Function(String label, RecurringStatus? status) onFilterSelected;
  final void Function(String label) onFavoriteToggled;
  final VoidCallback onClose;

  const _FilterDropdownMenu({
    required this.selectedFilter,
    required this.favorites,
    required this.onFilterSelected,
    required this.onFavoriteToggled,
    required this.onClose,
  });

  @override
  State<_FilterDropdownMenu> createState() => _FilterDropdownMenuState();
}

class _FilterDropdownMenuState extends State<_FilterDropdownMenu> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';

  bool _favoritesExpanded = true;
  bool _defaultFiltersExpanded = true;

  static const _allOptions = [
    _FilterOption('All', null),
    _FilterOption('Draft', RecurringStatus.draft),
    _FilterOption('Active', RecurringStatus.active),
    _FilterOption('Stopped', RecurringStatus.stopped),
    _FilterOption('Expired', RecurringStatus.expired),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
              size: 14,
              color: isExpanded
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF6B7280).withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
                color: isExpanded
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF6B7280).withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isExpanded
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF9CA3AF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOptions = _allOptions.where((opt) {
      if (_query.isEmpty) return true;
      return opt.label.toLowerCase().contains(_query);
    }).toList();

    final currentFavs = widget.favorites ?? const <String>{};
    final favoriteOptions = filteredOptions
        .where((opt) => currentFavs.contains(opt.label))
        .toList();

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 36,
            margin: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (favoriteOptions.isNotEmpty) ...[
                    _buildSectionHeader(
                      title: 'FAVORITES',
                      count: currentFavs.length,
                      isExpanded: _favoritesExpanded,
                      onTap: () => setState(
                        () => _favoritesExpanded = !_favoritesExpanded,
                      ),
                    ),
                    if (_favoritesExpanded)
                      ...favoriteOptions.map((opt) {
                        return _DropdownItem(
                          label: opt.label,
                          isSelected: widget.selectedFilter == opt.label,
                          isFavorite: true,
                          onTap: () =>
                              widget.onFilterSelected(opt.label, opt.status),
                          onFavoriteToggled: () =>
                              widget.onFavoriteToggled(opt.label),
                        );
                      }),
                    const SizedBox(height: 4),
                    _buildSectionHeader(
                      title: 'DEFAULT FILTERS',
                      count: filteredOptions.length,
                      isExpanded: _defaultFiltersExpanded,
                      onTap: () => setState(
                        () =>
                            _defaultFiltersExpanded = !_defaultFiltersExpanded,
                      ),
                    ),
                    if (_defaultFiltersExpanded)
                      ...filteredOptions.map((opt) {
                        final isFav = currentFavs.contains(opt.label);
                        return _DropdownItem(
                          label: opt.label,
                          isSelected: widget.selectedFilter == opt.label,
                          isFavorite: isFav,
                          onTap: () =>
                              widget.onFilterSelected(opt.label, opt.status),
                          onFavoriteToggled: () =>
                              widget.onFavoriteToggled(opt.label),
                        );
                      }),
                  ] else ...[
                    ...filteredOptions.map((opt) {
                      final isFav = currentFavs.contains(opt.label);
                      return _DropdownItem(
                        label: opt.label,
                        isSelected: widget.selectedFilter == opt.label,
                        isFavorite: isFav,
                        onTap: () =>
                            widget.onFilterSelected(opt.label, opt.status),
                        onFavoriteToggled: () =>
                            widget.onFavoriteToggled(opt.label),
                      );
                    }),
                  ],
                  if (filteredOptions.isEmpty && favoriteOptions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No matches found',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
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
    );
  }
}

class _DropdownItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggled;

  const _DropdownItem({
    required this.label,
    required this.isSelected,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggled,
  });

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _isHovered = false;

  void _setHovered(bool v) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isHovered = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color textIconColor = _isHovered
        ? Colors.white
        : (widget.isSelected
              ? const Color(0xFF1F2937)
              : const Color(0xFF4B5563));
    final Color bg = _isHovered
        ? const Color(0xFF3B82F6)
        : (widget.isSelected ? const Color(0xFFF3F4F6) : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: bg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (widget.isSelected && widget.label != 'All')
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: textIconColor,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  widget.onFavoriteToggled();
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    widget.isFavorite ? Icons.star : Icons.star_border,
                    size: 15,
                    color: widget.isFavorite
                        ? const Color(0xFFF59E0B)
                        : (_isHovered ? Colors.white : const Color(0xFF9CA3AF)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Table Settings Menu ----------------------------------------------------

class _TableSettingsMenu extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onCustomizeColumns;
  final bool clipText;
  final VoidCallback onClipTextToggled;

  const _TableSettingsMenu({
    required this.onClose,
    required this.onCustomizeColumns,
    required this.clipText,
    required this.onClipTextToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TableSettingsMenuItem(
            label: 'Customize Columns',
            icon: LucideIcons.settings,
            onTap: onCustomizeColumns,
          ),
          _TableSettingsMenuItem(
            label: clipText ? 'Wrap Text' : 'Clip Text',
            icon: clipText ? LucideIcons.wrapText : LucideIcons.list,
            onTap: onClipTextToggled,
          ),
        ],
      ),
    );
  }
}

class _TableSettingsMenuItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TableSettingsMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_TableSettingsMenuItem> createState() => _TableSettingsMenuItemState();
}

class _TableSettingsMenuItemState extends State<_TableSettingsMenuItem> {
  bool _isHovered = false;

  void _setHovered(bool v) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isHovered = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = _isHovered ? Colors.white : const Color(0xFF1F2937);
    final Color iconColor = _isHovered ? Colors.white : AppTheme.primaryBlue;
    final Color bg = _isHovered ? AppTheme.primaryBlue : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          color: bg,
          child: Row(
            children: [
              Icon(widget.icon, size: 15, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Selection Ribbon ─────────────────────────────────────────────────────────

class _SelectionRibbon extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback onDelete;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onBulkUpdate;

  const _SelectionRibbon({
    required this.selectedCount,
    required this.onClear,
    required this.onDelete,
    required this.onResume,
    required this.onStop,
    required this.onBulkUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      child: Row(
        children: [
          _RibbonButton(label: 'Bulk Update', onTap: onBulkUpdate),
          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: const Color(0xFFD1D5DB)),
          const SizedBox(width: 16),
          _RibbonButton(label: 'Resume', onTap: onResume),
          const SizedBox(width: 8),
          _RibbonButton(label: 'Stop', onTap: onStop),
          const SizedBox(width: 8),
          _RibbonButton(label: 'Delete', onTap: onDelete),
          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: const Color(0xFFD1D5DB)),
          const SizedBox(width: 16),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF295094),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(LucideIcons.x, color: Color(0xFFEF4444), size: 16),
          ),
        ],
      ),
    );
  }
}

class _RibbonButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RibbonButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1F2937),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: Colors.white,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _RibbonIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RibbonIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_RibbonIconButton> createState() => _RibbonIconButtonState();
}

class _RibbonIconButtonState extends State<_RibbonIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovered ? const Color(0xFFF3F4F6) : Colors.transparent,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(widget.icon, size: 15, color: const Color(0xFF4B5563)),
          ),
        ),
      ),
    );
  }
}

// ─── Table Options Menu (3-dots) ─────────────────────────────────────────────

class _TableOptionsMenu extends StatefulWidget {
  final String sortByField;
  final bool sortAscending;
  final void Function(String field, bool ascending) onSortChanged;
  final VoidCallback onRefresh;
  final VoidCallback onResetColumnWidths;
  final VoidCallback onCustomizeColumns;

  const _TableOptionsMenu({
    required this.sortByField,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onRefresh,
    required this.onResetColumnWidths,
    required this.onCustomizeColumns,
  });

  @override
  State<_TableOptionsMenu> createState() => _TableOptionsMenuState();
}

class _TableOptionsMenuState extends State<_TableOptionsMenu> {
  ButtonStyle _menuItemButtonStyle({bool isActive = false}) {
    return ButtonStyle(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive) return AppTheme.primaryBlue;
        if (states.contains(WidgetState.hovered)) return AppTheme.primaryBlue;
        return AppTheme.backgroundColor;
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
        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(180, 46)),
      alignment: Alignment.centerLeft,
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildSortSubmenuItem(String field) {
    final isSelected = widget.sortByField == field;
    return MenuItemButton(
      onPressed: () {
        if (isSelected) {
          widget.onSortChanged(field, !widget.sortAscending);
        } else {
          widget.onSortChanged(field, true);
        }
      },
      style: _menuItemButtonStyle(isActive: isSelected),
      trailingIcon: isSelected
          ? Icon(
              widget.sortAscending
                  ? LucideIcons.arrowUp
                  : LucideIcons.arrowDown,
              size: 14,
              color: Colors.white,
            )
          : null,
      child: Text(field, style: const TextStyle(fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-210, 8),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
        elevation: WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      builder: (context, controller, child) {
        return Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: IconButton(
            icon: const Icon(
              LucideIcons.moreHorizontal,
              size: 16,
              color: Color(0xFF4B5563),
            ),
            padding: EdgeInsets.zero,
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
        );
      },
      menuChildren: [
        SubmenuButton(
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.arrowUpDown, size: 16),
          submenuIcon: const WidgetStatePropertyAll(
            Icon(LucideIcons.chevronRight, size: 14),
          ),
          menuChildren: [
            _buildSortSubmenuItem('Customer Name'),
            _buildSortSubmenuItem('Billing Frequency'),
            _buildSortSubmenuItem('Amount'),
            _buildSortSubmenuItem('Status'),
          ],
          child: const Text('Sort by', style: TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          onPressed: () {
            ZerpaiToast.success(context, 'Import Recurring Invoices clicked');
          },
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.fileInput, size: 16),
          child: const Text(
            'Import Recurring Invoices',
            style: TextStyle(fontSize: 13),
          ),
        ),
        SubmenuButton(
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.fileOutput, size: 16),
          submenuIcon: const WidgetStatePropertyAll(
            Icon(LucideIcons.chevronRight, size: 14),
          ),
          menuChildren: [
            MenuItemButton(
              onPressed: () {
                ZerpaiToast.success(context, 'Export as PDF clicked');
              },
              style: _menuItemButtonStyle(),
              leadingIcon: const Icon(LucideIcons.fileDown, size: 16),
              child: const Text(
                'Export as PDF',
                style: TextStyle(fontSize: 13),
              ),
            ),
            MenuItemButton(
              onPressed: () {
                ZerpaiToast.success(context, 'Export as CSV clicked');
              },
              style: _menuItemButtonStyle(),
              leadingIcon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
              child: const Text(
                'Export as CSV',
                style: TextStyle(fontSize: 13),
              ),
            ),
            MenuItemButton(
              onPressed: () {
                ZerpaiToast.success(context, 'Export as Excel clicked');
              },
              style: _menuItemButtonStyle(),
              leadingIcon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
              child: const Text(
                'Export as Excel',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
          child: const Text('Export', style: TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          onPressed: () {
            ZerpaiToast.success(context, 'Preferences clicked');
          },
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.settings, size: 16),
          child: const Text('Preferences', style: TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          onPressed: widget.onCustomizeColumns,
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.sliders, size: 16),
          child: const Text(
            'Manage Custom Fields',
            style: TextStyle(fontSize: 13),
          ),
        ),
        MenuItemButton(
          onPressed: widget.onRefresh,
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.refreshCw, size: 16),
          child: const Text('Refresh List', style: TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          onPressed: widget.onResetColumnWidths,
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.refreshCw, size: 16),
          child: const Text(
            'Reset Column Width',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _BulkUpdateDialog extends StatefulWidget {
  final List<RecurringInvoice> selectedInvoices;
  const _BulkUpdateDialog({required this.selectedInvoices});

  @override
  State<_BulkUpdateDialog> createState() => _BulkUpdateDialogState();
}

class _BulkUpdateDialogState extends State<_BulkUpdateDialog> {
  String? _selectedField;
  String? _selectedRightDropdownValue;
  final _valueCtrl = TextEditingController();
  final List<String> _fields = [
    'Reference#',
    'Billing Address',
    'Shipping Address',
    'Billing and Shipping Address',
    'PDF Template',
    'Payment Terms',
    'Payment Gateways',
    'Sales person',
    'Customer Notes',
    'Terms & Conditions',
    'Preferences',
  ];

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAddress =
        _selectedField != null && _selectedField!.contains('Address');
    final isDropdownRight =
        _selectedField == 'PDF Template' ||
        _selectedField == 'Payment Terms' ||
        _selectedField == 'Payment Gateways' ||
        _selectedField == 'Preferences';

    final isMultiline =
        !isAddress &&
        !isDropdownRight &&
        (_selectedField == 'Customer Notes' ||
            _selectedField == 'Terms & Conditions');

    final firstCustomerName = widget.selectedInvoices.isNotEmpty
        ? widget.selectedInvoices.first.customerName
        : '--';

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: Colors.white,
      child: Container(
        width: 600,
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 24,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bulk Update Recurring Invoices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    LucideIcons.x,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 20),
            const Text(
              'Choose a field from the dropdown and update with new information.',
              style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: (isMultiline || isAddress)
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _CustomDropdown(
                    value: _selectedField,
                    hint: 'Select a field',
                    items: _fields,
                    width: 268,
                    onChanged: (val) {
                      setState(() {
                        _selectedField = val;
                        _valueCtrl.clear();
                        _selectedRightDropdownValue = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: isAddress
                      ? const SizedBox.shrink()
                      : (isDropdownRight
                            ? _CustomDropdown(
                                value: _selectedRightDropdownValue,
                                hint: _selectedField == 'PDF Template'
                                    ? 'Select a template'
                                    : (_selectedField == 'Payment Terms'
                                          ? 'Select payment terms'
                                          : 'Select an option'),
                                items: _selectedField == 'PDF Template'
                                    ? const [
                                        'Standard Template',
                                        'Spreadsheet Template',
                                      ]
                                    : (_selectedField == 'Payment Terms'
                                          ? const [
                                              'Due end of next month',
                                              'Due end of the month',
                                              'Due on Receipt',
                                              'Net 15',
                                              'Net 30',
                                              'Net 45',
                                              'Net 60',
                                            ]
                                          : (_selectedField == 'Preferences'
                                                ? const [
                                                    'Create Invoices as Drafts',
                                                    'Create and Send Invoices',
                                                    'Create, Charge and Send Invoices',
                                                  ]
                                                : const [
                                                    'Option 1',
                                                    'Option 2',
                                                  ])),
                                width: 268,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedRightDropdownValue = val;
                                    _valueCtrl.text = val;
                                  });
                                },
                              )
                            : Container(
                                height: isMultiline ? 80 : 38,
                                child: Stack(
                                  children: [
                                    TextField(
                                      controller: _valueCtrl,
                                      maxLines: isMultiline ? null : 1,
                                      expands: isMultiline,
                                      textAlignVertical: isMultiline
                                          ? TextAlignVertical.top
                                          : null,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFD1D5DB),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFD1D5DB),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF4D7EF2),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isMultiline)
                                      Positioned(
                                        right: 4,
                                        bottom: 4,
                                        child: IgnorePointer(
                                          child: CustomPaint(
                                            size: const Size(12, 12),
                                            painter: _ResizeHandlePainter(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              )),
                ),
              ],
            ),
            if (isAddress) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECURRING INVOICES ADDRESS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        text: 'Customer Name: ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                        ),
                        children: [
                          TextSpan(
                            text: '$firstCustomerName   ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: InkWell(
                              onTap: () {},
                              child: const Text(
                                'Choose existing address',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w500,
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
            ],
            const SizedBox(height: 20),
            const Text(
              'Note: All the selected recurring invoices will be updated with the new information and you cannot undo this action.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_selectedField != null &&
                        _valueCtrl.text.trim().isNotEmpty) {
                      Navigator.pop(context, {
                        'field': _selectedField,
                        'value': _valueCtrl.text.trim(),
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22A95E),
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
                  child: const Text(
                    'Update',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F2937),
                    backgroundColor: const Color(0xFFF3F4F6),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldDropdownOverlay extends StatefulWidget {
  final double width;
  final List<String> fields;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  const _FieldDropdownOverlay({
    required this.width,
    required this.fields,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  State<_FieldDropdownOverlay> createState() => _FieldDropdownOverlayState();
}

class _FieldDropdownOverlayState extends State<_FieldDropdownOverlay> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.fields
        .where((f) => f.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      width: widget.width,
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 36,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _query = val),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF4D7EF2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF4D7EF2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: Color(0xFF4D7EF2),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 6),
              itemCount: filtered.length,
              itemBuilder: (context, idx) {
                final field = filtered[idx];
                final isSelected = widget.selectedValue == field;
                return _FieldDropdownItem(
                  field: field,
                  isSelected: isSelected,
                  onTap: () => widget.onSelected(field),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldDropdownItem extends StatefulWidget {
  final String field;
  final bool isSelected;
  final VoidCallback onTap;

  const _FieldDropdownItem({
    required this.field,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FieldDropdownItem> createState() => _FieldDropdownItemState();
}

class _FieldDropdownItemState extends State<_FieldDropdownItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _isHovered;
    final bg = active ? const Color(0xFF4D7EF2) : Colors.transparent;
    final textColor = active ? Colors.white : const Color(0xFF374151);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.field,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomDropdown extends StatefulWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final double width;

  const _CustomDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.width,
  });

  @override
  State<_CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<_CustomDropdown> {
  LayerLink? __layerLink;
  LayerLink get _layerLink => __layerLink ??= LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              color: Colors.transparent,
              child: _FieldDropdownOverlay(
                width: widget.width,
                fields: widget.items,
                selectedValue: widget.value,
                onSelected: (val) {
                  widget.onChanged(val);
                  _closeDropdown();
                },
              ),
            ),
          ),
        ],
      ),
    );
    setState(() => _isOpen = true);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      if (mounted) setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isOpen
                  ? const Color(0xFF4D7EF2)
                  : const Color(0xFFD1D5DB),
              width: _isOpen ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.value ?? widget.hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.value == null
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                _isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 14,
                color: _isOpen
                    ? const Color(0xFF4D7EF2)
                    : const Color(0xFF4B5563),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResizeHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(size.width - 2, size.height - 10),
      Offset(size.width - 10, size.height - 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 2, size.height - 6),
      Offset(size.width - 6, size.height - 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
