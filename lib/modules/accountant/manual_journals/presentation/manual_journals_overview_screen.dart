import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import '../models/manual_journal_model.dart';
import '../providers/manual_journal_provider.dart';
import 'widgets/manual_journals_list_panel.dart';
import 'widgets/manual_journals_detail_panel.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';

class ManualJournalOverviewScreen extends ConsumerStatefulWidget {
  final String? initialJournalId;
  const ManualJournalOverviewScreen({super.key, this.initialJournalId});

  @override
  ConsumerState<ManualJournalOverviewScreen> createState() =>
      _ManualJournalOverviewScreenState();
}

class _ManualJournalOverviewScreenState
    extends ConsumerState<ManualJournalOverviewScreen> {
  bool _forceWideTable = false;

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
    try {
      await ref
          .read(manualJournalProvider.notifier)
          .updateStatus(id, ManualJournalStatus.posted);
      if (mounted) {
        ZerpaiToast.success(context, 'Journal posted successfully');
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

    try {
      await ref
          .read(manualJournalProvider.notifier)
          .updateStatus(id, ManualJournalStatus.cancelled);
      if (mounted) {
        ZerpaiToast.success(context, 'Journal cancelled successfully');
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

    final screenWidth = MediaQuery.of(context).size.width;
    final bool showDesktopSplit =
        widget.initialJournalId != null &&
        selectedJournal != null &&
        screenWidth >= 1000 &&
        !_forceWideTable;

    final Widget listPanel = ManualJournalsListPanel(compact: showDesktopSplit);

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      actions: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Card(
              elevation: 0,
              margin: EdgeInsets.all(AppTheme.space12).copyWith(top: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.space8),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: !showDesktopSplit
                  ? listPanel
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 320, child: listPanel),
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: AppTheme.borderColor,
                        ),
                        Expanded(
                          flex: 7,
                          child: ManualJournalDetailPanel(
                            journal: selectedJournal,
                            isBusy: state.isMutating,
                            onEdit: () => context.go(
                              AppRoutes.accountantManualJournalsCreate,
                              extra: selectedJournal,
                            ),
                            onPost: () => _handlePost(selectedJournal.id),
                            onCancelJournal: () =>
                                _handleCancelJournal(selectedJournal.id),
                            onDelete: () => _handleDelete(selectedJournal.id),
                            onClose: () {
                              context.go(AppRoutes.accountantManualJournals);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
