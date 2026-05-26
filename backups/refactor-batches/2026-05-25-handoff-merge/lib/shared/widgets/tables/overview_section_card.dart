import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class OverviewSectionCard extends StatelessWidget {
  const OverviewSectionCard({
    super.key,
    required this.entries,
    this.title,
  });

  final String? title;
  final List<OverviewEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((title ?? '').trim().isNotEmpty) ...[
            Text(title!, style: AppTheme.sectionHeader),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 28,
            runSpacing: 10,
            children: entries
                .map(
                  (entry) => SizedBox(
                    width: 220,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.label.toUpperCase(), style: AppTheme.metaHelper),
                        const SizedBox(height: 4),
                        Text(entry.value, style: AppTheme.bodyText),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class OverviewEntry {
  const OverviewEntry({required this.label, required this.value});

  final String label;
  final String value;
}
