import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class TransactionSeriesOption {
  final String id;
  final String name;
  const TransactionSeriesOption({required this.id, required this.name});

  static const TransactionSeriesOption defaultSeries = TransactionSeriesOption(
    id: 'default',
    name: 'Default Transaction Series',
  );

  @override
  bool operator ==(Object other) =>
      other is TransactionSeriesOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ─── Widget ──────────────────────────────────────────────────────────────────

/// Universal Transaction Series dropdown matching the Zoho design.
///
/// - Always shows "Default Transaction Series" highlighted at the top.
/// - When [multiSelect] is true the trigger shows chips; otherwise shows the
///   single selected name.
/// - [onAddTap] is called when the user taps "+ Add Transaction Series".
class TransactionSeriesDropdown extends StatefulWidget {
  /// Available user-created series (do NOT include the Default entry here).
  final List<TransactionSeriesOption> series;

  /// Multi-select: selected IDs.  Single-select: first element is the value.
  final List<String> selectedIds;

  /// Called with the new list of selected IDs after every change.
  final ValueChanged<List<String>> onChanged;

  /// Whether multiple series can be selected at once.
  final bool multiSelect;

  /// Called when "Add Transaction Series" footer is tapped.
  final VoidCallback onAddTap;

  /// Accent color used to highlight the Default option and the footer link.
  final Color accentColor;

  final String? errorText;
  final bool includeDefaultOption;
  final String placeholder;

  const TransactionSeriesDropdown({
    super.key,
    required this.series,
    required this.selectedIds,
    required this.onChanged,
    required this.onAddTap,
    required this.accentColor,
    this.multiSelect = false,
    this.errorText,
    this.includeDefaultOption = true,
    this.placeholder = 'Add Transaction Series',
  });

  @override
  State<TransactionSeriesDropdown> createState() =>
      _TransactionSeriesDropdownState();
}

class _TransactionSeriesDropdownState
    extends State<TransactionSeriesDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// Key on the trigger container so we can measure its exact rendered size,
  /// independent of any error-text that lives below it in the Column.
  final GlobalKey _triggerKey = GlobalKey();

  static const double _fieldHeight = 36.0;
  static const double _rowHeight = 36.0;

  @override
  void dispose() {
    _overlay?.remove();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ─── Overlay control ───────────────────────────────────────────────────────

  void _open() {
    if (_overlay != null) return;
    final entry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(entry);
    _overlay = entry;
    setState(() => _isOpen = true);
    // Recalculate offset after first layout so RenderBox sizes are available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _overlay?.markNeedsBuild();
        _searchFocus.requestFocus();
      }
    });
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    _searchCtrl.clear();
    if (mounted) setState(() => _isOpen = false);
  }

  void _toggle() => _isOpen ? _close() : _open();

  void _rebuild() => _overlay?.markNeedsBuild();

  // ─── Selection ─────────────────────────────────────────────────────────────

  void _select(String id) {
    if (widget.multiSelect) {
      final next = List<String>.from(widget.selectedIds);
      if (next.contains(id)) {
        next.remove(id);
      } else {
        next.add(id);
      }
      widget.onChanged(next);
      _rebuild();
    } else {
      widget.onChanged([id]);
      _close();
    }
  }

  void _removeChip(String id) {
    final next = List<String>.from(widget.selectedIds)..remove(id);
    widget.onChanged(next);
  }

  // ─── Overlay builder ───────────────────────────────────────────────────────

  Offset _calcOffset(double overlayHeight) {
    // Use the trigger's own RenderBox (via GlobalKey) — NOT the outer Column.
    final triggerBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (triggerBox == null || !triggerBox.hasSize) {
      return Offset(0, _fieldHeight + 4);
    }
    final fieldSize = triggerBox.size;

    if (!mounted) return Offset(0, fieldSize.height + 4);

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (overlayBox == null || !overlayBox.hasSize) {
      return Offset(0, fieldSize.height + 4);
    }

    final targetGlobal =
        triggerBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    final spaceBelow =
        overlayBox.size.height - (targetGlobal.dy + fieldSize.height);
    final spaceAbove = targetGlobal.dy;
    final showAbove = spaceBelow < overlayHeight && spaceAbove > spaceBelow;

    final rightOverflow =
        (targetGlobal.dx + fieldSize.width) - overlayBox.size.width;

    return Offset(
      rightOverflow > 0 ? -(rightOverflow + 8) : 0,
      showAbove ? -(overlayHeight + 4) : fieldSize.height + 4,
    );
  }

  Widget _buildOverlay() {
    if (!mounted) return const SizedBox.shrink();

    const double overlayHeight = 280;

    // Width comes from the trigger key's render box (same source as _calcOffset)
    final triggerBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    final triggerWidth = triggerBox?.size.width ?? 300.0;

    return Stack(
      children: [
        // Dismiss on outside tap
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _close(),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: _calcOffset(overlayHeight),
          child: Material(
            elevation: 6,
            color: Colors.transparent,
            child: Container(
              width: triggerWidth,
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: StatefulBuilder(
                builder: (ctx, setSS) {
                  final query = _searchCtrl.text.toLowerCase().trim();

                  // Should "Default Transaction Series" appear?
                  final showDefault = widget.includeDefaultOption &&
                      'default transaction series'.contains(query);

                  // Filter user-created series
                  final filtered = widget.series
                      .where((s) =>
                          query.isEmpty ||
                          s.name.toLowerCase().contains(query))
                      .toList();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SizedBox(
                          height: 32,
                          child: TextField(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            style: const TextStyle(fontSize: 13),
                            onChanged: (_) => setSS(() {}),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Search',
                              hintStyle: const TextStyle(
                                  fontSize: 13, color: AppTheme.textMuted),
                              prefixIcon: const Icon(Icons.search,
                                  size: 15, color: AppTheme.textMuted),
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                    color: AppTheme.borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                    color: AppTheme.borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                    color: widget.accentColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderColor),

                      // Items list
                      Flexible(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: [
                            // Default Transaction Series
                            if (showDefault)
                              _buildRow(
                                label: 'Default Transaction Series',
                                id: TransactionSeriesOption.defaultSeries.id,
                                isDefault: true,
                                setSS: setSS,
                              ),

                            // User-created series
                            for (final s in filtered)
                              _buildRow(
                                label: s.name,
                                id: s.id,
                                isDefault: false,
                                setSS: setSS,
                              ),

                            if (!showDefault && filtered.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 12),
                                child: Text(
                                  'No results',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMuted),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Footer: + Add Transaction Series
                      const Divider(height: 1, color: AppTheme.borderColor),
                      InkWell(
                        onTap: () {
                          _close();
                          widget.onAddTap();
                        },
                        hoverColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Icon(LucideIcons.plusCircle,
                                  size: 14, color: AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Text(
                                'Add Transaction Series',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow({
    required String label,
    required String id,
    required bool isDefault,
    required StateSetter setSS,
  }) {
    final isSelected = widget.selectedIds.contains(id);
    final rowColor = isDefault
        ? AppTheme.primaryBlue
        : isSelected
            ? AppTheme.infoBg
            : Colors.white;
    return Material(
      color: rowColor,
      child: InkWell(
        onTap: () {
          _select(id);
          setSS(() {});
        },
        hoverColor: isDefault
            ? AppTheme.primaryBlueDark
            : AppTheme.primaryBlue.withValues(alpha: 0.08),
        child: SizedBox(
          height: _rowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isDefault || isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isDefault
                          ? Colors.white
                          : isSelected
                              ? AppTheme.primaryBlueDark
                              : AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected && !isDefault)
                  Icon(Icons.check, size: 15, color: widget.accentColor),
                if (isSelected && isDefault)
                  const Icon(Icons.check, size: 15, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Trigger field ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggle,
            child: Container(
              key: _triggerKey,
              constraints: const BoxConstraints(minHeight: _fieldHeight),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: hasError
                      ? AppTheme.errorRed
                      : _isOpen
                          ? widget.accentColor
                          : AppTheme.borderColor,
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTriggerContent()),
                  const SizedBox(width: 6),
                  Icon(
                    _isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: _isOpen ? widget.accentColor : AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(fontSize: 11, color: AppTheme.errorRed),
          ),
        ],
      ],
    );
  }

  Widget _buildTriggerContent() {
    if (widget.selectedIds.isEmpty) {
      return Text(
        widget.placeholder,
        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
      );
    }

    if (!widget.multiSelect) {
      // Single select — just show the name
      final id = widget.selectedIds.first;
      final label = id == TransactionSeriesOption.defaultSeries.id
          ? 'Default Transaction Series'
          : widget.series
                  .where((s) => s.id == id)
                  .firstOrNull
                  ?.name ??
              id;
      return Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Multi-select — chips
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: widget.selectedIds.map((id) {
        final label = id == TransactionSeriesOption.defaultSeries.id
            ? 'Default Transaction Series'
            : widget.series
                    .where((s) => s.id == id)
                    .firstOrNull
                    ?.name ??
                id;
        return _Chip(
          label: label,
          accentColor: widget.accentColor,
          onRemove: () => _removeChip(id),
        );
      }).toList(),
    );
  }
}

// ─── Chip widget ─────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color accentColor;
  final VoidCallback onRemove;

  const _Chip({
    required this.label,
    required this.accentColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 4, 3),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 13, color: accentColor),
          ),
        ],
      ),
    );
  }
}
