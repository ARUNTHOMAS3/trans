import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ExpensesMoreSubMenuPanel extends StatelessWidget {
  final List<Widget> children;

  const ExpensesMoreSubMenuPanel({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class ExpensesMoreSubMenuItem extends StatefulWidget {
  final String label;
  final IconData? rightIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const ExpensesMoreSubMenuItem({
    super.key,
    required this.label,
    this.rightIcon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<ExpensesMoreSubMenuItem> createState() => _ExpensesMoreSubMenuItemState();
}

class _ExpensesMoreSubMenuItemState extends State<ExpensesMoreSubMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final showIndicator = widget.rightIcon != null &&
        (widget.isSelected || _hovered);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _hovered ? AppTheme.primaryBlueDark : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: _hovered
                        ? AppTheme.backgroundColor
                        : (widget.isSelected
                              ? AppTheme.primaryBlueDark
                              : AppTheme.textBody),
                    fontWeight: widget.isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (widget.rightIcon != null)
                SizedBox(
                  width: 14,
                  child: showIndicator
                      ? Icon(
                          widget.rightIcon,
                          size: 14,
                          color: _hovered
                              ? AppTheme.backgroundColor
                              : AppTheme.primaryBlueDark,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpensesMoreMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool hasChevron;
  final bool isActive;
  final VoidCallback onTap;

  const ExpensesMoreMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.hasChevron = false,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<ExpensesMoreMenuItem> createState() => _ExpensesMoreMenuItemState();
}

class _ExpensesMoreMenuItemState extends State<ExpensesMoreMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _hovered || widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: isHighlighted
              ? AppTheme.primaryBlueDark
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: isHighlighted
                    ? AppTheme.backgroundColor
                    : AppTheme.textBody,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isHighlighted
                        ? AppTheme.backgroundColor
                        : AppTheme.textBody,
                  ),
                ),
              ),
              if (widget.hasChevron)
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: isHighlighted
                      ? AppTheme.backgroundColor
                      : AppTheme.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
