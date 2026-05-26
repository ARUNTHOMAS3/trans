import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class CnGridHeader extends StatefulWidget {
  final String label;
  final bool center;

  const CnGridHeader({super.key, required this.label, this.center = false});

  @override
  State<CnGridHeader> createState() => _CnGridHeaderState();
}

class _CnGridHeaderState extends State<CnGridHeader> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            textAlign: widget.center ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isHovered ? AppTheme.primaryBlue : AppTheme.textSecondary,
            ),
          ),
          if (_isHovered) ...[
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronDown,
              size: 10,
              color: AppTheme.primaryBlue,
            ),
          ],
        ],
      ),
    );
  }
}
