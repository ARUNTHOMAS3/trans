import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportPaginationFooter extends StatelessWidget {
  static const int visibilityThreshold = 10;

  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int>? onPageChanged;

  const ReportPaginationFooter({
    super.key,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    this.onPageChanged,
  });

  int get totalPages => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

  bool get shouldShow => totalCount > visibilityThreshold;

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();

    final start = totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = totalCount == 0 ? 0 : (page * pageSize).clamp(0, totalCount);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space20,
        AppTheme.space20,
        AppTheme.space20,
      ),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              style: AppTheme.bodyText.copyWith(color: AppTheme.textMuted),
              children: [
                const TextSpan(text: 'Total Count: '),
                TextSpan(
                  text: totalCount.toString(),
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            height: AppTheme.space32,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(AppTheme.space6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PaginationArrow(
                  icon: Icons.chevron_left,
                  enabled: page > 1,
                  onPressed: () => onPageChanged?.call(page - 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                  ),
                  child: Text(
                    '$start - $end',
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _PaginationArrow(
                  icon: Icons.chevron_right,
                  enabled: page < totalPages,
                  onPressed: () => onPageChanged?.call(page + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PaginationArrow({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return MouseRegion(
        cursor: SystemMouseCursors.forbidden,
        child: SizedBox(
          width: AppTheme.space32,
          height: AppTheme.space32,
          child: Icon(icon, size: AppTheme.space18, color: AppTheme.textMuted),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.space6),
        hoverColor: AppTheme.bgHover,
        child: SizedBox(
          width: AppTheme.space32,
          height: AppTheme.space32,
          child: Icon(
            icon,
            size: AppTheme.space18,
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }
}
