import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import '../../models/manual_journal_model.dart';
import '../../providers/manual_journal_provider.dart';
import '../widgets/manual_journals_list_panel.dart';
import '../widgets/manual_journals_detail_panel.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';

class ManualJournalOverviewScreen extends ConsumerStatefulWidget {
  final String? initialJournalId;
  final String? initialSearchQuery;

  const ManualJournalOverviewScreen({
    super.key,
    this.initialJournalId,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<ManualJournalOverviewScreen> createState() =>
      _ManualJournalOverviewScreenState();
}

class _ManualJournalOverviewScreenState
    extends ConsumerState<ManualJournalOverviewScreen> {
  bool _forceWideTable = false;

  void _ensureRouteJournalSelection(ManualJournalState state) {
    final routeJournalId = widget.initialJournalId;
    if (routeJournalId == null || routeJournalId.isEmpty) return;
    if (state.selectedJournalId == routeJournalId) return;
    if (state.isLoading) return;
    if (state.failedJournalIds.contains(routeJournalId)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(manualJournalProvider.notifier).selectJournal(routeJournalId);
    });
  }

  String _statusLabel(ManualJournalStatus status) {
    switch (status) {
      case ManualJournalStatus.draft:
        return 'Draft';
      case ManualJournalStatus.posted:
        return 'Published';
      case ManualJournalStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(manualJournalProvider.notifier)
          .selectJournal(widget.initialJournalId);
    });
  }

  @override
  void didUpdateWidget(ManualJournalOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialJournalId != oldWidget.initialJournalId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(manualJournalProvider.notifier)
            .selectJournal(widget.initialJournalId);
      });
    }
  }

  Future<void> _handlePost(String id) async {
    final previousStatus = ref
        .read(manualJournalProvider)
        .selectedJournal
        ?.status;
    try {
      final updatedJournal = await ref
          .read(manualJournalProvider.notifier)
          .updateStatus(id, ManualJournalStatus.posted);
      if (mounted) {
        final fromLabel = _statusLabel(
          previousStatus ?? ManualJournalStatus.draft,
        );
        final toLabel = _statusLabel(updatedJournal.status);
        ZerpaiToast.success(
          context,
          'Status changed from $fromLabel to $toLabel.',
        );
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, ErrorHandler.getFriendlyMessage(e));
      }
    }
  }

  Future<void> _handleCancelJournal(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Journal'),
        content: const Text(
          'This will mark the draft journal as cancelled. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final previousStatus = ref
        .read(manualJournalProvider)
        .selectedJournal
        ?.status;
    try {
      final updatedJournal = await ref
          .read(manualJournalProvider.notifier)
          .updateStatus(id, ManualJournalStatus.cancelled);
      if (mounted) {
        final fromLabel = _statusLabel(
          previousStatus ?? ManualJournalStatus.draft,
        );
        final toLabel = _statusLabel(updatedJournal.status);
        ZerpaiToast.success(
          context,
          'Status changed from $fromLabel to $toLabel.',
        );
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, ErrorHandler.getFriendlyMessage(e));
      }
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Journal',
      message: 'This action cannot be undone. Delete this draft journal?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );

    if (confirmed != true) return;

    try {
      await ref.read(manualJournalProvider.notifier).deleteJournal(id);
      if (mounted) {
        ZerpaiToast.deleted(context, 'Journal');
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, ErrorHandler.getFriendlyMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manualJournalProvider);
    final selectedJournal = state.selectedJournal;
    final failedSelectedId =
        widget.initialJournalId != null &&
        state.failedJournalIds.contains(widget.initialJournalId);

    _ensureRouteJournalSelection(state);

    final screenWidth = MediaQuery.of(context).size.width;
    final bool shouldShowDetailPane =
        widget.initialJournalId != null &&
        screenWidth >= 1000 &&
        !_forceWideTable;

    final Widget listPanel = ManualJournalsListPanel(
      compact: shouldShowDetailPane,
      initialSearchQuery: widget.initialSearchQuery,
    );

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      actions: const [],
      child: !shouldShowDetailPane
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
                      ? ManualJournalDetailPanel(
                          journal: selectedJournal,
                          isBusy: state.isMutating,
                          onEdit: () => context.go(
                            AppRoutes.accountantManualJournalsEdit.replaceAll(
                              ':id',
                              selectedJournal.id,
                            ),
                            extra: selectedJournal,
                          ),
                          onPost: () => _handlePost(selectedJournal.id),
                          onCancelJournal: () =>
                              _handleCancelJournal(selectedJournal.id),
                          onDelete: () => _handleDelete(selectedJournal.id),
                          onClose: () {
                            context.go(AppRoutes.accountantManualJournals);
                          },
                        )
                      : failedSelectedId
                      ? ZErrorPlaceholder(
                          error: state.error ?? 'Failed to load journal.',
                          message: 'Failed to load journal overview',
                          onRetry: () {
                            ref
                                .read(manualJournalProvider.notifier)
                                .selectJournal(
                                  widget.initialJournalId,
                                  forceRefresh: true,
                                );
                          },
                        )
                      : const _ManualJournalDetailSkeleton(),
                ),
              ],
            ),
    );
  }
}

class _ManualJournalDetailSkeleton extends StatelessWidget {
  const _ManualJournalDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: const ZDocumentDetailSkeleton(),
    );
  }
}
