import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportFilterBar extends StatefulWidget {
  final List<Widget> filters;
  final VoidCallback? onRunReport;
  final String runLabel;
  final Widget? expandedPanel;
  final bool isExpandedPanelOpen;
  final VoidCallback? onDismissExpandedPanel;
  final bool showRunButton;
  final bool hasPendingFilterChanges;

  const ReportFilterBar({
    super.key,
    required this.filters,
    this.onRunReport,
    this.runLabel = 'Run Report',
    this.expandedPanel,
    this.isExpandedPanelOpen = false,
    this.onDismissExpandedPanel,
    this.showRunButton = true,
    this.hasPendingFilterChanges = false,
  });

  @override
  State<ReportFilterBar> createState() => _ReportFilterBarState();
}

class _ReportFilterBarState extends State<ReportFilterBar> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _syncScheduled = false;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    _scheduleOverlaySync();
  }

  @override
  void didUpdateWidget(covariant ReportFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleOverlaySync();
  }

  @override
  void dispose() {
    _isDisposing = true;
    _removeOverlay();
    super.dispose();
  }

  void _scheduleOverlaySync() {
    if (_syncScheduled || _isDisposing) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted || _isDisposing) return;
      _syncOverlayState();
    });
  }

  void _disposeOverlayEntry(OverlayEntry entry) {
    if (entry.mounted) {
      entry.remove();
    }
    entry.dispose();
  }

  void _syncOverlayState() {
    if (!mounted || _isDisposing) return;

    final shouldShow =
        widget.isExpandedPanelOpen && widget.expandedPanel != null;

    if (shouldShow) {
      if (_overlayEntry == null) {
        _showOverlay();
      } else if (_overlayEntry!.mounted) {
        _overlayEntry!.markNeedsBuild();
      }
    } else if (_overlayEntry != null) {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (!mounted ||
        _isDisposing ||
        _overlayEntry != null ||
        widget.expandedPanel == null) {
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final entry = OverlayEntry(builder: (_) => _buildOverlay());
    _overlayEntry = entry;
    overlay.insert(entry);
  }

  void _removeOverlay() {
    final entry = _overlayEntry;
    _overlayEntry = null;

    if (entry != null) {
      _disposeOverlayEntry(entry);
    }
  }

  Widget _buildOverlay() {
    if (!mounted || _isDisposing) return const SizedBox.shrink();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null ||
        !renderBox.hasSize ||
        widget.expandedPanel == null) {
      return const SizedBox.shrink();
    }

    final barSize = renderBox.size;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismissExpandedPanel,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, barSize.height),
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * -8),
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                width: barSize.width,
                child: widget.expandedPanel,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space24,
          AppTheme.space6,
          AppTheme.space24,
          AppTheme.space6,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppTheme.space8,
          runSpacing: AppTheme.space8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.filter,
                  size: AppTheme.space16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: AppTheme.space6),
                Text(
                  'Filters :',
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            ...widget.filters,
            if (widget.showRunButton)
              _ReportRunButton(
                label: widget.runLabel,
                onPressed: widget.onRunReport,
                hasPendingChanges: widget.hasPendingFilterChanges,
              ),
          ],
        ),
      ),
    );
  }
}

class ReportFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final bool showChevron;
  final bool showLabelColon;

  const ReportFilterChip({
    super.key,
    required this.label,
    required this.value,
    this.onPressed,
    this.leadingIcon,
    this.showChevron = true,
    this.showLabelColon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.bgLight,
      borderRadius: BorderRadius.circular(AppTheme.space8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.space8),
        child: Container(
          height: AppTheme.buttonHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(AppTheme.space8),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: AppTheme.space16,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: AppTheme.space8),
              ],
              Text(
                showLabelColon ? '$label : ' : label,
                style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
              ),
              if (value.isNotEmpty) ...[
                if (!showLabelColon) const SizedBox(width: AppTheme.space6),
                Text(
                  value,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
              if (showChevron) ...[
                const SizedBox(width: AppTheme.space8),
                const Icon(
                  LucideIcons.chevronDown,
                  size: AppTheme.space16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportRunButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool hasPendingChanges;

  const _ReportRunButton({
    required this.label,
    required this.onPressed,
    required this.hasPendingChanges,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: hasPendingChanges
            ? AppTheme.successDark
            : AppTheme.accentGreen,
        foregroundColor: AppTheme.backgroundColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
