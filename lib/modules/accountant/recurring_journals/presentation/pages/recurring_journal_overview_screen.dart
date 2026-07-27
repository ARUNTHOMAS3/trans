import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import '../../providers/recurring_journal_provider.dart';
import '../widgets/recurring_journals_list_panel.dart';
import '../widgets/recurring_journals_detail_panel.dart';

class RecurringJournalOverviewScreen extends ConsumerStatefulWidget {
  final String? initialJournalId;
  final String? initialSearchQuery;

  const RecurringJournalOverviewScreen({
    super.key,
    this.initialJournalId,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<RecurringJournalOverviewScreen> createState() =>
      _RecurringJournalOverviewScreenState();
}

class _RecurringJournalOverviewScreenState
    extends ConsumerState<RecurringJournalOverviewScreen> {
  final bool _forceWideTable = false;

  void _ensureRouteJournalSelection(RecurringJournalState state) {
    final routeJournalId = widget.initialJournalId;
    if (routeJournalId == null || routeJournalId.isEmpty) return;
    if (state.selectedJournalId == routeJournalId || state.isLoading) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(recurringJournalProvider.notifier).selectJournal(routeJournalId);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(recurringJournalProvider.notifier)
          .selectJournal(widget.initialJournalId);
    });
  }

  @override
  void didUpdateWidget(RecurringJournalOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialJournalId != oldWidget.initialJournalId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(recurringJournalProvider.notifier)
            .selectJournal(widget.initialJournalId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recurringJournalProvider);
    final selectedJournal = state.selectedJournal;
    final routeJournalExists = state.journals.any(
      (journal) => journal.id == widget.initialJournalId,
    );

    _ensureRouteJournalSelection(state);

    final screenWidth = MediaQuery.of(context).size.width;
    final bool showDesktopSplit =
        widget.initialJournalId != null &&
        screenWidth >= 1000 &&
        !_forceWideTable;

    final Widget listPanel = RecurringJournalsListPanel(
      compact: showDesktopSplit,
      initialSearchQuery: widget.initialSearchQuery,
    );

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      actions: const [],
      child: !showDesktopSplit
          ? listPanel
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 360, child: listPanel),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppTheme.borderLight,
                ),
                Expanded(
                  child: selectedJournal != null
                      ? RecurringJournalDetailPanel(
                          journal: selectedJournal,
                          onClose: () =>
                              context.go(AppRoutes.accountantRecurringJournals),
                          onEdit: () => context.go(
                            AppRoutes.accountantRecurringJournalsCreate,
                            extra: selectedJournal,
                          ),
                        )
                      : state.error != null
                      ? ZErrorPlaceholder(
                          error: state.error!,
                          message: 'Failed to load recurring journal',
                          onRetry: () => ref
                              .read(recurringJournalProvider.notifier)
                              .fetchJournals(),
                        )
                      : !state.isLoading && !routeJournalExists
                      ? ZErrorPlaceholder(
                          error: 'Recurring journal was not found.',
                          message: 'Unable to open recurring journal',
                          onRetry: () => ref
                              .read(recurringJournalProvider.notifier)
                              .fetchJournals(),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(20),
                          child: ZDocumentDetailSkeleton(),
                        ),
                ),
              ],
            ),
    );
  }
}
