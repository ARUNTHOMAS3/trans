// ignore_for_file: unused_element, unused_field, dead_code
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_row_actions.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/models/retainer_invoices_model.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/providers/retainer_invoices_provider.dart';

class ItemTradeSetupReportPage extends ConsumerStatefulWidget {
  const ItemTradeSetupReportPage({super.key});

  @override
  ConsumerState<ItemTradeSetupReportPage> createState() =>
      _ItemTradeSetupReportPageState();
}

class _ItemTradeSetupReportPageState
    extends ConsumerState<ItemTradeSetupReportPage> {
  late final ScrollController _rightController;
  final _searchCtrl = TextEditingController();

  OverlayEntry? _filterOverlayEntry;
  LayerLink? __filterLayerLink;
  LayerLink get _filterLayerLink => __filterLayerLink ??= LayerLink();
  bool _isFilterOpen = false;
  String _selectedFilterLabel = 'All';
  Set<String>? _favorites = <String>{};
  String? _activeDraggingKey;

  String _sortByField = 'Item Name';
  bool _sortAscending = true;

  // ── Row selection ──────────────────────────────────────────
  final Set<String> _selectedIds = {};
  bool get _hasSelection => _selectedIds.isNotEmpty;
  String? _hoveredRowId;

  // Settings overlay (same pattern as filter)
  OverlayEntry? _settingsOverlayEntry;
  LayerLink? __settingsLayerLink;
  LayerLink get _settingsLayerLink => __settingsLayerLink ??= LayerLink();
  bool _isSettingsOpen = false;
  bool _clipText = false;

  List<ColumnConfig> _columns = [
    ColumnConfig(
      id: 'ITEM NAME',
      label: 'Item Name',
      isLocked: true,
      orderIndex: 0,
    ),
  ];

  Map<String, double>? __columnWidths;
  Map<String, double> get _columnWidths => __columnWidths ??= {
    'ITEM NAME': 320.0,
  };

  @override
  void initState() {
    super.initState();
    _rightController = ScrollController();
  }

  @override
  void deactivate() {
    _closeFilterOverlay(updateState: false);
    _closeSettingsOverlay(updateState: false);
    super.deactivate();
  }

  @override
  void dispose() {
    _closeFilterOverlay(updateState: false);
    _closeSettingsOverlay(updateState: false);
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
                        .read(retainerInvoicesProvider.notifier)
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

  void _closeFilterOverlay({bool updateState = true}) {
    if (_filterOverlayEntry != null) {
      _filterOverlayEntry!.remove();
      _filterOverlayEntry = null;
      if (updateState && mounted) setState(() => _isFilterOpen = false);
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

  void _closeSettingsOverlay({bool updateState = true}) {
    if (_settingsOverlayEntry != null) {
      _settingsOverlayEntry!.remove();
      _settingsOverlayEntry = null;
      if (updateState && mounted) setState(() => _isSettingsOpen = false);
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

  String get _orgId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

  double _getColumnRightX(String targetKey) {
    double x = 0.0;
    final activeCols = _columns.where((c) => c.isVisible).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    for (final col in activeCols) {
      x += _columnWidths[col.id] ?? 120.0;
      if (col.id == targetKey) {
        break;
      }
    }
    return x;
  }

  @override
  Widget build(BuildContext context) {
    if ((_favorites as dynamic) == null) {
      _favorites = <String>{};
    }
    final state = ref.watch(retainerInvoicesProvider);
    final filtered = List<RetainerInvoice>.from(state.filteredInvoices);
    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortByField) {
        case 'Item Name':
          cmp = a.customerName.toLowerCase().compareTo(
            b.customerName.toLowerCase(),
          );
          break;
        default:
          cmp = a.customerName.toLowerCase().compareTo(
            b.customerName.toLowerCase(),
          );
      }
      return _sortAscending ? cmp : -cmp;
    });
    final allSelected =
        filtered.isNotEmpty && _selectedIds.length == filtered.length;

    final viewportWidth = MediaQuery.of(context).size.width;
    final contentWidth = (viewportWidth - 260).clamp(320.0, double.infinity);
    final itemNameWidth = (contentWidth - 84 - 60).clamp(
      320.0,
      double.infinity,
    );
    _columnWidths['ITEM NAME'] = itemNameWidth;
    final rightSideWidth = contentWidth;

    return ZerpaiLayout(
      pageTitle: '', // Hidden to use custom header inside body
      useTopPadding: false,
      useHorizontalPadding: false,
      enableBodyScroll: false,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Custom Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
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
                                ? 'All Item Trade Setups'
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
                      '/$_orgId${AppRoutes.itemMappingCreate}',
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
                          .read(retainerInvoicesProvider.notifier)
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

            // ── Bulk Selection Ribbon ─────────────────────────────────
            if (_hasSelection)
              _SelectionRibbon(
                selectedCount: _selectedIds.length,
                onClear: () => setState(() => _selectedIds.clear()),
                onDelete: () async {
                  final ok = await showZerpaiConfirmationDialog(
                    context,
                    title: 'Delete Selected',
                    message:
                        'Delete ${_selectedIds.length} selected invoice(s)? This cannot be undone.',
                    confirmLabel: 'Delete',
                    variant: ZerpaiConfirmationVariant.danger,
                  );
                  if (ok && mounted) {
                    for (final id in _selectedIds.toList()) {
                      ref
                          .read(retainerInvoicesProvider.notifier)
                          .deleteInvoice(id);
                    }
                    setState(() => _selectedIds.clear());
                    ZerpaiToast.deleted(context, 'Selected invoices');
                  }
                },
              ),

            // ── Unified Table Layout ──────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                      hasFilter:
                          state.activeFilter != null ||
                          state.searchQuery.isNotEmpty,
                      onNewTap: () => context.go(
                        '/$_orgId${AppRoutes.itemMappingCreate}',
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: rightSideWidth,
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                      SizedBox(
                                        width: 84,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            CompositedTransformTarget(
                                              link: _settingsLayerLink,
                                              child: InkWell(
                                                onTap: _toggleSettingsOverlay,
                                                hoverColor: Colors.transparent,
                                                splashColor:
                                                    Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                                            const SizedBox(width: 14),
                                            _buildSelectionCheckbox(
                                              value: _hasSelection,
                                              tristate: false,
                                              onChanged: (_) {
                                                setState(() {
                                                  if (allSelected) {
                                                    _selectedIds.clear();
                                                  } else {
                                                    _selectedIds
                                                      ..clear()
                                                      ..addAll(
                                                        filtered.map(
                                                          (e) => e.id,
                                                        ),
                                                      );
                                                  }
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 20),
                                          ],
                                        ),
                                      ),
                                      _thHeader(
                                        'ITEM NAME',
                                        'ITEM NAME',
                                      ),
                                      const SizedBox(
                                        width: 60,
                                      ), // Actions space
                                    ],
                                  ),
                                ),
                                // Rows
                                Expanded(
                                  child: ListView.separated(
                                    controller: _rightController,
                                    padding: EdgeInsets.zero,
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: Color(0xFFE5E7EB),
                                    ),
                                    itemBuilder: (_, idx) {
                                      final inv = filtered[idx];
                                      return MouseRegion(
                                        onEnter: (_) => setState(() {
                                          _hoveredRowId = inv.id;
                                        }),
                                        onExit: (_) => setState(() {
                                          if (_hoveredRowId == inv.id) {
                                            _hoveredRowId = null;
                                          }
                                        }),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            hoverColor: const Color(0xFFF3F4F6),
                                            onTap: () {
                                              final detailPath = AppRoutes
                                                  .itemMappingDetail
                                                  .replaceAll(':id', inv.id);
                                              context.go('/$_orgId$detailPath');
                                            },
                                            child: Container(
                                              height: 60,
                                              child: Row(
                                                children: [
                                                SizedBox(
                                                  width: 84,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .end,
                                                    children: [
                                                      _buildSelectionCheckbox(
                                                        value: _selectedIds
                                                            .contains(inv.id),
                                                        onChanged: (_) {
                                                          setState(() {
                                                            if (_selectedIds
                                                                .contains(
                                                              inv.id,
                                                            )) {
                                                              _selectedIds
                                                                  .remove(
                                                                inv.id,
                                                              );
                                                            } else {
                                                              _selectedIds.add(
                                                                inv.id,
                                                              );
                                                            }
                                                          });
                                                        },
                                                      ),
                                                      const SizedBox(width: 20),
                                                    ],
                                                  ),
                                                ),
                                                _tdCell(
                                                  Text(
                                                    inv.customerName,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF4B5563),
                                                    ),
                                                    maxLines:
                                                        _clipText ? 1 : null,
                                                    overflow: _clipText
                                                        ? TextOverflow.ellipsis
                                                        : TextOverflow.clip,
                                                  ),
                                                  'ITEM NAME',
                                                ),
                                                // Actions
                                                SizedBox(
                                                  width: 60,
                                                  child: Center(
                                                    child: ZRowActions(
                                                      key: ValueKey(
                                                        'actions_${inv.id}',
                                                      ),
                                                      onEdit: () {
                                                        final editPath = AppRoutes
                                                            .itemMappingEdit
                                                            .replaceAll(':id', inv.id);
                                                        context.go('/$_orgId$editPath');
                                                      },
                                                      onDelete: () async {
                                                        final ok = await showZerpaiConfirmationDialog(
                                                          context,
                                                          title:
                                                              'Delete Item Trade Setup',
                                                          message:
                                                              'Delete ${inv.invoiceNo}? This cannot be undone.',
                                                          confirmLabel: 'Delete',
                                                          variant:
                                                              ZerpaiConfirmationVariant
                                                                  .danger,
                                                        );
                                                        if (ok && mounted) {
                                                          ZerpaiToast.deleted(
                                                            context,
                                                            'Retainer invoice',
                                                          );
                                                          ref
                                                              .read(
                                                                retainerInvoicesProvider
                                                                    .notifier,
                                                              )
                                                              .deleteInvoice(
                                                                inv.id,
                                                              );
                                                        }
                                                      },
                                                      additionalActions: const [],
                                                    ),
                                                  ),
                                                ),
                                                ],
                                              ),
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
                    ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSelectionCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool tristate = false,
  }) {
    return SizedBox(
      height: 14,
      width: 14,
      child: Theme(
        data: Theme.of(context).copyWith(
          checkboxTheme: CheckboxThemeData(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(
              color: Color(0xFFC7CDD4),
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        child: Checkbox(
          value: value,
          tristate: tristate,
          activeColor: const Color(0xFF2563EB),
          checkColor: Colors.white,
          onChanged: onChanged,
        ),
      ),
    );
  }


  Widget _thHeader(String label, String key) {
    final width = _columnWidths[key] ?? 120.0;
    final isSortable = key == 'ITEM NAME';
    final isSorted = _sortByField == 'Item Name' && key == 'ITEM NAME';

    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: isSortable
                ? () {
                    setState(() {
                      if (_sortByField == 'Item Name') {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortByField = 'Item Name';
                        _sortAscending = true;
                      }
                    });
                  }
                : null,
            hoverColor: Colors.transparent,
            child: Container(
              width: width,
              padding: const EdgeInsets.only(left: 12, right: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5563),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSortable) ...[
                    const SizedBox(width: 4),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.chevronUp,
                          size: 8,
                          color: isSorted && _sortAscending
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF9CA3AF),
                        ),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 8,
                          color: isSorted && !_sortAscending
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            right: -12,
            top: 0,
            bottom: 0,
            child: _ColumnResizer(
              width: width,
              onDragStart: () => setState(() => _activeDraggingKey = key),
              onDragEnd: () => setState(() => _activeDraggingKey = null),
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
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
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

  // Defer setState to avoid mouse_tracker:199 assertion
  // (Flutter forbids tree mutations during pointer event dispatch).
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
                ? 'No invoices match your filters'
                : 'No Item Trade Setups yet',
            style: AppTheme.sectionHeader,
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Try clearing the active filter or search.'
                : 'Record advance payments collected from your customers.',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!hasFilter)
            ZButton.primary(
              label: 'New Item Trade Setup',
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
  final RetainerStatus? status;
  const _FilterOption(this.label, this.status);
}

class _FilterDropdownMenu extends StatefulWidget {
  final String selectedFilter;
  final Set<String>? favorites;
  final void Function(String label, RetainerStatus? status) onFilterSelected;
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
    _FilterOption('Draft', RetainerStatus.draft),
    _FilterOption('Sent', RetainerStatus.sent),
    _FilterOption('Paid', RetainerStatus.paid),
    _FilterOption('Partially Drawn', RetainerStatus.partiallyPaid),
    _FilterOption('Drawn', RetainerStatus.closed),
    _FilterOption('Void', RetainerStatus.voided),
    _FilterOption('Customer Viewed', RetainerStatus.sent),
    _FilterOption('Payment Initiated', RetainerStatus.sent),
    _FilterOption('Awaiting Payment', RetainerStatus.draft),
    _FilterOption('Ready To Draw', RetainerStatus.paid),
    _FilterOption('Pending Approval', RetainerStatus.draft),
    _FilterOption('Approved', RetainerStatus.paid),
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

class _NewCustomViewButton extends StatefulWidget {
  final VoidCallback onTap;

  const _NewCustomViewButton({required this.onTap});

  @override
  State<_NewCustomViewButton> createState() => _NewCustomViewButtonState();
}

class _NewCustomViewButtonState extends State<_NewCustomViewButton> {
  bool _isHovered = false;

  void _setHovered(bool v) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isHovered = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF1F2937);
    final Color bg = _isHovered ? const Color(0xFFF3F4F6) : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: bg,
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.add, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'New Custom View',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
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
            icon: LucideIcons.columns,
            onTap: onCustomizeColumns,
          ),
          _TableSettingsMenuItem(
            label: clipText ? 'Wrap Text' : 'Clip Text',
            icon: LucideIcons.alignLeft,
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

  const _SelectionRibbon({
    required this.selectedCount,
    required this.onClear,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),

          // Export as PDF icon
          _RibbonIconButton(
            icon: LucideIcons.fileDown,
            tooltip: 'Export as PDF',
            onTap: () {},
          ),

          const SizedBox(width: 4),

          // Print icon
          _RibbonIconButton(
            icon: LucideIcons.printer,
            tooltip: 'Print',
            onTap: () {},
          ),

          // Vertical divider
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFFE5E7EB),
          ),

          // Delete text button
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Count badge
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 6),

          const Text(
            'Selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),

          const Spacer(),

          // Esc + red X
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Esc',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.x, size: 14, color: Color(0xFFEF4444)),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
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
        if (states.contains(WidgetState.hovered)) return AppTheme.primaryBlue;
        return AppTheme.backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return Colors.white;
        if (isActive) return AppTheme.primaryBlue;
        return AppTheme.textPrimary;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return Colors.white;
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
          final bool defaultAsc =
              field != 'Created Time' &&
              field != 'Last Modified Time' &&
              field != 'Date' &&
              field != 'Issued Date';
          widget.onSortChanged(field, defaultAsc);
        }
      },
      style: _menuItemButtonStyle(isActive: isSelected),
      trailingIcon: isSelected
          ? Icon(
              widget.sortAscending
                  ? LucideIcons.arrowUp
                  : LucideIcons.arrowDown,
              size: 14,
            )
          : null,
      child: Text(field, style: const TextStyle(fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-160, 8),
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
            _buildSortSubmenuItem('Item Name'),
          ],
          child: const Text('Sort by', style: TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          onPressed: () {
            ZerpaiToast.success(context, 'Import Item Trade Setups clicked');
          },
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.fileInput, size: 16),
          child: const Text(
            'Import Item Trade Setups',
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

