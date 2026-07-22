// ignore_for_file: unused_element_parameter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/settings/record_locking/lock_configuration/presentation/providers/lock_configuration_provider.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class LockConfigurationReportPage extends ConsumerStatefulWidget {
  const LockConfigurationReportPage({super.key});

  @override
  ConsumerState<LockConfigurationReportPage> createState() =>
      _LockConfigurationReportPageState();
}

class _LockConfigurationReportPageState
    extends ConsumerState<LockConfigurationReportPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
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

  Future<void> _showDeleteConfirmationDialog(int rowIndex) async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x992A3140),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 0,
            bottom: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 500,
            height: 252,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 20, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4DB),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 23,
                                color: Color(0xFFE58B00),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Delete Lock Configuration?',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2F3643),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFCF4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              '•',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF232B3A),
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ZABNIX PRIVATE LIMITED',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 15,
                                color: const Color(0xFF313A4D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                      child: Text(
                        'If you delete this lock configuration, records locked using this\n'
                        'configuration will be unlocked and users in your organization can make\n'
                        'changes to them.',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 15,
                          height: 1.55,
                          color: const Color(0xFF313A4D),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
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
                              label: 'Delete',
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              onPressed: () {
                                ref
                                    .read(lockConfigurationProvider.notifier)
                                    .deleteSeries(rowIndex);
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 36,
                            child: ZButton.secondary(
                              label: 'Cancel',
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              onPressed: () => Navigator.of(dialogContext).pop(),
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
      },
    );
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
                  if (entry.route == null) {
                    ZerpaiToast.info(
                      context,
                      '${entry.label} is not available yet',
                    );
                    return;
                  }
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
            _ReportHeader(
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
                          _ReportTitleBar(
                            onCreate: () => context.go(
                              _withOrgPrefix(
                                AppRoutes.settingsLockConfigurationCreate,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _SeriesTableSection(
                              rows: ref.watch(lockConfigurationProvider),
                              onRowTap: (rowIndex) {
                                final target = Uri(
                                  path: _withOrgPrefix(
                                    AppRoutes.settingsLockConfigurationCreate,
                                  ),
                                  queryParameters: <String, String>{
                                    'editIndex': '$rowIndex',
                                  },
                                ).toString();
                                context.go(target);
                              },
                              onDeleteTap: (rowIndex) =>
                                  _showDeleteConfirmationDialog(rowIndex),
                              onInactiveTap: (rowIndex) {
                                ref
                                    .read(lockConfigurationProvider.notifier)
                                    .toggleStatus(rowIndex);
                              },
                              horizontalController: _horizontalController,
                              verticalController: _verticalController,
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

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({
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

class _ReportTitleBar extends StatelessWidget {
  const _ReportTitleBar({
    required this.onCreate,
  });

  final VoidCallback onCreate;

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
            'Lock Configuration',
            style: AppTheme.pageTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 36,
            child: ZButton.primary(
              label: 'New Lock Configuration',
              icon: Icons.add,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: onCreate,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesTableSection extends StatefulWidget {
  const _SeriesTableSection({
    required this.rows,
    required this.onRowTap,
    required this.onDeleteTap,
    required this.onInactiveTap,
    required this.horizontalController,
    required this.verticalController,
  });

  final List<LockConfigurationRecord> rows;
  final ValueChanged<int> onRowTap;
  final ValueChanged<int> onDeleteTap;
  final ValueChanged<int> onInactiveTap;
  final ScrollController horizontalController;
  final ScrollController verticalController;

  @override
  State<_SeriesTableSection> createState() => _SeriesTableSectionState();
}

class _SeriesTableSectionState extends State<_SeriesTableSection> {
  int? _hoveredRowIndex;

  @override
  void initState() {
    super.initState();
    widget.horizontalController.addListener(_handleHorizontalScroll);
  }

  @override
  void didUpdateWidget(covariant _SeriesTableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.horizontalController != widget.horizontalController) {
      oldWidget.horizontalController.removeListener(_handleHorizontalScroll);
      widget.horizontalController.addListener(_handleHorizontalScroll);
    }
  }

  @override
  void dispose() {
    widget.horizontalController.removeListener(_handleHorizontalScroll);
    super.dispose();
  }

  void _handleHorizontalScroll() {
    if (mounted) setState(() {});
  }

  Future<void> _nudgeHorizontal(double delta) async {
    if (!widget.horizontalController.hasClients) return;
    final position = widget.horizontalController.position;
    final target = (widget.horizontalController.offset + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    await widget.horizontalController.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  double _thumbFraction() {
    try {
      if (!widget.horizontalController.hasClients) return 0;
      final position = widget.horizontalController.position;
      if (!position.hasContentDimensions) return 0;
      final max = position.maxScrollExtent;
      if (max <= 0) return 0;
      return (widget.horizontalController.offset / max).clamp(0.0, 1.0);
    } catch (_) {
      return 0;
    }
  }

  double _thumbWidth(double trackWidth) {
    if (trackWidth <= 56.0) return trackWidth;
    try {
      if (!widget.horizontalController.hasClients) {
        return trackWidth.clamp(56.0, 140.0);
      }
      final position = widget.horizontalController.position;
      if (!position.hasContentDimensions) {
        return trackWidth.clamp(56.0, 140.0);
      }
      final total = position.maxScrollExtent + position.viewportDimension;
      if (total <= 0) return trackWidth.clamp(56.0, 140.0);
      return (trackWidth * (position.viewportDimension / total)).clamp(
        56.0,
        trackWidth,
      );
    } catch (_) {
      return trackWidth.clamp(56.0, 140.0);
    }
  }

  void _jumpHorizontalToFraction(double fraction) {
    if (!widget.horizontalController.hasClients) return;
    final position = widget.horizontalController.position;
    final target = (position.maxScrollExtent * fraction).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    widget.horizontalController.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    const columns = _seriesColumns;
    final rows = widget.rows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (notification) {
                    if (mounted) {
                      setState(() {});
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: widget.horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                    width: 1714,
                    child: SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppTheme.borderLight),
                            left: BorderSide(color: AppTheme.borderLight),
                            right: BorderSide(color: AppTheme.borderLight),
                          ),
                        ),
                        child: Table(
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              columnWidths: const {
                                0: FixedColumnWidth(160),
                                1: FixedColumnWidth(260),
                                2: FixedColumnWidth(272),
                                3: FixedColumnWidth(272),
                                4: FixedColumnWidth(272),
                                5: FixedColumnWidth(274),
                                6: FixedColumnWidth(120),
                                7: FixedColumnWidth(84),
                              },
                              children: [
                                TableRow(
                                  children: columns
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => _HeaderCell(
                                          label: entry.value.label,
                                          showRightBorder:
                                              entry.key !=
                                              columns.length - 2,
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                                for (
                                  var rowIndex = 0;
                                  rowIndex < rows.length;
                                  rowIndex++
                                )
                                  TableRow(
                                    children: [
                                      _BodyCell(
                                        value: rows[rowIndex].module,
                                        isHovered:
                                            _hoveredRowIndex == rowIndex,
                                        showHoverAction: false,
                                        showRightBorder: true,
                                        actionMenu: null,
                                        onTap: () =>
                                            widget.onRowTap(rowIndex),
                                        onHoverChanged: (hovered) {
                                          setState(() {
                                            _hoveredRowIndex = hovered
                                                ? rowIndex
                                                : null;
                                          });
                                        },
                                        isLink: false,
                                      ),
                                      _BodyCell(
                                        value: rows[rowIndex]
                                            .lockConfigurationName,
                                        isHovered:
                                            _hoveredRowIndex == rowIndex,
                                        showHoverAction: false,
                                        showRightBorder: true,
                                        actionMenu: null,
                                        onTap: () =>
                                            widget.onRowTap(rowIndex),
                                        onHoverChanged: (hovered) {
                                          setState(() {
                                            _hoveredRowIndex = hovered
                                                ? rowIndex
                                                : null;
                                          });
                                        },
                                        isLink: true,
                                      ),
                                      _BodyCell(
                                        value: rows[rowIndex].description,
                                        isHovered:
                                            _hoveredRowIndex == rowIndex,
                                        showHoverAction: false,
                                        showRightBorder: true,
                                        actionMenu: null,
                                        onTap: () =>
                                            widget.onRowTap(rowIndex),
                                        onHoverChanged: (hovered) {
                                          setState(() {
                                            _hoveredRowIndex = hovered
                                                ? rowIndex
                                                : null;
                                          });
                                        },
                                        isLink: false,
                                      ),
                                      _BodyCell(
                                        value: rows[rowIndex]
                                            .allowOrRestrictActions,
                                        isHovered:
                                            _hoveredRowIndex == rowIndex,
                                        showHoverAction: false,
                                        showRightBorder: true,
                                        actionMenu: null,
                                        onTap: null,
                                        onHoverChanged: (hovered) {
                                          setState(() {
                                            _hoveredRowIndex = hovered
                                                ? rowIndex
                                                : null;
                                          });
                                        },
                                        isLink: false,
                                        customChild: _ExpandableListCell(
                                          value: rows[rowIndex]
                                              .allowOrRestrictActions,
                                        ),
                                      ),
                                      _BodyCell(
                                        value: rows[rowIndex]
                                            .allowOrRestrictFields,
                                        isHovered:
                                            _hoveredRowIndex == rowIndex,
                                        showHoverAction: false,
                                        showRightBorder: true,
                                        actionMenu: null,
                                        onTap: null,
                                        onHoverChanged: (hovered) {
                                          setState(() {
                                            _hoveredRowIndex = hovered
                                                ? rowIndex
                                                : null;
                                          });
                                        },
                                        isLink: false,
                                        customChild: _ExpandableListCell(
                                          value: rows[rowIndex]
                                              .allowOrRestrictFields,
                                        ),
                                      ),
                                      _BodyCell(
                                        value: rows[rowIndex].lockRecordsFor,
                                        isHovered:
                                            _hoveredRowIndex == rowIndex,
                                        showHoverAction: false,
                                        showRightBorder: true,
                                        actionMenu: null,
                                        onTap: null,
                                        onHoverChanged: (hovered) {
                                          setState(() {
                                            _hoveredRowIndex = hovered
                                                ? rowIndex
                                                : null;
                                          });
                                        },
                                        isLink: false,
                                        customChild: _ExpandableListCell(
                                          value: rows[rowIndex].lockRecordsFor,
                                        ),
                                      ),
                                      _BodyCell(
                                        value: rows[rowIndex].status,
                                        isHovered:
                                            _hoveredRowIndex == rowIndex,
                                        showHoverAction: false,
                                        showRightBorder: false,
                                        actionMenu: null,
                                        onTap: () =>
                                            widget.onRowTap(rowIndex),
                                        onHoverChanged: (hovered) {
                                          setState(() {
                                            _hoveredRowIndex = hovered
                                                ? rowIndex
                                                : null;
                                          });
                                        },
                                        isLink: false,
                                      ),
                                      _BodyCell(
                                        value: '',
                                        isHovered:
                                            _hoveredRowIndex == rowIndex,
                                        showHoverAction: true,
                                        showRightBorder: true,
                                        showLeftBorder: false,
                                        actionMenu: _RowActionMenu(
                                          onEdit: () =>
                                              widget.onRowTap(rowIndex),
                                          onInactive: () => widget
                                              .onInactiveTap(rowIndex),
                                          inactiveLabel:
                                              rows[rowIndex].status ==
                                                  'Inactive'
                                              ? 'Mark as Active'
                                              : 'Mark as Inactive',
                                          onDelete: () => widget.onDeleteTap(
                                            rowIndex,
                                          ),
                                        ),
                                        onTap: null,
                                        onHoverChanged: (hovered) {
                                          setState(() {
                                            _hoveredRowIndex = hovered
                                                ? rowIndex
                                                : null;
                                          });
                                        },
                                        isLink: false,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
              Container(
                height: 24,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE7E8F0)),
                ),
                child: Row(
                  children: [
                    _ScrollArrowButton(
                      label: '<',
                      onTap: () => _nudgeHorizontal(-180),
                      showRightBorder: true,
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const horizontalInset = 8.0;
                          final trackWidth = constraints.maxWidth;
                          final usableTrackWidth = (trackWidth -
                                  (horizontalInset * 2))
                              .clamp(1.0, double.infinity);
                          final thumbWidth = _thumbWidth(
                            usableTrackWidth,
                          ).clamp(64.0, usableTrackWidth);
                          final maxTravel = (usableTrackWidth - thumbWidth)
                              .clamp(1.0, double.infinity);
                          final thumbLeft =
                              horizontalInset + (_thumbFraction() * maxTravel);

                          void moveToFractionFromLocalDx(double localDx) {
                            final target = (localDx - horizontalInset)
                                .clamp(0.0, usableTrackWidth);
                            _jumpHorizontalToFraction(target / usableTrackWidth);
                          }

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) =>
                                moveToFractionFromLocalDx(
                                  details.localPosition.dx,
                                ),
                            onHorizontalDragUpdate: (details) =>
                                moveToFractionFromLocalDx(
                                  details.localPosition.dx,
                                ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: horizontalInset,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F4F9),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: thumbLeft,
                                  top: 8,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      width: thumbWidth,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFB8B7C6),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    _ScrollArrowButton(
                      label: '>',
                      onTap: () => _nudgeHorizontal(180),
                      showRightBorder: false,
                      showLeftBorder: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScrollArrowButton extends StatelessWidget {
  const _ScrollArrowButton({
    required this.label,
    required this.onTap,
    this.showRightBorder = false,
    this.showLeftBorder = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool showRightBorder;
  final bool showLeftBorder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 24,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: showLeftBorder
                ? const BorderSide(color: Color(0xFFE7E8F0))
                : BorderSide.none,
            right: showRightBorder
                ? const BorderSide(color: Color(0xFFE7E8F0))
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFB7BAC6),
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    this.showRightBorder = true,
  });

  final String label;
  final bool showRightBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFE),
      ).copyWith(
        border: Border(
          right: showRightBorder
              ? const BorderSide(color: AppTheme.borderLight)
              : BorderSide.none,
          bottom: const BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Text(
        label,
        style: AppTheme.captionText.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6C718A),
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _BodyCell extends StatefulWidget {
  const _BodyCell({
    required this.value,
    required this.isHovered,
    required this.onHoverChanged,
    this.showHoverAction = false,
    this.isLink = false,
    this.onTap,
    this.actionMenu,
    this.showRightBorder = true,
    this.showLeftBorder = false,
    this.customChild,
  });

  final String value;
  final bool isHovered;
  final ValueChanged<bool> onHoverChanged;
  final bool showHoverAction;
  final bool isLink;
  final VoidCallback? onTap;
  final Widget? actionMenu;
  final bool showRightBorder;
  final bool showLeftBorder;
  final Widget? customChild;

  @override
  State<_BodyCell> createState() => _BodyCellState();
}

class _BodyCellState extends State<_BodyCell> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHoverChanged(true),
      onExit: (_) => widget.onHoverChanged(false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.showHoverAction ? 74 : null,
          constraints: const BoxConstraints(minHeight: 74),
          padding: EdgeInsets.symmetric(
            horizontal: widget.showHoverAction ? 0 : 10,
          ),
          alignment: widget.showHoverAction
              ? Alignment.center
              : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: widget.isHovered ? const Color(0xFFF5F8FF) : Colors.white,
            border: Border(
              left: widget.showLeftBorder
                  ? const BorderSide(color: AppTheme.borderLight)
                  : BorderSide.none,
              right: widget.showRightBorder
                  ? const BorderSide(color: AppTheme.borderLight)
                  : BorderSide.none,
              bottom: const BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: widget.showHoverAction
              ? AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: widget.isHovered ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !widget.isHovered,
                    child: widget.actionMenu ?? const _RowActionMenu(),
                  ),
                )
              : widget.customChild ??
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.value,
                        softWrap: true,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: widget.isLink
                              ? const Color(0xFF2962FF)
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}

class _ExpandableListCell extends StatefulWidget {
  const _ExpandableListCell({
    required this.value,
  });

  final String value;

  @override
  State<_ExpandableListCell> createState() => _ExpandableListCellState();
}

class _ExpandableListCellState extends State<_ExpandableListCell> {
  final MenuController _controller = MenuController();

  ({String prefix, List<String> items}) _splitValue(String value) {
    final separatorIndex = value.indexOf(': ');
    if (separatorIndex == -1) {
      return (prefix: '', items: <String>[value]);
    }

    final prefix = value.substring(0, separatorIndex + 2);
    final suffix = value.substring(separatorIndex + 2).trim();
    if (suffix.isEmpty) {
      return (prefix: prefix, items: const <String>[]);
    }

    final items = suffix
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && !item.startsWith('+'))
        .toList(growable: false);

    return (prefix: prefix, items: items);
  }

  @override
  Widget build(BuildContext context) {
    final split = _splitValue(widget.value);
    final prefix = split.prefix;
    final items = split.items;

    if (items.length <= 2) {
      return Text(
        widget.value,
        softWrap: true,
        style: AppTheme.bodyText.copyWith(
          fontSize: 13,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
      );
    }

    final visibleItems = items.take(2).join(', ');
    final remainingItems = items.skip(2).toList(growable: false);

    return MenuAnchor(
      controller: _controller,
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: WidgetStatePropertyAll(10),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      menuChildren: [
        Container(
          width: 170,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: remainingItems
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      item,
                      softWrap: true,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 2,
          children: [
            Text(
              '$prefix$visibleItems,',
              softWrap: true,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    '+${remainingItems.length}',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF2962FF),
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RowActionMenu extends StatefulWidget {
  const _RowActionMenu({
    this.onEdit,
    this.onDelete,
    this.onInactive,
    this.inactiveLabel = 'Mark as Inactive',
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onInactive;
  final String inactiveLabel;

  @override
  State<_RowActionMenu> createState() => _RowActionMenuState();
}

class _RowActionMenuState extends State<_RowActionMenu> {
  final MenuController _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(-82, 8),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
        elevation: WidgetStatePropertyAll(10),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      menuChildren: [
        _RowActionMenuItem(
          label: 'Edit',
          controller: _controller,
          onTap: widget.onEdit,
        ),
        const SizedBox(height: 4),
        _RowActionMenuItem(
          label: widget.inactiveLabel,
          controller: _controller,
          onTap: widget.onInactive ??
              () => ZerpaiToast.info(context, 'Inactive action triggered'),
        ),
        const SizedBox(height: 4),
        _RowActionMenuItem(
          label: 'Delete',
          controller: _controller,
          onTap: widget.onDelete,
        ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF29B765),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _RowActionMenuItem extends StatefulWidget {
  const _RowActionMenuItem({
    required this.label,
    required this.controller,
    this.onTap,
  });

  final String label;
  final MenuController controller;
  final VoidCallback? onTap;

  @override
  State<_RowActionMenuItem> createState() => _RowActionMenuItemState();
}

class _RowActionMenuItemState extends State<_RowActionMenuItem> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final background = _pressed
        ? const Color(0xFFF1F2F6)
        : (_hovered ? AppTheme.primaryBlue : Colors.white);
    final foreground = _hovered ? Colors.white : const Color(0xFF4B556B);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        setState(() {
          _hovered = false;
          _pressed = false;
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          widget.controller.close();
          widget.onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 140,
          height: 34,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesColumn {
  const _SeriesColumn(this.label, this.width);

  final String label;
  final double width;
}

const List<_SeriesColumn> _seriesColumns = [
  _SeriesColumn('MODULE', 160),
  _SeriesColumn('LOCK CONFIGURATION NAME', 260),
  _SeriesColumn('DESCRIPTION', 272),
  _SeriesColumn('ALLOW OR RESTRICT ACTIONS', 272),
  _SeriesColumn('ALLOW OR RESTRICT FIELDS', 272),
  _SeriesColumn('LOCK RECORDS FOR', 274),
  _SeriesColumn('STATUS', 120),
  _SeriesColumn('', 64),
];
