import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';

/// Shared header compatibility owner for settings handoff pages.
class SettingsPageHeader extends StatefulWidget {
  const SettingsPageHeader({
    super.key,
    this.orgName,
    this.searchController,
    this.searchFocusNode,
    this.searchItems = const <SettingsSearchItem>[],
    this.showBackButton = true,
    this.onBack,
  });

  final String? orgName;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final List<SettingsSearchItem> searchItems;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  State<SettingsPageHeader> createState() => _SettingsPageHeaderState();
}

class _SettingsPageHeaderState extends State<SettingsPageHeader> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;
  late final bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.searchController == null;
    _ownsFocusNode = widget.searchFocusNode == null;
    _controller = widget.searchController ?? TextEditingController();
    _focusNode = widget.searchFocusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayOrgName = widget.orgName?.trim().isNotEmpty == true
        ? widget.orgName!.trim()
        : 'Your Organization';

    void goBack() {
      if (widget.onBack != null) {
        widget.onBack!();
        return;
      }
      if (context.canPop()) {
        context.pop();
        return;
      }
      context.go(AppRoutes.settings);
    }

    final identity = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.warningBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: const Icon(
            LucideIcons.settings2,
            size: 20,
            color: AppTheme.warningOrange,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All Settings', style: AppTheme.pageTitle),
              const SizedBox(height: AppTheme.space4),
              Text(
                displayOrgName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final back = IconButton(
      onPressed: goBack,
      icon: const Icon(LucideIcons.chevronLeft, size: 20),
      tooltip: 'Back to settings',
      style: IconButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        side: const BorderSide(color: AppTheme.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final close = TextButton.icon(
      onPressed: () => context.go(AppRoutes.home),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        backgroundColor: AppTheme.bgLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
      label: const Text('Close Settings'),
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space16,
        AppTheme.space24,
        AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          if (compact) {
            return Row(
              children: [
                if (widget.showBackButton) ...[
                  back,
                  const SizedBox(width: AppTheme.space12),
                ],
                Expanded(child: identity),
                const SizedBox(width: AppTheme.space12),
                IconButton(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(LucideIcons.x, size: 18),
                  tooltip: 'Close settings',
                ),
              ],
            );
          }

          return Row(
            children: [
              if (widget.showBackButton) ...[
                back,
                const SizedBox(width: AppTheme.space12),
              ],
              SizedBox(width: 300, child: identity),
              const SizedBox(width: AppTheme.space24),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SettingsSearchField(
                      controller: _controller,
                      focusNode: _focusNode,
                      items: widget.searchItems,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space24),
              close,
            ],
          );
        },
      ),
    );
  }
}
