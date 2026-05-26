import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class DocumentViewToggle extends StatelessWidget {
  const DocumentViewToggle({
    super.key,
    required this.showPdfView,
    required this.onChanged,
    this.label = 'Show PDF View',
  });

  final bool showPdfView;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: showPdfView,
              onChanged: onChanged,
              activeTrackColor: AppTheme.primaryBlue,
              activeThumbColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
