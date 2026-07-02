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
                          _isExpanded = true; // Expand if clicked on tab
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
                          child: Text(
                            widget.tabs[index],
                            style: AppTheme.bodyText.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                            ),
                          ),
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
