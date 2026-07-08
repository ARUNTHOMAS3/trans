import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_row_actions.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_date_picker_field.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/dialogs/associate_templates_dialog.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';

class VendorsReportPage extends ConsumerStatefulWidget {
  const VendorsReportPage({super.key});

  @override
  ConsumerState<VendorsReportPage> createState() => _VendorsReportPageState();
}

class _VendorsReportPageState extends ConsumerState<VendorsReportPage> {
  late final ScrollController _rightController;
  late final ScrollController _horizontalController;
  final _searchCtrl = TextEditingController();

  OverlayEntry? _filterOverlayEntry;
  LayerLink? __filterLayerLink;
  LayerLink get _filterLayerLink => __filterLayerLink ??= LayerLink();
  bool _isFilterOpen = false;
  String _selectedFilterLabel = 'All';
  Set<String>? _favorites = <String>{};
  // ignore: unused_field
  String? _activeDraggingKey;

  String _sortByField = 'Name';
  bool _sortAscending = true;
  bool? _activeFilter;

  // ── Row selection ──────────────────────────────────────────
  final Set<String> _selectedIds = {};
  final Set<String> _inactiveIds = {};
  Timer? _inactiveBannerTimer;
  bool _showInactiveBanner = false;
  Timer? _activeBannerTimer;
  bool _showActiveBanner = false;
  bool get _hasSelection => _selectedIds.isNotEmpty;

  // Settings overlay (same pattern as filter)
  OverlayEntry? _settingsOverlayEntry;
  LayerLink? __settingsLayerLink;
  LayerLink get _settingsLayerLink => __settingsLayerLink ??= LayerLink();
  bool _isSettingsOpen = false;
  bool _clipText = false;

  Widget _buildTableCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return SizedBox(
      height: 14,
      width: 14,
      child: Theme(
        data: Theme.of(context).copyWith(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          checkboxTheme: CheckboxThemeData(
            side: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF2563EB);
              }
              return Colors.white;
            }),
            checkColor: const WidgetStatePropertyAll(Colors.white),
          ),
        ),
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2563EB),
        ),
      ),
    );
  }

  List<ColumnConfig> _columns = [
    ColumnConfig(id: 'NAME', label: 'Name', isLocked: true, orderIndex: 0),
    ColumnConfig(
      id: 'VENDOR NUMBER',
      label: 'Vendor Number',
      isLocked: true,
      orderIndex: 1,
    ),
    ColumnConfig(
      id: 'COMPANY NAME',
      label: 'Company Name',
      isLocked: true,
      orderIndex: 2,
    ),
    ColumnConfig(id: 'EMAIL', label: 'Email', orderIndex: 3),
    ColumnConfig(id: 'PHONE', label: 'Phone', orderIndex: 4),
    ColumnConfig(id: 'GST TREATMENT', label: 'GST Treatment', orderIndex: 5),
    ColumnConfig(id: 'PAYABLES', label: 'Payables', orderIndex: 6),
    ColumnConfig(id: 'PAYABLES (BCY)', label: 'Payables (BCY)', orderIndex: 7),
    ColumnConfig(
      id: 'UNUSED CREDITS (BCY)',
      label: 'Unused Credits (BCY)',
      orderIndex: 8,
    ),
    ColumnConfig(id: 'SOURCE', label: 'Source', orderIndex: 9),
    ColumnConfig(
      id: 'SOURCE OF SUPPLY',
      label: 'Source Of Supply',
      isVisible: false,
      orderIndex: 10,
    ),
    ColumnConfig(
      id: 'UNUSED CREDITS',
      label: 'Unused Credits',
      isVisible: false,
      orderIndex: 11,
    ),
    ColumnConfig(id: 'ADGF', label: 'ADGF', isVisible: false, orderIndex: 12),
    ColumnConfig(
      id: 'FIRST NAME',
      label: 'First Name',
      isVisible: false,
      orderIndex: 13,
    ),
    ColumnConfig(
      id: 'GST REGISTRATION NUMBER',
      label: 'GST Registration Number',
      isVisible: false,
      orderIndex: 14,
    ),
    ColumnConfig(
      id: 'LAST NAME',
      label: 'Last Name',
      isVisible: false,
      orderIndex: 15,
    ),
    ColumnConfig(
      id: 'MOBILE PHONE',
      label: 'Mobile Phone',
      isVisible: false,
      orderIndex: 16,
    ),
    ColumnConfig(
      id: 'PAYMENT TERMS',
      label: 'Payment Terms',
      isVisible: false,
      orderIndex: 17,
    ),
    ColumnConfig(
      id: 'STATUS',
      label: 'Status',
      isVisible: false,
      orderIndex: 18,
    ),
    ColumnConfig(
      id: 'WEBSITE',
      label: 'Website',
      isVisible: false,
      orderIndex: 19,
    ),
    ColumnConfig(
      id: 'DEMO ADVACED REPORTING TAG',
      label: 'demo advaced reporting tag',
      isVisible: false,
      orderIndex: 20,
    ),
    ColumnConfig(
      id: 'SCHEDULE',
      label: 'shedule',
      isVisible: false,
      orderIndex: 21,
    ),
  ];

  Map<String, double>? __columnWidths;
  Map<String, double> get _columnWidths => __columnWidths ??= {
    'NAME': 220.0,
    'VENDOR NUMBER': 180.0,
    'COMPANY NAME': 260.0,
    'EMAIL': 260.0,
    'PHONE': 170.0,
    'GST TREATMENT': 220.0,
    'PAYABLES': 150.0,
    'PAYABLES (BCY)': 160.0,
    'UNUSED CREDITS (BCY)': 190.0,
    'SOURCE': 160.0,
    'SOURCE OF SUPPLY': 180.0,
    'UNUSED CREDITS': 160.0,
    'ADGF': 130.0,
    'FIRST NAME': 150.0,
    'GST REGISTRATION NUMBER': 220.0,
    'LAST NAME': 150.0,
    'MOBILE PHONE': 180.0,
    'PAYMENT TERMS': 170.0,
    'STATUS': 140.0,
    'WEBSITE': 220.0,
    'DEMO ADVACED REPORTING TAG': 230.0,
    'SCHEDULE': 140.0,
  };

  @override
  void initState() {
    super.initState();
    _rightController = ScrollController();
    _horizontalController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vendorProvider.notifier).loadVendors();
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
    _inactiveBannerTimer?.cancel();
    _activeBannerTimer?.cancel();
    _rightController.dispose();
    _horizontalController.dispose();
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
                  onFilterSelected: (label, isActiveFilter) {
                    setState(() {
                      _selectedFilterLabel = label;
                      _activeFilter = isActiveFilter;
                    });
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

  void _showInactiveSuccessBanner() {
    _inactiveBannerTimer?.cancel();
    setState(() => _showInactiveBanner = true);
    _inactiveBannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showInactiveBanner = false);
      }
    });
  }

  void _showActiveSuccessBanner() {
    _activeBannerTimer?.cancel();
    setState(() => _showActiveBanner = true);
    _activeBannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showActiveBanner = false);
      }
    });
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

  Future<void> _showAssociateTemplatesDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const AssociateTemplatesDialog(),
    );
  }

  Future<void> _showMergeVendorsDialog(List<Vendor> vendors) async {
    final selectedVendors = vendors
        .where((v) => _selectedIds.contains(v.id))
        .toList();
    final selectedVendorName = selectedVendors.isNotEmpty
        ? selectedVendors.first.displayName
        : 'this vendor';
    final mergeCandidates =
        vendors
            .where((v) => !_selectedIds.contains(v.id))
            .map((v) => v.displayName)
            .toSet()
            .toList()
          ..sort();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _MergeVendorsDialog(
        selectedVendorName: selectedVendorName,
        vendorOptions: mergeCandidates,
      ),
    );
  }

  String get _orgId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

  // ignore: unused_element
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
    final tableCellStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      fontFamily: 'Inter',
      fontFamilyFallback: [
        'Source Sans Pro',
        'Helvetica',
        'Arial',
        'sans-serif',
      ],
    );
    final state = ref.watch(vendorProvider);
    final filtered = state.vendors.where((v) {
      if (_activeFilter == true) return v.isActive;
      if (_activeFilter == false) return !v.isActive;
      return true;
    }).where((v) {
      final q = _searchCtrl.text.toLowerCase().trim();
      if (q.isEmpty) return true;
      return v.displayName.toLowerCase().contains(q) ||
          (v.vendorNumber?.toLowerCase().contains(q) ?? false) ||
          (v.companyName?.toLowerCase().contains(q) ?? false) ||
          (v.email?.toLowerCase().contains(q) ?? false) ||
          (v.phone?.toLowerCase().contains(q) ?? false);
    }).toList();
    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortByField) {
        case 'Vendor Number':
          cmp = (a.vendorNumber ?? '').compareTo(b.vendorNumber ?? '');
          break;
        case 'Company Name':
          cmp = (a.companyName ?? '').toLowerCase().compareTo(
            (b.companyName ?? '').toLowerCase(),
          );
          break;
        case 'Email':
          cmp = (a.email ?? '').toLowerCase().compareTo(
            (b.email ?? '').toLowerCase(),
          );
          break;
        case 'Phone':
        case 'Mobile Phone':
          cmp = (a.phone ?? '').compareTo(b.phone ?? '');
          break;
        case 'Payables':
        case 'Payables (BCY)':
        case 'Unused Credits':
        case 'Unused Credits (BCY)':
          cmp = 0;
          break;
        case 'Status':
          cmp = a.isActive.toString().compareTo(b.isActive.toString());
          break;
        case 'Source':
        case 'Source Of Supply':
        case 'GST Treatment':
        case 'GST Registration Number':
        case 'Payment Terms':
        case 'Website':
        case 'demo advaced reporting tag':
        case 'shedule':
        case 'ADGF':
        case 'First Name':
        case 'Last Name':
          cmp = 0;
          break;
        case 'Name':
        default:
          cmp = a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          );
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
        56.0 +
        60.0;

    return ZerpaiLayout(
      pageTitle: '', // Hidden to use custom header inside body
      useTopPadding: false,
      useHorizontalPadding: false,
      enableBodyScroll: false,
      child: Stack(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Custom Header ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
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
                                    ? 'All Vendors'
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
                        onPressed: () =>
                            context.go('/$_orgId${AppRoutes.vendorsCreate}'),
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
                          ref.read(vendorProvider.notifier).loadVendors();
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
                            'Delete ${_selectedIds.length} selected vendor(s)? This cannot be undone.',
                        confirmLabel: 'Delete',
                        variant: ZerpaiConfirmationVariant.danger,
                      );
                      if (ok && mounted) {
                        for (final id in _selectedIds.toList()) {
                          ref.read(vendorProvider.notifier).deleteVendor(id);
                        }
                        setState(() => _selectedIds.clear());
                        ZerpaiToast.deleted(context, 'Selected vendors');
                      }
                    },
                    onMarkActive: () {
                      setState(() {
                        _inactiveIds.removeAll(_selectedIds);
                      });
                      _showActiveSuccessBanner();
                    },
                    onMarkInactive: () {
                      setState(() {
                        _inactiveIds.addAll(_selectedIds);
                      });
                      _showInactiveSuccessBanner();
                    },
                    onMerge: () => _showMergeVendorsDialog(filtered),
                    onAssociateTemplates: _showAssociateTemplatesDialog,
                  ),

                // ── Unified Table Layout ──────────────────────────────────
                Expanded(
                  child: state.isLoading
                      ? const TableSkeleton(rows: 12, columns: 6)
                      : filtered.isEmpty
                          ? _EmptyState(
                              hasFilter:
                                  _activeFilter != null ||
                                  _searchCtrl.text.isNotEmpty,
                              onNewTap: () =>
                                  context.go('/$_orgId${AppRoutes.vendorsCreate}'),
                            )
                          : Stack(
                          children: [
                            Theme(
                              data: Theme.of(context).copyWith(
                                scrollbarTheme: Theme.of(context).scrollbarTheme.copyWith(
                                  mainAxisMargin: 20.0,
                                ),
                              ),
                              child: Scrollbar(
                                controller: _horizontalController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _horizontalController,
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: rightSideWidth,
                                    child: Stack(
                                      children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Header Row
                                    Container(
                                      height: 42,
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
                                            width: 28,
                                            child: Center(
                                              child: CompositedTransformTarget(
                                                link: _settingsLayerLink,
                                                child: InkWell(
                                                  onTap: _toggleSettingsOverlay,
                                                  hoverColor:
                                                      Colors.transparent,
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
                                                      size: 16,
                                                      color: Color(0xFF2563EB),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 28,
                                            child: Center(
                                              child: _buildTableCheckbox(
                                                value:
                                                    filtered.isNotEmpty &&
                                                    _selectedIds.length ==
                                                        filtered.length,
                                                onChanged: (_) {
                                                  setState(() {
                                                    if (filtered.isNotEmpty &&
                                                        _selectedIds.length ==
                                                            filtered.length) {
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
                                            ),
                                          ),
                                          ...activeCols.map((col) {
                                            return _thHeader(
                                              col.label.toUpperCase(),
                                              col.id,
                                            );
                                          }),
                                          const SizedBox(
                                            width: 60,
                                          ), // Actions space
                                        ],
                                      ),
                                    ),
                                    // Rows
                                    Expanded(
                                      child: Scrollbar(
                                        controller: _rightController,
                                        thumbVisibility: true,
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
                                          final vendor = filtered[idx];
                                          final isVendorInactive = !vendor.isActive || _inactiveIds.contains(vendor.id);
                                          const inactiveTextColor = Color(
                                            0xFF6C718A,
                                          );

                                          return Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              hoverColor: const Color(0xFFF3F4F6),
                                              onTap: () {
                                                context.go('/$_orgId/purchases/vendors/${vendor.id}');
                                              },
                                              child: Container(
                                                height: 60,
                                                color: Colors.transparent,
                                                child: Row(
                                                  children: [
                                                    const SizedBox(width: 28),
                                                    SizedBox(
                                                      width: 28,
                                                      child: Center(
                                                        child: _buildTableCheckbox(
                                                          value: _selectedIds
                                                              .contains(vendor.id),
                                                          onChanged: (_) {
                                                            setState(() {
                                                              if (_selectedIds
                                                                  .contains(vendor.id)) {
                                                                _selectedIds.remove(vendor.id);
                                                              } else {
                                                                _selectedIds.add(vendor.id);
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    ...activeCols.map((col) {
                                                      switch (col.id) {
                                                        case 'NAME':
                                                          return _tdCell(
                                                            Text(
                                                              vendor.displayName,
                                                              style: tableCellStyle.copyWith(
                                                                color: isVendorInactive
                                                                    ? inactiveTextColor
                                                                    : const Color(0xFF0F52BA),
                                                              ),
                                                              maxLines: _clipText ? 1 : null,
                                                              overflow: _clipText ? TextOverflow.ellipsis : TextOverflow.clip,
                                                            ),
                                                            'NAME',
                                                          );
                                                        case 'VENDOR NUMBER':
                                                          return _tdCell(
                                                            Text(
                                                              vendor.vendorNumber ?? '--',
                                                              style: tableCellStyle.copyWith(
                                                                color: isVendorInactive
                                                                    ? inactiveTextColor
                                                                    : const Color(0xFF1F2937),
                                                              ),
                                                              maxLines: _clipText ? 1 : null,
                                                              overflow: _clipText ? TextOverflow.ellipsis : TextOverflow.clip,
                                                            ),
                                                            'VENDOR NUMBER',
                                                          );
                                                        case 'COMPANY NAME':
                                                          return _tdCell(
                                                            Text(
                                                              vendor.companyName ?? '--',
                                                              style: tableCellStyle.copyWith(
                                                                color: isVendorInactive
                                                                    ? inactiveTextColor
                                                                    : const Color(0xFF4B5563),
                                                              ),
                                                              maxLines: _clipText ? 1 : null,
                                                              overflow: _clipText ? TextOverflow.ellipsis : TextOverflow.clip,
                                                            ),
                                                            'COMPANY NAME',
                                                          );
                                                        case 'EMAIL':
                                                          return _tdCell(
                                                            Text(
                                                              vendor.email ?? '--',
                                                              style: tableCellStyle.copyWith(
                                                                color: isVendorInactive
                                                                    ? inactiveTextColor
                                                                    : const Color(0xFF4B5563),
                                                              ),
                                                              maxLines: _clipText ? 1 : null,
                                                              overflow: _clipText ? TextOverflow.ellipsis : TextOverflow.clip,
                                                            ),
                                                            'EMAIL',
                                                          );
                                                        case 'PHONE':
                                                          return _tdCell(
                                                            Text(
                                                              vendor.phone ?? '--',
                                                              style: tableCellStyle.copyWith(
                                                                color: isVendorInactive
                                                                    ? inactiveTextColor
                                                                    : const Color(0xFF9CA3AF),
                                                              ),
                                                            ),
                                                            'PHONE',
                                                          );
                                                        case 'GST TREATMENT':
                                                          return _tdCell(
                                                            Text(
                                                              vendor.gstTreatment ?? '--',
                                                              style: tableCellStyle.copyWith(
                                                                color: isVendorInactive
                                                                    ? inactiveTextColor
                                                                    : const Color(0xFF1F2937),
                                                              ),
                                                              maxLines: _clipText ? 1 : null,
                                                              overflow: _clipText ? TextOverflow.ellipsis : TextOverflow.clip,
                                                            ),
                                                            'GST TREATMENT',
                                                          );
                                                        case 'PAYABLES':
                                                        case 'PAYABLES (BCY)':
                                                        case 'UNUSED CREDITS':
                                                        case 'UNUSED CREDITS (BCY)':
                                                          return _tdCell(
                                                            Text(
                                                              '--',
                                                              style: tableCellStyle.copyWith(
                                                                color: isVendorInactive
                                                                    ? inactiveTextColor
                                                                    : const Color(0xFF1F2937),
                                                              ),
                                                            ),
                                                            col.id,
                                                          );
                                                        case 'STATUS':
                                                          return _tdCell(
                                                            Text(
                                                              vendor.isActive ? 'ACTIVE' : 'INACTIVE',
                                                              style: tableCellStyle.copyWith(
                                                                color: isVendorInactive
                                                                    ? inactiveTextColor
                                                                    : const Color(0xFF1F2937),
                                                              ),
                                                              maxLines: _clipText ? 1 : null,
                                                              overflow: _clipText ? TextOverflow.ellipsis : TextOverflow.clip,
                                                            ),
                                                            'STATUS',
                                                          );
                                                        default:
                                                          return _tdCell(
                                                            Text(
                                                              '--',
                                                              style: tableCellStyle.copyWith(
                                                                color: const Color(0xFF9CA3AF),
                                                              ),
                                                            ),
                                                            col.id,
                                                          );
                                                      }
                                                    }),
                                                    // Actions
                                                    SizedBox(
                                                      width: 60,
                                                      child: Center(
                                                        child: ZRowActions(
                                                          onEdit: () {
                                                            context.go('/$_orgId/purchases/vendors/${vendor.id}');
                                                          },
                                                          onDelete: () async {
                                                            final ok = await showZerpaiConfirmationDialog(
                                                              context,
                                                              title: 'Delete Vendor',
                                                              message: 'Delete ${vendor.displayName}? This cannot be undone.',
                                                              confirmLabel: 'Delete',
                                                              variant: ZerpaiConfirmationVariant.danger,
                                                            );
                                                            if (ok && mounted) {
                                                              ref.read(vendorProvider.notifier).deleteVendor(vendor.id);
                                                              ZerpaiToast.deleted(context, 'Vendor');
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
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Left scroll arrow button
                    Positioned(
                      left: 0,
                      bottom: 0,
                      height: 12,
                      width: 20,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            if (_horizontalController.hasClients) {
                              final current = _horizontalController.offset;
                              final target = (current - 100).clamp(
                                0.0,
                                _horizontalController.position.maxScrollExtent,
                              );
                              _horizontalController.animateTo(
                                target,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: const Icon(
                            Icons.arrow_left,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                    // Right scroll arrow button
                    Positioned(
                      right: 0,
                      bottom: 0,
                      height: 12,
                      width: 20,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            if (_horizontalController.hasClients) {
                              final current = _horizontalController.offset;
                              final target = (current + 100).clamp(
                                0.0,
                                _horizontalController.position.maxScrollExtent,
                              );
                              _horizontalController.animateTo(
                                target,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: const Icon(
                            Icons.arrow_right,
                            size: 14,
                            color: Color(0xFF9CA3AF),
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
          if (_showInactiveBanner)
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: -56, end: 0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7EF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22A95E),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'The selected contacts have been marked as inactive.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_showActiveBanner)
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: -56, end: 0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7EF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22A95E),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'The selected contacts have been marked as active.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _thHeader(String label, String key) {
    final width = _columnWidths[key] ?? 120.0;
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: key == 'NAME'
                ? () {
                    setState(() {
                      if (_sortByField == 'Name') {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortByField = 'Name';
                        _sortAscending = true;
                      }
                    });
                  }
                : null,
            child: Container(
              width: width,
              padding: const EdgeInsets.only(left: 12, right: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
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
                        if (key == 'NAME') ...[
                          const SizedBox(width: 4),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.translate(
                                offset: const Offset(0, 2),
                                child: Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 10,
                                  color: (_sortByField == 'Name' && _sortAscending)
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -2),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 10,
                                  color: (_sortByField != 'Name' || !_sortAscending)
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
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
          const SizedBox(height: 24),
          Text(
            hasFilter ? 'No vendors match your filters' : 'No Vendors yet',
            style: AppTheme.sectionHeader,
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Try clearing the active filter or search.'
                : 'Track and manage your vendor master records here.',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!hasFilter)
            ZButton.primary(
              label: 'New Vendor',
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
  final bool? isActiveFilter;
  const _FilterOption(this.label, this.isActiveFilter);
}

class _FilterDropdownMenu extends StatefulWidget {
  final String selectedFilter;
  final Set<String>? favorites;
  final void Function(String label, bool? isActiveFilter) onFilterSelected;
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
  bool _favoritesExpanded = true;
  bool _defaultFiltersExpanded = true;

  static const _allOptions = [
    _FilterOption('All Vendors', null),
    _FilterOption('Active Vendors', true),
    _FilterOption('Inactive Vendors', false),
    _FilterOption('Vendors - Reorder Items', null),
    _FilterOption('CRM Vendors', null),
    _FilterOption('Duplicate Vendors', null),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
    final filteredOptions = _allOptions;
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
                              widget.onFilterSelected(opt.label, opt.isActiveFilter),
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
                              widget.onFilterSelected(opt.label, opt.isActiveFilter),
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
                            widget.onFilterSelected(opt.label, opt.isActiveFilter),
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

// ignore: unused_element
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
  final VoidCallback onMarkActive;
  final VoidCallback onMarkInactive;
  final VoidCallback onMerge;
  final VoidCallback onAssociateTemplates;

  const _SelectionRibbon({
    required this.selectedCount,
    required this.onClear,
    required this.onDelete,
    required this.onMarkActive,
    required this.onMarkInactive,
    required this.onMerge,
    required this.onAssociateTemplates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          _RibbonActionButton(
            label: 'Bulk Update',
            onTap: () {
              showDialog(
                context: context,
                barrierColor: Colors.black54,
                builder: (_) => const _BulkUpdateVendorsDialog(),
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MergedRibbonIconButton(
                  icon: LucideIcons.mail,
                  tooltip: 'Send Vendor Statements',
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black54,
                      builder: (_) => const _EmailVendorStatementsDialog(),
                    );
                  },
                  isLeft: true,
                ),
                Container(
                  width: 1,
                  height: double.infinity,
                  color: const Color(0xFFE5E7EB),
                ),
                _MergedRibbonIconButton(
                  icon: LucideIcons.printer,
                  tooltip: 'Print Vendor Statements',
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black54,
                      builder: (_) => const _PrintVendorStatementsDialog(),
                    );
                  },
                  isRight: true,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: const Color(0xFFE5E7EB),
          ),
          _RibbonActionButton(label: 'Mark as Active', onTap: onMarkActive),
          const SizedBox(width: 8),
          _RibbonActionButton(label: 'Mark as Inactive', onTap: onMarkInactive),
          const SizedBox(width: 8),
          _RibbonActionButton(label: 'Merge', onTap: onMerge),
          const SizedBox(width: 8),
          _RibbonActionButton(
            label: 'Associate Templates',
            onTap: onAssociateTemplates,
          ),
          const SizedBox(width: 8),
          const _SelectionMoreMenu(),
          const SizedBox(width: 18),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          const Spacer(),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.x, size: 14, color: Color(0xFFEF4444)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _RibbonActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RibbonActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }
}

class _MergeVendorsDialog extends StatefulWidget {
  final String selectedVendorName;
  final List<String> vendorOptions;

  const _MergeVendorsDialog({
    required this.selectedVendorName,
    required this.vendorOptions,
  });

  @override
  State<_MergeVendorsDialog> createState() => _MergeVendorsDialogState();
}

class _MergeVendorsDialogState extends State<_MergeVendorsDialog> {
  String? _selectedMergeVendor;

  @override
  void initState() {
    super.initState();
    if (widget.vendorOptions.isNotEmpty) {
      _selectedMergeVendor = widget.vendorOptions.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Material(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 24,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 790,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: const Color(0xFFF9F9FB),
                  padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Merge Vendors',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Color(0xFF3F3F46),
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  "Select a vendor profile with whom you'd like to merge ",
                            ),
                            TextSpan(
                              text: widget.selectedVendorName.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF27272A),
                              ),
                            ),
                            const TextSpan(
                              text: '. Once merged, the transactions of ',
                            ),
                            TextSpan(
                              text: widget.selectedVendorName.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF27272A),
                              ),
                            ),
                            const TextSpan(
                              text:
                                  ' will be transferred, and this vendor record will be marked as inactive.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      FormDropdown<String>(
                        value: _selectedMergeVendor,
                        items: widget.vendorOptions,
                        onChanged: (value) {
                          setState(() => _selectedMergeVendor = value);
                        },
                        displayStringForValue: (value) => value,
                        hint: 'Select Vendor',
                        showSearch: false,
                        menuWidth: 742,
                        height: 38,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
                  child: Row(
                    children: [
                      ZButton.primary(
                        label: 'Continue',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      ZButton.secondary(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
    return ZTooltip(
      message: widget.tooltip,
      direction: ZTooltipDirection.bottom,
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
              color: _hovered
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFFF5F5F5),
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

class _MergedRibbonIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isLeft;
  final bool isRight;

  const _MergedRibbonIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isLeft = false,
    this.isRight = false,
  });

  @override
  State<_MergedRibbonIconButton> createState() =>
      _MergedRibbonIconButtonState();
}

class _MergedRibbonIconButtonState extends State<_MergedRibbonIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: widget.isLeft ? const Radius.circular(5) : Radius.zero,
      bottomLeft: widget.isLeft ? const Radius.circular(5) : Radius.zero,
      topRight: widget.isRight ? const Radius.circular(5) : Radius.zero,
      bottomRight: widget.isRight ? const Radius.circular(5) : Radius.zero,
    );

    return ZTooltip(
      message: widget.tooltip,
      direction: ZTooltipDirection.bottom,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: borderRadius,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovered ? const Color(0xFFF3F4F6) : Colors.transparent,
              borderRadius: borderRadius,
            ),
            child: Icon(widget.icon, size: 15, color: const Color(0xFF4B5563)),
          ),
        ),
      ),
    );
  }
}

class _SelectionMoreMenu extends StatelessWidget {
  const _SelectionMoreMenu();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
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
        return _RibbonIconButton(
          icon: LucideIcons.moreHorizontal,
          tooltip: 'More',
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
        );
      },
      menuChildren: [
        _SelectionMoreMenuItem(
          label: 'Enable Portal',
          isActive: true,
          onTap: () {},
        ),
        _SelectionMoreMenuItem(label: 'Disable Portal', onTap: () {}),
        _SelectionMoreMenuItem(label: 'Request GST Information', onTap: () {}),
        _SelectionMoreMenuItem(label: 'Delete', onTap: () {}),
      ],
    );
  }
}

class _SelectionMoreMenuItem extends StatefulWidget {
  final bool isActive;
  final String label;
  final VoidCallback onTap;

  const _SelectionMoreMenuItem({
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_SelectionMoreMenuItem> createState() => _SelectionMoreMenuItemState();
}

class _SelectionMoreMenuItemState extends State<_SelectionMoreMenuItem> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isHovered = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _isHovered;
    final isSelected = widget.isActive && !_isHovered;
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          width: 200,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppTheme.primaryBlue
                : (isSelected ? const Color(0xFFF3F4F6) : Colors.white),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              color: isHighlighted ? Colors.white : const Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
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
        if (states.contains(WidgetState.hovered)) return const Color(0xFF2563EB);
        if (isActive) return const Color(0xFFE5E7EB);
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return Colors.white;
        if (isActive) return const Color(0xFF1F2937);
        return AppTheme.textPrimary;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return Colors.white;
        if (isActive) return const Color(0xFF2563EB);
        return const Color(0xFF6B7280);
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
              field != 'Payables' &&
              field != 'Payables (BCY)' &&
              field != 'Unused Credits' &&
              field != 'Unused Credits (BCY)';
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
            _buildSortSubmenuItem('Name'),
            _buildSortSubmenuItem('Vendor Number'),
            _buildSortSubmenuItem('Company Name'),
            _buildSortSubmenuItem('Email'),
            _buildSortSubmenuItem('Phone'),
            _buildSortSubmenuItem('GST Treatment'),
            _buildSortSubmenuItem('Payables'),
            _buildSortSubmenuItem('Payables (BCY)'),
            _buildSortSubmenuItem('Unused Credits'),
            _buildSortSubmenuItem('Unused Credits (BCY)'),
            _buildSortSubmenuItem('Status'),
          ],
          child: const Text('Sort by', style: TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          onPressed: () {
            ZerpaiToast.success(context, 'Import Vendors clicked');
          },
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.fileInput, size: 16),
          child: const Text('Import Vendors', style: TextStyle(fontSize: 13)),
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
          leadingIcon: const Icon(
            LucideIcons.settings,
            size: 16,
            color: Color(0xFF20263A),
          ),
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

class _PrintVendorStatementsDialog extends StatefulWidget {
  const _PrintVendorStatementsDialog();

  @override
  State<_PrintVendorStatementsDialog> createState() =>
      _PrintVendorStatementsDialogState();
}

class _PrintVendorStatementsDialogState
    extends State<_PrintVendorStatementsDialog> {
  DateTime _startDate = DateTime(2026, 6, 1);
  DateTime _endDate = DateTime(2026, 6, 30);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Material(
          color: Colors.white,
          elevation: 24,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 500,
            height: 366,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Print Vendor statements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                // Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "You can print your vendor's statements for the selected date range.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Start Date',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ZDatePickerField(
                        selectedDate: _startDate,
                        onDateSelected: (date) {
                          setState(() {
                            _startDate = date;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'End Date',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ZDatePickerField(
                        selectedDate: _endDate,
                        onDateSelected: (date) {
                          setState(() {
                            _endDate = date;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                // Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ZerpaiToast.success(
                            context,
                            'Vendor statements sent to print queue',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22B378),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Print Statements',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: const Color(0xFF1F2937),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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
    );
  }
}

class _EmailVendorStatementsDialog extends StatefulWidget {
  const _EmailVendorStatementsDialog();

  @override
  State<_EmailVendorStatementsDialog> createState() =>
      _EmailVendorStatementsDialogState();
}

class _EmailVendorStatementsDialogState
    extends State<_EmailVendorStatementsDialog> {
  DateTime _startDate = DateTime(2026, 6, 1);
  DateTime _endDate = DateTime(2028, 6, 30);
  String _filterBy = 'All Transactions';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Material(
          color: Colors.white,
          elevation: 24,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 500,
            height: 532.99,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Email vendor statements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Start Date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ZDatePickerField(
                          selectedDate: _startDate,
                          onDateSelected: (date) {
                            setState(() {
                              _startDate = date;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'End Date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ZDatePickerField(
                          selectedDate: _endDate,
                          onDateSelected: (date) {
                            setState(() {
                              _endDate = date;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Filter By',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FormDropdown<String>(
                          value: _filterBy,
                          items: const ['All Transactions'],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _filterBy = value);
                            }
                          },
                          displayStringForValue: (value) => value,
                          showSearch: false,
                          menuWidth: 460,
                          height: 38,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Note:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Statements will be sent to vendors only if they have transactions and an opening balance that's more than zero in the selected date range.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "A PDF of the statement will be emailed to your vendor's primary contact.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                // Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ZerpaiToast.success(
                            context,
                            'Vendor statements sent successfully',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22B378),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Send Statements',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: const Color(0xFF1F2937),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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
    );
  }
}

class _HoveringRedX extends StatefulWidget {
  final VoidCallback onTap;
  const _HoveringRedX({required this.onTap});

  @override
  State<_HoveringRedX> createState() => _HoveringRedXState();
}

class _HoveringRedXState extends State<_HoveringRedX> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered ? const Color(0xFFFEE2E2) : Colors.transparent,
            border: Border.all(
              color: const Color(0xFFEF4444),
              width: 1.0,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.close,
              size: 9,
              color: Color(0xFFEF4444),
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkUpdateVendorsDialog extends StatefulWidget {
  const _BulkUpdateVendorsDialog();

  @override
  State<_BulkUpdateVendorsDialog> createState() =>
      _BulkUpdateVendorsDialogState();
}

class _BulkUpdateVendorsDialogState extends State<_BulkUpdateVendorsDialog> {
  String? _currency;
  String? _paymentTerms;
  String? _vendorLanguage;
  String? _priceList;
  String? _placeOfSupply;
  String? _gstTreatment;
  String? _tds;
  String? _adgf;
  String? _shedule;
  String? _demoAdvancedReportingTag;
  bool _showRemovePriceListCheckbox = false;
  bool _removeAssociatedPriceLists = false;
  bool _isPriceListHovered = false;
  final _demoFieldController = TextEditingController();

  @override
  void dispose() {
    _demoFieldController.dispose();
    super.dispose();
  }

  Widget _buildFieldRow({
    required String label,
    required Widget child,
    String? tooltipMessage,
    String? subText,
    Widget? trailing,
    Widget? bottomWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  if (tooltipMessage != null) ...[
                    const SizedBox(width: 4),
                    ZTooltip(
                      message: tooltipMessage,
                      child: const Icon(
                        LucideIcons.helpCircle,
                        size: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(width: 265, height: 34, child: child),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing,
                    ],
                  ],
                ),
                if (bottomWidget != null) ...[
                  const SizedBox(height: 6),
                  bottomWidget,
                ],
                if (subText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Material(
          color: Colors.white,
          elevation: 24,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 600,
            height: 768.71,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Bulk Update - Vendors',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFieldRow(
                          label: 'Currency',
                          child: FormDropdown<String>(
                            value: _currency,
                            items: const [
                              'AED - UAE Dirham',
                              'AFN - Afghan Afghani',
                              'AUD - Australian Dollar',
                              'BND - Brunei Dollar',
                              'CAD - Canadian Dollar',
                              'CNY - Yuan Renminbi',
                              'EUR - Euro',
                            ],
                            onChanged: (val) => setState(() => _currency = val),
                            displayStringForValue: (val) => val,
                            allowClear: true,
                            showSearch: true,
                            menuWidth: 265,
                            height: 34,
                          ),
                        ),
                        _buildFieldRow(
                          label: 'Payment Terms',
                          child: FormDropdown<String>(
                            value: _paymentTerms,
                            items: const [
                              'Due on Receipt',
                              'Net 15',
                              'Net 30',
                              'Net 45',
                              'Net 60',
                            ],
                            onChanged: (val) =>
                                setState(() => _paymentTerms = val),
                            displayStringForValue: (val) => val,
                            allowClear: true,
                            showSearch: true,
                            menuWidth: 265,
                            height: 34,
                          ),
                        ),
                        _buildFieldRow(
                          label: 'Vendor Language',
                          tooltipMessage:
                              'Select language for vendor communication.',
                          child: FormDropdown<String>(
                            value: _vendorLanguage,
                            items: const [
                              'English',
                              'Spanish',
                              'French',
                              'Hindi',
                            ],
                            onChanged: (val) =>
                                setState(() => _vendorLanguage = val),
                            displayStringForValue: (val) => val,
                            allowClear: true,
                            showSearch: true,
                            menuWidth: 265,
                            height: 34,
                          ),
                        ),
                        MouseRegion(
                          onEnter: (_) => setState(() => _isPriceListHovered = true),
                          onExit: (_) => setState(() => _isPriceListHovered = false),
                          child: _buildFieldRow(
                            label: 'Price List',
                            trailing: (!_showRemovePriceListCheckbox && _isPriceListHovered)
                                ? ZTooltip(
                                    message: 'Remove associated price lists',
                                    direction: ZTooltipDirection.bottom,
                                    child: _HoveringRedX(
                                      onTap: () {
                                        setState(() {
                                          _priceList = null;
                                          _showRemovePriceListCheckbox = true;
                                          _removeAssociatedPriceLists = true;
                                        });
                                      },
                                    ),
                                  )
                                : const SizedBox(width: 16, height: 16),
                            bottomWidget: _showRemovePriceListCheckbox
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: Transform.scale(
                                          scale: 0.8,
                                          child: Checkbox(
                                            value: _removeAssociatedPriceLists,
                                            activeColor: const Color(0xFF2563EB),
                                            side: const BorderSide(
                                              color: Color(0xFFD1D5DB),
                                              width: 1.0,
                                            ),
                                            fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                              if (states.contains(WidgetState.selected)) {
                                                return const Color(0xFF2563EB);
                                              }
                                              return Colors.white;
                                            }),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            onChanged: (val) {
                                              setState(() {
                                                _removeAssociatedPriceLists =
                                                    val ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Remove associated price lists',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                            child: FormDropdown<String>(
                              value: _priceList,
                              items: const [
                                'Retail Price List',
                                'Wholesale Price List',
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _priceList = val;
                                  if (val != null) {
                                    _showRemovePriceListCheckbox = false;
                                    _removeAssociatedPriceLists = false;
                                  }
                                });
                              },
                              displayStringForValue: (val) => val,
                              allowClear: false,
                              showSearch: true,
                              menuWidth: 265,
                              height: 34,
                            ),
                          ),
                        ),
                        _buildFieldRow(
                          label: 'Place of Supply / Source of Supply',
                          subText:
                              "This is not applicable for contacts that has 'Overseas' as GST treatment.",
                          child: FormDropdown<String>(
                            value: _placeOfSupply,
                            items: const [
                              'Delhi',
                              'Maharashtra',
                              'Karnataka',
                              'Tamil Nadu',
                            ],
                            onChanged: (val) =>
                                setState(() => _placeOfSupply = val),
                            displayStringForValue: (val) => val,
                            allowClear: true,
                            showSearch: true,
                            menuWidth: 265,
                            height: 34,
                          ),
                        ),
                        _buildFieldRow(
                          label: 'GST Treatment',
                          child: FormDropdown<String>(
                            value: _gstTreatment,
                            hint: 'Select a GST treatment',
                            items: const [
                              'Registered Business - Regular',
                              'Registered Business - Composition',
                              'Unregistered Business',
                              'Consumer',
                              'Overseas',
                              'SEZ',
                            ],
                            onChanged: (val) {
                              setState(() => _gstTreatment = val);
                            },
                            displayStringForValue: (val) => val,
                            allowClear: true,
                            showSearch: true,
                            menuWidth: 265,
                            height: 34,
                          ),
                        ),
                        _buildFieldRow(
                          label: 'TDS',
                          child: FormDropdown<String>(
                            value: _tds,
                            hint: 'Select a Tax',
                            items: const [
                              'TDS - 1%',
                              'TDS - 2%',
                              'TDS - 5%',
                              'TDS - 10%',
                            ],
                            onChanged: (val) {
                              setState(() => _tds = val);
                            },
                            displayStringForValue: (val) => val,
                            allowClear: true,
                            showSearch: true,
                            menuWidth: 265,
                            height: 34,
                          ),
                        ),
                        _buildFieldRow(
                          label: 'ADGF',
                          child: FormDropdown<String>(
                            value: _adgf,
                            hint: 'None',
                            items: const ['Option 1', 'Option 2'],
                            onChanged: (val) {
                              setState(() => _adgf = val);
                            },
                            displayStringForValue: (val) => val,
                            allowClear: true,
                            showSearch: true,
                            menuWidth: 265,
                            height: 34,
                          ),
                        ),
                        _buildFieldRow(
                          label: 'shedule',
                          child: FormDropdown<String>(
                            value: _shedule,
                            hint: 'None',
                            items: const ['Daily', 'Weekly', 'Monthly'],
                            onChanged: (val) {
                              setState(() => _shedule = val);
                            },
                            displayStringForValue: (val) => val,
                            allowClear: true,
                            showSearch: true,
                            menuWidth: 265,
                            height: 34,
                          ),
                        ),
                        _buildFieldRow(
                          label: 'demo advaced reporting tag',
                          child: FormDropdown<String>(
                            value: _demoAdvancedReportingTag,
                            hint: 'None',
                            items: const ['Tag A', 'Tag B'],
                            onChanged: (val) {
                              setState(() => _demoAdvancedReportingTag = val);
                            },
                            displayStringForValue: (val) => val,
                            allowClear: true,
                            showSearch: true,
                            menuWidth: 265,
                            height: 34,
                          ),
                        ),
                        _buildFieldRow(
                          label: 'demo feild',
                          child: TextFormField(
                            controller: _demoFieldController,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                // Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ZerpaiToast.success(
                            context,
                            'Fields updated successfully',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22B378),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Update Fields',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: const Color(0xFF1F2937),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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
    );
  }
}
