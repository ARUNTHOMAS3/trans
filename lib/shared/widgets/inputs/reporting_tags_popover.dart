import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_adaptive_menu.dart';

/// Reusable popover for configuring Reporting Tags on line items.
///
/// Usage:
/// ```dart
/// showReportingTagsPopover(
///   context: context,
///   link: item.reportingTagsLink,
///   selectedTags: item.selectedReportingTags,
///   onSave: (updatedTags) {
///     setState(() {
///       item.selectedReportingTags = updatedTags;
///     });
///   },
/// );
/// ```
OverlayEntry? showReportingTagsPopover({
  required BuildContext context,
  required LayerLink link,
  required Map<String, String> selectedTags,
  required ValueChanged<Map<String, String>> onSave,
  VoidCallback? onClose,
  Map<String, List<String>>? tagOptions,
}) {
  OverlayEntry? entry;

  entry = ZAdaptiveMenu.show(
    context: context,
    link: link,
    width: 500,
    maxHeight: 380,
    alignLeft: true,
    padding: EdgeInsets.zero,
    borderRadius: 8,
    onClose: () {
      entry?.remove();
      onClose?.call();
    },
    builder: (ctx) => ReportingTagsPopoverContent(
      selectedTags: selectedTags,
      tagOptions: tagOptions,
      onSave: (tags) {
        onSave(tags);
        entry?.remove();
        onClose?.call();
      },
      onCancel: () {
        entry?.remove();
        onClose?.call();
      },
    ),
  );

  return entry;
}

class ReportingTagsPopoverContent extends StatefulWidget {
  final Map<String, String> selectedTags;
  final Map<String, List<String>>? tagOptions;
  final ValueChanged<Map<String, String>> onSave;
  final VoidCallback onCancel;

  const ReportingTagsPopoverContent({
    super.key,
    required this.selectedTags,
    this.tagOptions,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ReportingTagsPopoverContent> createState() =>
      _ReportingTagsPopoverContentState();
}

class _ReportingTagsPopoverContentState
    extends State<ReportingTagsPopoverContent> {
  late Map<String, String> _tempTags;
  final ScrollController _scrollController = ScrollController();

  static const Map<String, List<String>> _defaultTagOptions = {
    'ADGF': ['None'],
    'shedule': ['None'],
    'demo adavced reporting tag': ['None'],
  };

  @override
  void initState() {
    super.initState();
    _tempTags = Map<String, String>.from(widget.selectedTags);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.tagOptions ?? _defaultTagOptions;
    final tagEntries = options.entries.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Reporting Tags',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  for (int i = 0; i < tagEntries.length; i += 2) ...[
                    if (i > 0) const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTagDropdown(
                            tagEntries[i].key,
                            tagEntries[i].value,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: i + 1 < tagEntries.length
                              ? _buildTagDropdown(
                                  tagEntries[i + 1].key,
                                  tagEntries[i + 1].value,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () => widget.onSave(_tempTags),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.borderLight),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagDropdown(String tagName, List<String> items) {
    final currentVal = _tempTags[tagName] ?? (items.isNotEmpty ? items.first : 'None');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tagName,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        FormDropdown<String>(
          items: items,
          value: items.contains(currentVal) ? currentVal : items.first,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _tempTags[tagName] = val;
              });
            }
          },
          hint: 'None',
        ),
      ],
    );
  }
}
