import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/accountant/providers/accountant_chart_of_accounts_provider.dart';
import 'package:dio/dio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

class AccountRow extends ConsumerStatefulWidget {
  final AccountNode node;
  final int level;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final Set<String> expandedIds;
  final Function(String) onToggleChild;
  final Function(String) onTapChild;
  final bool isLast;
  final List<bool> ancestorHasNext;
  final bool compact;
  final String? selectedAccountId;
  final List<String> columnOrder;
  final double? nameWidth;
  final double? codeWidth;
  final double? balanceWidth;
  final double? typeWidth;
  final double? documentsWidth;
  final double? parentWidth;

  const AccountRow({
    super.key,
    required this.node,
    required this.level,
    required this.isExpanded,
    required this.onToggle,
    required this.onTap,
    required this.expandedIds,
    required this.onToggleChild,
    required this.onTapChild,
    required this.isLast,
    required this.ancestorHasNext,
    required this.compact,
    this.selectedAccountId,
    required this.columnOrder,
    this.nameWidth,
    this.codeWidth,
    this.balanceWidth,
    this.typeWidth,
    this.documentsWidth,
    this.parentWidth,
  });

  @override
  ConsumerState<AccountRow> createState() => _AccountRowState();
}

class _AccountRowState extends ConsumerState<AccountRow> {
  bool _isHovered = false;
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final bool useFixed =
        !widget.compact &&
        widget.nameWidth != null &&
        widget.codeWidth != null &&
        widget.typeWidth != null &&
        widget.documentsWidth != null &&
        widget.parentWidth != null;
    // Indentation Rules: Base 16px + level * 20px
    final double indentUnit = widget.compact ? 14.0 : 20.0;
    final double indent =
        (widget.compact ? 2.0 : 4.0) + (widget.level * indentUnit);

    final bool isSelectedInBulk = ref.watch(
      chartOfAccountsProvider.select(
        (s) => s.selectedIds.contains(widget.node.id),
      ),
    );
    final bool isSelected =
        widget.selectedAccountId == widget.node.id || isSelectedInBulk;

    final state = ref.watch(chartOfAccountsProvider);
    final TextOverflow overflow = state.isTextWrapped
        ? TextOverflow.visible
        : TextOverflow.ellipsis;

    final List<String> visibleOrder = widget.compact
        ? const ['name']
        : widget.columnOrder.where((key) {
            if (key == 'documents') return state.showDocuments;
            if (key == 'parent') return state.showParentName;
            return true;
          }).toList();

    double widthFor(String key) {
      switch (key) {
        case 'name':
          return widget.nameWidth ?? 0;
        case 'code':
          return widget.codeWidth ?? 0;
        case 'balance':
          return widget.balanceWidth ?? 0;
        case 'type':
          return widget.typeWidth ?? 0;
        case 'documents':
          return widget.documentsWidth ?? 0;
        case 'parent':
          return widget.parentWidth ?? 0;
        default:
          return 0;
      }
    }

    int flexFor(String key) {
      switch (key) {
        case 'name':
          return 4;
        case 'code':
          return 2;
        case 'balance':
          return 2;
        case 'type':
          return 2;
        case 'documents':
          return 2;
        case 'parent':
          return 3;
        default:
          return 1;
      }
    }

    Widget wrapCell(String key, Widget child) {
      if (useFixed) {
        return SizedBox(width: widthFor(key), child: child);
      }
      if (widget.compact && key == 'code') {
        return SizedBox(width: 80, child: child);
      }
      return Expanded(flex: flexFor(key), child: child);
    }

    Widget buildNameCell() {
      return wrapCell(
        'name',
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TreeGuides(
                level: widget.level,
                indentUnit: indentUnit,
                isLast: widget.isLast,
                ancestorHasNext: widget.ancestorHasNext,
              ),
              SizedBox(width: indent),
              if (widget.node.children.isNotEmpty)
                SizedBox(
                  width: 20,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      widget.isExpanded
                          ? LucideIcons.chevronDown
                          : LucideIcons.chevronRight,
                      size: 16,
                      color: Colors.grey[700],
                    ),
                    onPressed: widget.onToggle,
                  ),
                )
              else
                const SizedBox(width: 20),
              const SizedBox(width: 2),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Opacity(
                        opacity: widget.node.isActive ? 1.0 : 0.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.node.name,
                              overflow: overflow,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: (widget.node.isActive || isSelected)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppTheme.primaryBlueDark
                                    : widget.node.isSystem
                                    ? AppTheme.primaryBlueDark
                                    : AppTheme.textPrimary,
                                decoration: widget.node.isActive
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                            ),
                            if (widget.compact) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.node.accountGroup,
                                overflow: overflow,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B), // Slate 500
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!widget.node.isActive)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
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

    Widget buildTextCell(String key, String text, TextStyle style) {
      return wrapCell(
        key,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(text, style: style, overflow: overflow),
        ),
      );
    }

    final List<Widget> columnWidgets = visibleOrder.map((key) {
      switch (key) {
        case 'name':
          return buildNameCell();
        case 'code':
          return buildTextCell(
            'code',
            widget.node.code ?? '',
            const TextStyle(fontSize: 13, color: Colors.grey),
          );
        case 'balance':
          final color = widget.node.balanceType == 'Cr'
              ? AppTheme.errorRed
              : AppTheme.primaryBlue;
          final balanceStr = widget.node.balance != null
              ? '${widget.node.balanceType ?? ''} ${widget.node.balance!.toStringAsFixed(2)}'
              : '--';
          return buildTextCell(
            'balance',
            balanceStr,
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          );
        case 'type':
          return wrapCell(
            'type',
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.node.accountType,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: overflow,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.node.accountGroup,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    overflow: overflow,
                  ),
                ],
              ),
            ),
          );
        case 'documents':
          return buildTextCell(
            'documents',
            '',
            const TextStyle(fontSize: 13, color: Colors.grey),
          );
        case 'parent':
          return buildTextCell(
            'parent',
            widget.node.parentName ?? '',
            const TextStyle(fontSize: 13, color: Colors.grey),
          );
        default:
          return const SizedBox.shrink();
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            onTap: widget.onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.selectionActiveBg
                    : (_isHovered || _isMenuOpen)
                    ? AppTheme.bgHover
                    : AppTheme.backgroundColor,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: Stack(
                children: [
                  if (isSelected)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 3,
                      child: Container(color: AppTheme.primaryBlue),
                    ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Align icons vertically
                      children: [
                        // 1. Padding for Folder/Filter Alignment
                        Container(width: 20),

                        // 2. Selectable / System Icon Cell
                        Container(
                          width: 22,
                          alignment: Alignment.center,
                          child: !widget.node.isDeletable
                              ? const Tooltip(
                                  message:
                                      "You cannot delete this account. However, you will be able to edit the account details.",
                                  child: Icon(
                                    LucideIcons.lock,
                                    size: 14,
                                    color: Color(0xFF94A3B8), // Slate 400
                                  ),
                                )
                              : InkWell(
                                  onTap: () => ref
                                      .read(chartOfAccountsProvider.notifier)
                                      .toggleSelectAccount(widget.node.id),
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelectedInBulk
                                            ? const Color(0xFF3B82F6)
                                            : const Color(
                                                0xFFCBD5E1,
                                              ), // Slate 300 for better visibility
                                        width: 1.5,
                                      ),
                                      color: isSelectedInBulk
                                          ? const Color(0xFF3B82F6)
                                          : Colors.transparent,
                                    ),
                                    child: isSelectedInBulk
                                        ? const Icon(
                                            LucideIcons.check,
                                            size: 10,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                        ),

                        ...columnWidgets,

                        // 8. Actions (Gear Icon)
                        SizedBox(
                          width: widget.compact ? 36 : 48,
                          child: Center(
                            child:
                                (widget.node.isDeletable &&
                                    (_isHovered || _isMenuOpen))
                                ? PopupMenuButton<String>(
                                    tooltip: 'Actions',
                                    color: Colors.white,
                                    onOpened: () =>
                                        setState(() => _isMenuOpen = true),
                                    onCanceled: () =>
                                        setState(() => _isMenuOpen = false),
                                    offset: const Offset(-100, 32),
                                    elevation: 8,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 160,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    icon: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _isMenuOpen
                                            ? const Color(0xFFEFF6FF)
                                            : const Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        LucideIcons
                                            .settings, // Solid Gear Icon as per spec
                                        size: 14,
                                        color: _isMenuOpen
                                            ? const Color(0xFF3B82F6)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    onSelected: (value) async {
                                      if (mounted)
                                        setState(() => _isMenuOpen = false);
                                      try {
                                        switch (value) {
                                          case 'edit':
                                            context.push(
                                              AppRoutes
                                                  .accountsChartOfAccountsCreate,
                                              extra: {'account': widget.node},
                                            );
                                            break;
                                          case 'inactive':
                                            final newStatus =
                                                !widget.node.isActive;
                                            await ref
                                                .read(
                                                  chartOfAccountsProvider
                                                      .notifier,
                                                )
                                                .updateAccountStatus(
                                                  widget.node.id,
                                                  newStatus,
                                                );
                                            if (mounted) {
                                              ZerpaiToast.success(
                                                context,
                                                'Account "${widget.node.name}" marked as ${newStatus ? 'Active' : 'Inactive'}',
                                              );
                                            }
                                            break;
                                          case 'delete':
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                backgroundColor: Colors.white,
                                                surfaceTintColor: Colors.white,
                                                title: const Text(
                                                  'Delete Account',
                                                ),
                                                content: Text(
                                                  'Are you sure you want to delete "${widget.node.name}"?',
                                                ),
                                                actions: [
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        context.pop(false),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              AppTheme
                                                                  .primaryBlue,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        context.pop(true),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              AppTheme.errorRed,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirmed == true) {
                                              await ref
                                                  .read(
                                                    chartOfAccountsProvider
                                                        .notifier,
                                                  )
                                                  .deleteAccount(
                                                    widget.node.id,
                                                  );
                                            }
                                            break;
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          String errorMessage = e.toString();
                                          if (e is DioException) {
                                            final data = e.response?.data;
                                            if (data is Map &&
                                                data.containsKey('message')) {
                                              errorMessage = data['message'];
                                            }
                                          }
                                          ZerpaiToast.error(
                                            context,
                                            errorMessage,
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        height: 38,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              LucideIcons.edit,
                                              size: 16,
                                              color: Color(0xFF3B82F6),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Edit',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF3B82F6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'inactive',
                                        height: 34,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          widget.node.isActive
                                              ? 'Mark as Inactive'
                                              : 'Mark as Active',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        height: 34,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        enabled: widget.node.isDeletable,
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: widget.node.isDeletable
                                                ? Colors.redAccent
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
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

        // Recursive Children
        if (widget.isExpanded)
          ...widget.node.children.map((child) {
            final index = widget.node.children.indexOf(child);
            final isLast = index == widget.node.children.length - 1;
            final ancestorHasNext = [...widget.ancestorHasNext, !widget.isLast];

            // Ensure child node has parentName set for display in the table
            final nodeWithParent =
                (child.parentName == null || child.parentName!.isEmpty)
                ? child.copyWith(parentName: widget.node.name)
                : child;

            return AccountRow(
              node: nodeWithParent,
              level: widget.level + 1,
              isExpanded: widget.expandedIds.contains(child.id),
              onToggle: () => widget.onToggleChild(child.id),
              onTap: () => widget.onTapChild(child.id),
              expandedIds: widget.expandedIds,
              onToggleChild: widget.onToggleChild,
              onTapChild: widget.onTapChild,
              isLast: isLast,
              ancestorHasNext: ancestorHasNext,
              compact: widget.compact,
              selectedAccountId: widget.selectedAccountId,
              columnOrder: widget.columnOrder,
              nameWidth: widget.nameWidth,
              codeWidth: widget.codeWidth,
              balanceWidth: widget.balanceWidth,
              typeWidth: widget.typeWidth,
              documentsWidth: widget.documentsWidth,
              parentWidth: widget.parentWidth,
            );
          }),
      ],
    );
  }
}

class TreeGuides extends StatelessWidget {
  final int level;
  final double indentUnit;
  final bool isLast;
  final List<bool> ancestorHasNext;

  const TreeGuides({
    super.key,
    required this.level,
    required this.indentUnit,
    required this.isLast,
    required this.ancestorHasNext,
  });

  @override
  Widget build(BuildContext context) {
    if (level == 0) return const SizedBox.shrink();
    return SizedBox(
      width: level * indentUnit,
      height: 44,
      child: CustomPaint(
        painter: _TreeGuidePainter(
          level: level,
          indentUnit: indentUnit,
          isLast: isLast,
          ancestorHasNext: ancestorHasNext,
        ),
      ),
    );
  }
}

class _TreeGuidePainter extends CustomPainter {
  final int level;
  final double indentUnit;
  final bool isLast;
  final List<bool> ancestorHasNext;

  _TreeGuidePainter({
    required this.level,
    required this.indentUnit,
    required this.isLast,
    required this.ancestorHasNext,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    for (int i = 0; i < level - 1; i++) {
      if (i < ancestorHasNext.length && ancestorHasNext[i]) {
        final x = (i + 0.5) * indentUnit;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }

    final x = (level - 0.5) * indentUnit;
    final midY = size.height / 2;
    final endY = isLast ? midY : size.height;
    canvas.drawLine(Offset(x, 0), Offset(x, endY), paint);
    canvas.drawLine(Offset(x, midY), Offset(x + indentUnit * 0.6, midY), paint);
  }

  @override
  bool shouldRepaint(covariant _TreeGuidePainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.indentUnit != indentUnit ||
        oldDelegate.isLast != isLast ||
        oldDelegate.ancestorHasNext != ancestorHasNext;
  }
}
