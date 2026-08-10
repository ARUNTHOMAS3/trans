import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportExportMenuItem extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double indent;
  final Widget? trailing;

  const ReportExportMenuItem({
    super.key,
    required this.label,
    this.onTap,
    this.indent = 0,
    this.trailing,
  });

  @override
  State<ReportExportMenuItem> createState() => _ReportExportMenuItemState();
}

class _ReportExportMenuItemState extends State<ReportExportMenuItem> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isHovered ? AppTheme.primaryBlue : AppTheme.backgroundColor;
    final foregroundColor = _isHovered ? AppTheme.backgroundColor : AppTheme.textPrimary;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.space4),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppTheme.space4),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: EdgeInsets.fromLTRB(
              AppTheme.space12 + widget.indent,
              AppTheme.space10,
              AppTheme.space12,
              AppTheme.space10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppTheme.tableCell.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReportExportSectionHeader extends StatelessWidget {
  final String label;

  const ReportExportSectionHeader({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space12,
        AppTheme.space12,
        AppTheme.space12,
        AppTheme.space8,
      ),
      child: Text(
        label,
        style: AppTheme.metaHelper.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

