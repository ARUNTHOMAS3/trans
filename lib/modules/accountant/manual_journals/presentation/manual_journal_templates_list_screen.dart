import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/providers/manual_journal_template_provider.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/widgets/manual_journal_template_card.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/models/manual_journal_model.dart';

class ManualJournalTemplatesListScreen extends ConsumerWidget {
  const ManualJournalTemplatesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(manualJournalTemplateProvider);

    return ZerpaiLayout(
      pageTitle: 'Manual Journal Templates',
      enableBodyScroll: false,
      actions: [
        ElevatedButton.icon(
          onPressed: () =>
              context.push(AppRoutes.accountantJournalTemplateCreation),
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('New Template'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: () => context.go(AppRoutes.accountantManualJournals),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.borderColor),
            foregroundColor: AppTheme.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text('Back to Journals'),
        ),
      ],
      child: state.isLoading
          ? Skeletonizer(
              ignoreContainers: true,
              enabled: true,
              child: const ZListSkeleton(itemCount: 6),
            )
          : state.error != null
          ? Center(child: Text('Error: ${state.error}'))
          : state.templates.isEmpty
          ? _buildEmptyState(context)
          : _buildTemplatesList(context, state, ref),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.fileText, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No templates created yet',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                context.push(AppRoutes.accountantJournalTemplateCreation),
            child: const Text('Create First Template'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList(
    BuildContext context,
    ManualJournalTemplateState state,
    WidgetRef ref,
  ) {
    return _PaginatedTemplatesList(templates: state.templates, ref: ref);
  }
}

class _PaginatedTemplatesList extends StatefulWidget {
  final List<ManualJournalTemplate> templates;
  final WidgetRef ref;

  const _PaginatedTemplatesList({required this.templates, required this.ref});

  @override
  State<_PaginatedTemplatesList> createState() =>
      _PaginatedTemplatesListState();
}

class _PaginatedTemplatesListState extends State<_PaginatedTemplatesList> {
  static const int _pageSize = 20;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    // If we have fewer items than the page size, we don't need pagination.
    // However, if the user requested pagination "controls", we can show them
    // disabled or simply show "Page 1 of 1" for consistency if preferred.
    // For now, let's just paginate if the list is long enough.

    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize < widget.templates.length)
        ? startIndex + _pageSize
        : widget.templates.length;

    // Safety check just in case templates changed and currentPage is out of bounds
    if (startIndex >= widget.templates.length && widget.templates.isNotEmpty) {
      // Reset to first page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentPage = 0);
      });
    }

    final currentItems = (startIndex < widget.templates.length)
        ? widget.templates.sublist(startIndex, endIndex)
        : <ManualJournalTemplate>[];

    final totalPages = (widget.templates.length / _pageSize).ceil();
    // Ensure at least 1 page
    final displayTotalPages = totalPages == 0 ? 1 : totalPages;

    final scrollController = ScrollController();
    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: ListView.separated(
              controller: scrollController,
              itemCount: currentItems.length,
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final template = currentItems[index];
                return ManualJournalTemplateCard(
                  template: template,
                  onSelect: null, // Just viewing in the list
                  actions: [
                    IconButton(
                      icon: const Icon(LucideIcons.copy, size: 18),
                      tooltip: 'Create Journal',
                      onPressed: () {
                        context.push(
                          AppRoutes.accountantManualJournalsCreate,
                          extra: template,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: AppTheme.errorRed,
                      ),
                      onPressed: () async {
                        final confirmed = await showZerpaiConfirmationDialog(
                          context,
                          title: 'Delete Template',
                          message:
                              'Are you sure you want to delete this template?',
                          confirmLabel: 'Delete',
                          cancelLabel: 'Cancel',
                          variant: ZerpaiConfirmationVariant.danger,
                        );
                        if (confirmed == true) {
                          await widget.ref
                              .read(manualJournalTemplateProvider.notifier)
                              .deleteTemplate(template.id);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (displayTotalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Page ${_currentPage + 1} of $displayTotalPages (${widget.templates.length} items)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, size: 16),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight, size: 16),
                  onPressed: _currentPage < displayTotalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
