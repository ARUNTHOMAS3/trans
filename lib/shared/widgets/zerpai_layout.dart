import 'package:flutter/material.dart';
import 'shortcut_handler.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/unsaved_changes_guard.dart';

class ZerpaiSearchShortcutScope extends StatefulWidget {
  final Widget child;

  const ZerpaiSearchShortcutScope({super.key, required this.child});

  static ZerpaiSearchShortcutScopeState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ZerpaiSearchShortcutScopeState>();
  }

  @override
  State<ZerpaiSearchShortcutScope> createState() =>
      ZerpaiSearchShortcutScopeState();
}

class ZerpaiSearchShortcutScopeState extends State<ZerpaiSearchShortcutScope> {
  final List<FocusNode> _registeredSearchFields = <FocusNode>[];

  void registerSearchField(FocusNode node) {
    if (_registeredSearchFields.contains(node)) {
      return;
    }
    _registeredSearchFields.add(node);
  }

  void unregisterSearchField(FocusNode node) {
    _registeredSearchFields.remove(node);
  }

  void focusPrimarySearchField() {
    for (final node in _registeredSearchFields) {
      if (node.canRequestFocus) {
        node.requestFocus();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class ZerpaiLayout extends StatelessWidget {
  final Widget child;
  final String pageTitle;
  final bool enableBodyScroll;
  final ValueChanged<String>? onNavigate;
  final Widget? floatingActionButton;
  final Widget? footer;
  final List<Widget>? actions;
  final bool useHorizontalPadding;
  final bool useTopPadding;
  final double? horizontalPaddingValue;
  final VoidCallback? onSave;
  final VoidCallback? onPublish;
  final VoidCallback? onCancel;
  final VoidCallback? onSearch;
  final bool isDirty;
  final FocusNode? searchFocusNode;
  final Widget? endDrawer;

  const ZerpaiLayout({
    super.key,
    required this.child,
    required this.pageTitle,
    this.enableBodyScroll = true,
    this.onNavigate,
    this.footer,
    this.floatingActionButton,
    this.actions,
    this.useHorizontalPadding = true,
    this.useTopPadding = true,
    this.horizontalPaddingValue,
    this.onSave,
    this.onPublish,
    this.onCancel,
    this.onSearch,
    this.isDirty = false,
    this.searchFocusNode,
    this.endDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return ZerpaiSearchShortcutScope(
      child: Builder(
        builder: (scopeContext) => UnsavedChangesGuard(
          isDirty: isDirty,
          onDiscardChanges: onCancel,
          child: ShortcutHandler(
            onSave: onSave,
            onPublish: onPublish,
            onCancel: onCancel,
            onSearch:
                onSearch ??
                () => ZerpaiSearchShortcutScope.maybeOf(
                  scopeContext,
                )?.focusPrimarySearchField(),
            isDirty: isDirty,
            searchFocusNode: searchFocusNode,
            child: _buildScaffold(context),
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double responsivePadding = screenWidth < 1000 ? 16.0 : 40.0;
    final double horizontalPadding =
        horizontalPaddingValue ??
        (useHorizontalPadding ? responsivePadding : 0);
    final double topPadding = useTopPadding ? 24 : 0;
    final double bottomPadding = 32;

    final Widget bodyContent = enableBodyScroll
        ? SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: child,
          )
        : Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: child,
          );

    final bool showHeader =
        pageTitle.isNotEmpty || (actions != null && actions!.isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      endDrawer: endDrawer,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Container(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                0,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isNarrow = constraints.maxWidth < 600;
                  return isNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pageTitle,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (actions != null && actions!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: actions!,
                              ),
                            ],
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Text(
                                pageTitle,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (actions != null && actions!.isNotEmpty) ...[
                              const SizedBox(width: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: actions!,
                              ),
                            ],
                          ],
                        );
                },
              ),
            ),
          Expanded(child: bodyContent),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}
