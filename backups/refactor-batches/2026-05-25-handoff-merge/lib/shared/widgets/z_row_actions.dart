import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// Standard Action Menu used in ERP table rows.
///
/// Usage:
/// ```dart
/// ZRowActions(
///   onEdit: () => _edit(item),
///   onDelete: () => _delete(item),
///   onDuplicate: () => _duplicate(item),
///   additionalActions: [
///     ZRowAction(
///       label: 'Mark as Paid',
///       icon: LucideIcons.check,
///       onPressed: () => _markPaid(item),
///     ),
///   ],
/// )
/// ```
class ZRowActions extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final List<ZRowAction>? additionalActions;
  final double width;

  const ZRowActions({
    super.key,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.additionalActions,
    this.width = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: PopupMenuButton<_ActionType>(
        icon: const Icon(
          LucideIcons.moreVertical,
          size: AppTheme.iconSize,
          color: AppTheme.textSecondary,
        ),
        color: AppTheme.backgroundColor,
        surfaceTintColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.space6),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        onSelected: (type) {
          switch (type) {
            case _ActionType.edit:
              onEdit?.call();
            case _ActionType.duplicate:
              onDuplicate?.call();
            case _ActionType.delete:
              onDelete?.call();
            case _ActionType.additional:
              // Handled via the value itself if we passed the callback
              break;
          }
        },
        itemBuilder: (context) {
          final items = <PopupMenuEntry<_ActionType>>[];

          if (onEdit != null) {
            items.add(_buildItem(_ActionType.edit, LucideIcons.pencil, 'Edit'));
          }
          if (onDuplicate != null) {
            items.add(_buildItem(_ActionType.duplicate, LucideIcons.copy, 'Duplicate'));
          }

          if (additionalActions != null) {
            for (final action in additionalActions!) {
              items.add(
                PopupMenuItem(
                  onTap: action.onPressed,
                  value: _ActionType.additional,
                  height: 36,
                  child: Row(
                    children: [
                      Icon(action.icon, size: 14, color: AppTheme.textPrimary),
                      const SizedBox(width: AppTheme.space8),
                      Text(action.label, style: AppTheme.tableCell),
                    ],
                  ),
                ),
              );
            }
          }

          if (onDelete != null) {
            if (items.isNotEmpty) items.add(const PopupMenuDivider(height: 1));
            items.add(
              _buildItem(
                _ActionType.delete,
                LucideIcons.trash2,
                'Delete',
                color: AppTheme.errorRed,
              ),
            );
          }

          return items;
        },
      ),
    );
  }

  PopupMenuItem<_ActionType> _buildItem(
    _ActionType type,
    IconData icon,
    String label, {
    Color color = AppTheme.textPrimary,
  }) {
    return PopupMenuItem(
      value: type,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppTheme.space8),
          Text(label, style: AppTheme.tableCell.copyWith(color: color)),
        ],
      ),
    );
  }
}

enum _ActionType { edit, duplicate, delete, additional }

class ZRowAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const ZRowAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}
