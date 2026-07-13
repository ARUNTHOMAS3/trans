import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ZExpandableTabs extends StatefulWidget {
  final List<String> tabs;
  final List<Widget> children;
  final int initialIndex;
  final bool initiallyExpanded;
  final bool showBorder;
  final EdgeInsets contentPadding;

  const ZExpandableTabs({
    Key? key,
    required this.tabs,
    required this.children,
    this.initialIndex = 0,
    this.initiallyExpanded = false,
    this.showBorder = true,
    this.contentPadding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  State<ZExpandableTabs> createState() => _ZExpandableTabsState();
}

class _ZExpandableTabsState extends State<ZExpandableTabs> {
  late int _activeIndex;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.initialIndex;
    _isExpanded = widget.initiallyExpanded;
  }

  Widget _buildTabTitle(String title, bool isSelected) {
    final parts = title.split(' ');
    if (parts.length >= 2 && int.tryParse(parts.last) != null) {
      final text = parts.sublist(0, parts.length - 1).join(' ');
      final count = parts.last;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: AppTheme.bodyText.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count,
              style: AppTheme.bodyText.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      title,
      style: AppTheme.bodyText.copyWith(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: widget.showBorder
            ? Border.all(color: AppTheme.borderLight)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ...List.generate(widget.tabs.length, (index) {
                    final isSelected = index == _activeIndex;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _activeIndex = index;
                          _isExpanded = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: isSelected && _isExpanded
                              ? const Border(
                                  bottom: BorderSide(
                                    color: AppTheme.primaryBlue,
                                    width: 2,
                                  ),
                                )
                              : null,
                        ),
                        child: Center(
                          child: _buildTabTitle(widget.tabs[index], isSelected),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  Icon(
                    _isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Content
          if (_isExpanded) ...[
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: widget.contentPadding,
              child: widget.children[_activeIndex],
            ),
          ],
        ],
      ),
    );
  }
}
