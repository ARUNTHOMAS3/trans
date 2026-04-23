import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import '../providers/recurring_journal_provider.dart';
import 'widgets/recurring_journals_list_panel.dart';
import 'widgets/recurring_journals_detail_panel.dart';
import 'widgets/recurring_journal_import_export_dialogs.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

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

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => RecurringJournalImportDialog(
        onImport: () {
          Navigator.pop(context);
          ZerpaiToast.show(context, 'Import starting...');
        },
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => RecurringJournalExportDialog(
        onExport: () {
          Navigator.pop(context);
          ZerpaiToast.show(context, 'Exporting journals...');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recurringJournalProvider);
    final selectedJournal = state.selectedJournal;

    final screenWidth = MediaQuery.of(context).size.width;
    final bool showDesktopSplit =
        widget.initialJournalId != null &&
        selectedJournal != null &&
        screenWidth >= 1000 &&
        !_forceWideTable;

    final Widget listPanel = RecurringJournalsListPanel(
      compact: showDesktopSplit,
      initialSearchQuery: widget.initialSearchQuery,
    );

    return ZerpaiLayout(
      pageTitle: '', // Empty title as per ManualJournal design
      enableBodyScroll: false,
      actions: [
        ElevatedButton.icon(
          onPressed: () =>
              context.go(AppRoutes.accountantRecurringJournalsCreate),
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('New'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: 11,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.space4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 38,
          width: 38,
          child: PopupMenuButton<String>(
            tooltip: 'More actions',
            onSelected: (value) {
              if (value == 'import') {
                _showImportDialog();
              } else if (value == 'export') {
                _showExportDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.download,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(width: 8),
                    Text('Import Recurring Journals'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.upload,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(width: 8),
                    Text('Export Recurring Journals'),
                  ],
                ),
              ),
            ],
            offset: const Offset(0, 42),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.space8),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            color: Colors.white,
            padding: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.space4),
                border: Border.all(color: AppTheme.borderColor),
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.moreHorizontal,
                size: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
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
                        SizedBox(width: 360, child: listPanel),
                        const VerticalDivider(
                          width: 1,
                          color: AppTheme.borderColor,
                        ),
                        Expanded(
                          child: RecurringJournalDetailPanel(
                            journal: selectedJournal,
                            onClose: () =>
                                context.go(AppRoutes.accountantRecurringJournals),
                            onEdit: () => context.go(
                              AppRoutes.accountantRecurringJournalsCreate,
                              extra: selectedJournal,
                            ),
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
