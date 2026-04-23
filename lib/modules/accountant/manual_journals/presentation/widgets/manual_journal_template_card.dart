import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/models/manual_journal_model.dart';

class ManualJournalTemplateCard extends StatefulWidget {
  final ManualJournalTemplate template;
  final VoidCallback? onSelect;
  final List<Widget>? actions;

  const ManualJournalTemplateCard({
    super.key,
    required this.template,
    this.onSelect,
    this.actions,
  });

  @override
  State<ManualJournalTemplateCard> createState() =>
      _ManualJournalTemplateCardState();
}

class _ManualJournalTemplateCardState extends State<ManualJournalTemplateCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onSelect,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(8),
                    bottomLeft: Radius.circular(_isExpanded ? 0 : 8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.template.templateName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                border: Border.all(color: AppTheme.borderColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.template.currency,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.template.items.length} lines • ${widget.template.reportingMethod.replaceAll('_', ' ')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.actions != null) ...widget.actions!,
              IconButton(
                icon: Icon(
                  _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const SizedBox(width: 4),
            ],
          ),
          if (_isExpanded) _buildDetails(),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: widget.template.items.map((item) {
          final isDebit = (item.debit > 0) || (item.type == 'debit');
          String amountOrType;
          if (widget.template.enterAmount) {
            final val = isDebit ? item.debit : item.credit;
            amountOrType = '${isDebit ? "Dr" : "Cr"} ${val.toStringAsFixed(2)}';
          } else {
            amountOrType = item.type?.toUpperCase() ?? '-';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.accountName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (item.contactId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.contactType != null
                                ? 'With ${item.contactType} Contact'
                                : 'With Contact',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (item.description?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.description ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  amountOrType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDebit
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
