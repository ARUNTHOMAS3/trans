// ignore_for_file: unused_element_parameter
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
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class ApprovalReportPage extends ConsumerStatefulWidget {
  const ApprovalReportPage({super.key});

  @override
  ConsumerState<ApprovalReportPage> createState() =>
      _ApprovalReportPageState();
}

class _ApprovalReportPageState
    extends ConsumerState<ApprovalReportPage> {
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


  Future<void> _showDeleteBlockedDialog() async {
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
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: 500,
            height: 276.17,
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
                          'You cannot delete this transaction series as it is the default\n'
                          'transaction series in the following locations:',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 15,
                            height: 1.55,
                            color: const Color(0xFF313A4D),
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
                    'Remove this transaction series as the default transaction series from the\n'
                    'above locations and try again.',
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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 36,
                      child: ZButton.primary(
                        label: 'Okay',
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
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
    final orgName =
        ref.watch(orgSettingsProvider).asData?.value?.name.trim().isNotEmpty ==
            true
                    ? ref.watch(orgSettingsProvider).asData!.value!.name.trim()
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
                                AppRoutes.settingsApprovalCreate,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _SeriesTableSection(
                              rows: ref.watch(ApprovalProvider),
                              onRowTap: (rowIndex) {
                                final target = Uri(
                                  path: _withOrgPrefix(
                                    AppRoutes.settingsApprovalCreate,
                                  ),
                                  queryParameters: <String, String>{
                                    'editIndex': '$rowIndex',
                                  },
                                ).toString();
                                context.go(target);
                              },
                              onDeleteTap: _showDeleteBlockedDialog,
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
            'Approval',
            style: AppTheme.pageTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 36,
            child: ZButton.primary(
              label: 'New',
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
    required this.horizontalController,
    required this.verticalController,
  });

  final List<ApprovalRecord> rows;
  final ValueChanged<int> onRowTap;
  final VoidCallback onDeleteTap;
  final ScrollController horizontalController;
  final ScrollController verticalController;

  @override
  State<_SeriesTableSection> createState() => _SeriesTableSectionState();
}

class _SeriesTableSectionState extends State<_SeriesTableSection> {
  int? _hoveredRowIndex;

  @override
  Widget build(BuildContext context) {
    const columns = _seriesColumns;
    final rows = widget.rows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          child: Row(
            children: [
              Text(
                'All Approvals',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFA8A2BF),
                  borderRadius: BorderRadius.circular(6),
                ),
                  child: Center(
                  child: Text(
                    '${rows.length}',
                    style: AppTheme.captionText.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: widget.verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: widget.verticalController,
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 24, 24),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.borderLight),
                    left: BorderSide(color: AppTheme.borderLight),
                    right: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FixedColumnWidth(64),
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
                                      entry.key != columns.length - 2,
                                ),
                              )
                              .toList(growable: false),
                        ),
                        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
                          TableRow(
                            children: [
                              _BodyCell(
                                value: _moduleFromSeriesName(rows[rowIndex].seriesName),
                                isHovered: _hoveredRowIndex == rowIndex,
                                showHoverAction: false,
                                showRightBorder: true,
                                actionMenu: null,
                                onTap: () => widget.onRowTap(rowIndex),
                                onHoverChanged: (hovered) {
                                  setState(() {
                                    _hoveredRowIndex = hovered ? rowIndex : null;
                                  });
                                },
                                isLink: true,
                              ),
                              _BodyCell(
                                value: _approvalTypeFromSeriesName(rows[rowIndex].seriesName),
                                isHovered: _hoveredRowIndex == rowIndex,
                                showHoverAction: false,
                                showRightBorder: false,
                                actionMenu: null,
                                onTap: () => widget.onRowTap(rowIndex),
                                onHoverChanged: (hovered) {
                                  setState(() {
                                    _hoveredRowIndex = hovered ? rowIndex : null;
                                  });
                                },
                                isLink: false,
                              ),
                              _BodyCell(
                                value: '',
                                isHovered: _hoveredRowIndex == rowIndex,
                                showHoverAction: true,
                                showRightBorder: false,
                                actionMenu: _RowActionMenu(
                                  onEdit: () => widget.onRowTap(rowIndex),
                                  onDelete: widget.onDeleteTap,
                                ),
                                onTap: null,
                                onHoverChanged: (hovered) {
                                  setState(() {
                                    _hoveredRowIndex = hovered ? rowIndex : null;
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
      ],
    );
  }

  String _moduleFromSeriesName(String seriesName) {
    final parts = seriesName.split(' - ');
    return parts.isNotEmpty ? parts.first : seriesName;
  }

  String _approvalTypeFromSeriesName(String seriesName) {
    final parts = seriesName.split(' - ');
    return parts.length >= 2 ? parts.sublist(1).join(' - ') : '';
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
          height: 52,
          padding: EdgeInsets.symmetric(
            horizontal: widget.showHoverAction ? 0 : 10,
          ),
          alignment: widget.showHoverAction
              ? Alignment.center
              : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: widget.isHovered ? const Color(0xFFF5F8FF) : Colors.white,
            border: Border(
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
                  Text(
                    widget.value,
                    overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _RowActionMenu extends StatelessWidget {
  const _RowActionMenu({
    this.onEdit,
    this.onDelete,
    this.onInactive,
    this.onDisable,
    this.onClone,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onInactive;
  final VoidCallback? onDisable;
  final VoidCallback? onClone;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-70, 8),
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
          onTap: onEdit,
        ),
        const SizedBox(height: 4),
        _RowActionMenuItem(
          label: 'Inactive',
          onTap: onInactive ?? () => ZerpaiToast.info(context, 'Inactive action triggered'),
        ),
        const SizedBox(height: 4),
        _RowActionMenuItem(
          label: 'Disable',
          onTap: onDisable ?? () => ZerpaiToast.info(context, 'Disable action triggered'),
        ),
        const SizedBox(height: 4),
        _RowActionMenuItem(
          label: 'Delete',
          onTap: onDelete,
        ),
        const SizedBox(height: 4),
        _RowActionMenuItem(
          label: 'Clone',
          onTap: onClone ?? () => ZerpaiToast.info(context, 'Clone action triggered'),
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
    this.onTap,
  });

  final String label;
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
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 80,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(6),
          ),
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
    );
  }
}


class _SeriesColumn {
  const _SeriesColumn(this.label, this.width);

  final String label;
  final double width;
}

const List<_SeriesColumn> _seriesColumns = [
  _SeriesColumn('MODULE', 400),
  _SeriesColumn('APPROVAL', 400),
  _SeriesColumn('', 64),
];
